import SwiftUI

/// One prompt, one open field. No chrome — a cursor on the night, like
/// writing. This is the user's place to leave everything: how they feel,
/// what they're grateful for, what the day holds. One word is a complete
/// entry; so is a page. Skippable.
struct JournalView: View {
    @Bindable var session: MorningSession

    @State private var text = ""
    @FocusState private var focused: Bool

    private var prompt: String {
        JournalPrompts.prompt(for: session.verse)
    }

    var body: some View {
        ZStack {
            KoumColor.night.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                MicroLabel(text: "Journal", color: KoumColor.firstlight)
                    .padding(.top, KoumSpacing.xxl)
                    .padding(.bottom, KoumSpacing.md)

                Text(prompt)
                    .font(KoumType.title)
                    .koumLineSpacing(6)
                    .foregroundStyle(KoumColor.boneMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, KoumSpacing.xl)

                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("Say anything. How you feel, what you're grateful for, what today needs. It all belongs here.")
                            .font(KoumType.devotional)
                            .koumLineSpacing(8)
                            .foregroundStyle(KoumColor.boneFaint)
                            .allowsHitTesting(false)
                    }
                    TextField("", text: $text, axis: .vertical)
                        .font(KoumType.devotional)
                        .foregroundStyle(KoumColor.bone)
                        .tint(KoumColor.firstlight)
                        .focused($focused)
                        .lineLimit(3...12)
                }

                Spacer()

                Button("Done") {
                    KoumHaptics.buttonPress()
                    session.saveJournal(text, prompt: prompt)
                }
                .buttonStyle(.koumPrimary)

                Button("Skip") {
                    session.skipJournal()
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

enum JournalPrompts {
    static let all = [
        "What stood out to you?",
        "Where do you need this today?",
        "What is God saying to you?",
        "How are you, honestly?",
        "What are you grateful for this morning?",
    ]

    static func prompt(for verse: VerseRef) -> String {
        let idx = abs(verse.key.hashValue / 3) % all.count
        return all[idx]
    }
}
