import SwiftUI

/// Type mode: the verse is visible; typing it — all of it — is the wake-up
/// mechanism, not a memory test. Words light up as they're typed and the
/// alarm ends only when the whole verse is down. Case and punctuation never
/// count against you; skipping words does.
struct TypeView: View {
    @Bindable var session: MorningSession
    @Bindable var verification: VerificationSession

    @State private var typed = ""
    @State private var coverage = VerseCoverage(matched: [])
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            KoumColor.night.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    MicroLabel(text: session.verse.display, color: KoumColor.firstlight)
                        .padding(.top, KoumSpacing.xl)
                        .padding(.bottom, KoumSpacing.md)

                    CoverageVerseText(
                        text: session.verseText,
                        matched: coverage.matched.isEmpty
                            ? VerseCoverage.evaluate(candidate: "", verseText: session.verseText).matched
                            : coverage.matched
                    )
                    .padding(.bottom, KoumSpacing.xl)

                    TextField(text: $typed, axis: .vertical) {
                        Text("Type it here")
                            .foregroundStyle(KoumColor.boneFaint)
                    }
                    .font(KoumType.body)
                    .foregroundStyle(KoumColor.bone)
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
                        Text("Every word, in order. Caps and commas don't count.")
                            .font(KoumType.caption)
                            .foregroundStyle(KoumColor.boneFaint)
                        Spacer()
                        CoverageProgressLabel(coverage: coverage)
                    }
                    .padding(.top, KoumSpacing.sm)

                    if verification.isDemo, verification.offersEscapeHatch {
                        Button("Skip for now") { verification.useEscapeHatch() }
                            .buttonStyle(.koumGhost)
                            .frame(maxWidth: .infinity)
                            .padding(.top, KoumSpacing.md)
                    }

                    Spacer(minLength: KoumSpacing.xl)
                }
                .padding(.horizontal, KoumSpacing.margin)
            }
            .scrollDismissesKeyboard(.never)
        }
        .onAppear {
            coverage = VerseCoverage.evaluate(candidate: "", verseText: session.verseText)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focused = true }
        }
    }

    /// The whole verse, word by word. Coverage never regresses, so a typo
    /// later in the line can't unlight what's already done.
    private func check(_ text: String) {
        guard case .working = verification.stage else { return }
        let result = VerseCoverage.evaluate(candidate: text, verseText: session.verseText)
        if result.matchedCount >= coverage.matchedCount {
            coverage = result
        } else {
            coverage = VerseCoverage(
                matched: zip(coverage.matched, result.matched).map { $0 || $1 })
        }
        if coverage.complete {
            focused = false
            verification.typePassed()
        }
    }
}
