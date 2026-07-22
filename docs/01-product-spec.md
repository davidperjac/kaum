# Koum — Product Specification

> **Working name:** Koum
> **Tagline:** *The alarm you turn off with your Bible.*
> **Platform:** iOS 26+ only (AlarmKit required)
> **Model:** Hard paywall, free trial, weekly + annual
> **v1 target:** 10–14 days to submission

---

## 0. Positioning

### The one-sentence pitch
Koum is an alarm clock that will not turn off until you have opened your Bible.

### The name
**Koum** — from Aramaic *ṭalitha koum* (Mark 5:41), "little girl, arise." Jesus speaking to a dead girl, telling her to get up. It is literally a wake-up command spoken by Christ.

- Pronounced "koom"
- Full brand lockup: **Koum — Wake up with purpose**
- App Store title: `Koum: Christian Alarm Clock`
- App Store subtitle: `Wake up with your Bible open`

**Spelling risk:** nobody can spell it from hearing it. Mitigate by always pairing with the tagline in marketing, and buying ASO keywords for `christian alarm`, `bible alarm`, `wake up with god`. The name does branding; the subtitle does discovery.

### Competitive reality — read this before building

The market has moved since this idea was first sketched. As of mid-2026 there are **direct competitors already shipping**:

| App | What it does | Where it's weak |
|---|---|---|
| **Bible Alarm** (biblealarm.app) | 13+ "morning practices" — guided prayer, Bible photo, sky photo, praise hands, smile selfie, jump for God. Free download + premium upgrade. Content-marketing SEO play with a real blog. | **Unfocused.** "Smile Selfie" and "Jump for God" dilute the Bible into one option among thirteen. Its Bible Photo practice is almost certainly *photo taken = done*, with no verification. Freemium, so no urgency. |
| **Rise Alarm Clock & Daily Verse** | Type out the verse to dismiss. CCM music. Wake-up tracker. | Typing only — no physical Bible, no camera moment, no visual demo. Free + IAP. Dated design. |
| **Bible Alarm: Christian Clock** (NEPHILIM LLC) | Arm alarm, "complete the verse," streaks. Explicitly advertises real iPhone system alarm access. | Thin. Verse completion is the whole product; no devotional, no journal, no prayer log. |
| **Shine – Bible Alarm** | Narrated verses + music as the alarm sound. | Passive. Nothing to complete. You can still roll over. Reviews complain about battery and volume. |
| **Spirit365 / Christian Alarm Clock 2** | Android-first, feature-stuffed, ad-supported. | Not competing for the same user. |

**What this means for Koum — three honest conclusions:**

1. **The market is validated.** People are shipping this and marketing it hard. Bible Alarm is running a full content-SEO operation with a blog. That is not what you do for a product that isn't converting.

2. **"Christian alarm app" is no longer the differentiator.** It's taken. The differentiator has to be *verification* — Koum is the only one that actually checks whether you read the verse. Everything in this spec bends toward that.

3. **The wedge is focus and rigor.** Bible Alarm is a grab-bag of thirteen cute practices. Koum does one thing: it does not stop ringing until Scripture has demonstrably been read. That's a sharper product, a sharper demo, and a sharper App Store listing.

### The moat, stated plainly
Anyone can build a Bible alarm. The defensible thing is **verse verification that works at 6am in bad light on a groggy user's first try.** That is an engineering problem, not a feature list. If Koum nails it and competitors keep shipping photo-taken-equals-done, Koum wins on the one review line that matters: *"it actually makes you do it."*

### The user
Primary persona is you: a Christian, 20–40, who has already decided they want a morning quiet time and keeps failing at it. Not a seeker. Not someone who needs convincing that Bible reading is good. **Someone who already believes it and can't execute.**

This matters because it determines the voice: Koum never persuades, never explains why Scripture is valuable, never evangelizes. It assumes the conviction is there and supplies only the mechanism. That assumption is the entire tone of the product.

### The pain, precisely
Not "I want to read the Bible more." That's a vitamin.
**"I keep breaking a promise I made to God and to myself, and I feel bad about it every single morning."** That's the painkiller. Recurring, specific, guilt-laden, and unresolved by willpower.

---

## 1. AlarmKit — the thing that changed

**Critical update to earlier planning:** iOS 26 shipped **AlarmKit**, which gives third-party apps the same alarm privileges as Apple's Clock app — full-screen alerts, sound that plays **through Silent mode and Focus modes**, Lock Screen presentation, and Dynamic Island integration.

This is enormous for Koum, and it changes the build in three ways:

**1. The old #1 risk is mostly gone.** Previous guidance said "you can't guarantee background alarm reliability, build a heavy Do Not Disturb onboarding flow." AlarmKit removes that. No persistent audio session hack, no silent-audio battery drain, no begging users to disable Focus. Skip that onboarding step entirely.

**2. iOS 26 minimum is non-negotiable.** AlarmKit does not exist before iOS 26. Set the deployment target to 26.0 and accept the smaller addressable base. Do not build a pre-26 fallback — a Christian alarm app that unreliably fails to ring is worse than no app.

**3. The alert UI is partly Apple's.** AlarmKit renders the alarm alert itself. Koum's custom verification flow happens *after* the user taps through into the app. Design for that handoff: Apple's alert → Koum's verse screen. The transition should feel continuous, not like two different apps.

**Implementation notes**
- Request the alarm authorization at the right moment in onboarding (Screen 12), not on launch
- Schedule-based alarms for wake times; snooze handled by AlarmKit's own controls where possible
- Alarms count toward a system-managed per-app limit — don't let users create unlimited alarms
- Users can revoke alarm permission in Settings → Notifications; detect this and show a recovery screen
- Maintain your own alarm state model alongside AlarmKit's for UI consistency

**Also worth noting:** competitors are already advertising "real iPhone system alarm access" as a selling point. It will be table stakes within months. Don't market on it — market on verification.

---

## 2. The core loop

```
   ALARM RINGS (AlarmKit, full screen, through Silent)
            ↓
   [ Tap into Koum ]
            ↓
   TODAY'S VERSE APPEARS  ──  large, alone, on a dark screen
            ↓
   ┌────────┴────────┬──────────────┐
   │        │        │              │
  SCAN    SPEAK    TYPE      ← user's choice, set in advance
   │        │        │              │
   └────────┬────────┴──────────────┘
            ↓
      ✓ VERIFIED — alarm silences
            ↓
   PRAY      (optional, skippable, ~60s)
            ↓
   DEVOTIONAL (2–3 paragraphs on today's verse)
            ↓
   JOURNAL   (one prompt, free text)
            ↓
   STREAK +1 — morning complete
```

**Design constraint that governs everything:** the user is at their least patient, least dexterous, and least tolerant point of the entire day. Every screen must be operable with one thumb, one eye open, in the dark.

**Time budget:** verification 15–40s, prayer 60s, devotional 90s, journal 45s. Full loop under 4 minutes. Advertise it as "3 minutes." A morning routine that takes 15 minutes will be abandoned by week two.

---

## 3. Feature: The Alarm

### Setup
- Multiple named alarms ("Weekdays", "Sunday")
- Time picker, repeat days
- Per-alarm: verification mode (scan / speak / type), verse source, sound
- **Grace window:** 30 minutes after alarm time to complete and keep the streak

### Sounds
Ship 6, no more:

| Name | Character |
|---|---|
| Dawn | Soft rising bell — the default |
| Chapel | Distant church bells |
| Morning Light | Gentle piano arpeggio |
| Rise | Firm, escalating tone for heavy sleepers |
| Choir | Wordless vocal swell |
| Classic | Standard alarm buzz for people who need it |

Escalating volume over 30 seconds. No worship songs with lyrics — you will hit licensing problems and it is not worth it for v1.

### Snooze
Allowed, but **capped at 2 snoozes of 5 minutes each.** After that, verification is the only exit.

Rationale: infinite snooze defeats the product. Zero snooze makes the app feel punitive and gets deleted. Two is the compromise, and the cap is itself a talking point.

### Verse selection
Three modes:
1. **Koum's plan** (default) — curated 365-day rotation of short, memorable, morning-appropriate verses
2. **Reading plan** — sequential through a book (Psalms, Proverbs, John, Romans)
3. **Custom** — user picks a book/chapter range to draw from

**Verse selection rules — these matter for verification success:**
- 1–3 verses maximum, never a long passage
- Prefer verses with distinctive noun phrases (helps fuzzy matching enormously)
- Avoid verses that appear near-identically in multiple places
- Avoid genealogies, law lists, anything numerically dense
- Skip verses that read as harsh or condemnatory as a *first* thought of the day — this is a wake-up app, not a rebuke

---

## 4. Feature: Verification (the core, spend your time here)

The user picks their preferred mode during onboarding and can change it per-alarm. **No mode is enforced. All three are first-class.**

### Mode A — Scan (the hero)

Point the camera at your open physical Bible. Koum reads the page and confirms the passage is there.

**Pipeline:**
```
Camera frame
    ↓
On-device Vision framework OCR (VNRecognizeTextRequest, .accurate)
    ↓
Local fuzzy match against target verse text
    ↓  (if confidence high → PASS immediately, no network)
    ↓  (if ambiguous → escalate)
LLM call: "What Bible reference is this text from?"
    ↓
Compare returned reference to target reference
    ↓
PASS / RETRY
```

**Why reference-matching, not text-matching:** Never ask the model *"is this John 3:16?"* — it will hallucinate agreement. Instead ask *"what passage is this?"* and compare the answer to your target. Far more robust, and it handles translation variance natively. KJV, NIV, ESV, NLT, NASB, CSB, and MSG diverge substantially in wording but all sit at the same reference.

**Robustness requirements — this is where the app is won or lost:**
- On-device OCR first, always. It is free, instant, offline, and handles the majority of cases.
- Two-column layouts are the norm in printed Bibles. Test against them specifically.
- Handle rotation, skew, shadow, thin paper bleed-through, and red-letter text.
- Match on **distinctive noun phrases**, not exact strings. "shepherd / not want" identifies Psalm 23 across every translation in English.
- Verse numbers in the OCR output are a strong signal — extract and weight them heavily.
- **Confidence threshold tuned to be generous.** A false pass costs nothing. A false fail costs a 1-star review.

**The escape hatch (mandatory):**
- Attempt 1–2: "Hmm, try again — get the whole page in frame"
- Attempt 3: "Having trouble? Move closer to a light."
- Attempt 4: **offer to switch to Type mode instantly**
- Attempt 5: **"I'll take your word for it"** — passes, logs the failure for your telemetry

The alarm must **never** become undismissable. This is both a user-trust issue and an App Store review risk — if a reviewer gets trapped, you get rejected.

### Mode B — Speak

Recite the verse aloud. On-device `SFSpeechRecognizer` transcribes; same fuzzy-match logic as scan.

- Works with a physical Bible, a digital one, or from memory
- **Passes at ~70% word match** — people misremember, and this is not a memorization test
- Advantage: speaking aloud wakes you up more than any other input
- Handle accents and grogginess with a generous threshold
- Fully on-device, no audio ever leaves the phone (say this in the UI — it matters to this audience)

### Mode C — Type

Type the verse. Shown on screen above the input.

- Not a memory test — the text is visible
- The act of typing is the wake-up mechanism
- Passes at ~85% character match, ignoring case and punctuation
- Guaranteed fallback that always works
- Long verses truncate to a reasonable typing length

### Cross-cutting

- **Offline:** scan and speak both work fully offline via on-device frameworks. Type always works. The LLM escalation is an enhancement, never a dependency.
- **Cost:** on-device-first means most mornings cost $0. Estimate under $0.02/user/month for the minority of scans that escalate.
- **Privacy:** camera frames used for OCR and discarded. Never stored, never uploaded unless escalation is needed, and then as text only — never the image.

---

## 5. Feature: Prayer

After verification. Skippable — always. Never guilt the user for skipping.

**Screen:** a prompt drawn from the day's verse ("Thank God for one thing before you get up") and two options:

**Voice prayer**
- Hold to record, release to stop
- Stored **on-device only** (this is spiritually intimate — say so explicitly in the UI)
- On-device transcription produces a text version for the log
- User can delete audio and keep text, or keep both

**Written prayer**
- Plain text field
- Same prompt

**Prayer log**
Chronological, notebook-styled. Scroll back through everything you have prayed. Entries can be marked **"Answered"** with a date — this is quietly one of the most powerful retention features in the app. Looking back at a prayer from four months ago and marking it answered is a genuinely moving experience, and it is the kind of thing users screenshot and share unprompted.

> **v1 scope note:** if you are cutting to hit 10 days, ship written prayer only and add voice in v1.1. Voice recording adds permissions, storage management, and a settings surface, and it is the least demoable feature in the app.

---

## 6. Feature: Devotional

2–3 short paragraphs on the day's verse. Under 250 words. Readable in 90 seconds.

**Structure:**
1. **Context** — one paragraph. What is happening here, who is speaking, to whom.
2. **Reflection** — one paragraph. What this means for an ordinary day.
3. **Today** — one or two sentences. Something concrete to carry.
4. **Related verses** — 2–3 cross-references, tappable to read inline.

### Content strategy — the honest version

This is a **content business, not a code problem**, and it is the second-biggest risk in the app after verification.

**Recommended approach for v1: pre-generated, human-edited, 120-day core.**
- Generate with an LLM, then read and edit every single one yourself
- 120 days covers the first four months; extend before anyone runs out
- Budget real time for this — a few full days of work, not an afternoon

**Why not runtime generation:** this audience has an unusually sharp ear for hollow spiritual language. LLM devotionals read as warm, vague, and slightly hollow — the exact failure mode that gets an app dismissed as "AI slop" in a Christian Twitter thread. And a runtime generation bug means a user opens a theologically wrong devotional at 6am with no review step.

**A strong alternative:** license or adapt public-domain devotional material. Spurgeon's *Morning and Evening*, Matthew Henry's commentary, Andrew Murray. Free, doctrinally substantial, and the older voice reads as *more* weighty rather than less. Lightly modernize the language. This is a genuine competitive edge over anything AI-generated, and it costs nothing.

### Doctrinal guardrails

Koum is **non-denominational and deliberately centrist.** Devotional content stays on ground shared across traditions:

**Safe:** God's character, gratitude, trust, perseverance, forgiveness, humility, God's faithfulness, prayer, love of neighbour.

**Avoid entirely:** eschatology, predestination vs. free will, baptism mode, spiritual gifts/cessationism, sacramental theology, church governance, political application, prosperity framing, anything about who is or isn't saved.

**Rule:** if two sincere Christians from different traditions would read a devotional and one would wince, cut it.

One theologically clumsy devotional screenshotted and shared is a genuinely bad week. Review every entry against this list.

### Translations

Ship KJV and WEB (both public domain) at minimum. **NIV, ESV, NLT, NASB, and CSB all require licensing** — do not ship them without permission. Verification works across all translations regardless, because it matches on reference, so users reading an NIV physical Bible are fully supported even if Koum displays KJV or WEB.

---

## 7. Feature: Journal

One prompt, one text field. Deliberately minimal.

**Prompts rotate and are anchored to the day's verse:**
- "What stood out to you?"
- "Where do you need this today?"
- "One line. What is God saying?"

**Rules:**
- No formatting, no tags, no folders, no photos in v1
- Autosaves
- No minimum length — one word is a complete entry
- Skippable

**Journal archive**
- Calendar view, completed days marked
- Tap a day to see: verse, prayer, journal entry together
- Search across entries
- **"On this day"** — surfaces last year's entry on the same date. Excellent long-term retention hook.

---

## 8. Feature: Streaks

The streak counts **mornings completed**, where complete = verification passed within the grace window. Prayer, devotional, and journal are optional and do not gate it.

**Rules:**
- Grace window: 30 minutes past alarm time
- **One freeze per month, automatic.** Miss a day, streak survives, user is told gently.
- No streak-loss shame. The copy on a broken streak is *"Start again tomorrow"* — never a red X, never a guilt message.

**Milestones:** 3, 7, 14, 30, 60, 100, 365 — each with a short verse and a shareable card.

**On shame:** this audience carries plenty already. Koum's job is to make consistency easy, not to punish inconsistency. A streak-loss screen that feels like a rebuke gets the app deleted. This is a real design principle, not a nicety — the emotional register of failure states is a competitive differentiator in a category full of guilt.

**Share cards:** streak milestone + verse + Koum mark, sized for Instagram Stories. Free organic distribution.

---

## 9. Home screen

Not a dashboard. One screen, three states.

**Evening / setup**
```
        Tomorrow, 6:30 AM
        ─────────────────
        Psalm 143:8
        "Let me hear in the morning
         of your steadfast love..."

        Scan · Change

        [   Alarm is set   ]

        ─────────────────
        🔥 12 mornings
```

**Morning, incomplete**
Straight into the verification flow. No home screen at all.

**Morning, complete**
```
        Good morning ✓
        ─────────────────
        You read Psalm 143:8
        You prayed
        You wrote

        🔥 13 mornings

        [ Read again ]  [ Journal ]
```

Then get out of the way. Koum is not an app people should spend time in — it is an app that gets them into a book and then out of the phone. Say this in the App Store description; it is a differentiator in a category full of engagement-maximizing apps.

---

## 10. Widgets & Live Activities

- **Lock Screen widget:** next alarm time + streak
- **Home Screen widget (small):** today's verse once completed, alarm time before
- **Live Activity:** during the morning flow, showing progress through the steps
- **Dynamic Island:** AlarmKit provides alarm presentation natively

---

## 11. Technical architecture

**Stack**
- SwiftUI, iOS 26+, no backend, no auth
- **AlarmKit** — alarm scheduling and presentation
- **Vision** — on-device OCR
- **Speech** — on-device recognition
- **SwiftData** — local persistence
- **CloudKit private database** — backup and sync, no account needed
- **RevenueCat** — subscriptions
- **Gemini Flash or Claude Haiku** — verification escalation only

**Data model**
```
Alarm         { id, time, repeatDays, mode, verseSource, sound, enabled }
DailyEntry    { date, verseRef, verified, verifyMode, attempts,
                prayerText, prayerAudioURL, journalText, completedAt }
Prayer        { id, date, text, audioURL?, answered, answeredDate? }
Streak        { current, longest, freezesUsed, lastCompleted }
Devotional    { verseRef, context, reflection, today, relatedRefs }
```

**Bundled content**
Verse database (KJV + WEB, public domain) and 120 devotionals ship in the binary. No network needed for the core loop.

**Privacy posture — market this**
- No account, no email, no login
- All journals and prayers on-device, CloudKit private DB only
- Camera frames never stored or transmitted
- Prayer audio never leaves the device
- No analytics SDK beyond RevenueCat and Apple's own

This is a meaningful selling point for an app holding people's prayers. Put it in the App Store description and on the paywall.

---

## 12. v1 scope — what ships, what waits

**In v1 (10–14 days)**
- AlarmKit alarms with repeat scheduling
- All three verification modes
- 120 bundled devotionals
- Written prayer + prayer log
- Journal + calendar archive
- Streaks with milestones and freeze
- Onboarding + hard paywall
- Lock Screen + Home Screen widgets
- KJV and WEB

**v1.1**
- Voice prayer recording + transcription
- "Answered prayer" marking
- Share cards
- Reading plans beyond the default
- Apple Watch companion

**v2**
- Licensed translations (NIV/ESV) if revenue justifies it
- Household mode — same verse for a family, see who has completed
- Church/small-group codes
- Extended devotional library

**Explicitly not doing**
- Social feed, friends, comments
- In-app full Bible reader (Koum sends you to *your* Bible — that is the whole point)
- Worship music library (licensing)
- Android (revisit at $5k MRR)

---

## 13. What will actually kill this

Ranked honestly.

**1. Scan reliability.** If it fails in bad light on thin paper, the reviews will say "doesn't work" and the app is dead. This is 40% of the engineering budget. On-device first, generous thresholds, always an escape hatch.

**2. Devotional content quality.** Generic AI devotionals will get you dismissed by exactly the audience you need. Human-edit everything or use public-domain sources.

**3. Competitors with a head start.** Bible Alarm is running content SEO and has thousands of users. You do not beat them on SEO — you beat them on TikTok, on focus, and on being the only one that actually verifies. Do not try to match their thirteen practices; that is their weakness, not their strength.

**4. Weekly pricing backlash.** This audience is more sensitive than most to feeling monetized. See the monetization spec — the recommendation is to test carefully rather than default to aggressive weekly pricing.

**5. Scope creep.** Prayer audio, reading plans, translations, Watch app. Every one is defensible and every one delays the ship. Cut ruthlessly.

**6. The gimmick wearing off.** Novelty carries 2–3 weeks. Retention past that comes from the prayer log, the journal archive, and "on this day." Build those properly even though they do not demo well.

---

## 14. App Store listing

**Title:** `Koum: Christian Alarm Clock`
**Subtitle:** `Wake up with your Bible open`

**Keywords:** `christian alarm, bible alarm, wake up with god, morning devotional, quiet time, prayer journal, bible reading plan, morning routine, scripture alarm, devotional app`

**Description opening:**
> Your alarm will not turn off until you have opened your Bible.
>
> Not a photo. Not a tap. Koum checks the passage — by scan, by voice, or by typing — and only then does the ringing stop.
>
> Most mornings you mean to start with God. Then the alarm goes off and you don't. Koum closes the gap between intention and the actual morning.

**Screenshots, in order:**
1. Alarm ringing, verse on screen — "Your alarm won't stop until you open your Bible"
2. Camera over a physical Bible, verified checkmark — "Scan the passage"
3. Devotional — "A short reflection on what you read"
4. Prayer log — "Every prayer, kept"
5. Streak — "42 mornings with God"
6. Journal calendar — "Look back on what He's been saying"

**App preview video:** 15 seconds. Dark room, alarm blaring, hand reaches for a physical Bible, opens it, phone scans, silence, checkmark. No narration, no music. The silence at the end is the whole ad.
