# Koum — Design System

> Minimalist. Elegant. Reverent without being churchy.
> **Design thesis: the app is dark because it is used in the dark.**

---

## 1. Direction

### The thesis

Almost every Christian app in the App Store is light-mode, warm cream, gold accents, serif type, soft photography of sunrises and open books. It is a well-worn look and it is *wrong for this product*, because Koum is used at 6:15am in a dark bedroom by someone who just opened their eyes.

Koum is **dark by default and dark by conviction.** A cream screen at full brightness at 6am is physically unpleasant. This is not a style preference — it is the single most important usability fact about the app, and it is also what makes it look unlike every competitor in the category.

### The image

**First light.** The moment before dawn — sky still deep blue, one edge of the horizon starting to warm. Not sunrise. The minute *before* sunrise. That is the emotional and visual register of the entire app: dark blue field, one warm point of light, growing.

This maps exactly to the product: you are in the dark, something warm arrives, you get up.

### Principles

1. **Dark first, always.** Light mode exists for daytime journal reading; it is the secondary theme, not the primary.
2. **Scripture is the largest thing on screen.** Always. The verse is never a caption to the UI — the UI is a frame for the verse.
3. **One warm accent, used sparingly.** Warmth means progress, completion, light.
4. **Nothing decorative.** No crosses, no doves, no stained glass, no watercolour washes. The reverence comes from restraint.
5. **Generous space.** Type breathes. Empty space is the design.
6. **Motion is slow.** Nothing snaps. Everything eases, like waking.

### Explicitly rejected

| Rejected | Why |
|---|---|
| Cream + gold + serif | The Christian-app default; instantly templated, and physically wrong at 6am |
| Cross iconography anywhere | Obvious, and Koum earns its identity through behaviour |
| Stock sunrise photography | Every competitor uses it |
| Warm-clay / terracotta accents | The current AI-design default; reads as generated |
| Gradients on buttons | Dates instantly |
| Rounded, friendly, "app-y" | Undermines the seriousness of the moment |

---

## 2. Colour

### Dark theme (primary)

```
NIGHT          #0A0E1A    Base background — deep blue-black, not neutral black
NIGHT_RAISED   #131827    Cards, sheets, raised surfaces
NIGHT_EDGE     #1E2536    Borders, dividers, input fields

BONE           #F2EFE8    Primary text — warm off-white, never pure #FFF
BONE_MUTED     #9BA3B4    Secondary text, labels, captions
BONE_FAINT     #5A6478    Disabled, placeholder, timestamps

FIRSTLIGHT     #E8A657    THE accent — warm amber. Progress, completion, active.
FIRSTLIGHT_DIM #8A6234    Pressed states, subtle accent fills

DEEP           #2B4A7A    Secondary accent — the blue of pre-dawn sky
VERIFIED       #6BAF92    Success only. Muted sage, never a bright green.
ATTENTION      #C4726A    Errors. Muted clay, never a harsh red.
```

**Notes on these choices:**

`NIGHT` is `#0A0E1A` — a blue-black, not `#000`. Pure black on OLED is harsh and reads as void; the blue tint reads as *night*, which is the point. It also makes `FIRSTLIGHT` sing against it.

`FIRSTLIGHT` at `#E8A657` is amber, deliberately pulled away from both gold (churchy) and terracotta (`#D97757`, the AI-design tell). It is the colour of a filament bulb or the first edge of sun. Warm, but not sentimental.

`ATTENTION` is muted clay, not red. Nothing in this app should feel alarming — including the alarm. A failed scan at 6am should feel like a gentle "try again," never like an error state.

`VERIFIED` is sage, not a bright success green. A bright green checkmark would feel like a productivity app. This should feel like relief.

### Light theme (secondary — daytime reading)

```
PAPER          #F7F5F0    Background
PAPER_RAISED   #FFFFFF    Cards
PAPER_EDGE     #E3DFD6    Borders

INK            #16192A    Primary text
INK_MUTED      #5A6070    Secondary
INK_FAINT      #9A9FAE    Tertiary

FIRSTLIGHT     #C4802E    Accent, darkened for contrast on light
DEEP           #2B4A7A    Unchanged
VERIFIED       #4A8A6E
ATTENTION      #A85248
```

### Rules

- The alarm screen is **always dark**, regardless of theme setting. Non-negotiable.
- `FIRSTLIGHT` appears at most **twice** on any screen.
- Accent = progress, completion, or the single primary action. Never decoration.
- All text meets WCAG AA against its background.

---

## 3. Typography

### Faces

**Display / Scripture — `Fraunces`** *(revised from Newsreader, July 2026)*
A warm, characterful "soft serif" with genuine personality at display sizes — feels hand-set rather than default. Available on Google Fonts, free for commercial use.

Used for: verse text, screen headlines, devotional body, numbers on the alarm face. Headlines run SemiBold for presence; verses stay Regular.

**Interface — `Inter`** *(weights revised up, July 2026)*
Neutral, superbly legible at small sizes, excellent at low brightness. Does the invisible work. Runs heavier than typical — buttons are 17pt SemiBold, body 16pt Medium — so nothing reads thin on a dark screen at 6am.

Used for: buttons, labels, settings, navigation, captions, metadata.

**Why this pairing:** the split is semantic, not aesthetic. **Serif is the voice of Scripture. Sans is the voice of the app.** They never trade roles. A user should be able to tell at a glance whether they are reading God's words or Koum's. That distinction is the whole typographic idea, and it is the aesthetic risk worth taking — most apps would set everything in one family.

Fall back to New York and SF Pro if bundling is a problem, but bundle if you can — SF Pro everywhere is what makes an app look like a template.

### Scale

```
VERSE_HERO     Newsreader Regular    34/44    -0.5    Alarm screen verse
VERSE          Newsreader Regular    26/38    -0.3    Verse in flow
DISPLAY        Newsreader Medium     30/36    -0.4    Screen headlines
TITLE          Newsreader Medium     22/28    -0.2    Section heads
DEVOTIONAL     Newsreader Regular    18/30     0      Devotional body
BODY           Inter Regular         16/24     0      UI text
LABEL          Inter Medium          14/20     0.1    Buttons, labels
CAPTION        Inter Regular         13/18     0.2    Metadata
MICRO          Inter Medium          11/14     0.6    Eyebrows, ALL CAPS
CLOCK          Newsreader Light      72/72    -2      Alarm time
STREAK         Newsreader Medium     48/52    -1      Streak number
```

### Rules

- **Scripture is never below 18pt.** Ever.
- Verse text is always the largest element on its screen.
- Line length caps at ~38 characters for verse, ~64 for devotional.
- Verse references (`PSALM 143:8`) set in `MICRO`, all caps, `BONE_MUTED`, `FIRSTLIGHT` on the alarm screen.
- Never italicize Scripture for emphasis. It carries its own weight.
- Full Dynamic Type support. Devotional readers skew older than you think.

---

## 4. Space & layout

8pt base grid.

```
xs   4     Tight pairs
sm   8     Within a component
md   16    Between components
lg   24    Screen margins
xl   40    Between sections
2xl  64    Around Scripture — always generous
3xl  96    Alarm screen breathing room
```

**Layout rules**
- Screen margin: 24pt
- Single column, always. No grids, no side-by-side.
- Verse blocks get `2xl` above and below, minimum.
- **One primary action per screen.** If a screen has two equal buttons, it is two screens.
- Primary actions sit in the bottom third — one-thumb reach, half-asleep.

---

## 5. Components

### Buttons

**Primary**
```
Height 56 · Radius 16 · FIRSTLIGHT fill · NIGHT text · LABEL
Full width minus margins
Pressed: FIRSTLIGHT_DIM, scale 0.98, 120ms
```

**Secondary**
```
Height 56 · Radius 16 · 1pt NIGHT_EDGE border · BONE text
Transparent fill
```

**Ghost**
```
No fill, no border · BONE_MUTED text · LABEL
For skip, later, dismiss
```

Skip buttons are always ghost, always quiet, always present. The user must never feel trapped — that is a product value expressed in a component.

### Verse block

```
   PSALM 143:8              ← MICRO, caps, FIRSTLIGHT, 16pt below

   Let me hear in the       ← VERSE_HERO, BONE
   morning of your
   steadfast love,
   for in you I trust.

                            ← 64pt clear below
```

No quote marks in the UI. No card, no border, no background. The verse floats on `NIGHT`. This is the most important visual pattern in the app.

### Cards

```
NIGHT_RAISED fill · Radius 20 · 20pt padding
No shadow in dark theme — elevation via surface colour only
Light theme: y2 blur8 rgba(0,0,0,0.04)
```

### Input

```
Height 52 · Radius 14 · NIGHT_EDGE fill · No border
Focused: 1pt FIRSTLIGHT border
Placeholder BONE_FAINT
```

Journal input is the exception: no visible field at all. Just a cursor on `NIGHT` with the prompt above in `BONE_MUTED`. Writing should feel like writing, not like filling a form.

### Streak

```
      🔥
      12                  ← STREAK, FIRSTLIGHT
   mornings               ← CAPTION, BONE_MUTED
```

Flame icon is a custom line glyph, not an emoji. Never a filled or animated flame — it would look like a game.

---

## 6. Signature elements

Three things that make Koum recognizable in a screenshot. Spend the design boldness here and keep everything else quiet.

### 1. The dawn gradient

The alarm screen background is not flat. It carries a barely-perceptible vertical gradient — `#0A0E1A` at the top easing to `#141A2E` at the bottom, with a faint `FIRSTLIGHT` glow at roughly 15% opacity along the very bottom edge.

**And it moves.** Over the 30 seconds the alarm rings, the glow rises very slightly and warms. Dawn arriving while you decide to get up.

Almost subliminal. Users will not consciously notice it. It is why the screen feels alive.

### 2. The verification moment

When a verse verifies:

1. Alarm sound cuts **instantly** — silence lands before any visual
2. 200ms of nothing
3. `FIRSTLIGHT` glow blooms from the screen centre, 600ms ease-out
4. Checkmark draws itself, stroke animation, 400ms
5. Glow settles to a warm ambient wash
6. Hold 800ms before advancing

**The silence is the reward.** It should feel like relief. This is the single most emotionally important 2 seconds in the product and it is what the entire TikTok demo rests on — get it right and the video makes itself.

### 3. Scripture as the only hero

Every screen containing Scripture gives it total dominance — largest type, most space, nothing competing. No screen ever puts a button, an image, or a nav bar in visual competition with a verse.

This is a discipline more than a device, and it is what will make Koum feel reverent without a single religious graphic.

---

## 7. Motion

**Everything eases. Nothing snaps.** The app is used by someone waking up; the motion should feel like the same process.

```
INSTANT   120ms   ease-out         Button press
QUICK     240ms   ease-out         Toggles, selection
GENTLE    400ms   ease-in-out      Screen transitions
SLOW      600ms   ease-out         Reveals, glow
BREATH    800ms   ease-in-out      Onboarding line-by-line
DAWN      30s     linear           Alarm gradient rise
```

**Patterns**
- Onboarding text appears line by line at `BREATH` intervals — pacing that forces the reader to slow down
- Screen transitions cross-fade + 8pt vertical drift, never horizontal slide
- Verse appears with opacity + 4pt rise, `SLOW`
- Streak increments count up over 600ms
- Nothing bounces. No spring curves anywhere in the app.

**Reduced motion:** respect it fully. The dawn gradient goes static, the verification glow becomes a simple fade. Nothing breaks.

---

## 8. Haptics

```
Verification passed     .success
Verification failed     .warning        ← never .error, too harsh
Button press            .light
Selection               .selection
Streak milestone        .success ×2, 200ms apart
Alarm ringing           continuous heavy pulse, with the sound
```

The failed-verification haptic being `.warning` rather than `.error` is deliberate. Nothing in this app should feel like failure — especially not at 6am, especially not when the user is trying.

---

## 9. Voice

**Koum sounds like a friend who gets up early and does not make a thing of it.**

| Do | Don't |
|---|---|
| "Good morning." | "Rise and shine, champion! ☀️" |
| "Start again tomorrow." | "You broke your streak! 😔" |
| "Try again — get the whole page in frame." | "Verification failed. Error 402." |
| "You read Psalm 143 today." | "You crushed your morning goal!" |
| "Nothing to do. It renews Thursday." | "⚡ DON'T MISS OUT ⚡" |

**Rules**
- Sentence case everywhere. Never Title Case On Buttons.
- Short sentences. Fragments are fine.
- **Never guilt.** Not for a broken streak, not for a skip, not for a cancel.
- **Never preach.** No "God has a plan for you," no "He's waiting for you." The user is already Christian; they do not need convincing and will find it patronizing.
- Emoji: only the flame in streaks. Nowhere else.
- Exclamation marks: essentially never.

**Error states**
Errors explain what happened and what to do. They never apologize and they are never vague.

> "Couldn't read the page. Try moving closer to a light, or type it instead."

Not: "Oops! Something went wrong 😅"

---

## 10. Icons

Custom line set. 1.5pt stroke, round caps, 24pt grid.

Needed: alarm, camera, microphone, keyboard, book, flame, calendar, check, chevron, settings, plus, close.

Style: geometric, slightly warm, never cute at the interface level. The mascot carries the warmth (see the identity doc); the UI stays composed.

No SF Symbols for the core set — that is what makes an app look default. SF Symbols are acceptable in Settings.

---

## 11. Screen inventory

| Screen | Theme | Notes |
|---|---|---|
| Onboarding | Dark | Type-only, no imagery |
| Alarm ringing | Dark, forced | Dawn gradient, verse hero |
| Verification | Dark, forced | Camera fills, verse overlaid |
| Verified | Dark, forced | Glow + check |
| Prayer | Dark | Prompt + input, minimal |
| Devotional | Follows theme | Reading-optimized |
| Journal | Follows theme | Cursor on field, no chrome |
| Home | Follows theme | Alarm + streak + verse |
| Archive | Follows theme | Calendar |
| Prayer log | Follows theme | Chronological |
| Settings | Follows theme | Standard list |
| Paywall | Dark | Always dark, always |

---

## 12. Quality floor

- Full Dynamic Type, all screens, up to accessibility sizes
- VoiceOver on everything; verse text reads as a single coherent block
- Reduced motion fully respected
- Contrast AA minimum throughout
- 44×44pt minimum tap targets — non-negotiable given the half-asleep user
- Landscape not supported (portrait only, intentional)
- Full iPhone range, SE through Pro Max
- Screen brightness on the alarm screen starts low and rises with the dawn gradient
