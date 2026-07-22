import SwiftData
import SwiftUI

/// Not a dashboard. One screen, three states: evening/setup, morning
/// incomplete (straight into the flow), morning complete. Then it gets out of
/// the way.
struct HomeView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Environment(\.koumTheme) private var theme

    @Query(sort: \AlarmModel.createdAt) private var alarms: [AlarmModel]
    @Query private var entries: [DailyEntry]

    @State private var showSettings = false
    @State private var showArchive = false
    @State private var showPrayerLog = false
    @State private var editingAlarm: AlarmModel?

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        if let entry = todayEntry, entry.verified {
                            completeState(entry)
                        } else if shouldOfferMorning {
                            incompleteState
                        } else {
                            eveningState
                        }
                    }
                    .padding(.horizontal, KoumSpacing.margin)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("Journal archive") { showArchive = true }
                        Button("Prayer log") { showPrayerLog = true }
                    } label: {
                        Image(systemName: "book.closed")
                            .foregroundStyle(theme.textMuted)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(theme.textMuted)
                    }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showArchive) { ArchiveView() }
            .sheet(isPresented: $showPrayerLog) { PrayerLogView() }
            .sheet(item: $editingAlarm) { alarm in
                AlarmEditView(alarm: alarm)
            }
        }
    }

    // MARK: - State resolution

    private var todayEntry: DailyEntry? {
        let today = Calendar.current.startOfDay(for: Date())
        return entries.first { $0.date == today }
    }

    /// True during the grace window after a missed/stopped alarm, or any time
    /// today's morning hasn't been done and an alarm already fired today.
    private var shouldOfferMorning: Bool {
        guard todayEntry?.verified != true else { return false }
        let cal = Calendar.current
        let now = Date()
        let weekday = cal.component(.weekday, from: now)
        for alarm in alarms where alarm.enabled {
            if !alarm.repeatDays.isEmpty && !alarm.repeatDays.contains(weekday) { continue }
            var comps = cal.dateComponents([.year, .month, .day], from: now)
            comps.hour = alarm.hour
            comps.minute = alarm.minute
            if let fire = cal.date(from: comps), fire <= now {
                return true
            }
        }
        return false
    }

    // MARK: - Evening / setup state

    private var eveningState: some View {
        VStack(spacing: 0) {
            Spacer(minLength: KoumSpacing.xl)

            if let next = app.nextAlarmDate(context: modelContext) {
                MicroLabel(text: nextAlarmLabel(next.date))
                    .padding(.bottom, KoumSpacing.xs)
                VStack(spacing: KoumSpacing.xs) {
                    Text(clockString(next.date))
                        .font(KoumType.clock)
                        .foregroundStyle(theme.text)
                        .monospacedDigit()
                    if let m = meridiemString(next.date) {
                        MicroLabel(text: m, color: theme.textFaint)
                    }
                }
                .padding(.bottom, KoumSpacing.xl)

                if let day = app.verseForDate(next.date, source: next.alarm.verseSource) {
                    VerseBlock(
                        reference: day.ref.display,
                        text: day.text,
                        referenceColor: theme.accent,
                        textColor: theme.text
                    )
                    .padding(.bottom, KoumSpacing.md)
                }

                HStack(spacing: KoumSpacing.md) {
                    Text(AlarmSound.named(next.alarm.soundName).displayName)
                    Text("·")
                    Text(next.alarm.mode.title)
                    Text("·")
                    Button("Change") { editingAlarm = next.alarm }
                        .foregroundStyle(theme.accent)
                }
                .font(KoumType.caption)
                .foregroundStyle(theme.textMuted)
                .padding(.bottom, KoumSpacing.xl)

                HStack(spacing: KoumSpacing.sm) {
                    GlyphView(glyph: .check, size: 14, color: theme.success)
                    Text("Alarm is set")
                }
                .font(KoumType.label)
                .foregroundStyle(theme.success)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(theme.edge, lineWidth: 1)
                    )
            } else {
                BreathingWren(imageName: "WrenSleeping", height: 80)
                    .padding(.bottom, KoumSpacing.lg)
                Text("No alarm set")
                    .font(KoumType.display)
                    .foregroundStyle(theme.text)
                    .padding(.bottom, KoumSpacing.md)
                Text("Tomorrow starts tonight.")
                    .font(KoumType.body)
                    .foregroundStyle(theme.textMuted)
                    .padding(.bottom, KoumSpacing.xl)

                Button("Set your alarm") {
                    let alarm = AlarmModel()
                    modelContext.insert(alarm)
                    try? modelContext.save()
                    editingAlarm = alarm
                }
                .buttonStyle(.koumPrimary)
            }

            Spacer(minLength: KoumSpacing.xl)
            streakFooter
        }
    }

    // MARK: - Morning incomplete

    private var incompleteState: some View {
        VStack(spacing: 0) {
            Spacer(minLength: KoumSpacing.xxl)
            Image("WrenWaiting")
                .resizable()
                .scaledToFit()
                .frame(height: 84)
                .accessibilityHidden(true)
                .padding(.bottom, KoumSpacing.lg)
            Text("Your verse is waiting")
                .font(KoumType.display)
                .foregroundStyle(theme.text)
                .padding(.bottom, KoumSpacing.sm)
            Text("Complete it within the grace window to keep your streak.")
                .font(KoumType.body)
                .foregroundStyle(theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.bottom, KoumSpacing.xl)

            Button("Open your Bible") {
                let alarm = currentDueAlarm
                app.beginMorning(alarm: alarm, context: modelContext)
            }
            .buttonStyle(.koumPrimary)

            Spacer(minLength: KoumSpacing.xl)
            streakFooter
        }
    }

    private var currentDueAlarm: AlarmModel? {
        let cal = Calendar.current
        let now = Date()
        let weekday = cal.component(.weekday, from: now)
        return alarms
            .filter { $0.enabled && ($0.repeatDays.isEmpty || $0.repeatDays.contains(weekday)) }
            .min { a, b in
                abs(minutesFromNow(a, cal: cal, now: now)) < abs(minutesFromNow(b, cal: cal, now: now))
            }
    }

    private func minutesFromNow(_ alarm: AlarmModel, cal: Calendar, now: Date) -> Int {
        var comps = cal.dateComponents([.year, .month, .day], from: now)
        comps.hour = alarm.hour
        comps.minute = alarm.minute
        guard let fire = cal.date(from: comps) else { return .max }
        return cal.dateComponents([.minute], from: fire, to: now).minute ?? .max
    }

    // MARK: - Morning complete

    private func completeState(_ entry: DailyEntry) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: KoumSpacing.xxl)

            HStack(spacing: KoumSpacing.md) {
                GlyphView(glyph: .check, size: 20, color: theme.success, lineWidth: 2)
                Text("Good morning")
            }
            .font(KoumType.display)
            .foregroundStyle(theme.text)
            .padding(.bottom, KoumSpacing.xl)

            VStack(alignment: .leading, spacing: KoumSpacing.sm) {
                Text("You read \(entry.verseRef.display)")
                if hasPrayerToday { Text("You prayed") }
                if entry.journalText?.isEmpty == false { Text("You wrote") }
            }
            .font(KoumType.body)
            .foregroundStyle(theme.textMuted)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, KoumSpacing.xl)

            streakFooter

            Spacer(minLength: KoumSpacing.xl)

            HStack(spacing: KoumSpacing.md) {
                Button("Read again") { showArchive = true }
                    .buttonStyle(.koumSecondary)
                Button("Journal") { showArchive = true }
                    .buttonStyle(.koumSecondary)
            }
        }
    }

    private var hasPrayerToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<PrayerEntry>(
            predicate: #Predicate { $0.date >= today })
        return ((try? modelContext.fetchCount(descriptor)) ?? 0) > 0
    }

    // MARK: - Streak footer

    private var streakFooter: some View {
        let streak = StreakService.effectiveStreak(in: modelContext)
        return VStack(spacing: KoumSpacing.sm) {
            Divider().overlay(theme.edge)
                .padding(.bottom, KoumSpacing.md)
            if streak.current > 0 {
                StreakBadge(count: streak.current, compact: true)
            } else if streak.broken {
                Text("Start again tomorrow")
                    .font(KoumType.caption)
                    .foregroundStyle(theme.textMuted)
            } else {
                Text("Tomorrow is morning one")
                    .font(KoumType.caption)
                    .foregroundStyle(theme.textMuted)
            }
            freezeNote
        }
        .padding(.bottom, KoumSpacing.lg)
    }

    @ViewBuilder
    private var freezeNote: some View {
        let state = StreakService.state(in: modelContext)
        if let used = state.freezeUsedDate,
           Calendar.current.isDate(used, inSameDayAs: Date()) {
            Text("Yesterday slipped by — your streak is safe this time.")
                .font(KoumType.micro)
                .foregroundStyle(theme.textFaint)
        }
    }

    private func clockString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("jmm")
        formatter.dateFormat = formatter.dateFormat
            .replacingOccurrences(of: "a", with: "")
            .trimmingCharacters(in: .whitespaces)
        return formatter.string(from: date)
    }

    private func meridiemString(_ date: Date) -> String? {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("jmm")
        guard formatter.dateFormat.contains("a") else { return nil }
        formatter.dateFormat = "a"
        return formatter.string(from: date)
    }

    private func nextAlarmLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInTomorrow(date) { return "Tomorrow" }
        return date.formatted(.dateTime.weekday(.wide))
    }
}


/// A Wren that breathes — a barely-perceptible 5-second swell, the only
/// living thing on an idle screen. Static under Reduced Motion.
struct BreathingWren: View {
    let imageName: String
    let height: CGFloat

    @State private var breath = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .scaleEffect(x: breath ? 1.012 : 1.0, y: breath ? 1.025 : 1.0, anchor: .bottom)
            .accessibilityHidden(true)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    breath = true
                }
            }
    }
}
