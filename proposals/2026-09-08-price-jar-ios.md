# Proposal (iOS): PriceJar — your own grocery price book, offline

**Date:** 2026-09-08 · **Slug:** `price-jar` · **Bundle ID:** `com.proapps.pricejar`
**Platform:** iOS 17+, iPhone only · **Category:** Shopping (secondary: Productivity)

> Not a port. Nothing in `factory/apps.json` (ReceiptLens, PlantCue) covers this, and the idea
> comes from App Store reviews of App Store apps, per the owner's 2026-09-07 decision.

## Pitch

PriceJar is a **price book**: the notebook frugal shoppers have kept for decades, where you write
down what a product actually cost, at which store, in which size — so that next time you can tell
at a glance whether €2.19 for 500 g of coffee is a good price or a bad one. You record a price in
about ten seconds (scan the barcode of something you have bought before and it pulls up your own
history), PriceJar normalises every price to a comparable unit (per kg, per litre, per item), and
tells you whether what you are holding is the best price you have ever paid, a typical price, or
overpriced. It also turns your shopping list into an estimated total and shows which of your stores
is cheapest for that basket. Everything is stored on the iPhone with SwiftData: no account, no
store data feeds, no country coverage limits, works in any currency and in both measurement
systems. Free, with an AdMob banner on the browsing screens and a one-time purchase to remove ads —
and a hard rule that no ad appears while you are standing in a shop entering a price.

**Target user:** the household shopper who splits their groceries across 2–6 stores and already
tries to track prices — today in a spreadsheet, a Notes file or their head. Skews toward
discount-store shoppers, large families, expats comparing local chains, and anyone who noticed
their basket getting more expensive and wants evidence instead of a feeling.

## Demand evidence (App Store first, dated)

- The clearest signal is an App Store review of the newest entrant, **Assay – Grocery Price Book**
  (released 2026-01-21): *"I've been looking for a simple, flexible, easy to use price book app
  ever since I switched from Android to Apple over a year ago."* (review dated Feb 18, 2026 —
  [App Store](https://apps.apple.com/us/app/assay-grocery-price-book/id6757925961)). A user
  hunting for a year, on a category whose apps have single-digit rating counts.
- The category's how-to literature tells people to give up on apps: *"Since there isn't a grocery
  price book app that will automate price book tracking, your best option is to set up a digital
  spreadsheet"*
  ([The Dollar Stretcher](https://thedollarstretcher.com/frugal-living/food/digital-grocery-price-book-solutions-and-apps/)),
  and the price-book method itself keeps being re-published as a money-saving technique
  ([Good Cheap Eats](https://goodcheapeats.com/use-a-price-book-to-track-grocery-prices-save-money/),
  [MoneyCrashers](https://www.moneycrashers.com/making-grocery-price-book/),
  [reluctantfrugalist.com](https://reluctantfrugalist.com/grocery-price-tracker-spreadsheet/) —
  spreadsheet templates offered because the apps are not trusted). Spreadsheet users are the
  easiest users to convert: they have already accepted the data entry.
- The behaviour is mainstream in 2026, not niche: food-at-home CPI is 2.7% above July 2025
  ([USDA ERS Food Price Outlook, July→Aug 2026](https://www.ers.usda.gov/data-products/food-price-outlook/summary-findings));
  60% of Americans dropped a brand they were loyal to over 2026 price increases, with a median
  switching threshold of a 16% price rise
  ([doss.com research, 2026](https://www.doss.com/research/inflation-breaking-american-brand-loyalty));
  shoppers are splitting their spend across more retailers and only a small fraction believe their
  main store is the cheap one
  ([Advantage Solutions 2026 Shopper Study](https://youradv.com/advantage360/2026-shopper-study-how-inflation-is-reshaping-grocery-loyalty-and-spend/));
  41% shop discount grocers more than a year ago, making more trips and buying fewer items each
  ([The Cool Down, 2026](https://www.thecooldown.com/green-business/grocery-prices-inflation-us-2026-report/)).
  Multi-store shopping is exactly the behaviour a price book serves.
- Platform gap as a signal only: the well-known price-book workflows come from Android/spreadsheet
  land, and the App Store entrants that exist are either abandoned or subscription-gated (below).

## The five candidates

Scored 1–5. Build effort and Apple review risk are inverted (5 = cheap / low risk).

| Candidate | Demand (App Store) | Competitor weakness | Build effort⁻¹ | Monetization fit | Review risk⁻¹ | Total |
|---|---|---|---|---|---|---|
| **Grocery price book (PriceJar)** | 4 | 5 | 4 | 4 | 5 | **22** |
| Pantry / fridge expiry tracker | 4 | 3 | 4 | 3 | 4 | 18 |
| Home inventory for insurance | 4 | 4 | 3 | 2 | 4 | 17 |
| Household chore / cleaning rotation | 4 | 1 | 4 | 4 | 3 | 16 |
| Car maintenance & service log | 3 | 2 | 4 | 2 | 4 | 15 |

Why the others lost:

- **Pantry/expiry:** real demand, but the incumbents are decent and the differentiator would have
  to be barcode→product-name lookup, which needs a network product database — against the
  offline-first rule. Incumbent pain is mostly network latency and unclear subscriptions
  (FridgeBuddy scans lagging "up to 30 seconds"; Fridgely reviewers complaining they cannot tell
  how often the £2.49 premium is charged —
  [Fango comparison, 2026](https://fango.fi/en/blog/best-food-waste-tracker-app/),
  [Fridgely on the App Store](https://apps.apple.com/gb/app/fridgely/id988016972)).
- **Home inventory:** the strongest incumbent hostility of the five — Sortly's free tier caps at
  100 items and its pricing has moved to business tiers users call "highway robbery" for home
  insurance use, and Encircle has drifted to restoration professionals
  ([HomeProof comparison, 2026](https://homeproofvault.com/blog/best-home-inventory-apps-compared/),
  [Capterra reviews](https://www.capterra.com/p/169199/Sortly-Pro/reviews/)). Rejected on
  monetization: you catalogue your house once and open the app twice a year, so nobody pays to
  remove ads and there is no repeat session to serve them in. Also a crowd of 2026 entrants
  (HomeProof, Kept, Itemlist, WHIG) raises 4.3 optics.
- **Chores:** the field is genuinely well served — Tody 4.8★ over ~11K ratings, Sweepy 4.7★ over
  ~9.4K, plus free options and one-time-purchase options
  ([appshunter, Aug 2026](https://appshunter.io/ios/topics/free-house-cleaning-app),
  [Sweepy](https://apps.apple.com/us/app/sweepy-home-cleaning-schedule/id1498897320)). Entering a
  category with two loved incumbents and dozens of clones is the 4.3 trap.
- **Car maintenance:** CarKeeper already ships the exact pitch we would make — "no login, no
  subscription, no ads, works entirely offline" — and MyAutoLog covers the feature-rich end
  ([carmaintenance.app, 2026](https://carmaintenance.app/best-car-maintenance-tracking-apps/),
  [CarKeeper](https://apps.apple.com/us/app/carkeeper-maintenance-log/id6792796712)). Nothing left
  to be better at, and use is monthly at best.

## Top App Store competitors and what their reviews say they do badly

| App | State (checked 2026-09-08) | What users complain about |
|---|---|---|
| [Price Book – Track Grocery Price](https://apps.apple.com/us/app/price-book-track-grocery-price/id1431720584) (Zinitt) | **2.9★, 19 ratings**, last update v1.5.1 on 2023-01-09 — effectively abandoned; Pro tiers $4.99–$9.99 | Ads on top of the core loop: *"I barely got my first item in and an advertising video came up before I could even go to the next step. Absolutely useless garbage app."* (Nov 2025). Barcode expectations: *"App does not identify the product name. What is the point of the bar code scanner?"* (Jun 2025) |
| [Smart Grocery Price Book](https://apps.apple.com/us/app/smart-grocery-price-book/id1385340762) (BORICUAPPS) | **2.7★, 12 ratings**, still targeting iOS 8 | No unit-price tracking at all — *"cannot track pricing by unit measurements (ounces, pounds, per-item)"* (Feb 2020), i.e. the one thing a price book is for. Ad bar *"covers the entire menu bar"*, blocking navigation (Sep 2020). Hard cap of 6 stores (Nov 2020). Barcode scan returns nothing for mainstream products (Dec 2024) |
| [PricePad – Track Prices & Save](https://apps.apple.com/us/app/pricepad-track-prices-save/id1550316875) (Price Pad LLC) | **4.1★, 11 ratings**, free with ads, v1.73 (Aug 2026) | Closest thing to a healthy competitor, and still tiny. A July 2025 update stopped the app launching for some iPhones before being patched — reliability, and no remove-ads option for a user who dislikes the banner |
| [Assay – Grocery Price Book](https://apps.apple.com/us/app/assay-grocery-price-book/id6757925961) | Released 2026-01-21, **1 rating**, subscription $1.99/mo or $9.99/yr | Charging rent for a local notebook. Its only public review is a feature request (family sharing) from someone who spent a year looking for this app |
| Network comparison apps — Flipp, Basket, Grocery Dealz, Groceries Tracker | Free but account- and coverage-bound | *"Coverage felt limited and inconsistent"*, US-only, no price history (Grocery Dealz); Groceries Tracker *"cannot tell you a price before you've paid it"* and caps free receipt scans; flyer prices ≠ shelf prices ([groceriestracker.com, 2026-03-29, updated Sep 2026](https://groceriestracker.com/blog/best-grocery-price-comparison-apps-2026)) |

**The gap:** every existing option is either abandoned, missing unit prices, subscription-gated, or
dependent on someone else's price feed for a country they may not cover. Nobody ships a fast,
offline, ad-supported-but-polite price book that works with *your* stores and *your* currency. Two
of the loudest complaints in the category are about ad placement — which is a monetization design
brief handed to us for free.

## V1 (buildable in a week on the factory iOS stack)

1. **Price book library** — items with name, optional brand, category, package size + unit, optional
   barcode, optional photo (PhotosPicker, no permission needed). Search and category filter.
2. **Stores** — user-defined list (name, optional note). No location, no map, no chains database.
3. **Price entry in ≤10 seconds** — store, price, package size, unit, date, flags for
   *sale price* and *loyalty-card price*; last-used store and size pre-filled; decimal keypad.
4. **Unit normalisation** — every entry reduced to a comparable unit (per kg / 100 g / L / 100 mL /
   item / ea), metric and imperial, with a per-item preferred display unit. Pure Swift logic with
   XCTest coverage — this is the part that must never be wrong.
5. **"Good price?" verdict** — enter or scan in the aisle and get *best price you've paid* /
   *typical* / *above your usual*, with the best price, its store and its date.
6. **Item history** — every recorded price, sorted; Swift Charts line of unit price over time;
   best store, best-ever price, median, and change vs. six months ago.
7. **Barcode recall** — AVFoundation scanner; a known barcode jumps to that item's history, an
   unknown barcode offers "add a new item" with the code attached. Honest copy: PriceJar
   recognises *your* items, it does not look products up online.
8. **Shopping list + Trip mode** — build a list, see an estimated total from your known prices and
   a per-store comparison of the basket ("Aldi ≈ €41.30 · Mercadona ≈ €46.10, based on 14 of 17
   items you have prices for"). Starting a trip picks a store; ticking items off offers to record
   the price you actually paid, which is how the price book fills itself.
9. **Stats** — basket cost trend by month, savings vs. your typical prices, items whose price rose
   most.
10. **CSV export** via the share sheet (spreadsheet users must be able to leave, and to arrive —
    see "not in V1" for import).
11. **Sample data** — first run offers 12 example items in a demo store, clearly labelled and
    deletable in one tap. Also what an App Store reviewer sees instead of an empty app.
12. **Remove Ads** — StoreKit 2 non-consumable, restore purchase, target price tier ~$3.99.
13. Light/dark, Dynamic Type, VoiceOver labels and accessibility identifiers on every control (the
    UI screenshot test depends on them), 9 store languages, settings with privacy/ads/about.

**Not in V1:** CSV/spreadsheet import, receipt OCR, online barcode→product lookup, iCloud or family
sharing, iPad, widgets, Watch, Live Activities, notifications of any kind, store flyers/deals feeds,
location or store detection, coupon and cashback features, currency conversion between currencies,
multi-user shared lists, Siri/Shortcuts.

## Where the ads go

- **Banner (AdMob adaptive anchored):** bottom of the Price Book library, Stores, Item history and
  Stats screens only — inset above the tab bar with safe-area padding, so it can never cover
  navigation (the Smart Grocery Price Book complaint, Sep 2020). Collapses to nothing when the
  Remove Ads purchase is active.
- **Interstitial:** exactly one placement — after a shopping trip is **saved**, on the trip summary,
  capped at one per session and never within 4 minutes of another ad, never on cold start, never
  before the user has completed anything.
- **Never, at any time:** the price entry form, the barcode scanner, the "Good price?" verdict
  sheet, any screen while a trip is active (**Shopping Mode suppresses all ads** — you are standing
  in a shop, one-handed, possibly with no signal), first run, onboarding, settings, and the purchase
  flow. This is the rule the abandoned incumbent broke in November 2025, and it is the one an
  in-aisle app cannot break.
- **ATT** is requested after the first price is saved — not at launch — with a prompt the user can
  make sense of because they have already seen what the app does.
- **Why someone pays:** the app is opened every shopping trip and several times per trip, in a shop,
  with one thumb, on a screen where the row you are comparing sits right above the banner. A
  one-time ~$3.99 to make that banner disappear forever is an easier decision than Assay's
  $9.99/year for the same category, and unlike Assay it removes nothing else — no feature is behind
  the purchase, which is also why review risk is low.

## Permissions and privacy

| Permission | Purpose string (draft) a reviewer would accept |
|---|---|
| Camera (`NSCameraUsageDescription`) | "PriceJar uses the camera to scan a product barcode so it can show the prices you already saved for that product." Requested only when the scanner is opened; every scanner feature has a manual alternative if denied. |
| Tracking (`NSUserTrackingUsageDescription`) | "Allow tracking so the ads that keep PriceJar free can be more relevant. Your prices, stores and shopping lists never leave your iPhone." |

Nothing else: no location, no notifications, no contacts, no photo-library permission (PhotosPicker
does not need one), no HealthKit, no Sign in with Apple, no backend.

**Privacy story, two sentences:** Your items, prices, stores, lists and trips are stored only on
your iPhone in the app's own SwiftData store, and PriceJar has no server and no account, so there is
nothing to sync, sell or breach. The single component that uses the network is the Google AdMob SDK,
which receives device and advertising identifiers to serve ads — declared in
`PrivacyInfo.xcprivacy`, in the App Store privacy labels and in the privacy policy page, and
switched off entirely once Remove Ads is purchased.

## Guideline risks considered

- **4.2 minimum functionality.** The rejection pattern here is "a unit-price calculator". PriceJar
  is not one: it is a persistent multi-entity database (items, stores, price entries, lists, trips)
  with normalisation across two measurement systems, per-item price history and charts, a basket
  planner that compares stores, statistics and CSV export, across five screens. The sample-data
  offer on first run means the reviewer sees a populated tool within ten seconds instead of five
  empty tabs — the cheapest 4.2 insurance there is.
- **4.3 spam / duplication.** This is the account's first App Store app, so there is nothing on the
  account to duplicate. The category's existing apps are not a template family (they are four
  unrelated small apps, two abandoned), and PriceJar's own screens — a verdict sheet, trip mode,
  per-store basket comparison — do not exist in any of them. The shared factory skeleton stays
  internal: its own colour palette (deep green / amber), its own icon, its own copy, no visual or
  naming resemblance to ReceiptLens or PlantCue. Store copy will not use the words used by the
  incumbents' listings.
- **5.1.1 data collection and storage.** One permission, requested at point of use, with a purpose
  string that names the feature and is true; no data collected beyond what AdMob requires; app
  functions if camera and tracking are both denied (nothing is gated on consent, which is the
  5.1.1(iv) requirement); the ATT prompt is separate from and later than any onboarding.
- **Also considered:** not finance (no bank connections, no payments, no real-money movement, no
  investment or credit copy), not health, not kids-category, no user-generated content to moderate,
  no web view, no system-level claims.

## Open risks

1. **Small proven market.** The top four price-book apps have 11–19 ratings between them. Either the
   demand is real but undiscoverable, or it is small. The evidence says the *behaviour* is common
   and the *apps* are bad, but ASO carries this app: the keyword field must fight for "price book",
   "grocery prices", "unit price", "price tracker", "shopping list budget", and the subtitle must
   say what it is in six words. Cheap to test, and the honest downside case is low downloads rather
   than a rejection.
2. **Data-entry friction is the real killer** in this category, not features. If recording a price
   takes more than ~10 seconds, retention dies and the price book stays empty. Trip mode, barcode
   recall and pre-filled defaults exist for exactly this; the spec should carry a testable
   acceptance criterion (a known item's price recorded in ≤4 taps plus the number).
3. **We cannot name products from barcodes offline.** Two competitors were punished in reviews for
   this expectation. Mitigation is honesty, not engineering: the scanner is described as "recall your
   own items" in-app and in the listing, and the first scan of a new barcode is a one-time naming
   step. Reviews that ask for online lookup will still arrive.
4. **ATT denial lowers ad revenue** on iOS; the one-time Remove Ads purchase and the high session
   frequency are the hedge. Expect ad revenue per user well below the AppGallery lane's assumptions.
5. **Unit-price arithmetic must be exact** across kg/g/L/mL/oz/lb/fl oz/count and locale decimal
   separators. A single wrong per-unit figure destroys the entire premise. Unit tests are
   non-negotiable and the spec should list the conversion table explicitly.
6. **Name.** "PriceJar" returned no App Store match on 2026-09-08, but only App Store Connect is
   authoritative and the human must confirm at app-creation time. Fallbacks in order: PricePocket,
   PriceLedger, BasketBook. Trademark-wise "PriceJar" avoids the Primark/PriceMark collision that
   ruled out an earlier candidate name.
7. **Nine-language listing** will be machine-drafted and needs native review before a serious
   launch, same caveat as ReceiptLens and PlantCue.
8. **AdMob prerequisites are human gates:** AdMob app + banner unit + interstitial unit, and the
   non-consumable IAP created in App Store Connect. Until the real IDs land in the registry the
   build must use test IDs, and `factory-ios-publish.yml` must keep refusing to submit with test
   IDs (`ca-app-pub-3940256099942544`).

---

*Next step: a human adds the `approved` label to the issue. No spec, code or registry entry has been
created.*
