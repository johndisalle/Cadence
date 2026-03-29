import SwiftUI

enum CadenceTheme {
    // Primary palette
    static let sage = Color(hex: "#7FA886")
    static let sand = Color(hex: "#C4A882")
    static let sky = Color(hex: "#7EB5D6")
    static let navy = Color(hex: "#2C3E5A")
    static let teal = Color(hex: "#5BA4A4")
    static let coral = Color(hex: "#E07A6B")
    static let lavender = Color(hex: "#9B8EC4")
    static let rose = Color(hex: "#D4849A")

    // Semantic colors
    static let backgroundPrimary = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let backgroundTertiary = Color(.tertiarySystemBackground)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)

    // Urgency colors
    static let urgencyLow = Color(hex: "#7FA886")     // sage green
    static let urgencyMedium = Color(hex: "#E5C07B")   // warm gold
    static let urgencyHigh = Color(hex: "#E07A6B")     // coral red

    static func urgencyColor(score: Double) -> Color {
        if score < 0.4 {
            return urgencyLow
        } else if score < 0.7 {
            return urgencyMedium
        } else {
            return urgencyHigh
        }
    }

    // Preset accent colors
    static let accentPresets: [(name: String, hex: String)] = [
        ("Teal", "#5BA4A4"),
        ("Sage", "#7FA886"),
        ("Sky", "#7EB5D6"),
        ("Navy", "#2C3E5A"),
        ("Sand", "#C4A882"),
        ("Coral", "#E07A6B"),
        ("Lavender", "#9B8EC4"),
        ("Rose", "#D4849A"),
        ("Amber", "#E5A84B"),
        ("Mint", "#6BC5A0"),
        ("Slate", "#6B7B8D"),
        ("Plum", "#8B5E83"),
    ]

    // Preset emojis by category
    static let emojiPresets: [EventCategory: [String]] = [
        .health: ["pill.fill", "figure.run", "figure.yoga", "syringe.fill", "mouth.fill", "eye.fill", "stethoscope", "dumbbell.fill", "brain.head.profile", "bed.double.fill"],
        .home: ["house.fill", "sparkles", "leaf.fill", "wrench.and.screwdriver.fill", "washer.fill", "trash.fill", "lightbulb.fill", "shower.fill", "bed.double.fill", "snowflake"],
        .vehicle: ["car.fill", "oilcan.fill", "fuelpump.fill", "battery.100.bolt", "tire", "bubbles.and.sparkles.fill", "key.fill", "parkingsign", "car.side.fill", "flag.checkered"],
        .personal: ["scissors", "drop.fill", "tshirt.fill", "book.fill", "pencil.line", "guitars.fill", "camera.fill", "suitcase.fill", "paintpalette.fill", "phone.fill"],
        .pets: ["dog.fill", "cat.fill", "fish.fill", "bird.fill", "hare.fill", "lizard.fill", "pawprint.fill", "bone.fill", "leaf.fill", "hare.fill"],
        .work: ["briefcase.fill", "chart.bar.fill", "envelope.fill", "desktopcomputer", "iphone", "doc.text.fill", "folder.fill", "calendar", "phone.fill", "building.2.fill"],
        .general: ["pin.fill", "star.fill", "bell.fill", "checklist", "target", "checkmark.circle.fill", "arrow.triangle.2.circlepath", "calendar.badge.clock", "alarm.fill", "tag.fill"],
    ]

    // Card styling
    static let cardCornerRadius: CGFloat = 20
    static let cardShadowRadius: CGFloat = 8
    static let cardPadding: CGFloat = 16

    // Spacing
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32
}

struct CadenceCardStyle: ViewModifier {
    var accentColor: Color = CadenceTheme.teal

    func body(content: Content) -> some View {
        content
            .padding(CadenceTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: CadenceTheme.cardCornerRadius)
                    .fill(CadenceTheme.backgroundSecondary)
                    .shadow(color: .black.opacity(0.06), radius: CadenceTheme.cardShadowRadius, y: 4)
            )
    }
}

extension View {
    func cadenceCard(accent: Color = CadenceTheme.teal) -> some View {
        modifier(CadenceCardStyle(accentColor: accent))
    }
}
