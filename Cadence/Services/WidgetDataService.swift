import Foundation
import SwiftData
import WidgetKit

struct WidgetEventData: Codable {
    let eventID: String
    let name: String
    let emoji: String
    let lastLogged: Date
    let urgency: Double
    let rhythm: String
    let colorHex: String
}

struct WidgetDataService {
    static func writeToSharedDefaults(events: [Event]) {
        guard let defaults = UserDefaults(suiteName: "group.com.cadence.app") else { return }

        let widgetEvents = events
            .filter { !$0.isArchived }
            .compactMap { event -> WidgetEventData? in
                let stats = IntervalEngine.compute(for: event)
                return WidgetEventData(
                    eventID: event.id.uuidString,
                    name: event.name,
                    emoji: event.emoji,
                    lastLogged: event.lastLoggedDate ?? event.createdAt,
                    urgency: stats?.urgencyScore ?? 0,
                    rhythm: stats?.rhythm ?? "No data",
                    colorHex: event.accentColorHex
                )
            }
            .sorted { $0.urgency > $1.urgency }

        if let data = try? JSONEncoder().encode(Array(widgetEvents.prefix(6))) {
            defaults.set(data, forKey: "widgetEvents")
        }

        WidgetCenter.shared.reloadAllTimelines()
    }
}
