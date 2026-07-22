import SwiftData
import SwiftUI

/// The whole morning, one step at a time. Always dark — this flow happens in
/// a dark bedroom.
struct MorningFlowView: View {
    @Bindable var session: MorningSession
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            KoumColor.night.ignoresSafeArea()

            switch session.step {
            case .ringing:
                RingingView(session: session)
                    .transition(.koumStep)
            case .verifying:
                verifyingView
                    .transition(.koumStep)
            case .verified:
                VerifiedBloom {
                    session.advanceFromVerified()
                }
                .transition(.opacity)
            case .prayer:
                PrayerView(session: session)
                    .transition(.koumStep)
            case .devotional:
                DevotionalView(session: session)
                    .transition(.koumStep)
            case .journal:
                JournalView(session: session)
                    .transition(.koumStep)
            case .complete:
                MorningCompleteView(session: session)
                    .transition(.koumStep)
            }
        }
        .animation(KoumMotion.gentleEase, value: stepIndex)
        .environment(\.koumTheme, KoumTheme(isDark: true))
        .preferredColorScheme(.dark)
        .statusBarHidden(session.step == .ringing)
        .onAppear { session.attach(context: modelContext) }
    }

    @ViewBuilder
    private var verifyingView: some View {
        if let verification = session.verification {
            switch verification.mode {
            case .scan:
                ScanView(session: session, verification: verification)
            case .speak:
                SpeakView(session: session, verification: verification)
            case .type:
                TypeView(session: session, verification: verification)
            }
        }
    }

    private var stepIndex: Int {
        switch session.step {
        case .ringing: 0
        case .verifying: 1
        case .verified: 2
        case .prayer: 3
        case .devotional: 4
        case .journal: 5
        case .complete: 6
        }
    }
}

extension AnyTransition {
    /// Cross-fade + 8pt vertical drift. Never a horizontal slide.
    static var koumStep: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(y: 8)),
            removal: .opacity
        )
    }
}
