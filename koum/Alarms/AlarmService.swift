import ActivityKit
import AlarmKit
import Foundation
import Observation
import SwiftUI

/// AlarmKit integration: authorization, scheduling, observation, stop.
/// Koum maintains its own alarm model (`AlarmModel`) and mirrors it into
/// AlarmKit; this service is the mirror.
@Observable
@MainActor
final class AlarmService {

    static let shared = AlarmService()

    enum AuthState {
        case notDetermined
        case authorized
        case denied
    }

    private(set) var authState: AuthState = .notDetermined
    /// IDs of alarms currently alerting (ringing) per AlarmKit.
    private(set) var alertingAlarmIDs: Set<UUID> = []

    private let manager = AlarmManager.shared
    private var observationTask: Task<Void, Never>?

    private init() {
        refreshAuthState()
    }

    func refreshAuthState() {
        switch manager.authorizationState {
        case .authorized: authState = .authorized
        case .denied: authState = .denied
        default: authState = .notDetermined
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            let state = try await manager.requestAuthorization()
            refreshAuthState()
            return state == .authorized
        } catch {
            refreshAuthState()
            return false
        }
    }

    /// Observe AlarmKit state so the app knows when an alarm is alerting even
    /// after relaunch.
    func startObserving() {
        guard observationTask == nil else { return }
        observationTask = Task { [weak self] in
            guard let self else { return }
            for await alarms in self.manager.alarmUpdates {
                self.handle(alarms: alarms)
            }
        }
    }

    private func handle(alarms: [Alarm]) {
        var alerting: Set<UUID> = []
        for alarm in alarms where alarm.state == .alerting {
            alerting.insert(alarm.id)
        }
        alertingAlarmIDs = alerting
    }

    // MARK: - Scheduling

    /// (Re)schedule a Koum alarm with AlarmKit. Uses the AlarmModel's ID as
    /// the AlarmKit ID so the two stay in lockstep.
    func schedule(_ model: AlarmModel, verseReference: String) async throws {
        let weekdays = model.repeatDays.compactMap(Self.localeWeekday(from:))

        let time = Alarm.Schedule.Relative.Time(hour: model.hour, minute: model.minute)
        let schedule = Alarm.Schedule.relative(.init(
            time: time,
            repeats: weekdays.isEmpty ? .never : .weekly(weekdays)
        ))

        let idString = model.id.uuidString
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: verseReference),
            stopButton: AlarmButton(
                text: "Stop",
                textColor: Color(hex: 0x5A6478),
                systemImageName: "stop.circle"
            ),
            secondaryButton: AlarmButton(
                text: "Open Bible",
                textColor: Color(hex: 0xE8A657),
                systemImageName: "book"
            ),
            secondaryButtonBehavior: .custom
        )

        let attributes = AlarmAttributes(
            presentation: AlarmPresentation(alert: alert),
            metadata: KoumAlarmMetadata(
                koumAlarmID: idString,
                verseReference: verseReference
            ),
            tintColor: Color(hex: 0xE8A657)
        )

        let configuration = AlarmManager.AlarmConfiguration(
            schedule: schedule,
            attributes: attributes,
            stopIntent: StopKoumAlarmIntent(alarmID: idString),
            secondaryIntent: OpenKoumIntent(alarmID: idString),
            sound: .named(model.soundName)
        )

        _ = try await manager.schedule(id: model.id, configuration: configuration)
    }

    /// One-shot snooze alarm N minutes out. Uses a derived, stable ID so a
    /// re-snooze replaces rather than accumulates.
    func scheduleSnooze(for model: AlarmModel, minutes: Int, verseReference: String) async throws {
        let now = Date()
        let fire = Calendar.current.date(byAdding: .minute, value: minutes, to: now) ?? now
        let comps = Calendar.current.dateComponents([.hour, .minute], from: fire)

        let idString = model.id.uuidString
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: verseReference),
            stopButton: AlarmButton(
                text: "Stop", textColor: Color(hex: 0x5A6478), systemImageName: "stop.circle"),
            secondaryButton: AlarmButton(
                text: "Open Bible", textColor: Color(hex: 0xE8A657), systemImageName: "book"),
            secondaryButtonBehavior: .custom
        )
        let attributes = AlarmAttributes(
            presentation: AlarmPresentation(alert: alert),
            metadata: KoumAlarmMetadata(koumAlarmID: idString, verseReference: verseReference),
            tintColor: Color(hex: 0xE8A657)
        )
        let configuration = AlarmManager.AlarmConfiguration(
            schedule: .relative(.init(
                time: .init(hour: comps.hour ?? 6, minute: comps.minute ?? 30),
                repeats: .never
            )),
            attributes: attributes,
            stopIntent: StopKoumAlarmIntent(alarmID: idString),
            secondaryIntent: OpenKoumIntent(alarmID: idString),
            sound: .named(model.soundName)
        )
        _ = try await manager.schedule(id: Self.snoozeID(for: model.id), configuration: configuration)
    }

    func cancel(_ id: UUID) {
        try? manager.cancel(id: id)
        try? manager.cancel(id: Self.snoozeID(for: id))
    }

    /// Stop a ringing alarm (called when verification passes, or defensively
    /// when entering the flow).
    func stopRinging(_ id: UUID) {
        try? manager.stop(id: id)
        try? manager.stop(id: Self.snoozeID(for: id))
    }

    // MARK: - Helpers

    /// Deterministic secondary UUID for the snooze slot of an alarm.
    static func snoozeID(for id: UUID) -> UUID {
        var bytes = id.uuid
        bytes.0 = bytes.0 &+ 1
        return UUID(uuid: bytes)
    }

    /// Calendar weekday (1 = Sunday … 7 = Saturday) → Locale.Weekday.
    static func localeWeekday(from calendarWeekday: Int) -> Locale.Weekday? {
        switch calendarWeekday {
        case 1: .sunday
        case 2: .monday
        case 3: .tuesday
        case 4: .wednesday
        case 5: .thursday
        case 6: .friday
        case 7: .saturday
        default: nil
        }
    }
}
