import SwiftUI

/// Screen 7 — the live alarm demo. The most important screen in the app.
/// The alarm actually fires (volume capped; they're holding the phone), the
/// real verification pipeline runs, and the demo can never fail: two failed
/// attempts auto-pass with grace.
struct DemoAlarmView: View {
    let onComplete: () -> Void

    private enum Phase {
        case intro
        case countdown
        case demo
    }

    @State private var phase: Phase = .intro
    @State private var session: MorningSession?

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

    var body: some View {
        ZStack {
            KoumColor.night.ignoresSafeArea()

            switch phase {
            case .intro:
                intro.transition(.koumStep)
            case .countdown:
                Color.clear
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

    private var intro: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text("Let's try it.")
                .font(KoumType.display)
                .foregroundStyle(KoumColor.bone)
                .padding(.bottom, KoumSpacing.lg)

            Text("Your alarm is about\nto go off.")
                .font(KoumType.title)
                .koumLineSpacing(6)
                .foregroundStyle(KoumColor.bone)
                .padding(.bottom, KoumSpacing.lg)

            Text("Have a Bible nearby —\nor don't, you can type\nit instead.")
                .font(KoumType.body)
                .koumLineSpacing(6)
                .foregroundStyle(KoumColor.boneMuted)

            Spacer()

            Button("I'm ready") {
                KoumHaptics.buttonPress()
                startDemo()
            }
            .buttonStyle(.koumPrimary)
            .padding(.bottom, KoumSpacing.lg)
        }
        .padding(.horizontal, KoumSpacing.margin)
    }

    private func startDemo() {
        phase = .countdown
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

        // A 2-second pause, then the alarm fires for real.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(KoumMotion.gentleEase) { phase = .demo }
        }
    }
}
