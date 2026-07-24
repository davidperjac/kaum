import SwiftUI

/// The daily reminder of what this app is for: qum — arise. A whole sunrise
/// happens in miniature: the painted night sky (the same codex skies the
/// onboarding lives under) brightens to first light while Isaiah 60:1 (WEB)
/// settles onto the screen, word of dawn arriving with the dawn itself.
/// ~3.6s, tap anywhere to skip, cold launches only, never shown over an alarm.
struct SplashView: View {
    let onDone: () -> Void

    /// Drives the painted-sky crossfade: 0 = deep night, 1 = sun cresting.
    @State private var dawn: Double = 0
    @State private var line1 = false
    @State private var line2 = false
    @State private var refShown = false
    @State private var markShown = false
    @State private var fadingOut = false
    @State private var finished = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // The same painted skies as onboarding — the splash is the first
            // sunrise the user ever sees, so it must be the same sunrise.
            SkyBackdrop(progress: dawn, meteors: false)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: KoumSpacing.sm) {
                    Text("Arise, shine;")
                        .font(KoumType.splash)
                        .foregroundStyle(KoumColor.bone)
                        .opacity(line1 ? 1 : 0)
                        .offset(y: line1 ? 0 : 8)
                    Text("for your light has come.")
                        .font(KoumType.splash)
                        .foregroundStyle(KoumColor.bone)
                        .opacity(line2 ? 1 : 0)
                        .offset(y: line2 ? 0 : 8)
                }
                .multilineTextAlignment(.center)
                .shadow(color: KoumColor.night.opacity(0.6), radius: 12, y: 2)

                MicroLabel(text: "Isaiah 60:1", color: KoumColor.firstlight)
                    .opacity(refShown ? 1 : 0)
                    .padding(.top, KoumSpacing.md)

                Spacer()
                Spacer()

                Text("KOUM")
                    .font(KoumType.micro)
                    .kerning(3.5)
                    .foregroundStyle(KoumColor.bone.opacity(0.7))
                    .opacity(markShown ? 1 : 0)
                    .padding(.bottom, KoumSpacing.xl)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, KoumSpacing.margin)
        }
        .opacity(fadingOut ? 0 : 1)
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .onAppear { run() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Arise, shine; for your light has come. Isaiah 60:1")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Tap to continue")
    }

    private func run() {
        if reduceMotion {
            dawn = 0.85
            line1 = true
            line2 = true
            refShown = true
            markShown = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { finish() }
            return
        }
        // The whole night-to-morning arc, compressed. Slow enough to feel.
        withAnimation(.easeInOut(duration: 3.4)) { dawn = 1 }
        withAnimation(KoumMotion.breathEase.delay(0.8)) { line1 = true }
        withAnimation(KoumMotion.breathEase.delay(1.4)) { line2 = true }
        withAnimation(KoumMotion.gentleEase.delay(2.1)) { refShown = true }
        withAnimation(KoumMotion.gentleEase.delay(2.5)) { markShown = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.7) { finish() }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        withAnimation(.easeIn(duration: 0.35)) { fadingOut = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onDone() }
    }
}
