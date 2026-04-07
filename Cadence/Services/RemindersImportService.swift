import EventKit
import Foundation

struct ImportableReminder: Identifiable {
    let id: String
    let title: String
    let completionDates: [Date]
    let listName: String
    let suggestedEmoji: String
    let suggestedColor: String

    var completionCount: Int { completionDates.count }
}

final class RemindersImportService {
    static let shared = RemindersImportService()
    private let eventStore = EKEventStore()

    func requestAccess() async -> Bool {
        do {
            return try await eventStore.requestFullAccessToReminders()
        } catch {
            return false
        }
    }

    func fetchImportableReminders() async -> [ImportableReminder] {
        let calendars = eventStore.calendars(for: .reminder)
        let twoYearsAgo = Calendar.current.date(byAdding: .year, value: -2, to: Date())!
        let predicate = eventStore.predicateForCompletedReminders(
            withCompletionDateStarting: twoYearsAgo,
            ending: Date(),
            calendars: calendars
        )

        let reminders: [EKReminder]
        do {
            reminders = try await withCheckedThrowingContinuation { continuation in
                eventStore.fetchReminders(matching: predicate) { result in
                    continuation.resume(returning: result ?? [])
                }
            }
        } catch {
            return []
        }

        // Group by title (case-insensitive)
        var grouped: [String: (dates: [Date], listName: String, originalTitle: String)] = [:]
        for reminder in reminders {
            let key = reminder.title?.trimmingCharacters(in: .whitespaces).lowercased() ?? ""
            guard !key.isEmpty else { continue }
            let originalTitle = reminder.title?.trimmingCharacters(in: .whitespaces) ?? key
            let date = reminder.completionDate ?? Date()
            let listName = reminder.calendar?.title ?? "Reminders"

            if grouped[key] != nil {
                grouped[key]!.dates.append(date)
            } else {
                grouped[key] = (dates: [date], listName: listName, originalTitle: originalTitle)
            }
        }

        // Only include reminders with 2+ completions
        return grouped.compactMap { key, value in
            guard value.dates.count >= 2 else { return nil }
            let title = value.originalTitle
            let (emoji, color) = suggestEmojiAndColor(for: title)
            return ImportableReminder(
                id: key,
                title: title,
                completionDates: value.dates.sorted(),
                listName: value.listName,
                suggestedEmoji: emoji,
                suggestedColor: color
            )
        }
        .sorted { $0.completionCount > $1.completionCount }
    }

    private func suggestEmojiAndColor(for title: String) -> (String, String) {
        let lower = title.lowercased()

        let keywords: [(keywords: [String], emoji: String, color: String)] = [
            (["oil", "oil change"], "oilcan.fill", "#C4A882"),
            (["plant", "water plant", "garden"], "leaf.fill", "#7FA886"),
            (["medication", "pill", "medicine", "vitamin", "supplement"], "pill.fill", "#5BA4A4"),
            (["exercise", "gym", "workout", "run", "jog"], "figure.run", "#E07A6B"),
            (["dentist", "teeth", "dental", "floss"], "mouth.fill", "#7EB5D6"),
            (["haircut", "hair", "barber"], "scissors", "#9B8EC4"),
            (["car", "vehicle", "tire", "gas"], "car.fill", "#C4A882"),
            (["clean", "vacuum", "mop", "dust"], "sparkles", "#7EB5D6"),
            (["laundry", "wash clothes"], "washer.fill", "#D4849A"),
            (["dog", "cat", "pet", "flea", "vet"], "pawprint.fill", "#E07A6B"),
            (["call", "phone", "parents", "mom", "dad"], "phone.fill", "#D4849A"),
            (["filter", "hvac", "furnace", "ac"], "fan.fill", "#7EB5D6"),
            (["bed", "sheet", "linen"], "bed.double.fill", "#9B8EC4"),
            (["budget", "finance", "bill", "pay"], "chart.bar.fill", "#2C3E5A"),
            (["backup", "phone", "computer"], "iphone.gen3", "#6B7B8D"),
            (["eye", "vision", "glasses", "contacts"], "eye.fill", "#9B8EC4"),
        ]

        for entry in keywords {
            if entry.keywords.contains(where: { lower.contains($0) }) {
                return (entry.emoji, entry.color)
            }
        }

        return ("pin.fill", "#5BA4A4")
    }
}
