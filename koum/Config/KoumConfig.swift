import Foundation

/// Central configuration. Everything an operator needs to touch before shipping
/// lives in this one file — API keys, product identifiers, and feature flags.
enum KoumConfig {

    // MARK: - RevenueCat

    /// RevenueCat public SDK key (starts with `appl_`). Empty string disables
    /// RevenueCat configuration; the app then treats the user as subscribed in
    /// DEBUG and unsubscribed in Release.
    static let revenueCatAPIKey = "appl_qRlVEgbJmEwWHAPJURjKrxafPTt"

    /// The single entitlement every paid product unlocks.
    static let entitlementID = "koum_pro"

    /// Product identifiers as created in App Store Connect.
    static let yearlyProductID = "dptech.koum.yearly"
    static let weeklyProductID = "dptech.koum.weekly"

    /// The one-time exit offer (discounted first year). Not yet created in
    /// App Store Connect / RevenueCat; the promo screen shows fallback copy
    /// until this product exists in an offering.
    static let promoYearlyProductID = "dptech.koum.yearly.promo"

    // MARK: - Verification escalation (Gemini Flash)

    /// Google Generative Language API key. Empty string disables LLM
    /// escalation entirely — the local matcher then uses its offline
    /// thresholds, which is a fully supported mode.
    static let geminiAPIKey = ""

    static let geminiModel = "gemini-2.5-flash"

    /// Hard timeout for the escalation call. The user is standing in the dark;
    /// never make them wait on a network call.
    static let escalationTimeout: TimeInterval = 3.0

    // MARK: - CloudKit

    /// Flip to `true` after enabling the iCloud capability + container.
    /// Models are written CloudKit-compatible; this is the only switch.
    static let cloudKitSyncEnabled = false

    // MARK: - App Group (widgets)

    static let appGroupID = "group.dptech.koum"

    // MARK: - Legal

    static let privacyPolicyURL = URL(string: "https://koum.app/privacy")!
    static let termsURL = URL(string: "https://koum.app/terms")!

    // MARK: - Product rules

    /// Minutes after alarm time during which completing verification keeps the
    /// streak.
    static let graceWindowMinutes = 30

    /// Snoozes allowed per morning, 5 minutes each. After that, verification
    /// is the only exit.
    static let maxSnoozes = 2
    static let snoozeMinutes = 5
}
