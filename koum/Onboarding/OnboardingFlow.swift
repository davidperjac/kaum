import SwiftData
import SwiftUI

/// The onboarding conversation. Every question is followed by a reaction to
/// the answer; Scripture carries the "why" at two moments; the live demo
/// carries the proof. Nothing ever advances on a tap the user didn't confirm,
/// and a quiet back chevron sits on every screen where going back is safe.
struct OnboardingFlow: View {
    @Environment(AppModel.self) private var app
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(\.modelContext) private var modelContext

    enum Screen: Int, CaseIterable {
        case coldOpen, problem, nameAsk
        case howOften, ackFrequency
        case blockers, ackBlockers
        case verseWhy                 // Mark 1:35 — Jesus' habit
        case motivation, ackMotivation
        case whyDaily                 // Psalm 5:3 — morning by morning
        case walkthrough              // how Koum works, 4 steps
        case demo
        case mode, time, days, verseSource, alarmPermission
        case building
        case summary
        case beforePaywall
        case paywall, confirmation
    }

    @State private var screen: Screen = .coldOpen
    @State private var walkthroughPage = 0

    // Answers
    @State private var userName = ""
    @State private var howOften = ""
    @State private var blockers: Set<String> = []
    @State private var motivation = ""
    @State private var mode: VerifyMode = .scan
    @State private var alarmTime = defaultTime
    @State private var repeatDays: Set<Int> = [2, 3, 4, 5, 6]
    @State private var verseSource: VerseSource = .koumPlan
    @State private var permissionDenied = false

    private static var defaultTime: Date {
        var comps = DateComponents()
        comps.hour = 6
        comps.minute = 30
        return Calendar.current.date(from: comps) ?? Date()
    }

    var body: some View {
        ZStack {
            KoumColor.night.ignoresSafeArea()

            content

            // Quiet back chevron wherever going back is safe
            if let previous = previousScreen {
                VStack {
                    HStack {
                        Button {
                            goBack(to: previous)
                        } label: {
                            GlyphView(glyph: .chevronRight, size: 16, color: KoumColor.boneFaint)
                                .rotationEffect(.degrees(180))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("Back")
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, KoumSpacing.xs)
                .padding(.leading, KoumSpacing.xs)
            }
        }
        .animation(KoumMotion.gentleEase, value: screen)
        .environment(\.koumTheme, KoumTheme(isDark: true))
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var content: some View {
        switch screen {
        case .coldOpen:
            OnboardingStatement(
                lines: ["You already know", "you should start", "your day with God."],
                button: "I know"
            ) { advance(.problem) }
            .transition(.koumStep)

        case .problem:
            OnboardingStatement(
                lines: ["The alarm goes off.", "You mean to open\nyour Bible.", "Then you don't."],
                button: "That's me"
            ) { advance(.nameAsk) }
            .transition(.koumStep)

        case .nameAsk:
            NameScreen(name: $userName) { advance(.howOften) }
                .transition(.koumStep)

        case .howOften:
            OnboardingChoice(
                question: personalized("How often do you actually start your morning with God?"),
                options: ["Almost every day", "A few times a week", "Once in a while", "I keep meaning to"],
                selection: $howOften
            ) { advance(.ackFrequency) }
            .transition(.koumStep)

        case .ackFrequency:
            let ack = OnboardingVoice.frequencyAck(howOften, name: userName)
            AcknowledgementScreen(lines: ack.lines, button: ack.button) {
                advance(.blockers)
            }
            .transition(.koumStep)

        case .blockers:
            OnboardingMultiChoice(
                question: "What usually gets in the way?",
                hint: "(choose any — be honest)",
                options: ["I hit snooze", "I grab my phone first", "I run out of time", "I forget", "I start and don't keep it up"],
                selection: $blockers
            ) { advance(.ackBlockers) }
            .transition(.koumStep)

        case .ackBlockers:
            let ack = OnboardingVoice.blockerAck(blockers)
            AcknowledgementScreen(lines: ack.lines, button: ack.button) {
                advance(.verseWhy)
            }
            .transition(.koumStep)

        case .verseWhy:
            VerseInterstitial(
                eyebrow: "Before the crowds found Jesus, this was his habit.",
                reference: "Mark 1:35",
                text: "Early in the morning, while it was still dark, he rose up and went out, and departed into a deserted place, and prayed there.",
                closing: "The quiet came first. Everything else came out of it.",
                button: "Continue"
            ) { advance(.motivation) }
            .transition(.koumStep)

        case .motivation:
            OnboardingChoice(
                question: "Finish the sentence.\n\n“If I met with God every morning, I'd feel...”",
                options: ["More grounded", "Less anxious", "Closer to God", "More like myself", "More disciplined"],
                selection: $motivation
            ) {
                app.onboardingMotivation = motivation
                    .replacingOccurrences(of: "More ", with: "more ")
                    .replacingOccurrences(of: "Less ", with: "less ")
                    .replacingOccurrences(of: "Closer", with: "closer")
                advance(.ackMotivation)
            }
            .transition(.koumStep)

        case .ackMotivation:
            let ack = OnboardingVoice.motivationAck(motivation, name: userName)
            AcknowledgementScreen(lines: ack.lines, button: ack.button) {
                advance(.whyDaily)
            }
            .transition(.koumStep)

        case .whyDaily:
            VerseInterstitial(
                eyebrow: "David was a king with a kingdom to run. The Lord still got the first appointment of his day.",
                reference: "Psalm 5:3",
                text: "Yahweh, in the morning you will hear my voice. In the morning I will lay my requests before you, and will watch expectantly.",
                closing: "First voice, first requests, first thing. Morning by morning — that's the habit.",
                button: "Every morning, then"
            ) { advance(.walkthrough) }
            .transition(.koumStep)

        case .walkthrough:
            WalkthroughScreen(page: $walkthroughPage) { advance(.demo) }
                .transition(.koumStep)

        case .demo:
            DemoAlarmView { advance(.mode) }
                .transition(.koumStep)

        case .mode:
            ModeChoiceScreen(selection: $mode) { advance(.time) }
                .transition(.koumStep)

        case .time:
            TimeScreen(time: $alarmTime) { advance(.days) }
                .transition(.koumStep)

        case .days:
            DaysScreen(days: $repeatDays) { advance(.verseSource) }
                .transition(.koumStep)

        case .verseSource:
            VerseSourceScreen(selection: $verseSource) { advance(.alarmPermission) }
                .transition(.koumStep)

        case .alarmPermission:
            AlarmPermissionScreen(denied: $permissionDenied) {
                advance(.building)
            }
            .transition(.koumStep)

        case .building:
            BuildingScreen(name: userName, lines: buildingLines) { advance(.summary) }
                .transition(.opacity)

        case .summary:
            SummaryScreen(
                name: userName,
                time: alarmTime,
                days: repeatDays,
                source: verseSource,
                mode: mode,
                motivation: app.onboardingMotivation
            ) { advance(.beforePaywall) }
            .transition(.koumStep)

        case .beforePaywall:
            BeforePaywallView(
                name: userName,
                motivation: app.onboardingMotivation,
                trialDays: subscriptions.yearlyTrialDays
            ) { advance(.paywall) }
            .transition(.koumStep)

        case .paywall:
            PaywallView(onUnlocked: {
                finishSetup()
                advance(.confirmation)
            }, onClose: {
                // Hard paywall: closing returns to the summary; the app
                // stays gated but the user is never trapped in a screen.
                advance(.summary)
            })
            .transition(.koumStep)

        case .confirmation:
            ConfirmationScreen(
                time: alarmTime,
                trialDays: subscriptions.isInTrial ? subscriptions.yearlyTrialDays : nil
            ) {
                app.hasCompletedOnboarding = true
            }
            .transition(.koumStep)
        }
    }

    // MARK: - Back navigation

    /// Where the back chevron leads. nil hides it (first screen, the demo,
    /// the building moment, the paywall pair, and the confirmation).
    private var previousScreen: Screen? {
        switch screen {
        case .coldOpen, .demo, .building, .paywall, .confirmation: nil
        case .problem: .coldOpen
        case .nameAsk: .problem
        case .howOften: .nameAsk
        case .ackFrequency: .howOften
        case .blockers: .howOften
        case .ackBlockers: .blockers
        case .verseWhy: .blockers
        case .motivation: .verseWhy
        case .ackMotivation: .motivation
        case .whyDaily: .motivation
        case .walkthrough: .whyDaily
        // After the demo: back skips the demo (never replay an alarm) and
        // returns to the walkthrough.
        case .mode: .walkthrough
        case .time: .mode
        case .days: .time
        case .verseSource: .days
        case .alarmPermission: .verseSource
        case .summary: .alarmPermission
        case .beforePaywall: .summary
        }
    }

    private func goBack(to previous: Screen) {
        KoumHaptics.selection()
        if screen == .walkthrough, walkthroughPage > 0 {
            withAnimation(KoumMotion.gentleEase) { walkthroughPage -= 1 }
            return
        }
        if previous == .walkthrough { walkthroughPage = 0 }
        screen = previous
    }

    // MARK: - Helpers

    /// The crafting moment narrates the user's actual choices — never
    /// generic theater.
    private var buildingLines: [String] {
        let timeString = alarmTime.formatted(date: .omitted, time: .shortened)
        let daysString: String = {
            if repeatDays.count == 7 { return "every day" }
            if repeatDays == Set([2, 3, 4, 5, 6]) { return "Mon–Fri" }
            return "\(repeatDays.count) mornings a week"
        }()
        let sourceString: String = {
            switch verseSource {
            case .koumPlan: "Verses chosen for mornings"
            case .readingPlan(let book): "Reading through \(book)"
            case .custom(let book, _, _): "Reading through \(book)"
            }
        }()
        let modeString: String = {
            switch mode {
            case .scan: "Your Bible turns it off"
            case .speak: "Your voice turns it off"
            case .type: "Typing the verse turns it off"
            }
        }()
        return [
            "\(sourceString), starting tomorrow",
            "Alarm set for \(timeString), \(daysString)",
            modeString,
        ]
    }

    private func personalized(_ question: String) -> String {
        userName.isEmpty ? question : "\(userName) — \(question.prefix(1).lowercased() + question.dropFirst())"
    }

    private func advance(_ next: Screen) {
        KoumHaptics.buttonPress()
        screen = next
    }

    /// Create the alarm from the collected answers and sync everything.
    private func finishSetup() {
        app.userName = userName

        let comps = Calendar.current.dateComponents([.hour, .minute], from: alarmTime)
        let alarm = AlarmModel(
            name: "Morning",
            hour: comps.hour ?? 6,
            minute: comps.minute ?? 30,
            repeatDays: Array(repeatDays).sorted(),
            mode: mode,
            verseSource: verseSource
        )
        modelContext.insert(alarm)
        try? modelContext.save()

        app.planStartDate = Date()
        subscriptions.setAttributes([
            "onboarding_frequency": howOften,
            "onboarding_blocker": blockers.sorted().joined(separator: ", "),
            "onboarding_motivation": motivation,
            "verification_mode": mode.rawValue,
            "alarm_time": alarm.timeDisplay,
        ])

        Task {
            await app.resyncAlarms(context: modelContext)
        }
    }
}
