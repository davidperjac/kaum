import SwiftUI

/// "How Koum works" — four pages, each carrying a living miniature of the
/// real morning instead of a lonely icon: the alarm actually ringing, the
/// verse lighting up word by word, the quiet minutes, the one-line journal.
/// The user watches their tomorrow happen in the palm of the page.
struct WalkthroughScreen: View {
    @Binding var page: Int
    let onDone: () -> Void

    private let titles = [
        ("The alarm rings", "At your time, straight through Silent and Focus. The real kind of alarm. And it won't stop for a tap."),
        ("Your Bible turns it off", "Scan the open page, say the verse out loud, or type it. Every word, to the end."),
        ("Two quiet minutes with God", "A short prayer drawn from the verse, then a devotional worth reading."),
        ("One line, and you're up", "A single journal line closes the morning. The whole thing takes under four minutes."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: KoumSpacing.lg)

            // The living miniature
            Group {
                switch page {
                case 0: MiniAlarmCard()
                case 1: MiniVerifyCard()
                case 2: MiniQuietCard()
                default: MiniJournalCard()
                }
            }
            .frame(height: 270)
            .padding(.horizontal, KoumSpacing.margin)

            Spacer(minLength: KoumSpacing.md)

            Text(titles[page].0)
                .font(KoumType.display)
                .koumLineSpacing(7)
                .foregroundStyle(KoumColor.bone)
                .multilineTextAlignment(.center)
                .padding(.bottom, KoumSpacing.md)

            Text(titles[page].1)
                .font(KoumType.body)
                .koumLineSpacing(6)
                .foregroundStyle(KoumColor.boneMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 320)

            Spacer(minLength: KoumSpacing.md)

            // Progress dots
            HStack(spacing: KoumSpacing.sm) {
                ForEach(titles.indices, id: \.self) { idx in
                    Capsule()
                        .fill(idx == page ? KoumColor.firstlight : KoumColor.nightEdge)
                        .frame(width: idx == page ? 18 : 7, height: 7)
                }
            }
            .animation(KoumMotion.quickEase, value: page)
            .padding(.bottom, KoumSpacing.md)

            Button(page == titles.count - 1 ? "Hear it for yourself" : "Continue") {
                KoumHaptics.buttonPress()
                if page == titles.count - 1 {
                    onDone()
                } else {
                    withAnimation(KoumMotion.gentleEase) { page += 1 }
                }
            }
            .buttonStyle(.koumPrimary)
            .padding(.horizontal, KoumSpacing.margin)
            .padding(.bottom, KoumSpacing.lg)
        }
        .id(page)
        .transition(.koumStep)
        .animation(KoumMotion.gentleEase, value: page)
    }
}

// MARK: - Shared miniature chrome

/// A soft device-like stage the miniatures live on.
private struct MiniStage<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(KoumColor.nightRaised.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(KoumColor.nightEdge, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 24, y: 10)
            content
                .padding(KoumSpacing.lg)
        }
        .frame(maxWidth: 300)
    }
}

// MARK: - Page 1: the alarm, ringing

private struct MiniAlarmCard: View {
    @State private var ripple = false
    @State private var glow = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        MiniStage {
            VStack(spacing: KoumSpacing.md) {
                // Sound ripples around the time — the thing is *ringing*.
                ZStack {
                    ForEach(0..<3, id: \.self) { idx in
                        Circle()
                            .stroke(KoumColor.firstlight.opacity(0.5), lineWidth: 1)
                            .frame(width: 80, height: 80)
                            .scaleEffect(ripple ? 2.1 : 0.9)
                            .opacity(ripple ? 0 : 0.7)
                            .animation(
                                reduceMotion ? nil :
                                    .easeOut(duration: 2.4)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(idx) * 0.8),
                                value: ripple
                            )
                    }
                    VStack(spacing: 2) {
                        Text("6:30")
                            .font(Font.custom("Lora-Regular", size: 44, relativeTo: .largeTitle))
                            .foregroundStyle(KoumColor.bone)
                            .monospacedDigit()
                        MicroLabel(text: "AM", color: KoumColor.boneFaint)
                    }
                }
                .frame(height: 150)

                Text("Snooze won't save you")
                    .font(KoumType.caption)
                    .foregroundStyle(KoumColor.boneFaint)
                    .padding(.horizontal, KoumSpacing.md)
                    .padding(.vertical, KoumSpacing.sm)
                    .background(Capsule().fill(KoumColor.night.opacity(0.6)))
                    .opacity(glow ? 1 : 0.55)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            ripple = true
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }
}

// MARK: - Page 2: the verse lights up

private struct MiniVerifyCard: View {
    private static let verse = "Cause me to hear your loving kindness in the morning, for I trust in you."
    @State private var litWords = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var words: [String] { Self.verse.split(separator: " ").map(String.init) }

    var body: some View {
        MiniStage {
            VStack(alignment: .leading, spacing: KoumSpacing.md) {
                MicroLabel(text: "Psalm 143:8", color: KoumColor.firstlight)

                Text(attributed)
                    .font(Font.custom("Lora-Regular", size: 17, relativeTo: .body))
                    .koumLineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: KoumSpacing.sm) {
                    GlyphView(glyph: .mic, size: 16)
                    Text(litWords >= words.count ? "Every word. Alarm off." : "Reading it out loud…")
                        .font(KoumType.caption)
                        .foregroundStyle(litWords >= words.count ? KoumColor.verified : KoumColor.boneMuted)
                        .animation(KoumMotion.quickEase, value: litWords)
                }
                .padding(.top, KoumSpacing.xs)
            }
        }
        .onAppear { run() }
    }

    private var attributed: AttributedString {
        var result = AttributedString()
        for (idx, word) in words.enumerated() {
            var piece = AttributedString(word)
            piece.foregroundColor = idx < litWords
                ? KoumColor.firstlight
                : KoumColor.bone.opacity(0.4)
            result += piece
            if idx < words.count - 1 { result += AttributedString(" ") }
        }
        return result
    }

    private func run() {
        if reduceMotion {
            litWords = words.count
            return
        }
        litWords = 0
        for idx in words.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8 + Double(idx) * 0.28) {
                withAnimation(KoumMotion.quickEase) { litWords = idx + 1 }
            }
        }
    }
}

// MARK: - Page 3: the quiet minutes

private struct MiniQuietCard: View {
    @State private var stage = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        MiniStage {
            VStack(alignment: .leading, spacing: KoumSpacing.md) {
                HStack(spacing: KoumSpacing.sm) {
                    GlyphView(glyph: .book, size: 18)
                    MicroLabel(text: "After the alarm", color: KoumColor.boneMuted)
                }

                quietRow("A prayer, from the verse",
                         sub: "Thirty honest seconds", on: stage >= 1)
                quietRow("A devotional worth reading",
                         sub: "Context, reflection, one thing to carry", on: stage >= 2)
                quietRow("No feed. No badges.",
                         sub: "Just you, up, with God", on: stage >= 3)
            }
        }
        .onAppear {
            if reduceMotion { stage = 3; return }
            for idx in 1...3 {
                withAnimation(KoumMotion.breathEase.delay(0.4 + Double(idx - 1) * 0.5)) {
                    stage = idx
                }
            }
        }
    }

    private func quietRow(_ title: String, sub: String, on: Bool) -> some View {
        HStack(alignment: .top, spacing: KoumSpacing.md) {
            Circle()
                .fill(on ? KoumColor.firstlight : KoumColor.nightEdge)
                .frame(width: 5, height: 5)
                .padding(.top, 7)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(KoumType.smallLabel)
                    .foregroundStyle(on ? KoumColor.bone : KoumColor.boneFaint)
                Text(sub)
                    .font(KoumType.caption)
                    .foregroundStyle(KoumColor.boneMuted.opacity(on ? 1 : 0.5))
            }
        }
    }
}

// MARK: - Page 4: one line, and up

private struct MiniJournalCard: View {
    private static let line = "Grateful for the quiet."
    @State private var typedCount = 0
    @State private var streakShown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        MiniStage {
            VStack(alignment: .leading, spacing: KoumSpacing.md) {
                MicroLabel(text: "One line before you go", color: KoumColor.boneMuted)

                HStack {
                    Text(String(Self.line.prefix(typedCount)))
                        .font(KoumType.body)
                        .foregroundStyle(KoumColor.bone)
                    if typedCount < Self.line.count {
                        Rectangle()
                            .fill(KoumColor.firstlight)
                            .frame(width: 2, height: 18)
                    }
                    Spacer(minLength: 0)
                }
                .padding(KoumSpacing.md)
                .frame(minHeight: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(KoumColor.night.opacity(0.7))
                )

                HStack(spacing: KoumSpacing.sm) {
                    FlameGlyph()
                        .stroke(KoumColor.firstlight,
                                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                        .frame(width: 14, height: 18)
                    Text("Morning 1, kept")
                        .font(KoumType.caption)
                        .foregroundStyle(KoumColor.boneMuted)
                }
                .opacity(streakShown ? 1 : 0)
                .offset(y: streakShown ? 0 : 4)
            }
        }
        .onAppear { run() }
    }

    private func run() {
        if reduceMotion {
            typedCount = Self.line.count
            streakShown = true
            return
        }
        typedCount = 0
        for idx in 0...Self.line.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7 + Double(idx) * 0.07) {
                typedCount = idx
            }
        }
        withAnimation(KoumMotion.breathEase.delay(0.7 + Double(Self.line.count) * 0.07 + 0.3)) {
            streakShown = true
        }
    }
}
