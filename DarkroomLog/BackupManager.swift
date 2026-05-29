import Foundation
import SwiftData

// MARK: - Backup data structures

struct BackupData: Codable {
    let version: Int
    let exportedAt: Date
    let equipment: [EquipmentRecord]
    let filmRolls: [FilmRollRecord]
    let sessions: [SessionRecord]
    var chemBatches: [ChemBatchRecord]?
}

struct EquipmentRecord: Codable {
    let name: String
    let category: String
}

struct FilmDevStepRecord: Codable {
    let name: String
    let seconds: Int
    let order: Int
    // Optional for backward compatibility with pre-v1.8 backups that lack these keys.
    var agitationEnabled: Bool?
    var agitationInitialSeconds: Int?
    var agitationIntervalSeconds: Int?
    var agitationDurationSeconds: Int?
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
    var devSteps: [FilmDevStepRecord]?
    var statusRaw: String?
    var loadedAt: Date?
    var exposedAt: Date?
    var developingAt: Date?
    var developedAt: Date?
    var doneAt: Date?
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

struct ChemBatchRecord: Codable {
    let name: String
    let notes: String
    let mixedOn: Date
    let maxUnits: Int
    let usedUnits: Int
    let expiryMonths: Int
    let createdAt: Date
}

struct PrintRecord: Codable {
    let id: UUID
    let name: String
    let exposureSeconds: Int
    let exposureTimesData: String
    let aperture: String
    let notes: String
    let rating: Int
    let createdAt: Date
    let photoData: Data?
    let filmRollId: UUID?
}

// MARK: - BackupManager

enum BackupManager {

    static func exportData(
        sessions: [Session],
        equipment: [Equipment],
        filmRolls: [FilmRoll],
        chemBatches: [ChemBatch] = []
    ) throws -> Data {
        let backup = BackupData(
            version: 2,
            exportedAt: Date(),
            equipment: equipment.map {
                EquipmentRecord(name: $0.name, category: $0.category)
            },
            filmRolls: filmRolls.map { roll in
                FilmRollRecord(
                    id: roll.id, name: roll.name, date: roll.date,
                    filmType: roll.filmType, film: roll.film,
                    camera: roll.camera, lens: roll.lens,
                    developer: roll.developer, notes: roll.notes,
                    devSteps: roll.devSteps.sorted { $0.order < $1.order }.map {
                        FilmDevStepRecord(
                            name: $0.name, seconds: $0.seconds, order: $0.order,
                            agitationEnabled: $0.agitationEnabled,
                            agitationInitialSeconds: $0.agitationInitialSeconds,
                            agitationIntervalSeconds: $0.agitationIntervalSeconds,
                            agitationDurationSeconds: $0.agitationDurationSeconds
                        )
                    },
                    statusRaw: roll.statusRaw,
                    loadedAt: roll.loadedAt,
                    exposedAt: roll.exposedAt,
                    developingAt: roll.developingAt,
                    developedAt: roll.developedAt,
                    doneAt: roll.doneAt
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
                            exposureSeconds: p.exposureTimes.first ?? p.exposureSeconds,
                            exposureTimesData: p.exposureTimes.map(String.init).joined(separator: ","),
                            aperture: p.aperture,
                            notes: p.notes, rating: p.rating,
                            createdAt: p.createdAt,
                            photoData: p.photoData,
                            filmRollId: p.filmRoll?.id
                        )
                    }
                )
            },
            chemBatches: chemBatches.map {
                ChemBatchRecord(
                    name: $0.name, notes: $0.notes,
                    mixedOn: $0.mixedOn, maxUnits: $0.maxUnits,
                    usedUnits: $0.usedUnits, expiryMonths: $0.expiryMonths,
                    createdAt: $0.createdAt
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(backup)
    }

    static func restore(from url: URL, context: ModelContext) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        // Decode fully BEFORE touching the store: a corrupt or incompatible file
        // throws here, leaving existing data untouched.
        let backup = try decoder.decode(BackupData.self, from: data)

        // Delete existing data as pending changes (not immediate batch deletes) so the
        // whole restore — deletes + inserts — commits atomically in the final save().
        // Deleting each Session cascade-deletes its Prints.
        for s in (try? context.fetch(FetchDescriptor<Session>())) ?? [] { context.delete(s) }
        for r in (try? context.fetch(FetchDescriptor<FilmRoll>())) ?? [] { context.delete(r) }
        for e in (try? context.fetch(FetchDescriptor<Equipment>())) ?? [] { context.delete(e) }
        for c in (try? context.fetch(FetchDescriptor<ChemBatch>())) ?? [] { context.delete(c) }

        // Restore equipment
        for rec in backup.equipment {
            context.insert(Equipment(name: rec.name, category: rec.category))
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
            roll.statusRaw = rec.statusRaw ?? FilmRollStatus.loaded.rawValue
            roll.loadedAt = rec.loadedAt
            roll.exposedAt = rec.exposedAt
            roll.developingAt = rec.developingAt
            roll.developedAt = rec.developedAt
            roll.doneAt = rec.doneAt
            context.insert(roll)
            for stepRec in rec.devSteps ?? [] {
                let step = FilmDevStep(name: stepRec.name, seconds: stepRec.seconds, order: stepRec.order)
                step.agitationEnabled = stepRec.agitationEnabled ?? false
                step.agitationInitialSeconds = stepRec.agitationInitialSeconds ?? 0
                step.agitationIntervalSeconds = stepRec.agitationIntervalSeconds ?? 30
                step.agitationDurationSeconds = stepRec.agitationDurationSeconds ?? 10
                context.insert(step)
                roll.devSteps.append(step)
            }
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
                p.exposureTimes = pRec.exposureTimesData.split(separator: ",").compactMap { Int($0) }
                p.aperture = pRec.aperture
                p.rating = pRec.rating
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

        // Restore chemistry batches (v2+ backups)
        for rec in backup.chemBatches ?? [] {
            let batch = ChemBatch(
                name: rec.name, notes: rec.notes,
                mixedOn: rec.mixedOn, maxUnits: rec.maxUnits,
                expiryMonths: rec.expiryMonths
            )
            batch.usedUnits = rec.usedUnits
            batch.createdAt = rec.createdAt
            context.insert(batch)
        }

        // Commit the whole restore in one transaction.
        try context.save()
    }
}
