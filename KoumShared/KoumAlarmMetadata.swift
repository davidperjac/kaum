import AlarmKit
import Foundation

/// Metadata attached to every Koum alarm. Compiled into both the app and the
/// widget extension (the Live Activity renders from it).
struct KoumAlarmMetadata: AlarmMetadata {
    /// Koum's own alarm model ID (stringified UUID).
    let koumAlarmID: String
    /// Display reference for the day's verse, e.g. "Psalm 143:8".
    let verseReference: String

    init(koumAlarmID: String = "", verseReference: String = "") {
        self.koumAlarmID = koumAlarmID
        self.verseReference = verseReference
    }
}
