import CoreHaptics
import Foundation

/// Authored haptic choreography for the two moments that carry the product:
/// the alarm's pulse and the verification bloom. Everything else stays with
/// the simple UIKit generators in `KoumHaptics`.
///
/// The grammar: soft, low-intensity, sparse — a hand on the shoulder, never
/// a buzz. Falls back silently on devices without CoreHaptics.
@MainActor
final class KoumHapticEngine {

    static let shared = KoumHapticEngine()

    private var engine: CHHapticEngine?
    private var pulsePlayer: CHHapticAdvancedPatternPlayer?

    private init() {}

    private func preparedEngine() -> CHHapticEngine? {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return nil }
        if let engine { return engine }
        do {
            let fresh = try CHHapticEngine()
            fresh.resetHandler = { [weak self] in
                Task { @MainActor [weak self] in
                    self?.engine = nil
                    self?.pulsePlayer = nil
                }
            }
            try fresh.start()
            engine = fresh
            return fresh
        } catch {
            return nil
        }
    }

    // MARK: - Alarm pulse

    /// The ringing heartbeat: a soft double-tap (lub-dub) every 1.6s, felt
    /// with the sound. Runs until stopped.
    func startAlarmPulse() {
        guard let engine = preparedEngine() else { return }
        stopAlarmPulse()
        do {
            let lub = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.55),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25),
                ],
                relativeTime: 0
            )
            let dub = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.35),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2),
                ],
                relativeTime: 0.22
            )
            let pattern = try CHHapticPattern(events: [lub, dub], parameters: [])
            let player = try engine.makeAdvancedPlayer(with: pattern)
            player.loopEnabled = true
            player.loopEnd = 1.6
            try player.start(atTime: CHHapticTimeImmediate)
            pulsePlayer = player
        } catch {
            pulsePlayer = nil
        }
    }

    func stopAlarmPulse() {
        try? pulsePlayer?.stop(atTime: CHHapticTimeImmediate)
        pulsePlayer = nil
    }

    // MARK: - Verification bloom

    /// One composed swell, timed with the glow: a slow continuous rise and
    /// fall (1.1s) with a single soft settle tap where the checkmark lands.
    func playBloomSwell() {
        guard let engine = preparedEngine() else {
            KoumHaptics.verificationPassed()
            return
        }
        do {
            let swell = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1),
                ],
                relativeTime: 0,
                duration: 1.1
            )
            let rise = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    .init(relativeTime: 0, value: 0.0),
                    .init(relativeTime: 0.45, value: 1.0),
                    .init(relativeTime: 1.1, value: 0.0),
                ],
                relativeTime: 0
            )
            let settle = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3),
                ],
                relativeTime: 1.15
            )
            let pattern = try CHHapticPattern(events: [swell, settle], parameterCurves: [rise])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            KoumHaptics.verificationPassed()
        }
    }
}
