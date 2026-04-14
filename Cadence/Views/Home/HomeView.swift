import SwiftUI
import SwiftData

enum HomeSortMode: String, CaseIterable {
    case name = "Name"
    case dueSoonest = "Due Soonest"
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Event> { !$0.isArchived },
           sort: \Event.name)
    private var events: [Event]

    @State private var searchText = ""
    @State private var showAddEvent = false
    @State private var showAsGrid = true
    @State private var sortMode: HomeSortMode = .dueSoonest
    @State private var showPaywall = false
    @State private var showFirstUpsellPaywall = false
    @State private var pendingAddAfterUpsell = false
    @State private var showRemindersImport = false
    @State private var navigationPath = NavigationPath()
    @State private var selectedCategory: EventCategory? = nil

    var selectedEventID: Binding<UUID?>?

    private var premium: PremiumManager { .shared }

    private var filteredEvents: [Event] {
        var base = events.filter { _ in true }  // start with all

        // Category filter
        if let category = selectedCategory {
            base = base.filter { $0.category == category }
        }

        // Search filter
        if !searchText.isEmpty {
            base = base.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        // Sort
        switch sortMode {
        case .name:
            return base.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .dueSoonest:
            return base.sorted {
                IntervalEngine.dueSoonestScore(for: $0) > IntervalEngine.dueSoonestScore(for: $1)
            }
        }
    }

    /// Categories that actually have events, for the filter chips
    private var activeCategories: [EventCategory] {
        let usedRaws = Set(events.map { $0.categoryRaw })
        return EventCategory.allCases.filter { usedRaws.contains($0.rawValue) }
    }

    private let gridColumns = [
        GridItem(.adaptive(minimum: 160), spacing: CadenceTheme.spacingMD)
    ]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if events.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        greetingHeader
                        if activeCategories.count > 1 {
                            categoryChips
                        }
                        if showAsGrid {
                            gridContent
                        } else {
                            listContent
                        }
                    }
                }
            }
            .navigationTitle("Cadence")
            .searchable(text: $searchText, prompt: "Search events")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    sortPicker
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showAsGrid.toggle()
                        }
                    } label: {
                        Image(systemName: showAsGrid ? "list.bullet" : "square.grid.2x2")
                            .imageScale(.large)
                    }
                    .accessibilityLabel(showAsGrid ? "Switch to list" : "Switch to grid")

                    Button {
                        handleAddTap()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                            .foregroundStyle(CadenceTheme.teal)
                    }
                    .accessibilityLabel("Add event")
                }
            }
            .sheet(isPresented: $showAddEvent) {
                AddEventView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showRemindersImport) {
                NavigationStack {
                    RemindersImportView()
                }
            }
            .fullScreenCover(
                isPresented: $showFirstUpsellPaywall,
                onDismiss: {
                    // Fires regardless of whether user tapped X, "Continue
                    // with free", or completed a purchase. If the upsell
                    // was triggered by the + button, present AddEventView next.
                    if pendingAddAfterUpsell {
                        pendingAddAfterUpsell = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            showAddEvent = true
                        }
                    }
                }
            ) {
                OnboardingPaywallView {
                    showFirstUpsellPaywall = false
                }
            }
            .navigationDestination(for: Event.self) { event in
                EventDetailView(event: event)
            }
            .onChange(of: selectedEventID?.wrappedValue) { _, newValue in
                guard let id = newValue else { return }
                if let event = events.first(where: { $0.id == id }) {
                    navigationPath.append(event)
                }
                selectedEventID?.wrappedValue = nil
            }
            .onReceive(NotificationCenter.default.publisher(for: .cadenceDidLogEvent)) { _ in
                // Brief delay so the log celebration animation lands before
                // the paywall takes over the screen.
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if PremiumManager.shared.shouldTriggerFirstUpsellAfterLog() {
                        showFirstUpsellPaywall = true
                    }
                }
            }
        }
    }

    // MARK: - Add Tap Handler

    private func handleAddTap() {
        // Hard cap first — at freeEventLimit, force the paywall (no skip)
        if !premium.canAddEvent(currentCount: events.count) {
            showPaywall = true
            return
        }
        // Soft first-time upsell — at the upsell threshold, show the
        // dismissible paywall, then continue to AddEventView on dismiss.
        if premium.shouldTriggerFirstUpsellOnAdd(currentCount: events.count) {
            pendingAddAfterUpsell = true
            showFirstUpsellPaywall = true
            return
        }
        // Normal path
        showAddEvent = true
    }

    // MARK: - Greeting Header

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greetingText)
                .font(.subheadline)
                .foregroundStyle(CadenceTheme.textSecondary)
            if overdueCount > 0 {
                Text("\(overdueCount) thing\(overdueCount == 1 ? "" : "s") need\(overdueCount == 1 ? "s" : "") attention")
                    .font(.caption)
                    .foregroundStyle(CadenceTheme.urgencyHigh)
            } else {
                Text("You're all caught up!")
                    .font(.caption)
                    .foregroundStyle(CadenceTheme.sage)
            }
        }
        .padding(.horizontal, CadenceTheme.spacingMD)
        .padding(.top, CadenceTheme.spacingSM)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    private var overdueCount: Int {
        events.filter { event in
            guard let stats = IntervalEngine.compute(for: event) else { return false }
            return stats.isOverdue
        }.count
    }

    // MARK: - Grid

    private var gridContent: some View {
        LazyVGrid(columns: gridColumns, spacing: CadenceTheme.spacingMD) {
            ForEach(filteredEvents, id: \.id) { event in
                NavigationLink(value: event) {
                    EventCardView(event: event)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, CadenceTheme.spacingMD)
        .padding(.top, CadenceTheme.spacingSM)
        .padding(.bottom, CadenceTheme.spacingXL)
    }

    // MARK: - List

    private var listContent: some View {
        LazyVStack(spacing: CadenceTheme.spacingSM) {
            ForEach(filteredEvents, id: \.id) { event in
                NavigationLink(value: event) {
                    EventCardView(event: event)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, CadenceTheme.spacingMD)
        .padding(.top, CadenceTheme.spacingSM)
        .padding(.bottom, CadenceTheme.spacingXL)
    }

    // MARK: - Category Chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chipButton(label: "All", icon: nil, isSelected: selectedCategory == nil) {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedCategory = nil }
                }
                ForEach(activeCategories) { category in
                    chipButton(
                        label: category.displayName,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    }
                }
            }
            .padding(.horizontal, CadenceTheme.spacingMD)
            .padding(.vertical, CadenceTheme.spacingXS)
        }
    }

    private func chipButton(label: String, icon: String?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(label)
                    .font(.subheadline.weight(isSelected ? .semibold : .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? .white : CadenceTheme.textSecondary)
            .background(
                Capsule().fill(isSelected ? CadenceTheme.teal : CadenceTheme.backgroundSecondary)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sort Picker

    private var sortPicker: some View {
        Menu {
            ForEach(HomeSortMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation { sortMode = mode }
                } label: {
                    Label(mode.rawValue,
                          systemImage: sortMode == mode ? "checkmark" : "")
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                Text(sortMode.rawValue)
                    .font(.subheadline)
            }
        }
    }

    // MARK: - Template Quick Add

    private func createEventFromTemplate(_ template: EventTemplate) {
        let event = Event(
            name: template.name,
            emoji: template.emoji,
            accentColorHex: template.accentColorHex,
            category: template.category
        )
        modelContext.insert(event)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: CadenceTheme.spacingLG) {
            Spacer()

            ZStack {
                Circle()
                    .fill(CadenceTheme.teal.opacity(0.1))
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(CadenceTheme.teal.opacity(0.06))
                    .frame(width: 200, height: 200)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(CadenceTheme.teal)
            }

            VStack(spacing: CadenceTheme.spacingSM) {
                Text("Welcome to Cadence")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CadenceTheme.textPrimary)

                Text("Track the rhythm of the things you care about.\nAdd your first event to get started.")
                    .font(.subheadline)
                    .foregroundStyle(CadenceTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // Popular Templates — quick-add pills
            VStack(spacing: CadenceTheme.spacingSM) {
                Text("Popular Templates")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(CadenceTheme.textTertiary)
                    .textCase(.uppercase)

                FlowLayout(spacing: CadenceTheme.spacingSM) {
                    ForEach(EventTemplate.popularTemplates) { template in
                        Button {
                            createEventFromTemplate(template)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: template.emoji)
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: template.accentColorHex))
                                Text(template.name)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(CadenceTheme.textPrimary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color(hex: template.accentColorHex).opacity(0.12))
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color(hex: template.accentColorHex).opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Reminders import CTA — for users who already track these in Apple Reminders
            Button {
                showRemindersImport = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.caption)
                    Text("Already tracking these in Reminders? Import them")
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(CadenceTheme.teal)
                .padding(.horizontal, CadenceTheme.spacingMD)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(CadenceTheme.teal.opacity(0.08))
                )
            }
            .buttonStyle(.plain)

            Button {
                showAddEvent = true
            } label: {
                Label("Add Your First Event", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, CadenceTheme.spacingLG)
                    .padding(.vertical, 14)
                    .background(
                        Capsule().fill(CadenceTheme.teal)
                    )
            }

            Spacer()
            Spacer()
        }
        .padding(CadenceTheme.spacingLG)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Event.self, LogEntry.self], inMemory: true)
}
