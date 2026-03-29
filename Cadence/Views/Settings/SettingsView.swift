import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var events: [Event]

    @AppStorage("appearanceMode") private var appearanceMode: String = "system"
    @AppStorage("remindersEnabled") private var remindersEnabled: Bool = false
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled: Bool = false

    @State private var showResetConfirmation = false
    @State private var showExportSheet = false
    @State private var exportedPDFData: Data?

    private let appVersion: String = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }()

    var body: some View {
        NavigationStack {
            List {
                appearanceSection
                notificationsSection
                dataSection
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
                exportPDF()
            } label: {
                HStack {
                    Image(systemName: "doc.richtext")
                        .foregroundStyle(CadenceTheme.teal)
                    Text("Export PDF Summary")
                        .foregroundStyle(CadenceTheme.textPrimary)
                }
            }
            .listRowBackground(CadenceTheme.backgroundSecondary)

            Button {
                loadSampleData()
            } label: {
                HStack {
                    Image(systemName: "tray.and.arrow.down")
                        .foregroundStyle(CadenceTheme.teal)
                    Text("Load Sample Data")
                        .foregroundStyle(CadenceTheme.textPrimary)
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
            .listRowBackground(CadenceTheme.backgroundSecondary)
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

    private func resetAllData() {
        do {
            try modelContext.delete(model: LogEntry.self)
            try modelContext.delete(model: Event.self)
            try modelContext.save()
        } catch {
            print("Failed to reset data: \(error)")
        }
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .modelContainer(for: [Event.self, LogEntry.self], inMemory: true)
}
