import SwiftData
import SwiftUI

/// Journal archive: calendar of completed days, day detail, search,
/// "on this day" from a year ago.
struct ArchiveView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.koumTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \DailyEntry.date, order: .reverse) private var entries: [DailyEntry]
    @State private var displayedMonth = Date()
    @State private var selectedEntry: DailyEntry?
    @State private var searchText = ""

    private var completedDays: Set<Date> {
        Set(entries.filter(\.verified).map { Calendar.current.startOfDay(for: $0.date) })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: KoumSpacing.lg) {
                        if searchText.isEmpty {
                            onThisDay
                            calendar
                            recentList
                        } else {
                            searchResults
                        }
                    }
                    .padding(.horizontal, KoumSpacing.margin)
                    .padding(.bottom, KoumSpacing.xl)
                }
            }
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search entries")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(item: $selectedEntry) { entry in
                DayDetailView(entry: entry)
            }
        }
    }

    // MARK: - On this day

    @ViewBuilder
    private var onThisDay: some View {
        let cal = Calendar.current
        if let lastYear = cal.date(byAdding: .year, value: -1, to: Date()),
           let entry = entries.first(where: { cal.isDate($0.date, inSameDayAs: lastYear) }),
           entry.verified {
            VStack(alignment: .leading, spacing: KoumSpacing.sm) {
                MicroLabel(text: "On this day last year", color: theme.accent)
                Button {
                    selectedEntry = entry
                } label: {
                    VStack(alignment: .leading, spacing: KoumSpacing.xs) {
                        Text(entry.verseRef.display)
                            .font(KoumType.label)
                            .foregroundStyle(theme.text)
                        if let journal = entry.journalText, !journal.isEmpty {
                            Text(journal)
                                .font(KoumType.caption)
                                .foregroundStyle(theme.textMuted)
                                .lineLimit(2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(KoumSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(theme.raised)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Calendar

    private var calendar: some View {
        VStack(spacing: KoumSpacing.md) {
            HStack {
                Button {
                    displayedMonth = Calendar.current.date(
                        byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.left").foregroundStyle(theme.textMuted)
                }
                Spacer()
                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(KoumType.label)
                    .foregroundStyle(theme.text)
                Spacer()
                Button {
                    displayedMonth = Calendar.current.date(
                        byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.right").foregroundStyle(theme.textMuted)
                }
            }

            let columns = Array(repeating: GridItem(.flexible()), count: 7)
            LazyVGrid(columns: columns, spacing: KoumSpacing.sm) {
                let symbols = Calendar.current.veryShortWeekdaySymbols
                ForEach(symbols.indices, id: \.self) { idx in
                    Text(symbols[idx])
                        .font(KoumType.micro)
                        .foregroundStyle(theme.textFaint)
                }
                ForEach(monthDays.indices, id: \.self) { idx in
                    if let day = monthDays[idx] {
                        dayCell(day)
                    } else {
                        Color.clear.frame(height: 34)
                    }
                }
            }
        }
        .padding(KoumSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(theme.raised)
        )
    }

    private var monthDays: [Date?] {
        let cal = Calendar.current
        guard let interval = cal.dateInterval(of: .month, for: displayedMonth) else { return [] }
        let firstWeekday = cal.component(.weekday, from: interval.start)
        let leading = (firstWeekday - cal.firstWeekday + 7) % 7
        let dayCount = cal.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
        var days: [Date?] = Array(repeating: nil, count: leading)
        for d in 0..<dayCount {
            days.append(cal.date(byAdding: .day, value: d, to: interval.start))
        }
        return days
    }

    private func dayCell(_ day: Date) -> some View {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        let completed = completedDays.contains(start)
        let isToday = cal.isDateInToday(day)
        let entry = entries.first { cal.isDate($0.date, inSameDayAs: day) }

        return Button {
            if let entry { selectedEntry = entry }
        } label: {
            Text("\(cal.component(.day, from: day))")
                .font(KoumType.caption)
                .foregroundStyle(completed ? KoumColor.night : theme.textMuted)
                .frame(width: 34, height: 34)
                .background(
                    Circle().fill(completed ? theme.accent : .clear)
                )
                .overlay(
                    Circle().stroke(isToday ? theme.accent : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(entry == nil)
    }

    // MARK: - Lists

    private var recentList: some View {
        VStack(alignment: .leading, spacing: KoumSpacing.sm) {
            let recent = entries.filter(\.verified).prefix(14)
            if recent.isEmpty {
                VStack(spacing: KoumSpacing.md) {
                    Image("WrenPerched")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 88)
                        .accessibilityHidden(true)
                    Text("Nothing here yet")
                        .font(KoumType.body)
                        .foregroundStyle(theme.textMuted)
                    Text("Your mornings will gather here.")
                        .font(KoumType.caption)
                        .foregroundStyle(theme.textFaint)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, KoumSpacing.xl)
            } else {
                ForEach(recent) { entry in
                    entryRow(entry)
                }
            }
        }
    }

    private var searchResults: some View {
        let query = searchText.lowercased()
        let matches = entries.filter {
            $0.journalText?.lowercased().contains(query) == true
                || $0.verseRef.display.lowercased().contains(query)
        }
        return VStack(alignment: .leading, spacing: KoumSpacing.sm) {
            if matches.isEmpty {
                Text("No entries match")
                    .font(KoumType.body)
                    .foregroundStyle(theme.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KoumSpacing.xl)
            } else {
                ForEach(matches) { entry in
                    entryRow(entry)
                }
            }
        }
    }

    private func entryRow(_ entry: DailyEntry) -> some View {
        Button {
            selectedEntry = entry
        } label: {
            VStack(alignment: .leading, spacing: KoumSpacing.xs) {
                HStack {
                    Text(entry.verseRef.display)
                        .font(KoumType.label)
                        .foregroundStyle(theme.text)
                    Spacer()
                    Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                        .font(KoumType.micro)
                        .foregroundStyle(theme.textFaint)
                }
                if let journal = entry.journalText, !journal.isEmpty {
                    Text(journal)
                        .font(KoumType.caption)
                        .foregroundStyle(theme.textMuted)
                        .lineLimit(2)
                }
            }
            .padding(KoumSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(theme.raised)
            )
        }
        .buttonStyle(.plain)
    }
}

/// One day: verse, prayer, journal together.
struct DayDetailView: View {
    let entry: DailyEntry

    @Environment(\.modelContext) private var modelContext
    @Environment(\.koumTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: KoumSpacing.xl) {
                        VerseBlock(
                            reference: entry.verseRef.display,
                            text: BibleStore.shared.displayText(for: entry.verseRef, preferred: .kjv),
                            referenceColor: theme.accent,
                            textColor: theme.text
                        )

                        if let prayer = prayerForDay {
                            VStack(alignment: .leading, spacing: KoumSpacing.sm) {
                                MicroLabel(text: "Prayer", color: theme.textMuted)
                                Text(prayer.text)
                                    .font(KoumType.devotional)
                                    .koumLineSpacing(8)
                                    .foregroundStyle(theme.text)
                            }
                        }

                        if let journal = entry.journalText, !journal.isEmpty {
                            VStack(alignment: .leading, spacing: KoumSpacing.sm) {
                                MicroLabel(text: entry.journalPrompt ?? "Journal", color: theme.textMuted)
                                Text(journal)
                                    .font(KoumType.devotional)
                                    .koumLineSpacing(8)
                                    .foregroundStyle(theme.text)
                            }
                        }
                    }
                    .padding(.horizontal, KoumSpacing.margin)
                    .padding(.vertical, KoumSpacing.lg)
                }
            }
            .navigationTitle(entry.date.formatted(date: .long, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var prayerForDay: PrayerEntry? {
        let cal = Calendar.current
        let descriptor = FetchDescriptor<PrayerEntry>()
        let all = (try? modelContext.fetch(descriptor)) ?? []
        return all.first { cal.isDate($0.date, inSameDayAs: entry.date) }
    }
}
