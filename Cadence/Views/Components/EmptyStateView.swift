import SwiftUI

struct EmptyStateView: View {
    let symbolName: String
    let title: String
    let subtitle: String
    var buttonTitle: String?
    var action: (() -> Void)?

    @State private var appeared = false

    var body: some View {
        VStack(spacing: CadenceTheme.spacingLG) {
            Image(systemName: symbolName)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(CadenceTheme.teal.opacity(0.6))
                .symbolEffect(.pulse, options: .repeating.speed(0.5))
                .scaleEffect(appeared ? 1.0 : 0.7)
                .opacity(appeared ? 1.0 : 0)

            VStack(spacing: CadenceTheme.spacingSM) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(CadenceTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(CadenceTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .opacity(appeared ? 1.0 : 0)
            .offset(y: appeared ? 0 : 10)

            if let buttonTitle, let action {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, CadenceTheme.spacingLG)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(CadenceTheme.teal)
                        )
                }
                .opacity(appeared ? 1.0 : 0)
                .offset(y: appeared ? 0 : 10)
            }
        }
        .padding(CadenceTheme.spacingXL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                appeared = true
            }
        }
    }
}

#Preview {
    EmptyStateView(
        symbolName: "calendar.badge.plus",
        title: "No Events Yet",
        subtitle: "Add your first event to start tracking life's natural rhythm.",
        buttonTitle: "Add Event",
        action: {}
    )
}

#Preview("No Button") {
    EmptyStateView(
        symbolName: "waveform.path.ecg",
        title: "No Insights Available",
        subtitle: "Log a few events and check back for smart suggestions."
    )
}
