import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

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
                WidgetEvent(name: "Medication", emoji: "💊", daysSince: 0.5, urgency: 0.2, rhythm: "Daily", colorHex: "#5BA4A4"),
                WidgetEvent(name: "Water Plants", emoji: "🪴", daysSince: 2.8, urgency: 0.8, rhythm: "Every 3 days", colorHex: "#7FA886"),
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
                            .foregroundStyle(Color(hex: event.colorHex))
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
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

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
        default:
            CadenceWidgetMediumView(entry: entry)
        }
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
        WidgetEvent(name: "Medication", emoji: "💊", daysSince: 0.5, urgency: 0.2, rhythm: "Daily", colorHex: "#5BA4A4"),
    ])
}

#Preview("Medium", as: .systemMedium) {
    CadenceWidget()
} timeline: {
    CadenceEntry(date: Date(), events: [
        WidgetEvent(name: "Medication", emoji: "💊", daysSince: 0.5, urgency: 0.2, rhythm: "Daily", colorHex: "#5BA4A4"),
        WidgetEvent(name: "Plants", emoji: "🪴", daysSince: 2.8, urgency: 0.8, rhythm: "Every 3 days", colorHex: "#7FA886"),
        WidgetEvent(name: "Exercise", emoji: "🏃", daysSince: 1.2, urgency: 0.4, rhythm: "Every 2 days", colorHex: "#E07A6B"),
    ])
}
