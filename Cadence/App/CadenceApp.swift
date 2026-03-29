import SwiftUI
import SwiftData

@main
struct CadenceApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([Event.self, LogEntry.self])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to configure SwiftData: \(error)")
        }

        NotificationService.shared.registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
