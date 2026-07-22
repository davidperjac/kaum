import SwiftData
import SwiftUI

/// The onboarding conversation. Screens 1–12 are the pitch — told like a
/// conversation with a friend, with Scripture at the two moments that carry
/// the "why". Then the live demo, configuration, and the ask.
///
/// Structure: every question is followed by a reaction to the answer. The
/// user should feel heard, not surveyed.
struct OnboardingFlow: View {
    @Environment(AppModel.self) private var app
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(\.modelContext) private var modelContext

    enum Screen: Int, CaseIterable {
        case coldOpen, problem, nameAsk
        case howOften, ackFrequency
        case blockers, ackBlockers
        case verseWhy                 // Mark 1:35 — this was His habit too
        case motivation, ackMotivation
        case whyDaily                 // manna + Lamentations 3:23 — why every day
        case mechanism
        case demo
        case mode, time, days, verseSource, alarmPermission
        case building
        case summary
        case paywall, confirmation
    }

    @State private var screen: Screen = .coldOpen

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
                    eyebrow: "Before the crowds found Him, this was His habit.",
                    reference: "Mark 1:35",
                    text: "Early in the morning, while it was still dark, he rose up and went out, and departed into a deserted place, and prayed there.",
                    closing: "The quiet came first. Everything else came out of it.",
                    button: "Continue"
                ) { advance(.motivation) }
                .transition(.koumStep)

            case .motivation:
                OnboardingChoice(
                    question: "Finish the sentence.\n\n“If I met Him every morning, I'd feel...”",
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
                    eyebrow: "In the wilderness, bread fell from heaven every morning. It couldn't be stored — yesterday's didn't feed today.",
                    reference: "Lamentations 3:23",
                    text: "They are new every morning. Great is your faithfulness.",
                    closing: "Mercy works like manna. It's gathered daily, or not at all.",
                    button: "Every day, then"
                ) { advance(.mechanism) }
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
