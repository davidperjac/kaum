import SwiftUI

/// The end of the live demo — the moment the pitch becomes belief. A full
/// sunrise floods the screen from the bottom, the words settle in one at a
/// time, and Wren sings. The one place in onboarding where Koum celebrates.
struct DemoFinaleView: View {
    let onContinue: () -> Void

    @State private var flood: Double = 0        // 0...1 sunrise rise
    @State private var line1 = false            // "That's it."
    @State private var line2 = false            // "That's every morning."
    @State private var bookShown = false
    @State private var bookGlow = false
    @State private var buttonShown = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            KoumColor.night.ignoresSafeArea()

            // The sunrise flood — dawn taking the whole screen
            GeometryReader { geo in
                let h = geo.size.height
                ZStack {
                    // Sky warms from the bottom upward
                    LinearGradient(
                        stops: [
                            .init(color: KoumColor.night, location: 0),
                            .init(color: KoumColor.night, location: max(0, 0.55 - 0.35 * flood)),
                            .init(color: Color(hex: 0x2A2440).opacity(flood), location: max(0.05, 0.78 - 0.3 * flood)),
                            .init(color: KoumColor.firstlight.opacity(0.32 * flood), location: 1),
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    // The sun crests at the bottom of the screen
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    KoumColor.firstlight,
                                    KoumColor.firstlight.opacity(0.35),
                                    KoumColor.firstlight.opacity(0),
                                ],
                                center: .center, startRadius: 10, endRadius: 260
                            )
                        )
                        .frame(width: 520, height: 520)
                        .position(x: geo.size.width / 2, y: h + 190 - 150 * flood)
                        .ignoresSafeArea()
                }
            }
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()

                GlyphView(glyph: .check, size: 34, color: KoumColor.verified, lineWidth: 2.5)
                    .opacity(line1 ? 1 : 0)
                    .padding(.bottom, KoumSpacing.xl)

                Text("That's it.")
                    .font(KoumType.display)
                    .foregroundStyle(KoumColor.bone)
                    .opacity(line1 ? 1 : 0)
                    .offset(y: line1 ? 0 : 6)

                Text("That's every morning.")
                    .font(KoumType.title)
                    .foregroundStyle(KoumColor.boneMuted)
                    .opacity(line2 ? 1 : 0)
                    .offset(y: line2 ? 0 : 6)
                    .padding(.top, KoumSpacing.sm)

                // The Book, with morning light rising off the page
                ZStack {
                    RadialGradient(
                        colors: [
                            KoumColor.firstlight.opacity(bookGlow ? 0.30 : 0.12),
                            KoumColor.firstlight.opacity(0),
                        ],
                        center: .center, startRadius: 0, endRadius: 70
                    )
                    .frame(width: 140, height: 140)
                    GlyphView(glyph: .bookRays, size: 64, color: KoumColor.firstlight, lineWidth: 1.8)
                }
                .opacity(bookShown ? 1 : 0)
                .offset(y: bookShown ? 0 : 8)
                .padding(.top, KoumSpacing.lg)

                Spacer()

                Button("Set up mine") {
                    KoumHaptics.buttonPress()
                    onContinue()
                }
                .buttonStyle(.koumPrimary)
                .opacity(buttonShown ? 1 : 0)
                .padding(.bottom, KoumSpacing.lg)
            }
            .padding(.horizontal, KoumSpacing.margin)
        }
        .onAppear { run() }
    }

    private func run() {
        if reduceMotion {
            flood = 1
            line1 = true
            line2 = true
            bookShown = true
            bookGlow = true
            buttonShown = true
            return
        }
        // Dawn floods up — slow, like an actual sunrise sped to two seconds
        withAnimation(.easeOut(duration: 2.2)) { flood = 1 }
        KoumHapticEngine.shared.playBloomSwell()

        withAnimation(KoumMotion.breathEase.delay(0.5)) { line1 = true }
        withAnimation(KoumMotion.breathEase.delay(1.0)) { line2 = true }
        withAnimation(KoumMotion.gentleEase.delay(1.5)) { bookShown = true }
        withAnimation(.easeInOut(duration: 2.6).delay(1.7).repeatForever(autoreverses: true)) {
            bookGlow = true
        }
        withAnimation(KoumMotion.gentleEase.delay(2.2)) { buttonShown = true }
    }
}
