import SwiftUI

/// The demo's two "kept" beats: right after the user prays, their prayer
/// comes back in the real prayer-log card; after the journal, their whole
/// morning comes back as a page. Both use the exact components the daily app
/// uses — the promise is shown with the real thing, not a mockup.

// MARK: - Their prayer, in the log

struct PrayerKeptView: View {
    @Bindable var session: MorningSession

    @State private var revealed = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            KoumColor.night.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                MicroLabel(text: "Your prayer log", color: KoumColor.firstlight)
                    .padding(.top, KoumSpacing.xxl)
                    .padding(.bottom, KoumSpacing.md)
                    .opacity(revealed >= 1 ? 1 : 0)

                Text("Kept. Every one of them.")
                    .font(KoumType.display)
                    .koumLineSpacing(7)
                    .foregroundStyle(KoumColor.bone)
                    .opacity(revealed >= 1 ? 1 : 0)
                    .offset(y: revealed >= 1 ? 0 : 6)
                    .padding(.bottom, KoumSpacing.xl)

                // The real card from the real log, holding their real prayer.
                PrayerCardView(
                    text: session.lastPrayerText,
                    date: Date(),
                    verseRef: session.verse
                )
                .opacity(revealed >= 2 ? 1 : 0)
                .offset(y: revealed >= 2 ? 0 : 8)
                .padding(.bottom, KoumSpacing.xl)

                Text("Every morning's prayer lands here, in your own words. And when God answers, you mark it. Watching that list fill up is the part nobody warns you about.")
                    .font(KoumType.body)
                    .koumLineSpacing(6)
                    .foregroundStyle(KoumColor.boneMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(revealed >= 3 ? 1 : 0)

                Spacer()

                Button("Continue") {
                    KoumHaptics.buttonPress()
                    session.advanceFromPrayerKept()
                }
                .buttonStyle(.koumPrimary)
                .opacity(revealed >= 3 ? 1 : 0)
                .padding(.bottom, KoumSpacing.lg)
            }
            .padding(.horizontal, KoumSpacing.margin)
        }
        .environment(\.koumTheme, KoumTheme(isDark: true))
        .onAppear { reveal() }
    }

    private func reveal() {
        if reduceMotion { revealed = 3; return }
        withAnimation(KoumMotion.breathEase) { revealed = 1 }
        withAnimation(KoumMotion.breathEase.delay(0.5)) { revealed = 2 }
        withAnimation(KoumMotion.breathEase.delay(1.0)) { revealed = 3 }
    }
}

// MARK: - Day 1, on the page

struct DayKeptView: View {
    @Bindable var session: MorningSession

    @State private var revealed = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            KoumColor.night.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                MicroLabel(text: "Your journal", color: KoumColor.firstlight)
                    .padding(.top, KoumSpacing.xxl)
                    .padding(.bottom, KoumSpacing.md)
                    .opacity(revealed >= 1 ? 1 : 0)

                Text("Day 1, on the page.")
                    .font(KoumType.display)
                    .koumLineSpacing(7)
                    .foregroundStyle(KoumColor.bone)
                    .opacity(revealed >= 1 ? 1 : 0)
                    .offset(y: revealed >= 1 ? 0 : 6)
                    .padding(.bottom, KoumSpacing.xl)

                dayCard
                    .opacity(revealed >= 2 ? 1 : 0)
                    .offset(y: revealed >= 2 ? 0 : 8)
                    .padding(.bottom, KoumSpacing.xl)

                Text("Every morning becomes a page like this: the verse, your prayer, your words. Come back in a month, or a year, and read what God was doing.")
                    .font(KoumType.body)
                    .koumLineSpacing(6)
                    .foregroundStyle(KoumColor.boneMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(revealed >= 3 ? 1 : 0)

                Spacer()

                Button("Continue") {
                    KoumHaptics.buttonPress()
                    session.advanceFromJournalKept()
                }
                .buttonStyle(.koumPrimary)
                .opacity(revealed >= 3 ? 1 : 0)
                .padding(.bottom, KoumSpacing.lg)
            }
            .padding(.horizontal, KoumSpacing.margin)
        }
        .environment(\.koumTheme, KoumTheme(isDark: true))
        .onAppear { reveal() }
    }

    /// The day's entry, exactly as the archive keeps it.
    private var dayCard: some View {
        VStack(alignment: .leading, spacing: KoumSpacing.sm) {
            HStack {
                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(KoumType.micro)
                    .foregroundStyle(KoumColor.boneFaint)
                Text("· \(session.verse.display)")
                    .font(KoumType.micro)
                    .foregroundStyle(KoumColor.boneFaint)
                Spacer()
                Label("Verified", systemImage: "checkmark")
                    .font(KoumType.micro)
                    .foregroundStyle(KoumColor.verified)
            }

            if !session.lastJournalText.isEmpty {
                Text(session.lastJournalText)
                    .font(KoumType.devotional)
                    .koumLineSpacing(8)
                    .foregroundStyle(KoumColor.bone)
                    .fixedSize(horizontal: false, vertical: true)
            } else if !session.lastPrayerText.isEmpty {
                Text(session.lastPrayerText)
                    .font(KoumType.devotional)
                    .koumLineSpacing(8)
                    .foregroundStyle(KoumColor.bone)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: KoumSpacing.sm) {
                FlameGlyph()
                    .stroke(KoumColor.firstlight,
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                    .frame(width: 14, height: 18)
                Text("Morning 1, kept")
                    .font(KoumType.caption)
                    .foregroundStyle(KoumColor.boneMuted)
            }
            .padding(.top, KoumSpacing.xs)
        }
        .padding(KoumSpacing.md + KoumSpacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(KoumColor.nightRaised)
        )
    }

    private func reveal() {
        if reduceMotion { revealed = 3; return }
        withAnimation(KoumMotion.breathEase) { revealed = 1 }
        withAnimation(KoumMotion.breathEase.delay(0.5)) { revealed = 2 }
        withAnimation(KoumMotion.breathEase.delay(1.0)) { revealed = 3 }
    }
}
