import Foundation

struct Milestone {
    let title: String
    let subtitle: String
    let icon: String
    let isConfetti: Bool
}

struct MilestoneEngine {

    /// Checks whether a milestone has been reached after a new log.
    /// Returns the most significant milestone if multiple apply.
    static func check(event: Event, newLogCount: Int) -> Milestone? {
        // Check streak-based milestones first (higher priority)
        if let streakMilestone = checkStreakMilestone(for: event) {
            return streakMilestone
        }

        // Check log-count milestones
        return checkLogCountMilestone(count: newLogCount)
    }

    // MARK: - Log Count Milestones

    private static func checkLogCountMilestone(count: Int) -> Milestone? {
        switch count {
        case 1:
            return Milestone(
                title: "First Step!",
                subtitle: "Every rhythm starts with one",
                icon: "star.fill",
                isConfetti: false
            )
        case 10:
            return Milestone(
                title: "Getting Started!",
                subtitle: "You're building a pattern",
                icon: "flame.fill",
                isConfetti: false
            )
        case 25:
            return Milestone(
                title: "Quarter Century!",
                subtitle: "Consistency is your superpower",
                icon: "bolt.fill",
                isConfetti: false
            )
        case 50:
            return Milestone(
                title: "Half Century!",
                subtitle: "This is officially a habit",
                icon: "trophy.fill",
                isConfetti: false
            )
        case 100:
            return Milestone(
                title: "Triple Digits!",
                subtitle: "You're a Cadence master",
                icon: "crown.fill",
                isConfetti: true
            )
        default:
            return nil
        }
    }

    // MARK: - Streak Milestones

    private static func checkStreakMilestone(for event: Event) -> Milestone? {
        guard let streak = StreakEngine.compute(for: event) else { return nil }
        let current = streak.currentStreak

        // Only fire at exact milestone boundaries
        switch current {
        case 25:
            return Milestone(
                title: "Legendary!",
                subtitle: "Your consistency is extraordinary",
                icon: "star.circle.fill",
                isConfetti: true
            )
        case 10:
            return Milestone(
                title: "Unstoppable!",
                subtitle: "10 consecutive on-time logs",
                icon: "flame.circle.fill",
                isConfetti: true
            )
        case 5:
            return Milestone(
                title: "On Fire!",
                subtitle: "5 in a row, right on rhythm",
                icon: "flame.fill",
                isConfetti: false
            )
        default:
            return nil
        }
    }

    /// Checks if all provided events were logged on time this week.
    static func checkPerfectWeek(events: [Event]) -> Milestone? {
        guard !events.isEmpty else { return nil }

        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return nil
        }

        for event in events {
            guard let stats = IntervalEngine.compute(for: event),
                  let predicted = stats.predictedNextDate else {
                // If we can't compute stats, skip this event
                continue
            }

            // Check if the event was expected this week and was logged on time
            if predicted < now && predicted >= weekStart {
                // This event was due this week
                let hasOnTimeLog = event.logs.contains { log in
                    log.timestamp >= weekStart && log.timestamp <= now
                }
                if !hasOnTimeLog {
                    return nil
                }
            }
        }

        return Milestone(
            title: "Perfect Week!",
            subtitle: "Every single event on rhythm",
            icon: "checkmark.seal.fill",
            isConfetti: true
        )
    }
}
