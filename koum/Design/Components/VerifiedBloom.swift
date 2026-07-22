import SwiftUI

/// The verification moment. The sound has already been cut by the caller —
/// silence lands before any visual. Then: 200ms of nothing, a FIRSTLIGHT glow
/// blooming from centre (600ms), a checkmark drawing itself (400ms), the glow
/// settling, and an 800ms hold before `onFinished`.
struct VerifiedBloom: View {
    var onFinished: () -> Void

    @State private var glow: Double = 0
    @State private var checkProgress: CGFloat = 0
    @State private var settled = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            KoumColor.night.ignoresSafeArea()

            // Glow
            RadialGradient(
                colors: [
                    KoumColor.firstlight.opacity(settled ? 0.22 : 0.5 * glow),
                    KoumColor.firstlight.opacity(0),
                ],
                center: .center,
                startRadius: 0,
                endRadius: 60 + 260 * glow
            )
            .ignoresSafeArea()
            .animation(KoumMotion.slowEase, value: settled)

            CheckmarkShape()
                .trim(from: 0, to: checkProgress)
                .stroke(
                    KoumColor.verified,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                )
                .frame(width: 72, height: 72)
        }
        .onAppear { run() }
        .accessibilityLabel("Verified")
    }

    private func run() {
        if reduceMotion {
            glow = 1
            checkProgress = 1
            settled = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { onFinished() }
            return
        }
        // 200ms of nothing — the silence is the reward
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.6)) { glow = 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.easeInOut(duration: 0.4)) { checkProgress = 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
            withAnimation(.easeOut(duration: 0.5)) { settled = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.95) {
            onFinished()
        }
    }
}

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: w * 0.12, y: h * 0.55))
        p.addLine(to: CGPoint(x: w * 0.40, y: h * 0.82))
        p.addLine(to: CGPoint(x: w * 0.88, y: h * 0.22))
        return p
    }
}
