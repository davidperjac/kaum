import SwiftUI

/// "How Koum works" — four centered pages walking the whole morning before
/// the live demo. Progress dots, explicit Continue on every page, back
/// handled by the flow's chrome.
struct WalkthroughScreen: View {
    @Binding var page: Int
    let onDone: () -> Void

    private struct Step {
        let glyphs: [KoumGlyph]
        let eyebrow: String
        let title: String
        let body: String
    }

    private let steps = [
        Step(
            glyphs: [.sunrise],
            eyebrow: "Step one",
            title: "The alarm rings",
            body: "At your time, straight through Silent and Focus — the real kind of alarm. And it won't stop for a tap."
        ),
        Step(
            glyphs: [.camera, .mic, .keyboard],
            eyebrow: "Step two",
            title: "Your Bible turns it off",
            body: "Scan the open page, say the verse out loud, or type it. You choose how the night before — and you can always switch."
        ),
        Step(
            glyphs: [.book],
            eyebrow: "Step three",
            title: "Two quiet minutes with God",
            body: "A short prayer prompt drawn from the verse, then a devotional worth reading — context, reflection, one thing to carry."
        ),
        Step(
            glyphs: [.check],
            eyebrow: "Step four",
            title: "One line, and you're up",
            body: "A single journal line closes the morning. The whole thing takes under four minutes."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            let step = steps[page]

            // Glyph row
            HStack(spacing: KoumSpacing.lg) {
                ForEach(step.glyphs.indices, id: \.self) { idx in
                    GlyphView(glyph: step.glyphs[idx], size: 40)
                }
            }
            .frame(height: 56)
            .padding(.bottom, KoumSpacing.xl)

            MicroLabel(text: step.eyebrow, color: KoumColor.firstlight)
                .padding(.bottom, KoumSpacing.sm)

            Text(step.title)
                .font(KoumType.display)
                .koumLineSpacing(7)
                .foregroundStyle(KoumColor.bone)
                .multilineTextAlignment(.center)
                .padding(.bottom, KoumSpacing.md)

            Text(step.body)
                .font(KoumType.body)
                .koumLineSpacing(6)
                .foregroundStyle(KoumColor.boneMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 320)

            Spacer()

            // Progress dots
            HStack(spacing: KoumSpacing.sm) {
                ForEach(steps.indices, id: \.self) { idx in
                    Circle()
                        .fill(idx == page ? KoumColor.firstlight : KoumColor.nightEdge)
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.bottom, KoumSpacing.md)

            Button(page == steps.count - 1 ? "Hear it for yourself" : "Continue") {
                KoumHaptics.buttonPress()
                if page == steps.count - 1 {
                    onDone()
                } else {
                    withAnimation(KoumMotion.gentleEase) { page += 1 }
                }
            }
            .buttonStyle(.koumPrimary)
            .padding(.bottom, KoumSpacing.lg)
        }
        .padding(.horizontal, KoumSpacing.margin)
        .id(page)
        .transition(.koumStep)
        .animation(KoumMotion.gentleEase, value: page)
    }
}
