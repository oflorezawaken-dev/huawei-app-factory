# iOS opportunity research, round 6 — **no candidate**, but the intersection is not empty

**Date:** 2026-09-22 (sixth research round. Earlier: `2026-09-15-no-candidate-ios.md`,
`2026-09-15-no-candidate-ios-2.md`, `2026-09-15-site-calc-ios.md`, `2026-09-18-no-candidate-ios-4.md`,
and the ShiftSlip/PriceJar proposals)
**Verdict:** I am not proposing an app. The best candidate scores **17/25**, against SiteCalc's 19,
PriceJar's 22 and ShiftSlip's 23.

**The direct answer to the question the brief asked.** The owner was right and round 5 was wrong:
the intersection of filter 1 (give-away) and filter 2 (findability) is **not** empty. I hunted the
exact pattern named in the brief — *a term people already type whose leader charges instead of
monetising with ads* — and found **six** live instances in the storefronts swept, all measured
today from Apple's own feeds:

| Term with traffic | Leader | Its price | Ratings | Free equivalent? |
|---|---|---|---|---|
| `pilot logbook` | LogTen (Coradine) `id837274884` | **$79.99–$129.99/yr**, monthly $9.99/$14.99 | **10,045** | yes — MyFlightbook, free since 2010 |
| `conduit bending` | QuickBend `id1010311475` | **$6.99 one-time** | **3,952** | no (best free: 608 ratings) |
| `E6B` | Sporty's E6B `id371817955` | **$9.99 one-time**, stale since 2024-02-17 | **5,340** | ten, all under 60 ratings |
| `bowling score keeper` | PinPal `id321817464` | **$8.99 one-time**, stale since 2023-03-29 | **5,006** | six, all under 900 ratings |
| `punch list` / `site audit` | Site Audit Pro `id430234732` | **$12.90 one-time** | **11,250** | yes — 3,557 ratings |
| `drum tuner` | iDrumTune `id1234266367` | **$12.99 one-time** | **2,331** | four, all under 40 ratings |

So the round-5 sentence "every term with traffic is already served by free ad-supported incumbents"
is false as a general claim, and should be struck. **It is true of the consumer categories round 5
swept** (darts, CVs, conjugation, flashcards, calculators, prayer times) **and false of professional
and hobby-craft tools**, which is exactly where the brief pointed.

What I did not find is one of those six that also survives the other filters. Each dies somewhere
else, and for three different reasons. That is the real finding of this round, and it is in
"Why 'the leader charges' is necessary but not sufficient" below.

Per the step's instruction this file is the deliverable. No issue was opened, no spec, code or
registry entry created.

Two operational findings surfaced while measuring and they are more urgent than any candidate:
**three other apps are already called SiteCalc on the US App Store and ours does not rank for its
own name**, and ShiftSlip still has not been renamed. Both are in "Housekeeping", at the end, with
IDs.

---

## Method actually used

Per the brief: local language first, Apple's own feeds only, business model read off the listing
rather than assumed.

- Swept the **top-paid charts** — not the free or grossing charts — for Utilities (6002),
  Productivity (6007), Reference (6006), Education (6017), Business (6000), Navigation (6010),
  Sports (6004), Music (6011), Photo & Video (6008), Travel (6003), Food (6023) and Lifestyle (6012)
  in **de, es, it, fr, br and us**. The top-paid chart is the right instrument for this brief: it is
  a list of leaders that charge. The grossing charts were swept too and are, in every European
  storefront, VPNs, phone cleaners, AI chat, mail and document scanners — nothing the factory may
  build.
- Ran keyword queries against Apple's search endpoint **in the local language first**
  (`Zerspanung`, `Drehzahl Rechner`, `Kältetechnik`, `Schweißen`, `Ballistik`, `Flugbuch`,
  `Berichtsheft`, `Ausbildungsnachweis`, `Imkerei`, `Sauerteig`, `Fangbuch`, `Sonnenstand`,
  `Ackerschlagkartei`, `Spritztagebuch`, `Herdenmanagement`, `Segeln Bordbuch`, `Modellbahn`,
  `Notenblatt`, `topografía`, `náutica`, `patrón de embarcación`, `ganadería`, …) before any English
  query.
- **Read the in-app-purchase list off each leader's own App Store listing** rather than inferring
  the business model. Every price in the table above and below came from that listing today.
- Read 1–3 star reviews on the listings themselves via Apple's customer-review feed.

**Limitation on the record, unchanged from round 5:** I have no keyword-volume tool. App Store
Connect's search-popularity index is not reachable from here and no third-party ASO data was used.
My proxy for "this term has traffic" is that apps *named after the term* accumulate four- and
five-figure rating counts in that storefront. It cannot separate high from medium traffic, and it
cannot tell me whether a new app could rank. Where that decides a candidate I say so.

---

## The five candidates

Scored 1–5. Build effort and Apple review risk are inverted (5 = cheap / low risk).

| Candidate | Demand (App Store) | Competitor weakness | Build effort⁻¹ | Monetization fit | Review risk⁻¹ | Total |
|---|---|---|---|---|---|---|
| Pilot logbook (FAA 61.51 / EASA FCL.050) | 4 | 3 | 2 | 4 | 4 | **17** |
| E6B flight computer | 4 | 4 | 4 | 2 | 1 | **15** |
| Bowling league score & statistics | 3 | 4 | 4 | 3 | 1 | **15** |
| Drum tuner (lug-by-lug pitch analysis) | 2 | 3 | 2 | 3 | 3 | **13** |
| True-scale / tiled PDF pattern printing | 1 | 4 | 4 | 2 | 2 | **13** |

Calibration: ShiftSlip 23, PriceJar 22, SiteCalc 19. Nothing here is close, and three of the five
fail a hard filter outright rather than merely scoring low.

A sixth, **conduit bending**, passes every filter in the list and is excluded by the owner's own
instruction. It is scored separately below because it is the cleanest proof that the pattern is real.

---

## Candidate 1 — Pilot logbook (17), the near-miss

**Why it looked like SiteCalc wearing a flight jacket.** Everything the brief asked for lines up:

| App | Business model (read off the listing today) | Ratings (us) |
|---|---|---|
| [LogTen Pilot Logbook](https://apps.apple.com/us/app/id837274884) (Coradine, on the store since 2014-10-16, updated 2026-09-16) | free download, **Basic $79.99/yr, Pro $129.99/yr**, monthly $9.99 / $14.99 | **10,045** |
| [Logbook Pro](https://apps.apple.com/us/app/id410773111) (NC Software) | **$69.99/yr**; 30 days $18.99, 3 mo $36.99, 6 mo $53.99; Schedule Importer **$109.99/yr** | 1,735 |
| [APDL – Airline Pilot Logbook](https://apps.apple.com/us/app/id669185248) (NC Software) | **$199.99/yr** | 981 |
| [ForeFlight](https://apps.apple.com/us/app/id333252638) | **$129.99–$390.00/yr** (logbook bundled) | 3,250 |
| [AIROS](https://apps.apple.com/us/app/id6737774277) | **$169.00/yr** | 99 |
| [MyFlightbook](https://apps.apple.com/us/app/id349983064) | **free, no in-app purchases**, since 2010-01-14 | 1,040 |

- **Filter 2 (findability):** "pilot logbook" is the term, not a phrase invented to describe a
  product. Every student pilot is told to buy one in week one.
- **Filter 3 (floor):** 10,045. Passes.
- **Filter 6 (statutory anchor):** the best one available. **14 CFR 61.51** (US) and **EASA Part-FCL
  FCL.050** (Europe) both oblige a pilot to log flight time, and both specify the fields. One rule
  per market, supranational in Europe, structurally unchanged for decades. This is not the
  fifty-state trap.
- **The demand signal is unusually good, and it is not about price.** The 1-star cluster on LogTen
  is about its cloud sync destroying career records: *"the latest update deleted all my flights"*
  (Wing4ward1, 1★, **2024-04-11**); *"The new sync software is not working, and has wiped my entire
  logbook"* (Daman115, 1★, **2024-03-30**); *"I went from 12500 hrs of flight time down to 891 hrs …
  I've been paying for over a decade for this app"* (C208AV8R, 1★, **2024-02-12**); *"This app
  doesn't guarantee that you will keep the information … I finally lost almost 7 years"* (fishing
  costa rica, 1★, **2022-12-06**). An on-device logbook you own as a file is the exact answer, and
  it is the thing a subscription whose architecture *is* the cloud cannot lead with.
- Permissions: none. Review risk: low. No collision with our catalogue (PriceJar and ShiftSlip are
  Finance; SiteCalc is a calculator).

**Why it fails: filter 1, on the same precedent that killed the family tree in round 5.**
MyFlightbook is **free, has no in-app purchases at all, has been on the store since 2010, tracks
currency, imports and exports**, and its 2026 reviews are people who love it: *"this is amazing and
free"* (The Original Royski, 5★, 2026-07-31); *"Since it's free I donate a certain amount every year
as a sign of appreciation"* (@27wido, 5★, 2026-06-30); *"a sensible approach to getting our logbooks
over to the digital age"* (Noway90879098087, 5★, 2026-06-21); *"I'm a CFI and my favorite feature is
the currency section"* (Ymistaddnickname, 5★, 2026-06-24). Round 5's rule — you cannot undercut
free-forever — applies unchanged.

The honest counter-argument, and I want it in writing because it is the strongest case for
overruling me: MyFlightbook **requires an account and stores everything in the cloud** (its own
listing: *"All information is stored in the cloud. Use of MyFlightbook requires a free account on
MyFlightbook.com"*). So the price is given away; the architecture is not. What I could not answer is
why that gap has stayed open for sixteen years, and the answer I can measure is unflattering — see
the next section.

**Second, independent blocker: filter 7, exactly as with SiteCalc.** Outside the US the field is
below the floor in every storefront the factory ships to. LogTen: **878 gb, 749 au, 593 ca, 458 br,
406 es, 390 fr, 381 de, 301 it**. The only non-US apps over the floor are EFBs, not logbooks
(OzRunways 8,142 au, RWY 1,954 br, OffBlock 1,912 de). Eight of nine locales would again be dead
weight.

**Third: build effort scores 2.** Flights with a dozen time columns, aircraft, landings, approaches,
holds; totals by category; currency arithmetic; CSV import from LogTen/ForeFlight/MyFlightbook so a
switcher is not retyping a decade; PDF/CSV export. A week builds it and does not verify it, and the
thing being computed is whether a pilot may legally carry passengers tonight.

---

## Why "the leader charges" is necessary but not sufficient — the finding of this round

The brief's pattern is correct and it is measurable. What the data added is a second condition the
brief does not yet contain, and aviation is where it shows up cleanly, twice:

**Free has already been tried in both aviation fields, repeatedly, and it lost.**

- **Logbooks:** MyFlightbook has been free, ad-free and account-free-of-charge since 2010. After
  sixteen years it has **1,040 ratings against LogTen's 10,045**, while pilots pay $79.99–$199.99 a
  year to three separate companies.
- **E6B:** the paid leader has not been updated since **2024-02-17** and its recent reviews are
  brutal — *"Missing plenty of basic features. No useful updates on the horizon. W&B is a joke"*
  (Randomme25, 3★, **2026-09-18**, four days ago); *"No weight and balance calculations! I literally
  bought this app to save time … Can I get my money back?"* (YOLOMBIA, 1★, 2024-09-28); *"For $10 app
  the lack of updates is kind of unfair"* (jkude30, 3★, 2025-04-10). Against that stale, buggy,
  $9.99 incumbent, **ten free E6B apps** are live and their rating counts are 56, 38, 29, 14, 7, 6,
  3, 0, 0, 0. **Combined, 153 against 5,340.**

So in this market the give-away does not cut the incumbent's revenue, because the thing being bought
is not the arithmetic — it is trust that the number is right. A wrong crosswind component or a
mislogged instrument approach is a checkride failure or worse, and a free app from an unknown
developer does not get tried.

**Proposed addition to the filter list, for the owner to accept or reject:**

> **Filter 1b — has the give-away already been tried here?** Before proposing to undercut a paid
> leader, count the free apps already offering the same thing and read their rating counts. If free
> apps exist in numbers and none has traction, the market is not paying out of ignorance, and being
> free is not a strategy. SiteCalc passed this: the nearest free contender, Feet & Inches Tape
> Calculator, has 9,262 ratings — free *works* in that field, it just has not been done properly.
> Aviation fails it: free has been done ten times and has 153 ratings to show for it.

This also resolves the tension round 5 declared unresolvable. Filters 1 and 2 are not opposite ends
of one distribution. There are three populations, not two:

1. terms with traffic whose leader is free and ad-supported (round 5's table) — no attack;
2. terms with traffic whose leader charges **and where free has traction** — this is the SiteCalc
   slot, and it is the one worth hunting;
3. terms with traffic whose leader charges **and where free has been tried and ignored** — aviation,
   and probably most safety-critical professional tools. Looks like an opening, is not one.

---

## Candidate 2 — E6B flight computer (15)

**Why it looked good.** The purest instance of the brief's pattern I found. Sporty's Pilot Shop
sells the physical E6B whiz wheel and a $99 handheld electronic E6B, and the app is the third
product on the same shelf — the Calculated Industries structure exactly. `E6B` is the literal term a
student pilot is taught. The leader has **5,340 ratings at $9.99 and has not shipped an update in
nineteen months**.

**Why it fails: filter 4, literally.** IDs issued in roughly the last 18 months, all free, all
advertising an E6B: `6759972536`, `6742122583`, `6743019639`, `6763776403`, `6787179895`,
`6795659922` — six, where the filter rejects at four. Submitting a seventh free E6B with ads is
handing a reviewer guideline 4.3, which is why review risk scores 1.

**And it fails 1b:** those six, plus four older free ones, have 153 ratings between them.

**And it collides with our own catalogue on 4.2/4.3.** A reviewer opening our developer account
would see SiteCalc — a trade calculator with a tape — and then an aviation calculator with a tape.
I am not going to argue that one past a reviewer when the account is three apps old.

---

## Candidate 3 — Bowling league score & statistics (15)

**Why it looked good.** [PinPal](https://apps.apple.com/us/app/id321817464) is **$8.99 with 5,006
ratings, on the store since 2009-07-25 and last updated 2023-03-29** — a decade-old paid app
carrying a whole field, which is precisely the shape the brief asked me to hunt. League bowling is
weekly, seasonal and statistics-obsessed (spare conversion, first-ball average, handicap), the
scoring rules are pure offline arithmetic, there is no dataset, no permission and no Apple-owned
category. It does not touch money, construction or our existing catalogue.

**Why it fails: filter 4 again, and worse than E6B.** Free bowling scorekeepers with IDs from the
last 18 months: `6742661765` (StrikeMaster, 60), `6760368904` (PinTracker, 3), `6772218110`
(Pindeck, 1), `6773135805` (Bowlski, 61), `6781722770` (12), plus `6472614518` (Bosc, 481) and
`6456705539` (57) just outside it. The two free apps over the floor are not scorekeepers at all —
Lanetalk (2,288) is a live-scoring feed that needs the bowling centre to run Lanetalk hardware, and
League Secretary (2,078) is league administration. So the field is **simultaneously empty of free
traction and full of 2025–26 clones**, the pathology round 5 named.

Secondary: demand scores 3 because it is one storefront. USBC league bowling is a US institution;
German `Kegeln` and the European tenpin fields return nothing above 200.

---

## Candidate 4 — Drum tuner (13)

**Why it looked good.** [iDrumTune](https://apps.apple.com/us/app/id1234266367) is **$12.99 with
2,331 ratings**, the only app over the floor in its field, and the free attempts are tiny — Drum
Tuner `id6784829761` 36, Drum Tuning Calculator 25, DrumPitchPro 20, DT Tune Buddy 14; the
second-place paid app, Drumtune PRO, has 288. Only two of the free apps carry recent IDs, so filter 4
survives. Term is what a drummer types. No dataset, no permission beyond the microphone.

**Why it fails.** Two ways.

1. **The give-away does not reach their revenue.** iDrumTune's own listing sells the app *and* a
   paid drum-acoustics masterclass at learndrumtuning.com — *"It's an app and a training course"*.
   Undercutting the app leaves the course, which is where the margin is. This is the CVpop problem
   from round 5 in a different costume.
2. **Build effort scores 2 and the risk is the product.** Detecting the resonant frequency of a
   drum head lug-by-lug, in a room with a band in it, is real-time DSP where accuracy *is* the
   feature. A week produces something that looks right and is wrong, and a drummer who detunes a kit
   on our numbers leaves a one-star review that is correct.

---

## Candidate 5 — True-scale / tiled PDF pattern printing (13)

**Why it looked good.** [Print to Size](https://apps.apple.com/us/app/id949490225) is **$2.99 with
19,842 ratings**, from 2015, and the "free equivalent" search returns nothing of the kind — the
`print actual size` result set is entirely photo-printing *services* (FreePrints 814,657). Printing a
downloaded PDF sewing, quilting or woodworking pattern at exact 1:1 scale, tiled across A4 or Letter
sheets with a calibration square, is a genuine unmet job, it is pure offline PDF geometry, and it is
comfortably a week's build.

**Why it fails: filter 2, which is the whole reason that filter exists.** I cannot name the term a
buyer types. "Print to size" is the incumbent's product name, not a search. A sewist with a taped
pattern types "sewing pattern", and that field belongs to Sewpal (11,010) and YarnPal (32,826), which
do something else entirely. This is the "shift log with tip-out arithmetic" failure: a real problem
nobody searches for by name. Guideline 4.2 is live against it as well — one screen, one function.

---

## The one that passes everything and is excluded by our own rule

**Conduit bending.** [QuickBend](https://apps.apple.com/us/app/id1010311475) — **$6.99, 3,952
ratings**, built by an electrician, on the store since 2015 — and
[Conduit Bender Elite](https://apps.apple.com/us/app/id580768337) — **$8.99, 1,712 ratings**, since
2012. The best free app in the field has **608** ratings, and the second free one is a manufacturer's
conduit-*fill* calculator (767), which is a different job. So:

- filter 1 ✅ their entire revenue is offset, saddle and shrink arithmetic;
- filter 1b ✅ free has traction in the adjacent trade-calculator field (2,515 for Master Electrician
  Ref. Lite), so free is not a losing strategy here;
- filter 2 ✅ `conduit bending` is what an apprentice types;
- filter 3 ✅ 3,952;
- filter 4 ✅ no 2025–26 clone flood;
- filter 6 ✅ no legal content needed — bend geometry is trigonometry, not the NEC.

And it is **out**, because the owner ruled a fourth trade calculator out of bounds and a reviewer
comparing it with SiteCalc would be right to. I am recording it in full because it is the proof the
brief asked for: the pattern exists, it is findable with the method above, and the reason we cannot
use this one is our own catalogue, not the market.

---

## Also looked at and dropped fast

All measured today, local language first.

| Idea | Killed by |
|---|---|
| **German trade tools** — `Zerspanung`, `Drehzahl Rechner`, `Kältetechnik`, `Schweißen`, `Ballistik` | The brief's first suggestion, and it is empty. Best in each field: 30, 2, 481, 32, 384 ratings. Every one of them is a free manufacturer app (Hoffmann, Walter, CERATIZIT, BITZER, voestalpine, Hornady). Manufacturers give trade tools away as marketing; there is no paid incumbent to undercut |
| **Aviation logbook outside the US** | `de` OffBlock 1,912, `br` RWY 1,954, `au` OzRunways 8,142 — all EFBs, not logbooks. Dedicated logbooks top out at 878 (gb) |
| Sheet music reader | forScore is a real paid leader (**$24.99, 43,031 us / 5,557 de / 2,261 fr / 1,616 es / 1,481 it**) but the product is an iPad on a music stand; an iPhone-only V1 is unusable, the build is a year, and Piascore already gives a free reader away |
| Photography sun/shadow planning | Sun Seeker is paid (**$11.99, 12,916**) but free is already winning around it — SolarWatch 6,017, Lumos 3,695, Atlas Photo 2,708 free in `us`; Sonnen-Info 6,416 free in `de`. Fails 1 and 1b |
| PeakFinder / mountain identification | Paid leader **$4.99, 11,529** — but the free one is bigger (PeakVisor 13,156). Also needs gigabytes of elevation data and a terrain renderer |
| Punch list / site audit | Site Audit Pro **$12.90, 11,250** and the free "Punch List & Site Audit Report" already has **3,557** — the give-away is shipped. Construction, besides |
| Metronome, tuner, slow-downer | Paid leaders exist and are big (TonalEnergy $6.99 58,829; Anytune Pro+ $14.99 8,350) but each sits under a free app that is bigger (Smart Metronome 60,331; GuitarTuna 147,559) or is the same developer's own free tier (Anytune 8,517) |
| Document scanners | TurboScan Pro **$9.99, 296,493** is the biggest paid app I found anywhere — and Apple ships scanning in Notes and Files, and the grossing charts are wall-to-wall free scanners. Filter 9 |
| File managers, password managers, ad blockers, VPNs | The rest of what is actually paid in European Utilities. Apple now ships Files and Passwords; an ad-funded ad blocker is a contradiction; VPNs are review poison |
| Berichtsheft / Ausbildungsnachweis (de) | A genuine national statutory duty (§ 13 BBiG, 1.2 M apprentices) and the whole App Store field is **64, 51, 50, 29, 25, 15, 8** ratings, mostly employer-branded. A good spec is still not a market |
| Ackerschlagkartei, Spritztagebuch, Herdenmanagement (de) | EU-wide statutory record-keeping (Reg. 1107/2009 Art. 67) and the fields are **229, 180, 11, 9, 1, 0** — `Spritztagebuch` returns literally nothing |
| Topografía, náutica, patrón de embarcación, ganadería (es) | 2,279 for a free topographic-map app; the nautical licence field is 36/9/7/5/5; livestock is farm games |
| Segeln Bordbuch (de) | 17, 3, 2, 1, 0 — and four of the five carry 2026 IDs |
| Imkerei, Sauerteig, Fangbuch, Modellbahn, Amateurfunk, Nähen (de) | Whole-field bests: 451, 44, 776, 457, 105, 351. Far under the floor |
| Astrology natal charts | Paid leaders clear the floor (Time Nomad $8.99 2,740; iPhemeris $29.99 1,116) but the free ad-supported astrology economy is enormous, which makes our model theirs; Swiss Ephemeris licensing is a real cost; and the clone flood is the worst on the store |
| Recipes, wine cellar, knitting, board games, genealogy, tides, astronomy, knots, flashcards, darts, CVs | Re-checked the decisive numbers where it was cheap; nothing has changed. Paprika is still **$4.99 with 53,844**, Knots 3D still **$5.99 with 12,727**, AnkiMobile still **$24.99 with 2,338**. All rejected in rounds 1–5 and not re-opened |

---

## Housekeeping — two things the owner should see before the next build week

**1. "SiteCalc" is not our name. Three other apps already carry it, from three different sellers,
and all three shipped before us.** The US query `sitecalc` returns them as results 1, 2 and 3, and
**ours is not in the top 20 for its own brand name.**

| # | Name | App ID | Seller | Released | Price | Ratings |
|---|---|---|---|---|---|---|
| 1 | SiteCalc**:** Construction Calc | `6762076301` | Neil Faulkner | **2026-07-23** | Free | 0 |
| 2 | SiteCalc**:** Trades Calculator | `6761667513` | Creayo LLC | **2026-04-05** | $29.99 | 0 |
| 3 | SiteCalc **-** Build Calculator | `6761253595` | Aditya Wirayudha | **2026-03-27** | $4.99 | 0 |
| — | **SiteCalc - Construction Calc (ours)** | `6813099045` | orlando florez | **2026-09-21** | Free | 0 |

Result 1 is not merely a name clash, it is our proposal: *"Built for tradespeople who need accurate,
fast, offline calculations on the job site. No account needed. Calculators work with no internet.
FREE IN EVERY TRADE … free forever"*, plus AR measure and a LiDAR room scan we do not have. It
shipped two months before us and outranks us on our own name.

Three consequences, in order of cost. The name carries no search traffic that reaches us, so
factory rule 10's keyword half (`Construction Calc`) is doing all the work and the brand half is
doing none. The 4.3 duplication argument now points at us, because we are fourth. And the field for
`construction calculator` carries six visible 2025–26 entrants (`6792503463` 12, `6748603879` 97,
`6768104883` 39, `6790149216` 1, `6764114412` 0, `6755673080` 66), which is the clone-flood pattern
filter 4 exists to catch, arriving after approval rather than before.

Nothing in the SiteCalc proposal caught this because it searched the *category*, not the intended
*product name*. That is a one-line addition to the research step and it should be made:
**before naming an app, query the App Store for the exact name and read the sellers.**

**2. ShiftSlip has still not been renamed, and the measurement round 5 made is unchanged.**
`com.proapps.shiftslip` → `id6810790853`, still "ShiftSlip: Tip & Shift Log", still **0 ratings**,
last updated 2026-09-16. The US query `tip tracker` returns twelve apps today and ours is not among
them; the apps that do rank include one with **0 ratings** (`id6756600088`) and one with **2**
(`id6757204261`). Round 5's cheapest recommendation has not been executed and nothing can be
concluded about the market until it is.

**3. PriceJar.** `com.proapps.pricejar` still returns no result in the US, es, de or gb storefront
lookups. `factory/apps.json` now records it as `in-review`, which is consistent with that — so the
round-5 "registry says live but the store says nothing" discrepancy is **resolved**, and the registry
is the thing that was wrong. For the same reason `site-calc` is recorded as `planned` while the app
is live on the store; the registry is behind again.

---

## What to hunt next round

1. **Take the 1b filter to the fields where it passes.** The method in this round works and is
   cheap: sweep the top-*paid* charts, then check two numbers per candidate — does the leader charge,
   and does any *free* app in that field have traction. Conduit bending scores on both and is barred
   only by our catalogue. There will be others in trades we have no app in: the untried ones I did
   not have time to sweep properly are **landscaping / irrigation, marine engine and rigging,
   locksmithing, upholstery and canvas, sign-making and vinyl, stained glass, leatherwork, farrier
   and saddlery, and pool-service dosing** in the US storefront, where the Calculated Industries
   business model — handheld tool plus app — repeats.
2. **Do not spend another round on European occupational tools.** Round 5 measured five variants of
   field-service record-keeping and called the vein spent. This round added five *trade calculation*
   fields in German (`Zerspanung`, `Drehzahl`, `Kältetechnik`, `Schweißen`, `Ballistik`) and three
   statutory-record fields (`Berichtsheft`, `Ackerschlagkartei`, `Herdenmanagement`) and every one is
   under 500 ratings, usually because a manufacturer already gives the tool away as marketing. That
   is now measured twice. The European professional App Store does not exist.
3. **Decide the US question explicitly.** Three of the four best candidates ever found — ShiftSlip,
   SiteCalc, pilot logbook — are US-anchored, and filter 7 says prefer non-US. Two rounds of
   European sweeps have produced nothing above the floor in any professional field. Either filter 7
   is retired and the listing effort is openly weighted to en-US, or the factory accepts that the
   professional-tool seam is closed to it. I cannot make that call.
4. **Fix the listings before the next build.** Rename ShiftSlip so the store name carries the phrase
   people type; rename SiteCalc off a name three other sellers already occupy, now, while it has
   zero ratings and the rename costs nothing; bring `factory/apps.json` back in line with the store
   (`site-calc` says `planned` and is live). A fourth app on a developer account whose first three
   cannot be found is worth less than two renames.

---

## Source discipline

Every rating count, price, in-app-purchase list, release date, update date and App Store ID in this
document was fetched on **2026-09-22** from `itunes.apple.com` search, lookup and chart feeds and
from the apps' own App Store listings, and is **primary** — including the LogTen, Logbook Pro, APDL,
ForeFlight and AIROS subscription ladders, which were read off each listing's In-App Purchases
section rather than inferred, and the quoted LogTen, MyFlightbook and Sporty's E6B reviews, which
were read on Apple's customer-review feed rather than on Reddit or in a comparison article. The
ShiftSlip, PriceJar and SiteCalc bundle lookups and the two SiteCalc listings are primary.

Marked **not primary / inferred**, and not load-bearing for the verdict: that Apple's search endpoint
ordering reflects App Store search ranking (it is a different system — the ShiftSlip and SiteCalc
findings above are indicative, not proof); the characterisation of 14 CFR 61.51, EASA FCL.050,
§ 13 BBiG and Reg. 1107/2009 Art. 67, which I did not verify against the statutes this round because
no candidate survived to depend on them; my keyword-traffic proxy, whose limits are stated in
"Method"; and the claim that Sporty's and Calculated Industries sell hardware alongside the app,
which comes from each app's own store description and not from the vendors' catalogues.

One negative result worth recording: LogTen's customer-review feed returns nothing newer than
**2024-06**, so the sync-disaster cluster quoted above is two and a half years old and I could not
verify from the store whether it has been fixed. MyFlightbook's feed, by contrast, is current to
2026-09, which is why its reviews carry more weight in the verdict than LogTen's do.

---

*No issue was opened, no spec written, no registry entry created. Filed as
`2026-09-22-no-candidate-ios-5.md` per the owner's instruction.*
