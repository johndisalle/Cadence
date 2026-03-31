import SwiftUI
import SwiftData

struct RemindersImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var hasAccess = false
    @State private var isLoading = false
    @State private var reminders: [ImportableReminder] = []
    @State private var selectedIDs: Set<String> = []
    @State private var searchText = ""
    @State private var importComplete = false
    @State private var importedCount = 0
    @State private var importedLogCount = 0

    private var filteredReminders: [ImportableReminder] {
        if searchText.isEmpty { return reminders }
        return reminders.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        Group {
            if importComplete {
                successView
            } else if !hasAccess {
                permissionView
            } else if isLoading {
                loadingView
            } else if reminders.isEmpty {
                emptyView
            } else {
                selectionView
            }
        }
        .navigationTitle("Import Reminders")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Permission

    private var permissionView: some View {
        VStack(spacing: CadenceTheme.spacingLG) {
            Spacer()

            Image(systemName: "checklist")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(CadenceTheme.teal)

            VStack(spacing: CadenceTheme.spacingSM) {
                Text("Import from Reminders")
                    .font(.title3.weight(.semibold))

                Text("Cadence can scan your completed reminders to find recurring patterns and import them as events — with full history.")
                    .font(.subheadline)
                    .foregroundStyle(CadenceTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task {
                    hasAccess = await RemindersImportService.shared.requestAccess()
                    if hasAccess { await loadReminders() }
                }
            } label: {
                Label("Allow Access", systemImage: "lock.open.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(CadenceTheme.teal))
            }
            .padding(.horizontal, CadenceTheme.spacingXL)

            Text("Cadence only reads completed reminders.\nNo data leaves your device.")
                .font(.caption)
                .foregroundStyle(CadenceTheme.textTertiary)
                .multilineTextAlignment(.center)

            Spacer()
            Spacer()
        }
        .padding(CadenceTheme.spacingLG)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: CadenceTheme.spacingMD) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Scanning your reminders...")
                .font(.subheadline)
                .foregroundStyle(CadenceTheme.textSecondary)
        }
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: CadenceTheme.spacingLG) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(CadenceTheme.textTertiary)
            Text("No recurring patterns found")
                .font(.headline)
            Text("Cadence looks for reminders completed 2 or more times. Complete some reminders in Apple Reminders and try again.")
                .font(.subheadline)
                .foregroundStyle(CadenceTheme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(CadenceTheme.spacingLG)
    }

    // MARK: - Selection

    private var selectionView: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                Text("\(selectedIDs.count) selected")
                    .font(.subheadline)
                    .foregroundStyle(CadenceTheme.textSecondary)
                Spacer()
                Button(selectedIDs.count == reminders.count ? "Deselect All" : "Select All") {
                    if selectedIDs.count == reminders.count {
                        selectedIDs.removeAll()
                    } else {
                        selectedIDs = Set(reminders.map(\.id))
                    }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(CadenceTheme.teal)
            }
            .padding(.horizontal)
            .padding(.vertical, CadenceTheme.spacingSM)

            List {
                ForEach(filteredReminders) { reminder in
                    reminderRow(reminder)
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search reminders")

            // Import button
            Button {
                importSelected()
            } label: {
                Text("Import \(selectedIDs.count) Events")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule().fill(
                            selectedIDs.isEmpty
                            ? Color.gray.opacity(0.4)
                            : CadenceTheme.teal
                        )
                    )
            }
            .disabled(selectedIDs.isEmpty)
            .padding(.horizontal, CadenceTheme.spacingLG)
            .padding(.vertical, CadenceTheme.spacingSM)
        }
    }

    private func reminderRow(_ reminder: ImportableReminder) -> some View {
        let isSelected = selectedIDs.contains(reminder.id)
        return Button {
            if isSelected {
                selectedIDs.remove(reminder.id)
            } else {
                selectedIDs.insert(reminder.id)
            }
        } label: {
            HStack(spacing: CadenceTheme.spacingSM) {
                Image(systemName: reminder.suggestedEmoji)
                    .font(.title3)
                    .foregroundStyle(Color(hex: reminder.suggestedColor))
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(reminder.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(CadenceTheme.textPrimary)
                    HStack(spacing: 4) {
                        Text("\(reminder.completionCount) completions")
                        Text("·")
                        Text(reminder.listName)
                    }
                    .font(.caption)
                    .foregroundStyle(CadenceTheme.textSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? CadenceTheme.teal : CadenceTheme.textTertiary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: CadenceTheme.spacingLG) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(CadenceTheme.sage)

            VStack(spacing: CadenceTheme.spacingSM) {
                Text("Import Complete!")
                    .font(.title3.weight(.bold))

                Text("Imported \(importedCount) events with \(importedLogCount) total logs. Your history is ready.")
                    .font(.subheadline)
                    .foregroundStyle(CadenceTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(CadenceTheme.teal))
            }
            .padding(.horizontal, CadenceTheme.spacingXL)

            Spacer()
            Spacer()
        }
        .padding(CadenceTheme.spacingLG)
    }

    // MARK: - Actions

    private func loadReminders() async {
        isLoading = true
        reminders = await RemindersImportService.shared.fetchImportableReminders()
        // Auto-select reminders with 3+ completions
        selectedIDs = Set(reminders.filter { $0.completionCount >= 3 }.map(\.id))
        isLoading = false
    }

    private func importSelected() {
        let selected = reminders.filter { selectedIDs.contains($0.id) }
        var totalLogs = 0

        for reminder in selected {
            let event = Event(
                name: reminder.title,
                emoji: reminder.suggestedEmoji,
                accentColorHex: reminder.suggestedColor
            )
            modelContext.insert(event)

            for date in reminder.completionDates {
                let log = LogEntry(timestamp: date, event: event)
                event.logs.append(log)
                modelContext.insert(log)
                totalLogs += 1
            }
        }

        try? modelContext.save()

        importedCount = selected.count
        importedLogCount = totalLogs
        withAnimation { importComplete = true }
    }
}

#Preview {
    NavigationStack {
        RemindersImportView()
    }
    .modelContainer(for: [Event.self, LogEntry.self], inMemory: true)
}
