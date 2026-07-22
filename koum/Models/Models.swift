import Foundation
import SwiftData

// All models are written CloudKit-compatible: no unique constraints, all
// properties optional or defaulted, no non-optional relationships without
// defaults. Sync is enabled by `KoumConfig.cloudKitSyncEnabled` only.

/// A user alarm. Mirrors AlarmKit's state; Koum keeps its own model for UI
/// consistency and for re-registering after reinstall/permission changes.
@Model
final class AlarmModel {
    var id: UUID = UUID()
    var name: String = "Morning"
    var hour: Int = 6
    var minute: Int = 30
    /// Weekday numbers 1–7, Sunday = 1 (Calendar.current convention). Empty =
    /// one-shot alarm for the next occurrence of the time.
    var repeatDays: [Int] = [2, 3, 4, 5, 6]
    var modeRaw: String = VerifyMode.scan.rawValue
    var verseSourceData: Data?
    var soundName: String = "Dawn"
    var enabled: Bool = true
    var createdAt: Date = Date()

    init(
        name: String = "Morning",
        hour: Int = 6,
        minute: Int = 30,
        repeatDays: [Int] = [2, 3, 4, 5, 6],
        mode: VerifyMode = .scan,
        verseSource: VerseSource = .koumPlan,
        soundName: String = "Dawn",
        enabled: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.hour = hour
        self.minute = minute
        self.repeatDays = repeatDays
        self.modeRaw = mode.rawValue
        self.verseSourceData = try? JSONEncoder().encode(verseSource)
        self.soundName = soundName
        self.enabled = enabled
        self.createdAt = Date()
    }

    var mode: VerifyMode {
        get { VerifyMode(rawValue: modeRaw) ?? .scan }
        set { modeRaw = newValue.rawValue }
    }

    var verseSource: VerseSource {
        get {
            guard let data = verseSourceData,
                  let source = try? JSONDecoder().decode(VerseSource.self, from: data)
            else { return .koumPlan }
            return source
        }
        set { verseSourceData = try? JSONEncoder().encode(newValue) }
    }

    var timeDisplay: String {
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let date = Calendar.current.date(from: comps) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }

    var repeatDisplay: String {
        guard !repeatDays.isEmpty else { return "Once" }
        if repeatDays.count == 7 { return "Every day" }
        if Set(repeatDays) == Set([2, 3, 4, 5, 6]) { return "Weekdays" }
        if Set(repeatDays) == Set([1, 7]) { return "Weekends" }
        let symbols = Calendar.current.shortWeekdaySymbols
        return repeatDays.sorted().map { symbols[$0 - 1] }.joined(separator: " ")
    }
}

/// One morning. Created when the alarm fires; completed when verified.
@Model
final class DailyEntry {
    /// Start of day, local calendar.
    var date: Date = Date()
    var verseBook: String = ""
    var verseChapter: Int = 0
    var verseVerse: Int = 0
    var verseVerseEnd: Int?
    var verified: Bool = false
    var verifyModeRaw: String?
    var attempts: Int = 0
    var usedEscapeHatch: Bool = false
    var journalText: String?
    var journalPrompt: String?
    var completedAt: Date?
    var alarmTime: Date?

    init(date: Date, verse: VerseRef, alarmTime: Date? = nil) {
        self.date = Calendar.current.startOfDay(for: date)
        self.verseBook = verse.book
        self.verseChapter = verse.chapter
        self.verseVerse = verse.verse
        self.verseVerseEnd = verse.verseEnd
        self.alarmTime = alarmTime
    }

    var verseRef: VerseRef {
        VerseRef(book: verseBook, chapter: verseChapter, verse: verseVerse, verseEnd: verseVerseEnd)
    }

    var verifyMode: VerifyMode? {
        verifyModeRaw.flatMap(VerifyMode.init(rawValue:))
    }
}

/// A prayer. On-device only (CloudKit private DB when sync is enabled).
@Model
final class PrayerEntry {
    var date: Date = Date()
    var text: String = ""
    var verseBook: String?
    var verseChapter: Int?
    var verseVerse: Int?
    var answered: Bool = false
    var answeredDate: Date?

    init(date: Date = Date(), text: String, verse: VerseRef? = nil) {
        self.date = date
        self.text = text
        self.verseBook = verse?.book
        self.verseChapter = verse?.chapter
        self.verseVerse = verse?.verse
    }

    var verseRef: VerseRef? {
        guard let book = verseBook, let ch = verseChapter, let v = verseVerse else { return nil }
        return VerseRef(book: book, chapter: ch, verse: v)
    }
}

/// Singleton-ish streak state (one row).
@Model
final class StreakState {
    var current: Int = 0
    var longest: Int = 0
    /// Date of the last completed morning (start of day).
    var lastCompleted: Date?
    /// The month (yyyy-MM) in which the automatic freeze was last spent.
    var freezeSpentMonth: String?
    /// Set when a freeze bridges a gap, so the UI can mention it gently once.
    var freezeUsedDate: Date?

    init() {}
}
