# Koum — Verification Engine

> The only technically hard part of the app, and the only part that can kill it.
> Budget ~40% of engineering time here.

---

## 1. The problem

A groggy person, in a dark room, points a phone at a thin-paper, two-column, small-type page and expects the noise to stop.

Everything about that sentence is hostile to OCR:

| Condition | Why it hurts |
|---|---|
| Low light | Noise, motion blur, poor contrast |
| Thin Bible paper | Show-through from the reverse page |
| Two columns | Text ordering breaks; lines interleave |
| Small type (7–9pt) | Below reliable OCR resolution at distance |
| Red-letter text | Low contrast in red channel |
| Curved page near the spine | Perspective distortion |
| Shaky hands | Motion blur |
| Cross-references and footnotes | Dense noise text adjacent to the target |
| Translation variance | The text on the page may share few exact words with your stored verse |

**The design consequence:** the system must be *generous*. A false pass costs nothing — the user is awake, holding a Bible, looking at the page. That is the outcome the product wants. A false fail costs a one-star review and a refund.

**Bias every threshold toward passing.**

---

## 2. Architecture

```
                    Camera frame
                         │
              ┌──────────▼──────────┐
              │  Vision OCR         │   on-device, free, instant
              │  VNRecognizeText    │
              └──────────┬──────────┘
                         │ raw text
              ┌──────────▼──────────┐
              │  Normalize          │   strip punctuation, case,
              │                     │   verse numbers, footnote marks
              └──────────┬──────────┘
                         │
              ┌──────────▼──────────┐
              │  LOCAL MATCH        │
              │  1. verse number    │
              │  2. distinctive     │
              │     noun phrases    │
              │  3. token overlap   │
              └──────────┬──────────┘
                         │
              score ≥ 0.55 ────────────► PASS  (no network)
                         │
              score 0.30–0.55 ─┐
                         │     │
              score < 0.30     │
                         │     │
                    ┌────▼─────▼────┐
                    │  LLM ESCALATE │   only if online
                    │  "what ref is │   only if ambiguous
                    │   this text?" │
                    └────┬──────────┘
                         │
              ref matches target ──────► PASS
                         │
                    RETRY / escape hatch
```

**Most mornings never touch the network.** Local match handles the majority of frames. Escalation is the exception, not the path.

---

## 3. Stage 1 — Capture

```swift
let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.usesLanguageCorrection = true
request.recognitionLanguages = ["en-US"]
request.minimumTextHeight = 0.008   // small Bible type
```

**Capture strategy — continuous, not shutter.**

Do not make the user press a button and hold still. Run recognition on the live camera stream and pass the moment a frame matches. This is dramatically more forgiving of shake and focus, and it feels magical rather than transactional — the alarm just stops while they are still holding the phone up.

```swift
// Sample ~4 frames/sec, keep the best result
// Pass on the first frame that clears threshold
// Accumulate text across frames — a verse split across
// two frames should still match
```

**Accumulate across frames.** Keep a rolling buffer of the last ~3 seconds of recognized text. If the user pans across the page, the union of frames may contain the verse even if no single frame does.

**Torch:** auto-enable when ambient light is low. Detect via `AVCaptureDevice` ISO or a brightness heuristic on early frames. Do it silently — do not ask.

**Guidance overlay:** a simple frame outline and one line of text. Nothing more.
- Default: *"Point at the page"*
- After 3s no text detected: *"Get the whole page in frame"*
- After 6s: *"Try turning on a light"*

---

## 4. Stage 2 — Normalize

```swift
func normalize(_ raw: String) -> [String] {
    raw.lowercased()
       .replacingOccurrences(of: #"\d+"#, with: " ", options: .regularExpression)
       .replacingOccurrences(of: #"[^\p{L}\s]"#, with: " ", options: .regularExpression)
       .split(separator: " ")
       .map(String.init)
       .filter { $0.count > 2 }
       .filter { !stopWords.contains($0) }
}
```

Strip: verse numbers, punctuation, footnote markers, chapter headings, cross-reference letters, and stop words. What remains is content words — the signal.

**Keep the verse numbers separately** before stripping. They are a strong locator.

---

## 5. Stage 3 — Local match

Three signals, weighted.

### Signal A — Verse number proximity (weight 0.3)

If the OCR sees `143` and `8` in proximity, and the target is Psalm 143:8, that is powerful evidence — and it is translation-independent.

```swift
func verseNumberScore(numbers: [Int], target: VerseRef) -> Double {
    let hasChapter = numbers.contains(target.chapter)
    let hasVerse   = numbers.contains(target.verse)
    if hasChapter && hasVerse { return 1.0 }
    if hasVerse { return 0.6 }
    if hasChapter { return 0.4 }
    return 0.0
}
```

### Signal B — Distinctive phrases (weight 0.5) ← the important one

For each verse, precompute 2–4 **distinctive noun phrases** that survive translation.

Psalm 23:1 across translations:
- KJV: *the LORD is my shepherd; I shall not want*
- NIV: *the LORD is my shepherd, I lack nothing*
- ESV: *the LORD is my shepherd; I shall not want*
- NLT: *the LORD is my shepherd; I have all that I need*
- MSG: *God, my shepherd! I don't need a thing*

Exact-text matching fails across this set. But `shepherd` appears in every one. That is the anchor.

```
Psalm 23:1  → anchors: ["shepherd"]
                weak:  ["lord", "want", "need"]

John 3:16   → anchors: ["world", "begotten|one and only|only", "perish", "everlasting|eternal"]

Psalm 143:8 → anchors: ["morning", "lovingkindness|steadfast|unfailing", "trust"]
```

Anchors are **stored in the verse database, not computed at runtime.** Generate them offline, review them by hand, ship them in the bundle.

```swift
struct VerseAnchors {
    let required: [Set<String>]   // each set = one concept, any member matches
    let supporting: [String]
}

func phraseScore(tokens: Set<String>, anchors: VerseAnchors) -> Double {
    let hits = anchors.required.filter { !$0.isDisjoint(with: tokens) }.count
    let base = Double(hits) / Double(anchors.required.count)
    let bonus = Double(anchors.supporting.filter(tokens.contains).count) * 0.05
    return min(base + bonus, 1.0)
}
```

**Anchor selection rules:**
- Pick concrete nouns — *shepherd*, *morning*, *rock*, *light*
- Avoid abstract nouns that recur everywhere — *love*, *God*, *heart*, *life*
- Group synonyms into one concept set
- 2–4 concepts per verse; more and you over-constrain

### Signal C — Token overlap (weight 0.2)

Jaccard similarity between OCR tokens and the stored verse tokens. Catches cases the anchors miss.

### Combined

```swift
let score = 0.3 * verseNumberScore
          + 0.5 * phraseScore
          + 0.2 * overlapScore

if score >= 0.55 { return .pass }
if score >= 0.30 { return .escalate }
return .retry
```

**Tune `0.55` down, not up.** Start at 0.55, watch real telemetry, lower it if failures appear. Never raise it above 0.65.

---

## 6. Stage 4 — LLM escalation

Only when the local score is ambiguous (0.30–0.55) **and** the network is available.

### The critical prompt design

**Never ask "is this John 3:16?"** The model will agree. Confirmation bias in LLMs on yes/no verification questions is severe and it will pass anything.

**Ask an open question:**

```
System:
You identify Bible passages from OCR text. The text may contain errors,
partial words, and interleaved columns. Respond with ONLY a JSON object,
no markdown, no explanation:
{"book":"...","chapter":N,"verse":N,"confidence":0.0-1.0}
If you cannot identify a passage, return {"book":null,"chapter":null,
"verse":null,"confidence":0.0}

User:
[normalized OCR text]
```

Then compare the returned reference to your target.

```swift
func escalate(text: String, target: VerseRef) async -> VerifyResult {
    guard let result = try? await llm.identify(text) else { return .retry }
    if result.book == target.book && result.chapter == target.chapter {
        // Verse-level match not required — same chapter is good enough.
        // They have the right page open. That is the goal.
        return .pass
    }
    return .retry
}
```

**Chapter-level matching is deliberate.** If the user has Psalm 143 open and the target is verse 8, they have done the thing. Demanding verse-level precision from OCR on a two-column page is where false failures come from.

### Model choice

Gemini Flash or Claude Haiku. Both are cheap, fast, and more than capable of this task.

**Cost:** roughly 300 input tokens, 40 output. Under $0.0002 per call. If ~15% of mornings escalate and a user completes 25 mornings/month, that's under $0.001/user/month. Immaterial.

**Timeout: 3 seconds.** If it doesn't return, fall through to retry. The user is standing in the dark; never make them wait on a network call.

**Privacy:** send text only, never the image. State this in the privacy policy and on the camera screen.

---

## 7. Speak mode

```swift
let recognizer = SFSpeechRecognizer(locale: .current)
request.requiresOnDeviceRecognition = true   // privacy + offline
request.shouldReportPartialResults = true
```

Same normalize-and-match pipeline. Two differences:

**1. Lower threshold — 0.45.** People misremember, mumble, and slur at 6am. This is not a memorization test.

**2. Pass on partial results.** Do not wait for the user to finish speaking. The moment the accumulated transcript clears threshold, pass. Stopping mid-sentence feels responsive and slightly magical.

Fully on-device. Say so on screen: *"Your voice stays on your phone."*

---

## 8. Type mode

Show the verse. User types it below.

- Threshold: 0.75 character-level similarity, case and punctuation ignored
- Live feedback — characters go `VERIFIED` as they match
- Auto-pass at threshold, no submit button
- Long verses truncate to a reasonable typing length (~120 chars) with an ellipsis
- Autocorrect off, autocapitalize off

This is the guaranteed fallback. It must never fail for any reason.

---

## 9. The escape hatch (mandatory)

```
Attempt 1     "Point at the page"
Attempt 2     "Get the whole page in frame"
Attempt 3     "Try turning on a light"
Attempt 4     [ Type it instead ]  ← prominent button appears
Attempt 5     [ I'll take your word for it ]  ← passes, logs failure
```

Attempt 5 appears after roughly 45 seconds of failed attempts, or 5 failed captures, whichever comes first.

**The alarm must never become undismissable.** This is:
- A user-trust requirement — trapping someone at 6am is genuinely bad
- An App Store review requirement — if a reviewer gets stuck, you are rejected
- A safety consideration — someone needs to get to work

The "I'll take your word for it" pass still counts for the streak. Log it silently with the OCR text and score so you can improve the matcher.

---

## 10. Telemetry

Log locally, sync anonymously (no verse content, no images, no journal text):

```swift
struct VerificationEvent {
    let verseRef: String
    let mode: VerifyMode
    let attempts: Int
    let durationMs: Int
    let localScore: Double
    let escalated: Bool
    let outcome: Outcome        // pass, escapeHatch, abandoned
    let ambientLight: Double?
}
```

**The number that matters: first-attempt pass rate by mode.**

| Metric | Target | If missed |
|---|---|---|
| Scan first-attempt pass | > 70% | Lower thresholds, improve anchors |
| Scan eventual pass | > 95% | Serious problem — investigate immediately |
| Escape hatch usage | < 8% | Threshold too tight |
| Median scan duration | < 12s | Capture strategy problem |
| Escalation rate | < 20% | Anchors too weak |

If scan first-attempt pass rate drops below 60%, **stop feature work and fix it.** Everything else in the app is worthless if this doesn't work.

---

## 11. Test set — build this before writing the matcher

Photograph real Bibles under real conditions. Minimum 200 images:

**Bibles:** KJV, NIV, ESV, NLT, NASB, CSB, a study Bible with heavy footnotes, a compact/pocket Bible, a large-print Bible, a red-letter edition

**Conditions:** full dark + torch, bedside lamp, dawn light through a curtain, overhead light, phone shadow across the page, page near the spine (curved), held at an angle, thin paper with show-through, hands shaking slightly

**Layouts:** two-column (most), single-column, verse-per-line, paragraph format, with and without cross-reference column

Run the matcher against this set on every change. This is your regression suite and it is the difference between an app that works and an app that gets refunded.

**Do this first, before writing the pipeline.** You cannot tune thresholds without ground truth.

---

## 12. Failure modes to handle explicitly

| Case | Handling |
|---|---|
| Wrong page open | Local score low → retry with *"That's a different passage"* |
| Digital Bible on another screen | Works fine, no special handling |
| Phone screen glare | Torch off if reflection detected; guidance copy |
| Non-English Bible | v1 English only. Detect and offer type mode. |
| Blank page / not a Bible | No text detected → *"Point at the page"* |
| User photographs the app's own screen | Detect target-verse-only text with no surrounding page content → gentle nudge. Low priority; not worth over-engineering. |
| Offline + ambiguous score | No escalation available → threshold drops to 0.45, then escape hatch sooner |
| Network timeout | Fall through to retry, never block |

**On cheating:** someone can photograph a screen or type from a Google result. Do not build anti-cheat. The user is the only person they would be cheating, they paid for this, and every anti-cheat measure adds false failures for honest users. The product's job is to make the right thing easy, not to police.

---

## 13. Build order

1. **Test image set** — 200 photos, labeled. Do this first.
2. **Vision OCR pipeline** — raw text out of a frame
3. **Normalizer** — tokens out of raw text
4. **Verse DB with hand-reviewed anchors** — 365 verses
5. **Local matcher** — tune against the test set until first-attempt pass > 70%
6. **Continuous capture UI** — live frames, accumulation, torch
7. **Escape hatch** — every stage
8. **LLM escalation** — last, as an enhancement
9. **Speak mode** — reuses the matcher
10. **Type mode** — trivial, ship early as the safety net

Steps 1–5 are the app. Everything else is packaging.
