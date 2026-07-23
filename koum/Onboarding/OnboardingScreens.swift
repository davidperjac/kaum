import SwiftUI

// MARK: - Line-by-line statement screen

/// Type appears line by line at BREATH intervals — pacing that forces the
/// reader to slow down. Centered, ceremonial; no imagery.
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

            VStack(spacing: KoumSpacing.lg) {
                ForEach(lines.indices, id: \.self) { idx in
                    Text(lines[idx])
                        .font(KoumType.display)
                        .koumLineSpacing(7)
                        .foregroundStyle(KoumColor.bone)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(idx < visibleLines ? 1 : 0)
                        .offset(y: idx < visibleLines ? 0 : 4)
                }
            }
            .frame(maxWidth: .infinity)
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

// MARK: - Single choice (explicit Continue — no auto-advance, ever)

struct OnboardingChoice: View {
    let question: String
    let options: [String]
    @Binding var selection: String
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(question)
                .font(KoumType.display)
                .koumLineSpacing(7)
                .foregroundStyle(KoumColor.bone)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, KoumSpacing.xxl)
                .padding(.bottom, KoumSpacing.xl)

            VStack(spacing: KoumSpacing.sm) {
                ForEach(options, id: \.self) { option in
                    OnboardingOptionRow(
                        text: option,
                        selected: selection == option,
                        multi: false
                    ) {
                        selection = option
                    }
                }
            }

            Spacer()

            Button("Continue", action: onContinue)
                .buttonStyle(.koumPrimary)
                .disabled(selection.isEmpty)
                .opacity(selection.isEmpty ? 0.4 : 1)
                .padding(.bottom, KoumSpacing.lg)
        }
        .padding(.horizontal, KoumSpacing.margin)
        .animation(KoumMotion.quickEase, value: selection)
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
            Text(question)
                .font(KoumType.display)
                .koumLineSpacing(7)
                .foregroundStyle(KoumColor.bone)
                .padding(.top, KoumSpacing.xxl)
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
        .animation(KoumMotion.quickEase, value: selection)
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

// MARK: - Mode choice (explicit Continue)

struct ModeChoiceScreen: View {
    @Binding var selection: VerifyMode
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("How do you want\nto turn it off?")
                .font(KoumType.display)
                .koumLineSpacing(7)
                .foregroundStyle(KoumColor.bone)
                .padding(.top, KoumSpacing.xxl)
                .padding(.bottom, KoumSpacing.xl)

            VStack(spacing: KoumSpacing.sm) {
                ForEach(VerifyMode.allCases, id: \.self) { mode in
                    Button {
                        KoumHaptics.selection()
                        selection = mode
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
                            Image(systemName: selection == mode ? "circle.inset.filled" : "circle")
                                .foregroundStyle(selection == mode ? KoumColor.firstlight : KoumColor.boneFaint)
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

            Text("You can change this anytime, even mid-alarm.")
                .font(KoumType.caption)
                .foregroundStyle(KoumColor.boneFaint)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, KoumSpacing.md)

            Spacer()

            Button("Continue", action: onContinue)
                .buttonStyle(.koumPrimary)
                .padding(.bottom, KoumSpacing.lg)
        }
        .padding(.horizontal, KoumSpacing.margin)
        .animation(KoumMotion.quickEase, value: selection)
    }
}

// MARK: - Time

struct TimeScreen: View {
    @Binding var time: Date
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("What time do you\nwant to be up?")
                .font(KoumType.display)
                .koumLineSpacing(7)
                .foregroundStyle(KoumColor.bone)
                .multilineTextAlignment(.center)
                .padding(.top, KoumSpacing.xxl)
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

// MARK: - Days

struct DaysScreen: View {
    @Binding var days: Set<Int>
    let onContinue: () -> Void

    private let symbols = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(spacing: 0) {
            Text("Which mornings?")
                .font(KoumType.display)
                .foregroundStyle(KoumColor.bone)
                .padding(.top, KoumSpacing.xxl)
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
        .animation(KoumMotion.quickEase, value: days)
    }
}

// MARK: - Verse source (explicit Continue)

struct VerseSourceScreen: View {
    @Binding var selection: VerseSource
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What do you want\nto read?")
                .font(KoumType.display)
                .koumLineSpacing(7)
                .foregroundStyle(KoumColor.bone)
                .padding(.top, KoumSpacing.xxl)
                .padding(.bottom, KoumSpacing.xl)

            VStack(spacing: KoumSpacing.sm) {
                sourceRow(.koumPlan, title: "Koum's plan",
                          subtitle: "A verse a day, chosen for mornings")
                ForEach(["Psalms", "Proverbs", "John", "Romans"], id: \.self) { book in
                    sourceRow(.readingPlan(book: book), title: book,
                              subtitle: "Read through, morning by morning")
                }
            }

            Text("You can change this whenever you like.")
                .font(KoumType.caption)
                .foregroundStyle(KoumColor.boneFaint)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, KoumSpacing.md)

            Spacer()

            Button("Continue", action: onContinue)
                .buttonStyle(.koumPrimary)
                .padding(.bottom, KoumSpacing.lg)
        }
        .padding(.horizontal, KoumSpacing.margin)
        .animation(KoumMotion.quickEase, value: selection)
    }

    private func sourceRow(_ source: VerseSource, title: String, subtitle: String?) -> some View {
        Button {
            KoumHaptics.selection()
            selection = source
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(selection == source ? KoumColor.firstlight : .clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Alarm permission

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

            Text("Koum needs permission to use iPhone alarms. The real kind, that ring through Silent and Focus.")
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

// MARK: - Summary / the pact

/// The pact. The sun is nearly up behind this screen; the plan reads like a
/// promise being sealed, not a settings recap. Everything arrives on a
/// breath: the name, the covenant card glowing with first light, the five
/// steps lighting one by one, their own words handed back to them.
struct SummaryScreen: View {
    var name: String = ""
    let time: Date
    let days: Set<Int>
    let source: VerseSource
    let mode: VerifyMode
    let motivation: String
    let onContinue: () -> Void

    @State private var stage = 0
    @State private var litSteps = 0
    @State private var cardGlow = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let steps = [
        "Wake up.",
        "Open your Bible.",
        "Read one verse.",
        "Pray for a minute.",
        "Write one line.",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MicroLabel(text: "Your morning", color: KoumColor.firstlight)
                .padding(.top, KoumSpacing.xl)
                .padding(.bottom, KoumSpacing.sm)
                .opacity(stage >= 1 ? 1 : 0)

            Text(name.isEmpty ? "Here it is." : "\(name), here it is.")
                .font(KoumType.display)
                .koumLineSpacing(7)
                .foregroundStyle(KoumColor.bone)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(stage >= 1 ? 1 : 0)
                .offset(y: stage >= 1 ? 0 : 6)
                .padding(.bottom, KoumSpacing.lg)

            // The covenant card: their plan, glowing with first light.
            VStack(alignment: .leading, spacing: KoumSpacing.md) {
                summaryRow(glyph: .sunrise,
                           title: time.formatted(date: .omitted, time: .shortened),
                           detail: daysDisplay)
                summaryRow(glyph: .book,
                           title: source.title,
                           detail: "One verse, waiting for you")
                summaryRow(glyph: mode.glyph,
                           title: mode.title,
                           detail: "That's what ends the alarm")
            }
            .padding(KoumSpacing.md + KoumSpacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(KoumColor.nightRaised.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(KoumColor.firstlight.opacity(cardGlow ? 0.45 : 0.2), lineWidth: 1)
                    )
                    .shadow(color: KoumColor.firstlight.opacity(cardGlow ? 0.16 : 0.05),
                            radius: 24, y: 6)
            )
            .opacity(stage >= 2 ? 1 : 0)
            .offset(y: stage >= 2 ? 0 : 8)
            .padding(.bottom, KoumSpacing.lg)

            // The five steps, catching light one by one.
            VStack(alignment: .leading, spacing: KoumSpacing.sm) {
                ForEach(steps.indices, id: \.self) { idx in
                    HStack(spacing: KoumSpacing.md) {
                        Circle()
                            .fill(idx < litSteps ? KoumColor.firstlight : KoumColor.nightEdge)
                            .frame(width: 5, height: 5)
                        Text(steps[idx])
                            .font(KoumType.body)
                            .foregroundStyle(idx < litSteps ? KoumColor.bone : KoumColor.boneFaint)
                    }
                }
                Text("Under four minutes, all of it.")
                    .font(KoumType.caption)
                    .foregroundStyle(KoumColor.boneMuted)
                    .padding(.top, KoumSpacing.xs)
            }
            .opacity(stage >= 3 ? 1 : 0)
            .padding(.bottom, KoumSpacing.lg)

            if !motivation.isEmpty {
                Text("You said you wanted to feel \(motivation).\nThis is how that starts.")
                    .font(KoumType.devotionalItalic)
                    .koumLineSpacing(6)
                    .foregroundStyle(KoumColor.boneMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(stage >= 4 ? 1 : 0)
            }

            Spacer()

            Text("Tomorrow at \(time.formatted(date: .omitted, time: .shortened)). One promise, kept.")
                .font(KoumType.caption)
                .foregroundStyle(KoumColor.boneFaint)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, KoumSpacing.sm)
                .opacity(stage >= 4 ? 1 : 0)

            Button("I'll be there", action: onContinue)
                .buttonStyle(.koumPrimary)
                .opacity(stage >= 4 ? 1 : 0)
                .padding(.bottom, KoumSpacing.lg)
        }
        .padding(.horizontal, KoumSpacing.margin)
        .onAppear { reveal() }
    }

    private func summaryRow(glyph: KoumGlyph, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: KoumSpacing.md) {
            GlyphView(glyph: glyph, size: 20)
                .frame(width: 24)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(KoumType.label)
                    .foregroundStyle(KoumColor.bone)
                Text(detail)
                    .font(KoumType.caption)
                    .foregroundStyle(KoumColor.boneMuted)
            }
        }
    }

    private func reveal() {
        if reduceMotion {
            stage = 4
            litSteps = steps.count
            cardGlow = true
            return
        }
        withAnimation(KoumMotion.breathEase) { stage = 1 }
        withAnimation(KoumMotion.breathEase.delay(0.5)) { stage = 2 }
        withAnimation(.easeInOut(duration: 2.4).delay(0.9)) { cardGlow = true }
        withAnimation(KoumMotion.breathEase.delay(1.0)) { stage = 3 }
        for idx in steps.indices {
            withAnimation(KoumMotion.quickEase.delay(1.2 + Double(idx) * 0.22)) {
                litSteps = idx + 1
            }
        }
        withAnimation(KoumMotion.breathEase.delay(1.2 + Double(steps.count) * 0.22)) { stage = 4 }
    }

    private var daysDisplay: String {
        if days.count == 7 { return "Every day" }
        if days == Set([2, 3, 4, 5, 6]) { return "Mon–Fri" }
        if days == Set([1, 7]) { return "Weekends" }
        let symbols = Calendar.current.shortWeekdaySymbols
        return days.sorted().map { symbols[$0 - 1] }.joined(separator: " ")
    }
}

// MARK: - Confirmation

struct ConfirmationScreen: View {
    let time: Date
    /// nil = no free trial configured; no trial language shown.
    var trialDays: Int? = nil
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
                .koumLineSpacing(7)
                .foregroundStyle(KoumColor.bone)
                .multilineTextAlignment(.center)
                .padding(.bottom, KoumSpacing.xl)

            Text("Put your Bible\nwhere you'll see it.")
                .font(KoumType.title)
                .koumLineSpacing(6)
                .foregroundStyle(KoumColor.boneMuted)
                .multilineTextAlignment(.center)
                .padding(.bottom, KoumSpacing.xl)

            if let trialDays, trialDays > 1 {
                Text("We'll remind you on day \(trialDays - 1),\nbefore your trial ends.")
                    .font(KoumType.caption)
                    .foregroundStyle(KoumColor.boneFaint)
                    .multilineTextAlignment(.center)
            }

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
