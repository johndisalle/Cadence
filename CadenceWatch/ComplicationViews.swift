import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct CadenceComplicationEntry: TimelineEntry {
    let date: Date
    let events: [WatchEvent]

    static var placeholder: CadenceComplicationEntry {
        CadenceComplicationEntry(
            date: .now,
            events: [
                WatchEvent(
                    id: "placeholder-1",
                    name: "Water Plants",
                    emoji: "leaf.fill",
                    lastLoggedDate: Date().addingTimeInterval(-86400 * 3),
                    urgency: 0.7,
                    rhythm: "Every 5 days",
                    colorHex: "#5BA4A4",
                    streak: 3
                ),
                WatchEvent(
                    id: "placeholder-2",
                    name: "Vitamins",
                    emoji: "pill.fill",
                    lastLoggedDate: Date().addingTimeInterval(-86400),
                    urgency: 0.3,
                    rhythm: "Daily",
                    colorHex: "#FF9800",
                    streak: 7
                )
            ]
        )
    }

    static var empty: CadenceComplicationEntry {
        CadenceComplicationEntry(date: .now, events: [])
    }
}

// MARK: - Timeline Provider

struct CadenceComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> CadenceComplicationEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (CadenceComplicationEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CadenceComplicationEntry>) -> Void) {
        let entry = loadEntry()
        // Refresh every 30 minutes so time-ago labels stay fresh
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> CadenceComplicationEntry {
        guard let data = UserDefaults.standard.data(forKey: "cachedWatchEvents"),
              let events = try? JSONDecoder().decode([WatchEvent].self, from: data) else {
            return .empty
        }
        let sorted = events.sorted { $0.urgency > $1.urgency }
        return CadenceComplicationEntry(date: .now, events: sorted)
    }
}

// MARK: - Circular Complication

struct CircularComplicationView: View {
    let entry: CadenceComplicationEntry

    var body: some View {
        if let top = entry.events.first {
            ZStack {
                AccessoryWidgetBackground()

                VStack(spacing: 1) {
                    Image(systemName: top.emoji)
                        .font(.system(size: 14))
                        .widgetAccentable()

                    Text("\(top.daysSinceLog)d")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .minimumScaleFactor(0.7)
                }
            }
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "metronome")
                    .font(.system(size: 18))
                    .widgetAccentable()
            }
        }
    }
}

// MARK: - Rectangular Complication

struct RectangularComplicationView: View {
    let entry: CadenceComplicationEntry

    var body: some View {
        if entry.events.isEmpty {
            HStack {
                Image(systemName: "metronome")
                    .widgetAccentable()
                Text("No events")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(alignment: .leading, spacing: 3) {
                ForEach(Array(entry.events.prefix(2))) { event in
                    HStack(spacing: 6) {
                        Image(systemName: event.emoji)
                            .font(.caption2)
                            .widgetAccentable()
                            .frame(width: 14)

                        Text(event.name)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .lineLimit(1)

                        Spacer()

                        Text(event.timeSinceLog)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Corner Complication

struct CornerComplicationView: View {
    let entry: CadenceComplicationEntry

    var body: some View {
        if let top = entry.events.first {
            Image(systemName: top.emoji)
                .font(.system(size: 20))
                .widgetAccentable()
                .widgetLabel {
                    Gauge(value: min(top.urgency, 1.0)) {
                        Text("\(top.daysSinceLog)d")
                    }
                    .gaugeStyle(.accessoryLinear)
                }
        } else {
            Image(systemName: "metronome")
                .font(.system(size: 20))
                .widgetAccentable()
                .widgetLabel("Cadence")
        }
    }
}

// MARK: - Widget

struct CadenceComplication: Widget {
    let kind = "CadenceComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CadenceComplicationProvider()) { entry in
            switch entry.widgetFamily {
            case .accessoryCircular:
                CircularComplicationView(entry: entry)
            case .accessoryRectangular:
                RectangularComplicationView(entry: entry)
            case .accessoryCorner:
                CornerComplicationView(entry: entry)
            default:
                CircularComplicationView(entry: entry)
            }
        }
        .configurationDisplayName("Cadence")
        .description("See your most urgent events at a glance.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner
        ])
    }
}

// Helper to access widget family inside the entry view
private extension CadenceComplicationEntry {
    var widgetFamily: WidgetFamily {
        // This is resolved at runtime by the widget system
        .accessoryCircular
    }
}

// MARK: - Previews

#Preview("Circular", as: .accessoryCircular) {
    CadenceComplication()
} timeline: {
    CadenceComplicationEntry.placeholder
}

#Preview("Rectangular", as: .accessoryRectangular) {
    CadenceComplication()
} timeline: {
    CadenceComplicationEntry.placeholder
}

#Preview("Corner", as: .accessoryCorner) {
    CadenceComplication()
} timeline: {
    CadenceComplicationEntry.placeholder
}
