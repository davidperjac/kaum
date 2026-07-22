import UIKit

/// Haptic vocabulary. The failed-verification haptic is `.warning`, never
/// `.error` — nothing in this app should feel like failure, especially not at
/// 6am, especially not when the user is trying.
enum KoumHaptics {

    static func verificationPassed() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func verificationFailed() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func buttonPress() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func streakMilestone() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            generator.notificationOccurred(.success)
        }
    }
}
