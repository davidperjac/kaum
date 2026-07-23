import SwiftUI

/// Koum typography.
///
/// The split is semantic, not aesthetic: **serif (Lora) is the voice of
/// Scripture; sans (Inter) is the voice of the app.** They never trade roles.
///
/// Lora carries calligraphic warmth at display sizes and stays sturdy at
/// verse sizes on a dark screen. Inter runs heavier than typical (SemiBold
/// buttons) so nothing reads thin at 6am. All styles scale with Dynamic Type.
enum KoumType {

    // MARK: Font family names (PostScript names as bundled)

    private static let serifRegular = "Lora-Regular"
    private static let serifMedium = "Lora-Medium"
    private static let serifSemiBold = "Lora-SemiBold"
    /// Lora ships no 300 weight; Regular carries the clock face.
    private static let serifLight = "Lora-Regular"
    private static let serifItalic = "Lora-Italic"
    private static let sansRegular = "Inter-Regular"
    private static let sansMedium = "Inter-Medium"
    private static let sansSemiBold = "Inter-SemiBold"

    // MARK: Scale

    /// Alarm screen verse — the largest thing on any screen. 34/44.
    static let verseHero = Font.custom(serifRegular, size: 34, relativeTo: .largeTitle)

    /// Verse within the flow. 26/38.
    static let verse = Font.custom(serifRegular, size: 26, relativeTo: .title)

    /// Screen headlines. 31/38.
    static let display = Font.custom(serifSemiBold, size: 31, relativeTo: .largeTitle)

    /// Section heads. 22/28.
    static let title = Font.custom(serifMedium, size: 22, relativeTo: .title2)

    /// Devotional body. 19/31. Scripture is never below 18pt.
    static let devotional = Font.custom(serifRegular, size: 19, relativeTo: .body)

    /// Devotional body, italic (for quoted Scripture inside prose).
    static let devotionalItalic = Font.custom(serifItalic, size: 19, relativeTo: .body)

    /// UI text. 16/24.
    static let body = Font.custom(sansMedium, size: 16, relativeTo: .body)

    /// Buttons. 17 SemiBold — decisive, never thin.
    static let label = Font.custom(sansSemiBold, size: 17, relativeTo: .body)

    /// Secondary labels. 15/20.
    static let smallLabel = Font.custom(sansMedium, size: 15, relativeTo: .callout)

    /// Metadata. 13/18.
    static let caption = Font.custom(sansMedium, size: 13, relativeTo: .caption)

    /// Eyebrows, ALL CAPS. 11/14, letterspaced.
    static let micro = Font.custom(sansSemiBold, size: 11, relativeTo: .caption2)

    /// Alarm time. 72.
    static let clock = Font.custom(serifLight, size: 72, relativeTo: .largeTitle)

    /// Streak number. 48.
    static let streak = Font.custom(serifSemiBold, size: 48, relativeTo: .largeTitle)

    /// Wordmark: KOUM in Lora SemiBold, letterspaced by the caller.
    static let wordmark = Font.custom(serifSemiBold, size: 24, relativeTo: .title2)

    /// Splash verse — Lora at ceremony size.
    static let splash = Font.custom(serifMedium, size: 30, relativeTo: .largeTitle)
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
