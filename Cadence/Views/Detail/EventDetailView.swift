import SwiftUI
import SwiftData
import Charts
import PhotosUI
import StoreKit

struct EventDetailView: View {
    @Bindable var event: Event
    @Environment(\.modelContext) private var modelContext

    enum DetailTab: String, CaseIterable {
        case overview = "Overview"
        case history = "History"
    }

    @State private var selectedTab: DetailTab = .overview
    @State private var showEditSheet = false
    @State private var showNoteLogSheet = false
    @State private var showPhotoLogSheet = false
    @State private var noteText = ""
    @State private var selectedPhotoData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?

    // Celebration state
    @State private var showConfetti = false
    @State private var showSuccessBurst = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var milestoneToShow: Milestone?
    @State private var showMilestoneAlert = false
    @State private var lastLogEntry: LogEntry?

    // Backdate state
    @State private var showBackdateSheet = false
    @State private var backdateDate = Date()
    @State private var backdateNotes = ""

    // Share state
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    @State private var showFamilyNudge = false
    @State private var showPaywall = false

    private var stats: IntervalStats? {
        IntervalEngine.compute(for: event)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Segmented picker
            Picker("Tab", selection: $selectedTab) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            // Tab content
            switch selectedTab {
            case .overview:
                overviewTab
            case .history:
                historyTab
            }
        }
        .navigationTitle(event.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showEditSheet = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .font(.title3)
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    showFamilyNudge = true
                } label: {
                    Label("Remind Someone", systemImage: "person.badge.clock")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    event.isArchived.toggle()
                } label: {
                    Label(
                        event.isArchived ? "Unarchive" : "Archive",
                        systemImage: event.isArchived ? "tray.and.arrow.up" : "archivebox"
                    )
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditEventView(event: event)
        }
        .sheet(isPresented: $showNoteLogSheet) {
            logWithNoteSheet
        }
        .sheet(isPresented: $showPhotoLogSheet) {
            logWithPhotoSheet
        }
        .overlay {
            ConfettiView(isShowing: $showConfetti)
        }
        .overlay {
            SuccessBurstView(isShowing: $showSuccessBurst)
        }
        .toast(isShowing: $showToast, message: toastMessage, icon: "checkmark.circle.fill") {
            undoLastLog()
        }
        .alert(
            milestoneToShow?.title ?? "",
            isPresented: $showMilestoneAlert
        ) {
            Button("Awesome!") { }
        } message: {
            Text(milestoneToShow?.subtitle ?? "")
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
        .sheet(isPresented: $showBackdateSheet) {
            backdateSheet
        }
        .sheet(isPresented: $showFamilyNudge) {
            FamilyNudgeSheet(event: event)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Overview Tab

    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: CadenceTheme.spacingLG) {
                // Large emoji
                Image(systemName: event.emoji)
                    .font(.system(size: 52))
                    .foregroundStyle(event.accentColor)
                    .padding(.top, CadenceTheme.spacingMD)

                // Stats box
                statsCard

                // Encouragement for empty events
                if event.logs.isEmpty {
                    VStack(spacing: CadenceTheme.spacingSM) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 32))
                            .foregroundStyle(CadenceTheme.teal.opacity(0.4))
                        Text("Log your first one!")
                            .font(.headline)
                            .foregroundStyle(CadenceTheme.textPrimary)
                        Text("After 3 logs, Cadence starts learning your rhythm and predicting when you'll need to do it next.")
                            .font(.subheadline)
                            .foregroundStyle(CadenceTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, CadenceTheme.spacingLG)
                    .padding(.vertical, CadenceTheme.spacingMD)
                }

                // Confidence ring
                if let stats, stats.confidencePercent > 0 {
                    confidenceView(stats: stats)
                }

                // Insight
                if let stats {
                    Text(stats.insight)
                        .font(.subheadline)
                        .foregroundStyle(CadenceTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Share buttons
                shareSection

                // Chart
                VStack(alignment: .leading, spacing: CadenceTheme.spacingSM) {
                    HStack {
                        Text("Interval Trend")
                            .font(.headline)
                        Spacer()
                        if !PremiumManager.shared.isPremium {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundStyle(CadenceTheme.sand)
                        }
                    }
                    if PremiumManager.shared.isPremium {
                        IntervalChartView(event: event)
                    } else {
                        IntervalChartView(event: event)
                            .blur(radius: 6)
                            .allowsHitTesting(false)
                            .overlay {
                                Button {
                                    showPaywall = true
                                } label: {
                                    Label("Unlock Charts", systemImage: "crown.fill")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Capsule().fill(CadenceTheme.teal))
                                }
                            }
                    }
                }
                .cadenceCard(accent: event.accentColor)
                .padding(.horizontal)

                Spacer(minLength: 100)
            }
        }
        .overlay(alignment: .bottom) {
            logNowButton
        }
    }

    // MARK: - Stats Card

    private var streakInfo: StreakInfo? {
        StreakEngine.compute(for: event)
    }

    private var statsCard: some View {
        VStack(spacing: CadenceTheme.spacingSM) {
            let logCount = event.logs.count
            let avgText: String = {
                guard let stats, stats.averageDays > 0 else { return "..." }
                return "\(Int(round(stats.averageDays)))"
            }()
            let lastText: String = {
                guard let last = event.lastLoggedDate else { return "Never" }
                return last.timeAgoDisplay
            }()

            HStack(spacing: CadenceTheme.spacingLG) {
                statItem(value: "\(logCount)", label: "Logs")
                statItem(value: avgText == "..." ? "--" : "~\(avgText)d", label: "Avg Interval")
                statItem(value: lastText, label: "Last")
            }

            // Streak row
            if let streak = streakInfo, streak.currentStreak > 0 {
                Divider()
                HStack(spacing: CadenceTheme.spacingMD) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(CadenceTheme.coral)
                        Text("\(streak.currentStreak) in a row")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CadenceTheme.textPrimary)
                    }

                    Spacer()

                    Text("Longest: \(streak.longestStreak)")
                        .font(.caption)
                        .foregroundStyle(CadenceTheme.textSecondary)
                }
            }
        }
        .cadenceCard(accent: event.accentColor)
        .padding(.horizontal)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(event.accentColor)
            Text(label)
                .font(.caption)
                .foregroundStyle(CadenceTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Confidence View

    private func confidenceView(stats: IntervalStats) -> some View {
        HStack(spacing: CadenceTheme.spacingMD) {
            // Small progress ring
            ZStack {
                Circle()
                    .stroke(event.accentColor.opacity(0.2), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: stats.confidencePercent / 100.0)
                    .stroke(event.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(round(stats.confidencePercent)))% Confidence")
                    .font(.headline)
                Text(stats.rhythm)
                    .font(.subheadline)
                    .foregroundStyle(CadenceTheme.textSecondary)
            }

            Spacer()
        }
        .cadenceCard(accent: event.accentColor)
        .padding(.horizontal)
    }

    // MARK: - Share Section

    @ViewBuilder
    private var shareSection: some View {
        let streak = streakInfo
        let hasStreak = (streak?.currentStreak ?? 0) > 0
        let hasEnoughLogs = event.logs.count >= 3

        if hasStreak || hasEnoughLogs {
            HStack(spacing: CadenceTheme.spacingSM) {
                if hasStreak {
                    Button {
                        let card = StreakShareCard(
                            eventName: event.name,
                            emoji: event.emoji,
                            streakDays: streak?.currentStreak ?? 0,
                            accentColorHex: event.accentColorHex
                        )
                        shareImage = card.renderAsImage(size: CGSize(width: 390, height: 520))
                        showShareSheet = true
                    } label: {
                        Label("Share Streak", systemImage: "flame.fill")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(event.accentColor.opacity(0.12))
                            )
                            .foregroundStyle(event.accentColor)
                    }
                }

                if hasEnoughLogs, let stats {
                    Button {
                        let card = RhythmShareCard(
                            eventName: event.name,
                            emoji: event.emoji,
                            rhythm: stats.rhythm,
                            consistency: Int(round(stats.confidencePercent)),
                            totalLogs: event.logs.count,
                            accentColorHex: event.accentColorHex
                        )
                        shareImage = card.renderAsImage(size: CGSize(width: 390, height: 520))
                        showShareSheet = true
                    } label: {
                        Label("Share Rhythm", systemImage: "waveform.path.ecg")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(event.accentColor.opacity(0.12))
                            )
                            .foregroundStyle(event.accentColor)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Log Now Button

    private var logNowButton: some View {
        VStack(spacing: 6) {
            Button {
                addLog(notes: nil, photoData: nil)
            } label: {
                Label("Log Now", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(event.accentColor)
                            .shadow(color: event.accentColor.opacity(0.4), radius: 12, y: 6)
                    )
                    .padding(.horizontal, CadenceTheme.spacingLG)
            }

            Button {
                backdateDate = Date()
                backdateNotes = ""
                showBackdateSheet = true
            } label: {
                Text("Log a past date")
                    .font(.caption)
                    .foregroundStyle(event.accentColor)
            }
            .padding(.bottom, CadenceTheme.spacingMD)
        }
    }

    // MARK: - History Tab

    private var historyTab: some View {
        VStack(spacing: 0) {
            // Action buttons
            HStack(spacing: CadenceTheme.spacingSM) {
                Button {
                    noteText = ""
                    showNoteLogSheet = true
                } label: {
                    Label("Log with Note", systemImage: "text.bubble")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(event.accentColor.opacity(0.12))
                        )
                        .foregroundStyle(event.accentColor)
                }

                Button {
                    showPhotoLogSheet = true
                } label: {
                    Label("Log with Photo", systemImage: "camera")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(event.accentColor.opacity(0.12))
                        )
                        .foregroundStyle(event.accentColor)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, CadenceTheme.spacingSM)

            if event.logs.isEmpty {
                ContentUnavailableView(
                    "No Logs Yet",
                    systemImage: "clock.badge.questionmark",
                    description: Text("Tap \"Log Now\" to record your first entry.")
                )
            } else {
                List {
                    ForEach(event.sortedLogs, id: \.id) { log in
                        logRow(log: log)
                    }
                    .onDelete(perform: deleteLogs)
                }
                .listStyle(.plain)
            }
        }
    }

    private func logRow(log: LogEntry) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.timestamp.shortFormatted)
                    .font(.subheadline.weight(.medium))
                if let notes = log.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(CadenceTheme.textSecondary)
                        .lineLimit(2)
                }
                Text(log.timestamp.timeAgoDisplay)
                    .font(.caption2)
                    .foregroundStyle(CadenceTheme.textTertiary)
            }

            Spacer()

            if let photoData = log.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.vertical, 4)
    }

    private func deleteLogs(at offsets: IndexSet) {
        let sorted = event.sortedLogs
        for index in offsets {
            let log = sorted[index]
            modelContext.delete(log)
        }
    }

    // MARK: - Actions

    private func addLog(notes: String?, photoData: Data?, date: Date = Date()) {
        let log = LogEntry(timestamp: date, notes: notes, photoData: photoData, event: event)
        event.logs.append(log)
        modelContext.insert(log)

        // Check milestone
        if let milestone = MilestoneEngine.check(event: event, newLogCount: event.logs.count) {
            milestoneToShow = milestone
            if milestone.isConfetti {
                showConfetti = true
            } else {
                showSuccessBurst = true
            }
            showMilestoneAlert = true
        } else {
            showSuccessBurst = true
        }

        // Show toast
        if let stats = IntervalEngine.compute(for: event),
           let nextDate = stats.predictedNextDate {
            let daysUntil = max(1, Int(Date().daysUntil(nextDate)))
            toastMessage = "Logged! Next expected in \(daysUntil)d"
        } else {
            toastMessage = "Logged \(event.name)!"
        }
        showToast = true
        lastLogEntry = log  // for undo

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Smart review prompt — ask at 10th, 50th, 100th total log
        let totalLogs = UserDefaults.standard.integer(forKey: "cadence_total_logs") + 1
        UserDefaults.standard.set(totalLogs, forKey: "cadence_total_logs")
        if [10, 50, 100].contains(totalLogs) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                guard let scene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene }).first else { return }
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }

    private func undoLastLog() {
        guard let log = lastLogEntry else { return }
        event.logs.removeAll { $0.id == log.id }
        modelContext.delete(log)
        lastLogEntry = nil
    }

    // MARK: - Log with Note Sheet

    private var logWithNoteSheet: some View {
        NavigationStack {
            Form {
                Section("Note") {
                    TextField("What happened?", text: $noteText, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("Log with Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showNoteLogSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        addLog(notes: noteText.isEmpty ? nil : noteText, photoData: nil)
                        showNoteLogSheet = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Backdate Sheet

    private var backdateSheet: some View {
        NavigationStack {
            Form {
                Section("Date & Time") {
                    DatePicker(
                        "When did it happen?",
                        selection: $backdateDate,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                Section("Note") {
                    TextField("Optional notes...", text: $backdateNotes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle("Log Past Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showBackdateSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        addLog(notes: backdateNotes.isEmpty ? nil : backdateNotes, photoData: nil, date: backdateDate)
                        showBackdateSheet = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Log with Photo Sheet

    private var logWithPhotoSheet: some View {
        NavigationStack {
            VStack(spacing: CadenceTheme.spacingMD) {
                if let data = selectedPhotoData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                } else {
                    VStack(spacing: CadenceTheme.spacingMD) {
                        Spacer()
                        PhotosPicker(
                            selection: $selectedPhotoItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Label("Choose Photo", systemImage: "photo.on.rectangle.angled")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, CadenceTheme.spacingLG)
                                .padding(.vertical, 14)
                                .background(Capsule().fill(event.accentColor))
                        }
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    selectedPhotoData = data
                                }
                            }
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("Log with Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        selectedPhotoData = nil
                        selectedPhotoItem = nil
                        showPhotoLogSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        addLog(notes: nil, photoData: selectedPhotoData)
                        selectedPhotoData = nil
                        selectedPhotoItem = nil
                        showPhotoLogSheet = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: Event.self, LogEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let event = Event(name: "Water Plants", emoji: "leaf.fill", accentColorHex: "#7FA886", category: .home)
    let cal = Calendar.current
    let now = Date()
    for i in stride(from: 0, to: 60, by: 3) {
        let jitter = Int.random(in: -1...1)
        let date = cal.date(byAdding: .day, value: -(i + jitter), to: now)!
        let log = LogEntry(timestamp: date, notes: i == 0 ? "Looking healthy!" : nil)
        event.logs.append(log)
    }
    container.mainContext.insert(event)

    return NavigationStack {
        EventDetailView(event: event)
    }
    .modelContainer(container)
}
