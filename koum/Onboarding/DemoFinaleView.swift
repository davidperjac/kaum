import SwiftUI

/// The end of the live demo — the moment the pitch becomes belief. A full
/// sunrise floods the screen from the bottom, the words settle in one at a
/// time, and Wren sings. The one place in onboarding where Koum celebrates.
struct DemoFinaleView: View {
    let onContinue: () -> Void

    @State private var flood: Double = 0        // 0...1 sunrise rise
    @State private var line1 = false            // "That's it."
    @State private var line2 = false            // "That's every morning."
    @State private var wrenShown = false
    @State private var notes: [Bool] = [false, false, false]
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

                // Wren sings the new morning in
                ZStack(alignment: .topTrailing) {
                    Image("WrenSinging")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 92)
                        .accessibilityHidden(true)
                    HStack(spacing: 5) {
                        ForEach(notes.indices, id: \.self) { idx in
                            Text("♪")
                                .font(.system(size: 13 + CGFloat(idx) * 2))
                                .foregroundStyle(KoumColor.firstlight)
                                .opacity(notes[idx] ? 1 : 0)
                                .offset(y: notes[idx] ? -8 : 4)
                        }
                    }
                    .offset(x: 26, y: -14)
                }
                .opacity(wrenShown ? 1 : 0)
                .offset(y: wrenShown ? 0 : 8)
                .padding(.top, KoumSpacing.xl)

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
            wrenShown = true
            notes = [true, true, true]
            buttonShown = true
            return
        }
        // Dawn floods up — slow, like an actual sunrise sped to two seconds
        withAnimation(.easeOut(duration: 2.2)) { flood = 1 }
        KoumHapticEngine.shared.playBloomSwell()

        withAnimation(KoumMotion.breathEase.delay(0.5)) { line1 = true }
        withAnimation(KoumMotion.breathEase.delay(1.0)) { line2 = true }
        withAnimation(KoumMotion.gentleEase.delay(1.5)) { wrenShown = true }
        for idx in notes.indices {
            withAnimation(KoumMotion.gentleEase.delay(1.8 + Double(idx) * 0.18)) {
                notes[idx] = true
            }
        }
        withAnimation(KoumMotion.gentleEase.delay(2.2)) { buttonShown = true }
    }
}
