import SwiftUI
import SwiftData
import Combine

struct SessionListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    @State private var showNewSession = false
    @State private var washTimers: [WashTimer] = []
    @State private var searchText = ""
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var filteredSessions: [Session] {
        guard !searchText.isEmpty else { return sessions }
        let q = searchText.lowercased()
        return sessions.filter {
            $0.name.lowercased().contains(q) ||
            $0.enlarger.lowercased().contains(q) ||
            $0.lens.lowercased().contains(q) ||
            $0.paper.lowercased().contains(q) ||
            $0.developer.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if !washTimers.isEmpty {
                    Section("Wash Timers") {
                        ForEach(washTimers) { wt in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(wt.printLabel)
                                        .font(.subheadline)
                                    Text(formatRemaining(wt.remaining))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                }
                                Spacer()
                                Button {
                                    NotificationManager.shared.cancelTimer(id: wt.id)
                                    washTimers = NotificationManager.shared.loadTimers()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                ForEach(filteredSessions) { session in
                    NavigationLink(destination: SessionDetailView(session: session)) {
                        SessionRowView(session: session)
                    }
                }
                .onDelete(perform: deleteSessions)
            }
            .searchable(text: $searchText, prompt: "Name, paper, developer…")
            .listStyle(.insetGrouped)
            .navigationTitle("Darkroom")
            .overlay {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No Sessions",
                        systemImage: "photo.stack",
                        description: Text("Start your first darkroom session.")
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: TimerView()) {
                        Image(systemName: "timer")
                    }
                    .accessibilityLabel("Timer")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNewSession = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New session")
                }
            }
            .darkroomOverflowMenu()
            .onAppear {
                washTimers = NotificationManager.shared.loadTimers()
            }
            .onReceive(ticker) { _ in
                // No timers → nothing to refresh; avoids decoding UserDefaults every second.
                // New timers are picked up by onAppear when returning from a print detail.
                guard !washTimers.isEmpty else { return }
                washTimers = NotificationManager.shared.loadTimers()
            }
        }
        .sheet(isPresented: $showNewSession) {
            NewSessionView()
        }
    }

    private func formatRemaining(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds))
        let m = s / 60
        let sec = s % 60
        return String(format: "%d:%02d remaining", m, sec)
    }

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            context.delete(filteredSessions[index])
        }
    }
}

struct SessionRowView: View {
    let session: Session

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.name.isEmpty ? "Untitled session" : session.name)
                    .font(.headline)
                Spacer()
                Text("\(session.prints.count) prints")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.12))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }

            HStack(spacing: 8) {
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
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)

            Text(session.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}
