import SwiftUI

struct LaunchScreenView: View {
    @State private var opacity: Double = 0
    @State private var scale: Double = 0.8

    var body: some View {
        ZStack {
            // Background — subtle gradient from cream to very light teal
            LinearGradient(
                colors: [Color(hex: "#F8FAF9"), Color(hex: "#EDF5F4")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                // App icon — waveform path in teal
                Image(systemName: "waveform.path")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(CadenceTheme.teal)

                Text("Cadence")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CadenceTheme.navy)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 1
                scale = 1.0
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
