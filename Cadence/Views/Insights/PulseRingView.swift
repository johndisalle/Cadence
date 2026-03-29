import SwiftUI

struct PulseRingView: View {
    let score: Int
    var accentColor: Color = CadenceTheme.teal

    @State private var animatedProgress: Double = 0.0

    private var progress: Double {
        Double(score) / 100.0
    }

    private var ringGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [
                accentColor.opacity(0.6),
                accentColor,
                accentColor.opacity(0.9),
                accentColor.opacity(0.6)
            ]),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    var body: some View {
        VStack(spacing: CadenceTheme.spacingSM) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(
                        CadenceTheme.textTertiary.opacity(0.15),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )

                // Progress ring
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        ringGradient,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Center content
                VStack(spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(Int(animatedProgress * 100))")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(CadenceTheme.textPrimary)
                            .contentTransition(.numericText())

                        Text("%")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundStyle(CadenceTheme.textSecondary)
                    }
                }
            }
            .frame(width: 180, height: 180)

            Text("Cadence Pulse")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(CadenceTheme.textSecondary)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).delay(0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: score) { _, newValue in
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = Double(newValue) / 100.0
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        PulseRingView(score: 85)
        PulseRingView(score: 42, accentColor: CadenceTheme.coral)
    }
    .padding()
}
