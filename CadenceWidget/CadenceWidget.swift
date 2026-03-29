import WidgetKit
import SwiftUI

// MARK: - Widget Data

struct WidgetEvent: Identifiable {
    let id = UUID()
    let eventID: String
    let name: String
    let emoji: String
    let daysSince: Double
    let urgency: Double
    let rhythm: String
    let colorHex: String

    var timeAgo: String {
        if daysSince < 0.042 { return "Just now" }
        if daysSince < 1 {
            let hours = Int(daysSince * 24)
            return "\(hours)h ago"
        }
        let days = Int(daysSince)
        return days == 1 ? "1d ago" : "\(days)d ago"
    }

    var daysSinceLabel: String {
        if daysSince < 0.042 { return "0d" }
        if daysSince < 1 { return "\(Int(daysSince * 24))h" }
        return "\(Int(daysSince))d"
    }

    var urgencyIndicator: String {
        if urgency > 0.8 { return "!!" }
        if urgency > 0.5 { return "!" }
        return ""
    }

    var color: Color {
        Color(hex: colorHex)
    }
}

struct CadenceEntry: TimelineEntry {
    let date: Date
    let events: [WidgetEvent]
}

// MARK: - Color Extension (widget-local)

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Timeline Provider

struct CadenceTimelineProvider: TimelineProvider {

    func placeholder(in context: Context) -> CadenceEntry {
        CadenceEntry(
            date: Date(),
            events: [
                WidgetEvent(eventID: "1", name: "Medication", emoji: "pill.fill", daysSince: 0.5, urgency: 0.2, rhythm: "Daily", colorHex: "#5BA4A4"),
                WidgetEvent(eventID: "2", name: "Water Plants", emoji: "leaf.fill", daysSince: 2.8, urgency: 0.8, rhythm: "Every 3 days", colorHex: "#7FA886"),
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CadenceEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CadenceEntry>) -> Void) {
        // Read cached widget data from App Group shared UserDefaults
        let entry = loadFromSharedDefaults() ?? placeholder(in: context)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadFromSharedDefaults() -> CadenceEntry? {
        // Uses App Group shared defaults to read event data written by the main app.
        // The main app should write widget data to:
        //   UserDefaults(suiteName: "group.com.cadence.app")
        // For now, return nil to show placeholder until the main app writes data.
        guard let defaults = UserDefaults(suiteName: "group.com.cadence.app"),
              let data = defaults.data(forKey: "widgetEvents"),
              let decoded = try? JSONDecoder().decode([WidgetEventData].self, from: data) else {
            return nil
        }

        let events = decoded.map { item in
            WidgetEvent(
                eventID: item.eventID,
                name: item.name,
                emoji: item.emoji,
                daysSince: Date().timeIntervalSince(item.lastLogged) / 86400.0,
                urgency: item.urgency,
                rhythm: item.rhythm,
                colorHex: item.colorHex
            )
        }

        return CadenceEntry(date: Date(), events: events)
    }
}

/// Codable struct for passing data via App Group UserDefaults
struct WidgetEventData: Codable {
    let eventID: String
    let name: String
    let emoji: String
    let lastLogged: Date
    let urgency: Double
    let rhythm: String
    let colorHex: String
}

// MARK: - Small Widget View

struct CadenceWidgetSmallView: View {
    let entry: CadenceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "waveform.path")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Cadence")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if let event = entry.events.first {
                Spacer()
                Text(event.emoji)
                    .font(.system(size: 32))
                Text(event.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(event.timeAgo)
                    .font(.caption)
                    .foregroundStyle(event.color)
                Spacer()
            } else {
                Spacer()
                Text("No events yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .widgetURL(
            entry.events.first.map { event in
                URL(string: "cadence://event/\(event.eventID)")!
            }
        )
    }
}

// MARK: - Medium Widget View

struct CadenceWidgetMediumView: View {
    let entry: CadenceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "waveform.path")
                    .font(.caption2)
                Text("Cadence")
                    .font(.caption2.weight(.semibold))
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.secondary)

            if entry.events.isEmpty {
                Spacer()
                Text("Add events to see them here")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(entry.events.prefix(3)) { event in
                        Link(destination: URL(string: "cadence://event/\(event.eventID)")!) {
                            VStack(spacing: 4) {
                                Text(event.emoji)
                                    .font(.title2)
                                Text(event.name)
                                    .font(.caption2.weight(.medium))
                                    .lineLimit(1)
                                Text(event.timeAgo)
                                    .font(.caption2)
                                    .foregroundStyle(event.color)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(event.color.opacity(event.urgency > 0.7 ? 0.15 : 0.07))
                            )
                        }
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Large Widget View

struct CadenceWidgetLargeView: View {
    let entry: CadenceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "waveform.path")
                    .font(.caption)
                Text("Cadence")
                    .font(.caption.weight(.semibold))
                Spacer()
            }
            .foregroundStyle(.secondary)

            ForEach(entry.events.prefix(6)) { event in
                HStack(spacing: 12) {
                    Text(event.emoji)
                        .font(.title3)
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.name)
                            .font(.subheadline.weight(.medium))
                        Text(event.rhythm)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(event.timeAgo)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(event.color)
                        if event.urgency > 0.7 {
                            Text("Overdue")
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding(.vertical, 4)

                if event.id != entry.events.prefix(6).last?.id {
                    Divider()
                }
            }

            if entry.events.isEmpty {
                Spacer()
                Text("Add events to start tracking")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            }
        }
        .padding()
    }
}

// MARK: - Lock Screen Circular

struct CadenceWidgetAccessoryCircularView: View {
    let entry: CadenceEntry

    var body: some View {
        if let event = entry.events.first {
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 1) {
                    Text(event.emoji)
                        .font(.title3)
                    Text(event.daysSinceLabel)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(event.urgency > 0.7 ? .red : .primary)
                }
            }
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "waveform.path")
                    .font(.title3)
            }
        }
    }
}

// MARK: - Lock Screen Rectangular

struct CadenceWidgetAccessoryRectangularView: View {
    let entry: CadenceEntry

    var body: some View {
        if entry.events.isEmpty {
            VStack(alignment: .leading) {
                Text("Cadence")
                    .font(.headline)
                    .widgetAccentable()
                Text("No events tracked")
                    .font(.caption)
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(entry.events.prefix(2)) { event in
                    HStack(spacing: 4) {
                        Text(event.emoji)
                            .font(.caption)
                        Text(event.name)
                            .font(.caption.weight(.medium))
                            .lineLimit(1)
                        Spacer()
                        Text(event.daysSinceLabel)
                            .font(.caption.weight(.bold))
                        if !event.urgencyIndicator.isEmpty {
                            Text(event.urgencyIndicator)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Widget Entry View

struct CadenceWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: CadenceEntry

    var body: some View {
        switch family {
        case .systemSmall:
            CadenceWidgetSmallView(entry: entry)
        case .systemMedium:
            CadenceWidgetMediumView(entry: entry)
        case .systemLarge:
            CadenceWidgetLargeView(entry: entry)
        case .accessoryCircular:
            CadenceWidgetAccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            CadenceWidgetAccessoryRectangularView(entry: entry)
        default:
            CadenceWidgetMediumView(entry: entry)
        }
    }
}

// MARK: - Widget Definition

struct CadenceWidget: Widget {
    let kind: String = "CadenceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CadenceTimelineProvider()) { entry in
            CadenceWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Cadence")
        .description("Track life's natural rhythm at a glance.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

// MARK: - Widget Bundle

@main
struct CadenceWidgetBundle: WidgetBundle {
    var body: some Widget {
        CadenceWidget()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    CadenceWidget()
} timeline: {
    CadenceEntry(date: Date(), events: [
        WidgetEvent(eventID: "1", name: "Medication", emoji: "pill.fill", daysSince: 0.5, urgency: 0.2, rhythm: "Daily", colorHex: "#5BA4A4"),
    ])
}

#Preview("Medium", as: .systemMedium) {
    CadenceWidget()
} timeline: {
    CadenceEntry(date: Date(), events: [
        WidgetEvent(eventID: "1", name: "Medication", emoji: "pill.fill", daysSince: 0.5, urgency: 0.2, rhythm: "Daily", colorHex: "#5BA4A4"),
        WidgetEvent(eventID: "2", name: "Plants", emoji: "leaf.fill", daysSince: 2.8, urgency: 0.8, rhythm: "Every 3 days", colorHex: "#7FA886"),
        WidgetEvent(eventID: "3", name: "Exercise", emoji: "figure.run", daysSince: 1.2, urgency: 0.4, rhythm: "Every 2 days", colorHex: "#E07A6B"),
    ])
}

#Preview("Large", as: .systemLarge) {
    CadenceWidget()
} timeline: {
    CadenceEntry(date: Date(), events: [
        WidgetEvent(eventID: "1", name: "Medication", emoji: "pill.fill", daysSince: 0.5, urgency: 0.2, rhythm: "Daily", colorHex: "#5BA4A4"),
        WidgetEvent(eventID: "2", name: "Water Plants", emoji: "leaf.fill", daysSince: 2.8, urgency: 0.8, rhythm: "Every 3 days", colorHex: "#7FA886"),
        WidgetEvent(eventID: "3", name: "Exercise", emoji: "figure.run", daysSince: 1.2, urgency: 0.4, rhythm: "Every 2 days", colorHex: "#E07A6B"),
    ])
}
