import SwiftUI

// The conversational beats of onboarding: the name ask, answer
// acknowledgements, Scripture interstitials, and the plan-building moment.
// One voice throughout — a friend who gets up early and doesn't make a
// thing of it.

// MARK: - Name ask

struct NameScreen: View {
    @Binding var name: String
    let onContinue: () -> Void

    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Before anything else,")
                .font(KoumType.title)
                .foregroundStyle(KoumColor.boneMuted)
                .padding(.top, KoumSpacing.xxl)
                .padding(.bottom, KoumSpacing.sm)

            Text("what should we\ncall you?")
                .font(KoumType.display)
                .koumLineSpacing(6)
                .foregroundStyle(KoumColor.bone)
                .padding(.bottom, KoumSpacing.xl)

            ZStack(alignment: .leading) {
                if name.isEmpty {
                    Text("Your first name")
                        .font(KoumType.verse)
                        .foregroundStyle(KoumColor.boneFaint)
                        .allowsHitTesting(false)
                }
                TextField("", text: $name)
                    .font(KoumType.verse)
                    .foregroundStyle(KoumColor.bone)
                    .tint(KoumColor.firstlight)
                    .textContentType(.givenName)
                    .autocorrectionDisabled()
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit { advance() }
            }

            Rectangle()
                .fill(focused ? KoumColor.firstlight : KoumColor.nightEdge)
                .frame(height: 1)
                .padding(.top, KoumSpacing.sm)
                .animation(KoumMotion.quickEase, value: focused)

            Text("Just for the app. No account, no email.")
                .font(KoumType.caption)
                .foregroundStyle(KoumColor.boneFaint)
                .padding(.top, KoumSpacing.md)

            Spacer()

            Button("Continue") { advance() }
                .buttonStyle(.koumPrimary)
                .disabled(trimmed.isEmpty)
                .opacity(trimmed.isEmpty ? 0.4 : 1)
                .padding(.bottom, KoumSpacing.lg)
        }
        .padding(.horizontal, KoumSpacing.margin)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { focused = true }
        }
    }

    private var trimmed: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func advance() {
        name = trimmed
        guard !name.isEmpty else { return }
        KoumHaptics.buttonPress()
        onContinue()
    }
}

// MARK: - Acknowledgement beat

/// A short reaction to what the user just said — the screen that makes the
/// flow feel heard rather than surveyed. Same breath-reveal as statements.
struct AcknowledgementScreen: View {
    let lines: [String]
    let button: String
    let action: () -> Void

    var body: some View {
        OnboardingStatement(lines: lines, button: button, action: action)
    }
}

enum OnboardingVoice {

    /// Reaction to screen "How often do you actually start your morning
    /// with God?"
    static func frequencyAck(_ answer: String, name: String) -> (lines: [String], button: String) {
        let greeting = name.isEmpty ? "" : "\(name), "
        switch answer {
        case "Almost every day":
            return (["\(greeting)then you already\nknow what it gives you.",
                     "The only thing left\nis every day."],
                    "Let's make it every day")
        case "A few times a week":
            return (["So you know it works.", "The hard part isn't\nthe reading.", "It's the getting up."],
                    "That's the part I need")
        case "Once in a while":
            return (["\(greeting)that's more common\nthan you think.", "Wanting to is\nthe real beginning."],
                    "I want more than once in a while")
        default: // "I keep meaning to"
            return (["That might be the most\nhonest answer there is.", "And a promise you keep\nmeaning to keep\nis still a promise."],
                    "Help me keep it")
        }
    }

    /// Reaction to the blockers multi-select.
    static func blockerAck(_ blockers: Set<String>) -> (lines: [String], button: String) {
        if blockers.contains("I hit snooze") {
            return (["The snooze button has\nbeaten better plans\nthan yours.",
                     "It wins because\nnothing is asking\nanything of you."],
                    "Change what's asking")
        }
        if blockers.contains("I grab my phone first") {
            return (["The phone wins because\nit asks first.",
                     "Tomorrow, the first thing\nasking for you\nwill be Scripture."],
                    "I'd rather it be the Lord")
        }
        if blockers.contains("I run out of time") {
            return (["Morning time isn't found.", "It's kept, before\nanything else\ncan claim it."],
                    "Keep it for me")
        }
        return (["Willpower was never\ngoing to be enough.", "Habits need something\nthat doesn't negotiate\nat 6am."],
                "Give me that")
    }

    /// Reaction to the motivation pick — echo their words back.
    static func motivationAck(_ answer: String, name: String) -> (lines: [String], button: String) {
        let feeling = answer.lowercased()
        let opening = name.isEmpty ? "Hold onto that." : "Hold onto that, \(name)."
        return (["\(opening)", "\u{201C}\(feeling.capitalized).\u{201D}", "You'll hear those words\nagain when it matters."],
                "Continue")
    }
}

// MARK: - Scripture interstitial

/// Scripture at the centre of the conversation. World English Bible. The
/// words that matter most carry a soft golden highlight, like a real
/// highlighter pass on a loved Bible page.
struct VerseInterstitial: View {
    let eyebrow: String
    let reference: String
    let text: String
    var keywords: [String] = []
    let closing: String
    let button: String
    let action: () -> Void

    @State private var stage = 0
    /// Characters swept by the highlighter so far, across all marks in
    /// reading order.
    @State private var sweptChars = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text(eyebrow)
                .font(KoumType.body)
                .foregroundStyle(KoumColor.boneMuted)
                .opacity(stage >= 1 ? 1 : 0)
                .padding(.bottom, KoumSpacing.xl)

            VStack(alignment: .leading, spacing: KoumSpacing.md) {
                MicroLabel(text: reference, color: KoumColor.firstlight)
                Text(highlightedText)
                    .font(KoumType.verse)
                    .koumLineSpacing(12)
                    .foregroundStyle(KoumColor.bone)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(reference). \(text)")
            .opacity(stage >= 2 ? 1 : 0)
            .offset(y: stage >= 2 ? 0 : 6)
            .padding(.bottom, KoumSpacing.xl)

            Text(closing)
                .font(KoumType.devotionalItalic)
                .koumLineSpacing(8)
                .foregroundStyle(KoumColor.boneMuted)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(stage >= 3 ? 1 : 0)

            Spacer()

            Button(button, action: action)
                .buttonStyle(.koumPrimary)
                .opacity(stage >= 3 ? 1 : 0)
                .padding(.bottom, KoumSpacing.lg)
        }
        .padding(.horizontal, KoumSpacing.margin)
        .onAppear { reveal() }
    }

    /// Character ranges (offsets into `text`) the highlighter will cross, in
    /// reading order — every occurrence of every keyword.
    private var markRanges: [Range<Int>] {
        var ranges: [Range<Int>] = []
        for keyword in keywords {
            var search = text.startIndex
            while let r = text.range(
                of: keyword, options: .caseInsensitive, range: search..<text.endIndex) {
                ranges.append(
                    text.distance(from: text.startIndex, to: r.lowerBound)
                    ..< text.distance(from: text.startIndex, to: r.upperBound))
                search = r.upperBound
            }
        }
        return ranges.sorted { $0.lowerBound < $1.lowerBound }
    }

    /// The verse with its key words washed in first light. The wash is drawn
    /// like a hand would drag a highlighter: left to right across the first
    /// word, a beat, then the next.
    private var highlightedText: AttributedString {
        var attributed = AttributedString(text)
        var budget = sweptChars
        for range in markRanges {
            guard budget > 0 else { break }
            let take = min(range.count, budget)
            budget -= take
            let chars = attributed.characters
            let lower = chars.index(chars.startIndex, offsetBy: range.lowerBound)
            let upper = chars.index(lower, offsetBy: take)
            // A real highlighter pass: bright gold, ink-dark word.
            attributed[lower..<upper].backgroundColor = KoumColor.firstlight.opacity(0.85)
            attributed[lower..<upper].foregroundColor = KoumColor.night
        }
        return attributed
    }

    /// Drag the highlighter across each mark, character by character, with a
    /// lift of the pen between words.
    private func sweepHighlights() {
        let charStep = 0.045
        let wordPause = 0.35
        var t = 0.0
        var count = 0
        for range in markRanges {
            for _ in 0..<range.count {
                t += charStep
                count += 1
                let target = count
                DispatchQueue.main.asyncAfter(deadline: .now() + t) {
                    sweptChars = target
                }
            }
            t += wordPause
        }
    }

    private func reveal() {
        if reduceMotion {
            stage = 3
            sweptChars = markRanges.reduce(0) { $0 + $1.count }
            return
        }
        withAnimation(KoumMotion.breathEase) { stage = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + KoumMotion.breath) {
            withAnimation(KoumMotion.breathEase) { stage = 2 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + KoumMotion.breath * 2.2) {
            sweepHighlights()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + KoumMotion.breath * 2.6) {
            withAnimation(KoumMotion.breathEase) { stage = 3 }
        }
    }
}

// MARK: - Building your morning

/// The quiet moment where Koum assembles the plan. Not a spinner — dawn
/// arriving over a few honest lines of work. The shared sky shows through;
/// this screen adds only its words.
struct BuildingScreen: View {
    let name: String
    var lines: [String] = [
        "Choosing your first verses",
        "Setting your alarm",
        "Preparing your first morning",
    ]
    let onDone: () -> Void

    @State private var currentLine = -1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text(name.isEmpty ? "Building your morning." : "Building your morning, \(name).")
                .font(KoumType.display)
                .foregroundStyle(KoumColor.bone)
                .padding(.bottom, KoumSpacing.xl)

            VStack(alignment: .leading, spacing: KoumSpacing.md) {
                ForEach(lines.indices, id: \.self) { idx in
                    HStack(spacing: KoumSpacing.md) {
                        Image(systemName: idx < currentLine ? "checkmark" : "circle")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(idx < currentLine ? KoumColor.verified : KoumColor.boneFaint)
                            .contentTransition(.symbolEffect(.replace))
                        Text(lines[idx])
                            .font(KoumType.body)
                            .foregroundStyle(idx <= currentLine ? KoumColor.bone : KoumColor.boneFaint)
                    }
                    .opacity(idx <= currentLine + 1 ? 1 : 0.4)
                }
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, KoumSpacing.margin)
        .onAppear { run() }
    }

    private func run() {
        if reduceMotion {
            currentLine = lines.count
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { onDone() }
            return
        }
        for idx in 0...lines.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(idx) * 0.85) {
                withAnimation(KoumMotion.quickEase) { currentLine = idx }
                if idx > 0 { KoumHaptics.selection() }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(lines.count) * 0.85 + 0.6) {
            onDone()
        }
    }
}
