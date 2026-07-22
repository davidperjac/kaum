import AVFoundation
import Foundation
import Observation
import Speech

/// Speak mode: on-device speech recognition, partial results, generous
/// threshold. The moment the accumulated transcript clears the bar, pass —
/// stopping the user mid-sentence feels responsive and slightly magical.
/// Fully on-device; no audio ever leaves the phone.
@Observable
@MainActor
final class SpeakVerifier {

    private(set) var transcript = ""
    private(set) var listening = false
    private(set) var permissionDenied = false
    private(set) var unavailable = false

    var onTranscript: ((String) -> Void)?

    private let audioEngine = AVAudioEngine()
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func start() async {
        let speechOK = await Self.requestSpeechAccess()
        let micOK = await Self.requestMicAccess()
        guard speechOK, micOK else {
            permissionDenied = true
            return
        }

        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
            ?? SFSpeechRecognizer()
        guard let recognizer, recognizer.isAvailable else {
            unavailable = true
            return
        }
        self.recognizer = recognizer

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        self.request = request

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            unavailable = true
            return
        }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0 else {
            unavailable = true
            return
        }
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            unavailable = true
            return
        }

        listening = true
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                    self.onTranscript?(self.transcript)
                }
                if error != nil {
                    self.stop()
                }
            }
        }
    }

    func stop() {
        guard listening || audioEngine.isRunning else { return }
        listening = false
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    static func requestSpeechAccess() async -> Bool {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized: return true
        case .notDetermined:
            return await withCheckedContinuation { cont in
                SFSpeechRecognizer.requestAuthorization { status in
                    cont.resume(returning: status == .authorized)
                }
            }
        default: return false
        }
    }

    static func requestMicAccess() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: return true
        case .undetermined:
            return await AVAudioApplication.requestRecordPermission()
        default: return false
        }
    }
}
