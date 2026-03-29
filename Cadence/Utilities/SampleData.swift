import Foundation
import SwiftData

struct SampleData {
    @MainActor
    static func populate(context: ModelContext) {
        let events = createSampleEvents()
        for event in events {
            context.insert(event)
        }
        try? context.save()
    }

    static func createSampleEvents() -> [Event] {
        let now = Date()
        let cal = Calendar.current

        // Medication — daily-ish
        let medication = Event(name: "Medication", emoji: "💊", accentColorHex: "#5BA4A4", category: .health)
        for i in 0..<30 {
            let date = cal.date(byAdding: .day, value: -i, to: now)!
            let jitter = Double.random(in: -2...2) * 3600
            let log = LogEntry(timestamp: date.addingTimeInterval(jitter))
            medication.logs.append(log)
        }

        // Water Plants — every 3 days
        let plants = Event(name: "Water Plants", emoji: "🪴", accentColorHex: "#7FA886", category: .home)
        for i in stride(from: 0, to: 60, by: 3) {
            let jitter = Int.random(in: -1...1)
            let date = cal.date(byAdding: .day, value: -(i + jitter), to: now)!
            let log = LogEntry(timestamp: date)
            plants.logs.append(log)
        }

        // Oil Change — every 3 months
        let oil = Event(name: "Oil Change", emoji: "🛢️", accentColorHex: "#C4A882", category: .vehicle)
        for i in stride(from: 0, to: 365, by: 90) {
            let jitter = Int.random(in: -7...7)
            let date = cal.date(byAdding: .day, value: -(i + jitter), to: now)!
            let log = LogEntry(timestamp: date, notes: i == 0 ? "Synthetic blend" : nil)
            oil.logs.append(log)
        }

        // Haircut — every 3-4 weeks
        let haircut = Event(name: "Haircut", emoji: "✂️", accentColorHex: "#9B8EC4", category: .personal)
        for i in stride(from: 0, to: 300, by: 25) {
            let jitter = Int.random(in: -3...3)
            let date = cal.date(byAdding: .day, value: -(i + jitter), to: now)!
            let log = LogEntry(timestamp: date)
            haircut.logs.append(log)
        }

        // Dentist — every 6 months
        let dentist = Event(name: "Dentist", emoji: "🦷", accentColorHex: "#7EB5D6", category: .health)
        for i in stride(from: 30, to: 730, by: 180) {
            let date = cal.date(byAdding: .day, value: -i, to: now)!
            let log = LogEntry(timestamp: date, notes: "Cleaning + checkup")
            dentist.logs.append(log)
        }

        // Exercise
        let exercise = Event(name: "Exercise", emoji: "🏃", accentColorHex: "#E07A6B", category: .health)
        for i in stride(from: 0, to: 90, by: 2) {
            let skip = Int.random(in: 0...4)
            if skip == 0 { continue }
            let date = cal.date(byAdding: .day, value: -i, to: now)!
            let log = LogEntry(timestamp: date)
            exercise.logs.append(log)
        }

        return [medication, plants, oil, haircut, dentist, exercise]
    }
}
