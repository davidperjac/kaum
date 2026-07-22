import Foundation
import Observation
import SwiftData
import SwiftUI

/// App-level coordinator: onboarding/paywall routing, the active morning
/// session, verse-of-the-day resolution, widget snapshots.
@Observable
@MainActor
final class AppModel {

    // MARK: - Persistent flags (UserDefaults)

    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    /// Plan day 1 anchors here.
    var planStartDate: Date {
        get {
            if let d = UserDefaults.standard.object(forKey: "planStartDate") as? Date { return d }
            let now = Date()
            UserDefaults.standard.set(now, forKey: "planStartDate")
            return now
        }
        set { UserDefaults.standard.set(newValue, forKey: "planStartDate") }
    }

    var themePreference: AppTheme {
        get { AppTheme(rawValue: UserDefaults.standard.string(forKey: "theme") ?? "") ?? .system }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "theme") }
    }

    var translationPreference: Translation {
        get { Translation(rawValue: UserDefaults.standard.string(forKey: "translation") ?? "") ?? .kjv }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "translation") }
    }

    /// Onboarding answers, kept for personalization + attribution.
    var onboardingMotivation: String {
        get { UserDefaults.standard.string(forKey: "onboardingMotivation") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "onboardingMotivation") }
    }

    // MARK: - Session

    var morningSession: MorningSession?

    // MARK: - Verse resolution

    /// Verse + anchors + display text for a date under an alarm's source.
    func verseForDate(_ date: Date, source: VerseSource) -> (ref: VerseRef, anchors: VerseAnchors, text: String)? {
        guard let (ref, anchors) = PlanStore.shared.verseForDate(
            date, source: source, startDate: planStartDate) else { return nil }
        let text = BibleStore.shared.displayText(for: ref, preferred: translationPreference)
        guard !text.isEmpty else { return nil }
        return (ref, anchors, text)
    }

    // MARK: - Morning session lifecycle

    /// Begin the morning flow for a given alarm model (or today's incomplete
    /// morning started manually from Home).
    func beginMorning(alarm: AlarmModel?, context: ModelContext) {
        let source = alarm?.verseSource ?? .koumPlan
        guard let day = verseForDate(Date(), source: source) else { return }

        let session = MorningSession(
            alarmModelID: alarm?.id,
            verse: day.ref,
            verseText: day.text,
            anchors: day.anchors,
            mode: alarm?.mode ?? .scan,
            sound: AlarmSound.named(alarm?.soundName ?? "Dawn")
        )
        session.attach(context: context)
        session.onFinished = { [weak self] in
            self?.morningSession = nil
            self?.refreshWidgetSnapshot(context: context)
        }
        morningSession = session
    }

    /// Route an alarm-fired launch (from the system alert's Open Bible
    /// button, or an alerting alarm found at launch).
    func handleAlarmLaunch(alarmID: String, context: ModelContext) {
        guard morningSession == nil else { return }
        guard let uuid = UUID(uuidString: alarmID) else { return }
        let alarm = try? context.fetch(FetchDescriptor<AlarmModel>(
            predicate: #Predicate { $0.id == uuid })).first
        // Defensively silence AlarmKit; Koum's in-app sound takes over.
        AlarmService.shared.stopRinging(uuid)
        beginMorning(alarm: alarm, context: context)
    }

    /// Has today's morning been completed?
    func todayEntry(context: ModelContext) -> DailyEntry? {
        let today = Calendar.current.startOfDay(for: Date())
        return try? context.fetch(FetchDescriptor<DailyEntry>(
            predicate: #Predicate { $0.date == today })).first
    }

    // MARK: - Alarm scheduling

    /// Re-sync all enabled alarms into AlarmKit (verse references refresh
    /// daily via this call on app foreground).
    func resyncAlarms(context: ModelContext) async {
        guard AlarmService.shared.authState == .authorized else { return }
        let alarms = (try? context.fetch(FetchDescriptor<AlarmModel>())) ?? []
        for alarm in alarms {
            if alarm.enabled {
                let verse = verseForDate(Date(), source: alarm.verseSource)
                try? await AlarmService.shared.schedule(
                    alarm, verseReference: verse?.ref.display ?? "Today's verse")
            } else {
                AlarmService.shared.cancel(alarm.id)
            }
        }
        refreshWidgetSnapshot(context: context)
    }

    /// Next occurrence across enabled alarms.
    func nextAlarmDate(context: ModelContext) -> (date: Date, alarm: AlarmModel)? {
        let alarms = ((try? context.fetch(FetchDescriptor<AlarmModel>())) ?? [])
            .filter(\.enabled)
        let cal = Calendar.current
        let now = Date()
        var best: (Date, AlarmModel)?
        for alarm in alarms {
            for offset in 0...7 {
                guard let day = cal.date(byAdding: .day, value: offset, to: now) else { continue }
                let weekday = cal.component(.weekday, from: day)
                if !alarm.repeatDays.isEmpty && !alarm.repeatDays.contains(weekday) { continue }
                var comps = cal.dateComponents([.year, .month, .day], from: day)
                comps.hour = alarm.hour
                comps.minute = alarm.minute
                guard let fire = cal.date(from: comps), fire > now else { continue }
                if best == nil || fire < best!.0 { best = (fire, alarm) }
                break
            }
        }
        return best.map { (date: $0.0, alarm: $0.1) }
    }

    // MARK: - Widgets

    func refreshWidgetSnapshot(context: ModelContext) {
        var snapshot = WidgetSnapshot()
        snapshot.streak = StreakService.effectiveStreak(in: context).current
        snapshot.completedToday = todayEntry(context: context)?.verified == true

        if let next = nextAlarmDate(context: context) {
            snapshot.nextAlarmDate = next.date
            if let day = verseForDate(next.date, source: next.alarm.verseSource) {
                snapshot.verseReference = day.ref.display
                snapshot.verseText = day.text
            }
        }
        snapshot.save(appGroupID: KoumConfig.appGroupID)
    }
}
