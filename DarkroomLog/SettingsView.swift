import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Backup file document

struct BackupFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    let data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Settings view

struct SettingsView: View {
    @AppStorage("metronomeEnabled") private var metronomeEnabled: Bool = true
    @AppStorage("forceDarkMode") private var forceDarkMode: Bool = false

    @Environment(\.modelContext) private var context
    @Query private var sessions: [Session]
    @Query private var equipment: [Equipment]
    @Query private var filmRolls: [FilmRoll]
    @Query private var chemBatches: [ChemBatch]

    @State private var exportDocument: BackupFileDocument?
    @State private var exportFilename = "DarkroomLog-backup.json"
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var pendingRestoreURL: URL?
    @State private var showRestoreConfirm = false
    @State private var alertMessage: String?
    @State private var showAlert = false

    var body: some View {
        Form {
            Section("Appearance") {
                Toggle("Always Dark Interface", isOn: $forceDarkMode)
            }

            Section("Timer") {
                Toggle("Metronome", isOn: $metronomeEnabled)
            }

            Section("Wash Timer") {
                Text("Wash timer notification volume follows your device's ringer volume.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button {
                    do {
                        let data = try BackupManager.exportData(
                            sessions: sessions,
                            equipment: equipment,
                            filmRolls: filmRolls,
                            chemBatches: chemBatches
                        )
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        exportFilename = "DarkroomLog-\(formatter.string(from: Date())).json"
                        exportDocument = BackupFileDocument(data: data)
                        showingExporter = true
                    } catch {
                        alertMessage = "Export failed: \(error.localizedDescription)"
                        showAlert = true
                    }
                } label: {
                    Label("Export Backup", systemImage: "square.and.arrow.up")
                }

                Button {
                    showingImporter = true
                } label: {
                    Label("Restore from Backup", systemImage: "square.and.arrow.down")
                }
                .foregroundStyle(.orange)
            } header: {
                Text("Data")
            } footer: {
                Text("Backup includes all sessions, prints, film rolls, equipment, and photos.")
                    .font(.caption)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: exportFilename
        ) { result in
            if case .failure(let error) = result {
                alertMessage = "Export failed: \(error.localizedDescription)"
                showAlert = true
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let url):
                pendingRestoreURL = url
                showRestoreConfirm = true
            case .failure(let error):
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
        .confirmationDialog(
            "Restore Backup",
            isPresented: $showRestoreConfirm,
            titleVisibility: .visible
        ) {
            Button("Replace all data and restore", role: .destructive) {
                guard let url = pendingRestoreURL else { return }
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                do {
                    try BackupManager.restore(from: url, context: context)
                    alertMessage = "Backup restored successfully."
                } catch {
                    alertMessage = "Restore failed: \(error.localizedDescription)"
                }
                showAlert = true
                pendingRestoreURL = nil
            }
            Button("Cancel", role: .cancel) { pendingRestoreURL = nil }
        } message: {
            Text("All current sessions, prints, film rolls, and equipment will be replaced. This cannot be undone.")
        }
        .alert("Backup", isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage ?? "")
        }
    }
}
