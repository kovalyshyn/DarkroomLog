import SwiftUI
import SwiftData

struct NewSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var enlarger = ""
    @State private var lens = ""
    @State private var paper = ""
    @State private var developer = ""
    @State private var comment = ""

    @State private var pickingEnlarger = false
    @State private var pickingLens = false
    @State private var pickingPaper = false
    @State private var pickingDeveloper = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Session name") {
                    TextField("e.g. Portraits — March 2026", text: $name)
                }

                Section("Equipment") {
                    EquipmentRow(label: "Enlarger",  value: enlarger)  { pickingEnlarger = true }
                    EquipmentRow(label: "Lens",      value: lens)      { pickingLens = true }
                    EquipmentRow(label: "Paper",     value: paper)     { pickingPaper = true }
                    EquipmentRow(label: "Developer", value: developer) { pickingDeveloper = true }
                }

                Section("Comment") {
                    TextField("Notes on the session…", text: $comment, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { save() }
                        .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $pickingEnlarger)  { EquipmentPickerView(type: .enlarger,  selection: $enlarger) }
            .sheet(isPresented: $pickingLens)      { EquipmentPickerView(type: .lens,      selection: $lens) }
            .sheet(isPresented: $pickingPaper)     { EquipmentPickerView(type: .paper,     selection: $paper) }
            .sheet(isPresented: $pickingDeveloper) { EquipmentPickerView(type: .developer, selection: $developer) }
        }
    }

    private func save() {
        context.insert(Session(
            name: name.trimmingCharacters(in: .whitespaces),
            enlarger: enlarger,
            lens: lens,
            paper: paper,
            developer: developer,
            comment: comment.trimmingCharacters(in: .whitespaces)
        ))
        dismiss()
    }
}

struct EquipmentRow: View {
    let label: String
    let value: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(label).foregroundStyle(.primary)
                Spacer()
                Text(value.isEmpty ? "Select…" : value)
                    .foregroundStyle(value.isEmpty ? .tertiary : .secondary)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
        }
    }
}
