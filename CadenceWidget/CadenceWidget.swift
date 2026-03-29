import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// NOTE: In a production Xcode project, Event, LogEntry, IntervalEngine, and Color+Hex
// would live in a shared framework (e.g. "CadenceKit") that both the main app and the
// widget extension link against. For now, these model files must be added to the widget
// target's Compile Sources in Build Phases.

// MARK: - Timeline Provider

struct CadenceTimelineProvider: TimelineProvider {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([Event.self, LogEntry.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            self.modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Widget ModelContainer failed: \(error)")
        }
    }

    func placeholder(in context: Context) -> CadenceEntry {
        CadenceEntry(
            date: Date(),
            events: [
                WidgetEvent(eventID: UUID().uuidString, name: "Medication", emoji: "💊", daysSince: 0.5, urgency: 0.2, rhythm: "Daily", colorHex: "#5BA4A4"),
                WidgetEvent(eventID: UUID().uuidString, name: "Water Plants", emoji: "🪴", daysSince: 2.8, urgency: 0.8, rhythm: "Every 3 days", colorHex: "#7FA886"),
            ]
        )
    }

    @MainActor
    func getSnapshot(in context: Context, completion: @escaping (CadenceEntry) -> Void) {
        let entry = buildEntry()
        completion(entry)
    }

    @MainActor
    func getTimeline(in context: Context, completion: @escaping (Timeline<CadenceEntry>) -> Void) {
        let entry = buildEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    @MainActor
    private func buildEntry() -> CadenceEntry {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Event>(
            predicate: #Predicate<Event> { !$0.isArchived }
        )

        let events = (try? context.fetch(descriptor)) ?? []
        let widgetEvents = events
            .compactMap { event -> WidgetEvent? in
                let stats = IntervalEngine.compute(for: event)
                let daysSince = event.daysSinceLastLog ?? 0
                return WidgetEvent(
                    eventID: event.id.uuidString,
                    name: event.name,
                    emoji: event.emoji,
                    daysSince: daysSince,
                    urgency: stats?.urgencyScore ?? 0,
                    rhythm: stats?.rhythm ?? "No data",
                    colorHex: event.accentColorHex
                )
            }
            .sorted { $0.urgency > $1.urgency }

        return CadenceEntry(date: Date(), events: Array(widgetEvents.prefix(6)))
    }
}

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

    /// Days-since formatted for compact display (lock screen)
    var daysSinceLabel: String {
        if daysSince < 0.042 { return "0d" }
        if daysSince < 1 { return "\(Int(daysSince * 24))h" }
        return "\(Int(daysSince))d"
    }

    /// Urgency indicator symbol for lock screen
    var urgencyIndicator: String {
        if urgency > 0.8 { return "!!" }
        if urgency > 0.5 { return "!" }
        return ""
    }
}

struct CadenceEntry: TimelineEntry {
    let date: Date
    let events: [WidgetEvent]
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
                    .foregroundStyle(Color(hex: event.colorHex))
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

// MARK: - Medium Widget View (Interactive Log Buttons)

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
                        ZStack(alignment: .topTrailing) {
                            Link(destination: URL(string: "cadence://event/\(event.eventID)")!) {
                                VStack(spacing: 4) {
                                    Text(event.emoji)
                                        .font(.title2)
                                    Text(event.name)
                                        .font(.caption2.weight(.medium))
                                        .lineLimit(1)
                                    Text(event.timeAgo)
                                        .font(.caption2)
                                        .foregroundStyle(Color(hex: event.colorHex))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(hex: event.colorHex).opacity(event.urgency > 0.7 ? 0.15 : 0.07))
                                )
                            }

                            // Interactive log button (iOS 17+)
                            Button(intent: LogEventFromWidgetIntent(eventID: event.eventID)) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: event.colorHex))
                            }
                            .buttonStyle(.plain)
                            .padding(4)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Large Widget View (Interactive Log Buttons)

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
                            .foregroundStyle(Color(hex: event.colorHex))
                        if event.urgency > 0.7 {
                            Text("Overdue")
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }

                    // Interactive log button (iOS 17+)
                    Button(intent: LogEventFromWidgetIntent(eventID: event.eventID)) {
                        Label("Log", systemImage: "checkmark.circle.fill")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color(hex: event.colorHex))
                            )
                    }
                    .buttonStyle(.plain)
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

// MARK: - Lock Screen Circular Widget View

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

// MARK: - Lock Screen Rectangular Widget View

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
        WidgetEvent(eventID: "preview-1", name: "Medication", emoji: "💊", daysSince: 0.5, urgency: 0.2, rhythm: "Daily", colorHex: "#5BA4A4"),
    ])
}

#Preview("Medium", as: .systemMedium) {
    CadenceWidget()
} timeline: {
    CadenceEntry(date: Date(), events: [
        WidgetEvent(eventID: "preview-1", name: "Medication", emoji: "💊", daysSince: 0.5, urgency: 0.2, rhythm: "Daily", colorHex: "#5BA4A4"),
        WidgetEvent(eventID: "preview-2", name: "Plants", emoji: "🪴", daysSince: 2.8, urgency: 0.8, rhythm: "Every 3 days", colorHex: "#7FA886"),
        WidgetEvent(eventID: "preview-3", name: "Exercise", emoji: "🏃", daysSince: 1.2, urgency: 0.4, rhythm: "Every 2 days", colorHex: "#E07A6B"),
    ])
}

#Preview("Large", as: .systemLarge) {
    CadenceWidget()
} timeline: {
    CadenceEntry(date: Date(), events: [
        WidgetEvent(eventID: "preview-1", name: "Medication", emoji: "💊", daysSince: 0.5, urgency: 0.2, rhythm: "Daily", colorHex: "#5BA4A4"),
        WidgetEvent(eventID: "preview-2", name: "Water Plants", emoji: "🪴", daysSince: 2.8, urgency: 0.8, rhythm: "Every 3 days", colorHex: "#7FA886"),
        WidgetEvent(eventID: "preview-3", name: "Exercise", emoji: "🏃", daysSince: 1.2, urgency: 0.4, rhythm: "Every 2 days", colorHex: "#E07A6B"),
        WidgetEvent(eventID: "preview-4", name: "Laundry", emoji: "🧺", daysSince: 5.0, urgency: 0.9, rhythm: "Weekly", colorHex: "#C4A86B"),
        WidgetEvent(eventID: "preview-5", name: "Call Mom", emoji: "📞", daysSince: 3.0, urgency: 0.6, rhythm: "Every 5 days", colorHex: "#A07CC5"),
    ])
}

#Preview("Lock Screen Circular", as: .accessoryCircular) {
    CadenceWidget()
} timeline: {
    CadenceEntry(date: Date(), events: [
        WidgetEvent(eventID: "preview-1", name: "Medication", emoji: "💊", daysSince: 0.5, urgency: 0.2, rhythm: "Daily", colorHex: "#5BA4A4"),
    ])
}

#Preview("Lock Screen Rectangular", as: .accessoryRectangular) {
    CadenceWidget()
} timeline: {
    CadenceEntry(date: Date(), events: [
        WidgetEvent(eventID: "preview-1", name: "Medication", emoji: "💊", daysSince: 0.5, urgency: 0.2, rhythm: "Daily", colorHex: "#5BA4A4"),
        WidgetEvent(eventID: "preview-2", name: "Water Plants", emoji: "🪴", daysSince: 2.8, urgency: 0.8, rhythm: "Every 3 days", colorHex: "#7FA886"),
    ])
}
