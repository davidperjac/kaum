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

    private func update(with info: CustomerInfo) {
        let entitlement = info.entitlements[KoumConfig.entitlementID]
        isSubscribed = entitlement?.isActive == true
        isInTrial = entitlement?.periodType == .trial
        trialEndsAt = entitlement?.expirationDate
    }
}
