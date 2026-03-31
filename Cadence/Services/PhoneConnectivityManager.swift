import Foundation
import WatchConnectivity
import SwiftData

/// Manages WatchConnectivity on the iPhone side.
/// Sends event data to the Apple Watch and handles log requests from the watch.
final class PhoneConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = PhoneConnectivityManager()

    private var session: WCSession?
    private var modelContainer: ModelContainer?

    private override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    func configure(with container: ModelContainer) {
        self.modelContainer = container
    }

    // MARK: - Send Events to Watch

    @MainActor
    func syncEventsToWatch(events: [Event]) {
        guard let session, session.isPaired, session.isWatchAppInstalled else { return }

        let watchEvents: [[String: Any]] = events
            .filter { !$0.isArchived }
            .sorted { (IntervalEngine.dueSoonestScore(for: $0)) > (IntervalEngine.dueSoonestScore(for: $1)) }
            .prefix(20)
            .map { event in
                let stats = IntervalEngine.compute(for: event)
                let streak = StreakEngine.compute(for: event)
                return [
                    "id": event.id.uuidString,
                    "name": event.name,
                    "emoji": event.emoji,
                    "lastLoggedDate": (event.lastLoggedDate ?? event.createdAt).timeIntervalSince1970,
                    "urgency": stats?.urgencyScore ?? 0,
                    "rhythm": stats?.rhythm ?? "No data yet",
                    "colorHex": event.accentColorHex,
                    "streak": streak?.currentStreak ?? 0,
                ]
            }

        do {
            try session.updateApplicationContext(["events": watchEvents, "syncDate": Date().timeIntervalSince1970])
        } catch {
            print("Failed to send events to watch: \(error)")
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("WCSession activation failed: \(error)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    // Handle log request from watch
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let action = message["action"] as? String,
              action == "log",
              let eventID = message["eventID"] as? String else {
            replyHandler(["success": false])
            return
        }

        Task { @MainActor in
            let success = handleLogFromWatch(eventID: eventID)
            replyHandler(["success": success])
        }
    }

    // Also handle without reply
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let action = message["action"] as? String,
              action == "log",
              let eventID = message["eventID"] as? String else { return }

        Task { @MainActor in
            _ = handleLogFromWatch(eventID: eventID)
        }
    }

    // MARK: - Handle Log

    @MainActor
    private func handleLogFromWatch(eventID: String) -> Bool {
        guard let container = modelContainer else { return false }
        let context = container.mainContext

        let descriptor = FetchDescriptor<Event>(
            predicate: #Predicate<Event> { !$0.isArchived }
        )

        guard let events = try? context.fetch(descriptor),
              let event = events.first(where: { $0.id.uuidString == eventID }) else {
            return false
        }

        let log = LogEntry(timestamp: Date(), event: event)
        event.logs.append(log)
        context.insert(log)

        do {
            try context.save()
            NotificationService.shared.scheduleSmartReminders(for: event)
            // Sync updated data back to watch
            if let allEvents = try? context.fetch(FetchDescriptor<Event>()) {
                syncEventsToWatch(events: allEvents)
            }
            return true
        } catch {
            print("Failed to save log from watch: \(error)")
            return false
        }
    }
}
