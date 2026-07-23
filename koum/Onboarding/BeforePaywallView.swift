import SwiftUI

/// The breath before the ask. Emotional connection first, then — only when a
/// free trial actually exists on the product — an honest preview of how the
/// trial goes. No trial configured, no trial language, anywhere.
struct BeforePaywallView: View {
    let name: String
    let motivation: String
    /// nil when the yearly product carries no introductory free trial.
    let trialDays: Int?
    let onContinue: () -> Void

    @State private var revealed = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text(name.isEmpty ? "One more thing." : "\(name), one more thing.")
                .font(KoumType.display)
                .koumLineSpacing(7)
                .foregroundStyle(KoumColor.bone)
                .opacity(revealed >= 1 ? 1 : 0)
                .padding(.bottom, KoumSpacing.lg)

            Text("We didn't build Koum to keep you on your phone. We built it to get you off your phone and into the Book.")
                .font(KoumType.devotional)
                .koumLineSpacing(8)
                .foregroundStyle(KoumColor.boneMuted)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(revealed >= 2 ? 1 : 0)
                .padding(.bottom, KoumSpacing.md)

            Text("So we want you to live your first real mornings with it, free.")
                .font(KoumType.devotional)
                .koumLineSpacing(8)
                .foregroundStyle(KoumColor.bone)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(revealed >= 2 ? 1 : 0)
                .padding(.bottom, KoumSpacing.xl)

            if let trialDays {
                VStack(alignment: .leading, spacing: KoumSpacing.md) {
                    timelineRow(
                        glyph: .sunrise,
                        title: "Today",
                        detail: "Everything unlocks. Your alarm is set for tomorrow."
                    )
                    if trialDays > 1 {
                        timelineRow(
                            glyph: .book,
                            title: "Day \(trialDays - 1)",
                            detail: "We remind you the trial is ending. Honestly, like we promised."
                        )
                    }
                    timelineRow(
                        glyph: .check,
                        title: "Day \(trialDays)",
                        detail: "Trial ends. Keep going, or cancel in Settings. No hard feelings."
                    )
                }
                .padding(KoumSpacing.md + KoumSpacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(KoumColor.nightRaised)
                )
                .opacity(revealed >= 3 ? 1 : 0)
            }

            Spacer()

            Button(trialDays != nil ? "Try Koum free" : "See the plan") {
                KoumHaptics.buttonPress()
                onContinue()
            }
            .buttonStyle(.koumPrimary)
            .opacity(revealed >= 3 ? 1 : 0)
            .padding(.bottom, KoumSpacing.lg)
        }
        .padding(.horizontal, KoumSpacing.margin)
        .onAppear { reveal() }
    }

    private func timelineRow(glyph: KoumGlyph, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: KoumSpacing.md) {
            GlyphView(glyph: glyph, size: 20)
                .frame(width: 24)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(KoumType.smallLabel)
                    .foregroundStyle(KoumColor.bone)
                Text(detail)
                    .font(KoumType.caption)
                    .foregroundStyle(KoumColor.boneMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func reveal() {
        if reduceMotion { revealed = 3; return }
        withAnimation(KoumMotion.breathEase) { revealed = 1 }
        withAnimation(KoumMotion.breathEase.delay(KoumMotion.breath)) { revealed = 2 }
        withAnimation(KoumMotion.breathEase.delay(KoumMotion.breath * 2)) { revealed = 3 }
    }
}
