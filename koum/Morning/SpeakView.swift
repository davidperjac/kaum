import Combine
import SwiftUI

/// Speak mode: the verse stays on screen; the user reads it aloud, and every
/// word lights up as it is heard. The alarm ends when the whole verse has
/// been spoken — all of it, not most of it.
struct SpeakView: View {
    @Bindable var session: MorningSession
    @Bindable var verification: VerificationSession

    @State private var speaker = SpeakVerifier()
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            KoumColor.night.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: KoumSpacing.xl)

                VStack(alignment: .leading, spacing: KoumSpacing.md) {
                    MicroLabel(text: session.verse.display, color: KoumColor.firstlight)
                    if let coverage = verification.coverage {
                        CoverageVerseText(
                            text: session.verseText,
                            matched: coverage.matched,
                            hero: session.verseText.count <= 150
                        )
                        CoverageProgressLabel(coverage: coverage)
                    }
                }
                .padding(.horizontal, KoumSpacing.margin)

                Spacer()

                // Listening indicator
                VStack(spacing: KoumSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(KoumColor.nightRaised)
                            .frame(width: 88, height: 88)
                        Image(systemName: speaker.listening ? "waveform" : "mic")
                            .font(.system(size: 30))
                            .foregroundStyle(KoumColor.firstlight)
                            .symbolEffect(.variableColor.iterative, isActive: speaker.listening)
                    }

                    Text(speaker.listening ? "Read the whole verse out loud" : "Starting the microphone…")
                        .font(KoumType.body)
                        .foregroundStyle(KoumColor.boneMuted)

                    Text("Your voice stays on your phone.")
                        .font(KoumType.micro)
                        .foregroundStyle(KoumColor.boneFaint)
                }

                Spacer()

                VStack(spacing: KoumSpacing.sm) {
                    if speaker.permissionDenied || speaker.unavailable {
                        Text(speaker.permissionDenied
                             ? "Microphone access is off. Type it instead, or allow it in Settings."
                             : "Speech recognition isn't available right now.")
                            .font(KoumType.caption)
                            .foregroundStyle(KoumColor.boneMuted)
                            .multilineTextAlignment(.center)
                        Button("Type it instead") { session.switchToType() }
                            .buttonStyle(.koumSecondary)
                    } else if verification.offersTypeSwitch {
                        Button("Type it instead") { session.switchToType() }
                            .buttonStyle(.koumGhost)
                    }
                    if verification.offersEscapeHatch {
                        Button(verification.isDemo ? "Skip for now" : "I'll take your word for it") {
                            verification.useEscapeHatch()
                        }
                        .buttonStyle(.koumGhost)
                    }
                }
                .padding(.horizontal, KoumSpacing.margin)
                .padding(.bottom, KoumSpacing.lg)
            }
        }
        .task {
            speaker.onTranscript = { text in
                verification.evaluate(text: text)
            }
            await speaker.start()
        }
        .onReceive(tick) { _ in verification.tick() }
        .onDisappear { speaker.stop() }
    }
}
