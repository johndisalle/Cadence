import Foundation

struct CadencePulse {
    let overallScore: Int // 0-100
    let eventSummaries: [EventSummary]
    let suggestions: [String]
    let weeklyMessage: String
}

struct EventSummary {
    let eventName: String
    let emoji: String
    let logsThisWeek: Int
    let logsLastWeek: Int
    let trend: TrendDirection
    let onTrack: Bool
}

enum TrendDirection {
    case up, down, steady

    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .steady: return "arrow.right"
        }
    }

    var label: String {
        switch self {
        case .up: return "Increasing"
        case .down: return "Decreasing"
        case .steady: return "Steady"
        }
    }
}

struct InsightsEngine {

    static func generatePulse(events: [Event]) -> CadencePulse {
        let activeEvents = events.filter { !$0.isArchived }
        let now = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: now)!

        var summaries: [EventSummary] = []
        var onTrackCount = 0

        for event in activeEvents {
            let thisWeek = event.logs.filter { $0.timestamp >= weekAgo }
            let lastWeek = event.logs.filter { $0.timestamp >= twoWeeksAgo && $0.timestamp < weekAgo }

            let stats = IntervalEngine.compute(for: event)
            let onTrack: Bool
            if let stats = stats {
                onTrack = !stats.isOverdue
            } else {
                onTrack = !event.logs.isEmpty
            }

            if onTrack { onTrackCount += 1 }

            let trend: TrendDirection
            if thisWeek.count > lastWeek.count {
                trend = .up
            } else if thisWeek.count < lastWeek.count {
                trend = .down
            } else {
                trend = .steady
            }

            summaries.append(EventSummary(
                eventName: event.name,
                emoji: event.emoji,
                logsThisWeek: thisWeek.count,
                logsLastWeek: lastWeek.count,
                trend: trend,
                onTrack: onTrack
            ))
        }

        let score: Int
        if activeEvents.isEmpty {
            score = 100
        } else {
            score = Int(Double(onTrackCount) / Double(activeEvents.count) * 100)
        }

        let suggestions = generateSuggestions(events: activeEvents)
        let weeklyMessage = generateWeeklyMessage(score: score, eventCount: activeEvents.count)

        return CadencePulse(
            overallScore: score,
            eventSummaries: summaries,
            suggestions: suggestions,
            weeklyMessage: weeklyMessage
        )
    }

    static func generateSuggestions(events: [Event]) -> [String] {
        var suggestions: [String] = []

        // Find events logged on the same day frequently
        let eventsByDay = findCoOccurringEvents(events: events)
        for (pair, count) in eventsByDay where count >= 3 {
            suggestions.append("You often do \(pair.0) and \(pair.1) on the same day — want to create a combined routine?")
        }

        // Seasonal awareness
        let month = Calendar.current.component(.month, from: Date())
        let isSpring = (3...5).contains(month)
        let isSummer = (6...8).contains(month)
        let isFall = (9...11).contains(month)

        for event in events {
            let name = event.name.lowercased()
            if (name.contains("plant") || name.contains("water") || name.contains("garden")) {
                if isSummer {
                    suggestions.append("Summer tip: Plants need more water in the heat — consider shortening your \(event.name) interval.")
                } else if isFall {
                    suggestions.append("Fall tip: Most plants need less frequent watering as temps drop.")
                }
            }
            if name.contains("hvac") || name.contains("filter") || name.contains("furnace") {
                if isSpring || isFall {
                    suggestions.append("Seasonal reminder: It's a good time to check your \(event.name)!")
                }
            }
        }

        // Overdue events
        let overdueEvents = events.compactMap { event -> (Event, IntervalStats)? in
            guard let stats = IntervalEngine.compute(for: event), stats.isOverdue else { return nil }
            return (event, stats)
        }.sorted { $0.1.overdueByDays > $1.1.overdueByDays }

        if overdueEvents.count >= 3 {
            suggestions.append("You have \(overdueEvents.count) overdue items — a quick catch-up session could knock them all out!")
        }

        // Consistency praise
        let consistentEvents = events.filter { event in
            guard let stats = IntervalEngine.compute(for: event) else { return false }
            return stats.confidencePercent > 80 && !stats.isOverdue
        }

        if !consistentEvents.isEmpty {
            let names = consistentEvents.prefix(2).map { $0.name }.joined(separator: " and ")
            suggestions.append("Great consistency with \(names)! Your rhythm is rock solid. 🎯")
        }

        return Array(suggestions.prefix(5))
    }

    static func findCoOccurringEvents(events: [Event]) -> [(pair: (String, String), count: Int)] {
        var dayMap: [String: Set<String>] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for event in events {
            for log in event.logs {
                let key = formatter.string(from: log.timestamp)
                dayMap[key, default: []].insert(event.name)
            }
        }

        var pairCounts: [String: Int] = [:]
        var pairNames: [String: (String, String)] = [:]

        for (_, eventNames) in dayMap where eventNames.count >= 2 {
            let sorted = eventNames.sorted()
            for i in 0..<sorted.count {
                for j in (i + 1)..<sorted.count {
                    let key = "\(sorted[i])|\(sorted[j])"
                    pairCounts[key, default: 0] += 1
                    pairNames[key] = (sorted[i], sorted[j])
                }
            }
        }

        return pairCounts
            .filter { $0.value >= 2 }
            .compactMap { key, count in
                guard let pair = pairNames[key] else { return nil }
                return (pair, count)
            }
            .sorted { $0.count > $1.count }
    }

    static func generateWeeklyMessage(score: Int, eventCount: Int) -> String {
        if eventCount == 0 {
            return "Add some events to start tracking your life's cadence!"
        }
        switch score {
        case 90...100:
            return "Your life is flowing beautifully at \(score)% this week. Everything's on rhythm! ✨"
        case 70..<90:
            return "Solid week at \(score)%! A few things could use attention, but you're doing great."
        case 50..<70:
            return "Your cadence is at \(score)% — some rhythms need a reset. You've got this!"
        default:
            return "A few things have fallen behind (\(score)%). Pick one item to get back on track today."
        }
    }
}
