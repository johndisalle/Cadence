import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var events: [Event]

    @AppStorage("appearanceMode") private var appearanceMode: String = "system"
    @AppStorage("remindersEnabled") private var remindersEnabled: Bool = false
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled: Bool = false

    @State private var showResetConfirmation = false
    @State private var showExportSheet = false
    @State private var exportedPDFData: Data?
    @State private var showPaywall = false
    @State private var showRestartAlert = false

    private var premium: PremiumManager { .shared }

    private let appVersion: String = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }()

    var body: some View {
        NavigationStack {
            List {
                if !premium.isPremium {
                    premiumBannerSection
                }
                appearanceSection
                notificationsSection
                dataSection
                importSection
                if archivedEventCount > 0 {
                    archivedSection
                }
                iCloudSyncSection
                familySharingSection
                aboutSection
                resetSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showExportSheet) {
                if let data = exportedPDFData {
                    ShareSheet(items: [data])
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert("Restart Cadence", isPresented: $showRestartAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Restart Cadence to apply sync changes.")
            }
        }
    }

    // MARK: - iCloud Sync

    private var iCloudSyncSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { iCloudSyncEnabled },
                set: { newValue in
                    iCloudSyncEnabled = newValue
                    showRestartAlert = true
                }
            )) {
                HStack {
                    Image(systemName: "icloud.fill")
                        .foregroundStyle(CadenceTheme.teal)
                    Text("Sync across my devices")
                        .foregroundStyle(CadenceTheme.textPrimary)
                }
            }
            .tint(CadenceTheme.teal)
            .listRowBackground(CadenceTheme.backgroundSecondary)
        } header: {
            Text("iCloud Sync")
        } footer: {
            Text("Keep your events and logs in sync between your iPhone, iPad, and Apple Watch using your private iCloud account. No data leaves your Apple ID.")
                .font(.caption)
                .foregroundStyle(CadenceTheme.textTertiary)
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $appearanceMode) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)
            .listRowBackground(CadenceTheme.backgroundSecondary)
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("Reminders", isOn: $remindersEnabled)
                .tint(CadenceTheme.teal)
                .listRowBackground(CadenceTheme.backgroundSecondary)

            Button {
                requestNotificationPermission()
            } label: {
                HStack {
                    Image(systemName: "bell.badge")
                        .foregroundStyle(CadenceTheme.teal)
                    Text("Request Permission")
                        .foregroundStyle(CadenceTheme.textPrimary)
                }
            }
            .listRowBackground(CadenceTheme.backgroundSecondary)
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        Section("Data") {
            Button {
                if premium.canExport() {
                    exportPDF()
                } else {
                    showPaywall = true
                }
            } label: {
                HStack {
                    Image(systemName: "doc.richtext")
                        .foregroundStyle(CadenceTheme.teal)
                    Text("Export PDF Summary")
                        .foregroundStyle(CadenceTheme.textPrimary)
                    if !premium.canExport() {
                        Spacer()
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundStyle(CadenceTheme.sand)
                    }
                }
            }
            .listRowBackground(CadenceTheme.backgroundSecondary)

        }
    }

    // MARK: - Import

    private var importSection: some View {
        Section("Import") {
            NavigationLink {
                RemindersImportView()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundStyle(CadenceTheme.teal)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Import from Reminders")
                            .foregroundStyle(CadenceTheme.textPrimary)
                        Text("Find recurring patterns in completed reminders")
                            .font(.caption)
                            .foregroundStyle(CadenceTheme.textSecondary)
                    }
                }
            }
            .listRowBackground(CadenceTheme.backgroundSecondary)
        }
    }

    // MARK: - Archived

    private var archivedEventCount: Int {
        events.filter { $0.isArchived }.count
    }

    private var archivedSection: some View {
        Section("Archived") {
            NavigationLink {
                ArchivedEventsView()
            } label: {
                HStack {
                    Image(systemName: "archivebox.fill")
                        .foregroundStyle(CadenceTheme.textTertiary)
                    Text("Archived Events")
                        .foregroundStyle(CadenceTheme.textPrimary)
                    Spacer()
                    Text("\(archivedEventCount)")
                        .foregroundStyle(CadenceTheme.textSecondary)
                }
            }
            .listRowBackground(CadenceTheme.backgroundSecondary)
        }
    }

    // MARK: - Family Sharing

    private var sharedEventCount: Int {
        events.filter { $0.isShared && !$0.isArchived }.count
    }

    private var familySharingSection: some View {
        Section("Family Sharing") {
            if premium.canUseFamilySharing() {
                NavigationLink {
                    FamilySharingView()
                } label: {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundStyle(CadenceTheme.teal)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Family Sharing")
                                .foregroundStyle(CadenceTheme.textPrimary)
                            Text(iCloudSyncEnabled
                                ? "On \u{2022} \(sharedEventCount) shared event\(sharedEventCount == 1 ? "" : "s")"
                                : "Off")
                                .font(.caption)
                                .foregroundStyle(CadenceTheme.textSecondary)
                        }
                    }
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundStyle(CadenceTheme.teal)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Family Sharing")
                                .foregroundStyle(CadenceTheme.textPrimary)
                            Text("Sync shared household tasks via iCloud")
                                .font(.caption)
                                .foregroundStyle(CadenceTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundStyle(CadenceTheme.sand)
                    }
                }
            }
        }
    }

    // MARK: - Premium Banner

    private var premiumBannerSection: some View {
        Section {
            Button {
                showPaywall = true
            } label: {
                HStack(spacing: CadenceTheme.spacingMD) {
                    Image(systemName: "crown.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [CadenceTheme.sand, CadenceTheme.coral],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Upgrade to Cadence Pro")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CadenceTheme.textPrimary)
                        Text("Unlimited events, insights, export & more")
                            .font(.caption)
                            .foregroundStyle(CadenceTheme.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(CadenceTheme.textTertiary)
                }
            }
            .listRowBackground(
                LinearGradient(
                    colors: [CadenceTheme.teal.opacity(0.08), CadenceTheme.sage.opacity(0.08)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                    .foregroundStyle(CadenceTheme.textPrimary)
                Spacer()
                Text(appVersion)
                    .foregroundStyle(CadenceTheme.textSecondary)
            }
            .listRowBackground(CadenceTheme.backgroundSecondary)

            Button {
                requestReview()
            } label: {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(CadenceTheme.sand)
                    Text("Rate Cadence on the App Store")
                        .foregroundStyle(CadenceTheme.textPrimary)
                }
            }
            .listRowBackground(CadenceTheme.backgroundSecondary)

            Link(destination: URL(string: "https://johndisalle.github.io/Cadence/privacy.html")!) {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(CadenceTheme.teal)
                    Text("Privacy Policy")
                        .foregroundStyle(CadenceTheme.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(CadenceTheme.textTertiary)
                }
            }
            .listRowBackground(CadenceTheme.backgroundSecondary)

            Link(destination: URL(string: "https://johndisalle.github.io/Cadence/terms.html")!) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(CadenceTheme.teal)
                    Text("Terms & Conditions")
                        .foregroundStyle(CadenceTheme.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(CadenceTheme.textTertiary)
                }
            }
            .listRowBackground(CadenceTheme.backgroundSecondary)

            Link(destination: URL(string: "https://johndisalle.github.io/Cadence/support.html")!) {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundStyle(CadenceTheme.teal)
                    Text("Help & Support")
                        .foregroundStyle(CadenceTheme.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(CadenceTheme.textTertiary)
                }
            }
            .listRowBackground(CadenceTheme.backgroundSecondary)

            VStack(alignment: .leading, spacing: CadenceTheme.spacingXS) {
                Text("Cadence")
                    .font(.headline)
                    .foregroundStyle(CadenceTheme.textPrimary)
                Text("Track life's natural rhythm")
                    .font(.subheadline)
                    .foregroundStyle(CadenceTheme.textSecondary)
            }
            .listRowBackground(CadenceTheme.backgroundSecondary)
        }
    }

    // MARK: - Reset

    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Reset All Data")
                }
            }
            .listRowBackground(CadenceTheme.backgroundSecondary)
            .confirmationDialog(
                "Reset All Data",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) {
                    resetAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your events and logs. This action cannot be undone.")
            }
        }
    }

    // MARK: - Actions

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                remindersEnabled = granted
            }
        }
    }

    private func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }
        SKStoreReviewController.requestReview(in: scene)
    }

    @MainActor
    private func exportPDF() {
        let data = PDFExportService.generateSummary(events: events)
        exportedPDFData = data
        showExportSheet = true
    }

    @MainActor
    private func loadSampleData() {
        SampleData.populate(context: modelContext)
    }

    @MainActor
    private func resetAllData() {
        // Delete all logs first, then events
        for event in events {
            for log in event.logs {
                modelContext.delete(log)
            }
            modelContext.delete(event)
        }
        try? modelContext.save()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Event.self, LogEntry.self], inMemory: true)
}
