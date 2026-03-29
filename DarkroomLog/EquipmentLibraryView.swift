import SwiftUI
import SwiftData

// MARK: - Library (manage reference lists)

struct EquipmentLibraryView: View {
    @Environment(\.modelContext) private var context
    @Query private var allEquipment: [Equipment]

    @State private var addingType: EquipmentType?
    @State private var newName = ""

    private func items(for type: EquipmentType) -> [Equipment] {
        allEquipment.filter { $0.category == type.rawValue }.sorted { $0.name < $1.name }
    }

    var body: some View {
        List {
            ForEach(EquipmentType.allCases, id: \.rawValue) { type in
                Section(type.pluralLabel) {
                    ForEach(items(for: type)) { item in
                        Text(item.name)
                    }
                    .onDelete { offsets in
                        let list = items(for: type)
                        for i in offsets { context.delete(list[i]) }
                    }

                    Button {
                        addingType = type
                    } label: {
                        Label("Add \(type.label)", systemImage: "plus")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Equipment")
        .navigationBarTitleDisplayMode(.large)
        .alert(
            "New \(addingType?.label ?? "")",
            isPresented: Binding(
                get: { addingType != nil },
                set: { if !$0 { addingType = nil } }
            )
        ) {
            TextField("Name", text: $newName)
            Button("Add") {
                guard let type = addingType,
                      !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                context.insert(Equipment(
                    name: newName.trimmingCharacters(in: .whitespaces),
                    equipmentType: type
                ))
                newName = ""
                addingType = nil
            }
            Button("Cancel", role: .cancel) {
                newName = ""
                addingType = nil
            }
        }
    }
}

// MARK: - Picker (select inside a form)

struct EquipmentPickerView: View {
    let type: EquipmentType
    @Binding var selection: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var allEquipment: [Equipment]

    @State private var newName = ""
    @State private var showingAdd = false

    private var items: [Equipment] {
        allEquipment.filter { $0.category == type.rawValue }.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            List {
                Button {
                    selection = ""
                    dismiss()
                } label: {
                    HStack {
                        Text("None").foregroundStyle(.secondary)
                        Spacer()
                        if selection.isEmpty {
                            Image(systemName: "checkmark").foregroundStyle(.blue)
                        }
                    }
                }
                .foregroundStyle(.primary)

                ForEach(items) { item in
                    Button {
                        selection = item.name
                        dismiss()
                    } label: {
                        HStack {
                            Text(item.name)
                            Spacer()
                            if selection == item.name {
                                Image(systemName: "checkmark").foregroundStyle(.blue)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
                .onDelete { offsets in
                    let list = items
                    for i in offsets {
                        if selection == list[i].name { selection = "" }
                        context.delete(list[i])
                    }
                }
            }
            .navigationTitle(type.pluralLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("New \(type.label)", isPresented: $showingAdd) {
                TextField("Name", text: $newName)
                Button("Add") {
                    let trimmed = newName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    context.insert(Equipment(name: trimmed, equipmentType: type))
                    selection = trimmed
                    newName = ""
                    dismiss()
                }
                Button("Cancel", role: .cancel) { newName = "" }
            }
        }
    }
}
