import Foundation
import Observation
import RevenueCat

/// RevenueCat wrapper. One entitlement (`koum_pro`) unlocks everything.
///
/// **Fail open.** If the entitlement check fails on a network error, treat
/// the user as subscribed — a paying user whose alarm refuses to work because
/// RevenueCat was unreachable at 6am is the worst failure mode this app has.
@Observable
@MainActor
final class SubscriptionManager {

    private(set) var isSubscribed = false
    private(set) var isInTrial = false
    private(set) var trialEndsAt: Date?
    private(set) var currentOffering: Offering?
    private(set) var allOfferings: Offerings?
    private(set) var lastError: String?

    /// True once RevenueCat is configured (a key is present).
    let isConfigured: Bool

    init() {
        isConfigured = !KoumConfig.revenueCatAPIKey.isEmpty
        if isConfigured {
            Purchases.logLevel = .info
            Purchases.configure(
                with: Configuration.Builder(withAPIKey: KoumConfig.revenueCatAPIKey)
                    .with(storeKitVersion: .storeKit2)
                    .build()
            )
        } else {
            // No key yet (pre-configuration builds): unlock in DEBUG so the
            // app is fully testable; stay locked in Release.
            #if DEBUG
            isSubscribed = true
            #endif
        }
    }

    func refresh() async {
        guard isConfigured else { return }
        do {
            let info = try await Purchases.shared.customerInfo()
            update(with: info)
        } catch {
            // Fail open on network error — never lock out a paying user
            // because their phone had no signal at 6am.
            if !isSubscribed { isSubscribed = true }
        }
    }

    func loadOffering() async {
        guard isConfigured else { return }
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
            allOfferings = offerings
        } catch {
            lastError = "Couldn't load plans. Check your connection."
        }
    }

    func purchase(_ package: Package) async throws {
        let result = try await Purchases.shared.purchase(package: package)
        guard !result.userCancelled else { return }
        update(with: result.customerInfo)
    }

    func restore() async throws {
        guard isConfigured else { return }
        let info = try await Purchases.shared.restorePurchases()
        update(with: info)
    }

    func setAttributes(_ attributes: [String: String]) {
        guard isConfigured else { return }
        Purchases.shared.attribution.setAttributes(attributes)
    }

    // MARK: - Offering helpers

    var yearlyPackage: Package? {
        currentOffering?.availablePackages.first {
            $0.storeProduct.productIdentifier == KoumConfig.yearlyProductID
        } ?? currentOffering?.annual
    }

    var weeklyPackage: Package? {
        currentOffering?.availablePackages.first {
            $0.storeProduct.productIdentifier == KoumConfig.weeklyProductID
        } ?? currentOffering?.weekly
    }

    /// The one-time exit offer, wherever it lives across offerings. Nil until
    /// the promo product exists in App Store Connect + RevenueCat.
    var promoYearlyPackage: Package? {
        allOfferings?.all.values
            .flatMap(\.availablePackages)
            .first { $0.storeProduct.productIdentifier == KoumConfig.promoYearlyProductID }
    }

    /// Free-trial length (in days) on the yearly product, or nil when the
    /// product carries no free-trial introductory offer. Every screen that
    /// mentions a trial must key off this — no offer, no trial language.
    var yearlyTrialDays: Int? {
        guard isConfigured else {
            #if DEBUG
            return 3 // design-preview default in unconfigured dev builds
            #else
            return nil
            #endif
        }
        guard let intro = yearlyPackage?.storeProduct.introductoryDiscount,
              intro.paymentMode == .freeTrial else { return nil }
        let period = intro.subscriptionPeriod
        switch period.unit {
        case .day: return period.value
        case .week: return period.value * 7
        case .month: return period.value * 30
        case .year: return period.value * 365
        @unknown default: return nil
        }
    }

    private func update(with info: CustomerInfo) {
        let entitlement = info.entitlements[KoumConfig.entitlementID]
        isSubscribed = entitlement?.isActive == true
        isInTrial = entitlement?.periodType == .trial
        trialEndsAt = entitlement?.expirationDate
    }
}
