# Step: write the APP_SPEC for an approved iOS proposal

Read `factory/prompts/00-factory-rules.md` first. Input: the approved proposal file
(`proposals/<file>-ios.md`) and `specifications/APP_SPEC_TEMPLATE_IOS.json`.

Do not use `APP_SPEC_TEMPLATE.json` or the Android specs as a model: they carry
package names, Petal Ads, AppGallery privacy tags and Huawei locale codes, none
of which apply here.

## Produce

1. **`specifications/<slug>.json`** following `APP_SPEC_TEMPLATE_IOS.json` exactly.
   Fill every section; delete the `_note` keys as you go (they are instructions to
   you, not spec content).
   - `app.bundle_id` = `<defaults.ios.bundle_id_prefix>.<slugwithoutdashes>`, read
     from `factory/apps.json`. Never invent a prefix.
   - `app.sku` = the slug.
   - `monetization`: AdMob banner + interstitial and `remove_ads_iap: true`, with
     `iap_product_id` = `<bundle_id>.removeads`. Fill `banner_screens`,
     `interstitial_moments` and — most important — `ads_never_on`, taking the rules
     straight from the proposal. If the proposal identified ad placement as a
     competitor's failure, that constraint is part of the product, not a nicety.
   - `permissions`: one entry per `NS*UsageDescription` the app actually needs, each
     with a usage string that names the feature and is true. The quality gate fails
     strings under 25 characters and generic phrasings; Apple rejects vague ones
     under guideline 5.1.1. State what still works when the user denies it.
   - `privacy.privacy_manifest`: the data types and required-reason APIs that go
     into `PrivacyInfo.xcprivacy`, using Apple's exact labels. With AdMob this
     always includes device/advertising identifiers.
   - `privacy.app_privacy_answers`: what the human will tick in App Store Connect's
     App Privacy questionnaire. This is a manual console step, so write it as a
     checklist someone can follow without re-deriving it.
   - `localization.supported_languages` = `defaults.ios.languages` from the registry
     (Apple's codes). Never reuse `defaults.languages`, which is Huawei's list.
   - `qa.acceptance_criteria`: testable statements with numbers. If the proposal
     named a friction risk, turn it into a measurable criterion.

2. **A new entry in `factory/apps.json` → `apps[]`** with:
   ```
   "platform": "ios", "path": "apps-ios/<slug>", "store_dir": "apps-ios/<slug>/store",
   "privacy_path": "docs/<slug>/privacy", "support_path": "docs/<slug>/support",
   "status": "planned", "asc_app_id": "",
   "admob": { "app_id": "", "banner_unit_id": "", "interstitial_unit_id": "" },
   "iap": { "remove_ads_product_id": "<bundle_id>.removeads" },
   "known_gaps": {}
   ```
   Omit `team_id`: it is inherited from `defaults.ios`. Leave `asc_app_id` and the
   AdMob IDs empty — they only exist after the human creates the app in the
   consoles, and the publish workflow refuses to submit while they are empty or
   still Google's test IDs.

3. **`apps-ios/<slug>/store/listing.json`** with every language in
   `defaults.ios.languages` present. Write the English entry properly, respecting
   Apple's limits (name ≤30, subtitle ≤30, promotional_text ≤170, description
   ≤4000, keywords ≤100 total, release_notes ≤4000); mark the rest `"_todo": true`
   for the listing step. The quality gate enforces those limits, so a name of 31
   characters fails the build rather than the review.

## Check your own work

Before committing, run:

```bash
python factory/tools/check_ios_app.py <slug>
```

It will report failures for things that legitimately do not exist yet (the app
code, icon, screenshots, the AdMob IDs). What matters is that `identity`,
`listing` and `spec` are not among them — those depend only on what this step
wrote. Fix anything it flags in that set before you commit.

Do NOT write app code, create the Xcode project, or invent App Store Connect IDs
in this step. Commit as `spec: add <slug> (iOS)` and stop.


## Where the tracking prompt goes — not negotiable

`monetization.att_requested_when` must place Apple's tracking prompt **on the first launch
after First Run completes, before the ad SDK starts**.

Do not specify it after a first saved entry, a first completed action, or anywhere else
that takes the user several steps to reach, however good that reads as UX. App Review
rejected PriceJar 1.0.0 under guideline 2.1 — *"unable to locate the App Tracking
Transparency permission request"* — for exactly that: the prompt fired only after the user
saved their first price, and a reviewer who opened Settings and never saved one never saw
it. Apple also asks for the prompt **before** any data that could track the user is
collected, and starting the ad SDK at launch is collection.

Onboarding is where the user is told what the app is, so asking immediately after it keeps
the intent of "never before the user knows what this is" and stays somewhere a review pass
reaches in its first thirty seconds.
