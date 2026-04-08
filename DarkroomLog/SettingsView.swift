import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @AppStorage("metronomeEnabled") private var metronomeEnabled: Bool = true

    @Environment(\.modelContext) private var context
    @Query private var sessions: [Session]
    @Query private var equipment: [Equipment]
    @Query private var filmRolls: [FilmRoll]

    @State private var showingExportSheet = false
    @State private var exportURL: URL?
    @State private var showingImporter = false
    @State private var pendingRestoreURL: URL?
    @State private var showRestoreConfirm = false
    @State private var alertMessage: String?
    @State private var showAlert = false

    var body: some View {
        Form {
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
                        exportURL = try BackupManager.export(
                            sessions: sessions,
                            equipment: equipment,
                            filmRolls: filmRolls
                        )
                        showingExportSheet = true
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
        .sheet(isPresented: $showingExportSheet) {
            if let url = exportURL {
                ShareSheet(url: url)
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

// MARK: - Share sheet wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
