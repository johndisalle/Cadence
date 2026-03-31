import SwiftUI

struct WatchLogConfirmationView: View {
    let eventName: String
    let colorHex: String

    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.green)
                    .scaleEffect(scale)

                Text("Logged!")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text(eventName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }

            // Auto-dismiss after 1.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        }
        .interactiveDismissDisabled(false)
    }
}

// MARK: - Preview

#Preview {
    WatchLogConfirmationView(eventName: "Water Plants", colorHex: "#5BA4A4")
}
