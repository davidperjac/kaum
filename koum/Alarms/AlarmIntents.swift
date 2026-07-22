import Combine
import AppIntents
import Foundation

/// Fired by the "Open Bible" button on the system alarm alert. Opens the app
/// into the verification flow; the alarm keeps its promise there.
struct OpenKoumIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Open Bible"
    static let description = IntentDescription("Open Koum to read today's verse.")
    static let openAppWhenRun = true
    static let isDiscoverable = false

    @Parameter(title: "Alarm ID")
    var alarmID: String

    init() {
        self.alarmID = ""
    }

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        AlarmLaunchState.shared.pendingAlarmID = alarmID
        return .result()
    }
}

/// Fired by the system stop button. Stops the ringing; the morning stays
/// incomplete until verified in-app (the streak is granted only on
/// verification, within the grace window).
struct StopKoumAlarmIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Stop"
    static let description = IntentDescription("Stop the alarm.")
    static let openAppWhenRun = false
    static let isDiscoverable = false

    @Parameter(title: "Alarm ID")
    var alarmID: String

    init() {
        self.alarmID = ""
    }

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        AlarmLaunchState.shared.stoppedWithoutVerification = alarmID
        return .result()
    }
}

/// Cross-object bridge between intents (which run in the app process) and the
/// SwiftUI scene.
@MainActor
final class AlarmLaunchState: ObservableObject {
    static let shared = AlarmLaunchState()

    /// Set when the user tapped "Open Bible" on the system alert.
    @Published var pendingAlarmID: String?
    /// Set when the user stopped the system alert without verifying.
    @Published var stoppedWithoutVerification: String?

    private init() {}
}
