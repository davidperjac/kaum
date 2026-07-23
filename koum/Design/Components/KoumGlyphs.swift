import SwiftUI

/// Koum's custom line icon set: 1.5pt stroke, round caps, drawn on a unit
/// grid. The core flow never uses SF Symbols — that is what makes an app
/// look default. (Settings may.)
enum KoumGlyph {
    case camera
    case mic
    case keyboard
    case book
    case bookRays
    case check
    case chevronRight
    case chevronDown
    case sunrise
}

struct GlyphView: View {
    let glyph: KoumGlyph
    var size: CGFloat = 22
    var color: Color = KoumColor.firstlight
    var lineWidth: CGFloat = 1.5

    var body: some View {
        glyphShape
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }

    private var glyphShape: AnyShape {
        switch glyph {
        case .camera: AnyShape(CameraGlyph())
        case .mic: AnyShape(MicGlyph())
        case .keyboard: AnyShape(KeyboardGlyph())
        case .book: AnyShape(BookGlyph())
        case .bookRays: AnyShape(BookRaysGlyph())
        case .check: AnyShape(CheckmarkShape())
        case .chevronRight: AnyShape(ChevronGlyph(down: false))
        case .chevronDown: AnyShape(ChevronGlyph(down: true))
        case .sunrise: AnyShape(SunriseGlyph())
        }
    }
}

/// Sunrise: the brand mark as a glyph — horizon line, rising dome, three rays.
struct SunriseGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let horizonY = h * 0.68
        // Horizon
        p.move(to: CGPoint(x: 0, y: horizonY))
        p.addLine(to: CGPoint(x: w, y: horizonY))
        // Dome
        p.move(to: CGPoint(x: w * 0.26, y: horizonY))
        p.addArc(
            center: CGPoint(x: w * 0.5, y: horizonY),
            radius: w * 0.24,
            startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false
        )
        // Rays
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.3))
        p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.16))
        p.move(to: CGPoint(x: w * 0.2, y: h * 0.42))
        p.addLine(to: CGPoint(x: w * 0.11, y: h * 0.32))
        p.move(to: CGPoint(x: w * 0.8, y: h * 0.42))
        p.addLine(to: CGPoint(x: w * 0.89, y: h * 0.32))
        return p
    }
}

/// Camera: body with a raised viewfinder hump and a centred lens.
struct CameraGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // Body
        p.addRoundedRect(
            in: CGRect(x: 0, y: h * 0.22, width: w, height: h * 0.62),
            cornerSize: CGSize(width: w * 0.12, height: w * 0.12)
        )
        // Viewfinder hump
        p.move(to: CGPoint(x: w * 0.3, y: h * 0.22))
        p.addLine(to: CGPoint(x: w * 0.38, y: h * 0.08))
        p.addLine(to: CGPoint(x: w * 0.62, y: h * 0.08))
        p.addLine(to: CGPoint(x: w * 0.7, y: h * 0.22))
        // Lens
        p.addEllipse(in: CGRect(x: w * 0.34, y: h * 0.37, width: w * 0.32, height: w * 0.32))
        return p
    }
}

/// Microphone: capsule, cradle, stem, base.
struct MicGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // Capsule
        p.addRoundedRect(
            in: CGRect(x: w * 0.36, y: h * 0.02, width: w * 0.28, height: h * 0.55),
            cornerSize: CGSize(width: w * 0.14, height: w * 0.14)
        )
        // Cradle
        p.move(to: CGPoint(x: w * 0.2, y: h * 0.4))
        p.addCurve(
            to: CGPoint(x: w * 0.8, y: h * 0.4),
            control1: CGPoint(x: w * 0.2, y: h * 0.78),
            control2: CGPoint(x: w * 0.8, y: h * 0.78)
        )
        // Stem + base
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.68))
        p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.88))
        p.move(to: CGPoint(x: w * 0.34, y: h * 0.95))
        p.addLine(to: CGPoint(x: w * 0.66, y: h * 0.95))
        return p
    }
}

/// Keyboard: frame, two rows of key ticks, space bar.
struct KeyboardGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.addRoundedRect(
            in: CGRect(x: 0, y: h * 0.2, width: w, height: h * 0.6),
            cornerSize: CGSize(width: w * 0.1, height: w * 0.1)
        )
        // Key ticks (two rows)
        for (rowY, count) in [(0.36, 4), (0.5, 4)] {
            let spacing = w * 0.72 / CGFloat(count - 1)
            for i in 0..<count {
                let x = w * 0.14 + CGFloat(i) * spacing
                p.move(to: CGPoint(x: x, y: h * rowY))
                p.addLine(to: CGPoint(x: x + 0.001, y: h * rowY))
            }
        }
        // Space bar
        p.move(to: CGPoint(x: w * 0.3, y: h * 0.66))
        p.addLine(to: CGPoint(x: w * 0.7, y: h * 0.66))
        return p
    }
}

/// Open book: spine and two soft page arcs.
struct BookGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // Left page
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.24))
        p.addCurve(
            to: CGPoint(x: 0, y: h * 0.18),
            control1: CGPoint(x: w * 0.35, y: h * 0.1),
            control2: CGPoint(x: w * 0.14, y: h * 0.1)
        )
        p.addLine(to: CGPoint(x: 0, y: h * 0.78))
        p.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.86),
            control1: CGPoint(x: w * 0.14, y: h * 0.7),
            control2: CGPoint(x: w * 0.35, y: h * 0.72)
        )
        // Right page (mirror)
        p.addCurve(
            to: CGPoint(x: w, y: h * 0.78),
            control1: CGPoint(x: w * 0.65, y: h * 0.72),
            control2: CGPoint(x: w * 0.86, y: h * 0.7)
        )
        p.addLine(to: CGPoint(x: w, y: h * 0.18))
        p.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.24),
            control1: CGPoint(x: w * 0.86, y: h * 0.1),
            control2: CGPoint(x: w * 0.65, y: h * 0.1)
        )
        // Spine
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.24))
        p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.86))
        return p
    }
}

/// Open Bible with light rising from the pages: the finale mark. The book
/// sits in the lower half; three rays climb from the open spread like the
/// first light of morning coming off the page.
struct BookRaysGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let top = h * 0.52       // book top edge
        let bottom = h * 0.98    // book bottom edge

        // Left page
        p.move(to: CGPoint(x: w * 0.5, y: top + h * 0.04))
        p.addCurve(
            to: CGPoint(x: 0, y: top),
            control1: CGPoint(x: w * 0.35, y: top - h * 0.06),
            control2: CGPoint(x: w * 0.14, y: top - h * 0.06)
        )
        p.addLine(to: CGPoint(x: 0, y: bottom - h * 0.06))
        p.addCurve(
            to: CGPoint(x: w * 0.5, y: bottom),
            control1: CGPoint(x: w * 0.14, y: bottom - h * 0.1),
            control2: CGPoint(x: w * 0.35, y: bottom - h * 0.08)
        )
        // Right page (mirror)
        p.addCurve(
            to: CGPoint(x: w, y: bottom - h * 0.06),
            control1: CGPoint(x: w * 0.65, y: bottom - h * 0.08),
            control2: CGPoint(x: w * 0.86, y: bottom - h * 0.1)
        )
        p.addLine(to: CGPoint(x: w, y: top))
        p.addCurve(
            to: CGPoint(x: w * 0.5, y: top + h * 0.04),
            control1: CGPoint(x: w * 0.86, y: top - h * 0.06),
            control2: CGPoint(x: w * 0.65, y: top - h * 0.06)
        )
        // Spine
        p.move(to: CGPoint(x: w * 0.5, y: top + h * 0.04))
        p.addLine(to: CGPoint(x: w * 0.5, y: bottom))

        // Light rising from the page: centre ray tallest, two angled.
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.3))
        p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.06))
        p.move(to: CGPoint(x: w * 0.3, y: h * 0.36))
        p.addLine(to: CGPoint(x: w * 0.19, y: h * 0.17))
        p.move(to: CGPoint(x: w * 0.7, y: h * 0.36))
        p.addLine(to: CGPoint(x: w * 0.81, y: h * 0.17))
        return p
    }
}

/// Chevron: two strokes, right or down.
struct ChevronGlyph: Shape {
    let down: Bool

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        if down {
            p.move(to: CGPoint(x: w * 0.2, y: h * 0.35))
            p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.65))
            p.addLine(to: CGPoint(x: w * 0.8, y: h * 0.35))
        } else {
            p.move(to: CGPoint(x: w * 0.35, y: h * 0.2))
            p.addLine(to: CGPoint(x: w * 0.65, y: h * 0.5))
            p.addLine(to: CGPoint(x: w * 0.35, y: h * 0.8))
        }
        return p
    }
}
