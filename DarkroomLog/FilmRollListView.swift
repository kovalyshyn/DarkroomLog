import SwiftUI
import SwiftData

struct FilmRollListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FilmRoll.date, order: .reverse) private var rolls: [FilmRoll]

    @State private var showAdd = false
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
                    NavigationLink(destination: FilmRollDetailView(roll: roll)) {
                        FilmRollRow(roll: roll)
                    }
                }
                .onDelete(perform: deleteRolls)
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Name, film, camera…")
            .navigationTitle("Light Table")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: TimerView(darkroomMode: false)) {
                        Image(systemName: "timer")
                    }
                    .accessibilityLabel("Timer")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New roll")
                }
            }
            .darkroomOverflowMenu()
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
    }

    private func deleteRolls(at offsets: IndexSet) {
        // FilmRoll has no inverse relationship to Print, so deleting a roll would
        // leave Print.filmRoll pointing at a deleted object. Null those links first.
        let allPrints = (try? context.fetch(FetchDescriptor<Print>())) ?? []
        for i in offsets {
            let roll = filteredRolls[i]
            for p in allPrints where p.filmRoll?.id == roll.id { p.filmRoll = nil }
            context.delete(roll)
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
                BadgeView(text: roll.rollStatus.label, tint: roll.rollStatus.color)
                BadgeView(text: roll.filmType)
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

// MARK: - Film Roll Detail

struct FilmRollDetailView: View {
    @Bindable var roll: FilmRoll
    @Environment(\.modelContext) private var context
    @Query private var allPrints: [Print]

    @State private var editingRoll = false
    @State private var showSharePreview = false
    @State private var showAddStep = false
    @State private var editingStep: FilmDevStep? = nil

    private var linkedPrints: [Print] {
        allPrints
            .filter { $0.filmRoll?.id == roll.id }
            .sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        Form {
            Section("Roll") {
                LabeledContent("Format", value: roll.filmType)
                    .font(.subheadline)
                LabeledContent("Date", value: roll.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                HStack {
                    Text("Status")
                    Spacer()
                    Label(roll.rollStatus.label, systemImage: roll.rollStatus.icon)
                        .foregroundStyle(roll.rollStatus.color)
                }
                .font(.subheadline)
            }

            if !roll.film.isEmpty || !roll.developer.isEmpty || !roll.camera.isEmpty || !roll.lens.isEmpty {
                Section("Film") {
                    if !roll.film.isEmpty      { LabeledContent("Film Stock", value: roll.film).font(.subheadline) }
                    if !roll.developer.isEmpty { LabeledContent("Developer",  value: roll.developer).font(.subheadline) }
                    if !roll.camera.isEmpty    { LabeledContent("Camera",     value: roll.camera).font(.subheadline) }
                    if !roll.lens.isEmpty      { LabeledContent("Lens",       value: roll.lens).font(.subheadline) }
                }
            }

            if !roll.notes.isEmpty {
                Section("Notes") {
                    Text(roll.notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            let sortedSteps = roll.devSteps.sorted(by: { $0.order < $1.order })

            Section("Development Steps") {
                ForEach(Array(sortedSteps.enumerated()), id: \.element.persistentModelID) { i, step in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.name.isEmpty ? "Step \(i + 1)" : step.name)
                                .font(.subheadline)
                            Text(formatDevSeconds(step.seconds))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { editingStep = step }
                }
                .onDelete { offsets in
                    for i in offsets {
                        let step = sortedSteps[i]
                        roll.devSteps.removeAll { $0.persistentModelID == step.persistentModelID }
                        context.delete(step)
                    }
                }

                Button { showAddStep = true } label: {
                    Label("Add Step", systemImage: "plus")
                }
            }

            if !sortedSteps.isEmpty {
                Section {
                    NavigationLink(destination: TimerView(
                        intervals: sortedSteps.map { $0.seconds },
                        stepNames: sortedSteps.map { $0.name },
                        agitationSchemes: sortedSteps.map { $0.agitationScheme },
                        darkroomMode: false
                    )) {
                        Label("Start Dev Timer", systemImage: "timer")
                    }
                }
            }

            let history = roll.statusHistory
            if !history.isEmpty {
                Section("History") {
                    ForEach(history, id: \.0) { s, date in
                        HStack {
                            Label(s.label, systemImage: s.icon)
                                .foregroundStyle(s.color)
                            Spacer()
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                    .onDelete { offsets in
                        for i in offsets {
                            roll.clearStatus(history[i].0)
                        }
                    }
                }
            }

            Section("Prints (\(linkedPrints.count))") {
                if linkedPrints.isEmpty {
                    Text("No prints linked to this roll")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(linkedPrints) { p in
                        NavigationLink(destination: PrintDetailView(print: p)) {
                            VStack(alignment: .leading, spacing: 2) {
                                let times = p.exposureTimes
                                let timeStr = times.isEmpty ? "\(p.exposureSeconds)s" : times.map { "\($0)s" }.joined(separator: " · ")
                                Text(p.name.isEmpty ? timeStr : p.name)
                                    .font(.subheadline)
                                HStack(spacing: 6) {
                                    if !p.name.isEmpty {
                                        Text(timeStr)
                                    }
                                    if let session = p.session, !session.name.isEmpty {
                                        Text("·")
                                        Text(session.name)
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(roll.name.isEmpty ? (roll.film.isEmpty ? "Roll" : roll.film) : roll.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSharePreview = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { editingRoll = true }
            }
        }
        .sheet(isPresented: $editingRoll) {
            FilmRollFormView(roll: roll)
        }
        .sheet(isPresented: $showSharePreview) {
            FilmRollSharePreviewSheet(roll: roll, printCount: linkedPrints.count)
        }
        .sheet(isPresented: $showAddStep) {
            FilmDevStepFormView { name, seconds, agitation in
                let step = FilmDevStep(name: name, seconds: seconds, order: roll.devSteps.count)
                if let a = agitation {
                    step.agitationEnabled = true
                    step.agitationInitialSeconds = a.initialSeconds
                    step.agitationIntervalSeconds = a.intervalSeconds
                    step.agitationDurationSeconds = a.durationSeconds
                }
                context.insert(step)
                roll.devSteps.append(step)
            }
        }
        .sheet(item: $editingStep) { step in
            FilmDevStepFormView(
                isNew: false,
                existingName: step.name,
                existingSeconds: step.seconds,
                existingAgitation: step.agitationScheme
            ) { name, seconds, agitation in
                step.name = name
                step.seconds = seconds
                step.agitationEnabled = agitation != nil
                step.agitationInitialSeconds = agitation?.initialSeconds ?? 0
                step.agitationIntervalSeconds = agitation?.intervalSeconds ?? 30
                step.agitationDurationSeconds = agitation?.durationSeconds ?? 10
            }
        }
    }

    private func formatDevSeconds(_ s: Int) -> String {
        let m = s / 60
        let sec = s % 60
        if m == 0 { return "\(sec)s" }
        if sec == 0 { return "\(m)m" }
        return "\(m)m \(sec)s"
    }
}

// MARK: - Film Roll Share Card

struct FilmRollShareCardView: View {
    let roll: FilmRoll
    let printCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header bar
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(roll.name.isEmpty ? (roll.film.isEmpty ? "Film Roll" : roll.film) : roll.name)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(ShareCardColor.title)
                    Text(roll.date.formatted(date: .long, time: .omitted))
                        .font(.system(size: 13))
                        .foregroundStyle(ShareCardColor.muted)
                }
                Spacer()
                Text(roll.filmType)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ShareCardColor.badgeText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(ShareCardColor.badgeFill)
                    .clipShape(Capsule())
            }
            .padding(20)

            ShareCardHairline()

            VStack(alignment: .leading, spacing: 12) {
                if !roll.film.isEmpty      { ShareCardRow(icon: DRIcon.film,      label: "Film Stock", value: roll.film) }
                if !roll.developer.isEmpty { ShareCardRow(icon: DRIcon.developer, label: "Developer",  value: roll.developer) }
                if !roll.camera.isEmpty    { ShareCardRow(icon: DRIcon.camera,    label: "Camera",     value: roll.camera) }
                if !roll.lens.isEmpty      { ShareCardRow(icon: DRIcon.lens,      label: "Lens",       value: roll.lens) }
            }
            .padding(20)

            if !roll.notes.isEmpty {
                ShareCardHairline()
                VStack(alignment: .leading, spacing: 4) {
                    Text("NOTES")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(ShareCardColor.label)
                        .tracking(0.8)
                    Text(roll.notes)
                        .font(.system(size: 13))
                        .foregroundStyle(ShareCardColor.value)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
            }

            ShareCardHairline()

            HStack {
                Image(systemName: DRIcon.prints)
                    .font(.system(size: 13))
                    .foregroundStyle(ShareCardColor.icon)
                Text(printCount == 1 ? "1 print" : "\(printCount) prints")
                    .font(.system(size: 14))
                    .foregroundStyle(ShareCardColor.secondary)
                Spacer()
                ShareCardFooter()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(width: 390)
        .background(ShareCardColor.background)
    }
}

// MARK: - Film Roll Share Preview Sheet

struct FilmRollSharePreviewSheet: View {
    let roll: FilmRoll
    let printCount: Int
    @Environment(\.dismiss) private var dismiss
    @State private var thumb: UIImage? = nil
    @State private var shareItems: [Any]? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack {
                    Color(.systemGroupedBackground).ignoresSafeArea()
                    if let thumb {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .black.opacity(0.35), radius: 16, y: 6)
                            .padding(24)
                    } else {
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(spacing: 12) {
                    Button {
                        Task { @MainActor in
                            let renderer = ImageRenderer(
                                content: FilmRollShareCardView(roll: roll, printCount: printCount)
                            )
                            renderer.scale = 3.0
                            if let img = renderer.uiImage, let url = saveToTemp(img) {
                                shareItems = [url]
                            }
                        }
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.bar)
            }
            .navigationTitle("Share Film Roll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task { await renderThumb() }
        .sheet(isPresented: .init(
            get: { shareItems != nil },
            set: { if !$0 { shareItems = nil } }
        )) {
            if let items = shareItems {
                ActivityViewController(items: items)
            }
        }
    }

    @MainActor
    private func renderThumb() async {
        let r = ImageRenderer(content: FilmRollShareCardView(roll: roll, printCount: printCount))
        r.scale = 1.5
        thumb = r.uiImage
    }

    private func saveToTemp(_ image: UIImage) -> URL? {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let dateStr = df.string(from: roll.date)

        let base = roll.name.isEmpty ? roll.film : roll.name
        let safeName = base
            .components(separatedBy: CharacterSet.alphanumerics
                .union(CharacterSet(charactersIn: " ")).inverted)
            .joined()
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "_")

        let filename = safeName.isEmpty
            ? "\(dateStr)_filmroll.jpg"
            : "\(dateStr)_\(safeName).jpg"

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        guard let data = image.jpegData(compressionQuality: 0.92) else { return nil }
        try? data.write(to: url, options: .atomic)
        return url
    }
}

// MARK: - Film Dev Step Form

struct FilmDevStepFormView: View {
    @Environment(\.dismiss) private var dismiss

    var isNew: Bool = true
    var existingName: String = ""
    var existingSeconds: Int = 60
    var existingAgitation: AgitationScheme? = nil
    var onSave: (String, Int, AgitationScheme?) -> Void

    @State private var name: String = ""
    @State private var minutes: Int = 1
    @State private var seconds: Int = 0
    @State private var agitationEnabled: Bool = false
    @State private var agitationInitial: Int = 0
    @State private var agitationInterval: Int = 30
    @State private var agitationDuration: Int = 10

    var body: some View {
        NavigationStack {
            Form {
                Section("Step") {
                    TextField("Name (optional)", text: $name)
                }
                Section("Duration") {
                    Stepper("\(minutes) min", value: $minutes, in: 0...99)
                    Stepper("\(seconds) sec", value: $seconds, in: 0...59)
                }
                Section {
                    Toggle("Agitation", isOn: $agitationEnabled.animation())
                    if agitationEnabled {
                        Stepper(
                            agitationInitial == 0 ? "Initial: none" : "Initial: \(agitationInitial)s continuous",
                            value: $agitationInitial, in: 0...120, step: 15
                        )
                        Stepper("Every: \(agitationInterval)s", value: $agitationInterval, in: 10...120, step: 10)
                        Stepper("For: \(agitationDuration)s", value: $agitationDuration, in: 5...30, step: 5)
                    }
                }
            }
            .navigationTitle(isNew ? "New Step" : "Edit Step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let scheme: AgitationScheme? = agitationEnabled
                            ? AgitationScheme(
                                initialSeconds: agitationInitial,
                                intervalSeconds: agitationInterval,
                                durationSeconds: agitationDuration)
                            : nil
                        onSave(name.trimmingCharacters(in: .whitespaces), minutes * 60 + seconds, scheme)
                        dismiss()
                    }
                    .disabled(minutes == 0 && seconds == 0)
                }
            }
            .onAppear {
                name = existingName
                minutes = existingSeconds / 60
                seconds = existingSeconds % 60
                if let a = existingAgitation {
                    agitationEnabled = true
                    agitationInitial = a.initialSeconds
                    agitationInterval = a.intervalSeconds
                    agitationDuration = a.durationSeconds
                }
            }
        }
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

    @State private var status: FilmRollStatus = .loaded
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
                    Picker("Status", selection: $status) {
                        ForEach(FilmRollStatus.allCases, id: \.self) { s in
                            Label(s.label, systemImage: s.icon).tag(s)
                        }
                    }
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
                    status = r.rollStatus
                }
            }
            .sheet(isPresented: $pickingFilmStock) { EquipmentPickerView(type: .filmStock, selection: $film) }
            .sheet(isPresented: $pickingDeveloper) { EquipmentPickerView(type: .developer, selection: $developer) }
            .sheet(isPresented: $pickingCamera)    { EquipmentPickerView(type: .camera,    selection: $camera) }
            .sheet(isPresented: $pickingLens)      { EquipmentPickerView(type: .lens,      selection: $lens) }
            
        }
    }

    private func save() {
        let trimName  = name.trimmingCharacters(in: .whitespaces)
        let trimNotes = notes.trimmingCharacters(in: .whitespaces)
        if let r = roll {
            r.name = trimName
            r.date = date
            r.filmType = filmType
            r.film = film
            r.developer = developer
            r.camera = camera
            r.lens = lens
            r.notes = trimNotes
            if status != r.rollStatus {
                r.setStatus(status)
            }
        } else {
            let r = FilmRoll(
                name: trimName, filmType: filmType, film: film,
                camera: camera, lens: lens, developer: developer, notes: trimNotes
            )
            r.date = date
            r.loadedAt = nil
            r.setStatus(status, at: date)
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
                            Image(systemName: "checkmark").foregroundStyle(.tint)
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
                                    BadgeView(text: roll.filmType)
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
                                Image(systemName: "checkmark").foregroundStyle(.tint)
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
