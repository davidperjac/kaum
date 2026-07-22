import SwiftData
import SwiftUI

/// Morning complete: streak +1, then get out of the way.
struct MorningCompleteView: View {
    @Bindable var session: MorningSession
    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var modelContext

    @State private var displayedStreak = 0
    @State private var showMilestone = false

    var body: some View {
        ZStack {
            KoumColor.night.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                if session.isDemo {
                    demoContent
                } else {
                    realContent
                }

                Spacer()

                Button(session.isDemo ? "Continue" : "Start the day") {
                    KoumHaptics.buttonPress()
                    session.finish()
                }
                .buttonStyle(.koumPrimary)
                .padding(.horizontal, KoumSpacing.margin)
                .padding(.bottom, KoumSpacing.lg)
            }
        }
        .onAppear { animateStreak() }
        .sheet(isPresented: $showMilestone) {
            if let milestone = session.milestoneHit {
                MilestoneView(milestone: milestone)
                    .presentationBackground(KoumColor.nightRaised)
            }
        }
    }

    private var demoContent: some View {
        VStack(spacing: KoumSpacing.md) {
            GlyphView(glyph: .check, size: 30, color: KoumColor.verified, lineWidth: 2.5)
                .padding(.bottom, KoumSpacing.sm)
            Text("That's it.")
                .font(KoumType.display)
                .foregroundStyle(KoumColor.bone)
            Text("That's every morning.")
                .font(KoumType.title)
                .foregroundStyle(KoumColor.boneMuted)
        }
    }

    private var realContent: some View {
        VStack(spacing: KoumSpacing.xl) {
            VStack(spacing: KoumSpacing.sm) {
                HStack(spacing: KoumSpacing.md) {
                    GlyphView(glyph: .check, size: 20, color: KoumColor.verified, lineWidth: 2)
                    Text(app.userName.isEmpty ? "Good morning" : "Good morning, \(app.userName)")
                        .font(KoumType.display)
                        .foregroundStyle(KoumColor.bone)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Text("You read \(session.verse.display)")
                    .font(KoumType.body)
                    .foregroundStyle(KoumColor.boneMuted)
            }

            StreakBadge(count: displayedStreak)
        }
        .environment(\.koumTheme, KoumTheme(isDark: true))
    }

    private func animateStreak() {
        guard !session.isDemo else { return }
        let target = StreakService.state(in: modelContext).current
        displayedStreak = max(0, target - 1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.6)) {
                displayedStreak = target
            }
        }
        if session.milestoneHit != nil {
            KoumHaptics.streakMilestone()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                showMilestone = true
            }
        }
    }
}

/// Milestone sheet: the number, a short verse, quiet celebration.
struct MilestoneView: View {
    let milestone: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let verse = StreakService.milestoneVerse(for: milestone)
        VStack(spacing: 0) {
            Spacer()
            Image("WrenCelebrating")
                .resizable()
                .scaledToFit()
                .frame(height: 96)
                .accessibilityHidden(true)
                .padding(.bottom, KoumSpacing.lg)
            Text("\(milestone)")
                .font(KoumType.streak)
                .foregroundStyle(KoumColor.firstlight)
            Text("mornings with God")
                .font(KoumType.title)
                .foregroundStyle(KoumColor.bone)
                .padding(.top, KoumSpacing.xs)
                .padding(.bottom, KoumSpacing.xl)
            VStack(spacing: KoumSpacing.md) {
                MicroLabel(text: verse.ref)
                Text(verse.text)
                    .font(KoumType.verse)
                    .koumLineSpacing(10)
                    .foregroundStyle(KoumColor.bone)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, KoumSpacing.lg)
            Spacer()
            Button("Keep going") { dismiss() }
                .buttonStyle(.koumPrimary)
                .padding(.horizontal, KoumSpacing.margin)
                .padding(.bottom, KoumSpacing.lg)
        }
        .presentationDetents([.large])
    }
}
