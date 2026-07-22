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
        VStack(alignment: .leading, spacing: KoumSpacing.sm) {
            HStack {
                Text(prayer.date.formatted(date: .abbreviated, time: .omitted))
                    .font(KoumType.micro)
                    .foregroundStyle(theme.textFaint)
                if let ref = prayer.verseRef {
                    Text("· \(ref.display)")
                        .font(KoumType.micro)
                        .foregroundStyle(theme.textFaint)
                }
                Spacer()
                if prayer.answered {
                    Label("Answered", systemImage: "checkmark")
                        .font(KoumType.micro)
                        .foregroundStyle(theme.success)
                }
            }

            Text(prayer.text)
                .font(KoumType.devotional)
                .koumLineSpacing(8)
                .foregroundStyle(theme.text)

            if prayer.answered, let date = prayer.answeredDate {
                Text("Answered \(date.formatted(date: .abbreviated, time: .omitted))")
                    .font(KoumType.caption)
                    .foregroundStyle(theme.success)
            } else {
                Button("Mark answered") {
                    KoumHaptics.selection()
                    prayer.answered = true
                    prayer.answeredDate = Date()
                    try? modelContext.save()
                }
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
