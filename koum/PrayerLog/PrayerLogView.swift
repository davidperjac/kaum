import SwiftData
import SwiftUI

/// The prayer log: chronological, notebook-styled. Entries can be marked
/// "Answered" with a date — quietly one of the most powerful retention
/// features in the app.
struct PrayerLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.koumTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \PrayerEntry.date, order: .reverse) private var prayers: [PrayerEntry]

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                if prayers.isEmpty {
                    VStack(spacing: KoumSpacing.md) {
                        Image("WrenWaiting")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 88)
                            .accessibilityHidden(true)
                        Text("Every prayer, kept")
                            .font(KoumType.title)
                            .foregroundStyle(theme.text)
                        Text("Prayers you write each morning gather here.")
                            .font(KoumType.caption)
                            .foregroundStyle(theme.textMuted)
                    }
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: KoumSpacing.md) {
                            ForEach(prayers) { prayer in
                                prayerCard(prayer)
                            }
                        }
                        .padding(.horizontal, KoumSpacing.margin)
                        .padding(.vertical, KoumSpacing.lg)
                    }
                }
            }
            .navigationTitle("Prayer log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func prayerCard(_ prayer: PrayerEntry) -> some View {
        PrayerCardView(
            text: prayer.text,
            date: prayer.date,
            verseRef: prayer.verseRef,
            answered: prayer.answered,
            answeredDate: prayer.answeredDate
        ) {
            KoumHaptics.selection()
            prayer.answered = true
            prayer.answeredDate = Date()
            try? modelContext.save()
        }
    }
}

/// One prayer, notebook-styled — the card the log is made of. Shared with the
/// onboarding demo so what new users are shown is exactly what they keep.
struct PrayerCardView: View {
    let text: String
    let date: Date
    var verseRef: VerseRef?
    var answered: Bool = false
    var answeredDate: Date?
    /// nil hides the action (read-only contexts like the demo preview).
    var onMarkAnswered: (() -> Void)?

    @Environment(\.koumTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: KoumSpacing.sm) {
            HStack {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(KoumType.micro)
                    .foregroundStyle(theme.textFaint)
                if let ref = verseRef {
                    Text("· \(ref.display)")
                        .font(KoumType.micro)
                        .foregroundStyle(theme.textFaint)
                }
                Spacer()
                if answered {
                    Label("Answered", systemImage: "checkmark")
                        .font(KoumType.micro)
                        .foregroundStyle(theme.success)
                }
            }

            Text(text)
                .font(KoumType.devotional)
                .koumLineSpacing(8)
                .foregroundStyle(theme.text)
                .fixedSize(horizontal: false, vertical: true)

            if answered, let answeredDate {
                Text("Answered \(answeredDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(KoumType.caption)
                    .foregroundStyle(theme.success)
            } else if let onMarkAnswered {
                Button("Mark answered", action: onMarkAnswered)
                    .buttonStyle(.koumGhost)
                    .padding(.leading, -16)
            }
        }
        .padding(KoumSpacing.md + KoumSpacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(theme.raised)
        )
    }
}
