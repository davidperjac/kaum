import SwiftUI

/// The alarm screen background. A barely-perceptible vertical gradient with a
/// faint FIRSTLIGHT glow along the bottom edge. Over the ~30 seconds the alarm
/// rings, the glow rises very slightly and warms — dawn arriving while you
/// decide to get up. Almost subliminal.
struct DawnGradient: View {
    /// 0...1 — how far dawn has progressed. Drive with a 30s linear animation.
    var progress: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x0A0E1A), Color(hex: 0x141A2E)],
                startPoint: .top,
                endPoint: .bottom
            )

            // First light along the bottom edge
            let p = reduceMotion ? 0.35 : progress
            RadialGradient(
                colors: [
                    KoumColor.firstlight.opacity(0.10 + 0.10 * p),
                    KoumColor.firstlight.opacity(0),
                ],
                center: UnitPoint(x: 0.5, y: 1.18 - 0.10 * p),
                startRadius: 0,
                endRadius: 340 + 80 * p
            )
        }
        .ignoresSafeArea()
    }
}

/// Animates dawn progress over 30 seconds once it appears, then lets the
/// ember breathe — a barely-perceptible 6-second cycle, slower than a
/// resting heart rate. Nothing on screen moves faster than the user unless
/// the user caused it.
struct AnimatedDawnBackground: View {
    @State private var progress: Double = 0
    @State private var breath = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            DawnGradient(progress: progress)

            // Breathing ember along the bottom edge
            if !reduceMotion {
                RadialGradient(
                    colors: [KoumColor.firstlight.opacity(breath ? 0.06 : 0.02), .clear],
                    center: UnitPoint(x: 0.5, y: 1.05),
                    startRadius: 0,
                    endRadius: 260
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: KoumMotion.dawn)) {
                progress = 1
            }
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                breath = true
            }
        }
    }
}
