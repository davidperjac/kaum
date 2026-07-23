import Foundation

/// Full-verse coverage for Speak and Type: every word of the verse, in
/// order, to 100%. The only forgiveness is *recognition* forgiveness —
/// homophones, archaic spellings, and near-miss transcriptions of a word the
/// user clearly said — never skipped words.
nonisolated struct VerseCoverage: Sendable {

    /// Per-target-word matched flags, in verse order.
    let matched: [Bool]

    var total: Int { matched.count }
    var matchedCount: Int { matched.filter { $0 }.count }
    var complete: Bool { !matched.isEmpty && matched.allSatisfy { $0 } }
    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(matchedCount) / Double(total)
    }

    // MARK: - Matching

    /// Words a recognizer plausibly substitutes for Scripture vocabulary.
    /// Keyed by target word; any listed form counts as that word.
    private static let equivalents: [String: Set<String>] = [
        "yahweh": ["lord", "jehovah", "yahweh", "yaweh", "the"],
        "lovingkindness": ["lovingkindness", "loving", "kindness"],
        "thee": ["thee", "the"],
        "thy": ["thy", "the", "my"],
        "thou": ["thou", "though", "now"],
        "hath": ["hath", "has", "have"],
        "doth": ["doth", "does", "dust"],
        "unto": ["unto", "onto", "into"],
        "saith": ["saith", "says", "sayeth"],
        "shalt": ["shalt", "shall", "shot"],
        "o": ["o", "oh", "owe"],
        "ye": ["ye", "yee", "the", "you"],
    ]

    /// Evaluate a spoken transcript or typed text against the verse.
    /// Alignment walks the verse in order; each verse word may match one of
    /// the next few candidate words, which absorbs recognizer stutter and
    /// duplicated partials without ever letting whole phrases be skipped.
    static func evaluate(candidate: String, verseText: String) -> VerseCoverage {
        let target = words(from: verseText)
        let spoken = words(from: candidate)
        guard !target.isEmpty else { return VerseCoverage(matched: []) }

        var flags = [Bool](repeating: false, count: target.count)
        var spokenIndex = 0

        for (i, word) in target.enumerated() {
            guard spokenIndex < spoken.count else { break }
            // Look a short window ahead: recognizers repeat and stumble.
            let windowEnd = min(spoken.count, spokenIndex + 4)
            var found: Int?
            for j in spokenIndex..<windowEnd where wordMatches(word, spoken[j]) {
                found = j
                break
            }
            if let j = found {
                flags[i] = true
                spokenIndex = j + 1
            }
            // No match: leave the word unlit and stay put — the user may
            // still be mid-verse; later words must not consume this one's
            // candidates out of order.
        }
        return VerseCoverage(matched: flags)
    }

    /// Live typing progress: matched words plus credit for a partial last
    /// word, so the counter moves with every keystroke.
    static func typingProgress(typed: String, verseText: String) -> (coverage: VerseCoverage, partial: Bool) {
        let coverage = evaluate(candidate: typed, verseText: verseText)
        guard !coverage.complete else { return (coverage, false) }

        let target = words(from: verseText)
        let typedWords = words(from: typed)
        // Is the trailing typed word a prefix of the next unmatched verse word?
        if let nextIdx = coverage.matched.firstIndex(of: false),
           let last = typedWords.last,
           !typed.hasSuffix(" "),
           target[nextIdx].hasPrefix(last), last.count < target[nextIdx].count {
            return (coverage, true)
        }
        return (coverage, false)
    }

    /// Verse words normalized for matching: lowercased, letters only.
    /// Every word counts — including "the". 100% means 100%.
    static func words(from text: String) -> [String] {
        text.lowercased()
            .map { $0.isLetter || $0 == "'" ? $0 : " " }
            .reduce(into: "") { $0.append($1) }
            .split(separator: " ")
            .map { $0.replacingOccurrences(of: "'", with: "") }
            .filter { !$0.isEmpty }
    }

    /// One verse word against one candidate word.
    static func wordMatches(_ target: String, _ candidate: String) -> Bool {
        if target == candidate { return true }
        if let forms = equivalents[target], forms.contains(candidate) { return true }
        // Near-miss tolerance scaled to length: never for short words.
        let allowed: Int
        switch target.count {
        case ..<4: allowed = 0
        case 4...6: allowed = 1
        default: allowed = 2
        }
        guard allowed > 0, abs(target.count - candidate.count) <= allowed else {
            return false
        }
        return editDistance(target, candidate) <= allowed
    }

    private static func editDistance(_ a: String, _ b: String) -> Int {
        let aa = Array(a), bb = Array(b)
        if aa.isEmpty { return bb.count }
        if bb.isEmpty { return aa.count }
        var previous = Array(0...bb.count)
        var current = [Int](repeating: 0, count: bb.count + 1)
        for i in 1...aa.count {
            current[0] = i
            for j in 1...bb.count {
                let cost = aa[i - 1] == bb[j - 1] ? 0 : 1
                current[j] = Swift.min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
            }
            swap(&previous, &current)
        }
        return previous[bb.count]
    }
}
