import SwiftUI

/// Koum typography.
///
/// The split is semantic, not aesthetic: **serif (Newsreader) is the voice of
/// Scripture; sans (Inter) is the voice of the app.** They never trade roles.
///
/// All styles scale with Dynamic Type relative to their natural text style.
enum KoumType {

    // MARK: Font family names (PostScript families as bundled)

    private static let serifRegular = "Newsreader-Regular"
    private static let serifMedium = "Newsreader-Medium"
    private static let serifLight = "Newsreader-Light"
    private static let serifItalic = "Newsreader-Italic"
    private static let sansRegular = "Inter-Regular"
    private static let sansMedium = "Inter-Medium"
    private static let sansSemiBold = "Inter-SemiBold"

    // MARK: Scale

    /// Alarm screen verse — the largest thing on any screen. 34/44.
    static let verseHero = Font.custom(serifRegular, size: 34, relativeTo: .largeTitle)

    /// Verse within the flow. 26/38.
    static let verse = Font.custom(serifRegular, size: 26, relativeTo: .title)

    /// Screen headlines. 30/36.
    static let display = Font.custom(serifMedium, size: 30, relativeTo: .largeTitle)

    /// Section heads. 22/28.
    static let title = Font.custom(serifMedium, size: 22, relativeTo: .title2)

    /// Devotional body. 18/30. Scripture is never below 18pt.
    static let devotional = Font.custom(serifRegular, size: 18, relativeTo: .body)

    /// Devotional body, italic (for quoted Scripture inside prose).
    static let devotionalItalic = Font.custom(serifItalic, size: 18, relativeTo: .body)

    /// UI text. 16/24.
    static let body = Font.custom(sansRegular, size: 16, relativeTo: .body)

    /// Buttons, labels. 14/20.
    static let label = Font.custom(sansMedium, size: 14, relativeTo: .callout)

    /// Metadata. 13/18.
    static let caption = Font.custom(sansRegular, size: 13, relativeTo: .caption)

    /// Eyebrows, ALL CAPS. 11/14, letterspaced.
    static let micro = Font.custom(sansMedium, size: 11, relativeTo: .caption2)

    /// Alarm time. 72.
    static let clock = Font.custom(serifLight, size: 72, relativeTo: .largeTitle)

    /// Streak number. 48.
    static let streak = Font.custom(serifMedium, size: 48, relativeTo: .largeTitle)

    /// Wordmark: KOUM in Newsreader Medium, letterspaced by the caller.
    static let wordmark = Font.custom(serifMedium, size: 24, relativeTo: .title2)
}

// MARK: - Line spacing helpers

extension View {
    /// Applies Koum line spacing for a given style's specified line height.
    /// SwiftUI lineSpacing is *additional* space, so pass (lineHeight - size).
    func koumLineSpacing(_ extra: CGFloat) -> some View {
        lineSpacing(extra)
    }
}

// MARK: - Text style conveniences

struct MicroLabel: View {
    let text: String
    var color: Color = KoumColor.boneMuted

    var body: some View {
        Text(text.uppercased())
            .font(KoumType.micro)
            .kerning(1.4)
            .foregroundStyle(color)
    }
}
