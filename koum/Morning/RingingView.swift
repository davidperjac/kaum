import Combine
import SwiftData
import SwiftUI

/// The alarm screen. Dawn gradient, the time, the verse — the largest thing
/// on screen — and the three mode buttons. Operable with one thumb, one eye
/// open, in the dark.
struct RingingView: View {
    @Bindable var session: MorningSession
    @Environment(\.modelContext) private var modelContext

    @State private var now = Date()
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            AnimatedDawnBackground()

            // The last stars of the night, still up there with you.
            StarField(intensity: 0.55, verticalFraction: 0.5)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer(minLength: KoumSpacing.xl)

                VStack(spacing: KoumSpacing.xs) {
                    Text(clockString)
                        .font(KoumType.clock)
                        .foregroundStyle(KoumColor.bone)
                        .monospacedDigit()
                    if let meridiem {
                        MicroLabel(text: meridiem, color: KoumColor.boneFaint)
                    }
                }

                Spacer(minLength: KoumSpacing.xxl)

                VerseBlock(
                    reference: session.verse.display,
                    text: session.verseText,
                    hero: session.verseText.count <= 150,
                    referenceColor: KoumColor.firstlight
                )
                .padding(.horizontal, KoumSpacing.margin)

                Spacer(minLength: KoumSpacing.xl)

                VStack(spacing: KoumSpacing.sm) {
                    modeButton(.scan)
                    modeButton(.speak)
                    modeButton(.type)
                }
                .padding(.horizontal, KoumSpacing.margin)

                if session.canSnooze {
                    Button("Snooze \(KoumConfig.snoozeMinutes) min") {
                        session.snooze(context: modelContext)
                    }
                    .buttonStyle(.koumGhost)
                    .padding(.top, KoumSpacing.sm)
                } else if !session.isDemo {
                    Text("No more snoozes. Your Bible is the way out.")
                        .font(KoumType.caption)
                        .foregroundStyle(KoumColor.boneFaint)
                        .padding(.top, KoumSpacing.md)
                }

                Spacer(minLength: KoumSpacing.lg)
            }
        }
        .onAppear {
            session.startRinging()
            KoumHapticEngine.shared.startAlarmPulse()
        }
        .onDisappear { KoumHapticEngine.shared.stopAlarmPulse() }
        .onReceive(timer) { now = $0 }
    }

    private func modeButton(_ mode: VerifyMode) -> some View {
        Button {
            KoumHaptics.buttonPress()
            session.beginVerification(mode: mode)
        } label: {
            HStack(spacing: KoumSpacing.md) {
                GlyphView(glyph: mode.glyph, size: 22)
                    .frame(width: 28)
                Text(mode.title)
                    .font(KoumType.label)
                    .foregroundStyle(KoumColor.bone)
                Spacer()
                GlyphView(glyph: .chevronRight, size: 12, color: KoumColor.boneFaint)
            }
            .padding(.horizontal, KoumSpacing.md + KoumSpacing.xs)
            .frame(height: 56)
        }
        .buttonStyle(KoumRowButtonStyle())
        .accessibilityLabel("\(mode.title). \(mode.subtitle)")
    }

    private var clockString: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("jmm")
        // Strip the meridiem; it renders separately, quietly.
        formatter.dateFormat = formatter.dateFormat
            .replacingOccurrences(of: "a", with: "")
            .trimmingCharacters(in: .whitespaces)
        return formatter.string(from: now)
    }

    private var meridiem: String? {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("jmm")
        guard formatter.dateFormat.contains("a") else { return nil }
        formatter.dateFormat = "a"
        return formatter.string(from: now)
    }
}
