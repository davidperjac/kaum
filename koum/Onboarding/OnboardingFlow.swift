import SwiftData
import SwiftUI

/// The 15-screen onboarding. Screens 1–7 are the pitch, 8–13 configuration,
/// then the paywall and confirmation. The live demo at screen 7 is the
/// highest-value screen in the app.
///
/// (The social-proof screen ships only once there are real reviews to quote.)
struct OnboardingFlow: View {
    @Environment(AppModel.self) private var app
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(\.modelContext) private var modelContext

    enum Screen: Int, CaseIterable {
        case coldOpen, problem, howOften, blockers, motivation, mechanism
        case demo
        case mode, time, days, verseSource, alarmPermission, summary
        case paywall, confirmation
    }

    @State private var screen: Screen = .coldOpen

    // Answers
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

            switch screen {
            case .coldOpen:
                OnboardingStatement(
                    lines: ["You already know", "you should start", "your day with Him."],
                    button: "I know"
                ) { advance(.problem) }
                .transition(.koumStep)

            case .problem:
                OnboardingStatement(
                    lines: ["The alarm goes off.", "You mean to open\nyour Bible.", "Then you don't."],
                    button: "That's me"
                ) { advance(.howOften) }
                .transition(.koumStep)

            case .howOften:
                OnboardingChoice(
                    question: "How often do you actually start your morning with God?",
                    options: ["Almost every day", "A few times a week", "Once in a while", "I keep meaning to"],
                    selection: $howOften
                ) { advance(.blockers) }
                .transition(.koumStep)

            case .blockers:
                OnboardingMultiChoice(
                    question: "What usually gets in the way?",
                    hint: "(choose any)",
                    options: ["I hit snooze", "I grab my phone first", "I run out of time", "I forget", "I start and don't keep it up"],
                    selection: $blockers
                ) { advance(.motivation) }
                .transition(.koumStep)

            case .motivation:
                OnboardingChoice(
                    question: "Finish the sentence.\n\n“If I actually did this every morning, I'd feel...”",
                    options: ["More grounded", "Less anxious", "Closer to God", "More like myself", "More disciplined"],
                    selection: $motivation
                ) {
                    app.onboardingMotivation = motivation
                        .replacingOccurrences(of: "More ", with: "more ")
                        .replacingOccurrences(of: "Less ", with: "less ")
                        .replacingOccurrences(of: "Closer", with: "closer")
                    advance(.mechanism)
                }
                .transition(.koumStep)

            case .mechanism:
                OnboardingStatement(
                    lines: [
                        "Koum is an alarm\nthat won't turn off\nuntil you've opened\nyour Bible.",
                        "Not a photo.\nNot a tap.",
                        "It checks.",
                    ],
                    button: "Show me"
                ) { advance(.demo) }
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
                    advance(.summary)
                }
                .transition(.koumStep)

            case .summary:
                SummaryScreen(
                    time: alarmTime,
                    days: repeatDays,
                    source: verseSource,
                    mode: mode,
                    motivation: app.onboardingMotivation
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
                ConfirmationScreen(time: alarmTime) {
                    app.hasCompletedOnboarding = true
                }
                .transition(.koumStep)
            }
        }
        .animation(KoumMotion.gentleEase, value: screen)
        .environment(\.koumTheme, KoumTheme(isDark: true))
        .preferredColorScheme(.dark)
    }

    private func advance(_ next: Screen) {
        KoumHaptics.buttonPress()
        screen = next
    }

    /// Create the alarm from the collected answers and sync everything.
    private func finishSetup() {
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
