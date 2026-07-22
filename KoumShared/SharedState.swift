import Foundation

/// Snapshot the app writes to the App Group for widgets to read.
struct WidgetSnapshot: Codable {
    var nextAlarmDate: Date?
    var streak: Int = 0
    var completedToday: Bool = false
    var verseReference: String = ""
    var verseText: String = ""

    static let key = "widgetSnapshot"

    static func load(appGroupID: String) -> WidgetSnapshot {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return WidgetSnapshot() }
        return snapshot
    }

    func save(appGroupID: String) {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = try? JSONEncoder().encode(self)
        else { return }
        defaults.set(data, forKey: Self.key)
    }
}
