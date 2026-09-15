# iOS opportunity research, round 2 — **no strong candidate**

**Date:** 2026-09-15 (second research pass of the day; the first is
`proposals/2026-09-15-no-candidate-ios.md`, which this file does not replace)
**Verdict:** I am not proposing an app. The best candidate scores **17/25**, the same as last
round's two near-misses and six points below ShiftSlip's 23. It fails screening filter 1 — the
give-away test — on primary evidence: the two things we would give away free are *already* given
away free by a shipped competitor.

Per the step's instruction, this file is the deliverable. No issue was opened, no spec, code or
registry entry created.

**But this round is not a repeat of the last one.** It found a measurement error in how the factory
has been researching, and that error is worth more than the candidates. See "The finding".

---

## What I was asked to check, and what happened to each lead

The owner's brief named four unexplored leads, in order. All four were worked; three died on
primary App Store data, one produced the near-miss.

| Lead | Result |
|---|---|
| 1. EU/LatAm anchors — meter readings & bill checks, vehicle inspection cycles, tenancy documentation | Meter readings → **the near-miss (17)**. Vehicle inspection → dead: the *national registry* apps are free and official (miDGT in Spain, App RUNT in Colombia); no third-party app can beat a reminder sourced from the actual register. Tenancy documentation → dead: four 2025–26 App Store IDs, 163-rating leader |
| 2. Categories whose leader exceeds 2,000 ratings | **One found** — and only because I searched in German. See "The finding" |
| 3. Free-tier cuts dated within the last 60 days | **None found.** Every paywall event I could date is older than the window: BandLab (May 2026), Medisafe (2026-01-01), the Bending Spoons portfolio (Evernote/WeTransfer/Vimeo, all pre-2026). Filter 4 says such signals expire; they have |
| 4. National, stable statutory data models | Checked four — German energy billing (§ 40 EnWG), EU driver hours (Reg. 561/2006), the Schengen 90/180 rule, French état des lieux (loi 1989 / décret 2016-382). All are genuinely national-or-supranational and stable. **None of them had an App Store field to match.** A good spec is not a market |

---

## The finding: the factory has been researching in the wrong language

Last round concluded that the offline personal-record-keeping space is closed. That conclusion was
drawn from English-language searches of a nine-language store.

Today, in German, the first serious query returned **Energy Tracker** (`id1193010972`): **4.7★,
6,018 ratings** — nearly three times ServerLife's ~2,145, the demand signal that justified building
ShiftSlip — for an app that does nothing but record household meter readings and compute
consumption. It has **not been updated since 2024-12-31**, and it is monetised by *ten separate
à-la-carte in-app purchases*, including €1.99 to remove the cap on the number of meters, €0.99 to
remove the cap on the number of contracts, €0.99 for backup and €0.99 for sync.

That app is invisible to every English-language search the factory has ever run. So is its whole
field. Last round's report worried that low rating counts meant the niches were small; at least one
of them was never small — it was in another language.

This is a method error, and it is correctable: **run the category sweep in de, es, it, fr and pt
before running it in English.** The listing ships in nine languages. A 6,000-rating leader in the
German store is worth more to this factory than a 500-rating leader in the US store, and the current
method cannot see it.

Two supporting observations from this round:

- **Our positioning is now literally a competitor's store copy.** Pool-Proof (`id6761028109`,
  free) describes itself on its App Store page as: *"All data is stored locally on your device. No
  login. No subscription. No data collection. Nothing ever leaves your phone."* — "Free forever."
  That is our proposal template, shipped by someone else, in the same month. The give-away test is
  no longer a clever filter; it is the only filter that matters.
- **Last round's killers all still hold**, so none of its rejected ideas returns: Paprika is still a
  **$4.99 one-time purchase and made cloud sync free in April 2026**; Stylebook is still **$4.99
  one-time, no subscription, no IAP**; Nara Baby is still **free with no premium tier and no ads**.

---

## The five candidates

Scored 1–5. Build effort and Apple review risk are inverted (5 = cheap / low risk).

| Candidate | Demand (App Store) | Competitor weakness | Build effort⁻¹ | Monetization fit | Review risk⁻¹ | Total |
|---|---|---|---|---|---|---|
| Utility meter readings & annual-bill true-up (DACH) | 4 | 3 | 4 | 2 | 4 | **17** |
| Pool water chemistry log & dosing | 2 | 3 | 4 | 3 | 2 | 14 |
| Schengen 90/180 + residency day counter | 2 | 2 | 4 | 2 | 3 | 13 |
| EU driver hours (Reg. 561/2006) companion | 1 | 4 | 2 | 2 | 2 | 11 |
| Tenancy move-in/move-out inventory (FR/ES/DE) | 2 | 2 | 3 | 1 | 2 | 10 |

For calibration: ShiftSlip scored 23 and PriceJar 22. Nothing here is close, and the top entry fails
a screening filter outright rather than merely scoring low.

---

## Candidate 1 — Utility meter readings & annual-bill true-up (17) — the near-miss

**Why it looked good.** It is the first idea in three research weeks that clears the ratings floor
on a non-US anchor, and the statutory frame is exactly the Pub 531 shape: under **§ 40 EnWG** a
German supplier must issue the annual statement within six weeks of the billing period ending, the
monthly *Abschlag* prepayments are set against it, and the consumer's only defence against a surprise
back-payment is their own meter readings — which is precisely what the Verbraucherzentrale tells
people to keep. The arithmetic is real work: multi-tariff meters, m³→kWh gas conversion,
consumption between irregular readings, extrapolation to period end, and the "will I owe money in
March?" forecast against the Abschlag. Offline by nature, zero permissions beyond an optional camera
for a meter photo, and it is a *household* app, so a Spanish, Italian, French and Portuguese listing
all carry real traffic.

**The field, all checked 2026-09-15 directly on apps.apple.com:**

| App | State |
|---|---|
| [Energy Tracker](https://apps.apple.com/de/app/energy-tracker/id1193010972) (best-ios-apps / Stefan Nebel) | **4.7★, 6,018 ratings.** v8.1.1, last updated **2024-12-31**. Ten IAPs: Master €6.99, Pro €3.99, *Limit aufheben (Messgeräte)* €1.99, *Limit aufheben (Verträge)* €0.99, Backup €0.99, Sync €0.99, special periods €0.99, weather data €0.49/€0.99, reminders free |
| [Zählerstände Strom Verbräuche](https://apps.apple.com/de/app/z%C3%A4hlerst%C3%A4nde-energieverbrauch/id1584696105) (Dmitrii Solovev) | 4.0★, **242 ratings**. v2.10, updated **2026-04-04**. IAPs from €2.99 ("Voller Zugang") up to €44.99 |
| [Zählerstände \| Ablesen, sparen](https://apps.apple.com/de/app/z%C3%A4hlerst%C3%A4nde-ablesen-sparen/id6479006613) (Moritz Karrasch) | 4.5★, **38 ratings**. v3.2.1093, 3 Sept. Ad-removal sold as **€0.99/month, €9.99/year or €24.99 once** |
| EHW+ (`id1548922124`) | The killer — see below |

**Why it fails: filter 1, on primary-adjacent evidence.** Our wedge would be "unlimited meters,
unlimited readings, free export, free backup, one-time ad removal". **EHW+ already gives unlimited
meters and unlimited readings away in its free base version**, on iOS, Android *and* web, and it
supports more meter types than we would (oil, district heating, PV, wallbox); it charges only for
multiple properties and some export/statistics functions
([ehwplus.com](https://www.ehwplus.com/), [netzwelt](https://www.netzwelt.de/download/26269-ehw-plus.html),
[TheAppNote review](https://www.theappnote.de/blog/zaehlerstaende-per-app-wie-gut-ist-ehw)).
Meterable sells its Pro tier as a **€5.99 one-time purchase** with CSV import/export, reminders and
backup ([meterable.app](https://meterable.app/de/)). So the entity caps we would break are already
broken for free by one competitor and for €5.99 forever by another, and the stale 6,018-rating
leader sells the same unlocks for €0.99–1.99. There is nothing here that costs an incumbent anything
to match — which is the definition of the test we now apply first.

**Second, independent blocker: monetization (2).** Meters are read monthly at best. That is the
occasional-use trap that killed home inventory (PriceJar round) and document expiry (last round):
nobody pays to remove a banner they see twelve times a year, and there is no repeat session to serve
one in.

**Headwind worth recording for any future attempt:** Germany's mandatory smart-meter rollout
(*intelligente Messsysteme*, running to 2032) removes the manual reading this whole category is
built on. The market is dated, not just small.

**I do not recommend overruling this one.** Last round's homeschool near-miss had a real
differentiator that could not legally ship; this one has no differentiator at all.

---

## Candidate 2 — Pool water chemistry log & dosing (14)

**Why it looked good.** It is the rare niche whose "database" is chemistry rather than law, so it
cannot go stale: pool volume, dosing for chlorine/acid/alkalinity/CYA, and the saturation index are
pure arithmetic. It is genuinely international — pools are a mass household product in Spain,
France, Italy, Brazil, Mexico and Australia — and in season it is used two or three times a week.
And the reference app paywalls exactly what we would give away: **Pool Math by TroubleFreePool**
(`id1228819359`, **3.6★, 285 ratings**, v512, 3 May) puts **unlimited test-log history, maintenance
reminders, unlimited pools and CSV export** behind **$7.99/year**, with free users limited to a
single log entry; its own community forum carries the complaints about that. Pool Care by Swim
University charges **$49.99/year**.

**Why it fails.** Two independent reasons.

1. **Demand, measured properly, is 2.** The reference app has 285 ratings. Whatever the size of the
   pool market, the App Store demand *for an app about it* is not proven, and that is the exact
   mistake PriceJar paid for.
2. **Clone flood, filter 3.** Checked today: Pool-Proof (`id6761028109`, free, quoted above),
   Pool Clarity: DIY Pool Care (`id6761957692`, free, v1.0.2 on 17 July, store copy *"No
   subscription, no ads, no hidden fees, no premium tier"*, monetised by Amazon affiliate links),
   Pool Care AI (`id6762838367`, 1.0★/1 rating, **$5.99 weekly** subscription, v2.1.2 on 1 Sept),
   plus Pooli and PoolFu. Three or four 2025–26 IDs, at least two advertising our positioning
   verbatim. Submitting a fifth invites guideline 4.3.

There is also a discipline problem the factory has no process for: the app would tell people how much
acid to pour into water. That needs safety copy no factory template currently carries.

---

## Candidate 3 — Schengen 90/180 + residency day counter (13)

**Why it looked good.** A supranational, precisely-specified, stable rule (90 days in any rolling
180), painful rolling-window arithmetic that people genuinely get wrong, an audience of non-EU
travellers, digital nomads and post-Brexit UK citizens, and a fresh regulatory backdrop in the EU
Entry/Exit System now counting those days at the border.

**Why it fails.** The field is small and the wedge is already shipped. Checked today:
[Schengen Calculator 90/180](https://apps.apple.com/us/app/schengen-calculator-90-180/id1054807221)
(on the store since 2015) is **4.5★ with 186 ratings** and sells yearly subscriptions at
$3.99/$7.99/$12.99; the leader,
[180 Days: Schengen Calculator](https://apps.apple.com/gb/app/180-days-schengen-calculator/id1663779128),
is **4.8★ with 850 ratings** and already sells a **£3.99 one-time lifetime unlock** while storing
everything **locally with no cloud transmission**. An 850-rating leader is under the floor, the
one-time-purchase-plus-local-storage pitch is taken, and the app is opened when you plan a trip —
not daily. Guideline 4.2 would also be a live argument against a day counter.

---

## Candidate 4 — EU driver hours (Reg. 561/2006) companion (11)

**Why it looked good.** The best statutory data model I found all week and the only one that is
EU-wide rather than national: 4.5 h driving then a 45-minute break, 9/10 h daily, 11/9 h rest,
56 h weekly, 90 h fortnightly. Millions of professional drivers across exactly the locales the
factory ships.

**Why it fails.** There is no App Store field at all.
[Tachograph](https://apps.apple.com/us/app/tachograph/id1324222679) (on the store since 2017) has
**3.8★ from 5 ratings** while charging $1.99/month or $19.99/year;
[Tachogram](https://apps.apple.com/us/app/tachogram-tachograph-app/id1494734187) (Mapon SIA) shows
**no rating at all** and was last updated **2024-08-15**; the 2025–26 entrants (Tachograph 2.0
`id6746964637`, TachoPlus `id6762611277`) are new and unrated. Drivers already carry a device that
does this — the tachograph is mandatory — so the app is a convenience, not a record. Build effort
scores 2 because a wrong answer here is a fine for the user, which makes the rules engine
safety-critical work, not a week's work.

---

## Candidate 5 — Tenancy move-in/move-out inventory (10)

**Why it looked good.** France specifies the document by law (loi du 6 juillet 1989 art. 3-2,
décret n° 2016-382 fixing its contents) and deposit disputes are a real, expensive, recurring fight
across France, Spain and Germany.

**Why it fails.** Everything at once. The clone flood is already here — Etat des lieux immo
(`id6747743582`), Location: État des lieux (`id6759527153`), Appyloc (`id6759391000`), Startloc
(`id6484595079`) — the established player,
[nockee](https://apps.apple.com/fr/app/nockee-%C3%A9tats-des-lieux/id1570016331), is **4.8★ with
163 ratings** and last updated 2025-09-01, and it sells per-inspection credits (€3.49–€19.99), which
tells you the real customers are letting professionals, not tenants. Monetization scores 1: a tenant
opens this twice per tenancy. This is the document-expiry failure mode with a French accent.

---

## Also looked at and dropped fast

All checked 2026-09-15.

| Idea | Killed by |
|---|---|
| Vehicle inspection / insurance / road-tax reminders (ES, CO, MX) | The national registers ship their own free apps — **miDGT** syncs expiry dates to the iPhone calendar, **App RUNT** reads SOAT and revisión técnico-mecánica status live. The third-party field is tiny anyway: [Info Coche](https://apps.apple.com/es/app/info-coche/id1610116608) is 3.9★ with **20 ratings**, updated 2025-06-23, and does not even do reminders |
| German *Nebenkostenabrechnung* checker | CHECK24 launched a free AI-based checker in 2026, and the analysis is OCR-plus-rules on a PDF — not an offline-first job |
| Teacher gradebook / attendance (ES + LatAm anchor) | Already answered at both ends: **4Docentes** ships the full cuaderno (classes, weighted criteria, attendance, diary) on a free plan with no time limit, and **iDoceo** is a one-time purchase. Additio's €11.99/yr is not an opening between those two |
| EU261 flight-compensation calculator and claim letter | Passes the give-away test beautifully — the claim agencies' entire revenue is the commission on arithmetic we could do offline — but it is used once every year or two, which is monetization 1, and it puts the factory into claims-and-legal framing. *(I could not verify AirHelp's App Store listing: the fetch returned 404. Recorded as unverified.)* |
| DAC7 second-hand seller record (Vinted/Wallapop, 30 sales / €2,000 thresholds) | Would be the **third money app** on this Apple account after PriceJar and ShiftSlip — filter 9 |
| Golf scorecard & handicap | 18Birdies' *free* tier already includes handicap tracking, digital scorecards and GPS on 43,000+ courses. Nothing left to give away |
| Homebrewing recipe/batch calculators | BeerSmith Mobile sits at 3.1★ over ~30 ratings; Brewfather's value is cloud sync. Field far under the floor |
| Working-time / overtime record (CJEU C-55/18, Spain's registro de jornada) | Genuinely statutory and EU-wide, and genuinely too close to ShiftSlip — a second hours-and-earnings app is the 4.3 argument against our own account |
| Gig-driver earnings, personal CRM, medication, homeschool, home maintenance, document expiry, wardrobe, pets, baby, filament, aligners, board games, ADHD, diet, cycle tracking, gift planner, budgeting | Rejected in the two earlier reports; re-checked the three decisive prices (Paprika, Stylebook, Nara Baby) and nothing has changed |

---

## What to hunt next week

1. **Search in German, Spanish, Italian, French and Portuguese first.** This is the actionable
   output of this round. The single 6,018-rating leader found today was in the fifth German-language
   query of the week and would never have surfaced in English. Run the whole category sweep per
   storefront (`apps.apple.com/de`, `/es`, `/it`, `/fr`, `/br`) and only then in `/us`.
2. **Keep the ratings floor, but read it per storefront.** A 2,000-rating leader in the German or
   Spanish store is a stronger signal for a nine-locale listing than a 2,000-rating leader in the US
   store, and the factory has never looked there.
3. **Hunt occupational record-keeping that is not earnings.** The one vein that produced a 23-scorer
   was occupational (tipped workers). Filter 9 bars a second earnings app, but not a second
   occupational one — the question to ask is which European trades are required to keep a record
   that is *not* money: inspection logs, treatment records, qualification and re-certification
   cycles, equipment checks.
4. **A decision for the owner, not for me.** Three research weeks have now produced two "no"s, and
   the reason is structural rather than seasonal: the filter set *(leader >2,000 ratings) ∧
   (offline-only, no network database) ∧ (not money, not health, not Apple-owned)* is close to an
   empty set, because a category large enough to clear the floor is almost always large because it
   is either a generic utility Apple now ships free or one that needs somebody's database (products,
   courses, foods, titles, maps). If the owner wants a third iOS app, the cheapest constraint to
   relax is one of these, and I would rank them in this order:
   - **Allow a static shipped dataset** that is physics, geography or chemistry rather than law —
     airport coordinates, unit and conversion tables, chemical constants. It cannot go dangerously
     stale the way state law can, and it reopens several categories the "no network database" rule
     currently closes.
   - **Accept a 1,000-rating floor when it is measured in a single non-English storefront**, since
     nine locales multiply it.
   - **Lift filter 9 for a money app with a genuinely different entity model.** Least attractive:
     it trades a real 4.3 risk for a category we already know is saturated.

---

## Caveats on this research

- **Primary vs secondary is marked throughout.** Every rating count, price, IAP list, version and
  update date in the tables above was fetched from apps.apple.com today. The EHW+ free-tier claim,
  Meterable's €5.99 Pro, 4Docentes' free plan, 18Birdies' free tier, BeerSmith's rating and the
  Paprika/Stylebook/Nara Baby prices come from developer sites and comparison articles and are
  marked as such — the EHW+ claim is the one that kills the top candidate, so it should be confirmed
  on its App Store page (`id1548922124`) before anyone revisits this idea.
- **I again failed to obtain primary Reddit or Apple Support Communities material.** Searches
  returned SEO content. Two rounds in a row is now a pattern, not bad luck: general-purpose web
  search does not reach forum threads well. Next week should read App Store review pages directly
  (`?see-all=reviews`) as the primary complaint source instead — that worked today.
- **The 60-day paywall window returned nothing at all.** Either no significant free-tier cut
  happened between mid-July and mid-September 2026, or the change was not covered in English. Given
  the finding above, I would not assume the former.
- **One genuine correction from within this round:** I first concluded, from a 38-rating app, that
  the German meter-reading field was tiny and killed the lead. That was wrong — I had found a minor
  app, not the leader, which has 6,018. The lead still dies, but on a different and better-evidenced
  reason, and the error is the reason the language finding exists.

---

*No issue was opened, no spec written, no registry entry created. Filed as
`2026-09-15-no-candidate-ios-2.md` because the first pass of 2026-09-15 already holds the
conventional filename; it is a separate report and neither supersedes the other.*
