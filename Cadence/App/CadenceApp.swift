import SwiftUI
import SwiftData

@main
struct CadenceApp: App {
    let modelContainer: ModelContainer

    init() {
        let syncService = CloudSyncService.shared
        do {
            let schema = Schema([Event.self, LogEntry.self])
            let config = syncService.makeModelConfiguration(schema: schema)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to configure SwiftData: \(error)")
        }

        NotificationService.shared.registerCategories()
        PhoneConnectivityManager.shared.configure(with: modelContainer)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}

// MARK: - Root View

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"

    @State private var selectedEventID: UUID?
    @State private var showAddEvent = false
    @State private var showQuickLog = false

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                ContentView(
                    selectedEventID: $selectedEventID,
                    showAddEvent: $showAddEvent,
                    showQuickLog: $showQuickLog
                )
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(colorScheme)
        .onOpenURL { url in
            handleDeepLink(url: url)
        }
    }

    private func handleDeepLink(url: URL) {
        guard let destination = DeepLinkRouter.parse(url: url) else { return }
        navigate(to: destination)
    }

    private func navigate(to destination: DeepLinkDestination) {
        switch destination {
        case .event(let id):
            selectedEventID = id
        case .addEvent:
            showAddEvent = true
        case .quickLog:
            showQuickLog = true
        }
    }
}
