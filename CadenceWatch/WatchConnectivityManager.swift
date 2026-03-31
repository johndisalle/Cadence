import WatchConnectivity
import Foundation
import Combine

// MARK: - WatchEvent

struct WatchEvent: Identifiable, Codable {
    let id: String
    let name: String
    let emoji: String
    let lastLoggedDate: Date
    let urgency: Double
    let rhythm: String
    let colorHex: String
    let streak: Int

    /// Human-readable time since last log, e.g. "2h ago", "3d ago"
    var timeSinceLog: String {
        let seconds = Date().timeIntervalSince(lastLoggedDate)
        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(seconds / 86400)
            return "\(days)d ago"
        }
    }

    /// Days since last log as an integer for complications
    var daysSinceLog: Int {
        max(0, Int(Date().timeIntervalSince(lastLoggedDate) / 86400))
    }

    /// Urgency tier for color coding
    var urgencyTier: UrgencyTier {
        if urgency < 0.4 {
            return .low
        } else if urgency < 0.7 {
            return .medium
        } else {
            return .high
        }
    }

    enum UrgencyTier {
        case low, medium, high

        var color: String {
            switch self {
            case .low: return "#4CAF50"
            case .medium: return "#FF9800"
            case .high: return "#F44336"
            }
        }
    }
}

// MARK: - WatchConnectivityManager

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var events: [WatchEvent] = []
    @Published var lastSyncDate: Date?
    @Published var isReachable: Bool = false

    private let eventsKey = "cachedWatchEvents"
    private let syncDateKey = "lastWatchSyncDate"

    private override init() {
        super.init()
        loadCachedEvents()
        activateSession()
    }

    // MARK: - Session

    private func activateSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - Sending

    /// Sends a log request to the iPhone for the given event ID.
    func logEvent(id: String) {
        guard WCSession.default.isReachable else {
            // Queue for when the phone becomes reachable
            let pending = UserDefaults.standard.array(forKey: "pendingLogs") as? [String] ?? []
            UserDefaults.standard.set(pending + [id], forKey: "pendingLogs")
            return
        }
        WCSession.default.sendMessage(
            ["action": "log", "eventID": id, "timestamp": Date().timeIntervalSince1970],
            replyHandler: nil,
            errorHandler: { error in
                print("[Watch] Failed to send log: \(error.localizedDescription)")
            }
        )
    }

    /// Requests fresh event data from the iPhone.
    func requestSync() {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(
            ["action": "requestSync"],
            replyHandler: nil,
            errorHandler: nil
        )
    }

    // MARK: - Persistence

    private func cacheEvents() {
        guard let data = try? JSONEncoder().encode(events) else { return }
        UserDefaults.standard.set(data, forKey: eventsKey)
        if let syncDate = lastSyncDate {
            UserDefaults.standard.set(syncDate.timeIntervalSince1970, forKey: syncDateKey)
        }
    }

    private func loadCachedEvents() {
        if let data = UserDefaults.standard.data(forKey: eventsKey),
           let cached = try? JSONDecoder().decode([WatchEvent].self, from: data) {
            events = cached.sorted { $0.urgency > $1.urgency }
        }
        let syncInterval = UserDefaults.standard.double(forKey: syncDateKey)
        if syncInterval > 0 {
            lastSyncDate = Date(timeIntervalSince1970: syncInterval)
        }
    }

    /// Flush any pending log requests that were queued while the phone was unreachable.
    private func flushPendingLogs() {
        guard let pending = UserDefaults.standard.array(forKey: "pendingLogs") as? [String],
              !pending.isEmpty else { return }
        for eventID in pending {
            WCSession.default.sendMessage(
                ["action": "log", "eventID": eventID, "timestamp": Date().timeIntervalSince1970],
                replyHandler: nil,
                errorHandler: nil
            )
        }
        UserDefaults.standard.removeObject(forKey: "pendingLogs")
    }

    // MARK: - Parsing

    private func parseEvents(from context: [String: Any]) {
        guard let eventDicts = context["events"] as? [[String: Any]] else { return }

        var parsed: [WatchEvent] = []
        for dict in eventDicts {
            guard let id = dict["id"] as? String,
                  let name = dict["name"] as? String,
                  let emoji = dict["emoji"] as? String,
                  let lastLoggedInterval = dict["lastLoggedDate"] as? Double,
                  let urgency = dict["urgency"] as? Double,
                  let rhythm = dict["rhythm"] as? String,
                  let colorHex = dict["colorHex"] as? String else {
                continue
            }
            let streak = dict["streak"] as? Int ?? 0
            let event = WatchEvent(
                id: id,
                name: name,
                emoji: emoji,
                lastLoggedDate: Date(timeIntervalSince1970: lastLoggedInterval),
                urgency: urgency,
                rhythm: rhythm,
                colorHex: colorHex,
                streak: streak
            )
            parsed.append(event)
        }

        DispatchQueue.main.async {
            self.events = parsed.sorted { $0.urgency > $1.urgency }
            self.lastSyncDate = Date()
            self.cacheEvents()
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
        if session.isReachable {
            flushPendingLogs()
        }
        // Load application context that may have arrived before activation
        if !session.receivedApplicationContext.isEmpty {
            parseEvents(from: session.receivedApplicationContext)
        }
    }

    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        parseEvents(from: applicationContext)
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        // Handle push updates from the phone (e.g. after a sync request)
        if message["type"] as? String == "eventsUpdate" {
            parseEvents(from: message)
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
        if session.isReachable {
            flushPendingLogs()
        }
    }
}
