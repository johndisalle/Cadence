import SwiftUI
import SwiftData

struct EventCardView: View {
    let event: Event
    @Environment(\.modelContext) private var modelContext

    private var stats: IntervalStats? {
        IntervalEngine.compute(for: event)
    }

    private var urgencyScore: Double {
        stats?.urgencyScore ?? 0
    }

    private var urgencyColor: Color {
        CadenceTheme.urgencyColor(score: urgencyScore)
    }

    private var isOverdue: Bool {
        stats?.isOverdue ?? false
    }

    private var isExpectedToday: Bool {
        guard let next = stats?.predictedNextDate else { return false }
        return Calendar.current.isDateInToday(next)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CadenceTheme.spacingSM) {
            // Top row: emoji + quick log
            HStack {
                Image(systemName: event.emoji)
                    .font(.system(size: 34))
                    .foregroundStyle(event.accentColor)

                Spacer()

                Button {
                    logNow()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(urgencyColor)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Log now")
            }

            // Event name
            Text(event.name)
                .font(.headline)
                .foregroundStyle(CadenceTheme.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            // Last done
            if let lastDate = event.lastLoggedDate {
                Text("Last done \(lastDate.timeAgoDisplay.lowercased())")
                    .font(.caption)
                    .foregroundStyle(CadenceTheme.textSecondary)
            } else {
                Text("Never logged")
                    .font(.caption)
                    .foregroundStyle(CadenceTheme.textTertiary)
            }

            // Rhythm
            if let rhythm = stats?.rhythm {
                Text(rhythm)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(CadenceTheme.textSecondary)
            }

            Spacer(minLength: 0)

            // Badges
            HStack(spacing: CadenceTheme.spacingXS) {
                if isOverdue {
                    badgeView(text: "Overdue", color: CadenceTheme.urgencyHigh)
                }
                if isExpectedToday {
                    badgeView(text: "Expected today", color: CadenceTheme.urgencyMedium)
                }
            }

            // Urgency accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(urgencyColor)
                .frame(height: 4)
                .opacity(0.8)
        }
        .cadenceCard(accent: event.accentColor)
    }

    // MARK: - Badge

    private func badgeView(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(color))
    }

    // MARK: - Log Action

    private func logNow() {
        let entry = LogEntry(timestamp: Date(), event: event)
        modelContext.insert(entry)

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Event.self, LogEntry.self, configurations: config)

    let event = Event(name: "Water Plants", emoji: "leaf.fill", accentColorHex: "#7FA886", category: .home)
    container.mainContext.insert(event)

    let log1 = LogEntry(timestamp: Date().addingTimeInterval(-86400 * 5), event: event)
    let log2 = LogEntry(timestamp: Date().addingTimeInterval(-86400 * 12), event: event)
    container.mainContext.insert(log1)
    container.mainContext.insert(log2)

    return EventCardView(event: event)
        .frame(width: 180)
        .padding()
        .modelContainer(container)
}
