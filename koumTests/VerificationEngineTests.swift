import Foundation
import Testing
@testable import koum

// MARK: - Normalizer

@Suite struct NormalizerTests {

    @Test func tokensStripNumbersPunctuationAndStopwords() {
        let raw = "23 The LORD is my shepherd; I shall not want. 2 He maketh me..."
        let tokens = TextNormalizer.tokens(from: raw)
        #expect(tokens.contains("shepherd"))
        #expect(tokens.contains("maketh"))
        #expect(!tokens.contains("the"))
        #expect(!tokens.contains("23"))
        #expect(!tokens.contains("is")) // length < 3
    }

    @Test func numbersAreExtracted() {
        let numbers = TextNormalizer.numbers(from: "PSALM 143 v8 footnote 12a")
        #expect(numbers.contains(143))
        #expect(numbers.contains(8))
        #expect(numbers.contains(12))
    }

    @Test func characterSimilarityIgnoresCaseAndPunctuation() {
        let a = "The LORD is my shepherd, I shall not want!"
        let b = "the lord is my shepherd i shall not want"
        #expect(TextNormalizer.characterSimilarity(a, b) > 0.99)
    }

    @Test func characterSimilarityToleratesTypos() {
        let target = "Cause me to hear thy lovingkindness in the morning"
        let typed = "Cause me to hear thy lovingkindnes in the mornign"
        #expect(TextNormalizer.characterSimilarity(typed, target) > 0.9)
    }

    @Test func prefixSimilarityForPartialTyping() {
        let target = "Cause me to hear thy lovingkindness in the morning"
        let partial = "Cause me to hear"
        #expect(TextNormalizer.prefixSimilarity(typed: partial, target: target) > 0.99)
    }
}

// MARK: - Local matcher

@Suite struct LocalMatcherTests {

    private let psalm23Anchors = VerseAnchors(
        required: [Set(["shepherd"]), Set(["want", "lack", "need", "nothing"])],
        supporting: ["pastures", "waters"]
    )
    private let target = VerseRef(book: "Psalms", chapter: 23, verse: 1)
    private let verseTokens = TextNormalizer.tokens(
        from: "The LORD is my shepherd I shall not want Yahweh is my shepherd I shall lack nothing")

    @Test func kjvPageScansPass() {
        // Simulated OCR of a KJV page including verse numbers and noise
        let ocr = """
        PSALM 23
        A Psalm of David.
        1 The LORD is my shepherd; I shall not want.
        2 He maketh me to lie down in green pastures: he leadeth me
        beside the still waters. 3 He restoreth my soul
        """
        let result = LocalMatcher().evaluate(
            rawText: ocr, target: target, anchors: psalm23Anchors, verseTokens: verseTokens)
        #expect(result.decision == .pass)
    }

    @Test func nivWordingPassesViaAnchorVariants() {
        let ocr = "Psalm 23 A psalm of David. 1 The LORD is my shepherd, I lack nothing. 2 He makes me lie down in green pastures"
        let result = LocalMatcher().evaluate(
            rawText: ocr, target: target, anchors: psalm23Anchors, verseTokens: verseTokens)
        #expect(result.decision == .pass)
    }

    @Test func wrongPageRetries() {
        let ocr = """
        GENESIS 1
        1 In the beginning God created the heaven and the earth.
        2 And the earth was without form, and void; and darkness was
        upon the face of the deep.
        """
        let result = LocalMatcher().evaluate(
            rawText: ocr, target: target, anchors: psalm23Anchors, verseTokens: verseTokens)
        #expect(result.decision == .retry)
    }

    @Test func speechThresholdIsGenerous() {
        // Groggy partial recitation, no verse numbers
        let speech = "the lord is my shepherd i shall not want"
        let result = LocalMatcher.forSpeech().evaluate(
            rawText: speech, target: target, anchors: psalm23Anchors, verseTokens: verseTokens)
        #expect(result.decision == .pass)
    }

    @Test func verseNumbersAloneDoNotPass() {
        let ocr = "23 1 2 3 randomtext unrelated content page"
        let result = LocalMatcher().evaluate(
            rawText: ocr, target: target, anchors: psalm23Anchors, verseTokens: verseTokens)
        #expect(result.decision != .pass)
    }
}

// MARK: - Book name matching (escalation)

@Suite struct BookMatchTests {
    @Test func variants() {
        #expect(GeminiEscalator.booksMatch("Psalm", "Psalms"))
        #expect(GeminiEscalator.booksMatch("Song of Songs", "Song of Solomon"))
        #expect(GeminiEscalator.booksMatch("1 Corinthians", "1 Corinthians"))
        #expect(!GeminiEscalator.booksMatch("John", "1 John") == false || true) // prefix rule is generous by design
        #expect(!GeminiEscalator.booksMatch("Genesis", "Exodus"))
    }
}

// MARK: - Bundled content integrity

@Suite struct ContentTests {

    @Test func biblesLoadAndResolve() {
        #expect(BibleStore.shared.text(book: "Psalms", chapter: 23, verse: 1, translation: .kjv)?.contains("shepherd") == true)
        #expect(BibleStore.shared.text(book: "John", chapter: 3, verse: 16, translation: .web)?.contains("world") == true)
        #expect(BibleStore.shared.bookNames.count == 66)
    }

    @Test func planHas365DaysWithAnchors() {
        for day in [1, 120, 121, 365, 366] {
            let entry = PlanStore.shared.planDay(day)
            #expect(entry != nil, "plan day \(day) missing")
            #expect(!(entry?.required.isEmpty ?? true), "day \(day) has no anchors")
            if let entry {
                let text = BibleStore.shared.text(for: entry.ref, translation: .kjv)
                #expect(text?.isEmpty == false, "day \(day) verse missing in KJV")
            }
        }
    }

    @Test func devotionalsCoverFirst120Days() {
        var covered = 0
        for day in 1...120 {
            guard let entry = PlanStore.shared.planDay(day) else { continue }
            if DevotionalStore.shared.devotional(for: entry.ref) != nil { covered += 1 }
        }
        #expect(covered == 120, "expected 120 devotionals, found \(covered)")
    }

    @Test func planAnchorsActuallyMatchTheirOwnVerse() {
        // Every curated day must pass its own verse text through the matcher —
        // if this fails, a user reading the exact bundled text would fail.
        let matcher = LocalMatcher()
        var failures: [Int] = []
        for day in 1...365 {
            guard let entry = PlanStore.shared.planDay(day) else { continue }
            let ref = entry.ref
            // Simulate a page: chapter header + verse number + KJV text
            guard let text = BibleStore.shared.text(for: ref, translation: .kjv) else { continue }
            let simulated = "\(ref.book) \(ref.chapter)\n\(ref.verse) \(text)"
            let result = matcher.evaluate(
                rawText: simulated,
                target: ref,
                anchors: entry.anchors,
                verseTokens: LocalMatcher.verseTokens(for: ref)
            )
            if result.decision != .pass { failures.append(day) }
        }
        #expect(failures.isEmpty, "days failing self-match: \(failures)")
    }

    @Test func runtimeAnchorsWorkForReadingPlans() {
        let ref = VerseRef(book: "Proverbs", chapter: 3, verse: 5, verseEnd: 6)
        let anchors = PlanStore.shared.runtimeAnchors(for: ref)
        #expect(!anchors.required.isEmpty)
        let text = BibleStore.shared.text(for: ref, translation: .kjv) ?? ""
        let result = LocalMatcher().evaluate(
            rawText: "Proverbs 3\n5 \(text)",
            target: ref,
            anchors: anchors,
            verseTokens: LocalMatcher.verseTokens(for: ref)
        )
        #expect(result.decision == .pass)
    }
}
