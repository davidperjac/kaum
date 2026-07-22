import SwiftUI

// MARK: - Line-by-line statement screen

/// Type appears line by line at BREATH intervals — pacing that forces the
/// reader to slow down. No logo, no imagery; type only.
struct OnboardingStatement: View {
    let lines: [String]
    let button: String
    let action: () -> Void

    @State private var visibleLines = 0
    @State private var buttonVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: KoumSpacing.lg) {
                ForEach(lines.indices, id: \.self) { idx in
                    Text(lines[idx])
                        .font(KoumType.display)
                        .koumLineSpacing(6)
                        .foregroundStyle(KoumColor.bone)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(idx < visibleLines ? 1 : 0)
                        .offset(y: idx < visibleLines ? 0 : 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, KoumSpacing.margin)

            Spacer()

            Button(button, action: action)
                .buttonStyle(.koumPrimary)
                .padding(.horizontal, KoumSpacing.margin)
                .padding(.bottom, KoumSpacing.lg)
                .opacity(buttonVisible ? 1 : 0)
        }
        .onAppear { reveal() }
    }

    private func reveal() {
        if reduceMotion {
            visibleLines = lines.count
            buttonVisible = true
            return
        }
        for idx in lines.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(idx) * KoumMotion.breath) {
                withAnimation(KoumMotion.breathEase) { visibleLines = idx + 1 }
            }
        }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + Double(lines.count) * KoumMotion.breath + 0.3
        ) {
            withAnimation(KoumMotion.gentleEase) { buttonVisible = true }
        }
    }
}

// MARK: - Single choice

struct OnboardingChoice: View {
    let question: String
    let options: [String]
    @Binding var selection: String
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: KoumSpacing.xxl)

            Text(question)
                .font(KoumType.display)
                .koumLineSpacing(6)
                .foregroundStyle(KoumColor.bone)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, KoumSpacing.xl)

            VStack(spacing: KoumSpacing.sm) {
                ForEach(options, id: \.self) { option in
                    OnboardingOptionRow(
                        text: option,
                        selected: selection == option,
                        multi: false
                    ) {
                        selection = option
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            onContinue()
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, KoumSpacing.margin)
    }
}

// MARK: - Multi choice

struct OnboardingMultiChoice: View {
    let question: String
    let hint: String
    let options: [String]
    @Binding var selection: Set<String>
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: KoumSpacing.xxl)

            Text(question)
                .font(KoumType.display)
                .koumLineSpacing(6)
                .foregroundStyle(KoumColor.bone)
                .padding(.bottom, KoumSpacing.xs)

            Text(hint)
                .font(KoumType.caption)
                .foregroundStyle(KoumColor.boneFaint)
                .padding(.bottom, KoumSpacing.xl)

            VStack(spacing: KoumSpacing.sm) {
                ForEach(options, id: \.self) { option in
                    OnboardingOptionRow(
                        text: option,
                        selected: selection.contains(option),
                        multi: true
                    ) {
                        if selection.contains(option) {
                            selection.remove(option)
                        } else {
                            selection.insert(option)
                        }
                    }
                }
            }

            Spacer()

            Button("Continue", action: onContinue)
                .buttonStyle(.koumPrimary)
                .padding(.bottom, KoumSpacing.lg)
                .disabled(selection.isEmpty)
                .opacity(selection.isEmpty ? 0.4 : 1)
        }
        .padding(.horizontal, KoumSpacing.margin)
    }
}

struct OnboardingOptionRow: View {
    let text: String
    let selected: Bool
    let multi: Bool
    let action: () -> Void

    var body: some View {
        Button {
            KoumHaptics.selection()
            action()
        } label: {
            HStack {
                Text(text)
                    .font(KoumType.body)
                    .foregroundStyle(KoumColor.bone)
                Spacer()
                Image(systemName: multi
                      ? (selected ? "checkmark.square.fill" : "square")
                      : (selected ? "circle.inset.filled" : "circle"))
                    .foregroundStyle(selected ? KoumColor.firstlight : KoumColor.boneFaint)
            }
            .padding(KoumSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(KoumColor.nightRaised)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(selected ? KoumColor.firstlight : .clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// MARK: - Screen 8: mode choice

struct ModeChoiceScreen: View {
    @Binding var selection: VerifyMode
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: KoumSpacing.xxl)

            Text("How do you want\nto turn it off?")
                .font(KoumType.display)
                .koumLineSpacing(6)
                .foregroundStyle(KoumColor.bone)
                .padding(.bottom, KoumSpacing.xl)

            VStack(spacing: KoumSpacing.sm) {
                ForEach(VerifyMode.allCases, id: \.self) { mode in
                    Button {
                        KoumHaptics.selection()
                        selection = mode
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            onContinue()
                        }
                    } label: {
                        HStack(spacing: KoumSpacing.md) {
                            GlyphView(glyph: mode.glyph, size: 24)
                                .frame(width: 30)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.title)
                                    .font(KoumType.label)
                                    .foregroundStyle(KoumColor.bone)
                                Text(mode.subtitle)
                                    .font(KoumType.caption)
                                    .foregroundStyle(KoumColor.boneMuted)
                            }
                            Spacer()
                        }
                        .padding(KoumSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(KoumColor.nightRaised)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(selection == mode ? KoumColor.firstlight : .clear, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("You can change this anytime.")
                .font(KoumType.caption)
                .foregroundStyle(KoumColor.boneFaint)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, KoumSpacing.md)

            Spacer()
        }
        .padding(.horizontal, KoumSpacing.margin)
    }
}

// MARK: - Screen 9: time

struct TimeScreen: View {
    @Binding var time: Date
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: KoumSpacing.xxl)

            Text("What time do you\nwant to be up?")
                .font(KoumType.display)
                .koumLineSpacing(6)
                .foregroundStyle(KoumColor.bone)
                .multilineTextAlignment(.center)
                .padding(.bottom, KoumSpacing.xl)

            DatePicker("Wake time", selection: $time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)

            Spacer()

            Button("Continue", action: onContinue)
                .buttonStyle(.koumPrimary)
                .padding(.bottom, KoumSpacing.lg)
        }
        .padding(.horizontal, KoumSpacing.margin)
    }
}

// MARK: - Screen 10: days

struct DaysScreen: View {
    @Binding var days: Set<Int>
    let onContinue: () -> Void

    private let symbols = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: KoumSpacing.xxl)

            Text("Which mornings?")
                .font(KoumType.display)
                .foregroundStyle(KoumColor.bone)
                .padding(.bottom, KoumSpacing.xl)

            HStack(spacing: KoumSpacing.sm) {
                ForEach(1...7, id: \.self) { day in
                    let selected = days.contains(day)
                    Button {
                        KoumHaptics.selection()
                        if selected { days.remove(day) } else { days.insert(day) }
                    } label: {
                        Text(symbols[day - 1])
                            .font(KoumType.label)
                            .foregroundStyle(selected ? KoumColor.night : KoumColor.boneMuted)
                            .frame(width: 42, height: 42)
                            .background(
                                Circle().fill(selected ? KoumColor.firstlight : KoumColor.nightRaised)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Calendar.current.weekdaySymbols[day - 1])
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(.bottom, KoumSpacing.lg)

            Text("Every day is easier\nthan most days.")
                .font(KoumType.body)
                .foregroundStyle(KoumColor.boneMuted)
                .multilineTextAlignment(.center)

            Spacer()

            Button("Continue", action: onContinue)
                .buttonStyle(.koumPrimary)
                .padding(.bottom, KoumSpacing.lg)
                .disabled(days.isEmpty)
                .opacity(days.isEmpty ? 0.4 : 1)
        }
        .padding(.horizontal, KoumSpacing.margin)
    }
}

// MARK: - Screen 11: verse source

struct VerseSourceScreen: View {
    @Binding var selection: VerseSource
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: KoumSpacing.xxl)

            Text("What do you want\nto read?")
                .font(KoumType.display)
                .koumLineSpacing(6)
                .foregroundStyle(KoumColor.bone)
                .padding(.bottom, KoumSpacing.xl)

            VStack(spacing: KoumSpacing.sm) {
                sourceRow(.koumPlan, title: "Koum's plan",
                          subtitle: "A verse a day, chosen for mornings")
                ForEach(["Psalms", "Proverbs", "John", "Romans"], id: \.self) { book in
                    sourceRow(.readingPlan(book: book), title: book, subtitle: nil)
                }
            }

            Text("You can change this whenever you like.")
                .font(KoumType.caption)
                .foregroundStyle(KoumColor.boneFaint)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, KoumSpacing.md)

            Spacer()
        }
        .padding(.horizontal, KoumSpacing.margin)
    }

    private func sourceRow(_ source: VerseSource, title: String, subtitle: String?) -> some View {
        Button {
            KoumHaptics.selection()
            selection = source
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onContinue() }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(KoumType.label)
                        .foregroundStyle(KoumColor.bone)
                    if let subtitle {
                        Text(subtitle)
                            .font(KoumType.caption)
                            .foregroundStyle(KoumColor.boneMuted)
                    }
                }
                Spacer()
                Image(systemName: selection == source ? "circle.inset.filled" : "circle")
                    .foregroundStyle(selection == source ? KoumColor.firstlight : KoumColor.boneFaint)
            }
            .padding(KoumSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(KoumColor.nightRaised)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Screen 12: alarm permission

struct AlarmPermissionScreen: View {
    @Binding var denied: Bool
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text("One thing.")
                .font(KoumType.display)
                .foregroundStyle(KoumColor.bone)
                .padding(.bottom, KoumSpacing.lg)

            Text("Koum needs permission to use iPhone alarms — the real kind, that ring through Silent and Focus.")
                .font(KoumType.body)
                .koumLineSpacing(6)
                .foregroundStyle(KoumColor.boneMuted)
                .padding(.bottom, KoumSpacing.md)

            Text("Same as your Clock app.")
                .font(KoumType.body)
                .foregroundStyle(KoumColor.bone)

            if denied {
                VStack(alignment: .leading, spacing: KoumSpacing.sm) {
                    Text("Alarms are off for Koum, and Koum can't work without them.")
                        .font(KoumType.body)
                        .foregroundStyle(KoumColor.attention)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.koumSecondary)
                }
                .padding(.top, KoumSpacing.xl)
            }

            Spacer()

            Button(denied ? "Try again" : "Allow alarms") {
                Task {
                    let granted = await AlarmService.shared.requestAuthorization()
                    if granted {
                        onContinue()
                    } else {
                        denied = true
                    }
                }
            }
            .buttonStyle(.koumPrimary)
            .padding(.bottom, denied ? KoumSpacing.sm : KoumSpacing.lg)

            if denied {
                Button("Continue anyway") { onContinue() }
                    .buttonStyle(.koumGhost)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, KoumSpacing.sm)
            }
        }
        .padding(.horizontal, KoumSpacing.margin)
    }
}

// MARK: - Screen 13: summary

struct SummaryScreen: View {
    var name: String = ""
    let time: Date
    let days: Set<Int>
    let source: VerseSource
    let mode: VerifyMode
    let motivation: String
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: KoumSpacing.xxl)

            Text(name.isEmpty ? "Here's your morning." : "\(name), here's\nyour morning.")
                .font(KoumType.display)
                .koumLineSpacing(6)
                .foregroundStyle(KoumColor.bone)
                .padding(.bottom, KoumSpacing.xl)

            VStack(alignment: .leading, spacing: KoumSpacing.xs) {
                Text("\(time.formatted(date: .omitted, time: .shortened)) · \(daysDisplay)")
                Text(source.title)
                Text("\(mode.title) to dismiss")
            }
            .font(KoumType.label)
            .foregroundStyle(KoumColor.bone)
            .padding(KoumSpacing.md + KoumSpacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(KoumColor.nightRaised)
            )
            .padding(.bottom, KoumSpacing.xl)

            VStack(alignment: .leading, spacing: KoumSpacing.xs) {
                Text("Wake up.")
                Text("Open your Bible.")
                Text("Read one verse.")
                Text("Pray for a minute.")
                Text("Write one line.")
            }
            .font(KoumType.body)
            .foregroundStyle(KoumColor.boneMuted)
            .padding(.bottom, KoumSpacing.md)

            Text("Under four minutes.")
                .font(KoumType.body)
                .foregroundStyle(KoumColor.bone)
                .padding(.bottom, KoumSpacing.xl)

            if !motivation.isEmpty {
                Text("You said you wanted to feel \(motivation).\nThis is how that starts.")
                    .font(KoumType.devotionalItalic)
                    .koumLineSpacing(6)
                    .foregroundStyle(KoumColor.boneMuted)
            }

            Spacer()

            Text("Tomorrow at \(time.formatted(date: .omitted, time: .shortened)) — one promise, kept.")
                .font(KoumType.caption)
                .foregroundStyle(KoumColor.boneFaint)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, KoumSpacing.sm)

            Button("I'll be there", action: onContinue)
                .buttonStyle(.koumPrimary)
                .padding(.bottom, KoumSpacing.lg)
        }
        .padding(.horizontal, KoumSpacing.margin)
    }

    private var daysDisplay: String {
        if days.count == 7 { return "Every day" }
        if days == Set([2, 3, 4, 5, 6]) { return "Mon–Fri" }
        if days == Set([1, 7]) { return "Weekends" }
        let symbols = Calendar.current.shortWeekdaySymbols
        return days.sorted().map { symbols[$0 - 1] }.joined(separator: " ")
    }
}

// MARK: - Screen 16: confirmation

struct ConfirmationScreen: View {
    let time: Date
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image("WrenSinging")
                .resizable()
                .scaledToFit()
                .frame(height: 96)
                .accessibilityHidden(true)
                .padding(.bottom, KoumSpacing.lg)

            Text("You're set for\n\(time.formatted(date: .omitted, time: .shortened)) tomorrow.")
                .font(KoumType.display)
                .koumLineSpacing(6)
                .foregroundStyle(KoumColor.bone)
                .multilineTextAlignment(.center)
                .padding(.bottom, KoumSpacing.xl)

            Text("Put your Bible\nwhere you'll see it.")
                .font(KoumType.title)
                .koumLineSpacing(6)
                .foregroundStyle(KoumColor.boneMuted)
                .multilineTextAlignment(.center)
                .padding(.bottom, KoumSpacing.xl)

            Text("We'll remind you on day 5,\nbefore the trial ends.")
                .font(KoumType.caption)
                .foregroundStyle(KoumColor.boneFaint)
                .multilineTextAlignment(.center)

            Spacer()

            Text("KOUM")
                .font(KoumType.wordmark)
                .kerning(3)
                .foregroundStyle(KoumColor.boneFaint)
                .padding(.bottom, KoumSpacing.md)
                .accessibilityHidden(true)

            Button("Done", action: onDone)
                .buttonStyle(.koumPrimary)
                .padding(.bottom, KoumSpacing.lg)
        }
        .padding(.horizontal, KoumSpacing.margin)
    }
}
