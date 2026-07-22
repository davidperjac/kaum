# Koum — RevenueCat & Monetization

---

## 1. Pricing

### Recommended launch pricing

| Product | Price | Trial | Notes |
|---|---|---|---|
| **Yearly** | $29.99/yr | 7 days free | Primary. Pre-selected. |
| **Weekly** | $3.99/wk | None | Secondary, present but quiet |
| **Lifetime** | $79.99 | None | v1.1, not at launch |

$29.99/yr = $2.50/month. Show that number on the paywall; it reframes the annual price as small.

### On weekly pricing — read this before committing

You planned weekly + yearly. Weekly converts well and is standard in the alarm-app category. But there is a specific risk in **this** market that does not apply to a push-up alarm app.

**The concern:** Christian audiences are unusually sensitive to feeling monetized inside something they consider sacred. $3.99/week is $207/year for an app that mostly rings and reads a page. When a user does that arithmetic — and in this category they do, and then they post about it — the reaction is not "expensive," it is "predatory." Reviews in Christian apps that use aggressive weekly pricing frequently use words like *taking advantage* and *shameful*. That is reputational damage that outlives the revenue.

**A second factor:** both leading competitors (Bible Alarm, Rise) are **free to download** with premium upgrades. Koum is asking for more, earlier, in a market where the alternative costs nothing to try.

**Recommendation:** keep weekly, but position it as the *inconvenient* option rather than the aggressive one.

- Yearly always pre-selected and visually dominant
- Weekly presented plainly, no trial, no emphasis
- Never make weekly the default or the highlighted tier
- Never run a weekly-only paywall

**Consider testing monthly at $5.99 as the middle tier** instead of leaning on weekly. Lower ARPU per conversion, materially better sentiment, and better long-term retention in a market where word of mouth travels through churches and group chats.

### Regional pricing

Global market, and Christianity's largest growth regions are not high-ARPU markets. Use App Store price tiers roughly proportional to local purchasing power:

| Region | Yearly |
|---|---|
| US, CA, UK, AU, Western EU | $29.99 |
| Eastern EU, Latin America | $14.99 |
| Brazil, Mexico, Philippines | $9.99 |
| India, Nigeria, Kenya, Indonesia | $6.99 |

Nigeria, Kenya, Brazil, the Philippines, and Indonesia have enormous, young, mobile-first Christian populations. At $29.99 you convert essentially none of them. At $6.99 you convert a meaningful share, and those markets are where the organic TikTok reach will be cheapest.

---

## 2. Entitlement

**One entitlement: `koum_pro`**

Do not create tiers. Every paid product unlocks everything. Tiering a four-feature app creates complexity with no revenue upside.

```
Entitlement: koum_pro
  ├── koum_yearly    (com.koum.app.yearly)
  ├── koum_weekly    (com.koum.app.weekly)
  └── koum_lifetime  (com.koum.app.lifetime)   [v1.1]
```

---

## 3. App Store Connect setup

### Subscription group
`Koum Premium` — one group. All auto-renewables inside it, so upgrades and downgrades are handled natively by Apple.

### Products

**Yearly**
```
Product ID:       com.koum.app.yearly
Reference name:   Koum Yearly
Duration:         1 year
Price:            $29.99 (Tier 30)
Intro offer:      7 days free trial, new subscribers only
Group level:      1
Display name:     Yearly
Description:      Full access to Koum. 7 days free.
```

**Weekly**
```
Product ID:       com.koum.app.weekly
Reference name:   Koum Weekly
Duration:         1 week
Price:            $3.99 (Tier 4)
Intro offer:      None
Group level:      2
Display name:     Weekly
Description:      Full access to Koum, billed weekly.
```

**Level 1 for yearly** means users on weekly can upgrade to yearly and Apple treats it as an upgrade with immediate proration. Get this right at setup; changing it later is painful.

### Promotional offers

Configure at launch even if unused until win-back campaigns exist:

```
winback_50        50% off first year        For cancelled trials
comeback_free     1 month free              For lapsed subscribers
church_partner    3 months free             For church/ministry partnerships
```

`church_partner` is worth having ready. Church-level distribution — a pastor mentioning it, a small group adopting it together — is a real channel in this market and it moves in bulk.

---

## 4. RevenueCat dashboard

### Project
```
Project:  Koum
App:      Koum iOS
Bundle:   com.koum.app
```

Upload the App Store Connect shared secret and the in-app purchase key, and enable server-to-server notifications (App Store Connect → App Information → App Store Server Notifications → V2 → RevenueCat's URL).

### Offerings

**`default`** — the standard paywall
```
Packages:
  $rc_annual   → com.koum.app.yearly   [default, highlighted]
  $rc_weekly   → com.koum.app.weekly
```

**`winback`** — post-cancellation
```
Packages:
  $rc_annual   → com.koum.app.yearly + winback_50
```

**`monthly_test`** — for the pricing experiment
```
Packages:
  $rc_annual   → com.koum.app.yearly
  $rc_monthly  → com.koum.app.monthly
```

Always fetch the offering by the `current` designation, never by hardcoded product ID. That is what makes remote price experiments possible without a build.

### Experiments to run

1. **Weekly vs. monthly as the secondary tier** — the important one. Measure not just conversion but 90-day retention and review sentiment.
2. **$29.99 vs. $39.99 yearly**
3. **7-day vs. 3-day trial**
4. **Paywall headline:** "Start tomorrow morning." vs. "Wake up with purpose."

Run one at a time, minimum two weeks each.

---

## 5. Implementation

### Setup

```swift
import RevenueCat

@main
struct KoumApp: App {
    init() {
        Purchases.logLevel = .info
        Purchases.configure(
            with: Configuration.Builder(withAPIKey: "appl_XXXXXXXX")
                .with(storeKitVersion: .storeKit2)
                .build()
        )
    }
}
```

**No `appUserID`.** Koum has no accounts. RevenueCat's anonymous ID plus Apple's receipt handles restore across devices on the same Apple ID, which is exactly the no-auth architecture the product wants.

### Subscription state

```swift
@Observable
final class SubscriptionManager {
    private(set) var isSubscribed = false
    private(set) var isInTrial = false
    private(set) var trialEndsAt: Date?

    static let shared = SubscriptionManager()

    func refresh() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            update(with: info)
        } catch {
            // Fail open on network error — never lock out a paying user
            // because their phone had no signal at 6am
        }
    }

    private func update(with info: CustomerInfo) {
        let entitlement = info.entitlements["koum_pro"]
        isSubscribed = entitlement?.isActive == true
        isInTrial = entitlement?.periodType == .trial
        trialEndsAt = entitlement?.expirationDate
    }
}
```

**Fail open.** If the entitlement check fails due to network error, treat the user as subscribed. A paying user whose alarm refuses to work because RevenueCat was unreachable will leave a one-star review and never come back. The revenue lost to occasional free access is trivially small next to that.

### Purchase

```swift
func purchase(_ package: Package) async throws {
    let result = try await Purchases.shared.purchase(package: package)
    guard !result.userCancelled else { return }
    update(with: result.customerInfo)
}

func restore() async throws {
    let info = try await Purchases.shared.restorePurchases()
    update(with: info)
}
```

### Paywall gating

The paywall sits between onboarding screen 14 and the app. Gate at the app root, not per-feature — every feature is behind `koum_pro`.

```swift
var body: some View {
    if !hasCompletedOnboarding {
        OnboardingFlow()
    } else if !subscriptions.isSubscribed {
        PaywallView()
    } else {
        HomeView()
    }
}
```

**Critical exception — the alarm always fires.** If a subscription lapses while an alarm is scheduled, the alarm must still ring and must still be dismissible. Show the paywall *after* dismissal, never instead of it. An alarm app that silently stops ringing because a payment failed is a genuinely harmful failure mode — someone misses work.

```swift
// In the alarm flow, never gate dismissal
func handleAlarmFired() {
    // Always allow verification and dismissal
    presentVerification()
    // Paywall only after the morning is complete
}
```

---

## 6. Attribution

```swift
Purchases.shared.attribution.setAttributes([
    "onboarding_frequency": frequencyAnswer,   // screen 3
    "onboarding_blocker":   blockerAnswer,     // screen 4
    "onboarding_motivation": motivationAnswer, // screen 5
    "verification_mode":    selectedMode,      // screen 8
    "alarm_time":           alarmTimeString    // screen 9
])
```

These let you segment conversion and retention by declared behaviour. The most valuable question this answers: **do scan-mode users retain better than type-mode users?** If scan retains meaningfully better, push harder toward scan in onboarding. If it retains worse, your scan reliability has a problem and the data will show it before the reviews do.

For TikTok attribution, set the install source via `Purchases.shared.attribution.setMediaSource()`.

---

## 7. Targets

| Metric | Target | Notes |
|---|---|---|
| Install → trial | 20%+ | Watch closely — competitors are free |
| Trial → paid | 35%+ | Above category average; the demo earns this |
| Yearly share of conversions | 70%+ | If lower, weekly is too prominent |
| M1 retention (paid) | 85%+ |  |
| M6 retention (paid) | 55%+ |  |
| Refund rate | < 2% | Above 3% = scan reliability problem |
| Net revenue / install | $1.50+ |  |

**Watch refund rate obsessively in week one.** In an alarm app, refunds are the fastest signal that verification is failing in the real world. A spike in refunds means the scan pipeline is breaking on real Bibles in real bedrooms, and you should ship a threshold loosening immediately.

**Sanity check on scale:** at $29.99/yr with ~30% net after Apple's cut and refunds, roughly 250 active yearly subscribers is $500/mo net. That is a realistic first-quarter target for a well-marketed indie app in a validated category, and it is the right order of magnitude to be aiming at — not a million-dollar business, a real side-project income.

---

## 8. Compliance

App Review rejects paywalls for these constantly:

- [ ] Price, currency, and billing period visible before purchase
- [ ] Trial length and post-trial price stated plainly on the same screen
- [ ] **Restore Purchases** button present and functional
- [ ] Terms of Use and Privacy Policy linked from the paywall
- [ ] Close button visible and reachable (after ≤3s delay)
- [ ] Auto-renewal disclosure present
- [ ] No dark patterns — no fake timers, no disguised close buttons

**Required text block on the paywall (small, legible):**

> Payment is charged to your Apple ID at confirmation. Subscription renews automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel in your Apple ID settings.

**Apple-specific note for this app:** because Koum uses AlarmKit and gates behind a hard paywall, make sure a reviewer with no subscription can still complete the onboarding demo. If a reviewer hits a wall before experiencing the product, rejection risk rises significantly. The onboarding demo at screen 7 is free by design — keep it that way.
