import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: Tab = .home
    @State private var navigationPath = NavigationPath()

    @Binding var selectedEventID: UUID?
    @Binding var showAddEvent: Bool
    @Binding var showQuickLog: Bool

    @Query(filter: #Predicate<Event> { !$0.isArchived },
           sort: \Event.name)
    private var events: [Event]

    enum Tab: String, CaseIterable {
        case home = "Home"
        case insights = "Insights"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .home: return "square.grid.2x2.fill"
            case .insights: return "waveform.path.ecg"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedEventID: $selectedEventID)
                .tabItem {
                    Label(Tab.home.rawValue, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)

            InsightsView()
                .tabItem {
                    Label(Tab.insights.rawValue, systemImage: Tab.insights.icon)
                }
                .tag(Tab.insights)

            SettingsView()
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
        .tint(CadenceTheme.teal)
        .sheet(isPresented: $showAddEvent) {
            AddEventView()
        }
        .sheet(isPresented: $showQuickLog) {
            quickLogSheet
        }
        .onChange(of: selectedEventID) { _, newValue in
            if newValue != nil {
                selectedTab = .home
            }
        }
    }

    /// Shows a quick-log sheet for the most urgent (due soonest) event.
    @ViewBuilder
    private var quickLogSheet: some View {
        if let urgentEvent = events
            .sorted(by: { IntervalEngine.dueSoonestScore(for: $0) > IntervalEngine.dueSoonestScore(for: $1) })
            .first {
            NavigationStack {
                EventDetailView(event: urgentEvent)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showQuickLog = false }
                        }
                    }
            }
        } else {
            Text("No events yet. Create one first!")
                .font(.headline)
                .foregroundStyle(CadenceTheme.textSecondary)
                .padding()
        }
    }
}

#Preview {
    ContentView(
        selectedEventID: .constant(nil),
        showAddEvent: .constant(false),
        showQuickLog: .constant(false)
    )
    .modelContainer(for: [Event.self, LogEntry.self], inMemory: true)
}
