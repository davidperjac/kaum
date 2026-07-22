#if DEBUG
import SwiftData
import SwiftUI

/// Launch-argument screen harness for design QA:
/// `xcrun simctl launch <sim> dptech.koum -uiPreview <name>`
/// Renders any screen state directly with seeded data. DEBUG only.
struct DebugPreviewHost: View {
    let name: String

    @Environment(\.modelContext) private var modelContext
    @Environment(AppModel.self) private var app

    @State private var session: MorningSession?

    static var requested: String? {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-uiPreview"), idx + 1 < args.count else { return nil }
        return args[idx + 1]
    }

    var body: some View {
        content
            .onAppear { seed() }
    }

    private func makeSession(step: MorningSession.Step) -> MorningSession {
        // Day 1 of the plan, so the devotional preview shows real content.
        let ref = name == "devotional"
            ? (PlanStore.shared.planDay(1)?.ref ?? VerseRef(book: "Psalms", chapter: 143, verse: 8))
            : VerseRef(book: "Psalms", chapter: 143, verse: 8)
        let s = MorningSession(
            alarmModelID: nil,
            verse: ref,
            verseText: BibleStore.shared.displayText(for: ref, preferred: .kjv),
            anchors: VerseAnchors(required: [Set(["morning"]), Set(["trust"])], supporting: []),
            mode: .scan,
            sound: .default,
            isDemo: false
        )
        s.attach(context: modelContext)
        s.debugJump(to: step)
        return s
    }

    @ViewBuilder
    private var content: some View {
        switch name {
        case "ringing": MorningFlowView(session: held(.ringing))
        case "verified": MorningFlowView(session: held(.verified))
        case "prayer": MorningFlowView(session: held(.prayer))
        case "devotional": MorningFlowView(session: held(.devotional))
        case "journal": MorningFlowView(session: held(.journal))
        case "complete": MorningFlowView(session: held(.complete))
        case "type":
            typePreview
        case "milestone":
            MilestoneView(milestone: 7)
                .background(KoumColor.nightRaised)
                .environment(\.koumTheme, KoumTheme(isDark: true))
                .preferredColorScheme(.dark)
        case "paywall":
            PaywallView(onUnlocked: {}, onClose: {})
        case "home", "home-evening", "home-complete":
            HomeView()
                .environment(\.koumTheme, KoumTheme(isDark: true))
                .preferredColorScheme(.dark)
        case "home-light":
            HomeView()
                .environment(\.koumTheme, KoumTheme(isDark: false))
                .preferredColorScheme(.light)
        case "archive":
            ArchiveView()
                .environment(\.koumTheme, KoumTheme(isDark: true))
                .preferredColorScheme(.dark)
        case "prayerlog":
            PrayerLogView()
                .environment(\.koumTheme, KoumTheme(isDark: true))
                .preferredColorScheme(.dark)
        case "settings":
            SettingsView()
                .environment(\.koumTheme, KoumTheme(isDark: true))
                .preferredColorScheme(.dark)
        default:
            OnboardingFlow()
        }
    }

    private var typePreview: some View {
        let s = held(.ringing)
        s.beginVerification(mode: .type)
        return MorningFlowView(session: s)
    }

    private func held(_ step: MorningSession.Step) -> MorningSession {
        if let session { return session }
        let s = makeSession(step: step)
        DispatchQueue.main.async { session = s }
        return s
    }

    private func seed() {
        let cal = Calendar.current
        let alarmCount = (try? modelContext.fetchCount(FetchDescriptor<AlarmModel>())) ?? 0
        let entryCount = (try? modelContext.fetchCount(FetchDescriptor<DailyEntry>())) ?? 0
        guard alarmCount == 0, entryCount == 0 else { return }

        switch name {
        case "home-evening", "settings":
            // Late-night alarm so the evening/setup state renders.
            let alarm = AlarmModel(hour: 23, minute: 45, repeatDays: [1, 2, 3, 4, 5, 6, 7])
            modelContext.insert(alarm)
        case "home-complete":
            let alarm = AlarmModel()
            modelContext.insert(alarm)
            let entry = DailyEntry(date: Date(), verse: VerseRef(book: "Psalms", chapter: 143, verse: 8))
            entry.verified = true
            entry.journalText = "He goes before me."
            modelContext.insert(entry)
            modelContext.insert(PrayerEntry(text: "Thank you for the quiet of this morning.", verse: entry.verseRef))
            let streak = StreakState()
            streak.current = 12
            streak.longest = 12
            streak.lastCompleted = cal.startOfDay(for: Date())
            modelContext.insert(streak)
        case "archive", "prayerlog":
            for offset in 1...9 {
                guard let day = cal.date(byAdding: .day, value: -offset, to: Date()),
                      let planDay = PlanStore.shared.planDay(offset) else { continue }
                let entry = DailyEntry(date: day, verse: planDay.ref)
                entry.verified = true
                entry.journalText = offset % 3 == 0 ? nil : "Morning \(offset) — still true."
                entry.journalPrompt = "What stood out to you?"
                modelContext.insert(entry)
                if offset % 2 == 0 {
                    let prayer = PrayerEntry(
                        date: day,
                        text: "Keep me steady today, and let me notice one small mercy.",
                        verse: planDay.ref)
                    if offset == 4 {
                        prayer.answered = true
                        prayer.answeredDate = Date()
                    }
                    modelContext.insert(prayer)
                }
            }
        default:
            break
        }
        try? modelContext.save()
    }
}
#endif
