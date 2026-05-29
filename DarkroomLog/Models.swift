import Foundation
import SwiftData
import SwiftUI

enum FilmRollStatus: String, CaseIterable {
    case loaded, exposed, developing, developed, done

    var label: String {
        switch self {
        case .loaded:     return "Loaded"
        case .exposed:    return "Exposed"
        case .developing: return "Developing"
        case .developed:  return "Developed"
        case .done:       return "Done"
        }
    }

    var icon: String {
        switch self {
        case .loaded:     return "camera"
        case .exposed:    return "circle.dotted"
        case .developing: return "flask"
        case .developed:  return "film"
        case .done:       return "checkmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .loaded:     return .blue
        case .exposed:    return .orange
        case .developing: return .purple
        case .developed:  return .green
        case .done:       return .secondary
        }
    }
}

enum EquipmentType: String, CaseIterable {
    case enlarger, camera, lens, paper, filmStock, developer

    var label: String {
        switch self {
        case .enlarger:  return "Enlarger"
        case .camera:    return "Camera"
        case .filmStock: return "Film Stock"
        case .lens:      return "Lens"
        case .paper:     return "Paper"
        case .developer: return "Developer"
        }
    }

    var pluralLabel: String {
        switch self {
        case .enlarger:  return "Enlargers"
        case .camera:    return "Cameras"
        case .filmStock: return "Film Stocks"
        case .lens:      return "Lenses"
        case .paper:     return "Papers"
        case .developer: return "Developers"
        }
    }
}

@Model
class Equipment {
    var name: String
    var category: String

    init(name: String, equipmentType: EquipmentType) {
        self.name = name
        self.category = equipmentType.rawValue
    }

    init(name: String, category: String) {
        self.name = name
        self.category = category
    }
}

@Model
class Session {
    var id: UUID
    var name: String
    var date: Date
    var enlarger: String
    var lens: String
    var paper: String
    var developer: String
    var comment: String
    @Relationship(deleteRule: .cascade) var prints: [Print]

    init(name: String = "", enlarger: String = "", lens: String = "",
         paper: String = "", developer: String = "", comment: String = "") {
        self.id = UUID()
        self.name = name
        self.date = Date()
        self.enlarger = enlarger
        self.lens = lens
        self.paper = paper
        self.developer = developer
        self.comment = comment
        self.prints = []
    }
}

@Model
class FilmRoll {
    var id: UUID
    var name: String
    var date: Date
    var filmType: String  // "135" or "120"
    var film: String
    var camera: String
    var lens: String
    var developer: String
    var notes: String
    var statusRaw: String = FilmRollStatus.loaded.rawValue
    var loadedAt: Date?
    var exposedAt: Date?
    var developingAt: Date?
    var developedAt: Date?
    var doneAt: Date?
    @Relationship(deleteRule: .cascade) var devSteps: [FilmDevStep] = []

    var rollStatus: FilmRollStatus {
        get { FilmRollStatus(rawValue: statusRaw) ?? .loaded }
        set { statusRaw = newValue.rawValue }
    }

    /// "Name (135)" / "Film (120)" / "135" — used wherever a roll is shown in one line.
    var displayLabel: String {
        let n = name.isEmpty ? film : name
        return n.isEmpty ? filmType : "\(n) (\(filmType))"
    }

    var statusHistory: [(FilmRollStatus, Date)] {
        [
            (FilmRollStatus.loaded,     loadedAt),
            (FilmRollStatus.exposed,    exposedAt),
            (FilmRollStatus.developing, developingAt),
            (FilmRollStatus.developed,  developedAt),
            (FilmRollStatus.done,       doneAt),
        ]
        .compactMap { s, d in d.map { (s, $0) } }
        .sorted { $0.1 < $1.1 }
    }

    func setStatus(_ s: FilmRollStatus, at when: Date = Date()) {
        rollStatus = s
        switch s {
        case .loaded:     loadedAt     = when
        case .exposed:    exposedAt    = when
        case .developing: developingAt = when
        case .developed:  developedAt  = when
        case .done:       doneAt       = when
        }
    }

    func clearStatus(_ s: FilmRollStatus) {
        switch s {
        case .loaded:     loadedAt     = nil
        case .exposed:    exposedAt    = nil
        case .developing: developingAt = nil
        case .developed:  developedAt  = nil
        case .done:       doneAt       = nil
        }
        // If current status was removed, revert to the last remaining one
        if rollStatus == s {
            let remaining = statusHistory.sorted { $0.1 > $1.1 }
            rollStatus = remaining.first?.0 ?? .loaded
        }
    }

    init(name: String = "", filmType: String = "135", film: String = "",
         camera: String = "", lens: String = "", developer: String = "", notes: String = "") {
        self.id = UUID()
        self.name = name
        self.date = Date()
        self.filmType = filmType
        self.film = film
        self.camera = camera
        self.lens = lens
        self.developer = developer
        self.notes = notes
        self.loadedAt = Date()
    }
}

struct AgitationScheme {
    var initialSeconds: Int   // continuous agitation at start (0 = none)
    var intervalSeconds: Int  // then every N seconds
    var durationSeconds: Int  // agitate for N seconds each time
}

@Model
class FilmDevStep {
    var name: String
    var seconds: Int
    var order: Int
    var agitationEnabled: Bool = false
    var agitationInitialSeconds: Int = 0
    var agitationIntervalSeconds: Int = 30
    var agitationDurationSeconds: Int = 10

    var agitationScheme: AgitationScheme? {
        guard agitationEnabled else { return nil }
        return AgitationScheme(
            initialSeconds: agitationInitialSeconds,
            intervalSeconds: agitationIntervalSeconds,
            durationSeconds: agitationDurationSeconds
        )
    }

    init(name: String = "", seconds: Int = 60, order: Int = 0) {
        self.name = name
        self.seconds = seconds
        self.order = order
    }
}

@Model
class ChemBatch {
    var name: String
    var notes: String
    var mixedOn: Date
    var maxUnits: Int      // capacity in rolls
    var usedUnits: Int     // manually incremented
    var expiryMonths: Int
    var createdAt: Date

    var usagePercent: Double { Double(usedUnits) / Double(max(1, maxUnits)) }

    var expiryDate: Date {
        Calendar.current.date(byAdding: .month, value: expiryMonths, to: mixedOn) ?? mixedOn
    }

    var isExpired: Bool { Date() >= expiryDate }

    var daysLeft: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0)
    }

    var statusColor: Color {
        if isExpired || usagePercent > 0.9 { return .red }
        if daysLeft < 14 || usagePercent > 0.75 { return .orange }
        return .green
    }

    init(name: String = "", notes: String = "", mixedOn: Date = Date(),
         maxUnits: Int = 20, expiryMonths: Int = 6) {
        self.name = name
        self.notes = notes
        self.mixedOn = mixedOn
        self.maxUnits = maxUnits
        self.usedUnits = 0
        self.expiryMonths = expiryMonths
        self.createdAt = Date()
    }
}

@Model
class Print {
    var id: UUID
    var name: String = ""
    var exposureSeconds: Int        // legacy v1.0 single time — kept for migration/backup
    var exposureTimesData: String = ""  // legacy CSV — kept for migration/backup
    var exposureTimes: [Int] = []   // native storage
    var aperture: String = ""
    var notes: String
    var rating: Int = 0        // 0 = unrated, 1–3 stars
    var createdAt: Date
    var photoData: Data?
    var session: Session?
    var filmRoll: FilmRoll?

    init(exposureTimes: [Int] = [], notes: String = "") {
        self.id = UUID()
        self.exposureTimes = exposureTimes
        self.exposureSeconds = exposureTimes.first ?? 0
        self.notes = notes
        self.createdAt = Date()
    }
}
