import SwiftUI

/// "How Koum works" — four pages, each carrying a living miniature of the
/// real morning instead of a lonely icon: the actual alarm screen in
/// miniature, the verse lighting up word by word under all three ways out,
/// the quiet minutes, the open journal. The user watches their tomorrow
/// happen in the palm of the page.
struct WalkthroughScreen: View {
    @Binding var page: Int
    let onDone: () -> Void

    private let titles = [
        ("The alarm rings", "At your time, straight through Silent and Focus. The real kind of alarm. And it won't stop for a tap."),
        ("Your Bible turns it off", "Scan the open page, say the verse out loud, or type it. Three ways out, and all of them go through Scripture."),
        ("Two quiet minutes with God", "A short prayer drawn from the verse, then a devotional worth reading. Every prayer lands in your log."),
        ("Then, your journal", "How you slept, what you're carrying, what you're grateful for. A line or a page, it's yours. Then you're up."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: KoumSpacing.lg)

            // The living miniature
            Group {
                switch page {
                case 0: MiniAlarmPreview()
                case 1: MiniVerifyCard()
                case 2: MiniQuietCard()
                default: MiniJournalCard()
                }
            }
            .frame(height: 290)
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

// MARK: - Page 1: the real alarm screen, in miniature

/// A faithful miniature of RingingView — the same dawn background, the same
/// clock, the same verse-first layout, the same three ways out — so what the
/// user tries in the demo is exactly what they were just shown.
struct MiniAlarmPreview: View {
    /// Show the "Snooze won't save you" capsule (walkthrough) or not (demo
    /// intro, which carries its own copy below the card).
    var showsSnoozeLine: Bool = true

    @State private var halo = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // The real alarm background: dawn arriving at the bottom edge.
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(hex: 0x0A0E1A))
                .overlay(
                    DawnGradient(progress: 0.55)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                )
                .overlay(
                    StarField(intensity: 0.4, meteors: false, verticalFraction: 0.45)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .allowsHitTesting(false)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(KoumColor.nightEdge, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 24, y: 10)

            VStack(spacing: KoumSpacing.md) {
                // The clock, ringing — a soft halo of first light breathes
                // behind it instead of any pulse ring.
                ZStack {
                    RadialGradient(
                        colors: [
                            KoumColor.firstlight.opacity(halo ? 0.28 : 0.10),
                            KoumColor.firstlight.opacity(0),
                        ],
                        center: .center, startRadius: 0, endRadius: 90
                    )
                    .frame(width: 180, height: 120)
                    VStack(spacing: 2) {
                        Text("6:30")
                            .font(Font.custom("Lora-Regular", size: 40, relativeTo: .largeTitle))
                            .foregroundStyle(KoumColor.bone)
                            .monospacedDigit()
                        MicroLabel(text: "AM", color: KoumColor.boneFaint)
                    }
                }
                .frame(height: 84)

                // The verse, largest thing on the screen — same as the real one.
                VStack(alignment: .leading, spacing: 4) {
                    MicroLabel(text: "Psalm 143:8", color: KoumColor.firstlight)
                    Text("Cause me to hear your loving kindness in the morning…")
                        .font(Font.custom("Lora-Regular", size: 14, relativeTo: .footnote))
                        .koumLineSpacing(4)
                        .foregroundStyle(KoumColor.bone)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // The three ways out — the real rows, scaled down.
                VStack(spacing: 6) {
                    ForEach(VerifyMode.allCases, id: \.self) { mode in
                        miniModeRow(mode)
                    }
                }

                if showsSnoozeLine {
                    Text("Snooze won't save you")
                        .font(KoumType.micro)
                        .foregroundStyle(KoumColor.boneFaint)
                }
            }
            .padding(KoumSpacing.lg)
        }
        .frame(maxWidth: 300)
        .onAppear {
            guard !reduceMotion else { halo = true; return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                halo = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("The alarm screen: the time, the verse, and three ways to turn it off: scan, say it, or type it.")
    }

    private func miniModeRow(_ mode: VerifyMode) -> some View {
        HStack(spacing: KoumSpacing.sm) {
            GlyphView(glyph: mode.glyph, size: 14)
                .frame(width: 18)
            Text(mode.title)
                .font(KoumType.caption)
                .foregroundStyle(KoumColor.bone)
            Spacer()
            GlyphView(glyph: .chevronRight, size: 9, color: KoumColor.boneFaint)
        }
        .padding(.horizontal, KoumSpacing.md)
        .frame(height: 34)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(KoumColor.nightRaised.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(KoumColor.nightEdge.opacity(0.6), lineWidth: 1)
                )
        )
    }
}

// MARK: - Page 2: the verse lights up, three ways out

private struct MiniVerifyCard: View {
    private static let verse = "Cause me to hear your loving kindness in the morning, for I trust in you."
    @State private var litWords = 0
    @State private var activeMode = 1   // start on Say it
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var words: [String] { Self.verse.split(separator: " ").map(String.init) }
    private let modes = VerifyMode.allCases

    var body: some View {
        MiniStage {
            VStack(alignment: .leading, spacing: KoumSpacing.md) {
                // The three options, one always lit — every way out is Scripture.
                HStack(spacing: KoumSpacing.sm) {
                    ForEach(modes.indices, id: \.self) { idx in
                        modeChip(modes[idx], active: idx == activeMode)
                    }
                }

                MicroLabel(text: "Psalm 143:8", color: KoumColor.firstlight)

                Text(attributed)
                    .font(Font.custom("Lora-Regular", size: 17, relativeTo: .body))
                    .koumLineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: KoumSpacing.sm) {
                    GlyphView(glyph: modes[activeMode].glyph, size: 16)
                    Text(litWords >= words.count ? "Every word. Alarm off." : statusLine)
                        .font(KoumType.caption)
                        .foregroundStyle(litWords >= words.count ? KoumColor.verified : KoumColor.boneMuted)
                        .animation(KoumMotion.quickEase, value: litWords)
                }
                .padding(.top, KoumSpacing.xs)
            }
        }
        .onAppear { run() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Three ways to end the alarm: scan the page, say the verse, or type it. Every word, to the end.")
    }

    private var statusLine: String {
        switch modes[activeMode] {
        case .scan: "Scanning the open page…"
        case .speak: "Reading it out loud…"
        case .type: "Typing every word…"
        }
    }

    private func modeChip(_ mode: VerifyMode, active: Bool) -> some View {
        HStack(spacing: 5) {
            GlyphView(glyph: mode.glyph, size: 12,
                      color: active ? KoumColor.night : KoumColor.boneMuted)
            Text(mode.title)
                .font(KoumType.micro)
                .foregroundStyle(active ? KoumColor.night : KoumColor.boneMuted)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(active ? KoumColor.firstlight : KoumColor.night.opacity(0.6))
        )
        .animation(KoumMotion.quickEase, value: active)
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
        // The active chip wanders through all three options while the verse
        // lights up, then settles.
        let total = 0.8 + Double(words.count) * 0.28
        var t = 2.4
        while t < total {
            DispatchQueue.main.asyncAfter(deadline: .now() + t) {
                withAnimation(KoumMotion.quickEase) {
                    activeMode = (activeMode + 1) % modes.count
                }
            }
            t += 2.4
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
                         sub: "Kept in your prayer log, in your words", on: stage >= 1)
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

// MARK: - Page 4: the journal, wide open

private struct MiniJournalCard: View {
    private static let line = "Grateful for the quiet. Nervous about today. God, go with me."
    @State private var typedCount = 0
    @State private var streakShown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        MiniStage {
            VStack(alignment: .leading, spacing: KoumSpacing.md) {
                MicroLabel(text: "Your journal. Say anything.", color: KoumColor.boneMuted)

                HStack {
                    Text(String(Self.line.prefix(typedCount)))
                        .font(KoumType.body)
                        .koumLineSpacing(4)
                        .foregroundStyle(KoumColor.bone)
                        .fixedSize(horizontal: false, vertical: true)
                    if typedCount < Self.line.count {
                        Rectangle()
                            .fill(KoumColor.firstlight)
                            .frame(width: 2, height: 18)
                    }
                    Spacer(minLength: 0)
                }
                .padding(KoumSpacing.md)
                .frame(minHeight: 72, alignment: .topLeading)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7 + Double(idx) * 0.05) {
                typedCount = idx
            }
        }
        withAnimation(KoumMotion.breathEase.delay(0.7 + Double(Self.line.count) * 0.05 + 0.3)) {
            streakShown = true
        }
    }
}
