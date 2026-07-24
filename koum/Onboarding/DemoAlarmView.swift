import SwiftUI

/// The live alarm demo — the most important screen in the app. The intro
/// shows the real alarm screen in miniature (the exact UI about to fire),
/// names every way out, then the lights go out and the alarm actually rings.
/// The real verification pipeline runs; the only mercy is a visible "skip"
/// after real struggle.
struct DemoAlarmView: View {
    let onComplete: () -> Void

    private enum Phase {
        case intro
        case countdown
        case demo
    }

    @State private var phase: Phase = .intro
    @State private var session: MorningSession?

    // Intro choreography
    @State private var stage = 0
    @State private var countdownLine = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Psalm 143:8 — short, beautiful, and easy to find or type.
    private static let demoVerse = VerseRef(book: "Psalms", chapter: 143, verse: 8)
    private static let demoAnchors = VerseAnchors(
        required: [
            ["morning"],
            ["lovingkindness", "loving", "steadfast", "unfailing", "kindness"],
            ["trust"],
        ].map(Set.init),
        supporting: ["hear", "cause", "soul", "walk", "lift"]
    )

    /// The dark theater before the alarm: storytelling first, one wink, and
    /// the reminder that there is no way around the Book.
    private static let countdownLines = [
        "Close your eyes.",
        "Okay, keep one open. You'll need it to read.",
        "It's tomorrow, before sunrise.",
        "Your snooze button is praying you'll press it. Don't.",
    ]

    var body: some View {
        ZStack {
            KoumColor.night.ignoresSafeArea()

            switch phase {
            case .intro:
                intro.transition(.koumStep)
            case .countdown:
                countdown.transition(.opacity)
            case .demo:
                if let session {
                    MorningFlowView(session: session)
                        .transition(.opacity)
                }
            }
        }
        .animation(KoumMotion.gentleEase, value: phaseIndex)
    }

    private var phaseIndex: Int {
        switch phase {
        case .intro: 0
        case .countdown: 1
        case .demo: 2
        }
    }

    // MARK: - Intro: the night before, compressed

    private var intro: some View {
        ZStack {
            StarField(intensity: 0.5)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: KoumSpacing.lg)

                // The real alarm screen, in miniature — exactly what is about
                // to fire, nothing invented for the pitch.
                MiniAlarmPreview(showsSnoozeLine: false)
                    .frame(height: 280)
                    .opacity(stage >= 1 ? 1 : 0)
                    .offset(y: stage >= 1 ? 0 : 8)

                Spacer(minLength: KoumSpacing.md)

                VStack(spacing: KoumSpacing.md) {
                    Text("Let's try it.")
                        .font(KoumType.display)
                        .foregroundStyle(KoumColor.bone)
                        .opacity(stage >= 1 ? 1 : 0)
                        .offset(y: stage >= 1 ? 0 : 6)

                    Text("Your alarm is about to ring.\nFor real, right now.")
                        .font(KoumType.title)
                        .koumLineSpacing(6)
                        .foregroundStyle(KoumColor.boneMuted)
                        .multilineTextAlignment(.center)
                        .opacity(stage >= 2 ? 1 : 0)
                        .offset(y: stage >= 2 ? 0 : 6)

                    Text("Say the verse out loud, or type it.\nHave your Bible nearby if you want to try the scan.")
                        .font(KoumType.body)
                        .koumLineSpacing(5)
                        .foregroundStyle(KoumColor.boneMuted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(stage >= 3 ? 1 : 0)
                }
                .padding(.horizontal, KoumSpacing.margin)

                Spacer(minLength: KoumSpacing.md)

                Button("I'm ready") {
                    KoumHaptics.buttonPress()
                    startDemo()
                }
                .buttonStyle(.koumPrimary)
                .opacity(stage >= 3 ? 1 : 0)
                .padding(.horizontal, KoumSpacing.margin)
                .padding(.bottom, KoumSpacing.lg)
            }
        }
        .onAppear { revealIntro() }
    }

    private func revealIntro() {
        if reduceMotion {
            stage = 3
            return
        }
        withAnimation(KoumMotion.breathEase) { stage = 1 }
        withAnimation(KoumMotion.breathEase.delay(0.6)) { stage = 2 }
        withAnimation(KoumMotion.breathEase.delay(1.2)) { stage = 3 }
    }

    // MARK: - Countdown: lights out

    private var countdown: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text(Self.countdownLines[min(countdownLine, Self.countdownLines.count - 1)])
                .font(KoumType.title)
                .koumLineSpacing(6)
                .foregroundStyle(KoumColor.boneMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, KoumSpacing.margin)
                .opacity(0.9)
                .id(countdownLine)
                .transition(.opacity)
                .animation(KoumMotion.breathEase, value: countdownLine)
        }
    }

    private func startDemo() {
        withAnimation(KoumMotion.gentleEase) { phase = .countdown }
        let text = BibleStore.shared.displayText(for: Self.demoVerse, preferred: .kjv)
        let demo = MorningSession(
            alarmModelID: nil,
            verse: Self.demoVerse,
            verseText: text.isEmpty
                ? "Cause me to hear thy lovingkindness in the morning; for in thee do I trust."
                : text,
            anchors: Self.demoAnchors,
            mode: .scan,
            sound: .default,
            isDemo: true
        )
        demo.onFinished = { onComplete() }
        session = demo

        // Darkness, four lines of theater, then the alarm fires for real.
        let lineBeat = 1.5
        for idx in 1..<Self.countdownLines.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + lineBeat * Double(idx)) {
                countdownLine = idx
            }
        }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + lineBeat * Double(Self.countdownLines.count)
        ) {
            withAnimation(KoumMotion.gentleEase) { phase = .demo }
        }
    }
}
