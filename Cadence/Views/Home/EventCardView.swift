import SwiftUI
import SwiftData

struct EventCardView: View {
    let event: Event
    @Environment(\.modelContext) private var modelContext

    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var logBounceScale: CGFloat = 1.0
    @State private var lastLogEntry: LogEntry?
    @State private var showLogSuccess = false
    @State private var logPulse = false

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

    private var trend: TrendDirection {
        IntervalEngine.trend(for: event)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CadenceTheme.spacingSM) {
            // Top row: emoji + quick log
            HStack {
                Image(systemName: event.emoji)
                    .font(.system(size: 34))
                    .foregroundStyle(event.accentColor)
                    .background(
                        Circle()
                            .fill(event.accentColor.opacity(0.10))
                            .frame(width: 50, height: 50)
                    )

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
                .font(.headline.weight(.semibold))
                .foregroundStyle(CadenceTheme.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            // Live-updating "time since"
            if let lastDate = event.lastLoggedDate {
                TimelineView(.periodic(from: .now, by: 60)) { _ in
                    Text(lastDate.liveDurationDisplay)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CadenceTheme.textSecondary)
                }
            } else {
                Text("Never logged")
                    .font(.subheadline)
                    .foregroundStyle(CadenceTheme.textTertiary)
            }

            // Rhythm + trend arrow
            if let rhythm = stats?.rhythm {
                HStack(spacing: 4) {
                    Text(rhythm)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(CadenceTheme.textSecondary)

                    if trend != .steady {
                        Image(systemName: trend.icon)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color(hex: trend.colorHex))
                    }
                }
            }

            Spacer(minLength: 0)

            // Badges
            HStack(spacing: CadenceTheme.spacingXS) {
                if let streak = StreakEngine.compute(for: event), streak.currentStreak >= 3 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                        Text("\(streak.currentStreak)")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(CadenceTheme.coral))
                }
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
        .padding(CadenceTheme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: CadenceTheme.cardCornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            event.accentColor.opacity(logPulse ? 0.20 : 0.06),
                            event.accentColor.opacity(logPulse ? 0.30 : 0.15)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.06), radius: CadenceTheme.cardShadowRadius, y: 4)
        )
        .overlay(
            Group {
                if showLogSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 54, weight: .bold))
                        .foregroundStyle(event.accentColor)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        )
        .scaleEffect(logBounceScale)
        .toast(isShowing: $showToast, message: toastMessage, icon: "checkmark.circle.fill") {
            undoLastLog()
        }
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
        event.logs.append(entry)
        modelContext.insert(entry)
        lastLogEntry = entry

        // Success bounce animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            logBounceScale = 1.08
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                logBounceScale = 1.0
            }
        }

        // Checkmark overlay
        withAnimation(.easeOut(duration: 0.3)) {
            showLogSuccess = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeIn(duration: 0.3)) {
                showLogSuccess = false
            }
        }

        // Color pulse
        withAnimation(.easeOut(duration: 0.25)) {
            logPulse = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.35)) {
                logPulse = false
            }
        }

        // Show toast
        if let stats = IntervalEngine.compute(for: event),
           let nextDate = stats.predictedNextDate {
            let daysUntil = max(1, Int(Date().daysUntil(nextDate)))
            toastMessage = "Logged! Next in ~\(daysUntil)d"
        } else {
            toastMessage = "Logged \(event.name)!"
        }
        showToast = true

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        NotificationService.shared.scheduleSmartReminders(for: event)
    }

    private func undoLastLog() {
        guard let log = lastLogEntry else { return }
        event.logs.removeAll { $0.id == log.id }
        modelContext.delete(log)
        lastLogEntry = nil
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
