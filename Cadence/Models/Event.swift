import Foundation
import SwiftData
import SwiftUI

@Model
final class Event {
    var id: UUID = UUID()
    var name: String = ""
    var emoji: String = "📌"
    var accentColorHex: String = "#5BA4A4"
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \LogEntry.event)
    var logs: [LogEntry] = []
    var customNotes: String?
    var isArchived: Bool = false
    var categoryRaw: String = "general"
    var sortOrder: Int = 0
    var isShared: Bool = false
    var locationReminder: String?

    var category: EventCategory {
        get { EventCategory(rawValue: categoryRaw) ?? .general }
        set { categoryRaw = newValue.rawValue }
    }

    var accentColor: Color {
        Color(hex: accentColorHex)
    }

    var sortedLogs: [LogEntry] {
        logs.sorted { $0.timestamp > $1.timestamp }
    }

    var lastLog: LogEntry? {
        sortedLogs.first
    }

    var lastLoggedDate: Date? {
        lastLog?.timestamp
    }

    var daysSinceLastLog: Double? {
        guard let last = lastLoggedDate else { return nil }
        return Date().timeIntervalSince(last) / 86400
    }

    init(
        name: String,
        emoji: String = "📌",
        accentColorHex: String = "#5BA4A4",
        category: EventCategory = .general,
        customNotes: String? = nil,
        isShared: Bool = false,
        locationReminder: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.accentColorHex = accentColorHex
        self.createdAt = Date()
        self.logs = []
        self.customNotes = customNotes
        self.isArchived = false
        self.categoryRaw = category.rawValue
        self.sortOrder = 0
        self.isShared = isShared
        self.locationReminder = locationReminder
    }
}

enum EventCategory: String, CaseIterable, Identifiable {
    case general = "general"
    case health = "health"
    case home = "home"
    case vehicle = "vehicle"
    case personal = "personal"
    case pets = "pets"
    case work = "work"

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .general: return "square.grid.2x2"
        case .health: return "heart.fill"
        case .home: return "house.fill"
        case .vehicle: return "car.fill"
        case .personal: return "person.fill"
        case .pets: return "pawprint.fill"
        case .work: return "briefcase.fill"
        }
    }
}
