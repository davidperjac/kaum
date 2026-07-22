import SwiftUI

/// 8pt base grid.
enum KoumSpacing {
    static let xs: CGFloat = 4     // tight pairs
    static let sm: CGFloat = 8     // within a component
    static let md: CGFloat = 16    // between components
    static let lg: CGFloat = 24    // screen margins
    static let xl: CGFloat = 40    // between sections
    static let xxl: CGFloat = 64   // around Scripture — always generous
    static let xxxl: CGFloat = 96  // alarm screen breathing room

    /// Standard screen margin.
    static let margin: CGFloat = 24
}

/// Motion durations. Everything eases; nothing snaps.
enum KoumMotion {
    static let instant: Double = 0.12   // button press
    static let quick: Double = 0.24     // toggles, selection
    static let gentle: Double = 0.40    // screen transitions
    static let slow: Double = 0.60      // reveals, glow
    static let breath: Double = 0.80    // onboarding line-by-line
    static let dawn: Double = 30.0      // alarm gradient rise

    static var instantEase: Animation { .easeOut(duration: instant) }
    static var quickEase: Animation { .easeOut(duration: quick) }
    static var gentleEase: Animation { .easeInOut(duration: gentle) }
    static var slowEase: Animation { .easeOut(duration: slow) }
    static var breathEase: Animation { .easeInOut(duration: breath) }
}
