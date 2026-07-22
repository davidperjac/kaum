import Foundation

/// Hand-reviewed (or runtime-derived) anchor concepts for one verse.
/// Each `required` set is one concept; any member matching counts as a hit.
nonisolated struct VerseAnchors: Sendable {
    let required: [Set<String>]
    let supporting: [String]
}

nonisolated enum MatchDecision: Sendable {
    case pass
    case escalate
    case retry
}

nonisolated struct MatchResult: Sendable {
    let score: Double
    let decision: MatchDecision
}

/// The local matcher: three weighted signals, biased toward passing.
/// A false pass costs nothing; a false fail costs a customer.
nonisolated struct LocalMatcher: Sendable {

    /// Thresholds. Tuned generous; lower before raising, never above 0.65.
    var passThreshold: Double = 0.55
    var escalateThreshold: Double = 0.30

    /// Offline mode (no escalation available): drop the pass bar.
    static func forSpeech() -> LocalMatcher {
        LocalMatcher(passThreshold: 0.45, escalateThreshold: 1.0) // speech never escalates
    }

    static func offline() -> LocalMatcher {
        LocalMatcher(passThreshold: 0.45, escalateThreshold: 1.0)
    }

    let weights = (verseNumber: 0.3, phrase: 0.5, overlap: 0.2)

    /// Signal A — verse number proximity. Translation-independent.
    func verseNumberScore(numbers: Set<Int>, target: VerseRef) -> Double {
        let hasChapter = numbers.contains(target.chapter)
        let hasVerse = target.verseRange.contains { numbers.contains($0) }
        if hasChapter && hasVerse { return 1.0 }
        if hasVerse { return 0.6 }
        if hasChapter { return 0.4 }
        return 0.0
    }

    /// Signal B — distinctive anchor phrases. The important one.
    func phraseScore(tokens: Set<String>, anchors: VerseAnchors) -> Double {
        guard !anchors.required.isEmpty else { return 0 }
        let hits = anchors.required.filter { !$0.isDisjoint(with: tokens) }.count
        let base = Double(hits) / Double(anchors.required.count)
        let bonus = Double(anchors.supporting.filter(tokens.contains).count) * 0.05
        return min(base + bonus, 1.0)
    }

    /// Signal C — Jaccard token overlap against the stored verse text.
    func overlapScore(tokens: Set<String>, verseTokens: Set<String>) -> Double {
        guard !tokens.isEmpty, !verseTokens.isEmpty else { return 0 }
        let intersection = tokens.intersection(verseTokens).count
        // Asymmetric containment rather than plain Jaccard: OCR of a full
        // page legitimately contains far more than the verse.
        return Double(intersection) / Double(verseTokens.count)
    }

    func evaluate(
        rawText: String,
        target: VerseRef,
        anchors: VerseAnchors,
        verseTokens: Set<String>
    ) -> MatchResult {
        let tokens = TextNormalizer.tokens(from: rawText)
        let numbers = TextNormalizer.numbers(from: rawText)

        let score = weights.verseNumber * verseNumberScore(numbers: numbers, target: target)
            + weights.phrase * phraseScore(tokens: tokens, anchors: anchors)
            + weights.overlap * overlapScore(tokens: tokens, verseTokens: verseTokens)

        let decision: MatchDecision
        if score >= passThreshold {
            decision = .pass
        } else if score >= escalateThreshold {
            decision = .escalate
        } else {
            decision = .retry
        }
        return MatchResult(score: score, decision: decision)
    }

    /// Tokens of the stored verse across both bundled translations.
    static func verseTokens(for ref: VerseRef) -> Set<String> {
        var tokens: Set<String> = []
        for translation in Translation.allCases {
            if let text = BibleStore.shared.text(for: ref, translation: translation) {
                tokens.formUnion(TextNormalizer.tokens(from: text))
            }
        }
        return tokens
    }
}
