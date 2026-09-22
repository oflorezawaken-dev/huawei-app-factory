# Step: research an app opportunity (iOS / App Store)

Read `factory/prompts/00-factory-rules.md` first.

## Goal

Propose ONE new iPhone app for the Apple App Store that the factory can build in
a week, that App Store users demonstrably want, and that is monetizable with
AdMob plus a one-time "remove ads" purchase without being annoying. Output a
proposal file and open a GitHub issue for a human to approve.

## Not only utilities — owner's decision, 2026-09-22

Six rounds were confined to "offline utility" by the first constraint of this
prompt, and they produced three calculators and trackers and four "no
candidate" verdicts. The funnel was the cause, not the market: the European
grossing charts for Utilities, Productivity and Business contain **no trade or
calculation app at all** (measured 2026-09-15), the one iOS app of this kind the
factory shipped to a US audience has zero downloads so far, and the best
converter in the owner's AppGallery portfolio is **Sudoku** — a game. Volume
sits in casual and logic games, education, entertainment and lifestyle, and in
those categories ads between sessions are the native business model rather
than an imposition.

So the search space is now **any category the constraints below allow**, and a
utility has to win its place against them rather than being the default.

## The one rule that overrides everything else

**Do NOT port or clone the factory's Huawei apps.** The owner decided
(2026-09-07) that iOS ideas must come from what the App Store market is asking
for, not from what the AppGallery lane already shipped. ReceiptLens, PlantCue
and anything else in `factory/apps.json` are off the table as candidates, and
so is any thin variation of them. Research the iOS market on its own terms.

## Constraints

- **Categories in scope:** casual and logic games (puzzle, word, board, card,
  trivia), education and study, entertainment, lifestyle and hobbies,
  reference, and utilities. Look at all of them before narrowing, and say in
  the proposal which ones you swept.
- **Everything ships on the device.** Content is bundled in the app or
  generated on device: puzzles from a seeded generator, a word list, a trivia
  bank with its source and licence stated. No social, no chat, no accounts, no
  leaderboards or multiplayer that need a server, no backend, no
  user-generated content that needs moderation, and no content that has to be
  refreshed from the network to stay useful.
- **Games must be buildable in SwiftUI in a week.** Turn-based or untimed
  mechanics drawn with SwiftUI views or `Canvas`. The factory has never
  shipped SpriteKit, physics, real-time action or 3D, and a first attempt at
  any of them is not a one-week build.
- **A bundled static reference dataset is allowed** (owner's decision,
  2026-09-15, after three rounds and two "no candidate" verdicts): physics,
  chemistry, geography, units, materials, astronomy, nutrition tables that
  are published constants, and similar data that does not go stale. This
  opens reference and professional-calculation categories that were excluded
  by definition. Still forbidden: **law, tax rates, prices, tariffs, exchange
  rates, schedules** or anything else that changes and would ship wrong
  offline (stale law is worse than no law); and anything that needs a
  *network* database or an API at runtime. Say in the proposal where the
  dataset comes from, its licence, and how big it is.
- Must be clearly differentiated from the top App Store competitors you find,
  and must not duplicate anything already in `factory/apps.json` (any platform).
- Avoid categories with special Apple rules or licenses: medical diagnosis,
  kids category, gambling, real-money finance, HealthKit-dependent ideas
  (HealthKit data cannot be used for ads at all), and anything drivable only
  by a web view. For games that also rules out casino mechanics, loot boxes,
  anything that simulates gambling, and anything aimed at children -- a game
  whose natural audience is under 13 lands in the Kids category, where
  third-party ad SDKs are effectively not allowed.
- Must be doable with the factory iOS stack: SwiftUI, SwiftData, camera/photo
  picker, local notifications, on-device only. iOS 17+, iPhone only at first.

## Apple-specific exclusion filters (reject candidates that trip any)

- **Guideline 4.2 (minimum functionality):** nothing that is essentially one
  screen or one trivial function (flashlight, plain calculator, wallpaper
  packs, a single converter). The app must have enough depth that a reviewer
  sees a real tool.
- **Guideline 4.3 (spam/duplication):** nothing that looks like a template
  reskin of an existing App Store app or of another app on this account. Each
  app needs its own visual identity and its own problem. **This is the main
  risk outside utilities.** Apple rejects clones of well-known games and
  content apps far more readily than clones of tools: a Sudoku, 2048, Wordle,
  solitaire or match-3 with new colours is exactly what 4.3 exists to stop.
  Name the mechanic or the content a reviewer sees in the first minute that no
  top-20 app for the search term already offers. If you cannot, reject.
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

1. **The competitive test -- the important one, and it depends on the kind of
   app.**
   - **For a tool** (a utility, a tracker, a reference): the give-away test.
     "Offline, no account, one-time purchase" is the *default* indie
     positioning on the 2026 App Store, not a differentiator; assume any
     competitor can copy it in a sprint. Ask instead: **what do we give away
     that the incumbent cannot afford to give away?** ShiftSlip passed because
     the incumbents' revenue *is* the arithmetic and the export, so matching us
     would cut their own subscription. If the answer is "nothing, they just
     have not bothered", reject. Round 6 added a second question that belongs
     here: **has giving it away already been tried?** Ten free E6B flight
     computers total 153 ratings against 5,340 for the paid one, because pilots
     buy trust in the number, not the arithmetic.
   - **For a game or a content app**: the give-away test does not apply --
     these categories are already free with ads, and that is *our* model too,
     so there is no paywall to break. Ask instead: **are the apps that own the
     search term weak?** Read their listings and recent reviews on
     apps.apple.com: 1-2 star reviews from the last six months about ad load,
     interstitials mid-game, crashes, paywalled basics or dark patterns; no
     update in over a year; a design that has not been touched since iOS 13. A
     field led by polished, actively maintained free apps is not an opening,
     however big it is -- craft alone does not beat a good free incumbent, and
     the factory does not buy installs. Quote the reviews, with dates.
2. **Findability.** Name the search term a buyer would already type into the App Store
   before they know this app exists, and check it is a term with traffic -- not a phrase
   invented to describe the product. An app nobody searches for has no free distribution,
   and this factory has no paid distribution at all: three apps shipped and the only one
   that reached the store took four days to earn zero downloads. That is a discovery
   problem, and nothing in the product filters below catches it. "Construction calculator"
   passes. "Shift log with tip-out arithmetic" does not -- people search "tip tracker".
   If the honest answer is "they would not search for this, they would have to be shown
   it", the idea needs paid acquisition the owner does not do, and it is out.
3. **Ratings floor.** The category leader must have **>2,000 App Store
   ratings**. A field whose apps total under ~500 ratings is a disqualifier,
   not an opening — PriceJar entered a field of 11–19 ratings and the factory
   paid for it. Ratings measure demand *for an app*. Population or activity
   figures (millions of people who do X) measure the activity, and are not a
   substitute for it.
4. **Clone-flood check.** Search the App Store for the pitch itself and read the
   numeric IDs. Four or more apps whose IDs were issued in roughly the last 18
   months already advertising our positioning = reject on guideline 4.3, however
   weak the paid leader is.
5. **Paywall-change signals expire.** A leader that cut its free tier is a real
   signal only if the change is dated **within 60 days** and free replacements
   have not already shipped. Measured once: that window closed in about eight
   months.
6. **Statutory anchors must be national and stable.** A legal record-keeping
   obligation is the best spec a factory app can have — IRS Pub 531 shaped
   ShiftSlip — but only where one rule covers the whole market. Fifty divergent
   state rules cannot ship offline (stale law is worse than no law), and
   stripping them out usually removes the differentiator with them.
7. **Prefer non-US anchors.** The listing ships in nine languages; a US-only
   idea wastes eight of them. EU/LatAm obligations — utility meter readings and
   bill checks, vehicle inspection cycles, tenancy documentation — are still
   unexplored.
8. **No ads next to health or reproductive data**, even where HealthKit is not
   involved and no guideline literally binds. The factory has no process for
   health-data ad disclosure, and an interstitial standing between a user and
   logging a dose is a missed dose, not a bad review.
9. **Do not enter a category Apple owns or has just crowned** — a free system
   app (Journal, Health → Medications, Reminders, Cycle Tracking, Wallet) or an
   Apple App of the Year.
10. **Count this account's own catalogue against 4.3.** PriceJar and ShiftSlip
   are both money apps and BuildTape (formerly SiteCalc) is a construction
   calculator: a third money app or a second trade calculator hands a reviewer
   the duplication argument for free. The owner's AppGallery games -- Sudoku
   above all -- are off the table as ports, per the rule at the top.

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

0. **Start from what each storefront already pays for and downloads.** Before
   any search, read Apple's own charts in `us`, `de`, `es`, `it`, `fr` and `br`:
   top free and top grossing for Games (6014) and its puzzle (7012), word
   (7019), board (7004), card (7005), trivia (7018) and casual (7003)
   subgenres, and for Education (6017), Entertainment (6016), Lifestyle (6012),
   Reference (6006) and Utilities (6002):
   `https://itunes.apple.com/<cc>/rss/topfreeapplications/limit=100/genre=<id>/json`
   and the same with `topgrossingapplications`. They are primary data and they
   answer in seconds what six rounds of guessing did not. Say which charts you
   read, and what they showed about where volume and money actually are.
1. **Search the storefronts in their own languages first.** The listing ships
   in nine languages, and two rounds concluded "the niches are small" from
   English-only queries — the first serious German query then found a
   6,018-rating leader invisible to any English search. Sweep
   `apps.apple.com/de`, `/es`, `/it`, `/fr`, `/br` in the local language
   **before** searching in English, and read competitor reviews directly at
   `?see-all=reviews` instead of hunting for Reddit threads, which returned SEO
   content two rounds in a row.
2. Use web search, dated sources only. Look at:
   - App Store category charts and "best iPhone app for X" articles (what ranks,
     what its reviews complain about);
   - Reddit (r/ios, r/iphone, r/apple, niche subreddits), Apple Support
     Communities and forums for unmet needs and complaints about incumbents;
   - App Store review patterns of the top competitors: recurring 1-2 star
     complaints are the demand signal;
   - seasonality and platform gaps (what exists on Android but is weak on iOS
     is fine as a *signal* of demand — building "the Android app but on iOS" is
     not, unless the idea stands on its own for iPhone users).
3. Shortlist 5 candidates. Score each 1-5 on: demand evidence (App Store
   specific), competition weakness, build effort (inverse), monetization fit
   (natural ad pauses AND remove-ads appeal), Apple review risk (inverse).
4. Pick the best. Be honest if none scores well; say "no strong candidate this
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
