import SwiftUI
import SwiftData

struct FilmRollListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FilmRoll.date, order: .reverse) private var rolls: [FilmRoll]

    @State private var showAdd = false
    @State private var editingRoll: FilmRoll? = nil
    @State private var searchText = ""

    private var filteredRolls: [FilmRoll] {
        guard !searchText.isEmpty else { return rolls }
        let q = searchText.lowercased()
        return rolls.filter {
            $0.name.lowercased().contains(q) ||
            $0.film.lowercased().contains(q) ||
            $0.camera.lowercased().contains(q) ||
            $0.filmType.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredRolls) { roll in
                    Button {
                        editingRoll = roll
                    } label: {
                        FilmRollRow(roll: roll)
                    }
                    .tint(.primary)
                }
                .onDelete(perform: deleteRolls)
            }
            .searchable(text: $searchText, prompt: "Name, film, camera…")
            .navigationTitle("Light Table")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        NavigationLink(destination: EquipmentLibraryView()) {
                            Label("Equipment", systemImage: "tray.full")
                        }
                        NavigationLink(destination: SettingsView()) {
                            Label("Settings", systemImage: "gearshape")
                        }
                        NavigationLink(destination: AboutView()) {
                            Label("About", systemImage: "info.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: TimerView(darkroomMode: false)) {
                        Image(systemName: "timer")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .overlay {
                if rolls.isEmpty {
                    ContentUnavailableView(
                        "No Film Rolls",
                        systemImage: "film",
                        description: Text("Tap + to add your first roll.")
                    )
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            FilmRollFormView()
        }
        .sheet(item: $editingRoll) { roll in
            FilmRollFormView(roll: roll)
        }
    }

    private func deleteRolls(at offsets: IndexSet) {
        for i in offsets {
            context.delete(filteredRolls[i])
        }
    }
}

struct FilmRollRow: View {
    let roll: FilmRoll

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(roll.name.isEmpty ? "Unnamed roll" : roll.name)
                    .font(.headline)
                Spacer()
                Text(roll.filmType)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                if !roll.film.isEmpty {
                    Text(roll.film)
                }
                if !roll.developer.isEmpty {
                    Text("·")
                    Text(roll.developer)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Text(roll.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

struct FilmRollFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var roll: FilmRoll? = nil

    @State private var name: String = ""
    @State private var date: Date = Date()
    @State private var filmType: String = "135"
    @State private var film: String = ""
    @State private var camera: String = ""
    @State private var lens: String = ""
    @State private var developer: String = ""
    @State private var notes: String = ""

    @State private var pickingFilmStock = false
    @State private var pickingCamera = false
    @State private var pickingLens = false
    @State private var pickingDeveloper = false

    private let filmTypes = ["135", "120"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Roll") {
                    TextField("Name", text: $name)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Picker("Format", selection: $filmType) {
                        ForEach(filmTypes, id: \.self) { t in
                            Text(t).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Film") {
                    EquipmentRow(label: "Film Stock", value: film)      { pickingFilmStock = true }
                    EquipmentRow(label: "Developer",  value: developer) { pickingDeveloper = true }
                    EquipmentRow(label: "Camera",     value: camera)    { pickingCamera = true }
                    EquipmentRow(label: "Lens",       value: lens)      { pickingLens = true }
                }

                Section("Notes") {
                    TextField("Notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(roll == nil ? "New Roll" : "Edit Roll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.isEmpty && film.isEmpty)
                }
            }
            .onAppear {
                if let r = roll {
                    name = r.name
                    date = r.date
                    filmType = r.filmType
                    film = r.film
                    developer = r.developer
                    camera = r.camera
                    lens = r.lens
                    notes = r.notes
                }
            }
            .sheet(isPresented: $pickingFilmStock) { EquipmentPickerView(type: .filmStock, selection: $film) }
            .sheet(isPresented: $pickingDeveloper) { EquipmentPickerView(type: .developer, selection: $developer) }
            .sheet(isPresented: $pickingCamera)    { EquipmentPickerView(type: .camera,    selection: $camera) }
            .sheet(isPresented: $pickingLens)      { EquipmentPickerView(type: .lens,      selection: $lens) }
            
        }
    }

    private func save() {
        if let r = roll {
            r.name = name
            r.date = date
            r.filmType = filmType
            r.film = film
            r.developer = developer
            r.camera = camera
            r.lens = lens
            r.notes = notes
        } else {
            let r = FilmRoll(
                name: name, filmType: filmType, film: film,
                camera: camera, lens: lens, developer: developer, notes: notes
            )
            r.date = date
            context.insert(r)
        }
        dismiss()
    }
}

// MARK: - Film Roll Picker (searchable sheet)

struct FilmRollPickerView: View {
    @Binding var selection: FilmRoll?
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FilmRoll.date, order: .reverse) private var rolls: [FilmRoll]
    @State private var searchText = ""

    private var filtered: [FilmRoll] {
        guard !searchText.isEmpty else { return rolls }
        let q = searchText.lowercased()
        return rolls.filter {
            $0.name.lowercased().contains(q) ||
            $0.film.lowercased().contains(q) ||
            $0.camera.lowercased().contains(q) ||
            $0.filmType.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Button {
                    selection = nil
                    dismiss()
                } label: {
                    HStack {
                        Text("None").foregroundStyle(.secondary)
                        Spacer()
                        if selection == nil {
                            Image(systemName: "checkmark").foregroundStyle(.blue)
                        }
                    }
                }
                .foregroundStyle(.primary)

                ForEach(filtered) { roll in
                    Button {
                        selection = roll
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(roll.name.isEmpty ? roll.film : roll.name)
                                    .font(.body)
                                HStack(spacing: 6) {
                                    Text(roll.filmType)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1)
                                        .background(Color.secondary.opacity(0.15))
                                        .clipShape(Capsule())
                                    if !roll.camera.isEmpty {
                                        Text(roll.camera)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if !roll.film.isEmpty && !roll.name.isEmpty {
                                        Text(roll.film)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            Spacer()
                            if selection?.id == roll.id {
                                Image(systemName: "checkmark").foregroundStyle(.blue)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .searchable(text: $searchText, prompt: "Name, film, camera…")
            .navigationTitle("Film Roll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
