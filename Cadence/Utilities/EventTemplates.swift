import Foundation

// MARK: - Event Template

struct EventTemplate: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let emoji: String
    let category: EventCategory
    let accentColorHex: String
    let suggestedIntervalDays: Int
    let subtitle: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(emoji)
    }

    static func == (lhs: EventTemplate, rhs: EventTemplate) -> Bool {
        lhs.name == rhs.name && lhs.emoji == rhs.emoji
    }
}

// MARK: - Quick Start Pack

struct QuickStartPack: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let description: String
    let templates: [EventTemplate]

    var count: Int { templates.count }
}

// MARK: - Template Library

extension EventTemplate {

    // MARK: Health & Wellness

    static let takeMedication = EventTemplate(
        name: "Take Medication",
        emoji: "pill.fill",
        category: .health,
        accentColorHex: "#5BA4A4",
        suggestedIntervalDays: 1,
        subtitle: "Track daily doses"
    )

    static let exercise = EventTemplate(
        name: "Exercise",
        emoji: "figure.run",
        category: .health,
        accentColorHex: "#E07A6B",
        suggestedIntervalDays: 2,
        subtitle: "Stay active and consistent"
    )

    static let dentistVisit = EventTemplate(
        name: "Dentist Visit",
        emoji: "mouth.fill",
        category: .health,
        accentColorHex: "#7EB5D6",
        suggestedIntervalDays: 180,
        subtitle: "Biannual checkups"
    )

    static let eyeExam = EventTemplate(
        name: "Eye Exam",
        emoji: "eye.fill",
        category: .health,
        accentColorHex: "#9B8EC4",
        suggestedIntervalDays: 365,
        subtitle: "Annual vision check"
    )

    static let haircut = EventTemplate(
        name: "Haircut",
        emoji: "scissors",
        category: .personal,
        accentColorHex: "#9B8EC4",
        suggestedIntervalDays: 28,
        subtitle: "Keep looking fresh"
    )

    static let weighIn = EventTemplate(
        name: "Weigh In",
        emoji: "scalemass.fill",
        category: .health,
        accentColorHex: "#5BA4A4",
        suggestedIntervalDays: 7,
        subtitle: "Weekly progress check"
    )

    // MARK: Home & Garden

    static let waterPlants = EventTemplate(
        name: "Water Plants",
        emoji: "leaf.fill",
        category: .home,
        accentColorHex: "#7FA886",
        suggestedIntervalDays: 3,
        subtitle: "Keep them thriving"
    )

    static let changeHVACFilter = EventTemplate(
        name: "Change HVAC Filter",
        emoji: "fan.fill",
        category: .home,
        accentColorHex: "#7EB5D6",
        suggestedIntervalDays: 90,
        subtitle: "Breathe cleaner air"
    )

    static let cleanHouse = EventTemplate(
        name: "Clean House",
        emoji: "sparkles",
        category: .home,
        accentColorHex: "#C4A882",
        suggestedIntervalDays: 7,
        subtitle: "Weekly deep clean"
    )

    static let laundry = EventTemplate(
        name: "Laundry",
        emoji: "washer.fill",
        category: .home,
        accentColorHex: "#D4849A",
        suggestedIntervalDays: 4,
        subtitle: "Stay on top of it"
    )

    static let changeBedSheets = EventTemplate(
        name: "Change Bed Sheets",
        emoji: "bed.double.fill",
        category: .home,
        accentColorHex: "#9B8EC4",
        suggestedIntervalDays: 14,
        subtitle: "Fresh sheets, better sleep"
    )

    static let mowLawn = EventTemplate(
        name: "Mow Lawn",
        emoji: "leaf.arrow.circlepath",
        category: .home,
        accentColorHex: "#7FA886",
        suggestedIntervalDays: 10,
        subtitle: "Keep the yard tidy"
    )

    // MARK: Vehicle

    static let oilChange = EventTemplate(
        name: "Oil Change",
        emoji: "oilcan.fill",
        category: .vehicle,
        accentColorHex: "#C4A882",
        suggestedIntervalDays: 90,
        subtitle: "Protect your engine"
    )

    static let carWash = EventTemplate(
        name: "Car Wash",
        emoji: "bubbles.and.sparkles.fill",
        category: .vehicle,
        accentColorHex: "#7EB5D6",
        suggestedIntervalDays: 14,
        subtitle: "Keep it shining"
    )

    static let tireRotation = EventTemplate(
        name: "Tire Rotation",
        emoji: "tire",
        category: .vehicle,
        accentColorHex: "#2C3E5A",
        suggestedIntervalDays: 180,
        subtitle: "Even tire wear"
    )

    static let gasFillUp = EventTemplate(
        name: "Gas Fill-up",
        emoji: "fuelpump.fill",
        category: .vehicle,
        accentColorHex: "#E5A84B",
        suggestedIntervalDays: 7,
        subtitle: "Track fuel stops"
    )

    // MARK: Pets

    static let feedPet = EventTemplate(
        name: "Feed Pet",
        emoji: "dog.fill",
        category: .pets,
        accentColorHex: "#C4A882",
        suggestedIntervalDays: 1,
        subtitle: "Daily feeding routine"
    )

    static let fleaTickMedication = EventTemplate(
        name: "Flea/Tick Medication",
        emoji: "pawprint.fill",
        category: .pets,
        accentColorHex: "#E07A6B",
        suggestedIntervalDays: 30,
        subtitle: "Monthly prevention"
    )

    static let vetVisit = EventTemplate(
        name: "Vet Visit",
        emoji: "stethoscope",
        category: .pets,
        accentColorHex: "#5BA4A4",
        suggestedIntervalDays: 365,
        subtitle: "Annual checkup"
    )

    static let groomPet = EventTemplate(
        name: "Groom Pet",
        emoji: "shower.fill",
        category: .pets,
        accentColorHex: "#7EB5D6",
        suggestedIntervalDays: 30,
        subtitle: "Bath and brush time"
    )

    // MARK: Life Admin

    static let callParents = EventTemplate(
        name: "Call Parents",
        emoji: "phone.fill",
        category: .personal,
        accentColorHex: "#D4849A",
        suggestedIntervalDays: 7,
        subtitle: "Stay connected"
    )

    static let budgetReview = EventTemplate(
        name: "Budget Review",
        emoji: "chart.bar.fill",
        category: .work,
        accentColorHex: "#2C3E5A",
        suggestedIntervalDays: 30,
        subtitle: "Monthly finances check"
    )

    static let backupPhone = EventTemplate(
        name: "Backup Phone",
        emoji: "iphone.gen3",
        category: .general,
        accentColorHex: "#6B7B8D",
        suggestedIntervalDays: 30,
        subtitle: "Protect your data"
    )

    static let replaceToothbrush = EventTemplate(
        name: "Replace Toothbrush",
        emoji: "mouth.fill",
        category: .personal,
        accentColorHex: "#5BA4A4",
        suggestedIntervalDays: 90,
        subtitle: "Fresh brush, better clean"
    )

    // MARK: - All Templates

    static let allTemplates: [EventTemplate] = [
        // Health & Wellness
        .takeMedication, .exercise, .dentistVisit, .eyeExam, .haircut, .weighIn,
        // Home & Garden
        .waterPlants, .changeHVACFilter, .cleanHouse, .laundry, .changeBedSheets, .mowLawn,
        // Vehicle
        .oilChange, .carWash, .tireRotation, .gasFillUp,
        // Pets
        .feedPet, .fleaTickMedication, .vetVisit, .groomPet,
        // Life Admin
        .callParents, .budgetReview, .backupPhone, .replaceToothbrush,
    ]

    // MARK: - Grouped by Category

    static var groupedByCategory: [String: [EventTemplate]] {
        Dictionary(grouping: allTemplates) { $0.category.displayName }
    }

    // MARK: - Quick Start Packs

    static let quickStartPacks: [QuickStartPack] = [
        QuickStartPack(
            name: "Home Essentials",
            emoji: "house.fill",
            description: "Keep your home running smoothly",
            templates: [.waterPlants, .cleanHouse, .changeHVACFilter, .laundry, .changeBedSheets]
        ),
        QuickStartPack(
            name: "Health Basics",
            emoji: "heart.fill",
            description: "Stay on top of your well-being",
            templates: [.takeMedication, .exercise, .dentistVisit, .haircut]
        ),
        QuickStartPack(
            name: "Pet Parent",
            emoji: "pawprint.fill",
            description: "Everything for your furry friend",
            templates: [.feedPet, .fleaTickMedication, .vetVisit, .groomPet]
        ),
        QuickStartPack(
            name: "Car Owner",
            emoji: "car.fill",
            description: "Keep your vehicle in top shape",
            templates: [.oilChange, .carWash, .tireRotation, .gasFillUp]
        ),
        QuickStartPack(
            name: "Full Starter Kit",
            emoji: "sparkles",
            description: "A curated mix of the most popular events",
            templates: [
                .takeMedication, .exercise, .waterPlants, .cleanHouse,
                .laundry, .oilChange, .callParents, .haircut,
            ]
        ),
    ]

    /// The most popular templates for quick-add suggestions.
    static let popularTemplates: [EventTemplate] = [
        .takeMedication, .waterPlants, .exercise, .cleanHouse, .callParents,
    ]

    // MARK: - Interval Description

    var intervalDescription: String {
        switch suggestedIntervalDays {
        case 1:
            return "Daily"
        case 2...6:
            return "~every \(suggestedIntervalDays) days"
        case 7:
            return "Weekly"
        case 8...13:
            return "~every \(suggestedIntervalDays) days"
        case 14:
            return "Biweekly"
        case 15...27:
            return "~every \(suggestedIntervalDays) days"
        case 28...31:
            return "Monthly"
        case 32...89:
            return "~every \(suggestedIntervalDays) days"
        case 90:
            return "Quarterly"
        case 91...179:
            return "~every \(suggestedIntervalDays) days"
        case 180:
            return "Every 6 months"
        case 181...364:
            return "~every \(suggestedIntervalDays) days"
        case 365:
            return "Yearly"
        default:
            return "~every \(suggestedIntervalDays) days"
        }
    }
}
