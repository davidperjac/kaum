import SwiftData
import SwiftUI

/// Alarm editor: time, days, mode, verse source, sound. One screen.
struct AlarmEditView: View {
    @Bindable var alarm: AlarmModel

    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.koumTheme) private var theme

    @State private var time = Date()
    @State private var previewingSound: String?

    private let daySymbols = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: KoumSpacing.xl) {

                        // Time
                        DatePicker(
                            "Time", selection: $time, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .onChange(of: time) { _, newValue in
                                let comps = Calendar.current.dateComponents(
                                    [.hour, .minute], from: newValue)
                                alarm.hour = comps.hour ?? 6
                                alarm.minute = comps.minute ?? 30
                            }

                        // Days
                        section("Which mornings") {
                            HStack(spacing: KoumSpacing.sm) {
                                ForEach(1...7, id: \.self) { day in
                                    dayToggle(day)
                                }
                            }
                            Text("Every day is easier than most days.")
                                .font(KoumType.caption)
                                .foregroundStyle(theme.textFaint)
                        }

                        // Mode
                        section("How you'll turn it off") {
                            ForEach(VerifyMode.allCases, id: \.self) { mode in
                                choiceRow(
                                    title: mode.title,
                                    subtitle: mode.subtitle,
                                    symbol: mode.symbolName,
                                    selected: alarm.mode == mode
                                ) { alarm.mode = mode }
                            }
                        }

                        // Verse source
                        section("What you'll read") {
                            choiceRow(
                                title: "Koum's plan",
                                subtitle: "A verse a day, chosen for mornings",
                                symbol: "sunrise",
                                selected: alarm.verseSource == .koumPlan
                            ) { alarm.verseSource = .koumPlan }

                            ForEach(["Psalms", "Proverbs", "John", "Romans"], id: \.self) { book in
                                choiceRow(
                                    title: book,
                                    subtitle: "Read through, morning by morning",
                                    symbol: "book",
                                    selected: alarm.verseSource == .readingPlan(book: book)
                                ) { alarm.verseSource = .readingPlan(book: book) }
                            }
                        }

                        // Sound
                        section("Sound") {
                            ForEach(AlarmSound.all) { sound in
                                choiceRow(
                                    title: sound.displayName,
                                    subtitle: sound.character,
                                    symbol: alarm.soundName == sound.id ? "speaker.wave.2" : "speaker",
                                    selected: alarm.soundName == sound.id
                                ) {
                                    alarm.soundName = sound.id
                                    AlarmSoundPlayer.shared.preview(sound: sound)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, KoumSpacing.margin)
                    .padding(.bottom, KoumSpacing.xl)
                }
            }
            .navigationTitle(alarm.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { save() }
                }
            }
        }
        .onAppear {
            var comps = DateComponents()
            comps.hour = alarm.hour
            comps.minute = alarm.minute
            time = Calendar.current.date(from: comps) ?? Date()
        }
        .onDisappear { AlarmSoundPlayer.shared.stop() }
    }

    private func save() {
        try? modelContext.save()
        Task {
            await app.resyncAlarms(context: modelContext)
        }
        dismiss()
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: KoumSpacing.sm) {
            MicroLabel(text: title, color: theme.textMuted)
            content()
        }
    }

    private func dayToggle(_ day: Int) -> some View {
        let selected = alarm.repeatDays.contains(day)
        return Button {
            KoumHaptics.selection()
            if selected {
                alarm.repeatDays.removeAll { $0 == day }
            } else {
                alarm.repeatDays.append(day)
            }
        } label: {
            Text(daySymbols[day - 1])
                .font(KoumType.label)
                .foregroundStyle(selected ? KoumColor.night : theme.textMuted)
                .frame(width: 40, height: 40)
                .background(
                    Circle().fill(selected ? theme.accent : theme.raised)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Calendar.current.weekdaySymbols[day - 1])
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func choiceRow(
        title: String, subtitle: String, symbol: String, selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            KoumHaptics.selection()
            action()
        } label: {
            HStack(spacing: KoumSpacing.md) {
                Image(systemName: symbol)
                    .foregroundStyle(selected ? theme.accent : theme.textMuted)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(KoumType.label)
                        .foregroundStyle(theme.text)
                    Text(subtitle)
                        .font(KoumType.caption)
                        .foregroundStyle(theme.textMuted)
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(theme.accent)
                }
            }
            .padding(KoumSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.raised)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(selected ? theme.accent : .clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
