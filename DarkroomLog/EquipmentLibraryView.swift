import SwiftUI
import SwiftData
import UIKit

// MARK: - Library root (category list)

struct EquipmentLibraryView: View {
    @Query private var allEquipment: [Equipment]

    private func count(for type: EquipmentType) -> Int {
        allEquipment.filter { $0.category == type.rawValue }.count
    }

    var body: some View {
        List {
            ForEach(EquipmentType.allCases, id: \.rawValue) { type in
                NavigationLink(destination: EquipmentCategoryView(type: type)) {
                    HStack {
                        Text(type.pluralLabel)
                        Spacer()
                        let n = count(for: type)
                        if n > 0 {
                            Text("\(n)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Equipment")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Category detail (items list)

struct EquipmentCategoryView: View {
    let type: EquipmentType
    @Environment(\.modelContext) private var context
    @Query private var allEquipment: [Equipment]

    @State private var newName = ""
    @State private var showingAdd = false
    @State private var editingItem: Equipment?
    @State private var editName = ""

    private var items: [Equipment] {
        allEquipment.filter { $0.category == type.rawValue }.sorted { $0.name < $1.name }
    }

    var body: some View {
        List {
            ForEach(items) { item in
                Text(item.name)
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = item.name
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        Button {
                            editingItem = item
                            editName = item.name
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            editingItem = item
                            editName = item.name
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
            }
            .onDelete { offsets in
                let list = items
                for i in offsets { context.delete(list[i]) }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(type.pluralLabel)
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if items.isEmpty {
                ContentUnavailableView(
                    "No \(type.pluralLabel)",
                    systemImage: "tray",
                    description: Text("Tap + to add your first item.")
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
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
                newName = ""
            }
            Button("Cancel", role: .cancel) { newName = "" }
        }
        .alert(
            "Edit \(editingItem?.name ?? "")",
            isPresented: Binding(get: { editingItem != nil }, set: { if !$0 { editingItem = nil } })
        ) {
            TextField("Name", text: $editName)
            Button("Save") {
                let trimmed = editName.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                editingItem?.name = trimmed
                editingItem = nil
            }
            Button("Cancel", role: .cancel) { editingItem = nil }
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
