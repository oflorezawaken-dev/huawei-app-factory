# Step: research an app opportunity (iOS / App Store)

Read `factory/prompts/00-factory-rules.md` first.

## Goal

Propose ONE new iPhone utility app for the Apple App Store that the factory can
build in a week, that App Store users demonstrably want, and that is monetizable
with AdMob plus a one-time "remove ads" purchase without being annoying. Output
a proposal file and open a GitHub issue for a human to approve.

## The one rule that overrides everything else

**Do NOT port or clone the factory's Huawei apps.** The owner decided
(2026-09-07) that iOS ideas must come from what the App Store market is asking
for, not from what the AppGallery lane already shipped. ReceiptLens, PlantCue
and anything else in `factory/apps.json` are off the table as candidates, and
so is any thin variation of them. Research the iOS market on its own terms.

## Constraints

- Offline-first utility (tools, productivity, finance tracking, health/habit
  tracking, home, study). No social, no chat, no accounts, no backend, no
  user-generated content that needs moderation.
- Must be clearly differentiated from the top App Store competitors you find,
  and must not duplicate anything already in `factory/apps.json` (any platform).
- Avoid categories with special Apple rules or licenses: medical diagnosis,
  kids category, gambling, real-money finance, HealthKit-dependent ideas
  (HealthKit data cannot be used for ads at all), and anything drivable only
  by a web view.
- Must be doable with the factory iOS stack: SwiftUI, SwiftData, camera/photo
  picker, local notifications, on-device only. iOS 17+, iPhone only at first.

## Apple-specific exclusion filters (reject candidates that trip any)

- **Guideline 4.2 (minimum functionality):** nothing that is essentially one
  screen or one trivial function (flashlight, plain calculator, wallpaper
  packs, a single converter). The app must have enough depth that a reviewer
  sees a real tool.
- **Guideline 4.3 (spam/duplication):** nothing that looks like a template
  reskin of an existing App Store app or of another app on this account. Each
  app needs its own visual identity and its own problem.
- **ATT economics:** a large share of iOS users deny tracking, which lowers ad
  revenue. Prefer ideas where the "remove ads" purchase is genuinely
  attractive (daily-use apps beat occasional-use apps).
- **Review friction:** avoid ideas whose core value requires permissions with
  hard-to-justify usage strings, or content Apple tends to escalate (VPNs,
  device "cleaners"/"boosters", anything promising system-level effects).

## Method

1. Use web search, dated sources only. Look at:
   - App Store category charts and "best iPhone app for X" articles (what ranks,
     what its reviews complain about);
   - Reddit (r/ios, r/iphone, r/apple, niche subreddits), Apple Support
     Communities and forums for unmet needs and complaints about incumbents;
   - App Store review patterns of the top competitors: recurring 1-2 star
     complaints are the demand signal;
   - seasonality and platform gaps (what exists on Android but is weak on iOS
     is fine as a *signal* of demand — building "the Android app but on iOS" is
     not, unless the idea stands on its own for iPhone users).
2. Shortlist 5 candidates. Score each 1-5 on: demand evidence (App Store
   specific), competition weakness, build effort (inverse), monetization fit
   (natural ad pauses AND remove-ads appeal), Apple review risk (inverse).
3. Pick the best. Be honest if none scores well; say "no strong candidate this
   week" and stop.

## Output

Write `proposals/<yyyy-mm-dd>-<slug>-ios.md` with:

- One-paragraph pitch and the target user.
- The 5-candidate scoring table.
- Top 3-5 App Store competitors with what their reviews say they do badly
  (with source links and dates).
- Feature list for a V1 buildable in a week, and an explicit "not in V1" list.
- Where ads go (which screens, which formats), where they must never appear,
  and why someone would pay to remove them.
- Permissions needed, each with a one-line justification a reviewer would
  accept, and the privacy story in two sentences.
- Which guideline risks (4.2, 4.3, 5.1.1) you considered and why this idea
  clears them.
- Open risks.

Then run:

```bash
gh issue create --title "Proposal (iOS): <App Name>" --label proposal --body-file proposals/<file>.md
```

Do NOT create the spec, code, or registry entry. A human adds the `approved`
label first.
