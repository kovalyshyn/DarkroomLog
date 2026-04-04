import SwiftUI
import SwiftData

@Observable
private final class AppModel {
    let container: ModelContainer

    init() {
        let schema = Schema([Session.self, Print.self, Equipment.self, FilmRoll.self])
        do {
            container = try ModelContainer(for: schema, migrationPlan: AppMigrationPlan.self)
        } catch {
            container = try! ModelContainer(for: schema)
        }
    }
}

@main
struct DarkroomLogApp: App {
    @State private var appModel = AppModel()

    init() {
        _ = NotificationManager.shared
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Darkroom", systemImage: "photo.stack") {
                    SessionListView()
                }
                Tab("Light Table", systemImage: "film") {
                    FilmRollListView()
                }
            }
        }
        .modelContainer(appModel.container)
    }
}
