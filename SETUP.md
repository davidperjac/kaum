# Koum — Configuration handoff

All code is complete and building. Everything below is **operator configuration** —
no code changes required for any of it. The single file you will touch is
`koum/Config/KoumConfig.swift`.

## 1. Keys (`koum/Config/KoumConfig.swift`)

| Constant | What to put there | Behavior while empty |
|---|---|---|
| `revenueCatAPIKey` | RevenueCat public key (`appl_…`) | DEBUG builds act subscribed; Release stays locked at paywall (purchase button lets a reviewer/dev through only when unconfigured) |
| `geminiAPIKey` | Google Generative Language API key | Scan verification runs fully offline with lowered thresholds (0.45) — completely supported mode |
| `cloudKitSyncEnabled` | Set `true` **after** step 4 | Local-only storage |

## 2. App Store Connect

Follow `docs/05-revenuecat-config.md` §3 exactly, with these product IDs
(they match the bundle ID `dptech.koum`, not the doc's `com.koum.app`):

- Subscription group `Koum Premium`
  - `dptech.koum.yearly` — $29.99/yr, 7-day free trial, group level 1
  - `dptech.koum.weekly` — $3.99/wk, no trial, group level 2
- Promotional offers per the doc (`winback_50`, `comeback_free`, `church_partner`)
- Regional pricing table per the doc §1

## 3. RevenueCat dashboard

- Project **Koum**, iOS app, bundle `dptech.koum`
- One entitlement: **`koum_pro`** — attach both products
- Offering `default`: `$rc_annual` → yearly (default), `$rc_weekly` → weekly
- Upload App Store Connect shared secret / IAP key; enable Server Notifications V2
- The paywall resolves packages by product ID first, then falls back to
  `offering.annual` / `offering.weekly` package types — either mapping works.

## 4. Signing & capabilities (Xcode, one-time)

Both targets already reference entitlements files with App Group
`group.dptech.koum`:

- In Signing & Capabilities for **koum** and **KoumWidgets**: confirm the App
  Group `group.dptech.koum` registers with your team (automatic signing
  usually does this on first device build).
- Optional CloudKit: add the iCloud capability (CloudKit, private database,
  default container) to the **koum** target, then flip
  `KoumConfig.cloudKitSyncEnabled = true`. Models are already
  CloudKit-compatible.

## 5. Legal URLs

`KoumConfig.privacyPolicyURL` / `termsURL` currently point at
`https://koum.app/privacy` and `/terms`. Host real pages there (or change the
URLs). App Review checks that both links resolve.

## 6. Before submission

- Audition the six synthesized alarm sounds in `koum/Resources/Sounds/`
  (Settings → alarm → Sound previews them in-app). They are shippable;
  replace the `.caf` files 1:1 if you commission real audio (30s, CAF/AAC,
  same filenames).
- Real-device testing of scan verification across Bibles/lighting per
  `docs/06-verification-engine.md` §11 — thresholds live in
  `LocalMatcher` (`passThreshold` 0.55; lower before raising, never above 0.65).
- App Store listing text/keywords/screenshot plan: `docs/01-product-spec.md` §14.
- The social-proof onboarding screen is intentionally not shipped (no real
  reviews yet) — the flow goes summary → paywall directly, per docs.

## What's already handled in code

- AlarmKit scheduling/observation, system-alert handoff ("Open Bible" opens
  straight into verification), snooze capped at 2×5min, alarm never gated by
  subscription state, escape hatch at every stage.
- All three verification modes, on-device first; Gemini escalation is
  text-only with a 3s timeout and a "what passage is this?" prompt shape.
- 365-day curated plan with hand-reviewed anchors; full KJV + WEB bundled;
  reading plans (Psalms/Proverbs/John/Romans) with runtime anchors.
- 120 Spurgeon-adapted devotionals (doctrinally screened, validated).
- Prayer log with "Answered" marking, journal + calendar archive + search +
  "On this day", streaks with monthly auto-freeze and milestone cards.
- 15-screen onboarding with live demo (auto-passes after 2 failed attempts,
  never fails), hard paywall with compliance text, trial day-3/day-5 local
  notifications, Lock Screen/Home Screen widgets, alarm Live Activity.
- Unit tests: 23 tests covering the matcher, normalizer, streak rules, and
  bundle-content integrity (every plan day self-verifies against its own
  anchors in both translations).
