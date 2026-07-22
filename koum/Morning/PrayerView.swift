import SwiftUI

/// Prayer, after verification. Always skippable, never guilted. Written
/// prayer in v1; the prompt is drawn from the day's verse.
struct PrayerView: View {
    @Bindable var session: MorningSession

    @State private var text = ""
    @FocusState private var focused: Bool

    private var prompt: String {
        PrayerPrompts.prompt(for: session.verse)
    }

    var body: some View {
        ZStack {
            KoumColor.night.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                MicroLabel(text: "Pray", color: KoumColor.firstlight)
                    .padding(.top, KoumSpacing.xxl)
                    .padding(.bottom, KoumSpacing.md)

                Text(prompt)
                    .font(KoumType.title)
                    .koumLineSpacing(6)
                    .foregroundStyle(KoumColor.bone)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, KoumSpacing.xl)

                // Journal-style input: no visible field, just a cursor and a
                // quiet placeholder where writing begins.
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("Write it, or just pray it. Both count.")
                            .font(KoumType.devotional)
                            .foregroundStyle(KoumColor.boneFaint)
                            .allowsHitTesting(false)
                    }
                    TextField("", text: $text, axis: .vertical)
                        .font(KoumType.devotional)
                        .foregroundStyle(KoumColor.bone)
                        .tint(KoumColor.firstlight)
                        .focused($focused)
                        .lineLimit(4...10)
                }

                Spacer()

                Text("Your prayers stay on your phone.")
                    .font(KoumType.micro)
                    .foregroundStyle(KoumColor.boneFaint)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, KoumSpacing.sm)

                Button("Amen") {
                    KoumHaptics.buttonPress()
                    session.savePrayer(text)
                }
                .buttonStyle(.koumPrimary)

                Button("Skip for now") {
                    session.skipPrayer()
                }
                .buttonStyle(.koumGhost)
                .frame(maxWidth: .infinity)
                .padding(.bottom, KoumSpacing.sm)
            }
            .padding(.horizontal, KoumSpacing.margin)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { focused = true }
        }
    }
}

enum PrayerPrompts {
    static let all = [
        "Thank God for one thing before you get up.",
        "What do you need from Him today? Ask plainly.",
        "Who needs your prayer this morning? Name them.",
        "Tell Him what you're carrying into today.",
        "One sentence of thanks. One sentence of asking.",
    ]

    /// Deterministic per-verse prompt so a morning's prompt is stable.
    static func prompt(for verse: VerseRef) -> String {
        let idx = abs(verse.key.hashValue) % all.count
        return all[idx]
    }
}
