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

## Screening filters (learned the hard way — apply before you score anything)

Three research weeks produced two shipped apps and one honest "no candidate"
(`proposals/2026-09-15-no-candidate-ios.md`). **Read every file in `proposals/`
before you start:** an idea rejected there is off the table unless you have new
dated evidence that whatever killed it has changed. The filters below encode
what those weeks cost.

1. **The give-away test — the important one.** "Offline, no account, one-time
   purchase" is the *default* indie positioning on the 2026 App Store, not a
   differentiator; assume any competitor can copy it in a sprint. Ask instead:
   **what do we give away that the incumbent cannot afford to give away?**
   ShiftSlip passed because the incumbents' revenue *is* the arithmetic and the
   export, so matching us would cut their own subscription. If the answer is
   "nothing, they just have not bothered", reject.
2. **Ratings floor.** The category leader must have **>2,000 App Store
   ratings**. A field whose apps total under ~500 ratings is a disqualifier,
   not an opening — PriceJar entered a field of 11–19 ratings and the factory
   paid for it. Ratings measure demand *for an app*. Population or activity
   figures (millions of people who do X) measure the activity, and are not a
   substitute for it.
3. **Clone-flood check.** Search the App Store for the pitch itself and read the
   numeric IDs. Four or more apps whose IDs were issued in roughly the last 18
   months already advertising our positioning = reject on guideline 4.3, however
   weak the paid leader is.
4. **Paywall-change signals expire.** A leader that cut its free tier is a real
   signal only if the change is dated **within 60 days** and free replacements
   have not already shipped. Measured once: that window closed in about eight
   months.
5. **Statutory anchors must be national and stable.** A legal record-keeping
   obligation is the best spec a factory app can have — IRS Pub 531 shaped
   ShiftSlip — but only where one rule covers the whole market. Fifty divergent
   state rules cannot ship offline (stale law is worse than no law), and
   stripping them out usually removes the differentiator with them.
6. **Prefer non-US anchors.** The listing ships in nine languages; a US-only
   idea wastes eight of them. EU/LatAm obligations — utility meter readings and
   bill checks, vehicle inspection cycles, tenancy documentation — are still
   unexplored.
7. **No ads next to health or reproductive data**, even where HealthKit is not
   involved and no guideline literally binds. The factory has no process for
   health-data ad disclosure, and an interstitial standing between a user and
   logging a dose is a missed dose, not a bad review.
8. **Do not enter a category Apple owns or has just crowned** — a free system
   app (Journal, Health → Medications, Reminders, Cycle Tracking, Wallet) or an
   Apple App of the Year.
9. **Count this account's own catalogue against 4.3.** PriceJar and ShiftSlip
   are both money apps; a third would hand a reviewer the duplication argument
   for free.

## Source discipline

Comparison articles ("best X apps of 2026") are usually published by competing
apps and have an obvious interest in making incumbents look bad. Treat them as
leads, never as evidence. **Prices, free-tier limits, rating counts,
last-updated dates and App Store IDs must come from apps.apple.com itself**, and
the proposal must say which claims are primary and which are not. If the
searches return SEO content instead of real user complaints, say so plainly
rather than dressing it up: thin demand evidence is itself a finding, and it is
one the scoring has to reflect.

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

If nothing clears the filters, the deliverable is
`proposals/<yyyy-mm-dd>-no-candidate-ios.md`: the finding, the scoring table,
what killed each candidate, and what to hunt next week. Open no issue. A week
that ends in a well-argued "no" is a good week; a week that ends in a forced
candidate costs a build week and an App Store slot.

Then run:

```bash
gh issue create --title "Proposal (iOS): <App Name>" --label proposal --body-file proposals/<file>.md
```

Do NOT create the spec, code, or registry entry. A human adds the `approved`
label first.
