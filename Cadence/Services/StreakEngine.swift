import Foundation

struct StreakInfo {
    let currentStreak: Int
    let longestStreak: Int
    let isOnStreak: Bool
    let streakStartDate: Date?
    let nextDueDate: Date?
}

struct StreakEngine {

    /// Computes streak information for an event based on its log history
    /// and predicted intervals. A streak is maintained when each log happens
    /// within 1.5x the predicted interval from the previous log.
    static func compute(for event: Event) -> StreakInfo? {
        let sorted = event.logs.sorted { $0.timestamp < $1.timestamp }
        guard sorted.count >= 2 else {
            // With 0 or 1 logs, there's no streak to compute
            if sorted.count == 1 {
                return StreakInfo(
                    currentStreak: 1,
                    longestStreak: 1,
                    isOnStreak: true,
                    streakStartDate: sorted.first?.timestamp,
                    nextDueDate: nil
                )
            }
            return nil
        }

        // Compute intervals between consecutive logs
        let intervals = zip(sorted.dropFirst(), sorted).map { later, earlier in
            later.timestamp.timeIntervalSince(earlier.timestamp) / 86400.0
        }

        // Use a rolling predicted interval to determine "on-time"
        // For each pair, the threshold is 1.5x the running average up to that point
        var currentStreak = 1  // first log always counts
        var longestStreak = 1
        var streakStartIndex = 0
        var currentStreakStartIndex = 0

        for i in 0..<intervals.count {
            // Compute running average of all intervals up to (but not including) this one
            let threshold: Double
            if i == 0 {
                // For the first interval, use that interval itself as baseline
                // (always considered on-time for streak start)
                threshold = intervals[0] * 1.5
            } else {
                let priorIntervals = Array(intervals[0..<i])
                let avg = priorIntervals.reduce(0, +) / Double(priorIntervals.count)
                threshold = avg * 1.5
            }

            if intervals[i] <= threshold {
                currentStreak += 1
            } else {
                // Streak broken
                if currentStreak > longestStreak {
                    longestStreak = currentStreak
                    streakStartIndex = currentStreakStartIndex
                }
                currentStreak = 1
                currentStreakStartIndex = i + 1
            }
        }

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        // Determine if the current streak is still active
        // (i.e., we haven't exceeded 1.5x the predicted interval since the last log)
        let stats = IntervalEngine.compute(for: event)
        let predictedDays = stats?.trendDays ?? stats?.averageDays ?? 0
        let lastLogDate = sorted.last!.timestamp
        let daysSinceLast = Date().timeIntervalSince(lastLogDate) / 86400.0

        let isOnStreak: Bool
        if predictedDays > 0 {
            isOnStreak = daysSinceLast <= predictedDays * 1.5
        } else {
            isOnStreak = currentStreak > 1
        }

        // If not on streak, reset current streak to 0
        let effectiveCurrentStreak = isOnStreak ? currentStreak : 0

        // Next due date to maintain streak
        let nextDueDate: Date? = {
            guard predictedDays > 0 else { return nil }
            return lastLogDate.addingTimeInterval(predictedDays * 1.5 * 86400)
        }()

        let streakStart = sorted[currentStreakStartIndex].timestamp

        return StreakInfo(
            currentStreak: effectiveCurrentStreak,
            longestStreak: longestStreak,
            isOnStreak: isOnStreak,
            streakStartDate: streakStart,
            nextDueDate: nextDueDate
        )
    }
}
