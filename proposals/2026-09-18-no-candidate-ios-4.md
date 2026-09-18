# iOS opportunity research, round 5 — **no strong candidate**

**Date:** 2026-09-18 (fifth research round. Earlier: `2026-09-15-no-candidate-ios.md`,
`2026-09-15-no-candidate-ios-2.md`, `2026-09-15-site-calc-ios.md`, and the ShiftSlip/PriceJar
proposals)
**Verdict:** I am not proposing an app. The best candidate scores **15/25**, against SiteCalc's 19,
PriceJar's 22 and ShiftSlip's 23. It fails the two filters that now matter most — 1 (give-away) and
4 (clone flood) — and it fails them on primary App Store data, not on judgement.

Per the step's instruction this file is the deliverable. No issue was opened, no spec, code or
registry entry created.

**Two things in this round are worth more than the candidates**, and both are measurements rather
than opinions:

1. Filters 1 and 2 are pulling in opposite directions, and in these five storefronts they are close
   to mutually exclusive. See "The finding".
2. **ShiftSlip's zero downloads look like a listing defect, not a market verdict** — and it is
   measurable today. See "The ShiftSlip measurement". If that reading is right, the cheapest next
   move for the factory is a metadata fix on an app that already exists, not a fourth app.

---

## Method actually used

Per the brief: local language first, Apple's own feeds only.

- Swept the **grossing and free charts** for Reference (6006), Utilities (6002), Productivity (6007),
  Education (6017), Lifestyle (6012) and Food & Drink (6023) in `de`, `es`, `it`, `fr` and `br`
  before any English query.
- Ran ~35 keyword queries against Apple's search endpoint **per storefront in the local language**
  (`conjugaison`, `Fahrtenbuch`, `Stammbaum`, `nudos`, `calendario lunar`, `Vokabeltrainer`,
  `currículo`, `cronograma de estudos`, `libretto universitario`, `Notenrechner`, `Dart Zähler`,
  `rapportino di lavoro`, `parte de trabajo`, `bon d'intervention`, `Zuschnitt`, `huerto`,
  `Gemüsegarten`, `orto`, `cantina vini`, `namaz vakitleri`, `özgeçmiş`, …). Every rating count,
  price, version and update date quoted below came back from that endpoint or from
  `itunes.apple.com/lookup` **today**, and is primary.
- Read complaints on the listings themselves via Apple's customer-review feed
  (`/rss/customerreviews/id=…`), not on Reddit. That worked for the German mileage apps; it failed
  for the Brazilian CV leader, whose recent feed is wall-to-wall five-star one-liners.

**Limitation I want on the record, because the owner raised filter 2 specifically.** I have no
keyword-volume tool: App Store Connect's search-popularity index is not reachable from here and no
third-party ASO data was used. My proxy for "does this term have traffic" is indirect — whether apps
*named after the term* accumulate large rating counts in that storefront, plus whether the phrase is
one a person would plausibly type. It is a decent proxy (nobody accumulates 24,766 ratings on
"Dart Zähler App" in a term nobody searches) but it cannot separate a high-traffic term from a
medium-traffic term, and it cannot tell me whether a new app could *rank* for it. Where that
distinction decides a candidate, I say so.

---

## The finding: filter 1 and filter 2 are measuring opposite ends of the same distribution

Round 3 concluded that "offline, no account, one-time purchase" is the default indie positioning, so
the only question worth asking is **what we give away that the incumbent cannot afford to give away**.
This round added filter 2: **name the term a buyer already types**. Running both against real
storefront data produces a clean and uncomfortable pattern:

**Every term with enough traffic to be findable is already served by free, ad-supported incumbents
with five-figure rating counts.** A high-traffic search term is precisely what attracts the
ad-supported clone economy, so by the time a term is worth ranking for, "free, offline, with a cheap
remove-ads IAP" has already shipped there five or six times. Measured today:

| Findable term | Storefront | Leader | Its business model |
|---|---|---|---|
| `Dart Zähler` | de | Dart Zähler App Punkte Rechner, **24,766 ratings** | free, ads, cheap unlock |
| `currículo` | br | Currículo Pro, **31,617** | free, ads + IAP |
| `Vokabeltrainer` | de | phase6, **82,477** | free + publisher content |
| `calculadora científica` | br | Calculadora₊, **40,717** | free |
| `conjugaison` | fr | Conjugaison française, **11,056** | free |
| `árvore genealógica` | br | FamilySearch, **52,135** | free, non-profit, forever |
| `cronograma de estudos` | br | Aprovado, **13,310** | free |

**And every field where an incumbent charges for something we could give away free is a field nobody
searches.** The give-away test passes beautifully in field-service reports, maintenance logs,
cut-list optimisers, site diaries and garden planners — and each of those fields' *entire App Store
presence* totals under ~200 ratings:

| Give-away passes | Storefront | Whole field |
|---|---|---|
| `bon d'intervention` | fr | best app 198 ratings; next 108, 68, 7, 5, 1, 0, 0 |
| `parte de trabajo` | es | 155, 154, 7, 7, 4, 3 |
| `rapportino di lavoro` | it | 79, 49, 26, 23, 8, 7, 5, 2 |
| `Zuschnitt` (cut list) | de | 21, 1, 0, 0, 0 — plus a €2.99 app with 0 |
| `Gemüsegarten` planner | de | 5, 4, 1, 0, 0, 0, 0, 0, 0, 0 |
| `Bautagebuch` | de | 70, 37, 35, 32, 32, 18 (the 2,730 is PlanRadar, B2B SaaS) |

This is not two independent filters. It is one distribution, and the factory is asking for a point
that is at both ends of it at once. **Darts is the cleanest case in five rounds:** German search term
with obvious traffic, six apps over 1,500 ratings, the core is offline arithmetic (501 checkout
routes), non-US anchor, no permissions, no dataset — it passes filter 2 better than anything else I
measured, and it dies on filter 1 in one line, because *every* incumbent is already free,
ad-supported and sells a cheap ad removal. That is our business model, shipped six times, in the
field that best satisfies the new filter.

---

## The ShiftSlip measurement

The brief says the discovery problem is what makes filter 2 urgent: four days on the store, zero
downloads, zero ratings. That is confirmed primary — `com.proapps.shiftslip` → id **6810790853**,
"ShiftSlip: Tip & Shift Log", Finance, released **2026-09-14**, updated **2026-09-16**, **0 ratings**.

But the market is not what the data says is wrong. Apple's search endpoint for the US storefront,
query **`tip tracker`**, returns twelve apps:

| App | Ratings |
|---|---|
| ServerLife - Tip Tracker (`id1098987860`) | 9,710 |
| TipTracker - track your income (`id1161307849`) | 9,397 |
| Just The Tips: Tip Tracker (`id937297529`) | 3,031 |
| Waiter Pal: Tip Tracker (`id1619187216`) | 795 |
| TipSee (`id664659826`) | 266 |
| Tip Tracker° (`id1589026466`) | 165 |
| TipKeepr - Server Tip Tracker (`id6745801270`) | 108 |
| Daily Tip Tracker (`id6755612721`) | 33 |
| Checkout - Server Tip Tracker (`id6759942669`) | 26 |
| Tip Tally Tracker (`id6746761105`) | 8 |
| Tip Tracker: TipThat (`id6757204261`) | 2 |
| **TipOut: Server Tip Tracker** (`id6756600088`) | **0** |

ShiftSlip is not in that list. It appears only on a brand-name query (`shiftslip`), at position 9,
behind Shyft, Shiftsmart and ScheduleFlex. **Apps with zero and two ratings rank for the term;
ours does not.** The one structural difference is the title: every app above carries the literal
phrase *Tip Tracker*; ours carries *Tip & Shift Log*. Factory rule 10 says the store name must
contain the search keyword — ShiftSlip's name contains the keyword's first word and not the word
people actually type.

**Caveats, stated because this matters:** the search endpoint is not the App Store's ranking
algorithm, a four-day-old app with no installs has no engagement signal to rank on, and keyword
fields (100 chars, invisible from outside) may already contain "tracker". So this is indicative,
not proof. It is, however, cheap to act on and cheaper than a build week.

One more thing surfaced while checking: **`com.proapps.pricejar` returns no result in the US
storefront lookup**, although `factory/apps.json` records PriceJar as `status: live`. Either the
registry is ahead of the store or the app is not where the registry says it is. Worth resolving
before the next release, per the factory's own "check the artifact, not the intention" rule.

---

## The five candidates

Scored 1–5. Build effort and Apple review risk are inverted (5 = cheap / low risk).

| Candidate | Demand (App Store) | Competitor weakness | Build effort⁻¹ | Monetization fit | Review risk⁻¹ | Total |
|---|---|---|---|---|---|---|
| Currículo / CV builder (br·it·tr·fr) | 5 | 3 | 4 | 2 | 1 | **15** |
| Fahrtenbuch — German mileage logbook | 4 | 2 | 2 | 3 | 3 | **14** |
| Cronograma de estudos (br) | 4 | 2 | 4 | 2 | 2 | **14** |
| Notenrechner / libretto universitario (de·it) | 3 | 2 | 4 | 2 | 3 | **14** |
| Árbol genealógico — offline family tree | 5 | 1 | 2 | 2 | 2 | **12** |

Calibration: ShiftSlip 23, PriceJar 22, SiteCalc 19. Nothing here is close, and three of the five
fail a hard filter outright rather than merely scoring low.

---

## Candidate 1 — Currículo / CV builder (15), the near-miss

**Why it looked good — it is the best filter-2 score I have ever measured.** The search term is the
word for the document itself, in six of our nine locales, and the fields are large:

| Storefront | Field |
|---|---|
| br | Currículo Pro `id1047522998` **31,617**; Currículo Vitae em PDF `id6478036307` **21,940**; Currículo Fácil 2027 `id6450423102` **13,288**; Currículo em PDF `id6740196922` **6,914**; Meu Currículo `id6472943302` 2,010; Currículo Fácil e Rápido `id1553532418` 1,581 |
| tr | CV Maker & Pro Resume Builder `id1475886222` **23,275**; CV Maker `id6447780121` **14,436**; Talley `id1562803362` 7,139; CV Builder `id1661532936` 4,726 |
| it | Curriculum Vitae Gratuito · CV (CVpop) `id1473493711` **16,949** |
| fr | CV Gratuit Français & Designer `id1473493711` **9,544**; CV Designer `id1457796755` 1,834 |
| es | Currículum vítae - Crear CV `id6740196922` 1,866; CV Engineer 850 |
| de | ~700 at best — the one storefront where this is not a market |

**And the give-away case is real in Brazil.** Currículo Pro's in-app purchase list, read off its
listing today: *Stop Ads R$ 12,90*, **Edit R$ 49,90**, **Styles R$ 59,90**, *Edit + Styles R$ 59,90*,
*Unlock All Styles R$ 12,90*, *Go Pro R$ 29,90*, and weekly subscriptions at **R$ 24,90 and
R$ 39,90**, monthly R$ 48,90, semester R$ 97,90. Charging a job-seeker R$ 49,90 to *edit their own
CV*, or R$ 39,90 a week, is the kind of thing an incumbent cannot walk back without losing the
revenue — the ShiftSlip structure.

**Why it fails anyway — filter 4, and not marginally.** This is the most cloned category on the App
Store. In the Brazilian and Italian results alone I counted IDs issued well inside the 18-month
window — `6740196922`, `6752897922`, `6754315344`, `6753...`, `6755...`, `6759621858`, `6478036307`,
`6455259592`, `6453171669`, `6451216090`, `6448645054`, `6447780121` — all doing exactly this, most
of them free-with-IAP. Filter 4 says four is a reject; there are more than a dozen. Submitting a
template-driven résumé builder with ads is handing a reviewer guideline 4.3 on a plate, which is why
review risk scores 1.

Two independent problems, either of which would be enough on its own:

- **Not every incumbent is greedy.** CVpop (16,949 ratings, Italy) already lets a free user create
  *and download a PDF*, paywalling only advanced templates. Our give-away is already given away in
  the second-largest field.
- **Occasional use.** A CV is written over two evenings and touched once a year. This is the trap
  that killed document expiry, home maintenance, meter readings and tenancy inventories in earlier
  rounds — and here the audience is job-seeking, which is the worst moment to ask anyone for money.

**Filter 2 footnote that generalises beyond this candidate.** "High-traffic term" and "term we can
rank for" are not the same thing. Ranking for `currículo` against a 31,617-rating incumbent with an
ASO budget is not free distribution either. The filter as written ("name the term a buyer would
type") is necessary but not sufficient; what the factory actually needs is a term with traffic
*whose top results are weak*.

---

## Candidate 2 — Fahrtenbuch, the German mileage logbook (14)

**Why it looked good.** It is the shape round 3 asked for: a national, stable, statutory
record-keeping duty (the *ordnungsgemäßes Fahrtenbuch* required to substantiate private-vs-business
use of a company car), a single search word every German company-car driver knows, and a field
comfortably over the ratings floor:

| App | State |
|---|---|
| [Fahrtenbuch](https://apps.apple.com/de/app/id286070473) | **€8,99 paid up front, 7,938 ratings, 4.5★**, updated **2026-08-05** |
| Vimcar `id919917811` | 27,312 ratings — fleet SaaS, hardware dongle |
| Mercedes-Benz Fahrtenbuch `id1536161235` | 7,304 |
| Driverslog Pro 2 `id1046975003` | 2,592 |
| Fahrtenbuch von Driversnote `id924418916` | 2,520 |

**Why it fails: filter 1, decisively.** Permanence is already sold, cheaply, by a well-run incumbent.
The €8.99 app has been on the store since 2010, was updated six weeks ago, and its review feed is
people thanking the developer for support: *"Ich nutze diese Fahrtenbuch App bereits seit 10 Jahren
ohne Probleme"* (Lefreal0203, 5★), *"exzellenter Support"* (unilosser, 5★). There is nothing it
cannot afford to give away, because it already gave away the thing we would have given away — a
one-time price — fifteen years ago.

**Second, independent blocker: build effort scores 2.** The complaints that do exist are about
*automatic* trip detection — Driversnote's *"Der iBeacon ist absolut unzuverlässig… die Fahrten nur
sporadisch aufgezeichnet"* (Enttäuschung 100, 1★), and the €8.99 app's own 1★ review about
background location not firing. Automatic detection is the feature, it needs Always-on location plus
motion, it is a review-friction permission, and it is not a week's work to do *better* than two
companies who have been iterating on it for a decade. A manual-entry Fahrtenbuch is a paper book.

**Third: a compliance line we must not cross.** The German tax authority's requirement is that the
log be closed and tamper-evident. An app that lets a user silently rewrite last March is not
*ordnungsgemäß*, and claiming otherwise would breach factory rule 4 (truth in copy). Implementable —
immutable entries with a visible edit trail — but it is exactly the "stale law offline" family of
risk, and the differentiator dies without the claim.

---

## Candidate 3 — Cronograma de estudos, Brazilian study-hours tracker (14)

**Why it looked good.** Brazil's *concurseiro* and ENEM culture is a genuine daily-use,
record-keeping habit — hours per subject, revision cycles, error logs — and the field clears the
floor easily: Aprovado `id586767537` **13,310**, Easy Study — ENEM e Concursos `id993247888`
**12,636**, Cronograma de Estudo e Tarefas `id1278473923` **7,323**, Gran Gerenciador de Estudos
`id1535120105` 3,916, YPT 2,021. Search terms (`cronograma de estudos`, `controle de estudos`) are
ordinary Portuguese, and the app needs no dataset and no permissions.

**Why it fails.** Three ways.

1. **Filter 1: the incumbents are free.** Aprovado and Easy Study are free, and the adjacent giants
   (Forest 20,659 in br, Focus Plant 11,363, Focus To-Do 17,513) already sell one-time unlocks.
   Nothing here costs an incumbent anything to match.
2. **It collides with our own registry.** HabitCue is a habit tracker already in `factory/apps.json`.
   A study-streak tracker is not the same entity model, but the factory's own rule is "must not
   duplicate anything already in `factory/apps.json` (any platform)", and I am not going to argue
   around the rule that exists to stop exactly this.
3. **Single low-ARPU locale.** The Spanish and Italian equivalents do not exist as markets: the whole
   `oposiciones`/`concorso` study-tracking field returns apps with **2 and 0 ratings**. Eight of nine
   locales are dead weight, and the live one is the cheapest.

---

## Candidate 4 — Notenrechner / libretto universitario (14)

**Why it looked good.** Two non-English storefronts clear the floor independently — de: Notenapp
`id822943895` **12,129**, Notan `id1487338991` **9,128**, AbiPlaner `id1400077683` 3,231; it:
Uniwhere `id872690072` **9,602**, MyLibretto `id914172791` **6,855** — and both terms are things
students type verbatim.

**Why it fails.** The incumbents are free and entrenched, so filter 1 has no purchase; the audience
is students, which is the weakest possible remove-ads case; and the differentiator that would matter
("tell me what my *Abitur* average will be") is sixteen divergent *Bundesland* rulebooks, which is
filter 6's fifty-states trap in German. Strip that out and it is a weighted-average calculator that
two apps with five-figure rating counts already give away.

---

## Candidate 5 — Árbol genealógico, offline family tree (12)

**Why it looked good.** Demand is large and genuinely multi-locale, which almost nothing else here
is: FamilySearch **52,135** (br), 3,913 (de), 3,741 (es), 3,098 (fr), 2,789 (it); MyHeritage
**15,337** (fr), 12,569 (de), 9,026 (br), 4,398 (es); Ancestry 4,827 (de). MyHeritage is the
**#1 grossing Reference app in France**. The terms are ordinary words in every one of our locales,
and a private, on-device tree is a real privacy pitch against products whose model is a shared public
tree plus record subscriptions.

**Why it fails: filter 1 is unanswerable here.** FamilySearch is free, unlimited, run by a
non-profit, and is not going to start charging — you cannot undercut free-forever. And the paid
niche is taken by a good one-time purchase: MobileFamilyTree 11 `id6480510866`, **€14,99, 916
ratings**, updated yesterday.

Filter 4 kills it independently: GensTree `id6502604080`, Árbol Genealógico Rápido `id6759252139`,
Árvore Genealógica & Herança `id6754881010`, Arbor `id6783099492`, Genoria `id6804055018`, Crea
Albero `id6741139774` — six 2026 IDs in the same niche, all with 0–189 ratings. Build effort scores
2 as well: a tree editor plus GEDCOM import/export plus pedigree rendering is not a week.

---

## Also looked at and dropped fast

All measured today, local language first.

| Idea | Killed by |
|---|---|
| **Darts scorer (de)** | The round's sharpest lesson. Leader `id1511427031` **24,766**, DartCounter 8,218, Dartsmind 3,768, Pro Darts 1,948, Dart Scores 1,829, Russ Bray 1,600 — and every one is free, ad-supported, with a cheap ad-removal IAP. Our exact model, already shipped six times |
| French conjugation | `id536600573` **11,056 ratings, free, last updated 2022-12-06** — a stale, free leader is not an opening when it is free. One locale only: the Spanish, Italian and Portuguese conjugation fields top out at 805, 687 and 9 ratings. Guideline 4.2 would also be live against a lookup tool |
| Vokabeltrainer (de) | Huge (phase6 **82,477**, Quizlet 107,114, cabuu 16,341, Lernbox 10,424) and closed at both ends: Quizlet gives everything away, phase6's moat is licensed publisher vocabulary we cannot ship, AnkiMobile owns the paid slot |
| Prayer times (tr) | Azan Time Pro **491,179**, Adhan Times 125,904, İslam Vakti 19,231, Ezan Vakti Pro 14,492 — plus Diyanet's own official app. All free. Nothing to give away |
| Knots (de·es) | Knots 3D `id453571750` is a **€6,99 one-time purchase, 3,933 de / 477 es ratings**. One-time permanence already sold; the product is 3D animation content, not a week's build |
| Moon / lunar calendar (es) | Clears the floor (`id1126370589` 6,258; 2,428; 1,426; 1,419) but every incumbent is free, the app is one screen of astronomy (4.2), and the gardening angle would mean shipping planting claims the factory cannot stand behind (rule 4) |
| Scientific calculator (br·es) | Calculadora₊ **40,717** br / 14,497 es, Photomath 47,268 br — free, and Apple ships a scientific calculator. 4.2 in its purest form |
| Recipes (it) | GialloZafferano **18,290** and Gronda 3,624 — the product is licensed recipe *content*, which the factory cannot produce or ship |
| Wine cellar (it) | Oeni 1,701 and Vinocell **€9,99 one-time** 579, under a 33,937-rating Vivino whose value is its network catalogue. Occasional use |
| Baby names (de·es) | Whole field: 824, 470, 302, 78, 70, 24 ratings. Far under the floor |
| Field-service reports / work orders (fr·it·es) | See the table in "The finding" — the give-away test passes and nobody searches. B2B SaaS with App Store presence in the double digits |
| Bautagebuch / diário de obra (de·br) | Same shape (70/37/35/32 in de; 93/22/9/8/6 in br), plus it would sit next to SiteCalc in our own catalogue |
| Cut-list optimiser, garden planner (de·it·es) | Fields of 0–21 ratings *and* a 2026 clone flood — simultaneously empty and crowded, the same pathology round 3 found in European construction calculators |
| Angelschein / exam prep (de) | Leader 1,130, and the content is a state-by-state official question catalogue — sixteen rulebooks, revised yearly |
| Test DGT (es) | Ranks #8 free *and* #8 grossing in es Reference, so the demand is real — but the question pool is the DGT's, and it tracks traffic law that changes. Forbidden by the dataset rule |
| Coin / TCG / antique scanners | The single most profitable Reference pattern in de·es·it·fr (CoinSnap, FoilSnap, HoloDex, AntiqSnap, Collectr). Every one needs a live price database and an ML model — both forbidden |
| AI translators, Bible/Hallow, ancestry DNA, PictureThis/PlantIn | The rest of what actually grosses in our storefronts. All network, all content, or both |
| Everything rejected in rounds 1–3 | Re-checked nothing has changed where it was cheap to check; not re-opened |

---

## What to hunt next round

1. **Fix the listing before building anything.** The ShiftSlip measurement above says a zero-rating
   competitor outranks us for our own keyword. Rename per factory rule 10 so the store name carries
   the phrase people type (*Tip Tracker*, not *Tip & Shift Log*), fill the 100-character keyword
   field, and re-measure the same query in a week. If ShiftSlip starts appearing for `tip tracker`
   and still gets no downloads, *then* the market verdict is in and it is worth a research round. As
   it stands the factory has never actually tested whether its apps are findable.
   Resolve the PriceJar lookup discrepancy at the same time.
2. **The owner has a choice to make between filter 1 and filter 2, and I cannot make it.** The data
   says the intersection is very close to empty. The three ways out, in the order I would rank them:
   - **Enter a findable, already-ad-supported field and win on decency rather than on give-away.**
     The Brazilian CV field is the live example: an incumbent with 31,617 ratings charges R$ 49,90 to
     edit a document and R$ 39,90 *a week*. "Everything free, one cheap permanent ad removal, no dark
     patterns" is a real position — it is just not the give-away test, and it means accepting
     guideline 4.3 exposure in a crowded category.
   - **Accept that a give-away-test winner will need distribution the factory does not have.** The
     fields where filter 1 passes cleanly are ones nobody searches. Winning there requires
     acquisition, and there is none.
   - **Keep both filters and accept more "no" rounds.** Defensible, and cheaper than a wasted build
     week — but five rounds have now produced one shipped proposal.
3. **Run a round in Turkish.** I touched `tr` twice and both fields were unexpectedly large — the CV
   field alone carries 23,275 / 14,436 / 7,139 / 4,726 ratings across four apps, comparable to Brazil
   with a fraction of Brazil's indie competition, and the factory already ships a Turkish listing.
   That storefront has never had a dedicated pass, and it is the only untested surface I found.
4. **Stop hunting occupational record-keeping in Europe.** Round 3 suggested it; this round measured
   five variants of it in four languages (work orders, intervention reports, site diaries,
   maintenance logs, mileage) and every field except the German Fahrtenbuch totals under 200 ratings.
   The vein is empty on the App Store even where the work is real. It is spent.

---

## Source discipline

Every rating count, price, in-app purchase list, version, update date and App Store ID in this
document was fetched on **2026-09-18** from `itunes.apple.com` search, lookup, chart and
customer-review feeds, and is **primary** — including the Currículo Pro IAP list, the quoted German
mileage-app reviews, and the `tip tracker` result set. The ShiftSlip and PriceJar bundle lookups are
primary.

Marked **not primary / inferred**, and not load-bearing for the verdict: that Apple's search endpoint
ordering reflects App Store search ranking (it is a different system — the ShiftSlip finding is
flagged as indicative above); the German tax-law characterisation of an *ordnungsgemäßes
Fahrtenbuch*, which I did not verify against the statute this round because the candidate died on
other grounds; and my keyword-traffic proxy, whose limits are stated in "Method".

The Brazilian CV leader's review feed was read directly and turned out to be uninformative — recent
entries are uniformly five-star one-liners. I am recording that rather than quoting comparison
articles in its place.

---

*No issue was opened, no spec written, no registry entry created. Filed as
`2026-09-18-no-candidate-ios-4.md` per the owner's instruction.*
