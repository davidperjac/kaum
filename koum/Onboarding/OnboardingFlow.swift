import SwiftData
import SwiftUI

/// The onboarding conversation. Every question is followed by a reaction to
/// the answer; Scripture carries the "why" at two moments; the live demo
/// carries the proof. One continuous pre-dawn sky sits behind the whole
/// conversation and brightens as the user walks toward their first morning.
/// The flow only moves forward — no back chevrons, no retreat — and every
/// step is saved, so closing the app resumes exactly where they left off.
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
        case mode, time, sound, days, verseSource, alarmPermission
        case building
        case summary
        case beforePaywall
        case paywall, confirmation
    }

    @State private var screen: Screen
    @State private var walkthroughPage = 0

    // Answers
    @State private var userName: String
    @State private var howOften: String
    @State private var blockers: Set<String>
    @State private var motivation: String
    @State private var mode: VerifyMode
    @State private var alarmTime: Date
    @State private var soundName: String
    @State private var repeatDays: Set<Int>
    @State private var verseSource: VerseSource
    @State private var permissionDenied = false

    init() {
        let saved = OnboardingProgress.load()
        _screen = State(initialValue: Self.resumeScreen(from: saved))
        _userName = State(initialValue: saved?.userName ?? "")
        _howOften = State(initialValue: saved?.howOften ?? "")
        _blockers = State(initialValue: saved?.blockers ?? [])
        _motivation = State(initialValue: saved?.motivation ?? "")
        _mode = State(initialValue: VerifyMode(rawValue: saved?.modeRaw ?? "") ?? .scan)
        _soundName = State(initialValue: saved?.soundName ?? AlarmSound.default.id)
        _repeatDays = State(initialValue: saved?.repeatDays ?? [2, 3, 4, 5, 6])
        _verseSource = State(initialValue: saved?.verseSource ?? .koumPlan)
        if let minutes = saved?.alarmMinutes {
            var comps = DateComponents()
            comps.hour = minutes / 60
            comps.minute = minutes % 60
            _alarmTime = State(initialValue: Calendar.current.date(from: comps) ?? Self.defaultTime)
        } else {
            _alarmTime = State(initialValue: Self.defaultTime)
        }
    }

    /// Transient screens can't be re-entered cold; land on the nearest
    /// stable neighbour instead.
    private static func resumeScreen(from saved: OnboardingProgress?) -> Screen {
        guard let saved, let screen = Screen(rawValue: saved.screenRaw) else { return .coldOpen }
        switch screen {
        case .building: return .summary
        case .paywall: return .beforePaywall
        default: return screen
        }
    }

    private static var defaultTime: Date {
        var comps = DateComponents()
        comps.hour = 6
        comps.minute = 30
        return Calendar.current.date(from: comps) ?? Date()
    }

    var body: some View {
        ZStack {
            // The sky owns the whole conversation. The demo and paywall
            // bring their own worlds; everything else lives under dawn.
            if screenShowsSky {
                SkyBackdrop(progress: skyProgress, dimmed: skyDimmed)
                    .transition(.opacity)
            } else {
                KoumColor.night.ignoresSafeArea()
            }

            content
        }
        .animation(KoumMotion.gentleEase, value: screen)
        .environment(\.koumTheme, KoumTheme(isDark: true))
        .preferredColorScheme(.dark)
        .onChange(of: screen) { _, _ in persist() }
    }

    // MARK: - Sky choreography

    /// How far dawn has come, screen by screen. The welcome sits in deep
    /// night; the sun is cresting by the pact.
    private var skyProgress: Double {
        switch screen {
        case .coldOpen: 0.0
        case .problem: 0.04
        case .nameAsk: 0.08
        case .howOften: 0.12
        case .ackFrequency: 0.16
        case .blockers: 0.20
        case .ackBlockers: 0.24
        case .verseWhy: 0.30
        case .motivation: 0.36
        case .ackMotivation: 0.40
        case .whyDaily: 0.46
        case .walkthrough: 0.52
        case .demo: 0.55
        case .mode: 0.60
        case .time: 0.64
        case .sound: 0.67
        case .days: 0.70
        case .verseSource: 0.74
        case .alarmPermission: 0.78
        case .building: 0.85
        case .summary: 0.92
        case .beforePaywall: 0.96
        case .paywall: 1.0
        case .confirmation: 1.0
        }
    }

    /// Control-dense screens get a deeper scrim so cards stay crisp.
    private var skyDimmed: Bool {
        switch screen {
        case .howOften, .blockers, .motivation, .mode, .time, .sound, .days,
             .verseSource, .alarmPermission, .nameAsk:
            true
        default:
            false
        }
    }

    /// The demo simulates a real (dark) morning and the paywall paints its
    /// own dawn; both opt out of the shared sky.
    private var screenShowsSky: Bool {
        switch screen {
        case .demo, .paywall: false
        default: true
        }
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
                hint: "(choose any. be honest)",
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
                keywords: ["morning", "rose up", "prayed"],
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
                keywords: ["morning", "voice", "watch expectantly"],
                closing: "First voice, first requests, first thing. Morning by morning. That's the habit.",
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
            TimeScreen(time: $alarmTime) { advance(.sound) }
                .transition(.koumStep)

        case .sound:
            SoundScreen(selection: $soundName) { advance(.days) }
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
            // Hard paywall. The X (shown until the one-time offer is spent)
            // opens the promo inside PaywallView; it never exits the screen.
            PaywallView(onUnlocked: {
                finishSetup()
                advance(.confirmation)
            })
            .transition(.koumStep)

        case .confirmation:
            ConfirmationScreen(
                time: alarmTime,
                trialDays: subscriptions.isInTrial ? subscriptions.yearlyTrialDays : nil
            ) {
                OnboardingProgress.clear()
                app.hasCompletedOnboarding = true
            }
            .transition(.koumStep)
        }
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
        userName.isEmpty ? question : "\(userName), \(question.prefix(1).lowercased() + question.dropFirst())"
    }

    private func advance(_ next: Screen) {
        KoumHaptics.buttonPress()
        screen = next
    }

    /// Save the whole conversation so a closed app reopens mid-sentence.
    private func persist() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: alarmTime)
        var progress = OnboardingProgress()
        progress.screenRaw = screen.rawValue
        progress.userName = userName
        progress.howOften = howOften
        progress.blockers = blockers
        progress.motivation = motivation
        progress.modeRaw = mode.rawValue
        progress.soundName = soundName
        progress.alarmMinutes = (comps.hour ?? 6) * 60 + (comps.minute ?? 30)
        progress.repeatDays = repeatDays
        progress.verseSource = verseSource
        progress.save()
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
            verseSource: verseSource,
            soundName: soundName
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
