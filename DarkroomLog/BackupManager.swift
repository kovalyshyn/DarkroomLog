import Foundation
import SwiftData

// MARK: - Backup data structures

struct BackupData: Codable {
    let version: Int
    let exportedAt: Date
    let equipment: [EquipmentRecord]
    let filmRolls: [FilmRollRecord]
    let sessions: [SessionRecord]
}

struct EquipmentRecord: Codable {
    let name: String
    let category: String
}

struct FilmRollRecord: Codable {
    let id: UUID
    let name: String
    let date: Date
    let filmType: String
    let film: String
    let camera: String
    let lens: String
    let developer: String
    let notes: String
}

struct SessionRecord: Codable {
    let id: UUID
    let name: String
    let date: Date
    let enlarger: String
    let lens: String
    let paper: String
    let developer: String
    let comment: String
    let prints: [PrintRecord]
}

struct PrintRecord: Codable {
    let id: UUID
    let name: String
    let exposureSeconds: Int
    let exposureTimesData: String
    let notes: String
    let createdAt: Date
    let photoData: Data?
    let filmRollId: UUID?
}

// MARK: - BackupManager

enum BackupManager {

    static func export(
        sessions: [Session],
        equipment: [Equipment],
        filmRolls: [FilmRoll]
    ) throws -> URL {
        let backup = BackupData(
            version: 1,
            exportedAt: Date(),
            equipment: equipment.map {
                EquipmentRecord(name: $0.name, category: $0.category)
            },
            filmRolls: filmRolls.map {
                FilmRollRecord(
                    id: $0.id, name: $0.name, date: $0.date,
                    filmType: $0.filmType, film: $0.film,
                    camera: $0.camera, lens: $0.lens,
                    developer: $0.developer, notes: $0.notes
                )
            },
            sessions: sessions.map { s in
                SessionRecord(
                    id: s.id, name: s.name, date: s.date,
                    enlarger: s.enlarger, lens: s.lens,
                    paper: s.paper, developer: s.developer, comment: s.comment,
                    prints: s.prints.map { p in
                        PrintRecord(
                            id: p.id, name: p.name,
                            exposureSeconds: p.exposureSeconds,
                            exposureTimesData: p.exposureTimesData,
                            notes: p.notes, createdAt: p.createdAt,
                            photoData: p.photoData,
                            filmRollId: p.filmRoll?.id
                        )
                    }
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let json = try encoder.encode(backup)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: Date())
        let filename = "DarkroomLog-\(dateStr).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try json.write(to: url, options: .atomic)
        return url
    }

    static func restore(from url: URL, context: ModelContext) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(BackupData.self, from: data)

        // Delete all existing data (Session cascade-deletes Prints)
        try context.delete(model: Session.self)
        try context.delete(model: FilmRoll.self)
        try context.delete(model: Equipment.self)

        // Restore equipment
        for rec in backup.equipment {
            let eq = Equipment(name: rec.name, equipmentType: .enlarger)
            eq.category = rec.category
            context.insert(eq)
        }

        // Restore film rolls, keep UUID for print linkage
        var rollMap: [UUID: FilmRoll] = [:]
        for rec in backup.filmRolls {
            let roll = FilmRoll(
                name: rec.name, filmType: rec.filmType, film: rec.film,
                camera: rec.camera, lens: rec.lens,
                developer: rec.developer, notes: rec.notes
            )
            roll.id = rec.id
            roll.date = rec.date
            context.insert(roll)
            rollMap[rec.id] = roll
        }

        // Restore sessions and prints
        for sRec in backup.sessions {
            let session = Session(
                name: sRec.name, enlarger: sRec.enlarger, lens: sRec.lens,
                paper: sRec.paper, developer: sRec.developer, comment: sRec.comment
            )
            session.id = sRec.id
            session.date = sRec.date
            context.insert(session)

            for pRec in sRec.prints {
                let p = Print(notes: pRec.notes)
                p.id = pRec.id
                p.name = pRec.name
                p.exposureSeconds = pRec.exposureSeconds
                p.exposureTimesData = pRec.exposureTimesData
                p.createdAt = pRec.createdAt
                p.photoData = pRec.photoData
                p.session = session
                if let rollId = pRec.filmRollId {
                    p.filmRoll = rollMap[rollId]
                }
                context.insert(p)
                session.prints.append(p)
            }
        }
    }
}
