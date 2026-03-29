import SwiftUI

struct LogButton: View {
    var symbolName: String = "checkmark"
    var color: Color = CadenceTheme.teal
    var size: CGFloat = 64
    var action: () -> Void

    @State private var isPressed = false
    @State private var rippleScale: CGFloat = 1.0
    @State private var rippleOpacity: Double = 0.0

    var body: some View {
        ZStack {
            // Ripple layer
            Circle()
                .fill(color.opacity(rippleOpacity))
                .frame(width: size * 1.6, height: size * 1.6)
                .scaleEffect(rippleScale)

            // Main button
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .shadow(color: color.opacity(0.35), radius: 10, y: 5)
                .overlay(
                    Image(systemName: symbolName)
                        .font(.system(size: size * 0.35, weight: .bold))
                        .foregroundStyle(.white)
                )
                .scaleEffect(isPressed ? 0.88 : 1.0)
        }
        .contentShape(Circle())
        .onTapGesture {
            triggerTap()
        }
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
    }

    private func triggerTap() {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Ripple animation
        rippleScale = 1.0
        rippleOpacity = 0.3
        withAnimation(.easeOut(duration: 0.5)) {
            rippleScale = 2.0
            rippleOpacity = 0.0
        }

        // Execute action
        action()
    }
}

// Convenient overlay modifier
extension View {
    func logButtonOverlay(
        symbolName: String = "checkmark",
        color: Color = CadenceTheme.teal,
        action: @escaping () -> Void
    ) -> some View {
        self.overlay(alignment: .bottomTrailing) {
            LogButton(symbolName: symbolName, color: color, action: action)
                .padding(CadenceTheme.spacingLG)
        }
    }
}

#Preview {
    ZStack {
        Color(.systemBackground)
            .ignoresSafeArea()

        VStack(spacing: 40) {
            LogButton(action: { print("Logged!") })

            LogButton(
                symbolName: "plus",
                color: CadenceTheme.coral,
                action: { print("Added!") }
            )

            LogButton(
                symbolName: "arrow.clockwise",
                color: CadenceTheme.lavender,
                size: 52,
                action: { print("Refreshed!") }
            )
        }
    }
}
