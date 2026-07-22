import SwiftUI

/// Koum palette. Dark theme is primary — the app is dark because it is used
/// in the dark. Light theme exists for daytime reading only.
///
/// Colors are theme-aware through the environment: views that follow the
/// user's theme read the adaptive variants; core-flow screens (alarm,
/// verification, paywall) use the dark constants directly because those
/// screens are always dark.
enum KoumColor {

    // MARK: Dark theme (primary)

    static let night = Color(hex: 0x0A0E1A)          // base background, blue-black
    static let nightRaised = Color(hex: 0x131827)    // cards, sheets
    static let nightEdge = Color(hex: 0x1E2536)      // borders, dividers, inputs

    static let bone = Color(hex: 0xF2EFE8)           // primary text, warm off-white
    static let boneMuted = Color(hex: 0x9BA3B4)      // secondary text
    static let boneFaint = Color(hex: 0x5A6478)      // disabled, placeholder

    static let firstlight = Color(hex: 0xE8A657)     // THE accent — warm amber
    static let firstlightDim = Color(hex: 0x8A6234)  // pressed states

    static let deep = Color(hex: 0x2B4A7A)           // pre-dawn blue
    static let verified = Color(hex: 0x6BAF92)       // success — muted sage
    static let attention = Color(hex: 0xC4726A)      // errors — muted clay

    // MARK: Light theme (secondary)

    static let paper = Color(hex: 0xF7F5F0)
    static let paperRaised = Color(hex: 0xFFFFFF)
    static let paperEdge = Color(hex: 0xE3DFD6)

    static let ink = Color(hex: 0x16192A)
    static let inkMuted = Color(hex: 0x5A6070)
    static let inkFaint = Color(hex: 0x9A9FAE)

    static let firstlightOnLight = Color(hex: 0xC4802E)
    static let verifiedOnLight = Color(hex: 0x4A8A6E)
    static let attentionOnLight = Color(hex: 0xA85248)
}

/// Adaptive palette for screens that follow the user's theme setting
/// (devotional, journal, home, archive, settings). Core-flow screens use
/// `KoumColor` dark constants directly.
struct KoumTheme {
    let isDark: Bool

    var background: Color { isDark ? KoumColor.night : KoumColor.paper }
    var raised: Color { isDark ? KoumColor.nightRaised : KoumColor.paperRaised }
    var edge: Color { isDark ? KoumColor.nightEdge : KoumColor.paperEdge }
    var text: Color { isDark ? KoumColor.bone : KoumColor.ink }
    var textMuted: Color { isDark ? KoumColor.boneMuted : KoumColor.inkMuted }
    var textFaint: Color { isDark ? KoumColor.boneFaint : KoumColor.inkFaint }
    var accent: Color { isDark ? KoumColor.firstlight : KoumColor.firstlightOnLight }
    var success: Color { isDark ? KoumColor.verified : KoumColor.verifiedOnLight }
    var attention: Color { isDark ? KoumColor.attention : KoumColor.attentionOnLight }
}

private struct KoumThemeKey: EnvironmentKey {
    static let defaultValue = KoumTheme(isDark: true)
}

extension EnvironmentValues {
    var koumTheme: KoumTheme {
        get { self[KoumThemeKey.self] }
        set { self[KoumThemeKey.self] = newValue }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
