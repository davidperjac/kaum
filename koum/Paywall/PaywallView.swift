import RevenueCat
import SwiftUI

/// The paywall. Always dark, calm, confident — no countdown timers, no fake
/// urgency. A living dawn sits at the top; the ask is personal; every word
/// about a free trial is driven by the actual product offer. No offer, no
/// trial language.
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
    @State private var heroGlow = false
    /// Hard paywall: closing is only offered after a beat, and it exits to a
    /// reduced state rather than the app.
    var onClose: (() -> Void)?

    private var trialDays: Int? { subscriptions.yearlyTrialDays }

    var body: some View {
        ZStack {
            KoumColor.night.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        hero
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
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                heroGlow = true
            }
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

    // MARK: - Hero: a living dawn above the ask

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            // The mark, glowing gently
            ZStack {
                RadialGradient(
                    colors: [
                        KoumColor.firstlight.opacity(heroGlow ? 0.28 : 0.14),
                        KoumColor.firstlight.opacity(0),
                    ],
                    center: .center, startRadius: 0, endRadius: 90
                )
                .frame(height: 130)
                GlyphView(glyph: .sunrise, size: 44)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, KoumSpacing.md)

            Text(app.userName.isEmpty
                 ? "Tomorrow morning,\neverything changes."
                 : "\(app.userName), tomorrow\nmorning changes.")
                .font(KoumType.display)
                .koumLineSpacing(7)
                .foregroundStyle(KoumColor.bone)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.top, KoumSpacing.sm)

            Text(app.onboardingMotivation.isEmpty
                 ? "An alarm your Bible turns off. A verse, a prayer, a line — under four minutes."
                 : "You said you wanted to feel \(app.onboardingMotivation). It starts with one kept morning.")
                .font(KoumType.body)
                .koumLineSpacing(5)
                .foregroundStyle(KoumColor.boneMuted)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.top, KoumSpacing.sm)
                .padding(.bottom, KoumSpacing.xl)
        }
    }

    // MARK: - Packages

    private var yearlyPackage: Package? { subscriptions.yearlyPackage }
    private var weeklyPackage: Package? { subscriptions.weeklyPackage }

    private var yearlyPrice: String { yearlyPackage?.localizedPriceString ?? "$29.99" }
    private var weeklyPrice: String { weeklyPackage?.localizedPriceString ?? "$3.99" }

    private var monthlyEquivalent: String {
        guard let yearly = yearlyPackage?.storeProduct.price else { return "$2.50" }
        let monthly = (yearly as NSDecimalNumber).doubleValue / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = yearlyPackage?.storeProduct.priceFormatter?.locale ?? .current
        return formatter.string(from: NSNumber(value: monthly)) ?? "$2.50"
    }

    private var packages: some View {
        VStack(spacing: KoumSpacing.md) {
            packageCard(
                title: "Yearly",
                priceLine: "\(yearlyPrice) per year",
                subLine: "\(monthlyEquivalent)/month, billed once",
                badge: trialDays.map { "\($0) days free" } ?? "Best value",
                selected: selectedYearly
            ) { selectedYearly = true }

            packageCard(
                title: "Weekly",
                priceLine: "\(weeklyPrice) per week",
                subLine: "Billed weekly, cancel anytime",
                badge: nil,
                selected: !selectedYearly
            ) { selectedYearly = false }
        }
        .padding(.bottom, KoumSpacing.md)
    }

    private func packageCard(
        title: String, priceLine: String, subLine: String, badge: String?,
        selected: Bool, action: @escaping () -> Void
    ) -> some View {
        Button {
            KoumHaptics.selection()
            action()
        } label: {
            HStack(spacing: KoumSpacing.md) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: KoumSpacing.sm) {
                        Text(title)
                            .font(KoumType.label)
                            .foregroundStyle(KoumColor.bone)
                        if let badge {
                            Text(badge.uppercased())
                                .font(KoumType.micro)
                                .kerning(1.1)
                                .foregroundStyle(KoumColor.night)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(KoumColor.firstlight))
                        }
                    }
                    Text(priceLine)
                        .font(KoumType.smallLabel)
                        .foregroundStyle(KoumColor.bone)
                    Text(subLine)
                        .font(KoumType.caption)
                        .foregroundStyle(KoumColor.boneMuted)
                }
                Spacer()
                Image(systemName: selected ? "circle.inset.filled" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(selected ? KoumColor.firstlight : KoumColor.boneFaint)
            }
            .padding(KoumSpacing.md + KoumSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(KoumColor.nightRaised)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(selected ? KoumColor.firstlight : KoumColor.nightEdge,
                                    lineWidth: selected ? 1.5 : 1)
                    )
                    .shadow(color: selected ? KoumColor.firstlight.opacity(0.18) : .clear,
                            radius: 18, y: 4)
            )
        }
        .buttonStyle(.plain)
        .animation(KoumMotion.quickEase, value: selected)
    }

    // MARK: - Footer: the ask, plainly

    private var ctaLabel: String {
        if purchasing { return "One moment…" }
        if selectedYearly, let trialDays { return "Start my \(trialDays)-day free trial" }
        return "Continue"
    }

    private var reassurance: String {
        if selectedYearly {
            if let trialDays {
                return "Free for \(trialDays) days, then \(yearlyPrice)/year. Cancel anytime."
            }
            return "\(yearlyPrice) per year. Cancel anytime."
        }
        return "\(weeklyPrice) per week. Cancel anytime."
    }

    private var footer: some View {
        VStack(spacing: KoumSpacing.sm) {
            Button(ctaLabel) { purchase() }
                .buttonStyle(.koumPrimary)
                .disabled(purchasing)

            Text(reassurance)
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
            .padding(.top, 2)

            Text("Payment is charged to your Apple ID at confirmation. Subscriptions renew automatically unless cancelled at least 24 hours before the period ends. Manage in Apple ID settings.")
                .font(.system(size: 9))
                .foregroundStyle(KoumColor.boneFaint.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, KoumSpacing.margin)
        .padding(.top, KoumSpacing.sm)
        .padding(.bottom, KoumSpacing.sm)
        .background(
            LinearGradient(
                colors: [KoumColor.night.opacity(0), KoumColor.night, KoumColor.night],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
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
                    NotificationService.scheduleTrialReminders(trialDays: trialDays)
                    onUnlocked()
                }
            } catch {
                errorMessage = "The purchase didn't go through. You haven't been charged beyond what Apple shows."
            }
        }
    }
}
