import RevenueCat
import SwiftUI

/// The paywall. Always dark. Calm, plain, confident — no countdown timers, no
/// fake discounts, no manufactured urgency of any kind. Yearly pre-selected;
/// weekly present but quiet.
struct PaywallView: View {
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(AppModel.self) private var app

    /// Called after a successful purchase (or when there is nothing to buy in
    /// an unconfigured build).
    var onUnlocked: () -> Void

    @State private var selectedYearly = true
    @State private var closeVisible = false
    @State private var purchasing = false
    @State private var errorMessage: String?
    /// Hard paywall: closing is only offered after a beat, and it exits to a
    /// reduced "come back tonight" state rather than the app.
    var onClose: (() -> Void)?

    var body: some View {
        ZStack {
            KoumColor.night.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        headline
                        features
                        packages
                    }
                    .padding(.horizontal, KoumSpacing.margin)
                }

                footer
            }

            if let onClose {
                VStack {
                    HStack {
                        Button {
                            onClose()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(KoumColor.boneFaint)
                                .frame(width: 32, height: 32)
                        }
                        .opacity(closeVisible ? 1 : 0)
                        .accessibilityLabel("Close")
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, KoumSpacing.sm)
                .padding(.leading, KoumSpacing.sm)
            }
        }
        .environment(\.koumTheme, KoumTheme(isDark: true))
        .preferredColorScheme(.dark)
        .task {
            await subscriptions.loadOffering()
            try? await Task.sleep(for: .seconds(3))
            withAnimation(KoumMotion.gentleEase) { closeVisible = true }
        }
        .alert(errorMessage ?? "", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        }
    }

    private var header: some View {
        Color.clear.frame(height: KoumSpacing.xl)
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: KoumSpacing.sm) {
            Text("Start tomorrow morning.")
                .font(KoumType.display)
                .foregroundStyle(KoumColor.bone)
            if !app.onboardingMotivation.isEmpty {
                Text("You said you wanted to feel \(app.onboardingMotivation.lowercased()). This is how that starts.")
                    .font(KoumType.body)
                    .foregroundStyle(KoumColor.boneMuted)
            }
        }
        .padding(.bottom, KoumSpacing.xl)
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: KoumSpacing.md) {
            featureRow("Alarm that rings through Silent")
            featureRow("Scan, speak, or type to dismiss")
            featureRow("A short devotional every morning")
            featureRow("Prayer log & journal")
            featureRow("Streaks that forgive a bad day")
        }
        .padding(.bottom, KoumSpacing.xl)
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: KoumSpacing.md) {
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(KoumColor.verified)
            Text(text)
                .font(KoumType.body)
                .foregroundStyle(KoumColor.bone)
        }
    }

    // MARK: - Packages

    private var yearlyPackage: Package? {
        subscriptions.currentOffering?.availablePackages.first {
            $0.storeProduct.productIdentifier == KoumConfig.yearlyProductID
        } ?? subscriptions.currentOffering?.annual
    }

    private var weeklyPackage: Package? {
        subscriptions.currentOffering?.availablePackages.first {
            $0.storeProduct.productIdentifier == KoumConfig.weeklyProductID
        } ?? subscriptions.currentOffering?.weekly
    }

    private var packages: some View {
        VStack(spacing: KoumSpacing.md) {
            packageCard(
                title: "Yearly",
                price: yearlyPackage?.localizedPriceString ?? "$29.99/yr",
                detail: "7 days free, then \(yearlyPackage?.localizedPriceString ?? "$29.99")/year — \(monthlyEquivalent)/month",
                badge: "Best value",
                selected: selectedYearly
            ) { selectedYearly = true }

            packageCard(
                title: "Weekly",
                price: weeklyPackage?.localizedPriceString ?? "$3.99/wk",
                detail: "\(weeklyPackage?.localizedPriceString ?? "$3.99") per week, billed weekly",
                badge: nil,
                selected: !selectedYearly
            ) { selectedYearly = false }
        }
        .padding(.bottom, KoumSpacing.lg)
    }

    private var monthlyEquivalent: String {
        guard let yearly = yearlyPackage?.storeProduct.price else { return "$2.50" }
        let monthly = (yearly as NSDecimalNumber).doubleValue / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = yearlyPackage?.storeProduct.priceFormatter?.locale ?? .current
        return formatter.string(from: NSNumber(value: monthly)) ?? "$2.50"
    }

    private func packageCard(
        title: String, price: String, detail: String, badge: String?,
        selected: Bool, action: @escaping () -> Void
    ) -> some View {
        Button {
            KoumHaptics.selection()
            action()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: KoumSpacing.xs) {
                    Text(title)
                        .font(KoumType.label)
                        .foregroundStyle(KoumColor.bone)
                    Text(detail)
                        .font(KoumType.caption)
                        .foregroundStyle(KoumColor.boneMuted)
                }
                Spacer()
                if let badge {
                    MicroLabel(text: badge, color: KoumColor.firstlight)
                        .padding(.trailing, KoumSpacing.sm)
                }
                Image(systemName: selected ? "circle.inset.filled" : "circle")
                    .foregroundStyle(selected ? KoumColor.firstlight : KoumColor.boneFaint)
            }
            .padding(KoumSpacing.md + KoumSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(KoumColor.nightRaised)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(selected ? KoumColor.firstlight : KoumColor.nightEdge, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: KoumSpacing.sm) {
            Button(purchasing ? "One moment…" : (selectedYearly ? "Start free" : "Subscribe")) {
                purchase()
            }
            .buttonStyle(.koumPrimary)
            .disabled(purchasing)

            Text(selectedYearly ? "No charge for 7 days. Cancel anytime." : "Cancel anytime.")
                .font(KoumType.caption)
                .foregroundStyle(KoumColor.boneMuted)

            Text("Your prayers and journal stay on your phone.")
                .font(KoumType.micro)
                .foregroundStyle(KoumColor.boneFaint)

            HStack(spacing: KoumSpacing.md) {
                Button("Restore") {
                    Task {
                        try? await subscriptions.restore()
                        if subscriptions.isSubscribed { onUnlocked() }
                    }
                }
                Link("Terms", destination: KoumConfig.termsURL)
                Link("Privacy", destination: KoumConfig.privacyPolicyURL)
            }
            .font(KoumType.micro)
            .foregroundStyle(KoumColor.boneFaint)

            Text("Payment is charged to your Apple ID at confirmation. Subscription renews automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel in your Apple ID settings.")
                .font(.system(size: 9))
                .foregroundStyle(KoumColor.boneFaint.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.top, KoumSpacing.xs)
        }
        .padding(.horizontal, KoumSpacing.margin)
        .padding(.bottom, KoumSpacing.sm)
    }

    private func purchase() {
        guard subscriptions.isConfigured else {
            // Pre-configuration build: let the developer through.
            onUnlocked()
            return
        }
        guard let package = selectedYearly ? yearlyPackage : weeklyPackage else {
            errorMessage = "Plans aren't available right now. Check your connection and try again."
            return
        }
        purchasing = true
        Task {
            defer { purchasing = false }
            do {
                try await subscriptions.purchase(package)
                if subscriptions.isSubscribed {
                    NotificationService.scheduleTrialReminders()
                    onUnlocked()
                }
            } catch {
                errorMessage = "The purchase didn't go through. You haven't been charged beyond what Apple shows."
            }
        }
    }
}
