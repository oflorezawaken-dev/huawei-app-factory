# iOS opportunity research, round 7 — **no candidate**, and the reason is structural

**Date:** 2026-09-22 (seventh research round, and the first with the search space opened
beyond utilities by the owner's decision of 2026-09-22. Earlier rounds:
`2026-09-15-no-candidate-ios.md`, `2026-09-15-no-candidate-ios-2.md`,
`2026-09-15-site-calc-ios.md`, `2026-09-18-no-candidate-ios-4.md`,
`2026-09-22-no-candidate-ios-5.md`, plus the ShiftSlip and PriceJar proposals.)

**Verdict:** I am not proposing an app. The best candidate scores **15/25**, against SiteCalc's 19,
PriceJar's 22 and ShiftSlip's 23. Per the step's instruction this file is the deliverable: no issue
was opened, no spec, code or registry entry created.

**The owner's premise was right and it is now measured.** Volume outside utilities is not
comparable to volume inside them — it is one to two orders of magnitude larger, and ads between
sessions really are the native business model there rather than an imposition. Round 6's European
grossing charts for Utilities/Productivity/Business contained no trade or calculation app at all;
this round's charts contain apps with **221,257**, **126,625** and **312,168** ratings in a single
European storefront.

**And that is exactly why there is no opening.** In games and content the incumbents are already
free and ad-supported. Our entire monetization model — free, ads, one-time remove-ads — *is the
incumbent model*, so we arrive with nothing to give away that is not already given away. In the
one field where two leaders had genuinely just closed their free tier (German geography quizzes,
paywalled 2026-08-10, inside filter 5's 60-day window), the free replacement had already shipped
and it is **free, ad-free and has no in-app purchases at all** — strictly better for the user than
anything we can ship. Details in "The finding".

This is not the same "no" as rounds 5 and 6. Those said the niches were too small. This one says
the fields are enormous and structurally closed to a developer with no user-acquisition budget.

---

## Method actually used

### Step 0 — the charts I read, in full

Apple's own RSS feeds, **144 of them, all fetched today (2026-09-22), zero errors**:
`topfreeapplications` and `topgrossingapplications`, `limit=100`, for

- **Games (6014)** and its subgenres **puzzle (7012)**, **word (7019)**, **board (7004)**,
  **card (7005)**, **trivia (7018)** and **casual (7003)**;
- **Education (6017)**, **Entertainment (6016)**, **Lifestyle (6012)**, **Reference (6006)** and
  **Utilities (6002)**;

in **us, de, es, it, fr, br**. (12 genres × 6 storefronts × 2 feeds = 144.)

### Steps 1–2 — searches, local language first

Every keyword query was run in the storefront's own language before any English query:
`Geographie Quiz`, `Partyspiel`, `Kopfrechnen`, `Noten lernen Musik`, `Anatomie lernen`,
`Sternenhimmel Sternbilder`, `Strickmuster Zähler`, `Zauberwürfel lösen`, `Detektiv Rätsel Krimi`,
`Skat offline`; `juego de geografia`, `impostor juego`, `solfeo`, `lengua de signos`,
`juego de detectives casos`; `quiz patente`, `cruciverba`, `scopa offline`; `code de la route`,
`belote hors ligne`.

Rating counts, prices, App Store IDs, release dates and last-updated dates all come from
**apps.apple.com / Apple's own search, lookup and customer-review feeds**. Every review quoted below
is from the app's own listing, with the date Apple stamps on it. No comparison articles were used as
evidence; none were needed.

**Limitation, unchanged from rounds 5 and 6:** I have no keyword-volume tool. My proxy for "this
term has traffic" remains that apps *named after the term* accumulate four- and five-figure rating
counts in that storefront.

---

## What the charts actually said

### 1. Puzzle, casual, board and card are one global chart, not six local ones

| Subgenre | Distinct apps in the grossing top-20 across all six storefronts | Of those, present in ≥5 of 6 |
|---|---|---|
| puzzle | 31 | **15** |
| casual | 32 | **15** |
| board | 44 | 12 |
| word | **61** | 5 |
| trivia | **60** | 10 |

Puzzle and casual are the same fifteen titles everywhere: Gossip Harbor, Royal Match, Candy Crush
Saga, Royal Kingdom, Toon Blast, Township, Gardenscapes, Homescapes, Fishdom, Travel Town, Tasty
Travels, Monopoly GO!, Coin Master, Dice Dreams, Disney Solitaire. Every one is a live-ops
free-to-play title monetised by consumable IAP and sustained by paid user acquisition. There is no
local seam and nothing in that list is a one-week SwiftUI build.

The **free** puzzle chart is worse, not better: of the 19 distinct apps in the free top-12 across
the six storefronts, **12 have App Store IDs issued in roughly the last 18 months** (Block Out!,
Meowdoku!, Colony Flow!, CubeAway, Bus Fever Party!, Bus Traffic Fever!, Brain Puzzle 3, Amaze GO!,
Food Hunt, Magic Sort!, Colorever, Arrow Escape). That is not an open field, it is a churn machine
running on install spend. We have no install spend.

### 2. Word and trivia are local — and in Europe and Brazil they are *party games*, not word games

This is the one genuinely surprising result, and it is where a small studio can still rank: 61 and
60 distinct apps respectively, with only 5 and 10 present in five or more storefronts.

But read what is actually ranking. The **word** grossing top-12 outside the US is barely about words:

- **DE:** Wahrheit oder Pflicht 18, Ich Hab Noch Nie 18 Trinkspiel, Ich hab noch nie: Naked Truth,
  Ich Habe Noch Nie・Partyspiel, Wer bin ich? Scharade, Wer bin ich Scharade · Guessly, Fakeit
- **ES:** Fakeit: Impostor, Adivina La Palabra · Guessly, Impostor (Cosmicode), Yo nunca 18,
  Adivina la Palabra - Guess Up
- **FR:** Olémains, Undercover™, Action ou Vérité Hot, Fakeit, Tu Préfères quoi ?, Devine Tête
  Charade · Guessly, Devine Tête Soirée, Je n'ai jamais
- **IT:** Fakeit, Charades Guess Game · Guessly, Non ho mai!, Impostore, Indovina la Parola,
  Guerra dei 5 secondi
- **BR:** Fakeit, Quem sou eu Charadas · Guessly, Quem sou eu? - CharadesApp, Jogo do Impostor - BAM!,
  Impostor (Cosmicode), Impostor (artGS), Picoboom

Pass-the-phone party games, bundled content, no server, no accounts, SwiftUI-buildable, monetised
by ads and content unlocks. On paper this is the factory's stack and the factory's business model,
found in the grossing charts of five storefronts. It is candidate 1 below, and it dies on the two
filters the owner asked me to watch hardest. See there.

### 3. Education is language learning, AI tutors, and national exam prep

Duolingo is #1 grossing Education in all six storefronts. Behind it: Babbel, Busuu, and a 2025–26
wave of AI speaking tutors (Learna, Loora, Praktika, Knowunity, LangLearn) that need a network by
construction and are out of scope.

The only non-language money is **national exam prep**, and it is large: `Code de la route 2026
Ornikar` is **#2 grossing Education in FR**, with MWM's at #10; `TodoTest` and `OpositaTest` are #8
and #9 in ES; `Concorsando.it` #7 in IT; `Qconcursos` #5 in BR. `Quiz Patente Ministeriale 2026` is
#5 grossing in the Italian *word* subgenre. Candidate 2 below.

### 4. Reference is translators, religion and AI collectible scanners

DE/ES/IT/FR/BR reference grossing is dominated by AI translators (DigitalSail, Air Apps, HEYOS,
BPMobile, APPLABS, DeepL) — network by construction; by religion (Hallow, Bible Chat, Haven,
Glorify, Liturgia Diária, Tariq); and by camera-AI collectible identification (CoinSnap, CoinIn,
FoilSnap, AntiqSnap, Collectr, PokéCardex) — also network by construction. This confirms the
existing memo that Europe pays for AI, religion and collectibles. None of the three is buildable
offline.

### 5. Entertainment is streaming; Lifestyle is dating

Entertainment grossing is TikTok, Disney+, Prime Video, Crunchyroll, HBO Max, national
broadcasters, plus the short-drama wave (DramaBox, NetShort). Lifestyle grossing is Tinder, Hinge,
Bumble, Badoo, Meetic, happn, plus smart-home companion apps. Both are closed by definition —
licensed content or a network service. Nothing to sweep further.

---

## The five candidates

Scored 1–5. Build effort and Apple review risk are inverted (5 = cheap / low risk).
Calibration: ShiftSlip 23, PriceJar 22, SiteCalc 19.

| Candidate | Demand (App Store) | Competitor weakness | Build effort⁻¹ | Monetization fit | Review risk⁻¹ | Total |
|---|---|---|---|---|---|---|
| 1. Party-game pack (impostor / charades / party bundle) | 5 | 1 | 4 | 4 | 1 | **15** |
| 2. Offline geography quiz | 4 | 2 | 4 | 3 | 2 | **15** |
| 3. National driving-theory exam prep (IT/FR) | 5 | 1 | 2 | 3 | 1 | **12** |
| 4. Offline national card game (Scopa / Belote / Skat) | 4 | 1 | 2 | 3 | 2 | **12** |
| 5. Text-deduction crime puzzles (Krimi-Rätsel) | 1 | 3 | 3 | 3 | 2 | **12** |

Also measured and rejected before scoring, each on a single hard filter: mental arithmetic
(`Kopfrechnen`), sight-reading / solfeo, anatomy quiz, sign-language dictionary, knitting row
counter, Rubik's-cube solver, Italian crosswords. All seven are in "Rejected below the fold".

Nothing is close to 19. Four of the five fail a hard filter outright rather than merely scoring low.

---

## Candidate 1 — Party-game pack (15). The volume winner, and a textbook 4.3 rejection

**Why it looked right.** It is the only place in any grossing chart where a one- or two-person
studio ranks alongside Playrix and Scopely, and it is the factory's stack exactly: bundled word
lists, pass-the-phone, no server, no accounts, SwiftUI, ads between rounds.

**Filter 4 (clone flood) — fails outright.** Searching `impostor juego` on the Spanish store
returns eleven apps; here are the release dates Apple reports, today:

| App | Developer | ID | Released | Ratings (es) |
|---|---|---|---|---|
| Splash: El Juego del Impostor | Cranberry Apps | `6744290388` | **2025-04-12** | 20,571 |
| Impostor - Juego de Palabras | Cosmicode Lda | `6748455155` | **2025-09-01** | 16,218 |
| Encuentra al Impostor | Sven Vucak | `6745120053` | **2025-05-18** | 5,219 |
| Imposter Who? | Sokak Technologies | `6746781192` | **2025-06-05** | 4,594 |
| Fakeit: Impostor Juego | smak apps | `6749012623` | **2025-08-12** | 891 |
| Impostor - Juego Faky | Prosperize | `6753783454` | **2025-10-09** | 311 |
| Impostor - Juego de Grupo | Jon Fernandez Calvoecheverria | `6757161327` | **2026-01-07** | 484 |

Seven apps, all with IDs issued in the last 18 months, all advertising our exact positioning. The
filter says four is a rejection. The Brazilian chart adds three more (`6751252728`, `6786653300`,
`6720754145`). The charades variant is the same story — Guessly (`6473058122`), Guess Up
(`1160484607`), CharadesApp (`1503437368`), Stirnraten (`959394136`) — and so is
never-have-I-ever, truth-or-dare and would-you-rather.

**Filter 1 for games (are the leaders weak?) — fails, on their own reviews.** The owner asked for
proof rather than assumption. Splash (`6744290388`) has **221,257 ratings at 4.7 in Germany alone**
and was **updated today, 2026-09-22**. Its recent low-star reviews are not a weakness we can
attack — they are complaints about *our own business model*:

- 3★ **2026-09-14** (Pink_fluffy_unicorn): *"Das Spiel ist das beste ich spiele es fast jeden Tag
  mit Freunden das einzige was nervt ist die Werbung"* — the best game, played daily, the one
  annoying thing is **the advertising**.
- 1★ **2026-09-05** (Ivan Pesterov): *"Ich sehe nichts mehr außer Werbung"* — I see nothing but ads.
- 1★ **2026-09-16** (Ju091012): *"Zu teuer…"*; 3★ **2026-09-06** (Lotti1110): *"Negativ das man für
  fast alles Geld bezahlen muss."*

And the five-star mass is unambiguous: *"Das ist wirklich das perfekte Spiel für Party"*,
*"Kann man wirklich überall spielen und macht immer Spaß"*, *"Ohne Abo genau so cool"*. Stirnraten
(`959394136`, 34,721 ratings, 4.7, updated **2026-09-18**) is the same picture, with a developer who
answers reviews in the thread.

An ad-supported entrant walking into a field whose only complaint is ad load is walking in with a
worse product. Reject.

**Guideline 4.3, stated plainly as the owner asked.** I cannot name a mechanic or a body of content
a reviewer would see in the first minute that no top-20 app for `impostor`, `Partyspiel` or
`charades` already offers. That sentence is the whole test, and failing to answer it is the
rejection.

---

## Candidate 2 — Offline geography quiz (15). The best-looking lead of the round, killed by a free competitor

This one deserves its own section because it nearly passed, and because what killed it is a rule
the factory should keep.

**Everything lined up.** GeoGuessr is **top-3 grossing Trivia in all six storefronts** — geography
as a game is proven demand at scale, and GeoGuessr itself needs Street View, i.e. a network, so the
offline shadow of that demand is a real thing to want. The offline field clears the hard filters:

- **Filter 3 (ratings floor):** `Unsere Welt` 11,981; `geotrainer` 10,159; `Wo liegt das?` 7,045 —
  all German, all far above 2,000.
- **Filter 4 (clone flood):** passes. The field's IDs are from 2012, 2013, 2016, 2017, 2020. Only
  one recent entrant (`6758594564`, Geotrivia, 2026-02-20).
- **Filter 2 (findability):** `Geographie Quiz`, `juego de geografía` — real terms, five-figure
  rating counts on apps named after them.
- **The dataset is exactly what the 2026-09-15 decision allows:** borders, capitals, flags, rivers,
  mountains — published constants that do not go stale.
- **Filter 5 (paywall-change signal) fires, and inside the window.** Two of the three German leaders
  closed their free tier this summer, dated on their own listings:
  - `Wo liegt das?` — 2★ **2026-08-13** (Chris [Gigi]): *"The last update (10.08.2026) brings cool
    new features but also limits free version to only play once within 12 hours. Nothing of that
    mentioned in the update description, very disappointing! Transparency is key!!"*; 3★
    **2026-08-15** (BSTRKT): *"musste feststellen, dass für viele Funktionen nun ein Abo vonnöten"*;
    1★ **2026-08-31** (Susanesbienen): *"Seit dem es dieses mit KI generierte Update gibt, spiele
    ich es so gut wie garnicht mehr"*; 1★ **2026-09-08** (heinz222): *"Die App hat sich stark
    verschlechtert."*
  - `geotrainer` — 3★ **2026-09-03** (Jessi14328): *"leider kann man ohne zu bezahlen nur wenig
    spielen und müsste ansonsten 11,99€ pro Jahr für ein Abo bezahlen."*

  The paywall landed **2026-08-10, forty-three days ago**. Filter 5's window is sixty.

**And then it dies on the second half of filter 5, which is the half that matters: the free
replacement has already shipped.**

**Seterra Erdkunde (Vollversion)**, `1093460065`, published by **GeoGuessr AB** itself — 5,050
ratings, **4.78**, updated 2026-05-05, 200+ exercises. Its own description opens with:

> *"Es handelt sich hierbei um die Vollversion der Seterra-Spiele **ohne Werbung oder
> In-App-Käufe**."*
> (This is the full version of the Seterra games, **with no advertising and no in-app purchases**.)

Its reviews are people who noticed:

- 5★ **2026-08-22** (Pferde Liebe): *"Alles kostenlos und total hilfreich."*
- 5★ **2026-02-16** (ggg_12345_xD): *"Die App ist Super und alles ist kostenlos und ich lerne damit
  für Erdkunde alle Länder der Welt."*
- 5★ **2026-01-27** (MasterJam0): *"Keine Werbung. Kein verfluchtes Abo. Einfach mal freie Bildung.
  Vielen Dank!"* — No ads. No damned subscription. Free education for once. Thank you.

`Flaggen und Hauptstädte Quiz` (`1539501646`, 2,249 ratings) says the same thing in its listing:
*"Kostenlos herunterladen und spielen… Offline spielen."*

So the paywalled leaders are not being replaced by an opening — they are being replaced by an
ad-free, IAP-free app funded by the company that owns the top of the Trivia grossing chart, for whom
Seterra is a funnel rather than a business. We would enter with ads and a remove-ads purchase, which
is a **worse** offer than what is already sitting there at 4.78 stars. This is round 5's
free-forever precedent and round 6's filter 1b in one field, and it is the correct kill.

**Proposed clarification to filter 5, for the owner to accept or reject:**

> A paywall-change signal is not merely expired by time. Before treating one as an opening, read the
> *replacement*. If a credible free competitor has already absorbed the defectors — and especially
> if it is free with no ads and no IAP — the window is shut the day it ships, not sixty days later.

---

## Candidate 3 — National driving-theory exam prep (12)

**Demand scores 5 and it is not close.** Primary, today:

| Storefront | App | ID | Ratings | Last updated |
|---|---|---|---|---|
| IT | Quiz Patente Ufficiale 2026 (SoftBoom) | `635361447` | **126,625** | 2026-09-07 |
| IT | SIDA Quiz Patente | `784464887` | 27,744 | 2026-09-18 |
| IT | Quiz Patente Ministeriale 2026 (Net Service) | `472968213` | 30,538 | 2026-07-01 |
| FR | Code de la route 2026 (Appagon) | `1324795163` | **109,552** | 2026-09-19 |
| FR | Code et Conduite by Stych | `1556454758` | 86,047 | 2026-03-03 |
| FR | En Voiture Simone | `1448880045` | 46,931 | 2026-09-10 |
| FR | Code de la Route & Permis 2026 (MWM) | `716697016` | 39,191 | 2026-09-17 |
| FR | Code de la route 2026 Ornikar | `1612432450` | 38,715 | 2026-09-21 |

**Three independent kills.**

1. **The content is law, and the prompt forbids it.** Every single leader carries **2026** in its
   name because the question bank is reissued. A bundled offline highway code is exactly the
   "stale law is worse than no law" case the brief rules out.
2. **Filter 1 / leaders are strong.** Twelve apps in the French field, all free, the top five
   updated within the last fortnight, three of them backed by actual driving schools (Ornikar,
   En Voiture Simone, Auto-école.net) for whom the app is lead generation and therefore
   permanently free. We cannot undercut a customer-acquisition cost.
3. **Licensing.** The Italian ministerial question bank is state-published material; SIDA, Egaf and
   Net Service are the licensed publishers. Not something to bundle on a guess.

---

## Candidate 4 — Offline national card game, Scopa / Belote / Skat (12)

**The idea:** the national card games are top-10 grossing in Card in their home storefronts
(Belote.com FR, Scopa: la Sfida IT, Rommé Treff and Skat DE, Burraco IT), and the leaders are
online-multiplayer with accounts — so an offline, play-against-the-device version for a train
journey looked like the give-away.

**It is already shipped, several times over, and the numbers are brutal.** Primary, today:

- IT: `La Scopa - I Classici italiani` (OutOfTheBit, `376825329`) **33,224** ratings, updated
  2026-08-07, offline; `La Briscola` (same house, `395480192`) **35,990**; `Scopa Dal Negro`
  (`706034551`) 26,553, updated 2026-09-16.
- FR: `Belote` (Eryod Soft, `687944090`) 4,286 and `Coinche / Belote Contrée` (`739934239`) 2,678 —
  both offline-capable; against `Belote.com` (GameDuell) at **312,168**.
- DE: `Skat LITE` (Isar Interactive, `574907037`) **69,447**, updated 2026-09-20;
  `Doppelkopf LITE` 29,801; `Skat Onkel - Offline Skatspiel` (`1473142314`) 2,055.

Plus guideline 4.3 — these are named, rule-fixed traditional games where the only differentiator
possible is polish — and a card-playing AI for Belote or Skat that is good enough not to be
embarrassing is not a one-week build (effort scores 2). Each is also a single-locale product,
wasting eight of the nine listing languages (filter 7 in reverse).

---

## Candidate 5 — Text-deduction crime puzzles / Krimi-Rätsel (12)

The one field where the leaders genuinely *are* weak — and it fails the floor and the flood at the
same time, which is the combination rounds 1 and 5 already documented.

- **Filter 3, fails:** the whole text-deduction niche is under the floor. `Enigmic: Krimi-Rätsel`
  (INFINITY GAMES, `6763931528`) 702 ratings; `ColdTrace` (`6762513021`) 583 de / 713 es;
  `Cryptic` (`6480405773`) **0**; `Detektivspiele・Krimi Rätsel` (`6782498401`) 0 de / 2 es;
  `Last Seen` (`6790769959`) 6; `TeaSpy` (`6796079426`) 0; `Mission Go` (`6752356593`) 1.
  The apps with real ratings in this search — `Murder in Alps` (21,562), `Criminal Case` (2,684) —
  are hidden-object live-ops games, a different product entirely.
- **Filter 4, fails:** six of those IDs were issued in 2026. The flood is forming right now.

---

## Rejected below the fold — seven more fields, each on one hard filter

| Field | Terms searched | Killed by | The number |
|---|---|---|---|
| Mental arithmetic | `Kopfrechnen` (de) | leaders free + active | König der Mathematik 7,360 (upd 2026-09-08); Numbio 2,802 (upd 2026-09-06); plus two 2026 entrants |
| Sight-reading / solfeo | `Noten lernen Musik` (de), `solfeo` (es) | **ratings floor** | whole niche under 2,000: Notes Teacher 1,170, Solfa 686, LASIDO 237, EarMaster 96. Above it sits piano teaching (Simply Piano 83,419), a different product |
| Anatomy quiz | `Anatomie lernen` (de) | **ratings floor** | Kenhub 785, 3D-Anatomie 283, Anatomy Quiz 254, PROMETHEUS 24 |
| Sign-language dictionary | `lengua de signos` (es) | **ratings floor** | DILSE (CNSE) 886, Spread the Sign 46, Signary 28, Dactyls 10, LEYSIGN 0 |
| Stargazing | `Sternenhimmel Sternbilder` (de) | leaders strong + active | Sky Guide 38,542 (upd 2026-09-19), Star Walk 2+ 30,913, Night Sky 28,286, Stellarium 8,443 (upd 2026-09-20) |
| Knitting row counter | `Strickmuster Zähler` (de) | floor **and** flood | best in field 344 ratings; seven of ten results have 2025–26 IDs and 0–63 ratings |
| Rubik's-cube solver | `Zauberwürfel lösen` (de) | leaders strong | Cube Solver 3D 43,018 at 4.8 (upd 2026-09-15), ASolver 26,589, 21Moves 10,525 — all free |
| Italian crosswords | `cruciverba` (it) | leaders strong | CodyCross 80,428 (upd 2026-09-14), Words of Wonders: Search 15,475, Crossword Master 11,824 |

---

## The finding

Round 5 concluded that findability and give-away were near-disjoint. Round 6 corrected it for
professional tools: there *are* terms with traffic whose leader charges. This round settles the
question the owner actually asked — whether leaving utilities fixes the funnel — and the answer is
that it changes the failure mode rather than removing it.

**Inside utilities**, the factory's edge was that incumbents charge for what we would give away
(ShiftSlip) or that free had never been done properly (SiteCalc). The give-away was a real weapon.

**Outside utilities, the weapon does not exist, because everyone is already free.** Every field
swept this round — party games, geography, driving theory, card games, crosswords, mental
arithmetic, cube solvers, stargazing — is led by free apps. Ads are not an imposition there, as the
brief correctly says; but that cuts both ways, because it means ad-supported-and-free is the
*baseline*, not an offer. What is left to compete on is craft and content volume, and the brief's
own rule is explicit: *craft alone does not beat a good free incumbent, and the factory does not buy
installs.*

The measurable form of this, and the sentence I would put in the filter list:

> **Filter 1c — in games and content, "free with ads" is the incumbent's model, not ours.** Before
> proposing a game or content app, name what a user gets from us that they do not already get free
> from the leader. If the honest answer is "the same thing, made better", the field is closed to a
> studio without user acquisition, however large it is. The leaders' 1-star reviews complaining
> about ad load are evidence *against* entering, not for.

Two of the three fields with the largest volume this round (party games, geography) had leaders
whose worst reviews were complaints about advertising and subscriptions. We would have arrived
selling advertising and a purchase.

---

## What to hunt next week

1. **Do not re-sweep games.** The charts are now measured and recorded here. Puzzle, casual, board
   and card are one global live-ops chart with no seam; word and trivia are local but flooded. A
   later round should only revisit games if the owner decides to fund user acquisition, which
   changes the arithmetic completely.
2. **The one untested shape in this round's data:** party/word/trivia is local (61 and 60 distinct
   apps across six storefronts, only 5 and 10 shared). That locality is the asset, not the mechanic.
   The question worth one round is whether there is a **local-language content field with the same
   locality and without the flood** — the flood this round was concentrated in exactly three
   mechanics (impostor, charades, drinking games), and the search was not exhaustive beyond them.
3. **Go back to round 6's population 2** — terms with traffic whose leader charges *and* where free
   has traction. Round 6 found six instances and killed all six on other filters; it did not prove
   the population was empty, only that its aviation members were poisoned. Conduit bending
   (QuickBend `1010311475`, $6.99, 3,952 ratings, free best-in-field 608) passed every filter and
   was excluded only by the owner's utilities-fatigue, which the 2026-09-22 decision has now
   formally reversed in the other direction. It is worth re-reading with fresh eyes.
4. **Non-US statutory anchors remain the least-explored ground** and nothing this round touched
   them. Filter 7 still points there.

---

## Housekeeping — carried forward from round 6, still open

Both items are from `2026-09-22-no-candidate-ios-5.md` and neither is closed. They cost nothing and
they affect apps that already exist:

- **BuildTape / SiteCalc naming.** Round 6 measured three other apps called SiteCalc on the US
  store and ours not ranking for its own name. Commit `afa366d` renamed the store listing to
  BuildTape; confirm the rename is live on the listing and that the app now ranks for its own name.
- **ShiftSlip findability.** The memo `verify-our-apps-are-findable-first` records that ShiftSlip
  does not rank for `tip tracker` while zero-rating rivals do. That is a metadata fix on a shipped
  app and it is still the cheapest available move in the iOS lane — cheaper than any seventh-round
  candidate would have been.
