import SwiftUI

struct SettingsView: View {
    @AppStorage("metronomeEnabled") private var metronomeEnabled: Bool = true

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
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
