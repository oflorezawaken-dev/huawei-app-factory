# Step: research an app opportunity

Read `factory/prompts/00-factory-rules.md` first.

## Goal

Propose ONE new Android utility app for Huawei AppGallery that the factory can build
in a week, that people actually need, and that is monetizable with Petal Ads without
being annoying. Output a proposal file and open a GitHub issue for a human to approve.

## Constraints

- Offline-first utility (tools, productivity, finance, health tracking, home, study).
  No social, no chat, no content that needs a backend or moderation.
- Must not duplicate an app already in `factory/apps.json`, and must be clearly
  differentiated from the top competitors you find.
- Avoid categories that need special licenses or sensitive-data declarations
  (medical diagnosis, kids, gambling, finance with real money movement).
- Must be doable with the factory stack (Compose, Room, camera/sensors, on-device only).

## Method

1. Use web search. Look at AppGallery and Google Play categories, "best X app" articles,
   Reddit/forum complaints about existing apps, and Huawei device-specific gaps
   (no Google services). Note the date of every source.
2. Shortlist 5 candidates. Score each 1-5 on: demand evidence, competition weakness,
   build effort (inverse), ad-friendliness (has natural pause moments), risk.
3. Pick the best. Be honest if none scores well; say "no strong candidate this week".

## Output

Write `proposals/<yyyy-mm-dd>-<slug>.md` with:

- One-paragraph pitch and the target user.
- The 5-candidate scoring table.
- Top 3-5 competitors with what they do badly (with source links and dates).
- Feature list for a V1 buildable in a week, and an explicit "not in V1" list.
- Where ads go (which screens, which formats) and where they must never appear.
- Permissions needed and the privacy story in two sentences.
- Open risks.

Then run:

```bash
gh issue create --title "Proposal: <App Name>" --label proposal --body-file proposals/<file>.md
```

Do NOT create the spec, code, or registry entry. A human adds the `approved` label first.
