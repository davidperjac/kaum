import SwiftUI

/// Type mode: the verse is visible; typing it is the wake-up mechanism, not a
/// memory test. Live feedback, auto-pass at threshold, no submit button.
/// This is the guaranteed fallback — it must never fail for any reason.
struct TypeView: View {
    @Bindable var session: MorningSession
    @Bindable var verification: VerificationSession

    @State private var typed = ""
    @FocusState private var focused: Bool

    /// Long verses truncate to a reasonable typing length.
    private var targetText: String {
        let text = session.verseText
        guard text.count > 120 else { return text }
        let cut = text.prefix(120)
        // Break at the last word boundary
        if let lastSpace = cut.lastIndex(of: " ") {
            return String(cut[..<lastSpace]) + "…"
        }
        return String(cut) + "…"
    }

    private var typingTarget: String {
        targetText.hasSuffix("…") ? String(targetText.dropLast()) : targetText
    }

    private var progress: Double {
        TextNormalizer.prefixSimilarity(typed: typed, target: typingTarget)
    }

    private var lengthRatio: Double {
        let target = Double(typingTarget.filter { $0.isLetter || $0.isNumber }.count)
        guard target > 0 else { return 1 }
        return Double(typed.filter { $0.isLetter || $0.isNumber }.count) / target
    }

    var body: some View {
        ZStack {
            KoumColor.night.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: KoumSpacing.lg)

                MicroLabel(text: session.verse.display, color: KoumColor.firstlight)
                    .padding(.bottom, KoumSpacing.md)

                Text(targetText)
                    .font(KoumType.verse)
                    .koumLineSpacing(10)
                    .foregroundStyle(KoumColor.bone)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, KoumSpacing.xl)

                TextField("Type it here", text: $typed, axis: .vertical)
                    .font(KoumType.body)
                    .foregroundStyle(matchColor)
                    .tint(KoumColor.firstlight)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.asciiCapable)
                    .focused($focused)
                    .padding(KoumSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(KoumColor.nightEdge)
                    )
                    .frame(minHeight: 52)
                    .onChange(of: typed) { _, newValue in
                        check(newValue)
                    }

                HStack {
                    Text("Close is close enough")
                        .font(KoumType.caption)
                        .foregroundStyle(KoumColor.boneFaint)
                    Spacer()
                    if lengthRatio > 0.1 {
                        Text("\(Int(min(lengthRatio, 1.0) * 100))%")
                            .font(KoumType.caption)
                            .foregroundStyle(progress > 0.75 ? KoumColor.verified : KoumColor.boneMuted)
                            .monospacedDigit()
                    }
                }
                .padding(.top, KoumSpacing.sm)

                Spacer()
            }
            .padding(.horizontal, KoumSpacing.margin)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focused = true }
        }
    }

    private var matchColor: Color {
        if typed.isEmpty { return KoumColor.bone }
        return progress >= 0.75 ? KoumColor.verified : KoumColor.bone
    }

    /// Pass when the typed text is long enough and similar enough.
    /// Threshold 0.75 character similarity, case/punctuation ignored.
    private func check(_ text: String) {
        guard case .working = verification.stage else { return }
        let similarity = TextNormalizer.characterSimilarity(text, typingTarget)
        if similarity >= 0.75 {
            focused = false
            verification.typePassed()
        }
    }
}
