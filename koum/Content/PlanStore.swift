import Foundation

/// The curated 365-day plan (bundled with hand-reviewed verification anchors),
/// plus reading-plan sequencing and runtime anchor generation for verses
/// outside the curated set.
nonisolated final class PlanStore: @unchecked Sendable {

    static let shared = PlanStore()

    struct PlanDay: Decodable {
        let day: Int
        let book: String
        let chapter: Int
        let verse: Int
        let verseEnd: Int?
        let required: [[String]]
        let supporting: [String]

        var ref: VerseRef {
            VerseRef(book: book, chapter: chapter, verse: verse, verseEnd: verseEnd)
        }

        var anchors: VerseAnchors {
            VerseAnchors(required: required.map(Set.init), supporting: supporting)
        }
    }

    private let lock = NSLock()
    private var _days: [PlanDay]?
    private var _wordCounts: [String: Int]?

    private init() {}

    private var days: [PlanDay] {
        lock.lock()
        defer { lock.unlock() }
        if let d = _days { return d }
        guard let url = Bundle.main.url(forResource: "plan", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([PlanDay].self, from: data)
        else {
            assertionFailure("Missing bundled plan.json")
            return []
        }
        _days = decoded
        return decoded
    }

    /// Word frequency across KJV+WEB, for runtime anchor generation.
    private var wordCounts: [String: Int] {
        lock.lock()
        defer { lock.unlock() }
        if let w = _wordCounts { return w }
        guard let url = Bundle.main.url(forResource: "wordfreq", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: Int].self, from: data)
        else { return [:] }
        _wordCounts = decoded
        return decoded
    }

    // MARK: - Day resolution

    /// The curated plan entry for a given plan day (1-based, wraps at 365).
    func planDay(_ day: Int) -> PlanDay? {
        let days = self.days
        guard !days.isEmpty else { return nil }
        let idx = ((day - 1) % days.count + days.count) % days.count
        return days[idx]
    }

    /// Verse + anchors for a date under a given source.
    /// `startDate` is when the user began using the app (plan day 1).
    func verseForDate(_ date: Date, source: VerseSource, startDate: Date) -> (ref: VerseRef, anchors: VerseAnchors)? {
        let cal = Calendar.current
        let daysSince = max(0, cal.dateComponents(
            [.day],
            from: cal.startOfDay(for: startDate),
            to: cal.startOfDay(for: date)).day ?? 0)

        switch source {
        case .koumPlan:
            guard let entry = planDay(daysSince + 1) else { return nil }
            return (entry.ref, entry.anchors)

        case .readingPlan(let book):
            return sequentialVerse(book: book, chapterStart: 1,
                                   chapterEnd: BibleStore.shared.chapterCount(book: book),
                                   index: daysSince)

        case .custom(let book, let start, let end):
            return sequentialVerse(book: book, chapterStart: start, chapterEnd: end, index: daysSince)
        }
    }

    /// Sequential reading: day N gets the Nth verse-group of the range,
    /// wrapping at the end. Groups short verses so each morning reads at
    /// least ~40 characters.
    private func sequentialVerse(book: String, chapterStart: Int, chapterEnd: Int, index: Int) -> (VerseRef, VerseAnchors)? {
        let store = BibleStore.shared
        var groups: [VerseRef] = []
        let last = min(chapterEnd, store.chapterCount(book: book))
        guard last >= chapterStart, chapterStart >= 1 else { return nil }

        for chapter in chapterStart...last {
            let count = store.verseCount(book: book, chapter: chapter)
            var v = 1
            while v <= count {
                var end = v
                var len = store.text(book: book, chapter: chapter, verse: v, translation: .kjv)?.count ?? 0
                // group very short verses with the next one
                while len < 40, end + 1 <= count {
                    end += 1
                    len += store.text(book: book, chapter: chapter, verse: end, translation: .kjv)?.count ?? 0
                }
                if len > 0 {
                    groups.append(VerseRef(book: book, chapter: chapter, verse: v,
                                           verseEnd: end > v ? end : nil))
                }
                v = end + 1
            }
        }
        guard !groups.isEmpty else { return nil }
        let ref = groups[index % groups.count]
        return (ref, runtimeAnchors(for: ref))
    }

    // MARK: - Runtime anchors

    /// For verses outside the curated plan: the rarest content words of the
    /// verse become required anchors; the rest become supporting.
    func runtimeAnchors(for ref: VerseRef) -> VerseAnchors {
        let store = BibleStore.shared
        let counts = wordCounts

        var tokens: Set<String> = []
        for translation in Translation.allCases {
            if let text = store.text(for: ref, translation: translation) {
                tokens.formUnion(TextNormalizer.tokens(from: text))
            }
        }
        guard !tokens.isEmpty else {
            return VerseAnchors(required: [], supporting: [])
        }

        // Rank by rarity (missing from table = very rare)
        let ranked = tokens.sorted { (counts[$0] ?? 1) < (counts[$1] ?? 1) }
        let distinctive = ranked.filter { (counts[$0] ?? 1) < 900 }

        let requiredWords = distinctive.prefix(3)
        let supporting = ranked.dropFirst(requiredWords.count).prefix(6)
        return VerseAnchors(
            required: requiredWords.map { Set([$0]) },
            supporting: Array(supporting)
        )
    }

    func preload() {
        Task.detached(priority: .utility) {
            _ = self.days
            _ = self.wordCounts
        }
    }
}
