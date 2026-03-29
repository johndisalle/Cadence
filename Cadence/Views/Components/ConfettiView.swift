import SwiftUI

// MARK: - Confetti Particle

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let isCircle: Bool
    var position: CGPoint
    var velocity: CGPoint
    var rotation: Double
    var rotationSpeed: Double
    var scale: CGFloat
    var opacity: Double
}

// MARK: - ConfettiView

struct ConfettiView: View {
    @Binding var isShowing: Bool

    private static let colors: [Color] = [
        CadenceTheme.teal,
        CadenceTheme.sage,
        CadenceTheme.coral,
        CadenceTheme.sky,
        CadenceTheme.sand,
        CadenceTheme.lavender,
    ]

    @State private var particles: [ConfettiParticle] = []
    @State private var startTime: Date = .now

    var body: some View {
        if isShowing {
            TimelineView(.animation) { timeline in
                let elapsed = timeline.date.timeIntervalSince(startTime)

                Canvas { context, size in
                    for particle in particles {
                        let gravity: Double = 600
                        let drag: Double = 0.97

                        let t = elapsed
                        let vx = particle.velocity.x * pow(drag, t * 60)
                        let vy = particle.velocity.y * pow(drag, t * 60) + gravity * t

                        let x = particle.position.x + vx * t
                        let y = particle.position.y + vy * t

                        let rotation = Angle.degrees(particle.rotation + particle.rotationSpeed * t)
                        let alpha = max(0, particle.opacity - (elapsed / 2.0) * particle.opacity)

                        guard alpha > 0 else { continue }

                        var ctx = context
                        ctx.opacity = alpha
                        ctx.translateBy(x: x, y: y)
                        ctx.rotate(by: rotation)
                        ctx.scaleBy(x: particle.scale, y: particle.scale)

                        let rect = CGRect(x: -4, y: -4, width: 8, height: 8)
                        if particle.isCircle {
                            ctx.fill(Circle().path(in: rect), with: .color(particle.color))
                        } else {
                            let rectPath = RoundedRectangle(cornerRadius: 1)
                                .path(in: CGRect(x: -5, y: -3, width: 10, height: 6))
                            ctx.fill(rectPath, with: .color(particle.color))
                        }
                    }
                }
                .onChange(of: elapsed >= 2.0) { _, finished in
                    if finished {
                        isShowing = false
                        particles = []
                    }
                }
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()
            .onAppear {
                startTime = .now
                generateParticles()
            }
        }
    }

    private func generateParticles() {
        let count = Int.random(in: 35...45)
        particles = (0..<count).map { _ in
            let angle = Double.random(in: -Double.pi * 0.85 ... -Double.pi * 0.15)
            let speed = Double.random(in: 300...700)
            return ConfettiParticle(
                color: Self.colors.randomElement()!,
                isCircle: Bool.random(),
                position: CGPoint(x: UIScreen.main.bounds.midX + CGFloat.random(in: -40...40),
                                  y: UIScreen.main.bounds.maxY * 0.65),
                velocity: CGPoint(x: cos(angle) * speed, y: sin(angle) * speed),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -400...400),
                scale: CGFloat.random(in: 0.7...1.4),
                opacity: 1.0
            )
        }
    }
}

// MARK: - SuccessBurstView

struct SuccessBurstView: View {
    @Binding var isShowing: Bool

    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 1.0

    var body: some View {
        if isShowing {
            Circle()
                .fill(CadenceTheme.sage.opacity(0.25))
                .frame(width: 120, height: 120)
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.4)) {
                        scale = 1.5
                    }
                    withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                        opacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        isShowing = false
                        scale = 0.3
                        opacity = 1.0
                    }
                }
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Previews

#Preview("Confetti") {
    struct PreviewWrapper: View {
        @State private var show = true
        var body: some View {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                VStack {
                    Button("Celebrate!") { show = true }
                        .buttonStyle(.borderedProminent)
                }
                ConfettiView(isShowing: $show)
            }
        }
    }
    return PreviewWrapper()
}

#Preview("Success Burst") {
    struct PreviewWrapper: View {
        @State private var show = true
        var body: some View {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                VStack {
                    Button("Burst!") { show = true }
                        .buttonStyle(.borderedProminent)
                }
                SuccessBurstView(isShowing: $show)
            }
        }
    }
    return PreviewWrapper()
}
