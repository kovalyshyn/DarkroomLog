import SwiftUI
import SwiftData
import PhotosUI
import Combine

struct AddPrintView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let session: Session

    @State private var printName: String = ""
    @State private var selectedRoll: FilmRoll? = nil
    @State private var pickingRoll = false
    @State private var exposureTimes: [Int] = [10]
    @State private var aperture: String = ""
    @State private var rating: Int = 0
    @State private var notes: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var showCamera = false
    @State private var showLibraryPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Print") {
                    TextField("Name (optional)", text: $printName)
                    HStack {
                        Text("Rating")
                        Spacer()
                        StarRatingView(rating: $rating)
                    }
                }

                Section("Film Roll") {
                    Button {
                        pickingRoll = true
                    } label: {
                        HStack {
                            Text(selectedRoll.map { rollLabel($0) } ?? "None")
                                .foregroundStyle(selectedRoll == nil ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)
                }

                Section("Exposure") {
                    HStack {
                        Text("Aperture")
                        Spacer()
                        TextField("f/8", text: $aperture)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                            .frame(width: 80)
                    }

                    ForEach(exposureTimes.indices, id: \.self) { i in
                        HStack {
                            Text("Step \(i + 1)")
                            Spacer()
                            Text("\(exposureTimes[i]) sec")
                                .foregroundStyle(.secondary)
                            Stepper("", value: $exposureTimes[i], in: 1...3600)
                                .labelsHidden()
                        }
                    }
                    .onDelete { exposureTimes.remove(atOffsets: $0) }

                    Button { exposureTimes.append(10) } label: {
                        Label("Add step", systemImage: "plus")
                    }
                }

                Section("Notes") {
                    TextField("Dodging, burning, grade, observations...", text: $notes, axis: .vertical)
                        .lineLimit(4...8)
                }

                Section("Photo") {
                    if let data = photoData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Menu {
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                Button { showCamera = true } label: {
                                    Label("Take Photo", systemImage: "camera")
                                }
                            }
                            Button { showLibraryPicker = true } label: {
                                Label("Choose from Library", systemImage: "photo.on.rectangle")
                            }
                        } label: {
                            Text("Change photo…").foregroundStyle(.secondary)
                        }

                        Button("Remove photo", role: .destructive) {
                            photoData = nil
                            selectedPhoto = nil
                        }
                    } else {
                        Menu {
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                Button { showCamera = true } label: {
                                    Label("Take Photo", systemImage: "camera")
                                }
                            }
                            Button { showLibraryPicker = true } label: {
                                Label("Choose from Library", systemImage: "photo.on.rectangle")
                            }
                        } label: {
                            Label("Add photo of print", systemImage: "camera")
                        }
                    }
                }
            }
            .navigationTitle("New Print")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .sheet(isPresented: $pickingRoll) {
                FilmRollPickerView(selection: $selectedRoll)
            }
            .photosPicker(isPresented: $showLibraryPicker, selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        photoData = compressedPhotoData(image)
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraImagePicker(imageData: $photoData)
            }
        }
    }

    private func rollLabel(_ roll: FilmRoll) -> String {
        let name = roll.name.isEmpty ? roll.film : roll.name
        return name.isEmpty ? roll.filmType : "\(name) (\(roll.filmType))"
    }

    private func save() {
        let newPrint = Print(exposureTimes: exposureTimes, notes: notes.trimmingCharacters(in: .whitespaces))
        newPrint.name = printName.trimmingCharacters(in: .whitespaces)
        newPrint.aperture = aperture.trimmingCharacters(in: .whitespaces)
        newPrint.rating = rating
        newPrint.photoData = photoData
        newPrint.filmRoll = selectedRoll
        newPrint.session = session
        session.prints.append(newPrint)
        context.insert(newPrint)
        dismiss()
    }
}

struct PrintDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var print: Print
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showFullscreen = false
    @State private var showWashTimerPicker = false
    @State private var pickingRoll = false
    @State private var showCamera = false
    @State private var showLibraryPicker = false
    @State private var times: [Int] = []
    @State private var activeWashTimer: WashTimer? = nil
    @State private var now = Date()
    @State private var showSharePreview = false
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Form {
            Section("Print") {
                TextField("Name (optional)", text: $print.name)
                HStack {
                    Text("Rating")
                    Spacer()
                    StarRatingView(rating: $print.rating)
                }
            }

            Section("Film Roll") {
                if let roll = print.filmRoll {
                    NavigationLink(destination: FilmRollDetailView(roll: roll)) {
                        Text(rollLabel(roll))
                    }
                    Button("Change roll…") { pickingRoll = true }
                        .foregroundStyle(.secondary)
                } else {
                    Button {
                        pickingRoll = true
                    } label: {
                        HStack {
                            Text("None").foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }

            Section("Exposure") {
                HStack {
                    Text("Aperture")
                    Spacer()
                    TextField("f/8", text: $print.aperture)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                        .frame(width: 80)
                }

                ForEach(times.indices, id: \.self) { i in
                    HStack {
                        Text("Step \(i + 1)")
                        Spacer()
                        Text("\(times[i]) sec")
                            .foregroundStyle(.secondary)
                        Stepper("", value: $times[i], in: 1...3600)
                            .labelsHidden()
                    }
                }
                .onDelete { times.remove(atOffsets: $0) }

                Button { times.append(10) } label: {
                    Label("Add step", systemImage: "plus")
                }

                if !times.isEmpty {
                    NavigationLink(destination: TimerView(intervals: times)) {
                        Label("Start Timer", systemImage: "timer")
                            .foregroundStyle(.red)
                    }
                }
            }

            Section("Wash Timer") {
                if let wt = activeWashTimer {
                    HStack {
                        Label(formatRemaining(wt.endDate.timeIntervalSince(now)), systemImage: "hourglass")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        Spacer()
                        Button("Stop", role: .destructive) {
                            NotificationManager.shared.cancelTimer(id: wt.id)
                            activeWashTimer = nil
                        }
                    }
                } else {
                    Button {
                        NotificationManager.shared.requestPermission()
                        showWashTimerPicker = true
                    } label: {
                        Label("Start Wash Timer", systemImage: "hourglass")
                    }
                }
            }

            Section("Notes") {
                TextField("Notes...", text: $print.notes, axis: .vertical)
                    .lineLimit(4...10)
            }

            Section("Photo") {
                if let data = print.photoData, let uiImage = UIImage(data: data) {
                    Button {
                        showFullscreen = true
                    } label: {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    Menu {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button { showCamera = true } label: {
                                Label("Take Photo", systemImage: "camera")
                            }
                        }
                        Button { showLibraryPicker = true } label: {
                            Label("Choose from Library", systemImage: "photo.on.rectangle")
                        }
                    } label: {
                        Text("Change photo…").foregroundStyle(.secondary)
                    }

                    Button("Remove photo", role: .destructive) {
                        print.photoData = nil
                        selectedPhoto = nil
                    }
                } else {
                    Menu {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button { showCamera = true } label: {
                                Label("Take Photo", systemImage: "camera")
                            }
                        }
                        Button { showLibraryPicker = true } label: {
                            Label("Choose from Library", systemImage: "photo.on.rectangle")
                        }
                    } label: {
                        Label("Add photo of print", systemImage: "camera")
                    }
                }
            }
        }
        .navigationTitle(print.name.isEmpty ? "Print detail" : print.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSharePreview = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showSharePreview) {
            PrintSharePreviewSheet(print: print)
        }
        .onAppear {
            let existing = print.exposureTimes
            if existing.isEmpty && print.exposureSeconds > 0 {
                times = [print.exposureSeconds]
                print.exposureTimesData = String(print.exposureSeconds)
            } else {
                times = existing
            }
            activeWashTimer = NotificationManager.shared.activeTimer(for: print.id.uuidString)
        }
        .onChange(of: times) { _, newTimes in
            print.exposureTimes = newTimes
            print.exposureSeconds = newTimes.first ?? 0
        }
        .onDisappear {
            print.name = print.name.trimmingCharacters(in: .whitespaces)
            print.aperture = print.aperture.trimmingCharacters(in: .whitespaces)
            print.notes = print.notes.trimmingCharacters(in: .whitespaces)
        }
        .onReceive(ticker) { date in
            now = date
            activeWashTimer = NotificationManager.shared.activeTimer(for: print.id.uuidString)
        }
        .confirmationDialog("Wash Timer", isPresented: $showWashTimerPicker, titleVisibility: .visible) {
            Button("10 minutes") { scheduleWash(minutes: 10) }
            Button("20 minutes") { scheduleWash(minutes: 20) }
            Button("30 minutes") { scheduleWash(minutes: 30) }
            Button("40 minutes") { scheduleWash(minutes: 40) }
            Button("60 minutes") { scheduleWash(minutes: 60) }
            Button("Cancel", role: .cancel) { }
        }
        .fullScreenCover(isPresented: $showFullscreen) {
            if let data = print.photoData, let uiImage = UIImage(data: data) {
                PhotoFullscreenView(uiImage: uiImage) {
                    showFullscreen = false
                }
            }
        }
        .sheet(isPresented: $pickingRoll) {
            FilmRollPickerView(selection: $print.filmRoll)
        }
        .photosPicker(isPresented: $showLibraryPicker, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    print.photoData = compressedPhotoData(image)
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraImagePicker(imageData: $print.photoData)
        }
    }

    private func rollLabel(_ roll: FilmRoll) -> String {
        let name = roll.name.isEmpty ? roll.film : roll.name
        let type_ = roll.filmType
        return name.isEmpty ? type_ : "\(name) (\(type_))"
    }

    private func scheduleWash(minutes: Int) {
        let label = print.name.isEmpty ? print.createdAt.formatted(date: .omitted, time: .shortened) : print.name
        NotificationManager.shared.scheduleWashTimer(
            printId: print.id.uuidString,
            label: label,
            minutes: minutes
        )
        activeWashTimer = NotificationManager.shared.activeTimer(for: print.id.uuidString)
    }

    private func formatRemaining(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds))
        let m = s / 60
        let sec = s % 60
        return String(format: "%d:%02d remaining", m, sec)
    }
}

struct EditSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var session: Session

    @State private var pickingEnlarger = false
    @State private var pickingLens = false
    @State private var pickingPaper = false
    @State private var pickingDeveloper = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Session name") {
                    TextField("Name", text: $session.name)
                }
                Section("Equipment") {
                    EquipmentRow(label: "Enlarger",  value: session.enlarger)  { pickingEnlarger = true }
                    EquipmentRow(label: "Lens",      value: session.lens)      { pickingLens = true }
                    EquipmentRow(label: "Paper",     value: session.paper)     { pickingPaper = true }
                    EquipmentRow(label: "Developer", value: session.developer) { pickingDeveloper = true }
                }

                Section("Comment") {
                    TextField("Notes on the session…", text: $session.comment, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        session.name = session.name.trimmingCharacters(in: .whitespaces)
                        session.comment = session.comment.trimmingCharacters(in: .whitespaces)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $pickingEnlarger)  { EquipmentPickerView(type: .enlarger,  selection: $session.enlarger) }
            .sheet(isPresented: $pickingLens)      { EquipmentPickerView(type: .lens,      selection: $session.lens) }
            .sheet(isPresented: $pickingPaper)     { EquipmentPickerView(type: .paper,     selection: $session.paper) }
            .sheet(isPresented: $pickingDeveloper) { EquipmentPickerView(type: .developer, selection: $session.developer) }
        }
    }
}

// MARK: - Photo compression

private func compressedPhotoData(_ image: UIImage, maxDimension: CGFloat = 1200, quality: CGFloat = 0.78) -> Data? {
    let size = image.size
    let longest = max(size.width, size.height)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1.0  // render at 1:1, not at device 3× scale
    if longest > maxDimension {
        let scale = maxDimension / longest
        let newSize = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: quality)
    }
    // Image is already small enough — just recompress
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    let redrawn = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
    return redrawn.jpegData(compressionQuality: quality)
}

// MARK: - Camera picker

struct CameraImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraImagePicker
        init(_ parent: CameraImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.imageData = compressedPhotoData(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Star rating

struct StarRatingView: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...3, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundStyle(star <= rating ? Color.yellow : Color.secondary)
                    .onTapGesture { rating = (rating == star) ? 0 : star }
            }
        }
        .font(.system(size: 20))
    }
}

// MARK: - Share card

enum ShareLayout: CaseIterable {
    case portrait, landscape
}

struct PrintShareCardView: View {
    let print: Print
    var layout: ShareLayout = .portrait

    private var exposureText: String {
        let times = print.exposureTimes
        if times.isEmpty { return print.exposureSeconds > 0 ? "\(print.exposureSeconds)s" : "" }
        if times.count == 1 { return "\(times[0])s" }
        return times.enumerated().map { "Step \($0.offset + 1): \($0.element)s" }.joined(separator: "  ·  ")
    }

    var body: some View {
        switch layout {
        case .portrait: portraitCard
        case .landscape: landscapeCard
        }
    }

    // Portrait: photo top (full, no crop), text below
    private var portraitCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let data = print.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 390)
            }
            infoBlock(compact: false)
            cardFooter
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
        }
        .frame(width: 390)
        .background(Color(white: 0.07))
    }

    // Landscape: photo left (200pt), text right (190pt)
    // Height is determined by text content; photo fills via background
    private var landscapeCard: some View {
        let hasPhoto = print.photoData != nil
        let photoWidth: CGFloat = 200
        let textWidth: CGFloat = hasPhoto ? 190 : 390

        return HStack(alignment: .top, spacing: 0) {
            if hasPhoto {
                Color.clear.frame(width: photoWidth)
            }
            VStack(alignment: .leading, spacing: 0) {
                infoBlock(compact: true)
                Spacer(minLength: 12)
                cardFooter
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
            }
            .frame(width: textWidth)
        }
        .frame(width: 390)
        .background(
            HStack(spacing: 0) {
                if let data = print.photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: photoWidth)
                        .clipped()
                }
                Color(white: 0.07)
            }
        )
    }

    @ViewBuilder
    private func infoBlock(compact: Bool) -> some View {
        let p: CGFloat     = compact ? 14 : 20
        let title: CGFloat = compact ? 17 : 22
        let body: CGFloat  = compact ? 12 : 14
        let tag: CGFloat   = compact ? 8  : 9
        let icon: CGFloat  = compact ? 11 : 13
        let gap: CGFloat   = compact ? 10 : 14

        VStack(alignment: .leading, spacing: gap) {
            // Name + stars
            if !print.name.isEmpty || print.rating > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    if !print.name.isEmpty {
                        Text(print.name)
                            .font(.system(size: title, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                    }
                    if print.rating > 0 {
                        HStack(spacing: 3) {
                            ForEach(1...3, id: \.self) { star in
                                Image(systemName: star <= print.rating ? "star.fill" : "star")
                                    .font(.system(size: compact ? 10 : 13))
                                    .foregroundStyle(star <= print.rating ? Color.yellow : Color.white.opacity(0.25))
                            }
                        }
                    }
                }
            }

            Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)

            // Film Roll
            if let roll = print.filmRoll {
                let rollName = [roll.name, roll.film, roll.filmType]
                    .filter { !$0.isEmpty }
                    .joined(separator: " · ")
                if !rollName.isEmpty {
                    row("film", "Film Roll", rollName, body: body, tag: tag, icon: icon)
                }
            }

            // Session equipment
            let s = print.session
            Group {
                if let v = s?.enlarger,  !v.isEmpty { row("viewfinder",   "Enlarger",  v, body: body, tag: tag, icon: icon) }
                if let v = s?.lens,      !v.isEmpty { row("camera.aperture", "Lens",   v, body: body, tag: tag, icon: icon) }
                if let v = s?.paper,     !v.isEmpty { row("doc.plaintext", "Paper",    v, body: body, tag: tag, icon: icon) }
                if let v = s?.developer, !v.isEmpty { row("flask",         "Developer",v, body: body, tag: tag, icon: icon) }
            }

            // Exposure
            let ap = print.aperture
            let ex = exposureText
            if !ap.isEmpty || !ex.isEmpty {
                Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
                if !ap.isEmpty { row("f.cursive", "Aperture", ap, body: body, tag: tag, icon: icon) }
                if !ex.isEmpty { row("timer",     "Exposure", ex, body: body, tag: tag, icon: icon) }
            }
        }
        .padding(p)
    }

    private var cardFooter: some View {
        HStack {
            Spacer()
            Text("Generated with DarkroomLog")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.25))
        }
    }

    private func row(_ sfIcon: String, _ label: String, _ value: String,
                     body: CGFloat, tag: CGFloat, icon: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: sfIcon)
                .font(.system(size: icon))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 16)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 1) {
                Text(label.uppercased())
                    .font(.system(size: tag, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
                    .tracking(0.8)
                Text(value)
                    .font(.system(size: body))
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Share preview sheet

struct PrintSharePreviewSheet: View {
    let print: Print
    @Environment(\.dismiss) private var dismiss
    @State private var layout: ShareLayout = .portrait
    @State private var thumbPortrait: UIImage? = nil
    @State private var thumbLandscape: UIImage? = nil
    @State private var shareItems: [Any]? = nil

    private var currentThumb: UIImage? {
        layout == .portrait ? thumbPortrait : thumbLandscape
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Preview
                ZStack {
                    Color(.systemGroupedBackground).ignoresSafeArea()
                    if let thumb = currentThumb {
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

                // Controls
                VStack(spacing: 12) {
                    Picker("Layout", selection: $layout) {
                        Text("Portrait").tag(ShareLayout.portrait)
                        Text("Landscape").tag(ShareLayout.landscape)
                    }
                    .pickerStyle(.segmented)

                    Button {
                        Task { @MainActor in
                            let renderer = ImageRenderer(
                                content: PrintShareCardView(print: print, layout: layout)
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
            .navigationTitle("Share Print")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task { await renderThumbs() }
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
    private func renderThumbs() async {
        let rp = ImageRenderer(content: PrintShareCardView(print: print, layout: .portrait))
        rp.scale = 1.5
        thumbPortrait = rp.uiImage

        let rl = ImageRenderer(content: PrintShareCardView(print: print, layout: .landscape))
        rl.scale = 1.5
        thumbLandscape = rl.uiImage
    }

    private func saveToTemp(_ image: UIImage) -> URL? {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd_HH-mm"
        let dateStr = df.string(from: print.createdAt)

        let safeName = print.name
            .components(separatedBy: CharacterSet.alphanumerics
                .union(CharacterSet(charactersIn: " ")).inverted)
            .joined()
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "_")

        let filename = safeName.isEmpty
            ? "\(dateStr)_darkroomlog.jpg"
            : "\(dateStr)_\(safeName).jpg"

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        guard let data = image.jpegData(compressionQuality: 0.92) else { return nil }
        try? data.write(to: url, options: .atomic)
        return url
    }
}

// MARK: - Activity view controller wrapper

struct ActivityViewController: UIViewControllerRepresentable {
    let items: [Any]
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.completionWithItemsHandler = { _, _, _, _ in dismiss() }
        return vc
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {
        if let popover = vc.popoverPresentationController {
            popover.sourceView = vc.view
            popover.sourceRect = CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
    }
}

// MARK: - Fullscreen photo viewer

struct PhotoFullscreenView: View {
    let uiImage: UIImage
    let onClose: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = max(1, lastScale * value)
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if scale > 1 {
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring()) {
                        scale = 1
                        lastScale = 1
                        offset = .zero
                        lastOffset = .zero
                    }
                }

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding()
            }
        }
    }
}
