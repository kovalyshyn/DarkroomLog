import SwiftUI
import SwiftData

@main
struct DarkroomLogApp: App {
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
        .modelContainer(for: [Session.self, Print.self, Equipment.self, FilmRoll.self])
    }
}
