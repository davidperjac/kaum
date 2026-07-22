import Foundation

/// Bundled Bible text (KJV + WEB, both public domain). Loaded lazily off the
/// main thread on first access; ~4MB JSON per translation.
nonisolated final class BibleStore: @unchecked Sendable {

    static let shared = BibleStore()

    struct Book: Decodable {
        let name: String
        let chapters: [[String]]
    }

    private struct BibleFile: Decodable {
        let translation: String
        let books: [Book]
    }

    private let lock = NSLock()
    private var bibles: [Translation: [String: [[String]]]] = [:]
    private var bookOrders: [Translation: [String]] = [:]

    private init() {}

    /// Blocking load; call from a background task or accept first-hit cost.
    private func bible(for translation: Translation) -> [String: [[String]]] {
        lock.lock()
        defer { lock.unlock() }
        if let loaded = bibles[translation] { return loaded }
        guard let url = Bundle.main.url(
            forResource: translation.rawValue.lowercased(), withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let file = try? JSONDecoder().decode(BibleFile.self, from: data)
        else {
            assertionFailure("Missing bundled Bible: \(translation.rawValue)")
            return [:]
        }
        var dict: [String: [[String]]] = [:]
        for book in file.books { dict[book.name] = book.chapters }
        bibles[translation] = dict
        bookOrders[translation] = file.books.map(\.name)
        return dict
    }

    /// Warm both translations in the background.
    func preload() {
        Task.detached(priority: .utility) {
            _ = self.bible(for: .kjv)
            _ = self.bible(for: .web)
        }
    }

    var bookNames: [String] {
        _ = bible(for: .kjv)
        lock.lock()
        defer { lock.unlock() }
        return bookOrders[.kjv] ?? []
    }

    func chapterCount(book: String, translation: Translation = .kjv) -> Int {
        bible(for: translation)[book]?.count ?? 0
    }

    func verseCount(book: String, chapter: Int, translation: Translation = .kjv) -> Int {
        guard let chapters = bible(for: translation)[book],
              chapter >= 1, chapter <= chapters.count else { return 0 }
        return chapters[chapter - 1].count
    }

    /// Text of a single verse, or nil.
    func text(book: String, chapter: Int, verse: Int, translation: Translation) -> String? {
        guard let chapters = bible(for: translation)[book],
              chapter >= 1, chapter <= chapters.count else { return nil }
        let verses = chapters[chapter - 1]
        guard verse >= 1, verse <= verses.count else { return nil }
        let t = verses[verse - 1]
        return t.isEmpty ? nil : t
    }

    /// Text for a ref (joining short ranges), or nil if entirely missing.
    func text(for ref: VerseRef, translation: Translation) -> String? {
        let parts = ref.verseRange.compactMap {
            text(book: ref.book, chapter: ref.chapter, verse: $0, translation: translation)
        }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " ")
    }

    /// Verse text with a guaranteed fallback across translations.
    func displayText(for ref: VerseRef, preferred: Translation) -> String {
        if let t = text(for: ref, translation: preferred) { return t }
        let other: Translation = preferred == .kjv ? .web : .kjv
        return text(for: ref, translation: other) ?? ""
    }
}
