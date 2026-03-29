import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .home

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
            HomeView()
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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Event.self, LogEntry.self], inMemory: true)
}
