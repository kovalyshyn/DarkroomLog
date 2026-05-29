import SwiftUI
import SwiftData

// MARK: - Chemistry list

struct ChemistryView: View {
    @Query(sort: \ChemBatch.name) private var batches: [ChemBatch]
    @Environment(\.modelContext) private var context
    @State private var searchText = ""
    @State private var showAddForm = false

    private var filtered: [ChemBatch] {
        guard !searchText.isEmpty else { return batches }
        let q = searchText.lowercased()
        return batches.filter {
            $0.name.lowercased().contains(q) || $0.notes.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { batch in
                    NavigationLink {
                        ChemBatchDetailView(batch: batch)
                    } label: {
                        ChemBatchRow(batch: batch)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            batch.usedUnits += 1
                        } label: {
                            Label("+1", systemImage: "plus")
                        }
                        .tint(.blue)

                        Button {
                            batch.mixedOn = Date()
                            batch.usedUnits = 0
                        } label: {
                            Label("Renew", systemImage: "arrow.counterclockwise")
                        }
                        .tint(.orange)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            context.delete(batch)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Name, notes…")
            .navigationTitle("Chemistry")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddForm = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .darkroomOverflowMenu()
            .overlay {
                if batches.isEmpty {
                    ContentUnavailableView(
                        "No Chemistry",
                        systemImage: "flask",
                        description: Text("Add your first chemical batch.")
                    )
                }
            }
        }
        .sheet(isPresented: $showAddForm) {
            ChemBatchFormSheet(batch: nil)
        }
    }
}

// MARK: - List row

struct ChemBatchRow: View {
    let batch: ChemBatch

    private var usagePercent: Double { Double(batch.usedUnits) / Double(max(1, batch.maxUnits)) }
    private var expiryDate: Date {
        Calendar.current.date(byAdding: .month, value: batch.expiryMonths, to: batch.mixedOn) ?? batch.mixedOn
    }
    private var isExpired: Bool { Date() >= expiryDate }
    private var daysLeft: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0)
    }
    private var statusColor: Color {
        if isExpired || usagePercent > 0.9 { return .red }
        if daysLeft < 14 || usagePercent > 0.75 { return .orange }
        return .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(batch.name)
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
            }

            ProgressView(value: min(1.0, usagePercent))
                .tint(statusColor)

            HStack {
                Text("\(batch.usedUnits) / \(batch.maxUnits) rolls")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Group {
                    if isExpired {
                        Text("Expired")
                            .foregroundStyle(.red)
                    } else if daysLeft < 14 {
                        Text("Expires in \(daysLeft)d")
                            .foregroundStyle(.orange)
                    } else {
                        Text("Until \(expiryDate.formatted(date: .abbreviated, time: .omitted))")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Detail view

struct ChemBatchDetailView: View {
    @Bindable var batch: ChemBatch
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    private var usagePercent: Double { Double(batch.usedUnits) / Double(max(1, batch.maxUnits)) }
    private var expiryDate: Date {
        Calendar.current.date(byAdding: .month, value: batch.expiryMonths, to: batch.mixedOn) ?? batch.mixedOn
    }
    private var isExpired: Bool { Date() >= expiryDate }
    private var daysLeft: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0)
    }
    private var statusColor: Color {
        if isExpired || usagePercent > 0.9 { return .red }
        if daysLeft < 14 || usagePercent > 0.75 { return .orange }
        return .green
    }

    var body: some View {
        List {
            // Progress
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(batch.usedUnits)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                        Text("/ \(batch.maxUnits) rolls")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(min(1.0, usagePercent) * 100))%")
                            .font(.title2.bold())
                            .foregroundStyle(statusColor)
                    }
                    ProgressView(value: min(1.0, usagePercent))
                        .tint(statusColor)
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
                .padding(.vertical, 6)

                // Expiry status
                if isExpired {
                    Label("Expired", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                } else if daysLeft < 14 {
                    Label(
                        "Expires in \(daysLeft) days — \(expiryDate.formatted(date: .abbreviated, time: .omitted))",
                        systemImage: "clock"
                    )
                    .foregroundStyle(.orange)
                } else {
                    Label(
                        "Expires \(expiryDate.formatted(date: .abbreviated, time: .omitted))",
                        systemImage: "calendar"
                    )
                    .foregroundStyle(.secondary)
                }
            }

            // Details
            Section("Details") {
                LabeledContent("Mixed on", value: batch.mixedOn.formatted(date: .long, time: .omitted))
                LabeledContent("Capacity", value: "\(batch.maxUnits) rolls")
                LabeledContent("Shelf life", value: "\(batch.expiryMonths) months")
                if !batch.notes.isEmpty {
                    Text(batch.notes)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            // Actions
            Section {
                Button {
                    batch.usedUnits += 1
                } label: {
                    Label("+1 roll used", systemImage: "plus.circle")
                }

                Button {
                    batch.usedUnits = max(0, batch.usedUnits - 1)
                } label: {
                    Label("−1 roll (correction)", systemImage: "minus.circle")
                }
                .disabled(batch.usedUnits <= 0)
                .foregroundStyle(batch.usedUnits > 0 ? .primary : .secondary)

                Button {
                    batch.mixedOn = Date()
                    batch.usedUnits = 0
                } label: {
                    Label("Renewed — reset to fresh batch", systemImage: "arrow.counterclockwise")
                }
                .foregroundStyle(.orange)
            }

            // Delete
            Section {
                Button {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle(batch.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEdit = true }
            }
        }
        .alert("Delete \(batch.name)?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                context.delete(batch)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showEdit) {
            ChemBatchFormSheet(batch: batch)
        }
    }
}

// MARK: - Add / Edit form sheet

struct ChemBatchFormSheet: View {
    let batch: ChemBatch?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var notes = ""
    @State private var mixedOn = Date()
    @State private var maxUnits = 20
    @State private var expiryMonths = 6

    private var isNew: Bool { batch == nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Chemical") {
                    TextField("Name (e.g. D76, C-41 Dev…)", text: $name)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section {
                    DatePicker("Mixed on", selection: $mixedOn, displayedComponents: .date)
                    Stepper("Capacity: \(maxUnits) rolls", value: $maxUnits, in: 1...500)
                } header: {
                    Text("Batch")
                } footer: {
                    Text("Number of film rolls this batch can process before exhaustion.")
                        .font(.caption)
                }
                Section("Shelf life after mixing") {
                    Picker("Expires after", selection: $expiryMonths) {
                        Text("1 month").tag(1)
                        Text("3 months").tag(3)
                        Text("6 months").tag(6)
                        Text("9 months").tag(9)
                        Text("12 months").tag(12)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(isNew ? "New Chemical" : "Edit Chemical")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedName = name.trimmingCharacters(in: .whitespaces)
                        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)
                        if let batch {
                            batch.name = trimmedName
                            batch.notes = trimmedNotes
                            batch.mixedOn = mixedOn
                            batch.maxUnits = maxUnits
                            batch.expiryMonths = expiryMonths
                        } else {
                            let b = ChemBatch(
                                name: trimmedName,
                                notes: trimmedNotes,
                                mixedOn: mixedOn,
                                maxUnits: maxUnits,
                                expiryMonths: expiryMonths
                            )
                            context.insert(b)
                        }
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let batch {
                    name         = batch.name
                    notes        = batch.notes
                    mixedOn      = batch.mixedOn
                    maxUnits     = batch.maxUnits
                    expiryMonths = batch.expiryMonths
                }
            }
        }
    }
}
