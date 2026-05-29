import SwiftUI
import SwiftData

@Observable
private final class AppModel {
    let container: ModelContainer
    /// True when the on-disk store couldn't be opened and a temporary in-memory
    /// store is in use instead — so we can warn the user rather than crash-loop.
    let storeLoadFailed: Bool

    init() {
        let models: [any PersistentModel.Type] =
            [Session.self, Print.self, Equipment.self, FilmRoll.self, ChemBatch.self, FilmDevStep.self]
        do {
            container = try ModelContainer(for: Schema(models))
            storeLoadFailed = false
            migrateLegacyRollsToDone(context: container.mainContext)
            migratePrintExposures(context: container.mainContext)
        } catch {
            // The persistent store is unreadable/corrupt. Fall back to an in-memory
            // store so the app still launches and the user can restore from a backup.
            storeLoadFailed = true
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Schema(models), configurations: config)
        }
    }
}

@main
struct DarkroomLogApp: App {
    @State private var appModel = AppModel()
    @State private var showStoreError = false
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
            .onAppear { showStoreError = appModel.storeLoadFailed }
            .alert("Couldn't open your data", isPresented: $showStoreError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your saved data couldn't be loaded, so a temporary database is in use. Restore from a backup in Settings to recover it. Changes made now won't be saved.")
            }
        }
        .modelContainer(appModel.container)
    }
}
