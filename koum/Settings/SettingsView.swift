import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(\.modelContext) private var modelContext
    @Environment(\.koumTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \AlarmModel.createdAt) private var alarms: [AlarmModel]
    @State private var editingAlarm: AlarmModel?
    @State private var restoreMessage: String?

    var body: some View {
        NavigationStack {
            List {
                // Alarms
                Section("Alarms") {
                    ForEach(alarms) { alarm in
                        Button {
                            editingAlarm = alarm
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(alarm.timeDisplay)
                                        .font(KoumType.body)
                                        .foregroundStyle(theme.text)
                                    Text("\(alarm.repeatDisplay) · \(alarm.mode.title)")
                                        .font(KoumType.caption)
                                        .foregroundStyle(theme.textMuted)
                                }
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { alarm.enabled },
                                    set: { newValue in
                                        alarm.enabled = newValue
                                        try? modelContext.save()
                                        Task { await app.resyncAlarms(context: modelContext) }
                                    }
                                ))
                                .labelsHidden()
                                .tint(theme.accent)
                            }
                        }
                    }
                    .onDelete { offsets in
                        for idx in offsets {
                            AlarmService.shared.cancel(alarms[idx].id)
                            modelContext.delete(alarms[idx])
                        }
                        try? modelContext.save()
                    }

                    Button("Add alarm") {
                        let alarm = AlarmModel(name: alarms.isEmpty ? "Morning" : "Alarm \(alarms.count + 1)")
                        modelContext.insert(alarm)
                        try? modelContext.save()
                        editingAlarm = alarm
                    }
                    .foregroundStyle(theme.accent)
                }

                // Appearance
                Section("Appearance") {
                    Picker("Theme", selection: Binding(
                        get: { app.themePreference },
                        set: { app.themePreference = $0 }
                    )) {
                        ForEach(AppTheme.allCases, id: \.self) { t in
                            Text(t.title).tag(t)
                        }
                    }

                    Picker("Translation", selection: Binding(
                        get: { app.translationPreference },
                        set: { app.translationPreference = $0 }
                    )) {
                        ForEach(Translation.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                }

                // Subscription
                Section("Subscription") {
                    if subscriptions.isSubscribed {
                        LabeledContent("Koum Pro", value: subscriptions.isInTrial ? "Trial" : "Active")
                    }
                    Button("Restore purchases") {
                        Task {
                            do {
                                try await subscriptions.restore()
                                restoreMessage = subscriptions.isSubscribed
                                    ? "Restored." : "No purchases found for this Apple ID."
                            } catch {
                                restoreMessage = "Couldn't reach the App Store. Try again later."
                            }
                        }
                    }
                    .foregroundStyle(theme.accent)
                }

                // Privacy
                Section {
                    Link("Privacy policy", destination: KoumConfig.privacyPolicyURL)
                    Link("Terms of use", destination: KoumConfig.termsURL)
                } header: {
                    Text("About")
                } footer: {
                    Text("No account. No analytics beyond the App Store's own. Your journal and prayers stay on your phone.")
                        .font(KoumType.micro)
                }

                if AlarmService.shared.authState == .denied {
                    Section {
                        Button("Alarm permission is off — open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .foregroundStyle(theme.attention)
                    } footer: {
                        Text("Koum cannot ring without alarm access.")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(item: $editingAlarm) { alarm in
                AlarmEditView(alarm: alarm)
            }
            .alert(restoreMessage ?? "", isPresented: Binding(
                get: { restoreMessage != nil },
                set: { if !$0 { restoreMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            }
        }
    }
}
