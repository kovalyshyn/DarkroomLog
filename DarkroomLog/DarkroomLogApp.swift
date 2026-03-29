import SwiftUI
import SwiftData

@main
struct DarkroomLogApp: App {
    var body: some Scene {
        WindowGroup {
            SessionListView()
        }
        .modelContainer(for: [Session.self, Print.self, Equipment.self])
    }
}
