import SwiftUI

/// Primary action button. FIRSTLIGHT fill, NIGHT text, height 56, radius 16.
/// One per screen — if a screen has two equal buttons, it is two screens.
struct KoumPrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(KoumType.label)
            .foregroundStyle(KoumColor.night)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(configuration.isPressed ? KoumColor.firstlightDim : KoumColor.firstlight)
                    .opacity(enabled ? 1 : 0.35)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(KoumMotion.instantEase, value: configuration.isPressed)
    }
}

/// Secondary button. 1pt NIGHT_EDGE border, BONE text, transparent fill.
struct KoumSecondaryButtonStyle: ButtonStyle {
    @Environment(\.koumTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(KoumType.label)
            .foregroundStyle(theme.text)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(theme.edge, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(KoumMotion.instantEase, value: configuration.isPressed)
    }
}

/// Ghost button — for skip, later, dismiss. Always quiet, always present.
/// The user must never feel trapped; that is a product value expressed in a
/// component.
struct KoumGhostButtonStyle: ButtonStyle {
    @Environment(\.koumTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(KoumType.label)
            .foregroundStyle(theme.textMuted)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(KoumMotion.instantEase, value: configuration.isPressed)
    }
}

/// Raised-card row (mode select, options). Gentle press: scale + brighten.
struct KoumRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(KoumColor.nightRaised)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(KoumColor.nightEdge.opacity(0.6), lineWidth: 1)
                    )
                    .brightness(configuration.isPressed ? 0.04 : 0)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(KoumMotion.instantEase, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == KoumPrimaryButtonStyle {
    static var koumPrimary: KoumPrimaryButtonStyle { KoumPrimaryButtonStyle() }
}
extension ButtonStyle where Self == KoumSecondaryButtonStyle {
    static var koumSecondary: KoumSecondaryButtonStyle { KoumSecondaryButtonStyle() }
}
extension ButtonStyle where Self == KoumGhostButtonStyle {
    static var koumGhost: KoumGhostButtonStyle { KoumGhostButtonStyle() }
}
