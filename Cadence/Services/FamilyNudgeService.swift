import Foundation

struct FamilyNudge {
    let eventName: String
    let emoji: String
    let message: String
    let shareText: String
}

struct FamilyNudgeService {
    static func createNudge(for event: Event) -> FamilyNudge {
        let stats = IntervalEngine.compute(for: event)
        let daysSince = event.daysSinceLastLog.map { Int($0) } ?? 0

        let message: String
        if let stats = stats, stats.isOverdue {
            let overdue = Int(stats.overdueByDays)
            message = "Hey! \(event.name) is overdue by \(overdue) day\(overdue == 1 ? "" : "s"). Can you take care of it?"
        } else if daysSince > 0 {
            message = "Hey! It's been \(daysSince) day\(daysSince == 1 ? "" : "s") since \(event.name) was last done. Can you handle it?"
        } else {
            message = "Hey! \(event.name) needs to be done. Can you take care of it?"
        }

        let shareText = """
        \(message)

        Tracked with Cadence — Track life's natural rhythm
        https://apps.apple.com/app/cadence
        """

        return FamilyNudge(
            eventName: event.name,
            emoji: event.emoji,
            message: message,
            shareText: shareText
        )
    }
}
