import Foundation

nonisolated struct Devotional: Decodable {
    let day: Int
    let book: String
    let chapter: Int
    let verse: Int
    let verseEnd: Int?
    let context: String
    let reflection: String
    let today: String
    let related: [RelatedRef]

    struct RelatedRef: Decodable, Hashable {
        let book: String
        let chapter: Int
        let verse: Int

        var ref: VerseRef { VerseRef(book: book, chapter: chapter, verse: verse) }
    }

    var ref: VerseRef {
        VerseRef(book: book, chapter: chapter, verse: verse, verseEnd: verseEnd)
    }
}

/// 120 bundled devotionals adapted from Spurgeon's Morning & Evening (public
/// domain), keyed by verse reference.
nonisolated final class DevotionalStore: @unchecked Sendable {

    static let shared = DevotionalStore()

    private let lock = NSLock()
    private var byKey: [String: Devotional]?

    private init() {}

    private func index() -> [String: Devotional] {
        lock.lock()
        defer { lock.unlock() }
        if let i = byKey { return i }
        guard let url = Bundle.main.url(forResource: "devotionals", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([Devotional].self, from: data)
        else {
            assertionFailure("Missing bundled devotionals.json")
            return [:]
        }
        var dict: [String: Devotional] = [:]
        for d in list { dict[d.ref.key] = d }
        byKey = dict
        return dict
    }

    func devotional(for ref: VerseRef) -> Devotional? {
        index()[ref.key]
    }

    func preload() {
        Task.detached(priority: .utility) { _ = self.index() }
    }
}
