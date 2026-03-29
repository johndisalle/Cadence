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

    var body: some View {
        if hasCompletedOnboarding {
            ContentView()
        } else {
            OnboardingView()
        }
    }
}
