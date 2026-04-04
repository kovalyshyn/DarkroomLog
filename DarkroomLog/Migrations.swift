import SwiftData

// MARK: - Schema v1 (DarkroomLog 1.0 / 1.1)
// Session, Print, Equipment — no FilmRoll, no filmRoll on Print

enum AppSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Session.self, Print.self, Equipment.self]
    }
}

// MARK: - Schema v2 (DarkroomLog 1.2)
// Adds FilmRoll model + filmRoll relationship on Print

enum AppSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 1, 0)
    static var models: [any PersistentModel.Type] {
        [Session.self, Print.self, Equipment.self, FilmRoll.self]
    }
}

// MARK: - Migration plan

enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [AppSchemaV1.self, AppSchemaV2.self]
    }
    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: AppSchemaV1.self, toVersion: AppSchemaV2.self)]
    }
}
