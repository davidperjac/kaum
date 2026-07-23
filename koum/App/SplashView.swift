import SwiftUI

/// The daily reminder of what this app is for: qum — arise. A sun rises over
/// a thin horizon while Isaiah 60:1 (WEB) settles onto the screen. ~2.5s,
/// tap anywhere to skip, cold launches only, and never shown over an alarm.
struct SplashView: View {
    let onDone: () -> Void

    @State private var horizonWidth: CGFloat = 0
    @State private var sunRisen = false
    @State private var glow: Double = 0
    @State private var line1 = false
    @State private var line2 = false
    @State private var refShown = false
    @State private var fadingOut = false
    @State private var finished = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            KoumColor.night.ignoresSafeArea()

            // The rising sun over the horizon — the icon, alive.
            GeometryReader { geo in
                let w = geo.size.width
                let horizonY = geo.size.height * 0.62
                ZStack {
                    // Glow
                    RadialGradient(
                        colors: [
                            KoumColor.firstlight.opacity(0.38 * glow),
                            KoumColor.firstlight.opacity(0),
                        ],
                        center: UnitPoint(x: 0.5, y: horizonY / geo.size.height),
                        startRadius: 0,
                        endRadius: w * 0.55
                    )

                    // Sun dome, clipped by the horizon
                    Circle()
                        .fill(KoumColor.firstlight)
                        .frame(width: w * 0.30, height: w * 0.30)
                        .position(x: w / 2, y: horizonY + (sunRisen ? -w * 0.03 : w * 0.16))
                        .mask(
                            Rectangle()
                                .frame(height: horizonY)
                                .position(x: w / 2, y: horizonY / 2)
                        )

                    // Horizon line, drawing outward from centre
                    Rectangle()
                        .fill(KoumColor.bone.opacity(0.85))
                        .frame(width: horizonWidth * w * 0.74, height: 1.5)
                        .position(x: w / 2, y: horizonY)
                }
            }
            .ignoresSafeArea()

            // The verse
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: KoumSpacing.sm) {
                    Text("Arise, shine;")
                        .font(KoumType.splash)
                        .foregroundStyle(KoumColor.bone)
                        .opacity(line1 ? 1 : 0)
                        .offset(y: line1 ? 0 : 6)
                    Text("for your light has come.")
                        .font(KoumType.splash)
                        .foregroundStyle(KoumColor.bone)
                        .opacity(line2 ? 1 : 0)
                        .offset(y: line2 ? 0 : 6)
                }
                .multilineTextAlignment(.center)

                MicroLabel(text: "Isaiah 60:1", color: KoumColor.firstlight)
                    .opacity(refShown ? 1 : 0)
                    .padding(.top, KoumSpacing.md)

                Spacer()
                Spacer()
                Spacer()
            }
            .padding(.horizontal, KoumSpacing.margin)
        }
        .opacity(fadingOut ? 0 : 1)
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .onAppear { run() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Arise, shine; for your light has come. Isaiah 60:1")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Tap to continue")
    }

    private func run() {
        if reduceMotion {
            horizonWidth = 1
            sunRisen = true
            glow = 1
            line1 = true
            line2 = true
            refShown = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { finish() }
            return
        }
        withAnimation(.easeOut(duration: 0.5)) { horizonWidth = 1 }
        withAnimation(.easeOut(duration: 1.2).delay(0.25)) {
            sunRisen = true
            glow = 1
        }
        withAnimation(KoumMotion.breathEase.delay(0.7)) { line1 = true }
        withAnimation(KoumMotion.breathEase.delay(1.1)) { line2 = true }
        withAnimation(KoumMotion.gentleEase.delay(1.6)) { refShown = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { finish() }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        withAnimation(.easeIn(duration: 0.3)) { fadingOut = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onDone() }
    }
}
