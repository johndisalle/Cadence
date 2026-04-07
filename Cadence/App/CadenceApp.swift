import SwiftUI
import SwiftData
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let eventIDString = response.notification.request.content.userInfo["eventID"] as? String ?? ""

        switch response.actionIdentifier {
        case "LOG_NOW":
            guard let uuid = UUID(uuidString: eventIDString) else { return }
            do {
                let container = try ModelContainer(for: Event.self, LogEntry.self)
                let context = container.mainContext
                let descriptor = FetchDescriptor<Event>(
                    predicate: #Predicate<Event> { event in event.id == uuid }
                )
                guard let event = try context.fetch(descriptor).first else { return }
                let log = LogEntry(timestamp: Date(), event: event)
                event.logs.append(log)
                context.insert(log)
                try context.save()
                NotificationService.shared.scheduleSmartReminders(for: event)
            } catch {
                print("Failed to log from notification: \(error)")
            }

        case "SNOOZE":
            guard let uuid = UUID(uuidString: eventIDString) else { return }
            do {
                let container = try ModelContainer(for: Event.self, LogEntry.self)
                let context = container.mainContext
                let descriptor = FetchDescriptor<Event>(
                    predicate: #Predicate<Event> { event in event.id == uuid }
                )
                guard let event = try context.fetch(descriptor).first else { return }
                NotificationService.shared.scheduleReminder(for: event, in: 1.0 / 24.0)
            } catch {
                print("Failed to snooze: \(error)")
            }

        default:
            break
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }
}

@main
struct CadenceApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
    @Environment(\.scenePhase) private var scenePhase
    @Query(filter: #Predicate<Event> { !$0.isArchived }) private var events: [Event]

    @State private var showLaunchScreen = true
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
        ZStack {
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

            if showLaunchScreen {
                LaunchScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showLaunchScreen = false
                }
            }
            WidgetDataService.writeToSharedDefaults(events: events)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                WidgetDataService.writeToSharedDefaults(events: events)
            }
        }
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
