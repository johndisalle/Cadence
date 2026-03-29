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

    private var filteredEvents: [Event] {
        let base = searchText.isEmpty
            ? events
            : events.filter { $0.name.localizedCaseInsensitiveContains(searchText) }

        switch sortMode {
        case .name:
            return base.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .dueSoonest:
            return base.sorted {
                IntervalEngine.dueSoonestScore(for: $0) > IntervalEngine.dueSoonestScore(for: $1)
            }
        }
    }

    private let gridColumns = [
        GridItem(.adaptive(minimum: 160), spacing: CadenceTheme.spacingMD)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if events.isEmpty {
                    emptyState
                } else {
                    ScrollView {
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
                        showAddEvent = true
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
        }
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
        .navigationDestination(for: Event.self) { event in
            EventDetailView(event: event)
        }
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
        .navigationDestination(for: Event.self) { event in
            EventDetailView(event: event)
        }
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
                Text("🌿")
                    .font(.system(size: 56))
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
