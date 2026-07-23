import Foundation

/// Everything the onboarding conversation has collected so far, persisted on
/// every step so closing the app never sends anyone back to the beginning.
/// Cleared the moment onboarding completes.
nonisolated struct OnboardingProgress: Codable {
    var screenRaw: Int = 0
    var userName: String = ""
    var howOften: String = ""
    var blockers: Set<String> = []
    var motivation: String = ""
    var modeRaw: String = ""
    /// Minutes past midnight; nil = never chosen.
    var alarmMinutes: Int?
    var repeatDays: Set<Int> = [2, 3, 4, 5, 6]
    var verseSource: VerseSource = .koumPlan

    private static let key = "onboardingProgress"

    static func load() -> OnboardingProgress? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(OnboardingProgress.self, from: data)
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
