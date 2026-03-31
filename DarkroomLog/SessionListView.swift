import SwiftUI
import SwiftData
import Combine

struct SessionListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    @State private var showNewSession = false
    @State private var washTimers: [WashTimer] = []
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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
            .onAppear {
                washTimers = NotificationManager.shared.loadTimers()
            }
            .onReceive(ticker) { _ in
                washTimers = NotificationManager.shared.loadTimers()
            }
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
