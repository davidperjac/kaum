import SwiftUI

/// The most important visual pattern in the app. No quote marks, no card, no
/// border, no background — the verse floats on the screen. Scripture is the
/// largest thing wherever it appears.
struct VerseBlock: View {
    let reference: String
    let text: String
    var hero: Bool = false
    var referenceColor: Color = KoumColor.boneMuted
    var textColor: Color = KoumColor.bone

    var body: some View {
        VStack(alignment: .leading, spacing: KoumSpacing.md) {
            MicroLabel(text: reference, color: referenceColor)
            Text(text)
                .font(hero ? KoumType.verseHero : KoumType.verse)
                .koumLineSpacing(hero ? 10 : 12)
                .foregroundStyle(textColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(reference). \(text)")
    }
}

/// Streak display: custom line-glyph flame, number, caption. Never a filled
/// or animated flame — it would look like a game.
struct StreakBadge: View {
    let count: Int
    var compact: Bool = false

    @Environment(\.koumTheme) private var theme

    var body: some View {
        if compact {
            HStack(spacing: KoumSpacing.sm) {
                FlameGlyph()
                    .stroke(theme.accent, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                    .frame(width: 16, height: 20)
                Text("\(count) \(count == 1 ? "morning" : "mornings")")
                    .font(KoumType.caption)
                    .foregroundStyle(theme.textMuted)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Streak: \(count) mornings")
        } else {
            VStack(spacing: KoumSpacing.sm) {
                FlameGlyph()
                    .stroke(theme.accent, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                    .frame(width: 22, height: 28)
                Text("\(count)")
                    .font(KoumType.streak)
                    .foregroundStyle(theme.accent)
                    .contentTransition(.numericText())
                Text(count == 1 ? "morning" : "mornings")
                    .font(KoumType.caption)
                    .foregroundStyle(theme.textMuted)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Streak: \(count) mornings")
        }
    }
}

/// Custom flame line glyph — geometric, slightly warm, never cute.
struct FlameGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        // Outer flame: a teardrop leaning slightly right
        p.move(to: CGPoint(x: w * 0.5, y: 0))
        p.addCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control1: CGPoint(x: w * 1.05, y: h * 0.35),
            control2: CGPoint(x: w * 1.0, y: h * 0.85)
        )
        p.addCurve(
            to: CGPoint(x: w * 0.5, y: 0),
            control1: CGPoint(x: w * 0.0, y: h * 0.85),
            control2: CGPoint(x: w * -0.05, y: h * 0.35)
        )
        // Inner lick
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.45))
        p.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.92),
            control1: CGPoint(x: w * 0.72, y: h * 0.62),
            control2: CGPoint(x: w * 0.7, y: h * 0.85)
        )
        return p
    }
}
