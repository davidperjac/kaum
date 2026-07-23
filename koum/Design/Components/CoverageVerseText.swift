import SwiftUI

/// The verse during Speak/Type verification: every word starts as night-dim
/// bone and turns to first light as it is heard or typed. The verse itself
/// is the progress bar — watching it catch fire word by word is the reward
/// for finishing it.
struct CoverageVerseText: View {
    let text: String
    /// Flags aligned with `VerseCoverage.words(from: text)`.
    let matched: [Bool]
    var hero: Bool = false

    var body: some View {
        Text(attributed)
            .font(hero ? KoumType.verseHero : KoumType.verse)
            .koumLineSpacing(hero ? 10 : 12)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(KoumMotion.quickEase, value: matched)
    }

    private var attributed: AttributedString {
        var result = AttributedString()
        var flagIndex = 0
        // Walk the display text chunk by chunk, keeping punctuation attached,
        // consuming one flag per matchable word inside the chunk.
        let chunks = text.split(separator: " ", omittingEmptySubsequences: false)
        for (i, chunk) in chunks.enumerated() {
            let wordCount = VerseCoverage.words(from: String(chunk)).count
            var lit = false
            if wordCount > 0 {
                let end = min(flagIndex + wordCount, matched.count)
                lit = flagIndex < matched.count && matched[flagIndex..<end].allSatisfy { $0 }
                flagIndex = end
            }
            var piece = AttributedString(String(chunk))
            piece.foregroundColor = lit ? KoumColor.firstlight : KoumColor.bone.opacity(0.45)
            result += piece
            if i < chunks.count - 1 {
                result += AttributedString(" ")
            }
        }
        return result
    }
}

/// Quiet numeric progress under a coverage verse: "14 of 21 words".
struct CoverageProgressLabel: View {
    let coverage: VerseCoverage

    var body: some View {
        Text("\(coverage.matchedCount) of \(coverage.total) words")
            .font(KoumType.caption)
            .foregroundStyle(coverage.complete ? KoumColor.verified : KoumColor.boneMuted)
            .monospacedDigit()
            .contentTransition(.numericText())
            .animation(KoumMotion.quickEase, value: coverage.matchedCount)
    }
}
