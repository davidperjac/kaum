# Koum — Brand, Logo & Mascot

---

## 1. The name

**Koum** — Aramaic, from *ṭalitha koum* (Mark 5:41): *"Little girl, arise."*

Jesus takes a dead girl's hand and tells her to get up. She gets up.

It is, quite literally, the most famous wake-up instruction in Scripture, spoken by Christ, and it means "arise." For an alarm clock app, that is close to perfect.

**Why it works**
- Genuinely meaningful to anyone who knows the passage — and a small delight when they connect it
- Mysterious and clean to anyone who doesn't
- Four letters, one syllable, trademarkable, almost certainly available
- Doesn't say "Bible" or "Christian" in the name, which keeps it from feeling like a category app

**Why it's risky**
- Unspellable from hearing it. This is a real cost to word-of-mouth.
- Meaningless on its own in the App Store search results

**Mitigation:** the name never appears alone in marketing. It is always locked to the tagline, and the App Store title carries the category keywords.

```
KOUM
Wake up with purpose
```

App Store title: `Koum: Christian Alarm Clock`
Subtitle: `Wake up with your Bible open`

The name does the branding. The subtitle does the finding.

---

## 2. Logo

### Wordmark

`KOUM` set in **Newsreader Medium**, all caps, letterspaced +8%.

Serif, because it should feel like it belongs on a book spine rather than a startup deck. The letterspacing gives it air and stops the tight `OU` pair from reading as a blob.

```
K  O  U  M
```

**One detail — the O.** The counter of the `O` is very slightly open at the bottom-left, as though a sliver of light is escaping. Almost invisible at small sizes; noticeable when you look. It is the "first light" idea hidden inside the letterform, and it gives the wordmark a reason to exist beyond "the name in a nice font."

Do not overdo this. The gap is 3–4% of the stroke width. If people notice it immediately, it is too large.

### Lockups

**Primary (vertical)**
```
     ─────────
      K O U M
   wake up with purpose
```
Tagline in Inter Regular, `MICRO` size, letterspaced, `BONE_MUTED`.

**Horizontal** — mark + `KOUM`, for headers and web.

**Mark alone** — the horizon symbol below.

### Colour

- `BONE` on `NIGHT` — primary, the default everywhere
- `INK` on `PAPER` — light contexts
- Single-colour black or white for stamps and merch
- **Never** gradient. **Never** `FIRSTLIGHT` for the full wordmark — the accent is for the mark only.

---

## 3. App icon

The icon has one job: to be recognizable on a dark home screen at 6am, and to look unlike every other app in its category.

### The concept: horizon

A single horizontal line across a dark blue field, with a warm arc of light just breaking beneath it.

```
   ┌─────────────────┐
   │                 │
   │                 │   NIGHT → deep blue field
   │                 │
   │ ─────────────── │   BONE horizon line
   │      ▁▂▃▂▁      │   FIRSTLIGHT arc rising
   │                 │
   └─────────────────┘
```

**Specifics**
- Background: vertical gradient, `#0A0E1A` top → `#141A2E` bottom
- Horizon: 1.5pt `BONE` line at 58% height, spanning ~70% of the width, softly faded at both ends
- Arc: `FIRSTLIGHT` semicircle rising from just below the line, with a soft radial glow
- No text. No cross. No book. No sun rays.

**Why it works**
- Reads instantly at 60×60 as *dawn*
- Zero religious iconography, which paradoxically makes it feel more serious than a cross would
- The only warm-on-dark icon in a category of cream-and-gold
- The horizon line is a subtle echo of a page edge

**Alternative worth prototyping:** the same horizon, but the line has a slight fold — the top edge of an open book seen edge-on, doubling as a horizon. Riskier, more distinctive. Prototype both at 60×60 before committing; if the book reading isn't instant, drop it.

### Variants
- **Dark (default)** — as above
- **Light** — `PAPER` field, `INK` horizon, `FIRSTLIGHT` arc
- **Tinted** — monochrome horizon + arc, system-tinted

---

## 4. Mascot

### Should Koum have one?

**Yes — but as a small, quiet companion, not a brand character.**

The tension: you want friendly and cute. The product is a dark, reverent, minimal app used in a serious emotional moment. A cartoon mascot in the alarm flow would break it completely.

The resolution: **the mascot lives at the edges, never in the core loop.**

| Where the mascot appears | Where it never appears |
|---|---|
| Empty states | The alarm screen |
| Streak milestones | The verification flow |
| Onboarding punctuation (1–2 screens max) | The devotional |
| Push notification icons | The journal |
| Social content and TikTok | The paywall |
| App Store screenshot 6 | Anywhere Scripture is on screen |

This split is the whole design decision. The mascot makes Koum *approachable* in marketing and *warm* in the moments between; the core experience stays composed.

---

### The mascot: **Wren**

A small bird. Specifically a wren.

**Why a wren:**
- Wrens are among the first birds to sing before dawn — they are literally the sound of the pre-dawn chorus. The mascot *is* the app's function.
- Tiny, round, and naturally cute without any cartoon exaggeration
- Birds carry gentle scriptural resonance (Matthew 6:26, sparrows) without being a religious symbol
- Nothing else in this category has one. Every competitor uses suns, crosses, or open books.
- A bird that wakes you by singing is a much kinder metaphor than an alarm that yells at you

### Design

**Form**
- Simple, rounded, almost a soft teardrop
- Small round head, no visible neck
- Two dot eyes, warm dark brown, positioned slightly forward — awake and curious, never sleepy or half-lidded
- Small triangular beak, `FIRSTLIGHT`
- A single upturned tail — the wren's signature silhouette and the one anatomical detail worth keeping
- Simple wing shape suggested by one curved line

**Colour**
- Body: warm brown-grey, `#8B7A6B`
- Belly: `BONE`, slightly lighter
- Beak and feet: `FIRSTLIGHT`
- Eyes: `#2A2018`
- A single `FIRSTLIGHT` highlight on the crown — the first light hitting it

**Style**
- Flat vector, no gradients, no outlines
- Geometric construction — built from circles and soft curves
- Roughly 3 head-heights tall (chunky, not elegant)
- Rendered small: never larger than 120pt in-app

**What Wren is not**
- Not a Christian bird. No halo, no tiny cross, no praying wings, no Bible under its wing. That would be cloying and would undercut the app's restraint.
- Not expressive to the point of cartoon. No big anime eyes, no open-mouthed shouting.
- Not animated in the core app.

### Poses (ship 6, no more)

| Pose | Where |
|---|---|
| **Perched** | Default. Sitting, alert, facing forward. Empty states. |
| **Singing** | Head tilted up, beak open, three small `FIRSTLIGHT` notes rising. Alarm-set confirmation, push icons. |
| **Sleeping** | Curled, eyes closed. Evening/wind-down states. |
| **Celebrating** | Small hop, wings slightly out. Streak milestones only. |
| **Waiting** | Head cocked, looking sideways. Missed morning, gentle re-engagement. |
| **Flying** | Small, in profile, wings mid-beat. Loading, transitions. |

### Voice

Wren does not speak. No dialogue, no first-person, no "Hi, I'm Wren!"

It appears and it reacts. Koum's copy stays in Koum's voice; the bird is a visual presence only. The moment a mascot starts talking, the app becomes a kids' app.

### Naming

The bird is called Wren internally and in social content. It is not named in the app UI — it just exists. Users who care will name it themselves, which is better.

---

## 5. Where warmth lives

A useful way to hold the whole identity:

```
   COLD, COMPOSED              WARM, FRIENDLY
   ──────────────              ──────────────
   Alarm screen                Empty states
   Verification                Streak celebrations
   Scripture                   Push notifications
   Devotional                  Onboarding edges
   Journal                     Social & TikTok
   Paywall                     App Store screenshot 6
```

The app is serious where it matters and warm where it can afford to be. That contrast is more memorable than being uniformly one or the other — and it is exactly the balance that a category full of relentlessly gentle, uniformly warm Christian apps is not striking.

---

## 6. Social & marketing identity

**TikTok/Reels format** — dark, quiet, real:
- Real bedroom, real dark, real physical Bible
- The alarm actually blaring, the actual scan, the actual silence
- No voiceover, no music, no text overlay beyond one line
- The cut to silence is the hook

**The one line that goes on everything:**
> *The alarm you turn off with your Bible.*

**Wren's role in social:** app icon presence, end cards, sticker packs, comment replies. Never in the demo video itself — the demo is about the Bible and the silence, and a cartoon bird would undercut it.

---

## 7. Asset checklist

**Logo**
- [ ] Wordmark, SVG, with the open-`O` detail
- [ ] Vertical and horizontal lockups
- [ ] Single-colour versions

**Icon**
- [ ] 1024×1024 master, dark
- [ ] Light and tinted variants
- [ ] Book-fold horizon alternative, tested at 60×60

**Wren**
- [ ] 6 poses, SVG
- [ ] Flat PNG exports at 1×/2×/3×
- [ ] Sticker pack versions for social
- [ ] Push notification icon (singing pose)

**Marketing**
- [ ] 6 App Store screenshots
- [ ] 15s app preview video
- [ ] Streak share card template
- [ ] Landing page hero
