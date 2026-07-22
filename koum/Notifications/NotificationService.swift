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

    /// Day 3 and day 5 trial messages — as promised on the confirmation
    /// screen, honestly.
    static func scheduleTrialReminders() {
        Task {
            await requestPermissionIfNeeded()
            let center = UNUserNotificationCenter.current()

            let day3 = UNMutableNotificationContent()
            day3.title = "Three mornings"
            day3.body = "That's the hard part done."
            day3.sound = .default
            try? await center.add(UNNotificationRequest(
                identifier: "trial.day3",
                content: day3,
                trigger: UNTimeIntervalNotificationTrigger(
                    timeInterval: 3 * 24 * 3600, repeats: false)
            ))

            let day5 = UNMutableNotificationContent()
            day5.title = "Your trial ends in two days"
            day5.body = "You've had 5 mornings with God. If you want to keep going, nothing to do — it renews on its own. If not, cancel in Settings, no hard feelings."
            day5.sound = .default
            try? await center.add(UNNotificationRequest(
                identifier: "trial.day5",
                content: day5,
                trigger: UNTimeIntervalNotificationTrigger(
                    timeInterval: 5 * 24 * 3600, repeats: false)
            ))
        }
    }

    static func cancelTrialReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["trial.day3", "trial.day5"])
    }
}
