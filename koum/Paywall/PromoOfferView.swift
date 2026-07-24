import RevenueCat
import SwiftUI

/// Remembers whether the one-time exit offer has been spent. Once consumed
/// it is never shown again and the paywall's X disappears for good.
enum PromoOffer {
    private static let key = "promoOfferConsumed"

    static var consumed: Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    static func markConsumed() {
        UserDefaults.standard.set(true, forKey: key)
    }
}

/// The one-time exit offer: shown exactly once, when the user reaches for
/// the X on the paywall. A single discounted yearly, plainly framed as the
/// only time it will ever be offered. Declining marks it consumed forever.
struct PromoOfferView: View {
    @Environment(SubscriptionManager.self) private var subscriptions

    /// Called after a successful purchase (or pass-through in unconfigured
    /// developer builds).
    var onUnlocked: () -> Void
    /// Called when the user declines; the caller consumes the offer.
    var onDecline: () -> Void

    @State private var revealed = 0
    @State private var purchasing = false
    @State private var errorMessage: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Pricing

    private var promoPackage: Package? { subscriptions.promoYearlyPackage }

    private var promoPrice: String {
        promoPackage?.localizedPriceString ?? "$19.99"
    }

    private var fullPrice: String {
        subscriptions.yearlyPackage?.localizedPriceString ?? "$29.99"
    }

    /// "33% OFF", computed from the live prices when both exist.
    private var discountLabel: String {
        guard let promo = promoPackage?.storeProduct.price,
              let full = subscriptions.yearlyPackage?.storeProduct.price else {
            return "33% OFF"
        }
        let p = (promo as NSDecimalNumber).doubleValue
        let f = (full as NSDecimalNumber).doubleValue
        guard f > 0, p < f else { return "33% OFF" }
        return "\(Int((1 - p / f) * 100))% OFF"
    }

    private var promoWeekly: String {
        let base = (promoPackage?.storeProduct.price as NSDecimalNumber?)?.doubleValue ?? 19.99
        let weekly = floor(base / 52 * 100) / 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = promoPackage?.storeProduct.priceFormatter?.locale ?? .current
        return formatter.string(from: NSNumber(value: weekly)) ?? "$0.38"
    }

    var body: some View {
        ZStack {
            KoumColor.night.ignoresSafeArea()

            // A quiet ember below: the door is closing, but warmly.
            RadialGradient(
                colors: [KoumColor.firstlight.opacity(0.22), KoumColor.firstlight.opacity(0)],
                center: UnitPoint(x: 0.5, y: 1.15),
                startRadius: 0, endRadius: 420
            )
            .ignoresSafeArea()

            StarField(intensity: 0.35, meteors: false)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                MicroLabel(text: "Before you go", color: KoumColor.firstlight)
                    .padding(.top, KoumSpacing.xxl)
                    .padding(.bottom, KoumSpacing.md)
                    .opacity(revealed >= 1 ? 1 : 0)

                Text("One time.\nOnly now.")
                    .font(KoumType.display)
                    .koumLineSpacing(7)
                    .foregroundStyle(KoumColor.bone)
                    .opacity(revealed >= 1 ? 1 : 0)
                    .offset(y: revealed >= 1 ? 0 : 6)
                    .padding(.bottom, KoumSpacing.md)

                Text("Your alarm is built, your verse is chosen, and tomorrow is already on the calendar. So here is the one deal we ever make.")
                    .font(KoumType.body)
                    .koumLineSpacing(6)
                    .foregroundStyle(KoumColor.boneMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(revealed >= 2 ? 1 : 0)
                    .padding(.bottom, KoumSpacing.xl)

                // The offer card
                VStack(alignment: .leading, spacing: KoumSpacing.sm) {
                    HStack {
                        Text("Yearly")
                            .font(KoumType.label)
                            .foregroundStyle(KoumColor.bone)
                        Spacer()
                        Text(discountLabel)
                            .font(KoumType.micro)
                            .kerning(1.1)
                            .foregroundStyle(KoumColor.night)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(KoumColor.firstlight))
                    }
                    HStack(alignment: .firstTextBaseline, spacing: KoumSpacing.sm) {
                        Text(fullPrice)
                            .font(KoumType.body)
                            .strikethrough(true, color: KoumColor.boneFaint)
                            .foregroundStyle(KoumColor.boneFaint)
                        Text(promoPrice)
                            .font(KoumType.title)
                            .foregroundStyle(KoumColor.bone)
                        Text("for your first year")
                            .font(KoumType.caption)
                            .foregroundStyle(KoumColor.boneMuted)
                    }
                    Text("That's \(promoWeekly) a week for every kept morning.")
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
                                .stroke(KoumColor.firstlight, lineWidth: 1.5)
                        )
                        .shadow(color: KoumColor.firstlight.opacity(0.22), radius: 20, y: 4)
                )
                .opacity(revealed >= 2 ? 1 : 0)
                .offset(y: revealed >= 2 ? 0 : 8)

                Text("Close this and it's gone. Not hidden, not \u{201C}check back later.\u{201D} Gone.")
                    .font(KoumType.caption)
                    .foregroundStyle(KoumColor.boneMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, KoumSpacing.md)
                    .opacity(revealed >= 3 ? 1 : 0)

                Spacer()

                Button(purchasing ? "One moment…" : "Claim my year for \(promoPrice)") {
                    purchase()
                }
                .buttonStyle(.koumPrimary)
                .disabled(purchasing)
                .opacity(revealed >= 3 ? 1 : 0)
                .padding(.bottom, KoumSpacing.xs)

                Button("No thanks") {
                    KoumHaptics.buttonPress()
                    onDecline()
                }
                .buttonStyle(.koumGhost)
                .frame(maxWidth: .infinity)
                .opacity(revealed >= 3 ? 1 : 0)
                .padding(.bottom, KoumSpacing.sm)
            }
            .padding(.horizontal, KoumSpacing.margin)
        }
        .environment(\.koumTheme, KoumTheme(isDark: true))
        .preferredColorScheme(.dark)
        .onAppear { reveal() }
        .alert(errorMessage ?? "", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        }
    }

    private func reveal() {
        if reduceMotion { revealed = 3; return }
        withAnimation(KoumMotion.breathEase) { revealed = 1 }
        withAnimation(KoumMotion.breathEase.delay(0.4)) { revealed = 2 }
        withAnimation(KoumMotion.breathEase.delay(0.9)) { revealed = 3 }
    }

    private func purchase() {
        guard subscriptions.isConfigured else {
            // Pre-configuration build: let the developer through.
            onUnlocked()
            return
        }
        guard let package = promoPackage else {
            errorMessage = "This offer isn't available right now. Check your connection and try again."
            return
        }
        purchasing = true
        Task {
            defer { purchasing = false }
            do {
                try await subscriptions.purchase(package)
                if subscriptions.isSubscribed {
                    PromoOffer.markConsumed()
                    onUnlocked()
                }
            } catch {
                errorMessage = "The purchase didn't go through. You haven't been charged beyond what Apple shows."
            }
        }
    }
}
