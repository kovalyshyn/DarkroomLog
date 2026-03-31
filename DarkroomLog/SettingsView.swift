import SwiftUI

struct SettingsView: View {
    @AppStorage("metronomeEnabled") private var metronomeEnabled: Bool = true

    var body: some View {
        Form {
            Section("Timer") {
                Toggle("Metronome", isOn: $metronomeEnabled)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
