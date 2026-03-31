import Foundation

enum TrendDirection {
    case improving  // intervals getting shorter (more consistent)
    case declining  // intervals getting longer
    case steady

    var icon: String {
        switch self {
        case .improving: return "arrow.down.right"
        case .declining: return "arrow.up.right"
        case .steady: return "equal"
        }
    }

    var colorHex: String {
        switch self {
        case .improving: return "#7FA886"
        case .declining: return "#E07A6B"
        case .steady: return "#6B7B8D"
        }
    }
}

struct IntervalStats {
    let averageDays: Double
    let medianDays: Double
    let trendDays: Double
    let confidencePercent: Double
    let predictedNextDate: Date?
    let isOverdue: Bool
    let overdueByDays: Double
    let rhythm: String
    let insight: String
    let urgencyScore: Double // 0.0 (just done) to 1.0 (very overdue)
}

struct IntervalEngine {

    static func compute(for event: Event) -> IntervalStats? {
        let sorted = event.logs.sorted { $0.timestamp < $1.timestamp }
        guard sorted.count >= 2 else {
            return singleLogStats(event: event)
        }

        let intervals = zip(sorted.dropFirst(), sorted).map { later, earlier in
            later.timestamp.timeIntervalSince(earlier.timestamp) / 86400.0
        }

        let avg = intervals.reduce(0, +) / Double(intervals.count)
        let median = Self.median(intervals)

        // Last-5 trend
        let recentIntervals = Array(intervals.suffix(5))
        let trend = recentIntervals.isEmpty ? avg : recentIntervals.reduce(0, +) / Double(recentIntervals.count)

        // Confidence based on consistency
        let stddev = Self.standardDeviation(intervals)
        let cv = avg > 0 ? stddev / avg : 1.0
        let confidence = max(0, min(100, (1.0 - cv) * 100))

        // Weighted prediction: 40% trend, 35% median, 25% average
        let predicted = trend * 0.4 + median * 0.35 + avg * 0.25
        let lastDate = sorted.last!.timestamp
        let nextDate = lastDate.addingTimeInterval(predicted * 86400)

        let daysSinceLast = Date().timeIntervalSince(lastDate) / 86400.0
        let isOverdue = daysSinceLast > predicted
        let overdueBy = max(0, daysSinceLast - predicted)

        // Urgency: 0 at log time, 1 at 1.5x predicted interval
        let urgency = min(1.0, max(0, daysSinceLast / (predicted * 1.5)))

        let rhythm = Self.rhythmDescription(days: predicted)
        let insight = Self.generateInsight(
            event: event,
            avg: avg,
            trend: trend,
            daysSinceLast: daysSinceLast,
            predicted: predicted,
            logCount: sorted.count
        )

        return IntervalStats(
            averageDays: avg,
            medianDays: median,
            trendDays: trend,
            confidencePercent: confidence,
            predictedNextDate: nextDate,
            isOverdue: isOverdue,
            overdueByDays: overdueBy,
            rhythm: rhythm,
            insight: insight,
            urgencyScore: urgency
        )
    }

    private static func singleLogStats(event: Event) -> IntervalStats? {
        guard let log = event.logs.first else { return nil }
        let daysSince = Date().timeIntervalSince(log.timestamp) / 86400.0
        return IntervalStats(
            averageDays: 0,
            medianDays: 0,
            trendDays: 0,
            confidencePercent: 0,
            predictedNextDate: nil,
            isOverdue: false,
            overdueByDays: 0,
            rhythm: "Not enough data",
            insight: "Log a few more times so Cadence can learn your rhythm.",
            urgencyScore: min(1.0, daysSince / 30.0)
        )
    }

    static func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        let count = sorted.count
        if count == 0 { return 0 }
        if count % 2 == 0 {
            return (sorted[count / 2 - 1] + sorted[count / 2]) / 2.0
        } else {
            return sorted[count / 2]
        }
    }

    static func standardDeviation(_ values: [Double]) -> Double {
        let count = Double(values.count)
        guard count > 1 else { return 0 }
        let avg = values.reduce(0, +) / count
        let sumOfSquares = values.reduce(0) { $0 + ($1 - avg) * ($1 - avg) }
        return (sumOfSquares / (count - 1)).squareRoot()
    }

    static func rhythmDescription(days: Double) -> String {
        if days < 1 {
            let hours = Int(days * 24)
            return "Every \(max(1, hours)) hours"
        } else if days < 1.5 {
            return "Daily"
        } else if days < 2.5 {
            return "Every other day"
        } else if days < 6 {
            return "Every \(Int(round(days))) days"
        } else if days < 9 {
            return "Weekly"
        } else if days < 16 {
            return "Every \(Int(round(days / 7))) weeks"
        } else if days < 25 {
            return "Every ~3 weeks"
        } else if days < 45 {
            return "Monthly"
        } else if days < 75 {
            return "Every ~2 months"
        } else if days < 100 {
            return "Quarterly"
        } else if days < 200 {
            return "Every ~\(Int(round(days / 30))) months"
        } else if days < 400 {
            return "Twice a year"
        } else {
            return "Yearly"
        }
    }

    static func generateInsight(
        event: Event,
        avg: Double,
        trend: Double,
        daysSinceLast: Double,
        predicted: Double,
        logCount: Int
    ) -> String {
        let name = event.name

        if daysSinceLast < predicted * 0.5 {
            return "You're ahead of schedule on \(name) — nice rhythm!"
        } else if daysSinceLast > predicted * 1.3 {
            let overdue = Int(daysSinceLast - predicted)
            return "\(name) is about \(overdue) day\(overdue == 1 ? "" : "s") past your usual rhythm."
        } else if abs(trend - avg) > avg * 0.2 {
            if trend < avg {
                return "Your \(name) cadence is getting faster — from ~\(Int(avg))d avg to ~\(Int(trend))d recently."
            } else {
                return "Your \(name) intervals are stretching out — from ~\(Int(avg))d to ~\(Int(trend))d."
            }
        } else if logCount > 10 {
            return "Solid \(rhythmDescription(days: predicted).lowercased()) rhythm for \(name). \(logCount) logs and counting!"
        } else {
            return "Usually every \(Int(round(predicted))) days. Keep logging to sharpen the prediction."
        }
    }

    static func intervals(for event: Event) -> [Double] {
        let sorted = event.logs.sorted { $0.timestamp < $1.timestamp }
        guard sorted.count >= 2 else { return [] }
        return zip(sorted.dropFirst(), sorted).map { later, earlier in
            later.timestamp.timeIntervalSince(earlier.timestamp) / 86400.0
        }
    }

    static func trend(for event: Event) -> TrendDirection {
        let intervals = self.intervals(for: event)
        guard intervals.count >= 4 else { return .steady }

        let recent = intervals.suffix(3)
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let overallAvg = intervals.reduce(0, +) / Double(intervals.count)

        guard overallAvg > 0 else { return .steady }
        let ratio = recentAvg / overallAvg
        if ratio < 0.85 { return .improving }
        if ratio > 1.15 { return .declining }
        return .steady
    }

    static func dueSoonestScore(for event: Event) -> Double {
        guard let stats = compute(for: event) else {
            return event.logs.isEmpty ? 0.5 : 0.1
        }
        return stats.urgencyScore
    }
}
