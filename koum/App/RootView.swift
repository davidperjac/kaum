import SwiftData
import SwiftUI

/// Root routing: onboarding → paywall gate → home, with the morning flow
/// overlaying everything when an alarm fires.
///
/// **The alarm always fires.** If a subscription lapses while an alarm is
/// scheduled, verification and dismissal still work; the paywall waits until
/// the morning is complete. An alarm app that silently stops ringing because
/// a payment failed is a genuinely harmful failure mode.
struct RootView: View {
    @Environment(AppModel.self) private var app
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var systemScheme
    @Environment(\.scenePhase) private var scenePhase

    @ObservedObject private var launchState = AlarmLaunchState.shared
    @State private var showLapsedPaywall = false

    private var theme: KoumTheme {
        switch app.themePreference {
        case .system: KoumTheme(isDark: systemScheme == .dark)
        case .dark: KoumTheme(isDark: true)
        case .light: KoumTheme(isDark: false)
        }
    }

    var body: some View {
        Group {
            if let session = app.morningSession {
                // Highest priority: a morning in progress. Never gated.
                MorningFlowView(session: session)
            } else if !app.hasCompletedOnboarding {
                OnboardingFlow()
            } else if !subscriptions.isSubscribed && subscriptions.isConfigured {
                // Lapsed / never-converted after onboarding: hard gate.
                PaywallView(onUnlocked: {})
            } else {
                HomeView()
                    .environment(\.koumTheme, theme)
                    .preferredColorScheme(app.themePreference == .system
                                          ? nil
                                          : (app.themePreference == .dark ? .dark : .light))
            }
        }
        .task {
            AlarmService.shared.startObserving()
            AlarmService.shared.refreshAuthState()
            await subscriptions.refresh()
            await app.resyncAlarms(context: modelContext)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            AlarmService.shared.refreshAuthState()
            Task {
                await subscriptions.refresh()
                await app.resyncAlarms(context: modelContext)
                checkAlertingAlarms()
            }
        }
        .onChange(of: launchState.pendingAlarmID) { _, id in
            guard let id else { return }
            launchState.pendingAlarmID = nil
            app.handleAlarmLaunch(alarmID: id, context: modelContext)
        }
        .onChange(of: AlarmService.shared.alertingAlarmIDs) { _, alerting in
            // Fallback path: an alarm is alerting and the app is open (or was
            // just launched from the alert) but no intent arrived.
            guard app.morningSession == nil, let first = alerting.first else { return }
            app.handleAlarmLaunch(alarmID: first.uuidString, context: modelContext)
        }
    }

    private func checkAlertingAlarms() {
        guard app.morningSession == nil,
              let first = AlarmService.shared.alertingAlarmIDs.first else { return }
        app.handleAlarmLaunch(alarmID: first.uuidString, context: modelContext)
    }
}
