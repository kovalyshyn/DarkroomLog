import SwiftUI
import SwiftData

struct SessionListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    @State private var showNewSession = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(sessions) { session in
                    NavigationLink(destination: SessionDetailView(session: session)) {
                        SessionRowView(session: session)
                    }
                }
                .onDelete(perform: deleteSessions)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Darkroom")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: TimerView()) {
                        Image(systemName: "timer")
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        showNewSession = true
                    } label: {
                        Label("New Session", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewSession) {
                NewSessionView()
            }
        }
    }

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            context.delete(sessions[index])
        }
    }
}

struct SessionRowView: View {
    let session: Session

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.name.isEmpty ? "Untitled session" : session.name)
                    .font(.headline)
                Spacer()
                Text("\(session.prints.count) prints")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.12))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
            HStack(spacing: 4) {
                if !session.enlarger.isEmpty {
                    Text(session.enlarger)
                    Text("·").foregroundStyle(.secondary)
                }
                if !session.lens.isEmpty {
                    Text(session.lens)
                    Text("·").foregroundStyle(.secondary)
                }
                if !session.paper.isEmpty {
                    Text(session.paper)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)

            Text(session.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
