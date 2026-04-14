import SwiftUI
import SwiftData

struct FamilySharingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var events: [Event]

    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled: Bool = false

    private var syncService: CloudSyncService { CloudSyncService.shared }

    private var sharedEvents: [Event] {
        events.filter { $0.isShared && !$0.isArchived }
    }

    private var personalEvents: [Event] {
        events.filter { !$0.isShared && !$0.isArchived }
    }

    var body: some View {
        List {
            headerSection

            if iCloudSyncEnabled {
                syncStatusSection
                sharedEventsSection
                personalEventsSection
            } else {
                enableSyncPromptSection
            }

            setupInstructionsSection
        }
        .navigationTitle("Family Sharing")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Header

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: CadenceTheme.spacingSM) {
                HStack(spacing: CadenceTheme.spacingSM) {
                    Image(systemName: "person.2.fill")
                        .font(.title2)
                        .foregroundStyle(CadenceTheme.teal)
                    Text("Shared Household Tasks")
                        .font(.headline)
                        .foregroundStyle(CadenceTheme.textPrimary)
                }

                Text("Share events with your family so everyone stays on top of household tasks. When iCloud Sync is on, events you mark as \"Shared\" will appear on all family members' devices.")
                    .font(.subheadline)
                    .foregroundStyle(CadenceTheme.textSecondary)
            }
            .padding(.vertical, CadenceTheme.spacingXS)
            .listRowBackground(CadenceTheme.backgroundSecondary)
        }
    }

    // MARK: - Enable Sync Prompt (when iCloud Sync is off)

    private var enableSyncPromptSection: some View {
        Section {
            VStack(alignment: .leading, spacing: CadenceTheme.spacingSM) {
                HStack(spacing: CadenceTheme.spacingSM) {
                    Image(systemName: "icloud.slash")
                        .font(.title2)
                        .foregroundStyle(CadenceTheme.textTertiary)
                    Text("iCloud Sync is Off")
                        .font(.headline)
                        .foregroundStyle(CadenceTheme.textPrimary)
                }
                Text("To share events with family members, turn on \"Sync across my devices\" in Settings → iCloud Sync, then come back here.")
                    .font(.subheadline)
                    .foregroundStyle(CadenceTheme.textSecondary)
            }
            .padding(.vertical, CadenceTheme.spacingXS)
            .listRowBackground(CadenceTheme.backgroundSecondary)
        }
    }

    // MARK: - Sync Status

    private var syncStatusSection: some View {
        Section("Sync Status") {
            HStack {
                Image(systemName: syncService.syncStatusIcon)
                    .foregroundStyle(statusColor)
                    .symbolEffect(.pulse, isActive: syncService.syncStatus == .syncing)
                Text(syncService.syncStatus.rawValue)
                    .foregroundStyle(CadenceTheme.textPrimary)
                Spacer()
                if let lastSync = syncService.lastSyncDate {
                    Text(lastSync, style: .relative)
                        .font(.caption)
                        .foregroundStyle(CadenceTheme.textSecondary)
                }
            }
            .listRowBackground(CadenceTheme.backgroundSecondary)
        }
    }

    // MARK: - Shared Events

    private var sharedEventsSection: some View {
        Section {
            if sharedEvents.isEmpty {
                HStack {
                    Image(systemName: "tray")
                        .foregroundStyle(CadenceTheme.textTertiary)
                    Text("No shared events yet")
                        .foregroundStyle(CadenceTheme.textTertiary)
                }
                .listRowBackground(CadenceTheme.backgroundSecondary)
            } else {
                ForEach(sharedEvents) { event in
                    eventRow(event, isShared: true)
                }
            }
        } header: {
            HStack {
                Text("Shared Events")
                Spacer()
                Text("\(sharedEvents.count)")
                    .font(.caption)
                    .foregroundStyle(CadenceTheme.textSecondary)
            }
        }
    }

    // MARK: - Personal Events

    private var personalEventsSection: some View {
        Section {
            if personalEvents.isEmpty {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(CadenceTheme.textTertiary)
                    Text("All events are shared")
                        .foregroundStyle(CadenceTheme.textTertiary)
                }
                .listRowBackground(CadenceTheme.backgroundSecondary)
            } else {
                ForEach(personalEvents) { event in
                    eventRow(event, isShared: false)
                }
            }
        } header: {
            HStack {
                Text("Personal Events")
                Spacer()
                Text("\(personalEvents.count)")
                    .font(.caption)
                    .foregroundStyle(CadenceTheme.textSecondary)
            }
        }
    }

    // MARK: - Setup Instructions

    private var setupInstructionsSection: some View {
        Section("How to Set Up Family Sharing") {
            VStack(alignment: .leading, spacing: CadenceTheme.spacingSM) {
                instructionRow(number: 1, text: "Open Settings on your iPhone and tap your name at the top.")
                instructionRow(number: 2, text: "Tap \"Family Sharing\" and set up your family group (or join an existing one).")
                instructionRow(number: 3, text: "Make sure all family members have Cadence installed.")
                instructionRow(number: 4, text: "Turn on \"Sync across my devices\" in Settings → iCloud Sync, then mark events as \"Shared\" to make them visible to everyone.")
            }
            .padding(.vertical, CadenceTheme.spacingXS)
            .listRowBackground(CadenceTheme.backgroundSecondary)
        }
    }

    // MARK: - Helpers

    private func eventRow(_ event: Event, isShared: Bool) -> some View {
        HStack {
            Image(systemName: event.emoji)
                .font(.title3)
                .foregroundStyle(event.accentColor)
            Text(event.name)
                .foregroundStyle(CadenceTheme.textPrimary)
            Spacer()
            Button {
                withAnimation {
                    event.isShared.toggle()
                }
            } label: {
                Image(systemName: isShared ? "person.2.fill" : "person.fill")
                    .foregroundStyle(isShared ? CadenceTheme.teal : CadenceTheme.textTertiary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
        }
        .listRowBackground(CadenceTheme.backgroundSecondary)
    }

    private func instructionRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: CadenceTheme.spacingSM) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(CadenceTheme.teal)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundStyle(CadenceTheme.textSecondary)
        }
    }

    private var statusColor: Color {
        switch syncService.syncStatus {
        case .idle: return CadenceTheme.textSecondary
        case .syncing: return CadenceTheme.teal
        case .synced: return CadenceTheme.sage
        case .error: return CadenceTheme.coral
        case .disabled: return CadenceTheme.textTertiary
        }
    }
}

#Preview {
    NavigationStack {
        FamilySharingView()
    }
    .modelContainer(for: [Event.self, LogEntry.self], inMemory: true)
}
