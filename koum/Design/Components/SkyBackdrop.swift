import SwiftUI

/// The onboarding sky. One continuous pre-dawn world behind the whole
/// conversation: deep night at the welcome, first light at the Scripture
/// beats, the sun cresting by the finale. Three painted keyframes crossfade
/// as `progress` advances; a starfield lives in the dark and dies with the
/// dawn; everything breathes slower than a resting heart rate.
///
/// Falls back to pure gradients when the painted skies are absent, so
/// previews and tests never break on assets.
struct SkyBackdrop: View {
    /// 0 = deepest night, 1 = sun cresting.
    var progress: Double
    /// Extra dimming for screens dense with controls (choices, pickers).
    var dimmed: Bool = false
    /// Whether the starfield may show meteors.
    var meteors: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathing = false

    private static let hasPaintedSkies = UIImage(named: "SkyNight") != nil

    var body: some View {
        ZStack {
            KoumColor.night.ignoresSafeArea()

            if Self.hasPaintedSkies {
                paintedSky
            } else {
                gradientSky
            }

            StarField(
                intensity: starIntensity,
                meteors: meteors && !reduceMotion
            )
            .ignoresSafeArea()

            readabilityScrim
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
    }

    /// Stars live in the night and fade as first light arrives.
    private var starIntensity: Double {
        max(0, 1 - progress * 1.6) * (dimmed ? 0.5 : 1)
    }

    // MARK: - Painted keyframes

    private var paintedSky: some View {
        GeometryReader { geo in
            ZStack {
                skyImage("SkyNight", size: geo.size)
                    .opacity(1 - clamped((progress - 0.0) / 0.55))
                skyImage("SkyFirstLight", size: geo.size)
                    .opacity(clamped((progress - 0.0) / 0.55) - clamped((progress - 0.55) / 0.45))
                skyImage("SkySunrise", size: geo.size)
                    .opacity(clamped((progress - 0.55) / 0.45))
            }
        }
        .ignoresSafeArea()
    }

    private func skyImage(_ name: String, size: CGSize) -> some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .clipped()
            .scaleEffect(reduceMotion ? 1.04 : (breathing ? 1.07 : 1.04))
            // The world sinks slightly as you walk toward morning.
            .offset(y: CGFloat(progress) * 12)
    }

    private func clamped(_ v: Double) -> Double { min(1, max(0, v)) }

    // MARK: - Gradient fallback

    private var gradientSky: some View {
        let mid: CGFloat = max(0.05, 0.6 - 0.35 * CGFloat(progress))
        let stops: [Gradient.Stop] = [
            Gradient.Stop(color: KoumColor.night, location: 0),
            Gradient.Stop(color: KoumColor.night, location: mid),
            Gradient.Stop(color: Color(hex: 0x1B2A4A).opacity(0.4 + 0.6 * progress), location: 0.82),
            Gradient.Stop(color: KoumColor.firstlight.opacity(0.30 * progress), location: 1),
        ]
        return ZStack {
            LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
            RadialGradient(
                colors: [
                    KoumColor.firstlight.opacity(0.35 * progress),
                    KoumColor.firstlight.opacity(0),
                ],
                center: UnitPoint(x: 0.5, y: 1.12),
                startRadius: 0,
                endRadius: 320
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Scrim

    /// Keeps type legible over the painting without killing it.
    private var readabilityScrim: some View {
        LinearGradient(
            stops: [
                .init(color: KoumColor.night.opacity(dimmed ? 0.78 : 0.55), location: 0),
                .init(color: KoumColor.night.opacity(dimmed ? 0.66 : 0.42), location: 0.45),
                .init(color: KoumColor.night.opacity(dimmed ? 0.5 : 0.22), location: 1),
            ],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Starfield

/// Quiet stars that twinkle on individual clocks, with the occasional slow
/// meteor. Deterministic layout (seeded), Canvas-drawn, cheap. Intensity 0
/// removes it entirely.
struct StarField: View {
    var intensity: Double
    var meteors: Bool = true
    /// Confine stars to the top portion of the screen (1 = whole screen).
    var verticalFraction: CGFloat = 0.72

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Star {
        let x: CGFloat
        let y: CGFloat
        let radius: CGFloat
        let phase: Double
        let speed: Double
        let base: Double
    }

    private static let stars: [Star] = {
        var rng = SeededRandom(seed: 0x5EED)
        return (0..<70).map { _ in
            Star(
                x: CGFloat(rng.next()),
                y: CGFloat(rng.next()),
                radius: 0.5 + CGFloat(rng.next()) * 1.1,
                phase: rng.next() * .pi * 2,
                speed: 0.25 + rng.next() * 0.7,
                base: 0.25 + rng.next() * 0.55
            )
        }
    }()

    var body: some View {
        if intensity <= 0.01 {
            EmptyView()
        } else if reduceMotion {
            Canvas { context, size in
                draw(context: context, size: size, time: 0, animated: false)
            }
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
                Canvas { context, size in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    draw(context: context, size: size, time: t, animated: true)
                }
            }
        }
    }

    private func draw(context: GraphicsContext, size: CGSize, time: Double, animated: Bool) {
        let height = size.height * verticalFraction
        for star in Self.stars {
            let twinkle = animated
                ? (sin(time * star.speed * 2 + star.phase) + 1) / 2
                : 0.5
            let alpha = star.base * (0.45 + 0.55 * twinkle) * intensity
            guard alpha > 0.02 else { continue }
            let rect = CGRect(
                x: star.x * size.width,
                y: star.y * height,
                width: star.radius * 2,
                height: star.radius * 2
            )
            context.fill(
                Path(ellipseIn: rect),
                with: .color(KoumColor.bone.opacity(alpha))
            )
        }

        guard meteors, animated else { return }
        drawMeteor(context: context, size: size, time: time)
    }

    /// One slow shooting star roughly every 12 seconds, each window using its
    /// own seeded trajectory so no two feel alike.
    private func drawMeteor(context: GraphicsContext, size: CGSize, time: Double) {
        let window: Double = 12
        let index = Int(time / window)
        let local = time.truncatingRemainder(dividingBy: window)
        let duration = 1.6
        guard local < duration else { return }

        var rng = SeededRandom(seed: UInt64(bitPattern: Int64(index)) &* 0x9E3779B97F4A7C15 &+ 0xBADC0FFEE)
        // Skip some windows entirely; the sky shouldn't feel busy.
        guard rng.next() < 0.6 else { return }

        let t = local / duration
        let startX = CGFloat(0.15 + rng.next() * 0.7) * size.width
        let startY = CGFloat(0.05 + rng.next() * 0.25) * size.height
        let dx: CGFloat = (rng.next() < 0.5 ? -1 : 1) * CGFloat(120 + rng.next() * 80)
        let dy: CGFloat = CGFloat(70 + rng.next() * 50)

        let head = CGPoint(x: startX + dx * t, y: startY + dy * t)
        let tail = CGPoint(x: head.x - dx * 0.22, y: head.y - dy * 0.22)

        // Bright at mid-flight, invisible at both ends.
        let flare = sin(t * .pi)
        let alpha = 0.55 * flare * intensity
        guard alpha > 0.02 else { return }

        var path = Path()
        path.move(to: tail)
        path.addLine(to: head)
        context.stroke(
            path,
            with: .linearGradient(
                Gradient(colors: [
                    KoumColor.bone.opacity(0),
                    KoumColor.firstlight.opacity(alpha),
                ]),
                startPoint: tail,
                endPoint: head
            ),
            style: StrokeStyle(lineWidth: 1.4, lineCap: .round)
        )
    }
}

/// Tiny deterministic generator so the sky is identical every launch.
private struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> Double {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return Double(state % 100_000) / 100_000
    }
}
