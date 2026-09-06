# Step: write the APP_SPEC for an approved proposal

Read `factory/prompts/00-factory-rules.md` first. Input: the approved proposal file
(`proposals/<file>.md`) and `specifications/APP_SPEC_TEMPLATE.json`. Use
`specifications/receipt-lens.json` as a worked example of the level of detail expected.

## Produce

1. `specifications/<slug>.json` following the template exactly. Fill every section.
   - `app.package_name` = `com.huaweiappfactory.<slugwithoutdashes>`
   - `monetization.provider` = "Huawei Petal Ads", `enabled: true`, with the exact
     screens for banners and the exact moments for interstitials, and the rule that ads
     never interrupt the core task.
   - `privacy` must state what is stored, that nothing is sent to our servers, that ads
     use network and the ad SDK collects data, and the backup decision
     (`allowBackup=false` is the default for new apps).
   - `localization.supported_languages` = the registry default languages.
   - `qa.acceptance_criteria` must be testable statements, not adjectives.
2. A new entry in `factory/apps.json` → `apps[]` with `status: "planned"`,
   `agc_app_id: ""`, and empty `known_gaps: {}`.
3. `apps/<slug>/store/listing.json` skeleton with all registry languages present
   (English written properly, others marked `"_todo": true` for the listing step).

Do NOT write app code in this step. Commit as `spec: add <slug>` and stop.
