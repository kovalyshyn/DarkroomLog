import SwiftUI
import SwiftData

@main
struct DarkroomLogApp: App {
    init() {
        _ = NotificationManager.shared
    }

    var body: some Scene {
        WindowGroup {
            SessionListView()
        }
        .modelContainer(for: [Session.self, Print.self, Equipment.self])
    }
}
