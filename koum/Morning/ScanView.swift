import Combine
import AVFoundation
import SwiftUI

/// Scan mode: camera fills the screen, the target verse reference overlaid,
/// a frame guide and one line of guidance. Continuous recognition — the alarm
/// just stops when a frame matches.
struct ScanView: View {
    @Bindable var session: MorningSession
    @Bindable var verification: VerificationSession

    @State private var scanner = ScanVerifier()
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            CameraPreview(session: scanner.captureSession)
                .ignoresSafeArea()

            // Dim vignette so overlays stay legible
            LinearGradient(
                colors: [KoumColor.night.opacity(0.75), .clear, .clear, KoumColor.night.opacity(0.85)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: KoumSpacing.sm) {
                    MicroLabel(text: session.verse.display, color: KoumColor.firstlight)
                    Text("Find it in your Bible")
                        .font(KoumType.body)
                        .foregroundStyle(KoumColor.boneMuted)
                }
                .padding(.top, KoumSpacing.md)

                Spacer()

                // Frame guide
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(KoumColor.bone.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [8, 8]))
                    .aspectRatio(0.75, contentMode: .fit)
                    .padding(.horizontal, KoumSpacing.xl)

                Spacer()

                VStack(spacing: KoumSpacing.md) {
                    Text(verification.guidance)
                        .font(KoumType.body)
                        .foregroundStyle(KoumColor.bone)
                        .multilineTextAlignment(.center)
                        .animation(KoumMotion.quickEase, value: verification.guidance)

                    if scanner.permissionDenied {
                        Text("Camera access is off. Type it instead, or allow the camera in Settings.")
                            .font(KoumType.caption)
                            .foregroundStyle(KoumColor.boneMuted)
                            .multilineTextAlignment(.center)
                    }

                    if verification.offersTypeSwitch || scanner.permissionDenied {
                        Button("Type it instead") { session.switchToType() }
                            .buttonStyle(.koumSecondary)
                    }

                    if verification.offersEscapeHatch {
                        Button(verification.isDemo ? "Skip for now" : "I'll take your word for it") {
                            verification.useEscapeHatch()
                        }
                        .buttonStyle(.koumGhost)
                    }
                    Text("The page is read on your phone and never uploaded.")
                        .font(KoumType.micro)
                        .foregroundStyle(KoumColor.boneFaint)
                }
                .padding(.horizontal, KoumSpacing.margin)
                .padding(.bottom, KoumSpacing.md)
            }
        }
        .task {
            scanner.onRecognizedText = { text in
                verification.evaluate(text: text)
            }
            await scanner.start()
        }
        .onReceive(tick) { _ in verification.tick() }
        .onDisappear { scanner.stop() }
    }
}

/// AVCaptureSession preview layer wrapper.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
