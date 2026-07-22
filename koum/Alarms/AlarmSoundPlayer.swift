import AVFoundation
import Foundation

/// Plays the alarm sound inside the app during the verification flow, so the
/// "silence on verify" moment belongs to Koum. Uses the `.playback` category:
/// audible regardless of the silent switch while the app is foreground.
@MainActor
final class AlarmSoundPlayer {

    static let shared = AlarmSoundPlayer()

    private var player: AVAudioPlayer?

    private init() {}

    /// Start looping the given sound. `volumeCap` keeps the in-hand demo
    /// below full alarm volume.
    func startRinging(sound: AlarmSound, volumeCap: Float = 1.0, ramp: Bool = true) {
        stop()
        guard let url = sound.fileURL else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = ramp ? 0.15 * volumeCap : volumeCap
            player.prepareToPlay()
            player.play()
            if ramp {
                player.setVolume(volumeCap, fadeDuration: 20)
            }
            self.player = player
        } catch {
            // Sound failure must never block the flow.
        }
    }

    /// Cut instantly — silence lands before any visual.
    func stop() {
        player?.stop()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Preview a sound briefly (settings / alarm editor).
    func preview(sound: AlarmSound) {
        stop()
        guard let url = sound.fileURL else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = 0
            player.volume = 0.7
            player.currentTime = 8 // skip the quiet ramp-in
            player.play()
            self.player = player
        } catch {}
    }

    var isPlaying: Bool { player?.isPlaying ?? false }
}
