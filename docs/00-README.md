# Koum

**The alarm you turn off with your Bible.**

An iOS alarm clock that will not stop ringing until you have demonstrably opened Scripture — by scanning the page, reciting it aloud, or typing it out. Then it walks you through a short prayer, a devotional, and a journal entry. Under four minutes, every morning.

---

## The documents

| File | Contents |
|---|---|
| **01-product-spec.md** | Positioning, competitive analysis, all features, core loop, technical architecture, v1 scope, App Store listing |
| **02-onboarding-and-paywall.md** | 16-screen onboarding with full copy, live demo mechanics, paywall design, trial flow, win-back |
| **03-design-system.md** | Palette, typography, spacing, components, signature elements, motion, voice |
| **04-brand-and-mascot.md** | Name rationale, wordmark, app icon, Wren the mascot, where warmth lives |
| **05-revenuecat-config.md** | Pricing, entitlements, App Store Connect setup, RevenueCat offerings, implementation, compliance |
| **06-verification-engine.md** | OCR pipeline, matching algorithm, LLM escalation, escape hatch, test set, telemetry |

---

## Three things that changed from the original plan

**1. AlarmKit exists now.** iOS 26 gave third-party apps real system-level alarms that ring through Silent and Focus modes. The single biggest technical risk in the original plan — unreliable background alarms — is gone. The cost is an iOS 26 minimum deployment target. Take that trade.

**2. There are direct competitors already shipping.** Bible Alarm, Rise, Bible Alarm: Christian Clock, and Shine are all live. This validates the market, and it means "Christian alarm app" is no longer the differentiator. **Verification is.** Bible Alarm's "Bible Photo" practice almost certainly just checks that a photo was taken. Koum actually checks the passage. That is the entire wedge — build the listing, the demo, and the product around it.

**3. Weekly pricing carries specific risk here.** This audience reacts badly to feeling monetized inside something sacred, and both leading competitors are free to download. Weekly stays in the offering but positioned quietly, with monthly worth testing as the alternative secondary tier.

---

## Build order

**Days 1–2 — Verification foundation**
Photograph 200 real Bible pages under real conditions. Build the OCR pipeline, the normalizer, and the local matcher. Tune until first-attempt pass rate clears 70%. Nothing else matters until this works.

**Days 3–4 — Alarm**
AlarmKit integration, scheduling, the ringing screen, the handoff into verification, all three modes wired end to end.

**Days 5–6 — The morning flow**
Prayer, devotional, journal, streaks. Load the 120 pre-written devotionals.

**Days 7–8 — Onboarding & paywall**
All 16 screens. The live demo at screen 7 is the highest-value screen in the app — build it properly. RevenueCat wiring.

**Days 9–10 — Polish**
Dawn gradient, verification bloom, haptics, widgets, Dynamic Type, VoiceOver.

**Days 11–12 — Content & assets**
Human-edit every devotional. Icon, Wren poses, screenshots, the 15-second preview video.

**Days 13–14 — Buffer**
Real-device testing across lighting conditions. Submit.

---

## The two things that decide whether this works

**Scan reliability.** If it fails on thin paper in dim light, the reviews say "doesn't work" and the app is dead. Forty percent of engineering time belongs here. Bias every threshold toward passing — a false pass costs nothing, a false fail costs a customer.

**Devotional quality.** Generic AI devotionals will get Koum dismissed by exactly the audience it needs. Human-edit all 120, or adapt public-domain material from Spurgeon or Matthew Henry, which reads as more substantial anyway and costs nothing.

---

## The demo

Fifteen seconds. Dark room. Alarm blaring. A hand reaches for a physical Bible, opens it, holds up a phone. Scan. **Silence.** Checkmark.

No voiceover. No music. No text overlay beyond one line.

The cut to silence is the hook, and it is the reason this is worth building — the ad films itself, and no competitor can shoot it because none of them actually verify.
