import SwiftUI
import WatchKit

struct WatchEventDetailView: View {
    let event: WatchEvent
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @State private var showConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Icon
                Image(systemName: event.emoji)
                    .font(.system(size: 36))
                    .foregroundStyle(Color(hex: event.colorHex))
                    .padding(.top, 8)

                // Event name
                Text(event.name)
                    .font(.system(.headline, design: .rounded))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                // Last logged
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Last: \(event.timeSinceLog)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Rhythm
                Text(event.rhythm)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                // Urgency indicator
                urgencyBadge

                // Streak (if available)
                if event.streak > 1 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("\(event.streak)-log streak")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Log Now button
                Button {
                    logNow()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Log Now")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: event.colorHex))
                .padding(.top, 4)
            }
            .padding(.horizontal, 4)
        }
        .fullScreenCover(isPresented: $showConfirmation) {
            WatchLogConfirmationView(eventName: event.name, colorHex: event.colorHex)
        }
    }

    // MARK: - Urgency Badge

    private var urgencyBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color(hex: event.urgencyTier.color))
                .frame(width: 8, height: 8)

            Text(urgencyLabel)
                .font(.caption2)
                .foregroundStyle(Color(hex: event.urgencyTier.color))
        }
    }

    private var urgencyLabel: String {
        switch event.urgencyTier {
        case .low: return "On track"
        case .medium: return "Due soon"
        case .high: return "Overdue"
        }
    }

    // MARK: - Actions

    private func logNow() {
        connectivity.logEvent(id: event.id)
        WKInterfaceDevice.current().play(.success)
        showConfirmation = true
    }
}

// MARK: - Preview

#Preview {
    let sample = WatchEvent(
        id: "preview-1",
        name: "Water Plants",
        emoji: "leaf.fill",
        lastLoggedDate: Date().addingTimeInterval(-86400 * 3),
        urgency: 0.65,
        rhythm: "Every 5 days",
        colorHex: "#5BA4A4",
        streak: 4
    )
    return WatchEventDetailView(event: sample)
        .environmentObject(WatchConnectivityManager.shared)
}
