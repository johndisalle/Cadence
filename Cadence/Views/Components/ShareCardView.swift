import SwiftUI

// MARK: - Streak Share Card

struct StreakShareCard: View {
    let eventName: String
    let emoji: String
    let streakDays: Int
    let accentColorHex: String

    private var accent: Color { Color(hex: accentColorHex) }

    var body: some View {
        ZStack {
            // Gradient background
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [accent, accent.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 24) {
                Spacer()

                // Glowing SF Symbol
                Image(systemName: emoji)
                    .font(.system(size: 64, weight: .medium))
                    .foregroundStyle(.white)
                    .shadow(color: .white.opacity(0.6), radius: 16, y: 0)
                    .shadow(color: .white.opacity(0.3), radius: 32, y: 0)

                // Event name
                Text(eventName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                // Streak highlight
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.title)
                        .foregroundStyle(.orange)
                    Text("\(streakDays) in a row")
                        .font(.title.weight(.heavy))
                        .foregroundStyle(.white)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.2))
                )

                Spacer()

                // Watermark
                Text("Tracked with Cadence")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, 20)
            }
            .padding(24)
        }
        .frame(width: 390, height: 520)
    }
}

// MARK: - Rhythm Share Card

struct RhythmShareCard: View {
    let eventName: String
    let emoji: String
    let rhythm: String
    let consistency: Int
    let totalLogs: Int
    let accentColorHex: String

    private var accent: Color { Color(hex: accentColorHex) }

    var body: some View {
        ZStack {
            // Gradient background
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [accent, accent.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 20) {
                Spacer()

                // SF Symbol + event name
                Image(systemName: emoji)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(.white)
                    .shadow(color: .white.opacity(0.5), radius: 12, y: 0)

                Text(eventName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)

                // Consistency ring
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: Double(consistency) / 100.0)
                        .stroke(.white, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(consistency)%")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("consistency")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .frame(width: 140, height: 140)

                // Rhythm
                Text(rhythm)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))

                // Total logs
                Text("\(totalLogs) total logs")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                // Watermark
                Text("Tracked with Cadence")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, 20)
            }
            .padding(24)
        }
        .frame(width: 390, height: 520)
    }
}

// MARK: - Render View as Image

extension View {
    @MainActor
    func renderAsImage(size: CGSize) -> UIImage {
        let controller = UIHostingController(rootView: self.frame(width: size.width, height: size.height))
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Previews

#Preview("Streak Card") {
    StreakShareCard(
        eventName: "Water Plants",
        emoji: "leaf.fill",
        streakDays: 30,
        accentColorHex: "#7FA886"
    )
}

#Preview("Rhythm Card") {
    RhythmShareCard(
        eventName: "Medication",
        emoji: "pill.fill",
        rhythm: "Every 3.2 days",
        consistency: 94,
        totalLogs: 47,
        accentColorHex: "#5BA4A4"
    )
}
