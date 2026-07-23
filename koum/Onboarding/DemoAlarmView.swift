import SwiftUI

/// The live alarm demo — the most important screen in the app. The intro
/// builds the moment like the night before: a quiet clock ticking toward
/// ring, breath-revealed lines, then the lights go out for two seconds and
/// the alarm actually fires. The real verification pipeline runs; the only
/// mercy is a visible "skip" after real struggle.
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
    @State private var ripple = false
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
                Spacer()

                // The clock, holding its breath. Ripples build the whole time.
                ZStack {
                    ForEach(0..<3, id: \.self) { idx in
                        Circle()
                            .stroke(KoumColor.firstlight.opacity(0.4), lineWidth: 1)
                            .frame(width: 130, height: 130)
                            .scaleEffect(ripple ? 2.0 : 0.85)
                            .opacity(ripple ? 0 : 0.6)
                            .animation(
                                reduceMotion ? nil :
                                    .easeOut(duration: 2.8)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(idx) * 0.9),
                                value: ripple
                            )
                    }
                    VStack(spacing: KoumSpacing.xs) {
                        Text("6:30")
                            .font(Font.custom("Lora-Regular", size: 64, relativeTo: .largeTitle))
                            .foregroundStyle(KoumColor.bone)
                            .monospacedDigit()
                        MicroLabel(text: "Tomorrow morning", color: KoumColor.boneFaint)
                    }
                }
                .frame(height: 210)
                .opacity(stage >= 1 ? 1 : 0)

                Spacer()

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

                    Text("Have a Bible nearby if you can.\nNo Bible? You can type the verse.")
                        .font(KoumType.body)
                        .koumLineSpacing(5)
                        .foregroundStyle(KoumColor.boneMuted)
                        .multilineTextAlignment(.center)
                        .opacity(stage >= 3 ? 1 : 0)
                }
                .padding(.horizontal, KoumSpacing.margin)

                Spacer()

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
        ripple = true
        withAnimation(KoumMotion.breathEase) { stage = 1 }
        withAnimation(KoumMotion.breathEase.delay(0.6)) { stage = 2 }
        withAnimation(KoumMotion.breathEase.delay(1.2)) { stage = 3 }
    }

    // MARK: - Countdown: lights out

    private var countdown: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text(countdownLine == 0 ? "Close your eyes." : "It's tomorrow, before sunrise.")
                .font(KoumType.title)
                .foregroundStyle(KoumColor.boneMuted)
                .opacity(countdownLine >= 0 ? 0.9 : 0)
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

        // A breath of darkness, one line, then the alarm fires for real.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            countdownLine = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            withAnimation(KoumMotion.gentleEase) { phase = .demo }
        }
    }
}
