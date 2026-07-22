import Foundation

/// Normalizes OCR / speech / typed text into content-word tokens.
/// Strips digits, punctuation, and stop words; lowercases; keeps words of
/// length ≥ 3. Verse numbers are extracted separately before stripping —
/// they are a strong, translation-independent locator signal.
nonisolated enum TextNormalizer {

    static let stopWords: Set<String> = [
        "the", "and", "for", "that", "with", "his", "her", "him", "she",
        "you", "your", "yours", "they", "them", "their", "this", "these",
        "those", "there", "then", "than", "but", "not", "nor", "are", "was",
        "were", "been", "being", "have", "has", "had", "will", "would",
        "shall", "should", "may", "might", "can", "could", "did", "does",
        "doth", "hath", "unto", "thee", "thou", "thy", "thine", "yea",
        "which", "what", "when", "where", "who", "whom", "whose", "why",
        "how", "all", "any", "each", "every", "both", "few", "more", "most",
        "other", "some", "such", "only", "own", "same", "too", "very", "one",
        "two", "out", "off", "over", "under", "again", "further", "into",
        "through", "during", "before", "after", "above", "below", "from",
        "down", "upon", "also", "because", "until", "while", "about",
        "against", "between", "among", "let", "even", "saith", "said", "say",
        "says", "verily",
    ]

    /// Content-word tokens from raw text.
    static func tokens(from raw: String) -> Set<String> {
        var result: Set<String> = []
        var current = ""
        for scalar in raw.lowercased().unicodeScalars {
            if ("a"..."z").contains(String(scalar)) {
                current.append(Character(scalar))
            } else {
                appendToken(current, to: &result)
                current = ""
            }
        }
        appendToken(current, to: &result)
        return result
    }

    private static func appendToken(_ token: String, to set: inout Set<String>) {
        guard token.count >= 3, !stopWords.contains(token) else { return }
        set.insert(token)
    }

    /// All integers found in the raw text (verse/chapter numbers, footnotes…).
    static func numbers(from raw: String) -> Set<Int> {
        var result: Set<Int> = []
        var current = ""
        for ch in raw {
            if ch.isNumber {
                current.append(ch)
            } else {
                if let n = Int(current), n > 0, n < 1000 { result.insert(n) }
                current = ""
            }
        }
        if let n = Int(current), n > 0, n < 1000 { result.insert(n) }
        return result
    }

    /// Character-level similarity for Type mode: 0...1, case and punctuation
    /// ignored. Uses Levenshtein distance over normalized characters.
    static func characterSimilarity(_ a: String, _ b: String) -> Double {
        let na = normalizedCharacters(a)
        let nb = normalizedCharacters(b)
        guard !na.isEmpty, !nb.isEmpty else { return 0 }
        let dist = levenshtein(na, nb)
        let maxLen = max(na.count, nb.count)
        return 1.0 - Double(dist) / Double(maxLen)
    }

    /// Similarity of `typed` against the matching-length prefix of `target`,
    /// for live feedback while the user is still typing.
    static func prefixSimilarity(typed: String, target: String) -> Double {
        let nt = normalizedCharacters(typed)
        let full = normalizedCharacters(target)
        guard !nt.isEmpty, !full.isEmpty else { return 0 }
        let prefix = Array(full.prefix(nt.count))
        let dist = levenshtein(nt, prefix)
        return 1.0 - Double(dist) / Double(max(nt.count, prefix.count))
    }

    private static func normalizedCharacters(_ s: String) -> [Character] {
        s.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    private static func levenshtein(_ a: [Character], _ b: [Character]) -> Int {
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var previous = Array(0...b.count)
        var current = [Int](repeating: 0, count: b.count + 1)
        for i in 1...a.count {
            current[0] = i
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                current[j] = Swift.min(
                    previous[j] + 1,
                    current[j - 1] + 1,
                    previous[j - 1] + cost
                )
            }
            swap(&previous, &current)
        }
        return previous[b.count]
    }
}
