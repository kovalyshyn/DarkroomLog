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
                ForEach(sortedPrints) { print in
                    NavigationLink(destination: PrintDetailView(print: print)) {
                        PrintRowView(print: print)
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
                Text("\(print.exposureSeconds) sec")
                    .font(.headline)

                if !print.notes.isEmpty {
                    Text(print.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Text(print.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}
