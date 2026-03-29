import SwiftUI
import SwiftData
import PhotosUI

struct AddPrintView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let session: Session

    @State private var exposureSeconds: Int = 0
    @State private var notes: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var showTimer = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Exposure") {
                    HStack {
                        Text("Time")
                        Spacer()
                        Text("\(exposureSeconds) sec")
                            .foregroundStyle(.secondary)
                        Stepper("", value: $exposureSeconds, in: 0...3600)
                            .labelsHidden()
                    }
                    NavigationLink(destination: TimerView(onStop: { seconds in
                        exposureSeconds = seconds
                    })) {
                        Label("Use Timer", systemImage: "timer")
                    }
                }

                Section("Notes") {
                    TextField("Dodging, burning, grade, observations...", text: $notes, axis: .vertical)
                        .lineLimit(4...8)
                }

                Section("Photo") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let data = photoData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Label("Add photo of print", systemImage: "camera")
                        }
                    }
                    .onChange(of: selectedPhoto) { _, newItem in
                        Task {
                            photoData = try? await newItem?.loadTransferable(type: Data.self)
                        }
                    }

                    if photoData != nil {
                        Button("Remove photo", role: .destructive) {
                            photoData = nil
                            selectedPhoto = nil
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
        }
    }

    private func save() {
        let newPrint = Print(exposureSeconds: exposureSeconds, notes: notes)
        newPrint.photoData = photoData
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

    var body: some View {
        Form {
            Section("Exposure") {
                HStack {
                    Text("Time")
                    Spacer()
                    Text("\(print.exposureSeconds) sec")
                        .foregroundStyle(.secondary)
                    Stepper("", value: $print.exposureSeconds, in: 0...3600)
                        .labelsHidden()
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

                    Button("Remove photo", role: .destructive) {
                        print.photoData = nil
                        selectedPhoto = nil
                    }
                } else {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Add photo of print", systemImage: "camera")
                    }
                    .onChange(of: selectedPhoto) { _, newItem in
                        Task {
                            print.photoData = try? await newItem?.loadTransferable(type: Data.self)
                        }
                    }
                }
            }
        }
        .navigationTitle("Print detail")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showFullscreen) {
            if let data = print.photoData, let uiImage = UIImage(data: data) {
                PhotoFullscreenView(uiImage: uiImage) {
                    showFullscreen = false
                }
            }
        }
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
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $pickingEnlarger)  { EquipmentPickerView(type: .enlarger,  selection: $session.enlarger) }
            .sheet(isPresented: $pickingLens)      { EquipmentPickerView(type: .lens,      selection: $session.lens) }
            .sheet(isPresented: $pickingPaper)     { EquipmentPickerView(type: .paper,     selection: $session.paper) }
            .sheet(isPresented: $pickingDeveloper) { EquipmentPickerView(type: .developer, selection: $session.developer) }
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
