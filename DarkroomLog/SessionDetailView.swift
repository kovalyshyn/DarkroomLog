import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var session: Session
    @State private var showAddPrint = false
    @State private var showEditSession = false

    var sortedPrints: [Print] {
        session.prints.sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        List {
            Section("Equipment") {
                equipmentRow("Enlarger",  value: session.enlarger)
                equipmentRow("Lens",      value: session.lens)
                equipmentRow("Paper",     value: session.paper)
                equipmentRow("Developer", value: session.developer)
            }

            if !session.comment.isEmpty {
                Section("Comment") {
                    Text(session.comment)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Prints") {
                ForEach(sortedPrints) { entry in
                    NavigationLink(destination: PrintDetailView(print: entry)) {
                        PrintRowView(print: entry)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            duplicatePrint(entry)
                        } label: {
                            Label("Duplicate", systemImage: "plus.square.on.square")
                        }
                        .tint(.indigo)
                    }
                }
                .onDelete(perform: deletePrints)

                Button {
                    showAddPrint = true
                } label: {
                    Label("Add Print", systemImage: "plus")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(session.name.isEmpty ? "Session" : session.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: TimerView()) {
                    Image(systemName: "timer")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEditSession = true }
            }
        }
        .sheet(isPresented: $showAddPrint) {
            AddPrintView(session: session)
        }
        .sheet(isPresented: $showEditSession) {
            EditSessionView(session: session)
        }
    }

    @ViewBuilder
    private func equipmentRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value.isEmpty ? "—" : value)
                .foregroundStyle(value.isEmpty ? .tertiary : .primary)
        }
        .font(.subheadline)
    }

    private func deletePrints(at offsets: IndexSet) {
        let sorted = sortedPrints
        for index in offsets {
            context.delete(sorted[index])
        }
    }

    private func duplicatePrint(_ original: Print) {
        let copy = Print(exposureTimes: original.exposureTimes, notes: original.notes)
        copy.name = original.name
        copy.aperture = original.aperture
        copy.rating = original.rating
        copy.filmRoll = original.filmRoll
        copy.session = session
        session.prints.append(copy)
        context.insert(copy)
    }
}

struct PrintRowView: View {
    let print: Print

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let data = print.photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.15))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundStyle(.tertiary)
                                .font(.system(size: 16))
                        )
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                let times = print.exposureTimes
                let timeStr = times.isEmpty ? "\(print.exposureSeconds) sec" : times.map { "\($0)s" }.joined(separator: " · ")
                HStack {
                    Text(print.name.isEmpty ? timeStr : print.name)
                        .font(.headline)
                    Spacer()
                    if print.rating > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...3, id: \.self) { star in
                                Image(systemName: star <= print.rating ? "star.fill" : "star")
                                    .foregroundStyle(star <= print.rating ? Color.yellow : Color.clear)
                                    .font(.system(size: 10))
                            }
                        }
                    }
                }
                if !print.name.isEmpty {
                    Text(timeStr)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !print.aperture.isEmpty {
                    Text(print.aperture)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(print.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}
