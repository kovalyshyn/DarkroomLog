import Foundation
import SwiftData

enum EquipmentType: String, CaseIterable {
    case enlarger, lens, paper, developer

    var label: String {
        switch self {
        case .enlarger:  return "Enlarger"
        case .lens:      return "Lens"
        case .paper:     return "Paper"
        case .developer: return "Developer"
        }
    }

    var pluralLabel: String {
        switch self {
        case .enlarger:  return "Enlargers"
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
class Print {
    var id: UUID
    var exposureSeconds: Int
    var notes: String
    var createdAt: Date
    var photoData: Data?
    var session: Session?

    init(exposureSeconds: Int = 0, notes: String = "") {
        self.id = UUID()
        self.exposureSeconds = exposureSeconds
        self.notes = notes
        self.createdAt = Date()
    }
}
