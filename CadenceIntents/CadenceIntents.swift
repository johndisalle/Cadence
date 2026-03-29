import AppIntents
import SwiftData
import Foundation
import WidgetKit

// MARK: - Log Event Intent (Siri + Shortcuts + Widgets)

struct LogEventIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Event in Cadence"
    static var description: IntentDescription = "Quickly log that you've done something in Cadence"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Event Name")
    var eventName: String

    init() {}

    init(eventName: String) {
        self.eventName = eventName
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: Event.self, LogEntry.self)
        let context = container.mainContext

        let descriptor = FetchDescriptor<Event>(
            predicate: #Predicate<Event> { event in
                event.name == eventName && !event.isArchived
            }
        )

        guard let event = try context.fetch(descriptor).first else {
            return .result(dialog: "Couldn't find an event called \"\(eventName)\" in Cadence.")
        }

        let log = LogEntry(timestamp: Date(), event: event)
        context.insert(log)
        event.logs.append(log)
        try context.save()

        NotificationService.shared.scheduleSmartReminders(for: event)

        let stats = IntervalEngine.compute(for: event)
        let rhythm = stats?.rhythm ?? "Keep logging!"

        return .result(dialog: "\(event.emoji) Logged \(event.name)! \(rhythm)")
    }
}

// MARK: - Log Event From Widget Intent (iOS 17+ Interactive Widgets)

struct LogEventFromWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Log Event"
    static var description: IntentDescription = "Log an event from a widget"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Event ID")
    var eventID: String

    init() {}

    init(eventID: String) {
        self.eventID = eventID
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let container = try ModelContainer(for: Event.self, LogEntry.self)
        let context = container.mainContext

        let descriptor = FetchDescriptor<Event>(
            predicate: #Predicate<Event> { !$0.isArchived }
        )

        let events = try context.fetch(descriptor)

        guard let event = events.first(where: { $0.id.uuidString == eventID }) else {
            return .result()
        }

        let log = LogEntry(timestamp: Date(), event: event)
        context.insert(log)
        event.logs.append(log)
        try context.save()

        NotificationService.shared.scheduleSmartReminders(for: event)

        // Reload widget timelines so the widget updates immediately after logging
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}

// MARK: - Shortcuts Provider
//
// Note: AppShortcut phrases with dynamic parameters require AppEnum/AppEntity types.
// LogEventIntent uses a plain String parameter, so it's available in the Shortcuts app
// but not as a predefined Siri phrase. Users can create custom Siri Shortcuts manually.

// MARK: - Get Due Events Intent

struct GetDueEventsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Due Events"
    static var description: IntentDescription = "See which events are due or overdue in Cadence"

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: Event.self, LogEntry.self)
        let context = container.mainContext

        let descriptor = FetchDescriptor<Event>(
            predicate: #Predicate<Event> { !$0.isArchived }
        )

        let events = try context.fetch(descriptor)
        let overdueEvents = events.compactMap { event -> (Event, IntervalStats)? in
            guard let stats = IntervalEngine.compute(for: event), stats.isOverdue else { return nil }
            return (event, stats)
        }

        if overdueEvents.isEmpty {
            return .result(dialog: "All caught up! Nothing overdue in Cadence. ✨")
        }

        let names = overdueEvents.prefix(5).map { "\($0.0.emoji) \($0.0.name)" }.joined(separator: ", ")
        return .result(dialog: "\(overdueEvents.count) overdue: \(names)")
    }
}
