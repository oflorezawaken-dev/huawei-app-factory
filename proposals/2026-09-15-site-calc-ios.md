# Proposal (iOS): SiteCalc — the construction calculator that stops being rented

**Date:** 2026-09-15 (fourth research round; the first three are
`2026-09-15-no-candidate-ios.md`, `2026-09-15-no-candidate-ios-2.md` and the ShiftSlip/PriceJar
proposals)
**Verdict:** I am proposing an app. **SiteCalc scores 19/25** — below ShiftSlip's 23 and PriceJar's
22, above every candidate of the last three rounds — and, unlike any of them, it **passes every hard
screening filter**, including filter 1, the give-away test.

One honest caveat up front, stated in full in "Open risks": this idea is **US/Canada/UK-only in
practice**, and I measured that rather than assumed it. That contradicts filter 6 ("prefer non-US
anchors"), which is a preference, not a gate. It is the real cost of this pick and the owner should
weigh it before approving.

---

## Pitch

Carpenters, framers, remodellers and DIY builders do arithmetic all day in a base-12, mixed-fraction
number system that no ordinary calculator understands: 14' 3-5/8" + 9' 11-3/4", divided by 16" on
centre. For forty years the answer has been a Calculated Industries *Construction Master* — a $70–$100
handheld, and since mid-2024 an iPhone app that **only rents**: $4.99/month or $39.99/year, with no
one-time or lifetime option anywhere in the company's catalogue. **SiteCalc gives that arithmetic away
permanently free** — dimensional math, rafter and stair solvers, area/volume, material estimating,
saved jobs, and PDF/CSV export — monetised by a banner on the list and settings screens and a one-time
purchase to remove it. The target user is a tradesperson who already knows exactly what a Construction
Master does, already resents paying a subscription for it, and opens the tool thirty times a day.

**Why this is the give-away test passing and not another "offline, no account" pitch:** Calculated
Industries' revenue *is* this arithmetic — twice. It is the $39.99/year subscription, and it is the
justification for the handheld calculators the company has sold since 1985. Matching a permanently-free
version cuts both lines at once. That is the same structure that made ShiftSlip a 23 (the incumbents'
revenue was the arithmetic and the export), and it is the structure the last three rounds could not
find anywhere.

---

## The five candidates

Scored 1–5. Build effort and Apple review risk are inverted (5 = cheap / low risk).

| Candidate | Demand (App Store) | Competitor weakness | Build effort⁻¹ | Monetization fit | Review risk⁻¹ | Total |
|---|---|---|---|---|---|---|
| **Construction / trades calculator (SiteCalc)** | 5 | 4 | 3 | 4 | 3 | **19** |
| Offline tide tables from TICON-4 | 5 | 1 | 4 | 3 | 2 | 15 |
| Knitting & crochet counter + yarn reference | 4 | 2 | 4 | 3 | 1 | 14 |
| Astronomy / stargazing | 5 | 1 | 1 | 3 | 2 | 12 |
| Electrical installation calculations (EU) | 1 | 3 | 3 | 2 | 2 | 11 |

Every rating count, price, version and update date below was pulled today from Apple's own
storefront and lookup API and is **primary**. Claims drawn from developer sites, forums or comparison
articles are marked **secondary** where they appear.

---

## Why the other four died

**Offline tide tables (15) — the one the new dataset rule actually unlocked, and the cleanest
failure of the give-away test in four rounds.** It clears the ratings floor in *six* storefronts at
once, which is exactly what round 3 asked for: [Tides Near Me](https://apps.apple.com/us/app/tides-near-me/id585223877)
**161,797 ratings**, and [Tide Charts](https://apps.apple.com/us/app/id957143504) (7th Gear)
**111,772 US / 13,002 BR / 7,941 DE / 7,634 FR / 5,676 ES / 2,623 IT**. The dataset problem is
genuinely solved: **TICON-4** ([SEANOE](https://www.seanoe.org/data/00980/109129/), Hart-Davis,
Dettmering & Seitz, 2025) publishes 50 tidal constituents for **4,383 globally distributed tide
gauges** as a 45 MB CSV under **CC-BY 4.0**, commercial use permitted with attribution, and tidal
constituents are astronomy — they do not go stale. Tide prediction from them is a sum of sinusoids.

It dies because **Tide Charts is already free, already offline, and already sells a one-time ad
removal for R$ 12,90 (~€2) with no subscription** — its own store copy says *"Sem acesso à internet,
enquanto no exterior? Sem problemas. Este aplicativo foi projetado para dar-lhe as previsões de maré
e lunares sem acesso à internet!"* That is our entire business model, shipped by an incumbent with
111,772 ratings and a four-year head start. There is nothing we would give away that it does not
already give away. It fails filter 3 independently: I counted **ten or more App Store IDs issued in
the last 18 months** in tides alone (`6782403294`, `6753727747`, `6780517417`, `6788731790`,
`6765971349`, `6779113618`, `6499068417`, `6751110813`, `6477821120`, `6782159193`).

The one real gap is coverage — the most critical review surfaced on Tides Near Me is *"My country was
not listed. I searched for well known areas in Oman and by Oman only and no results."* (Moteaux, 2
stars, 2024-05-03). But that gap is not stinginess: the incumbents lack those stations because the
**tide gauges do not exist there**, and TICON-4 is built from the same gauge network. The
differentiator is illusory. Worth recording so nobody re-opens this.

**Knitting & crochet (14).** Real demand — [YarnPal](https://apps.apple.com/us/app/id6738537088)
32,518 ratings, [Loopsy](https://apps.apple.com/us/app/id6745416564) 15,610, LoopCraft 5,214, My Row
Counter 3,685 — but YarnPal, Loopsy and LoopCraft **all carry 2025–26 App Store IDs**, joined by
StitchTally, RowTally and three more. A textbook filter-3 rejection. The product is also pattern
*content*, which is copyrighted, not a published static dataset.

**Astronomy (12).** The biggest numbers I found anywhere — [Night Sky](https://apps.apple.com/us/app/id475772902)
**495,274 ratings**, [Sky Guide](https://apps.apple.com/us/app/id576588894) **373,769** (Reference
category, $39.99/yr PLUS, $59.99/yr PRO, $249.99 lifetime), Star Walk 2 Plus 95,395 — and a real
subscription backlash ([Cloudy Nights](https://www.cloudynights.com/forums/topic/993808-sky-guide-pro-subscription-as-of-2026/),
*secondary*). It fails on two axes at once. The cheap permanent option **has already shipped at
scale**: [Star Walk 2 Pro](https://apps.apple.com/us/app/id892279069) is a **$2.99 one-time purchase
with 67,167 ratings**, StarMap 3D+ Plus is $2.99 with 6,851, and even SkySafari 7 Pro is a $17.99
one-time purchase with 5,466. And a sky renderer competitive with a 495k-rating incumbent is not a
week's build — effort scores 1. The serious-observer sub-field that *would* be buildable (an observing
planner and log) is the PriceJar trap: SkySafari 7 Plus has 1,600 ratings.

**Electrical installation calculations (11).** I opened the round here, in Italian and German, because
it is the archetypal professional-calculation category. It is simply tiny: one app —
[Calcoli Elettrici / Elektro Berechnungen](https://apps.apple.com/it/app/calcoli-elettrici/id993232048)
(Egal Net di Ettore Gallina, id993232048) — serves the whole of Europe in 52 languages and has
**233 ratings in Italy and 48 in Germany**, at €5.99/**year**. Far under the floor, and nothing to
undercut. It is also the wrong shape for the factory: conductor ampacity tables are normative
documents (IEC/CEI/VDE/NEC), a wrong cable section is a fire, and that is the "stale law offline"
trap wearing an engineering hat.

---

## The market: what the charts say, and why this round looked where it did

Before scoring anything I swept the **Reference (6006) grossing charts in de, es, it, fr and br**, and
the Utilities (6002), Productivity (6007) and Business (6000) charts in de, it and es — primary, from
Apple's feeds. Two results shaped the round:

1. **Paid Reference in Europe is almost entirely things the factory may not build**: network AI
   translators, Bible/Quran apps, AI identification scanners, and TCG/coin *price* scanners (prices
   are forbidden outright). The only non-AI, non-religious apps grossing in all five storefronts were
   Sky Guide and Night Sky.
2. **No trade-calculation app appears anywhere in the European Utilities, Productivity or Business
   grossing charts.** That is strong evidence professional calculation does not monetize at scale in
   Europe — and it is why SiteCalc's demand case is US, not EU.

**A note the owner should have:** the rule change permitting a static reference dataset was tested
properly and it did open a real category — tides, with a genuine CC-BY global dataset and a
six-storefront demand signal. It died on the give-away test, not on the data. SiteCalc, by contrast,
needs only a few kilobytes of published constants (nominal-vs-actual lumber dimensions, concrete bag
yields, standard sheet sizes). So the honest accounting is: **the dataset rule is not what produced
this candidate — the instruction to look at professional calculation is.**

---

## The competitors

All figures fetched from apps.apple.com on 2026-09-15.

| App | State | Price |
|---|---|---|
| [Construction Master Pro Calc](https://apps.apple.com/us/app/construction-master-pro-calc/id370406446) (Calculated Industries) | **4.8★, 39,790 ratings**, 1.12M+ downloads. v12.11.22, updated 2026-09-02 | Free download, **$4.99/mo or $39.99/yr**, 14-day trial. **No one-time option** |
| [Construction Master 5 Calc](https://apps.apple.com/us/app/construction-master-5-calc/id370412148) (same developer) | **4.8★, 13,210 ratings**. v12.10.17, updated 2026-01-31 | **$3.99/mo or $34.99/yr**. **No one-time or lifetime option** |
| [Concrete Calculator Plus](https://apps.apple.com/us/app/id1494386815) | 4.8★, **25,770 ratings** — but **stale since 2024-03-15** and single-purpose (concrete only) | Free |
| [Feet & Inches Tape Calculator](https://apps.apple.com/us/app/feet-inches-tape-calculator/id1434258634) (Tue Nguyen Minh) | 4.4★, **9,262 ratings**. v1.3.3, updated 2025-11-26 | Free; **the free version locks the addition button** behind a $2.99 IAP |
| [Material Estimator](https://apps.apple.com/us/app/id376071081) · [Pipe Trades Pro](https://apps.apple.com/us/app/id596142100) (Calculated Industries) | 3,123 and 4,300 ratings | Subscription only, same structure |

**What the reviews say they do badly.** Primary, from the Construction Master Pro
[reviews page](https://apps.apple.com/us/app/construction-master-pro-calc/id370406446?see-all=reviews):

- ★☆☆☆☆ *"Why $40/year?"* — Oct8ne, **2024-03-26**: *"the subscription price of this app is nearly
  equivalent to buying a new calculator EVERY YEAR"*
- ★☆☆☆☆ *"Recommendation"* — Uselesssssssssssssss, **2024-06-21**: *"when I recommended this app to my
  new hires, they told me it cost $20 a month"* — a 20-year customer who had bought the $70 handheld,
  computing a 16-year cost of $3,840
- ★☆☆☆☆ *"Was nice"* — H H 37, **2026-07-18**: *"they moved to a subscription that I think is way
  over-priced"*
- ★☆☆☆☆ *"Pretty Obvious Bait & Switch"* — Captain Slippyfist, **2023-05-05**: the subscription is
  *"pretty deep into the description, and not many people... are going to read that deep"*

**The decisive competitive fact.** Filter 4 warns that a paywall opening closes in about eight months.
This one has been open **since mid-2024** — the developer's own reply to the backlash is dated
**2024-06-22** (*secondary*, via Google Play listings) — and the complaints run **continuously from
2023 through July 2026**. Twenty-seven months, and **no free replacement has shipped**. The nearest
free contender, Feet & Inches Tape Calculator, paywalls its *addition button* and has no rafter, stair,
area, volume or material-estimating functions at all. That inverts filter 4 rather than tripping it:
the window has not closed because the dimensional-math engine is genuinely fiddly to build — which is
also the reason this cannot be a template reskin, and therefore a defence on 4.3.

---

## V1 — buildable in a week

1. **Dimensional calculator.** A unit-aware numeric type: feet, inches, fractions (1/2 … 1/64),
   decimal feet/inches, metres, cm, mm — added, subtracted, multiplied and divided in one expression,
   with a selectable fraction precision.
2. **A scrollable tape.** Every entry visible, labelable and correctable after the fact — the single
   loudest usability complaint about the handheld ("single-number display").
3. **Imperial ↔ metric** conversion inside the same expression.
4. **Right-angle / roof solver.** Rise, run, diagonal, pitch (in-per-ft and degrees), common rafter,
   hip/valley. Pure geometry.
5. **Stair layout.** Total rise → riser count, riser height, tread depth, total run, stringer length.
   **The user enters their own limits; the app ships no building-code values.**
6. **Area & volume.** Rooms, walls, footings, columns, slabs, circles, arcs.
7. **Material estimating** off that geometry: concrete (yd³/m³ and bag counts), studs at a
   user-chosen spacing, drywall sheets, tile with a waste %, paint from a user-entered coverage rate,
   decking, roofing squares.
8. **Jobs.** Save a named job; its tape and its material lists live under it (SwiftData).
9. **PDF and CSV export of a job — free forever.** This is the part the incumbents charge for.
10. Sample job on first run; **Remove Ads** non-consumable.

**Not in V1:** any building-code value (rise/run limits, span tables, ampacity — the stale-law trap);
**any cost, price, quoting or invoicing feature** (deliberate — see 4.3 below); laser/Bosch device
integration; an AI assistant; photos or camera; cloud sync; accounts; iPad; Apple Watch; sharing.

---

## Ads

- **Banner:** the Jobs list, a saved job's detail screen, and Settings/Reference. Nowhere else.
- **Interstitial:** exactly one, **after** a PDF or CSV has already been written to disk.
- **Never:** on the calculator/tape screen, on the rafter or stair solver, or while any result is on
  screen. This is a tool held in a gloved hand on a jobsite; an ad between a framer and a number is a
  miscut board, not a bad review.

**Why someone pays to remove them.** This is the strongest remove-ads case in four rounds of research.
It is opened dozens of times a day, every working day, by someone being paid by the hour — the exact
opposite of the occasional-use trap that killed document expiry, home maintenance, meter readings and
tenancy inventories in earlier rounds. And the audience is already primed to pay *once*: their
complaint is not "it costs money", it is "it is rented".

---

## Permissions and privacy

**No permissions at all** beyond the ATT prompt required by the factory's AdMob rules. No camera, no
location, no notifications, no contacts, no photo library — so there is no usage string for a reviewer
to argue about, which is itself a review-risk reduction.

Every job, tape and material list is stored on the device in SwiftData and never leaves it; the only
network traffic the app makes is the ad request. Nothing about a customer, a site or a measurement is
collected, transmitted or shared.

---

## Guideline risks considered

- **4.2 (minimum functionality) — the real risk, and I am not going to pretend otherwise.** We would
  be submitting something a reviewer may first read as "a calculator", which is close to Apple's own
  canonical example. The defence is that it is not one screen or one function: a unit-aware
  dimensional arithmetic engine, four trigonometric solvers, a material-estimating model, a persistent
  multi-entity job store, and document generation. Apple has also approved this app class repeatedly
  and recently — Construction Master Pro (`id370406446`) and Feet & Inches Tape Calculator
  (`id1434258634`, 9,262 ratings) are both live. **Mitigation:** lead the screenshots with a saved job
  and an exported material list, not with the keypad, so the reviewer sees a tool.
- **4.3 (spam/duplication).** The serious apps in this US field carry old IDs (2010–2018); the 2026
  entrants I found — `6786981827`, `6757513389`, `6753908597`, `6755673080` — have **0, 8, 19 and 66
  ratings** and none combines dimensional math with saved jobs and export. Against our own account the
  distinction is clean and deliberate: PriceJar and ShiftSlip are money apps, and SiteCalc ships **no
  currency field anywhere** — dropping cost estimating from V1 is partly a 4.3 decision.
- **5.1.1 (data collection).** One ATT prompt after first use, nothing gated behind consent, no
  account, no data collection beyond the ad SDK, no permissions to justify.
- **Filter 8 (Apple-owned category).** Apple's Calculator gained unit conversion and Math Notes in
  iOS 18, and neither does base-12 mixed-fraction dimensional arithmetic. Measure is an AR ruler.
  Not Apple's category.
- **Trademark.** "Construction Master" and "Calculated Industries" are theirs. The app is SiteCalc and
  must never reference them, in the listing or in the copy.

---

## Naming (factory rule 10)

Store name on the **Brand - Keyword** pattern, inside Apple's 30-character limit:
`SiteCalc - Construction Calc` (28). The searched keywords are "construction calculator", "feet inches
calculator" and "rafter calculator". Per-language `appName` values ship as the factory requires
(es-ES `SiteCalc - Calculadora Obra`, and so on), but see the first open risk — outside English they
will carry very little traffic, and the listing effort should be weighted to en-US/en-GB/en-CA.

---

## Open risks

1. **Eight of the nine factory locales are dead weight here, and I measured it rather than assumed
   it.** Feet-inch-fraction arithmetic is the reason this app exists, and metric markets do not need
   it. Every construction calculator I found in the German, Spanish, Italian, French and Brazilian
   storefronts has **0–6 ratings** — `6784948727`, `6773137907`, `6744296879`, `6780137961`,
   `6766280669`, `6806845871`, `6760567482`, `6760597761`, `6764519874`, `6794571498`, `6767523216`,
   `6752885747`, `6748490957`, `6760630950` — and nearly all carry 2026 IDs, so those storefronts are
   *simultaneously* empty of demand and already clone-flooded. **This is the main cost of approving
   SiteCalc and it directly contradicts filter 6.** The counter-argument is that ShiftSlip was also
   US-anchored, scored 23, and shipped.
2. **Correctness is safety-adjacent.** A wrong rafter length gets cut into a real board. This needs a
   genuine unit-test suite over the dimensional type and every solver, validated against published
   worked examples, plus a visible "check your work" line. It is also why build effort scores 3 and
   not 4 — a week is enough to build it, and only just enough to verify it.
3. **The keypad is a known factory failure mode.** A construction calculator's keypad is *denser* than
   the Sudoku number pad whose ninth key fell off a 384dp screen. Per CLAUDE.md this row must measure
   first and wrap or shrink; the tape takes the space the keypad leaves, not the reverse. This must be
   checked on a real phone before any screenshot is taken.
4. **The incumbent is good, not bad.** Construction Master Pro sits at 4.8★ over 39,790 ratings and was
   updated two weeks ago. We do not beat it on features and should not claim to. We beat it on price
   and permanence, and the proposal stands or falls on that.
5. **ATT denial depresses ad revenue**, as always on iOS. Here the remove-ads purchase is meant to
   carry the app rather than the banner — which is the right way round, but it does mean the IAP price
   and the ad placement deserve more care than usual.
6. **Scope discipline.** Everything in "Not in V1" is something a tradesperson will ask for. Cost
   estimating in particular must stay out, for the 4.3 reason above.

---

## Source discipline

Every rating count, price, in-app purchase list, version and update date in this document was fetched
on 2026-09-15 from apps.apple.com and Apple's own lookup and chart feeds, and is **primary** — as are
the four quoted Construction Master Pro reviews, read on the App Store listing itself per the method
note, not on Reddit. The TICON-4 licence and station count are primary from SEANOE. Marked
**secondary** and not relied on for the decision: the 2024-06-22 developer-response date for the
subscription change (via Google Play listings), the Cloudy Nights thread on Sky Guide, and the
XTide/UKHO harmonic-data licensing history.

Unlike the previous two rounds, reading complaints directly on the App Store listing worked — the
dated 1-star Construction Master Pro reviews are the core demand evidence here, and they were not
available from any comparison article.
