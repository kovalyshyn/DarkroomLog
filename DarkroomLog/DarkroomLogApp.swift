import SwiftUI
import SwiftData

@Observable
private final class AppModel {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Session.self, Print.self, Equipment.self, FilmRoll.self, ChemBatch.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}

@main
struct DarkroomLogApp: App {
    @State private var appModel = AppModel()
    @AppStorage("forceDarkMode") private var forceDarkMode: Bool = false

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
                Tab("Chemistry", systemImage: "flask") {
                    ChemistryView()
                }
            }
            .preferredColorScheme(forceDarkMode ? .dark : nil)
        }
        .modelContainer(appModel.container)
    }
}
