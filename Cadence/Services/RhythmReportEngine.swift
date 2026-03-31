import Foundation

// MARK: - Report Models

struct MonthlyReport {
    let month: String
    let totalLogs: Int
    let activeEvents: Int
    let mostConsistentEvent: String?
    let mostConsistentEmoji: String?
    let consistencyPercent: Int?
    let busiestDay: String?
    let insights: [String]
}

struct YearInReview {
    let year: String
    let totalLogs: Int
    let totalEvents: Int
    let mostConsistent: (name: String, emoji: String, percent: Int)?
    let mostImproved: (name: String, emoji: String)?
    let longestStreak: (name: String, emoji: String, days: Int)?
    let busiestMonth: String?
    let averageLogsPerWeek: Double
    let insights: [String]
}

// MARK: - Engine

struct RhythmReportEngine {

    // MARK: - Monthly Report

    static func monthlyReport(events: [Event], month: Date = Date()) -> MonthlyReport {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: month)
        guard let monthStart = calendar.date(from: components),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return MonthlyReport(month: formattedMonth(month), totalLogs: 0, activeEvents: 0,
                                 mostConsistentEvent: nil, mostConsistentEmoji: nil,
                                 consistencyPercent: nil, busiestDay: nil, insights: [])
        }

        let activeEvents = events.filter { !$0.isArchived }

        // Collect all logs in the month
        var allMonthLogs: [(event: Event, log: LogEntry)] = []
        for event in activeEvents {
            for log in event.logs where log.timestamp >= monthStart && log.timestamp < monthEnd {
                allMonthLogs.append((event, log))
            }
        }

        let totalLogs = allMonthLogs.count
        let eventsWithLogs = Set(allMonthLogs.map { $0.event.name })
        let activeCount = eventsWithLogs.count

        // Busiest day of week
        let busiestDay = findBusiestDay(logs: allMonthLogs.map { $0.log })

        // Most consistent event (lowest coefficient of variation)
        var bestConsistency: (name: String, emoji: String, percent: Int)?
        var bestCV = Double.infinity

        for event in activeEvents {
            let intervals = IntervalEngine.intervals(for: event)
            guard intervals.count >= 2 else { continue }
            let avg = intervals.reduce(0, +) / Double(intervals.count)
            guard avg > 0 else { continue }
            let stddev = IntervalEngine.standardDeviation(intervals)
            let cv = stddev / avg
            let confidence = max(0, min(100, (1.0 - cv) * 100))

            if cv < bestCV {
                bestCV = cv
                bestConsistency = (name: event.name, emoji: event.emoji, percent: Int(round(confidence)))
            }
        }

        // Count missed events (events with logs before this month but none in it)
        var missedEvents: [String] = []
        for event in activeEvents {
            let hasLogsBefore = event.logs.contains { $0.timestamp < monthStart }
            let hasLogsInMonth = event.logs.contains { $0.timestamp >= monthStart && $0.timestamp < monthEnd }
            if hasLogsBefore && !hasLogsInMonth {
                missedEvents.append(event.name)
            }
        }

        // Find events with shortening intervals
        var shorteningEvents: [String] = []
        for event in activeEvents {
            let intervals = IntervalEngine.intervals(for: event)
            guard intervals.count >= 4 else { continue }
            let firstHalf = Array(intervals.prefix(intervals.count / 2))
            let secondHalf = Array(intervals.suffix(intervals.count / 2))
            let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
            let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
            if secondAvg < firstAvg * 0.85 {
                shorteningEvents.append(event.name)
            }
        }

        // Generate insights
        var insights: [String] = []

        if activeCount > 0 {
            insights.append("You logged \(totalLogs) time\(totalLogs == 1 ? "" : "s") across \(activeCount) event\(activeCount == 1 ? "" : "s").")
        }

        if let best = bestConsistency, best.percent > 50 {
            insights.append("Your most consistent rhythm: \(best.name) (\(best.percent)% on time).")
        }

        if let day = busiestDay {
            insights.append("\(day)s are your most active day.")
        }

        for name in shorteningEvents.prefix(1) {
            insights.append("\(name) intervals are getting shorter \u{2014} you're ahead of schedule!")
        }

        for name in missedEvents.prefix(1) {
            insights.append("You missed \(name) this month.")
        }

        return MonthlyReport(
            month: formattedMonth(month),
            totalLogs: totalLogs,
            activeEvents: activeCount,
            mostConsistentEvent: bestConsistency?.name,
            mostConsistentEmoji: bestConsistency?.emoji,
            consistencyPercent: bestConsistency?.percent,
            busiestDay: busiestDay,
            insights: Array(insights.prefix(5))
        )
    }

    // MARK: - Year in Review

    static func yearInReview(events: [Event], year: Int = Calendar.current.component(.year, from: Date())) -> YearInReview {
        let calendar = Calendar.current
        var yearStartComponents = DateComponents()
        yearStartComponents.year = year
        yearStartComponents.month = 1
        yearStartComponents.day = 1
        guard let yearStart = calendar.date(from: yearStartComponents),
              let yearEnd = calendar.date(byAdding: .year, value: 1, to: yearStart) else {
            return YearInReview(year: "\(year)", totalLogs: 0, totalEvents: 0,
                                mostConsistent: nil, mostImproved: nil, longestStreak: nil,
                                busiestMonth: nil, averageLogsPerWeek: 0, insights: [])
        }

        let activeEvents = events.filter { !$0.isArchived }

        // Collect logs for the year
        var totalLogs = 0
        var eventsWithLogs = Set<String>()
        var monthCounts = [Int: Int]()

        for event in activeEvents {
            for log in event.logs where log.timestamp >= yearStart && log.timestamp < yearEnd {
                totalLogs += 1
                eventsWithLogs.insert(event.name)
                let m = calendar.component(.month, from: log.timestamp)
                monthCounts[m, default: 0] += 1
            }
        }

        // Most consistent
        var bestConsistent: (name: String, emoji: String, percent: Int)?
        var bestCV = Double.infinity
        for event in activeEvents {
            let intervals = IntervalEngine.intervals(for: event)
            guard intervals.count >= 2 else { continue }
            let avg = intervals.reduce(0, +) / Double(intervals.count)
            guard avg > 0 else { continue }
            let stddev = IntervalEngine.standardDeviation(intervals)
            let cv = stddev / avg
            let confidence = max(0, min(100, (1.0 - cv) * 100))
            if cv < bestCV {
                bestCV = cv
                bestConsistent = (name: event.name, emoji: event.emoji, percent: Int(round(confidence)))
            }
        }

        // Most improved (biggest decrease in interval variance between first half and second half)
        var bestImprovement: (name: String, emoji: String, improvement: Double)?
        for event in activeEvents {
            let intervals = IntervalEngine.intervals(for: event)
            guard intervals.count >= 4 else { continue }
            let half = intervals.count / 2
            let firstHalf = Array(intervals.prefix(half))
            let secondHalf = Array(intervals.suffix(half))
            let firstVar = IntervalEngine.standardDeviation(firstHalf)
            let secondVar = IntervalEngine.standardDeviation(secondHalf)
            guard firstVar > 0 else { continue }
            let improvement = (firstVar - secondVar) / firstVar
            if improvement > 0, improvement > (bestImprovement?.improvement ?? 0) {
                bestImprovement = (name: event.name, emoji: event.emoji, improvement: improvement)
            }
        }

        // Longest streak
        var longestStreakResult: (name: String, emoji: String, days: Int)?
        for event in activeEvents {
            if let streak = StreakEngine.compute(for: event) {
                let best = max(streak.currentStreak, streak.longestStreak)
                if best > (longestStreakResult?.days ?? 0) {
                    longestStreakResult = (name: event.name, emoji: event.emoji, days: best)
                }
            }
        }

        // Busiest month
        let busiestMonthNum = monthCounts.max(by: { $0.value < $1.value })?.key
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"
        let busiestMonth: String? = {
            guard let m = busiestMonthNum else { return nil }
            var comps = DateComponents()
            comps.month = m
            comps.day = 1
            comps.year = year
            guard let date = calendar.date(from: comps) else { return nil }
            return monthFormatter.string(from: date)
        }()

        // Average logs per week
        let now = Date()
        let effectiveEnd = min(now, yearEnd)
        let weeksInRange = max(1, effectiveEnd.timeIntervalSince(yearStart) / (7 * 86400))
        let avgPerWeek = Double(totalLogs) / weeksInRange

        // Insights
        var insights: [String] = []
        insights.append("You logged \(totalLogs) time\(totalLogs == 1 ? "" : "s") across \(eventsWithLogs.count) event\(eventsWithLogs.count == 1 ? "" : "s") in \(year).")

        if let best = bestConsistent {
            insights.append("\(best.name) was your most consistent rhythm at \(best.percent)%.")
        }
        if let improved = bestImprovement {
            insights.append("\(improved.name) showed the most improvement over time.")
        }
        if let streak = longestStreakResult {
            insights.append("Your longest streak was \(streak.days) entries for \(streak.name).")
        }
        if let month = busiestMonth {
            insights.append("\(month) was your busiest month.")
        }

        return YearInReview(
            year: "\(year)",
            totalLogs: totalLogs,
            totalEvents: eventsWithLogs.count,
            mostConsistent: bestConsistent,
            mostImproved: bestImprovement.map { (name: $0.name, emoji: $0.emoji) },
            longestStreak: longestStreakResult,
            busiestMonth: busiestMonth,
            averageLogsPerWeek: avgPerWeek,
            insights: Array(insights.prefix(5))
        )
    }

    // MARK: - Helpers

    private static func formattedMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private static func findBusiestDay(logs: [LogEntry]) -> String? {
        guard !logs.isEmpty else { return nil }
        let calendar = Calendar.current
        var dayCounts = [Int: Int]()
        for log in logs {
            let weekday = calendar.component(.weekday, from: log.timestamp)
            dayCounts[weekday, default: 0] += 1
        }
        guard let busiestWeekday = dayCounts.max(by: { $0.value < $1.value })?.key else {
            return nil
        }
        let formatter = DateFormatter()
        return formatter.weekdaySymbols[busiestWeekday - 1]
    }
}
