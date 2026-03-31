import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func scheduleReminder(for event: Event, in days: Double) {
        let content = UNMutableNotificationContent()
        content.title = event.name
        content.body = "It's time to log \(event.name). Tap to record it now!"
        content.sound = .default
        content.categoryIdentifier = "EVENT_REMINDER"
        content.userInfo = ["eventID": event.id.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(60, days * 86400),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "cadence-\(event.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleSmartReminders(for event: Event) {
        cancelReminders(for: event)

        guard let stats = IntervalEngine.compute(for: event),
              let nextDate = stats.predictedNextDate else { return }

        let daysUntil = Date().daysUntil(nextDate)

        if daysUntil > 0 {
            scheduleReminder(for: event, in: daysUntil)
        } else {
            // Already overdue — remind in 1 hour
            scheduleReminder(for: event, in: 1.0 / 24.0)
        }
    }

    func cancelReminders(for event: Event) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["cadence-\(event.id.uuidString)"]
        )
    }

    func registerCategories() {
        let logAction = UNNotificationAction(
            identifier: "LOG_NOW",
            title: "Log Now ✓",
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Remind Later",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: "EVENT_REMINDER",
            actions: [logAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
