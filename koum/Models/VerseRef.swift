import Foundation

/// A reference to one verse or a short consecutive range within one chapter.
nonisolated struct VerseRef: Hashable, Codable, Sendable {
    var book: String
    var chapter: Int
    var verse: Int
    var verseEnd: Int?

    /// "Psalm 143:8" / "Lamentations 3:22–23"
    var display: String {
        let bookName = book == "Psalms" ? "Psalm" : book
        if let end = verseEnd, end != verse {
            return "\(bookName) \(chapter):\(verse)–\(end)"
        }
        return "\(bookName) \(chapter):\(verse)"
    }

    /// Stable identity string used as a dictionary key ("Psalms.143.8").
    var key: String {
        "\(book).\(chapter).\(verse)"
    }

    var verseRange: ClosedRange<Int> {
        verse...(verseEnd ?? verse)
    }
}

nonisolated enum VerifyMode: String, Codable, CaseIterable, Sendable {
    case scan
    case speak
    case type

    var title: String {
        switch self {
        case .scan: "Scan"
        case .speak: "Say it"
        case .type: "Type it"
        }
    }

    var subtitle: String {
        switch self {
        case .scan: "Point your camera at your open Bible"
        case .speak: "Read the verse out loud"
        case .type: "Type it out"
        }
    }

    var symbolName: String {
        switch self {
        case .scan: "camera"
        case .speak: "mic"
        case .type: "keyboard"
        }
    }

    var glyph: KoumGlyph {
        switch self {
        case .scan: .camera
        case .speak: .mic
        case .type: .keyboard
        }
    }
}

/// Where a given alarm draws its verses from.
nonisolated enum VerseSource: Codable, Hashable, Sendable {
    /// Koum's curated 365-day plan.
    case koumPlan
    /// Sequential reading through one book.
    case readingPlan(book: String)
    /// Sequential reading through a user-chosen chapter range of a book.
    case custom(book: String, chapterStart: Int, chapterEnd: Int)

    var title: String {
        switch self {
        case .koumPlan: "Koum's plan"
        case .readingPlan(let book): book
        case .custom(let book, let start, let end):
            start == end ? "\(book) \(start)" : "\(book) \(start)–\(end)"
        }
    }
}

nonisolated enum Translation: String, Codable, CaseIterable, Sendable {
    case kjv = "KJV"
    case web = "WEB"

    var displayName: String {
        switch self {
        case .kjv: "King James Version"
        case .web: "World English Bible"
        }
    }
}

nonisolated enum AppTheme: String, Codable, CaseIterable {
    case system
    case dark
    case light

    var title: String {
        switch self {
        case .system: "Match system"
        case .dark: "Dark"
        case .light: "Light"
        }
    }
}
