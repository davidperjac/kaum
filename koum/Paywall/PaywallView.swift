import RevenueCat
import SwiftUI

/// The paywall. A painted dawn breaks across the whole screen — the one
/// moment Koum spends its full visual budget. Calm, confident, personal;
/// no countdown timers, no fake urgency. Every word about a free trial is
/// driven by the actual product offer: no offer, no trial language.
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
    @State private var revealed = 0
    @State private var ctaGlow = false
    /// The one-time exit offer. Once it has been seen and declined, the X
    /// never comes back: the paywall is hard from then on.
    @State private var showPromo = false
    @State private var promoConsumed = PromoOffer.consumed

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var trialDays: Int? { subscriptions.yearlyTrialDays }

    var body: some View {
        ZStack {
            dawnBackground

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .center, spacing: 0) {
                        hero
                        valueRows
                        packages
                    }
                    .padding(.horizontal, KoumSpacing.margin)
                }

                footer
            }

            // The X lives on the right, and only until the one-time offer has
            // been spent. Tapping it opens the offer, not the exit.
            if !promoConsumed {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(KoumMotion.gentleEase) { showPromo = true }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(KoumColor.boneFaint)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(KoumColor.night.opacity(0.4)))
                        }
                        .opacity(closeVisible ? 1 : 0)
                        .accessibilityLabel("Close")
                    }
                    Spacer()
                }
                .padding(.top, KoumSpacing.sm)
                .padding(.trailing, KoumSpacing.sm)
            }

            if showPromo {
                PromoOfferView(
                    onUnlocked: onUnlocked,
                    onDecline: {
                        PromoOffer.markConsumed()
                        withAnimation(KoumMotion.gentleEase) {
                            promoConsumed = true
                            showPromo = false
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .environment(\.koumTheme, KoumTheme(isDark: true))
        .preferredColorScheme(.dark)
        .task {
            await subscriptions.loadOffering()
            reveal()
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

    private func reveal() {
        if reduceMotion {
            revealed = 3
            return
        }
        withAnimation(KoumMotion.breathEase) { revealed = 1 }
        withAnimation(KoumMotion.breathEase.delay(0.4)) { revealed = 2 }
        withAnimation(KoumMotion.breathEase.delay(0.8)) { revealed = 3 }
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(1)) {
            ctaGlow = true
        }
    }

    // MARK: - Background: the painted dawn

    private var dawnBackground: some View {
        ZStack {
            KoumColor.night.ignoresSafeArea()
            GeometryReader { geo in
                Image("PaywallDawn")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .ignoresSafeArea()

            // Keep the top calm for the headline, the bottom firm for the ask.
            LinearGradient(
                stops: [
                    .init(color: KoumColor.night.opacity(0.55), location: 0),
                    .init(color: KoumColor.night.opacity(0.25), location: 0.35),
                    .init(color: KoumColor.night.opacity(0.45), location: 0.62),
                    .init(color: KoumColor.night.opacity(0.92), location: 0.95),
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 0) {
            Image("AppIconArt")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(KoumColor.bone.opacity(0.14), lineWidth: 1)
                )
                .shadow(color: KoumColor.night.opacity(0.5), radius: 10, y: 3)
                .padding(.top, KoumSpacing.xl)
                .padding(.bottom, KoumSpacing.sm)
                .opacity(revealed >= 1 ? 1 : 0)
                .accessibilityHidden(true)

            Text("KOUM")
                .font(KoumType.micro)
                .kerning(3.5)
                .foregroundStyle(KoumColor.bone.opacity(0.8))
                .padding(.bottom, KoumSpacing.xl)
                .opacity(revealed >= 1 ? 1 : 0)

            Text(app.userName.isEmpty
                 ? "Tomorrow morning,\neverything changes."
                 : "\(app.userName),\ntomorrow morning\neverything changes.")
                .font(KoumType.display)
                .koumLineSpacing(7)
                .foregroundStyle(KoumColor.bone)
                .multilineTextAlignment(.center)
                .shadow(color: KoumColor.night.opacity(0.8), radius: 14, y: 2)
                .opacity(revealed >= 1 ? 1 : 0)
                .offset(y: revealed >= 1 ? 0 : 8)

            Text(app.onboardingMotivation.isEmpty
                 ? "The alarm your Bible turns off."
                 : "You said you wanted to feel \(app.onboardingMotivation). It starts with one kept morning.")
                .font(KoumType.body)
                .koumLineSpacing(5)
                .foregroundStyle(KoumColor.bone.opacity(0.85))
                .multilineTextAlignment(.center)
                .shadow(color: KoumColor.night.opacity(0.8), radius: 10, y: 1)
                .padding(.top, KoumSpacing.md)
                .padding(.bottom, KoumSpacing.xl)
                .opacity(revealed >= 1 ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - What they're keeping

    private var valueRows: some View {
        VStack(alignment: .leading, spacing: KoumSpacing.md) {
            valueRow(glyph: .sunrise, text: "An alarm that rings through Silent, every chosen morning")
            valueRow(glyph: .book, text: "Scripture as the only way to turn it off")
            valueRow(glyph: .check, text: "A verse, a prayer, your journal. A streak of kept mornings")
        }
        .padding(KoumSpacing.md + KoumSpacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(KoumColor.night.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(KoumColor.bone.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.bottom, KoumSpacing.lg)
        .opacity(revealed >= 2 ? 1 : 0)
        .offset(y: revealed >= 2 ? 0 : 8)
    }

    private func valueRow(glyph: KoumGlyph, text: String) -> some View {
        HStack(alignment: .center, spacing: KoumSpacing.md) {
            GlyphView(glyph: glyph, size: 20)
                .frame(width: 24)
            Text(text)
                .font(KoumType.smallLabel)
                .foregroundStyle(KoumColor.bone)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Packages

    private var yearlyPackage: Package? { subscriptions.yearlyPackage }
    private var weeklyPackage: Package? { subscriptions.weeklyPackage }

    private var yearlyPrice: String { yearlyPackage?.localizedPriceString ?? "$29.99" }
    private var weeklyPrice: String { weeklyPackage?.localizedPriceString ?? "$3.99" }

    /// The yearly price handed back per week, floored to the cent so it
    /// always reads at its cheapest honest value.
    private var weeklyEquivalent: String {
        guard let yearly = yearlyPackage?.storeProduct.price else { return "$0.57" }
        let weekly = floor((yearly as NSDecimalNumber).doubleValue / 52 * 100) / 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = yearlyPackage?.storeProduct.priceFormatter?.locale ?? .current
        return formatter.string(from: NSNumber(value: weekly)) ?? "$0.57"
    }

    private var packages: some View {
        VStack(spacing: KoumSpacing.sm) {
            // Yearly: the intended choice, dressed for it.
            Button {
                KoumHaptics.selection()
                selectedYearly = true
            } label: {
                VStack(alignment: .leading, spacing: KoumSpacing.xs) {
                    HStack {
                        Text("Yearly")
                            .font(KoumType.label)
                            .foregroundStyle(KoumColor.bone)
                        Spacer()
                        Text((trialDays.map { "\($0) DAYS FREE" } ?? "BEST VALUE"))
                            .font(KoumType.micro)
                            .kerning(1.1)
                            .foregroundStyle(KoumColor.night)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(KoumColor.firstlight))
                    }
                    HStack(alignment: .firstTextBaseline, spacing: KoumSpacing.xs) {
                        Text(weeklyEquivalent)
                            .font(KoumType.title)
                            .foregroundStyle(KoumColor.bone)
                        Text("per week")
                            .font(KoumType.caption)
                            .foregroundStyle(KoumColor.boneMuted)
                    }
                    Text("\(yearlyPrice) billed once a year")
                        .font(KoumType.caption)
                        .foregroundStyle(KoumColor.boneMuted)
                }
                .padding(KoumSpacing.md + KoumSpacing.xs)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(KoumColor.nightRaised.opacity(0.92))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(selectedYearly ? KoumColor.firstlight : KoumColor.nightEdge,
                                        lineWidth: selectedYearly ? 1.5 : 1)
                        )
                        .shadow(color: selectedYearly ? KoumColor.firstlight.opacity(0.22) : .clear,
                                radius: 20, y: 4)
                )
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(selectedYearly ? .isSelected : [])

            // Weekly: present, quiet.
            Button {
                KoumHaptics.selection()
                selectedYearly = false
            } label: {
                HStack {
                    Text("Weekly")
                        .font(KoumType.smallLabel)
                        .foregroundStyle(KoumColor.bone)
                    Spacer()
                    Text("\(weeklyPrice)/week")
                        .font(KoumType.smallLabel)
                        .foregroundStyle(KoumColor.boneMuted)
                }
                .padding(.horizontal, KoumSpacing.md + KoumSpacing.xs)
                .padding(.vertical, KoumSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(KoumColor.nightRaised.opacity(0.75))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(!selectedYearly ? KoumColor.firstlight : KoumColor.nightEdge,
                                        lineWidth: !selectedYearly ? 1.5 : 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(!selectedYearly ? .isSelected : [])
        }
        .animation(KoumMotion.quickEase, value: selectedYearly)
        // Clear the pinned footer so the weekly option is never buried.
        .padding(.bottom, KoumSpacing.xl)
        .opacity(revealed >= 3 ? 1 : 0)
        .offset(y: revealed >= 3 ? 0 : 8)
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
                return "Free for \(trialDays) days, then \(yearlyPrice) a year. Cancel anytime."
            }
            return "\(yearlyPrice) per year. Cancel anytime."
        }
        return "\(weeklyPrice) per week. Cancel anytime."
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Button(ctaLabel) { purchase() }
                .buttonStyle(.koumPrimary)
                .disabled(purchasing)
                .shadow(color: KoumColor.firstlight.opacity(ctaGlow ? 0.35 : 0.12),
                        radius: 22, y: 4)
                .padding(.bottom, KoumSpacing.sm)

            Text(reassurance)
                .font(KoumType.caption)
                .foregroundStyle(KoumColor.boneMuted)
                .padding(.bottom, KoumSpacing.md)

            HStack(spacing: 0) {
                Button("Restore") {
                    Task {
                        try? await subscriptions.restore()
                        if subscriptions.isSubscribed { onUnlocked() }
                    }
                }
                .frame(maxWidth: .infinity)
                Link("Terms", destination: KoumConfig.termsURL)
                    .frame(maxWidth: .infinity)
                Link("Privacy", destination: KoumConfig.privacyPolicyURL)
                    .frame(maxWidth: .infinity)
            }
            .font(KoumType.caption)
            .foregroundStyle(KoumColor.boneFaint)
            .frame(maxWidth: 300)
            .padding(.bottom, KoumSpacing.md)

            Text("Renews automatically. Cancel anytime in your Apple ID settings, at least a day before renewal. Your prayers and journal never leave your phone.")
                .font(.system(size: 10))
                .foregroundStyle(KoumColor.boneFaint.opacity(0.75))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, KoumSpacing.md)
        }
        .padding(.horizontal, KoumSpacing.margin)
        .padding(.top, KoumSpacing.md)
        .padding(.bottom, KoumSpacing.sm)
        .background(
            LinearGradient(
                colors: [KoumColor.night.opacity(0), KoumColor.night.opacity(0.95), KoumColor.night],
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
