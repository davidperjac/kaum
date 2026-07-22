import AVFoundation
import Foundation
import Observation
@preconcurrency import Vision

/// Continuous camera capture + on-device Vision OCR.
///
/// No shutter button: recognition runs on the live stream (~4 fps) and passes
/// the moment a frame — or the union of the last ~3 seconds of frames —
/// matches. Torch auto-enables in low light, silently. Frames are used for
/// OCR and discarded; never stored, never uploaded.
///
/// `ScanVerifier` is the main-actor face for SwiftUI; `CaptureEngine` owns the
/// AVCaptureSession and all capture-path state, confined to its own queues.
@Observable
@MainActor
final class ScanVerifier {

    var onRecognizedText: ((String) -> Void)?
    private(set) var isRunning = false
    private(set) var permissionDenied = false

    private let engine = CaptureEngine()

    var captureSession: AVCaptureSession { engine.session }

    func start() async {
        let granted = await Self.requestCameraAccess()
        guard granted else {
            permissionDenied = true
            return
        }
        engine.onText = { [weak self] text in
            Task { @MainActor [weak self] in
                self?.onRecognizedText?(text)
            }
        }
        engine.start()
        isRunning = true
    }

    func stop() {
        isRunning = false
        engine.stop()
    }

    static func requestCameraAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video)
        default: return false
        }
    }
}

/// Camera + Vision pipeline. Everything here runs on `videoQueue` /
/// `visionQueue`; nothing touches the main actor.
nonisolated final class CaptureEngine: NSObject, @unchecked Sendable {

    let session = AVCaptureSession()

    /// Called with the accumulated recent-frame text on every recognition.
    var onText: ((String) -> Void)?

    private let videoQueue = DispatchQueue(label: "koum.scan.video")
    private let visionQueue = DispatchQueue(label: "koum.scan.vision")

    private var device: AVCaptureDevice?
    private var lastProcessed = Date.distantPast
    private var processing = false

    /// Rolling buffer of recognized frame texts (last ~3s at 4 fps ≈ 12).
    private var recentFrames: [(date: Date, text: String)] = []
    private let framesLock = NSLock()

    private var torchOn = false
    private var lowLightSamples = 0

    func start() {
        videoQueue.async { [weak self] in
            self?.configureAndRun()
        }
    }

    func stop() {
        videoQueue.async { [weak self] in
            guard let self else { return }
            self.setTorch(false)
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    private func configureAndRun() {
        guard session.inputs.isEmpty else {
            if !session.isRunning { session.startRunning() }
            return
        }
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }
        device = camera
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.setSampleBufferDelegate(self, queue: videoQueue)
        if session.canAddOutput(output) { session.addOutput(output) }

        // Continuous autofocus, close range — it's a book in someone's hands
        try? camera.lockForConfiguration()
        if camera.isFocusModeSupported(.continuousAutoFocus) {
            camera.focusMode = .continuousAutoFocus
        }
        if camera.isAutoFocusRangeRestrictionSupported {
            camera.autoFocusRangeRestriction = .near
        }
        camera.unlockForConfiguration()

        session.commitConfiguration()
        session.startRunning()
    }

    private func setTorch(_ on: Bool) {
        guard let device, device.hasTorch, device.isTorchAvailable || !on else { return }
        try? device.lockForConfiguration()
        if on, device.isTorchAvailable {
            try? device.setTorchModeOn(level: 0.6)
        } else {
            device.torchMode = .off
        }
        device.unlockForConfiguration()
        torchOn = on
    }

    /// The union of recent frame text — a verse split across frames still
    /// matches while the user pans the page.
    private func accumulatedText(adding text: String) -> String {
        framesLock.lock()
        defer { framesLock.unlock() }
        let now = Date()
        recentFrames.append((now, text))
        recentFrames.removeAll { now.timeIntervalSince($0.date) > 3.0 }
        return recentFrames.map(\.text).joined(separator: "\n")
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CaptureEngine: nonisolated AVCaptureVideoDataOutputSampleBufferDelegate {

    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Throttle to ~4 fps and one in-flight request
        let now = Date()
        guard now.timeIntervalSince(lastProcessed) >= 0.25, !processing else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastProcessed = now
        processing = true

        // Low-light heuristic from EXIF brightness; auto-torch after sustained dark
        if !torchOn,
           let attachments = CMCopyDictionaryOfAttachments(
               allocator: nil, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate
           ) as? [String: Any],
           let exif = attachments[kCGImagePropertyExifDictionary as String] as? [String: Any],
           let brightness = exif[kCGImagePropertyExifBrightnessValue as String] as? Double {
            if brightness < -1.0 {
                lowLightSamples += 1
                if lowLightSamples >= 6 { setTorch(true) }
            } else {
                lowLightSamples = 0
            }
        }

        let request = VNRecognizeTextRequest { [weak self] request, _ in
            guard let self else { return }
            defer { self.processing = false }
            guard let observations = request.results as? [VNRecognizedTextObservation],
                  !observations.isEmpty else { return }
            let text = observations
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")
            guard !text.isEmpty else { return }
            self.onText?(self.accumulatedText(adding: text))
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US"]
        request.minimumTextHeight = 0.008 // small Bible type

        nonisolated(unsafe) let buffer = pixelBuffer
        nonisolated(unsafe) let ocrRequest = request
        visionQueue.async { [weak self] in
            let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .right)
            do {
                try handler.perform([ocrRequest])
            } catch {
                self?.processing = false
            }
        }
    }
}
