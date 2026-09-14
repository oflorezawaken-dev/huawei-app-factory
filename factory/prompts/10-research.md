# Step: research an app opportunity

Read `factory/prompts/00-factory-rules.md` first.

## Goal

Propose ONE new Android app for Huawei AppGallery that the factory can build in a week,
that people **search for by name**, and that is monetizable with Petal Ads without being
annoying. Output a proposal file and open a GitHub issue for a human to approve.

## The discovery rule (learned the hard way, 2026-09-14)

On AppGallery a small publisher lives or dies by **search demand capture**, not by
branding. The owner's own portfolio proves it: every app of theirs that gets real
installs is named after the query people type -- Sudoku, Translate, Clima (weather),
GTA cheats. The factory's first three apps (ReceiptLens, PlantCue, HabitCue) were named
as invented brands with zero keyword surface, which makes them invisible in search no
matter how good the code is.

So a candidate only qualifies if:

- **There is a generic search term people already type** for this function, in plain
  words (calculator, sudoku, qr scanner, voice recorder, weather, unit converter).
  A niche that has to be explained is a niche nobody searches.
- **The store name can lead with that term.** The naming pattern is
  `Keyword - short descriptor` or `Brand - Keyword` (copy the winners:
  "Sudoku - Sudoku Puzzles", "Clima - Weather Forecast"). Set a per-language `appName`
  in `store/listing.json` with the keyword translated (Spanish especially: AppGallery
  is strong in Latin America and Spain). An invented name alone is a disqualifier.
- **Intent matches the app exactly.** Their highest converting app is Sudoku at 48%,
  because someone searching "sudoku" wants precisely that. Their worst is a cheats/guide
  app at 6% -- high impressions, no installs, because the listing promised a different
  thing than the query meant.

## Constraints

- Offline-first. No backend, no accounts, no chat, no social, no user-moderated content.
- **Allowed types:** utilities (tools, productivity, finance, health tracking, home,
  study) **and single-player offline puzzle/casual games** (sudoku, solitaire, word and
  number puzzles). Games are explicitly in scope: they are the best ad surface the
  factory has, since an interstitial between rounds interrupts nothing.
- Must not duplicate an app already in `factory/apps.json`.
- Avoid categories that need special licenses or sensitive-data declarations
  (medical diagnosis, kids, gambling, finance with real money movement).
- **Never build on someone else's trademark.** No app named after or built around
  Instagram, GTA, WhatsApp, a TV channel or any other brand, even when the search
  volume is tempting. Cheat-code and "guide to <branded thing>" apps are banned: they
  convert badly and they invite takedowns.
- Must be doable with the factory stack (Compose, Room, camera/sensors, on-device only).

## Method

1. Use web search. Look at AppGallery and Google Play categories, "best X app" articles,
   Reddit/forum complaints about existing apps, and Huawei device-specific gaps
   (no Google services). Note the date of every source.
2. Shortlist 5 candidates. Score each 1-5 on: **search-term demand** (is there a plain
   generic query for it?), competition weakness, build effort (inverse),
   ad-friendliness (has natural pause moments), low risk.
3. Pick the best. Be honest if none scores well; say "no strong candidate this week".
4. Write the exact store name you would ship, in English and Spanish, and say which
   query it is meant to capture. If you cannot write a name that contains the query,
   the candidate fails and you pick another one.

## Output

Write `proposals/<yyyy-mm-dd>-<slug>.md` with:

- One-paragraph pitch and the target user.
- **The store name in English and Spanish, and the search query each one captures.**
- The 5-candidate scoring table.
- Top 3-5 competitors with what they do badly (with source links and dates).
- Feature list for a V1 buildable in a week, and an explicit "not in V1" list.
- Where ads go (which screens, which formats) and where they must never appear.
- Permissions needed and the privacy story in two sentences.
- Open risks.

Then run:

```bash
gh issue create --title "Proposal: <App Name>" --label proposal --body-file proposals/<file>.md
```

Do NOT create the spec, code, or registry entry. A human adds the `approved` label first.
