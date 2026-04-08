import Foundation
import SwiftData

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
    }
}

@Model
class Print {
    var id: UUID
    var name: String = ""
    var exposureSeconds: Int   // kept for migration from v1.0
    var exposureTimesData: String = ""
    var aperture: String = ""
    var notes: String
    var rating: Int = 0        // 0 = unrated, 1–3 stars
    var createdAt: Date
    var photoData: Data?
    var session: Session?
    var filmRoll: FilmRoll?

    var exposureTimes: [Int] {
        get { exposureTimesData.split(separator: ",").compactMap { Int($0) } }
        set { exposureTimesData = newValue.map { String($0) }.joined(separator: ",") }
    }

    init(exposureTimes: [Int] = [], notes: String = "") {
        self.id = UUID()
        self.exposureSeconds = exposureTimes.first ?? 0
        self.exposureTimesData = exposureTimes.map { String($0) }.joined(separator: ",")
        self.notes = notes
        self.createdAt = Date()
    }
}
