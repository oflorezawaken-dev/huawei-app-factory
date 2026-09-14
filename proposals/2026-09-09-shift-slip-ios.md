# Proposal (iOS): ShiftSlip — the daily tip record the IRS asks for, offline

**Date:** 2026-09-09 · **Slug:** `shift-slip` · **Bundle ID:** `com.proapps.shiftslip`
**Platform:** iOS 17+, iPhone only · **Category:** Finance (secondary: Productivity)
**Draft store name:** `ShiftSlip: Tip & Shift Log` (26/30) · **Draft subtitle:** `Tips, hours, tip-outs. Offline` (30/30)

> Not a port. Nothing in `factory/apps.json` covers this, the idea came out of App Store review
> patterns of App Store apps, and it is deliberately structurally different from PriceJar (the other
> app on this Apple account) — see guideline 4.3 below.

## Pitch

ShiftSlip is the end-of-shift notebook for people paid in tips. You finish a shift, open the app,
and in under fifteen seconds record the four things that actually matter — hours worked, cash tips,
charge tips, and what you tipped out to the bar and the bussers — and ShiftSlip tells you what that
shift really paid you per hour once the tip-out came off. Over a week it shows which shifts are
worth picking up and which are worth trading away; over a month it produces the *daily tip record*
that IRS Publication 531 already requires every tipped worker to keep, in the exact fields the
publication names, ready to export as CSV or PDF for your employer report or your tax preparer.
Everything lives on the iPhone in SwiftData: no account, no email signup, no cloud, works in the
back of house with no signal. Free, with an AdMob banner on the review-and-report screens and a
one-time purchase to remove it — and a hard rule that no ad ever appears while you are entering a
shift, because the category leader's worst reviews are exactly about that.

**Target user:** the tipped or commission worker with variable income and more than one income
source — servers, bartenders, baristas, delivery drivers, hairdressers and barbers, nail techs,
massage therapists, valets, caddies, hotel staff, tattoo artists. Skews toward people working
doubles or two jobs, who are currently tracking this in the Notes app, a paper notebook, or a
spreadsheet, and who need the numbers twice: weekly (is this schedule worth it?) and annually (tax
filing).

## Demand evidence (App Store first, dated)

- **The category is proven on iOS at real scale, not hypothetical.** ServerLife – Tip Tracker
  reports over 750,000 users and 65 million logged income entries, at 4.0★ across roughly 2,145
  reviews ([App Store](https://apps.apple.com/us/app/serverlife-tip-tracker/id1098987860);
  rating/review count via [AppFollow](https://appfollow.io/ios/serverlife-tip-tracker/1098987860),
  checked 2026-09-09). Just the Tips carries 4.5★ over 3,000+ ratings
  ([App Store](https://apps.apple.com/us/app/just-the-tips-tip-tracker/id937297529), checked
  2026-09-09). This is the difference between this candidate and PriceJar's category, where the
  whole field had 11–19 ratings: here the demand is already measured.
- **Every incumbent at scale rents out the arithmetic.** ServerLife's free tier logs tips but puts
  *hourly wage calculation, advanced graphs and data export* behind $4.99/month; TipKeepr's premium
  is $5.39/month or $53.90/year; TipSee sells "Remove Ads 1 Month" for **$0.99 a month** alongside
  $4.99/month and $24.99/year tiers
  ([tipkeepr.com comparison, 2026-08-22](https://tipkeepr.com/blog/best-tip-tracking-apps);
  [TipSee on the App Store](https://apps.apple.com/us/app/tipsee-tip-tracker-app/id664659826),
  checked 2026-09-09). Charging a server a monthly subscription to divide tips by hours, or monthly
  rent to hide a banner, is the opening.
- **A federal law change made the record legally salient, and it runs through 2028.** The OBBB tip
  deduction lets eligible workers deduct up to $25,000 of qualified tips, applies to tax years
  **2025 through 2028** retroactive to 2025-01-01, and the final regulations name **over 70
  qualifying occupations** — hairdressers, golf caddies, taxi drivers, massage therapists,
  concierges, HVAC installers, digital content creators
  ([RSM US, 2026-04-15](https://rsmus.com/insights/tax-alerts/2026/no-tax-tips-final-rules-confirm-qualifying-occupations-tip-definition.html);
  [IRS newsroom, 2026-01-26](https://www.irs.gov/newsroom/one-big-beautiful-bill-how-to-take-advantage-of-no-tax-on-tips-and-overtime)).
  Only *voluntary* cash and charged tips qualify — service charges and mandatory auto-gratuities do
  not — so for the first time the distinction between a tip and an auto-grat is worth money to the
  worker, and no shipped app tags it.
- **The IRS already specified the data model.** Publication 531 (rev. 12/2024) tells the employee to
  write down, each workday: *"Cash tips you get directly from customers or from other employees"*,
  *"Tips from credit and debit card charge customers that your employer pays you"*, *"The value of
  any noncash tips you get"*, and *"The amount of tips you paid out to other employees through tip
  pools or tip splitting"* — plus the date, your name, and the employer and business name — and to
  *"Give your report for each month to your employer by the 10th of the next month"*
  ([IRS Pub 531](https://www.irs.gov/publications/p531)). A statutory field list and a monthly
  deadline is the cheapest product spec a factory app will ever get, and it is a genuine 4.2 defence.
- **The underpayment problem gives the same numbers a second job.** A record 5.8 million workers were
  paid below minimum wage last year
  ([Forbes, 2026-08-24](https://www.forbes.com/sites/antoniopequenoiv/2026/08/24/58-million-workers-were-shortchanged-on-wages-last-year-as-minimum-wage-theft-hit-record-high/)),
  and tipped pay is where the arithmetic goes wrong: the federal cash wage is $2.13/hour against a
  $7.25 minimum with a maximum tip credit of $5.12, and *"when an employer takes a tip credit,
  overtime must be calculated based on the full minimum wage, which is currently $7.25 an hour, not
  the lower direct (or cash) wage payment"*
  ([DOL Fact Sheet #15](https://www.dol.gov/agencies/whd/fact-sheets/15-tipped-employees-flsa)).
  A worker who has logged their own hours and tips is the only person able to check that.
- Platform gap as a signal only: the workflow itself lives in spreadsheets and paper closeout slips,
  which is where the incumbents' own reviewers say they came from and, in several cases, went back to.

## The five candidates

Scored 1–5. Build effort and Apple review risk are inverted (5 = cheap / low risk).

| Candidate | Demand (App Store) | Competitor weakness | Build effort⁻¹ | Monetization fit | Review risk⁻¹ | Total |
|---|---|---|---|---|---|---|
| **Tip & shift earnings log (ShiftSlip)** | 5 | 4 | 5 | 5 | 4 | **23** |
| Offline flashcards / spaced repetition | 5 | 3 | 3 | 3 | 2 | 16 |
| Shift-rotation work calendar | 4 | 1 | 4 | 4 | 3 | 16 |
| Music practice journal | 3 | 3 | 3 | 2 | 4 | 15 |
| Espresso dial-in log | 2 | 2 | 4 | 2 | 3 | 13 |

Why the others lost:

- **Offline flashcards.** The demand signal is the loudest of anything I found — Quizlet has
  paywalled Learn mode, practice tests, offline access *and* flashcard export, and sits at 1.4/5
  across 600+ Trustpilot reviews, with students calling it *"predatory… preys on broke students"*
  ([MintDeck, 2026](https://www.mintdeck.app/blog/quizlet-paywall-free-alternative);
  [Studyboost, 2026](https://studyboost.org/blog/best-quizlet-alternatives-free/)), while AnkiMobile
  remains a $24.99 one-time purchase. Rejected on **review risk**, not demand: twelve credible free
  alternatives already launched into that hole in 2026 (Knowt, RemNote, Mochi, MintDeck, NoteHive),
  flashcard apps are the single most template-cloned genre on the store (4.3), and an ad-supported,
  ATT-prompting study app with obvious appeal to school-age users invites both Apple scrutiny and
  AdMob child-directed-treatment complications the factory has no process for. Also the real work is
  a correct FSRS scheduler plus deck import formats — not a one-week build.
- **Shift-rotation calendar.** Genuinely well served, which is the 4.3 trap: Supershift is 4.9★ over
  ~4.9K ratings and free to download, and My Shift Planner claims 400,000+ shift workers with
  built-in 4-on/4-off, DuPont and Continental 2-2-3 patterns
  ([appshunter, 2026](https://appshunter.io/ios/topics/shift-calendar-work);
  [Temporal, 2026](https://temporal.day/blog/best-calendar-app-shift-workers-2026)). Nothing left to
  be better at. Note that ShiftSlip deliberately does *not* become this app — see "not in V1".
- **Music practice journal.** Modacity charges $12.99/month or $129/year and caps its free tier at
  ten practice items ([App Store](https://apps.apple.com/us/app/modacity-pro-music-practice/id1351617981);
  [Practis, 2026](https://pract.is/blog/modacity-alternatives-practice-apps-for-serious-musicians)),
  which looked like an opening until the same comparison named **Andante**, which is free and already
  covers session logging, goals, streaks, charts and export. Beaten to it, by a free app, in a small
  paying market.
- **Espresso dial-in log.** Beanconqueror is comprehensive, free, and explicitly *no ads*, and 2026
  brought a wave of entrants (Dialed Shots, BeanBench, Coffeely, PUCK YEAH)
  ([Beans with Beanie, 2026](https://www.beanswithbeanie.com/guides/best-coffee-apps-2026);
  [Beanconqueror reviews](https://justuseapp.com/en/app/1445297158/beanconqueror/reviews)). An
  ad-supported app cannot win a category whose reference app is free and ad-free.

**Also looked at and dropped fast:** knitting/crochet row counters (Loopsy is 4.8★ over ~12K ratings
and free — [appshunter, 2026](https://appshunter.io/ios/topics/knitting-app)); paycheck-audit apps,
which are the adjacent idea to this one but were taken in 2026 by WageWatch and
[OverPay](https://apps.apple.com/us/app/overpay-overtime-pay-audit/id6763273391) (already
local-only, no account) and carry legal-claim framing the factory should not adopt; and the four
candidates already rejected in the PriceJar proposal (pantry/expiry, home inventory, chores, car
maintenance), which have not changed.

## Top App Store competitors and what their reviews say they do badly

All checked 2026-09-09.

| App | State | What users complain about |
|---|---|---|
| [ServerLife – Tip Tracker](https://apps.apple.com/us/app/serverlife-tip-tracker/id1098987860) (MZBApps) | **4.0★, ~2,145 reviews**, 750K+ users, 65M entries. Free basic; premium $4.99/mo | The paywall is on the maths: hourly wage calculation, advanced graphs and data export are premium. Recent updates forced cash and credit tips to be entered separately instead of a total, added ad pop-ups, and replaced a single weekly/monthly/yearly view with one metric at a time; reviewers who joined in 2017 say they are deleting it ([tipkeepr comparison, 2026-08-22](https://tipkeepr.com/blog/best-tip-tracking-apps), [justuseapp review digest](https://justuseapp.com/en/app/1098987860/serverlife-tip-tracker/reviews)) |
| [TipSee Tip Tracker](https://apps.apple.com/us/app/tipsee-tip-tracker-app/id664659826) (Webcoast Design) | **3.1★, 266 ratings**, v120.0.9 (Aug 10). IAPs: **Remove Ads 1 Month $0.99**, Monthly $4.99, Yearly $24.99, Pro 30 Days $1.99 | Ads inside the entry loop: *"Anytime I typed a letter or just touch the screen while using the app a new ad would pop up like literally every two seconds"* (Jun 2021). Core features removed: *"About 9 months ago the ability to track tip outs and hourly pay disappeared"*, with no replies to emails or reviews (Jun 2022). And an account wall dropped onto a local app locked a user out of a year of income data (Jul 2022) |
| [Just the Tips](https://apps.apple.com/us/app/just-the-tips-tip-tracker/id937297529) (Twin Oaks Technologies) | **4.5★, 3,000+ ratings**, v1.6.33 (2025-07-13). Free + premium $1.99 / $19.99 | **Requires email registration to use** a local notebook, and its privacy disclosure includes identifiers and device IDs used for third-party advertising. Reviewers call out stagnation — *"The #1 Tips App for Servers hasn't been updated in 6 years"* — with the developer promising updates in reply |
| [TipKeepr](https://apps.apple.com/us/app/tipkeepr-tip-tracker/id6745801270) | 2025 entrant. Free core; premium **$5.39/mo or $53.90/yr** | Its own comparison concedes the product is unfinished: *"does not advertise AI forecasting, and its business dashboard is still coming soon"* — a subscription price on a roadmap |
| The 2025–26 entrant flood — TipManager, [Tips45](https://apps.apple.com/us/app/tip-tracker-tips45/id6758269550), Tip Tally Tracker, [Waiter Pal](https://apps.apple.com/us/app/waiter-pal-tip-tracker/id1619187216), Waiter's Tip Tracker, Server44 | Many, small, mostly months old | Not a source of user complaints so much as the shape of the risk: this category is being carpet-bombed with small look-alikes right now. It is simultaneously the strongest demand evidence and the main reason to be careful about 4.3 |

**The gap:** every app at scale either paywalls the arithmetic (ServerLife, TipKeepr), rents out ad
removal by the month (TipSee), or demands an email account for a notebook that never leaves the phone
(Just the Tips). None of them is built around the record the IRS actually asks for — Pub 531's
tip-out field is the one TipSee's reviewers watched disappear — and none of them lets the user
separate a voluntary tip from an auto-gratuity, which as of the 2025 tax year is the distinction that
decides what qualifies for a $25,000 deduction. Free maths, free export, no account, no monthly rent,
and no ad between the user and the entry field: that is the whole positioning, and two of the three
loudest complaints in the category hand it to us.

## V1 (buildable in a week on the factory iOS stack)

1. **Jobs** — user-defined income sources with name, pay type (hourly, hourly + tips, commission,
   tips only), base rate, optional employer/business name (Pub 531 wants it), currency symbol,
   pay-period cycle (weekly / biweekly / semimonthly / monthly with a start date), and an optional
   default tip-out rule. Multiple jobs, because doubles and second jobs are the target user.
2. **Shift entry in ≤15 seconds** — date, job, start/end (or plain hours), cash tips, charge tips,
   noncash tip value, and tip-out. Last-used job and typical shift length pre-filled, decimal
   keypad, one screen, no modal chains. This screen is the product; it gets the tightest tap budget
   and an acceptance criterion in the spec.
3. **Tip-out rules engine** — per-job rules as a percentage of tips, a percentage of sales, a flat
   amount, or a manual figure, splittable across named recipients (bar, busser, host, food runner).
   Pure Swift, unit-tested. This is the feature TipSee lost and never restored.
4. **Qualified vs. non-qualified tagging** — each shift separates voluntary cash/charge tips from
   service charges and mandatory auto-gratuities, with an optional occupation label on the job (the
   W-2 Box 14b TTOC field employers must report from 2026). ShiftSlip totals both columns and says
   plainly that it is producing records, not tax advice, and not a deduction figure.
5. **What that shift really paid** — effective hourly rate after tip-out, tips-per-hour, and
   tip percentage where sales were entered, on the shift summary and rolled up by week, pay period
   and month.
6. **Daily tip record** — a chronological view in exactly Pub 531's fields, with the monthly total
   and a "due to your employer by the 10th" marker for the closing month. This is the screen no
   competitor has.
7. **Reports & charts** — Swift Charts of earnings by week, by day-of-week and by job; best and worst
   shifts; average hourly by day-of-week (the "is Tuesday lunch worth it" question); pay-period
   totals with a hours × rate expectation the user can compare to their actual paycheque, and an
   informational flag when a pay period's average falls below a minimum wage **the user enters
   themselves** in settings — framed as "worth asking about", explicitly not a legal determination,
   and with no bundled wage database (state minimums change; shipping a stale one offline would be
   worse than asking).
8. **Free export** — CSV and a printable PDF of the daily tip record for any date range, via the
   share sheet. Free forever, because it is the one thing a tax filer cannot be held hostage over.
9. **Optional closeout photo** — attach a photo of the paper closeout slip to a shift via
   PhotosPicker (no permission required).
10. **Sample data** — first run offers two example jobs and three weeks of shifts, clearly labelled
    and deletable in one tap. Also what an App Store reviewer sees instead of four empty tabs.
11. **Remove Ads** — StoreKit 2 non-consumable, restore purchase, target tier ~$3.99.
12. Light/dark, Dynamic Type, VoiceOver labels and accessibility identifiers on every control (the UI
    screenshot test depends on them), the nine factory languages, settings with privacy/ads/about.

**Not in V1:** notifications and reminders of any kind (deliberate — it keeps the app at zero
permissions), shift *scheduling* or rotation patterns (that is the Supershift category and we are not
entering it), iCloud/cross-device sync, sharing or teams, CSV import, receipt or paystub OCR, mileage
or expense tracking, location, live GPS or auto-clock-in, any bank/payroll/POS connection, computed
tax or deduction figures, filing help, multi-currency conversion, budgeting, iPad, widgets, Watch,
Live Activities, Siri/Shortcuts.

## Where the ads go

- **Banner (AdMob adaptive anchored):** bottom of the Dashboard, Shift History, Reports and Jobs
  screens only — inset above the tab bar with safe-area padding, so it can never cover navigation.
  Collapses to nothing once Remove Ads is active.
- **Interstitial:** exactly one placement — the shift summary shown *after* a shift has already been
  saved to disk, capped at one per session, never within 4 minutes of another ad, never on cold
  start, and never until the user has logged at least three shifts. The save completes first,
  always; an ad can never sit between the user and a recorded number.
- **Never, at any time:** the shift entry form, the tip-out split screen, the Daily Tip Record view,
  the export/share flow, the minimum-wage check, first run, onboarding, settings, and the purchase
  flow. TipSee's reviewers were driven off by an ad on every keystroke and ServerLife's by ad pop-ups
  arriving with a UI regression; an app that people open at 1am in a dark server station with sticky
  hands cannot make that mistake.
- **ATT** is requested after the first shift is saved — never at launch — so the prompt arrives from
  an app the user has already seen work.
- **Why someone pays:** this is a three-to-six-times-a-week app for its target user, opened at the
  end of a shift when patience is at its lowest, on screens where the number they came for sits right
  above the banner. A one-time ~$3.99 removes the banner forever, against TipSee's $0.99 **per month**
  for the same thing and ServerLife's $4.99/month for maths ShiftSlip gives away. Nothing else is
  behind the purchase — no feature, no export, no report — which is both the honest pitch and the
  reason a reviewer has nothing to object to.

## Permissions and privacy

| Permission | Purpose string (draft) a reviewer would accept |
|---|---|
| Tracking (`NSUserTrackingUsageDescription`) | "Allow tracking so the ads that keep ShiftSlip free can be more relevant. Your shifts, tips and earnings never leave your iPhone." |

That is the entire list. No camera (PhotosPicker needs no permission), no location, no notifications,
no contacts, no calendar, no HealthKit, no Sign in with Apple, no account, no backend. A
zero-permission app is the lowest-friction submission the factory can make, and it is also the
marketing: the closest competitor by rating makes you register an email address to use a notebook.

**Privacy story, two sentences:** Your jobs, shifts, tips, tip-outs and reports are stored only on
your iPhone in the app's own SwiftData store, and ShiftSlip has no server and no account, so there is
nothing to sync, sell or breach — income data in particular never goes anywhere. The single component
that touches the network is the Google AdMob SDK, which receives device and advertising identifiers to
serve ads and never receives any earnings data, declared in `PrivacyInfo.xcprivacy`, in the App Store
privacy labels and in the privacy policy page, and switched off entirely once Remove Ads is purchased.

## Guideline risks considered

- **4.2 minimum functionality.** The rejection pattern here would be "a tip calculator". ShiftSlip is
  not one: it is a multi-entity persistent database (jobs, pay periods, shifts, tip-out rules,
  tip-out recipients, tags) with a rules engine that resolves tip-outs four different ways, pay-period
  arithmetic across four cycle types, per-day-of-week analytics, charts, a statutory record view, and
  CSV/PDF export, across five screens. The Pub 531 field list is a useful thing to be able to point at
  in a review note: the app implements a record the federal government requires. Sample data on first
  run means the reviewer sees a populated tool in ten seconds.
- **4.3 spam / duplication.** This is the real risk and it has two halves. *Against other apps:* the
  category is being flooded with small tip trackers right now, so ShiftSlip has to not look like one —
  its own name (no "Tip…" prefix, checked 2026-09-09 with no App Store match for "ShiftSlip"), its own
  icon and palette, its own screens (the Daily Tip Record view, the tip-out splitter, the
  qualified/non-qualified split, the day-of-week hourly report) that none of the incumbents ship, and
  store copy written from the Pub 531 angle rather than from the "track your tips!" template.
  *Against our own account:* PriceJar is the only other app on this account, and a reviewer comparing
  them must not see a reskin. They share no entities, no screens, no palette and no icon language:
  PriceJar is a shopping app about outgoing money and unit prices with a barcode scanner; ShiftSlip is
  a work app about incoming money and hours with no camera at all. ShiftSlip gets its own visual
  identity (deep navy / brass, distinct from PriceJar's green/amber) and its own copy. The shared
  factory skeleton stays internal.
- **5.1.1 data collection and storage.** One permission, requested after the user has already saved a
  shift, with a purpose string that is true; nothing is gated on consenting to tracking; no data
  collected beyond what AdMob requires; no account and no personal data requested at all — no name,
  no email, no employer identity unless the user chooses to type one for their own record.
- **Also considered:** this is *not* real-money finance — no bank, payroll or POS connection, no
  payments, no money movement, no lending, no investment or credit copy. It is not health and does not
  touch HealthKit. Not kids-category, no user-generated content anyone else can see, nothing to
  moderate, no web view, no system-level claims. The one place to stay disciplined is **tax framing**:
  ShiftSlip produces records and totals and says so; it must never compute a deduction, estimate a
  refund, give filing advice, or imply IRS endorsement, and the copy needs a plain "not tax advice"
  line on the report and export screens.

## Open risks

1. **The category is crowded and getting more so.** Six or more entrants appeared in 2025–26. Demand
   is proven, but so is the supply of look-alikes, and ASO will be a fight against apps whose names
   *are* the keywords. Mitigation is the Pub 531 positioning, free export and the one-time purchase —
   all three are things the incumbents cannot copy without giving up revenue — plus a keyword field
   working "tip out", "daily tip record", "server income", "hourly", "tip tracker", "shift log".
   Honest downside: low downloads rather than a rejection.
2. **The market is essentially US (plus Canada).** Tipping at this intensity does not exist in most of
   the nine factory locales, so es-ES, de-DE, it, tr and zh-Hans listings will carry almost no
   traffic; the app is en-US-first with the others shipped because the factory ships them. Commission
   and hairdresser/barber use cases are the partial hedge in tip-light markets.
3. **Tax adjacency is a copy discipline problem, not an engineering one.** Everything here is
   record-keeping, but a single sentence promising a deduction, a refund estimate, or "IRS-approved"
   status turns a Finance-category app into a compliance argument. The spec should state the banned
   phrasings explicitly and the listing must be reviewed against them before submission.
4. **The minimum-wage check must stay informational.** It compares the user's own logged hours and
   tips against a minimum wage the user typed in. It must not name states, cite law, allege anything,
   or suggest action, and if it feels at all like a legal claim during review prep, cut it — the
   effective-hourly number carries most of the value on its own.
5. **Arithmetic must be exact** across pay-period boundaries, four tip-out rule types, split shifts,
   overnight shifts crossing midnight, and locale decimal separators. A wrong hourly figure destroys
   the premise, and this is an app about people's income. Unit tests on the rules engine and the
   period roll-ups are non-negotiable, and the spec should carry the worked examples.
6. **Data loss would be unforgivable and there is no cloud backup in V1.** A tipped worker's whole
   year of income records living in one app's local store, with iCloud sync explicitly out of scope,
   means the CSV/PDF export is not a nicety — it is the backup story, and the app should nudge an
   export at the end of each month. Note that Just the Tips' reviewers already lost data to an
   account wall; ours would be a device loss.
7. **Zero permissions means zero re-engagement hooks.** No notifications in V1 is the right call for
   review friction, but nothing reminds a user to log Friday's shift. The habit has to come from the
   shift itself. If retention is weak, an opt-in local reminder is the first V1.1 candidate.
8. **Name.** "ShiftSlip" returned no App Store match on 2026-09-09, but only App Store Connect is
   authoritative and the human must confirm at app-creation time. Fallbacks in order: ShiftTake,
   Doubles, ShiftCount, EarnLog. Avoid anything ending in "Jar" — the point is not to look like a
   sibling of PriceJar.
9. **Nine-language listing** will be machine-drafted and needs native review before a serious launch,
   same caveat as every other factory app.
10. **AdMob and IAP prerequisites are human gates:** an AdMob app plus banner and interstitial units,
    and the non-consumable Remove Ads product created in App Store Connect. Until the real IDs land in
    the registry the build uses test IDs, and `factory-ios-publish.yml` must keep refusing to submit
    while `ca-app-pub-3940256099942544` is in the build.

---

*Next step: a human adds the `approved` label to the issue. No spec, code or registry entry has been
created.*
