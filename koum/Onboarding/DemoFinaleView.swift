import StoreKit
import SwiftUI

/// The end of the live demo — the moment the pitch becomes belief. The same
/// painted sky the whole onboarding lives under completes its sunrise here,
/// slowly, while the words settle in. No icons, no ornaments: just dawn and
/// two sentences. This is also where Koum asks, once ever, for an App Store
/// review — at the emotional peak, before the paywall.
struct DemoFinaleView: View {
    let onContinue: () -> Void

    @State private var dawn: Double = 0.05      // sky progress, night → sun
    @State private var line1 = false            // "That's it."
    @State private var line2 = false            // "That's every morning."
    @State private var buttonShown = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.requestReview) private var requestReview

    private static let reviewFlagKey = "didRequestReviewAtFinale"

    var body: some View {
        ZStack {
            // The codex-painted sunrise, arriving for real this time.
            SkyBackdrop(progress: dawn, meteors: false)

            VStack(spacing: 0) {
                Spacer()

                GlyphView(glyph: .check, size: 34, color: KoumColor.verified, lineWidth: 2.5)
                    .opacity(line1 ? 1 : 0)
                    .padding(.bottom, KoumSpacing.xl)

                Text("That's it.")
                    .font(KoumType.display)
                    .foregroundStyle(KoumColor.bone)
                    .shadow(color: KoumColor.night.opacity(0.6), radius: 12, y: 2)
                    .opacity(line1 ? 1 : 0)
                    .offset(y: line1 ? 0 : 6)

                Text("That's every morning.")
                    .font(KoumType.title)
                    .foregroundStyle(KoumColor.bone.opacity(0.85))
                    .shadow(color: KoumColor.night.opacity(0.6), radius: 10, y: 1)
                    .opacity(line2 ? 1 : 0)
                    .offset(y: line2 ? 0 : 6)
                    .padding(.top, KoumSpacing.sm)

                Spacer()

                Button("Set up mine") {
                    KoumHaptics.buttonPress()
                    onContinue()
                }
                .buttonStyle(.koumPrimary)
                .opacity(buttonShown ? 1 : 0)
                .padding(.bottom, KoumSpacing.lg)
            }
            .padding(.horizontal, KoumSpacing.margin)
        }
        .onAppear { run() }
    }

    private func run() {
        if reduceMotion {
            dawn = 1
            line1 = true
            line2 = true
            buttonShown = true
            askForReview(after: 1.2)
            return
        }
        // The whole sunrise, unhurried — dawn should feel earned, not played.
        withAnimation(.easeInOut(duration: 4.5)) { dawn = 1 }
        KoumHapticEngine.shared.playBloomSwell()

        withAnimation(KoumMotion.breathEase.delay(1.2)) { line1 = true }
        withAnimation(KoumMotion.breathEase.delay(2.2)) { line2 = true }
        withAnimation(KoumMotion.gentleEase.delay(3.4)) { buttonShown = true }
        askForReview(after: 3.0)
    }

    /// One ask, ever, at the top of the aha moment. iOS decides whether the
    /// sheet actually appears; the flag stops Koum from ever asking again.
    private func askForReview(after delay: Double) {
        guard !UserDefaults.standard.bool(forKey: Self.reviewFlagKey) else { return }
        UserDefaults.standard.set(true, forKey: Self.reviewFlagKey)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            requestReview()
        }
    }
}
