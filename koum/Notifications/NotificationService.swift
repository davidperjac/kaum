import Foundation
import UserNotifications

/// Local notifications: honest trial touchpoints and the day-1 nudge.
/// Permission is requested quietly at trial start (screen 16 context), never
/// on launch.
enum NotificationService {

    static func requestPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    /// One honest reminder the day before the trial ends — exactly as
    /// promised on the confirmation screen. No-op for trials of 1 day or
    /// none at all.
    static func scheduleTrialReminders(trialDays: Int?) {
        guard let trialDays, trialDays > 1 else { return }
        Task {
            await requestPermissionIfNeeded()
            let center = UNUserNotificationCenter.current()

            let reminder = UNMutableNotificationContent()
            reminder.title = "Your trial ends tomorrow"
            reminder.body = "You've had \(trialDays - 1) \(trialDays - 1 == 1 ? "morning" : "mornings") with God. To keep going, nothing to do — it renews on its own. If not, cancel in Settings, no hard feelings."
            reminder.sound = .default
            try? await center.add(UNNotificationRequest(
                identifier: "trial.reminder",
                content: reminder,
                trigger: UNTimeIntervalNotificationTrigger(
                    timeInterval: Double(trialDays - 1) * 24 * 3600, repeats: false)
            ))
        }
    }

    static func cancelTrialReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["trial.reminder", "trial.day3", "trial.day5"])
    }
}
