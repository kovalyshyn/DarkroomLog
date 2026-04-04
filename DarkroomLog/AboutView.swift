import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    AppIconView(size: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .shadow(color: .black.opacity(0.3), radius: 10, y: 4)

                    VStack(spacing: 4) {
                        Text("DarkroomLog")
                            .font(.title2.bold())
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .listRowBackground(Color.clear)

            Section("About") {
                Text("DarkroomLog helps analog photographers log darkroom sessions, track exposure times, catalog film rolls, and keep notes on every print.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }

            Section("Developer") {
                LabeledContent("Author", value: "Vitalii Kovalyshyn")
                Link(destination: URL(string: "https://filmly.co.ua")!) {
                    LabeledContent("Community") {
                        Text("filmly.co.ua")
                            .foregroundStyle(.blue)
                    }
                }
                Link(destination: URL(string: "https://github.com/kovalyshyn/DarkroomLog")!) {
                    LabeledContent("Source Code") {
                        Text("github.com")
                            .foregroundStyle(.blue)
                    }
                }
            }

        }
        .listStyle(.insetGrouped)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
