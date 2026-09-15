# iOS opportunity research, 2026-09-15 — **no strong candidate this week**

**Verdict:** I am not proposing an app. Nothing I found scores well enough to spend a build week on.
The best two candidates tie at **17/25**, each with a fatal single-axis failure, against the 23/25
that ShiftSlip scored on 2026-09-09. Per the step's own instruction ("Be honest if none scores well;
say 'no strong candidate this week' and stop"), this file is the deliverable and no spec, code or
registry entry has been created.

This is not a "nothing exists" report. It is a specific finding about the September 2026 App Store,
written up below so next week's research does not repeat it.

---

## The finding

Every offline-first personal-record-keeping niche I probed had already been closed, and closed in one
of only three ways:

1. **A free, offline, one-time-purchase incumbent already owns it.** Stylebook ($4.99, works entirely
   offline) in wardrobe; BG Stats ($5.99, works offline) in board games; TrayMinder (free, built by an
   orthodontist, 13k+ reviews since 2017) in aligner tracking; Paprika ($4.99) in recipes. An
   ad-supported entrant is strictly worse than what is already there.
2. **A 2025–26 clone flood got there first.** Document/expiry reminders, home maintenance, and 3D
   printing filament inventory each had five to eight apps with 2025-or-later App Store IDs when I
   looked. That is guideline 4.3 surface area with none of the demand proof.
3. **The obvious paywall opening was filled within months of opening.** This is the important one —
   see medication below.

The pattern behind all three: the *generic* utilities have been absorbed by Apple (Journal, Health →
Medications, Notes → Math Notes and scanning, Measure, Wallet), and the *niche* record-keepers are
being carpet-bombed by indie devs faster than a demand signal can survive contact with the store. The
window between "a hated paywall appears" and "four free local-first replacements ship" was about
**eight months** in the one case I could date precisely.

---

## The five candidates

Scored 1–5. Build effort and Apple review risk are inverted (5 = cheap / low risk).

| Candidate | Demand (App Store) | Competitor weakness | Build effort⁻¹ | Monetization fit | Review risk⁻¹ | Total |
|---|---|---|---|---|---|---|
| Medication adherence + refill inventory | 5 | 2 | 4 | 4 | 2 | **17** |
| Homeschool attendance & portfolio record | 2 | 5 | 4 | 3 | 3 | **17** |
| Home maintenance & appliance log | 3 | 4 | 4 | 2 | 2 | 15 |
| Personal CRM / keep-in-touch | 3 | 2 | 4 | 3 | 3 | 15 |
| Document & renewal expiry tracker | 3 | 2 | 5 | 2 | 1 | 13 |

For calibration: ShiftSlip scored 23, and its own proposal named PriceJar's mistake as entering a
category whose entire App Store field had 11–19 ratings. Two of the five below repeat exactly that
mistake, and the other three fail on competitor weakness or review risk.

---

## Candidate 1 — Medication adherence + refill inventory (17)

**Why it looked good.** The single loudest dated demand signal I found all week. Medisafe carries
**101,000+ ratings at 4.7★** on the App Store and, **as of 2026-01-01**, capped its free tier at
**two medications**, moving additional meds, reports and family sharing behind $4.99/month or
$39.99/year. The backlash is measurable: Trustpilot shows **69% 1-star and 23% 2-star**, with
reviewers writing *"your choice to start charging incredibly vulnerable users an annual fee has led
me to move my medication reminders to another app that is ZERO fees… super basic functionality that
costs them nothing has suddenly been completely paywalled."* Apple's own Health → Medications is free
and unlimited but, as of iOS 26, **has no supply or refill tracking** — it will not count down pills
or warn you before you run out — and no grace period for a slightly-late dose. That gap is real.

**Why it fails.** The hole is already filled. By September 2026 there are at least four apps offering
**free unlimited medications** — Pillo, MyTherapy, MedTimer and TakeYourPills — and DoseMed is
explicitly **local-first with no cloud sync required**, which is the exact pitch the factory would
have made. Arriving ninth with ads is arriving late and worse.

Second, independent blocker: **review and ethics risk.** This would put an AdMob banner and an ATT
prompt into an app whose data is health data. We would not touch HealthKit, so guideline 5.1.3 does
not bind literally — but the factory has no process for health-data ad disclosure, and the failure
mode of an interstitial standing between a user and logging a dose is not a bad review, it is a
missed dose. I scored review risk 2 and I would argue for 1.

Sources (checked 2026-09-15): [Medisafe App Store listing](https://apps.apple.com/us/app/medisafe-medication-management/id573916946) ·
[Trustpilot](https://www.trustpilot.com/review/medisafe.com) ·
[Apple Support — Track your medications in Health](https://support.apple.com/guide/iphone/track-your-medications-iph811670c81/ios) ·
[Caring Village, 13 Best Medication Reminder Apps (2026)](https://caringvillage.com/blog/caregiver-tech/medication-reminder-apps/) ·
[Bearable, Best Medication Tracker Apps of 2026](https://bearable.app/the-best-medication-tracker-apps-of-2026/)

---

## Candidate 2 — Homeschool attendance & portfolio record (17) — the near-miss

**This is the one a human could reasonably overrule me on.** It is the only candidate where the
incumbents are genuinely weak and genuinely expensive, and it has the ShiftSlip-shaped anchor: a
legal record-keeping obligation that specifies the data model for you.

**The anchor.** About half of US states require a minimum number of instructional days (commonly
**180**) or hours (typically **900–1,000/year**); Indiana requires no notice at all but does require
you to keep an attendance record. Pennsylvania-style states require a **portfolio** of work samples
plus an annual evaluation. The population is large and growing: **~3.4 million K-12 homeschool
students in 2024-25 (≈6% of school-age children)**, with enrollment in 18 comparable-record states up
**51% over six school years**.

**The incumbents, all checked directly on the App Store 2026-09-15:**

| App | State | Price |
|---|---|---|
| [Homeschool Panda](https://apps.apple.com/us/app/homeschool-panda/id1470263093) | **3.2★, 32 ratings.** Last updated **v2.14, 2024-06-12** — over two years stale | Free + $4.99/mo, $49.99/yr, $7.99/mo, $79.99/yr |
| [Homeschool Planner AI: Uschool](https://apps.apple.com/us/app/homeschool-planner-ai-uschool/id6469048740) | 4.7★, **84 ratings**. Updated 2025-08-19 | Free + $4.99–12.99/mo, $47.90–124.99/yr |
| [Homeschool Planner](https://apps.apple.com/us/app/homeschool-planner/id6745445641) | 4.3★, **22 ratings**. Updated 2025-08-26 | Free tier = **1 student, 1 lesson plan**; $59.99/yr (1 student), $119.99/yr (5), $199.99/yr (10) |

Charging **$119.99/year to track a second and third child** is the opening. Unlimited students free,
free PDF/CSV year-end reports and transcripts, no account, no subscription, one-time ad removal —
that is a sharp, honest wedge, and daily attendance logging over 180 school days is genuine daily use.

**Why I still did not pick it.**

1. **Demand scores 2, and that is the exact mistake the factory already paid for.** The entire iOS
   field totals **138 ratings** (32 + 84 + 22). The ShiftSlip proposal named PriceJar's failure as
   entering a category whose whole field had 11–19 ratings. 138 is the same shape of number. The
   3.4M-student figure measures the *activity*, not App Store demand for an app about it — those
   families are on web tools (Homeschool Planet and similar), spreadsheets and paper planners.
2. **The differentiator cannot legally ship.** The idea only sings as "tell me what *my state*
   requires and show me whether I am on track." Bundling 50 states' homeschool law offline is exactly
   the trap ShiftSlip already flagged for state minimum wages: shipping stale law offline is worse
   than not shipping it. Strip it out and the product degrades to "a good offline attendance and
   portfolio log" — still decent, no longer a knockout.
3. **Seasonal and US-only.** Nine-language listings would carry almost no traffic, and the school year
   has already started, so we would launch into the tail of setup season.

**If a human overrules me, here is the scaffolding so the week is not lost:**

- **V1:** students; subjects/courses; a ≤5-second daily log (date, student, subject, hours, note);
  attendance calendar with a days/hours counter against a target the *user* enters; portfolio items
  (PhotosPicker, no camera permission); reading log; simple gradebook; year-end PDF + CSV report and
  transcript, free forever; sample data on first run; Remove Ads non-consumable.
- **Not in V1:** any bundled state-law database, lesson planning or curriculum content, AI anything,
  a student-facing portal (keeps children out of an ad-supported surface), sync, sharing, iPad.
- **Ads:** banner on dashboard, library and reports only; one interstitial after a report has already
  been written to disk; never on the daily log screen, never in the portfolio capture flow, never on
  the export. AdMob **max ad content rating G**, because this is a 4+ Education listing.
- **Permissions:** local notifications (optional daily log reminder) and ATT. Nothing else —
  PhotosPicker needs no permission.
- **Guidelines:** 4.2 is fine (multi-entity database, calendar arithmetic, report generation, export).
  4.3 is fine both ways — the field is three apps, and it shares nothing with PriceJar or ShiftSlip.
  5.1.1 is one ATT prompt after first use, nothing gated on consent, no account. The discipline
  problem is **compliance framing**: the app produces records and says so; it must never state or
  imply that a user meets their state's legal requirements.

Sources: the three App Store listings above (fetched 2026-09-15) ·
[NHERI, homeschool student counts](https://nheri.org/how-many-homeschool-students-are-there-in-the-united-states/) ·
[Homeschool laws by state, 2026 guide](https://www.homeschoolingexperts.org/homeschool-laws-by-state-2026/) ·
[statehomeschoollaws.com](https://statehomeschoollaws.com/states)

---

## Candidate 3 — Home maintenance & appliance log (15)

**Why it looked good.** A paying market was literally vacated: **Centriq shut down on 2025-01-31 and
wiped customer data**, after charging roughly $49/year for manuals, warranties, barcode scanning and
maintenance reminders. HomeZada, the survivor, charges **$99/yr (Premium) and $189/yr (Deluxe)** and
its mobile app has historically sat around **2.9★**.

**Why it fails.** The clone flood. In one search I surfaced Upkeepy (`id6760043465`), HomeKeep
(`id6759167634`), HomeTaskPro (`id6755658243`), Filterness (`id6760980128`), FilterFixBaan
(`id6757287013`), UpKeep Pro (`id6758960165`) and HomeBeacon — every one of them a 2025–26 App Store
ID, several explicitly advertising "100% offline, no subscriptions." That is our pitch, shipped six
times, before we started.

Independently, monetization fit is weak (2): this is a once-or-twice-a-month app whose core job —
recurring reminders — iOS Reminders already does free, so "remove ads" has little to bite on.

Sources (checked 2026-09-15): [homebeacon.app on Centriq's shutdown](https://homebeacon.app/alternatives/centriq-alternative) ·
[realestateledger.io, best home maintenance app 2026](https://realestateledger.io/comparisons/best-home-maintenance-tracking-app) ·
[Upkeepy](https://apps.apple.com/app/id6760043465) · [Filterness](https://apps.apple.com/us/app/filterness/id6760980128)

---

## Candidate 4 — Personal CRM / keep-in-touch (15)

**Why it looked good.** The prices are absurd for what the software does: **Dex $15–20/month, Clay
$30+/month**, and UpHabit's free tier is **capped at 10 relationships**, which is a demo rather than a
product. The privacy pitch writes itself — notes about your friends should never leave your phone.

**Why it fails.** Competitor weakness scores 2, not because the leaders are good but because the
category is already answered at the cheap end: Dex's own 2026 roundup compares **60+ personal CRMs**,
and Dextr ships a **free-forever plan** with paid tiers at **$1.99–14.99 per year**. There is no
oxygen between "free forever" and "one-time $3.99 to remove a banner." Retention in this category is
also notoriously poor — people stop maintaining the graph — which undercuts the remove-ads case.

Sources (checked 2026-09-15): [Dex, Personal CRMs in 2026: The Complete List](https://getdex.com/blog/personal-crm-list/) ·
[Dextr, Best Personal CRM Apps in 2026](https://dextr.app/articles/best-personal-crm-apps-in-2026/)

---

## Candidate 5 — Document & renewal expiry tracker (13)

**Why it looked good.** Universal problem (passports, visas, residence permits, insurance, licences,
warranties), trivially offline, zero permissions, and genuinely international — one of the few ideas
where the nine factory locales would all carry traffic.

**Why it fails.** This is the most crowded new-app niche I saw, and the entrants are *already doing
our differentiators*. Document Expiry Reminder (`id6756968613`) advertises AES-256 on-device and
"works entirely offline"; Deadlinr (`id6757941172`) sells a **lifetime purchase for up to 6 family
members**; EverPass (`id6759546153`) ships passport **MRZ OCR**; RenewalKit (`id6758590671`) does
on-device Vision OCR with nothing retained; Expiry Tracker (`id6746894673`) is a sixth. Five or six
apps, all with 2025–26 IDs, all privacy-first and offline. Review risk scores 1: submitting a seventh
is asking a reviewer to apply guideline 4.3. Monetization is weak anyway — people open this app twice
a year.

Sources (checked 2026-09-15): the App Store listings linked by ID above.

---

## Also looked at and dropped fast

All checked 2026-09-15.

| Idea | Killed by |
|---|---|
| Wardrobe / cost-per-wear | [Stylebook](https://fitwardrobe.me/blog/best-outfit-planning-apps-compared/) is a **$4.99 one-time purchase that works entirely offline**; Whering and Indyx are free with generous tiers and better tagging than we could build |
| Pet health & vaccine log | Crowded with 2024–26 entrants, and **Healthy Pet Tracker** already ships "no account, data stays on your device, Pro is a one-time purchase, no third-party SDKs" |
| Baby / newborn tracker | **Nara Baby** is free with no premium tiers and no ads; **Pebbi**'s free tier includes full offline mode, CSV export and two carers. Our only possible edge (caregiver sync) is the one thing an offline app cannot do |
| 3D printing filament inventory | The worst flood of all: SpoolLab, Spool, Spool Buddy, Spool Master, Spoolstock, 3D Print Filament Tracker — Spool Buddy's pitch is verbatim "no accounts, subscriptions, tracking" |
| Clear-aligner wear tracker | [TrayMinder](https://apps.apple.com/us/app/trayminder-aligner-timer/id1320684802): free, built by an orthodontist, on the store since 2017, **13k+ reviews**, $2 IAP for Watch sync |
| Youth sports substitution / equal playing time | Pitch Planner, FairSub and SubNow are free; SubTime claims 50,000+ coaches; FairPlayTime and SubHero are 2025 entrants |
| Board game play & score log | BG Stats ($5.99) already works offline with BGG sync; free alternatives exist |
| Pickleball round-robin organiser | Pickleheads, Main Court and several free round-robin generators |
| Caregiver / elderly care coordination | The job is coordination between people; offline-only cripples it. CareZone is dead, and Medisafe/TendTo own what remains |
| Restaurant HACCP temperature log | Real pain and a genuine statutory anchor, but it is B2B (RiskLimiter starts at **$59.99/location/month**), so App Store demand evidence is absent and AdMob is the wrong instrument |
| ADHD routine / executive function | Apple named **Tiimo** its 2025 iPhone App of the Year. Do not enter a category Apple just crowned |
| Diet / calorie tracking | Highest negative-review rate of any category, but a real food diary needs a food database, i.e. network — it cannot be offline-first |
| Period / cycle tracking | Proven demand and a real privacy opening, but I will not put ATT and ad SDKs next to reproductive-health data, and Apple ships Cycle Tracking free |
| Gift / holiday shopping planner | Perfect seasonal timing and the definition of the occasional-use app the brief warns against: six weeks of use, no remove-ads case |
| Budget / spending tracker | Would be the **third** money app on this account after PriceJar and ShiftSlip — the 4.3 argument against us writes itself — and the post-Mint free field is saturated |
| Flashcards, shift-rotation calendar, music practice, espresso log, knitting counters, paycheck audit | Already rejected in the ShiftSlip proposal (2026-09-09); nothing has changed |
| Pantry/expiry, home inventory, chores, car maintenance | Already rejected in the PriceJar proposal (2026-09-08); nothing has changed |

---

## What to hunt next week

The three ways a niche got closed all share one property: **the competitor could copy our pitch.**
"Offline, no account, one-time purchase" is now the default indie positioning, not a differentiator.
So the filter for next week is not "find an unserved niche" — it is **find a niche where the thing we
give away is expensive for the incumbent to give away.**

ShiftSlip passes that test: the incumbents' revenue *is* the arithmetic and the export, so they cannot
match us without cutting their own subscription. Concretely, next week I would look for:

1. **Categories where the leader has >2,000 ratings** (proven App Store demand, not proven activity
   demand) — a field totalling under ~500 ratings is a disqualifier, not a gap.
2. **A paywall change dated in the last 60 days**, checked against whether free replacements have
   *already* shipped. The medication case says that window closes in well under a year, so the signal
   is only useful while it is fresh.
3. **A statutory or institutional data model** we can implement exactly — the Pub 531 shape — but
   where the rules are *national and stable*, not 50 divergent state rules we cannot ship offline.
4. **Non-US anchors.** Four of this week's five candidates were US-only, which wastes eight of the
   nine factory locales. EU/LatAm-anchored obligations (utility meter readings and bill checks,
   vehicle inspection cycles, tenancy documentation) are unexplored.

---

## Caveats on this research

- **Source quality is uneven and I want that on the record.** The three homeschool listings, and the
  App Store IDs cited throughout, were fetched directly from apps.apple.com on 2026-09-15 and are
  primary. Much of the rest — the Medisafe free-tier change, Centriq's shutdown, the "four free
  unlimited medication apps", competitor pricing — comes from comparison articles published by
  competing apps, which have an obvious interest in making incumbents look bad. I believe the
  direction of every one of those claims; I would verify exact prices and dates before building.
- **I did not get useful primary Reddit or Apple Support Communities material.** The searches
  returned SEO content rather than threads. The unmet-need evidence here is therefore thinner than the
  competitor-weakness evidence, and a week that found a good candidate would want both.
- **Rating counts are a proxy, not a census.** A low count can mean a bad category or an unserved one.
  I treated it as disqualifying because that is the lesson the factory already paid for with PriceJar,
  but it is a judgement call and the homeschool entry is where it bites.

---

*No issue was opened, no spec written, no registry entry created. If the owner wants the homeschool
candidate built anyway, the V1 scaffolding above is ready to become a proposal.*
