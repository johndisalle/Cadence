import Foundation

extension Date {
    var timeAgoDisplay: String {
        let interval = Date().timeIntervalSince(self)
        let seconds = Int(interval)
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24
        let weeks = days / 7
        let months = days / 30

        if seconds < 60 {
            return "Just now"
        } else if minutes < 60 {
            return "\(minutes) min ago"
        } else if hours < 24 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if days < 7 {
            return days == 1 ? "Yesterday" : "\(days) days ago"
        } else if weeks < 5 {
            return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
        } else if months < 12 {
            return months == 1 ? "1 month ago" : "\(months) months ago"
        } else {
            let years = months / 12
            return years == 1 ? "1 year ago" : "\(years) years ago"
        }
    }

    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    var dayOnlyFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    func daysUntil(_ other: Date) -> Double {
        other.timeIntervalSince(self) / 86400.0
    }

    var liveDurationDisplay: String {
        let interval = Date().timeIntervalSince(self)
        let minutes = Int(interval) / 60
        let hours = minutes / 60
        let days = hours / 24

        if minutes < 1 { return "just now" }
        if minutes < 60 { return "\(minutes)m ago" }
        if hours < 24 { return "\(hours)h \(minutes % 60)m ago" }
        if days < 7 { return "\(days)d \(hours % 24)h ago" }
        if days < 30 { return "\(days / 7)w \(days % 7)d ago" }
        return "\(days / 30)mo ago"
    }
}
