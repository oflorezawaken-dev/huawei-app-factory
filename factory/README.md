# Huawei App Factory

A reusable pipeline that turns an approved app idea into a signed Android release
published on Huawei AppGallery, with a human deciding at four points and everything
else automated. Proven end to end with [ReceiptLens](../apps/receipt-lens) on 2026-09-06.

## The two layers

| Layer | What it does | Runs where | Costs tokens? |
|---|---|---|---|
| **Conductor** | Build, test, sign, quality gate, upload to AppGallery Connect, push listing/icon/screenshots/app-info, submit | GitHub Actions (`.github/workflows/factory-*.yml`) + `factory/tools/*.py` | No |
| **Brain** | Research ideas, write the spec, generate the app, fix builds, write listing text and the privacy page | Claude Code headless (`claude -p`) with the prompts in `factory/prompts/`, launched by `factory/factory.py` from your machine (or a scheduler) | Yes, on your subscription |

State lives in GitHub: a proposal is an issue, approval is the `approved` label, a
generated app is a PR, the AppGallery App ID is a field in `factory/apps.json`.

## One app, start to finish

```text
cron / you        python factory/factory.py research          → proposals/<date>-<slug>.md + issue
YOU (5 min)       read the issue → add label `approved`
you               python factory/factory.py spec <slug> --proposal proposals/<file>.md
you               python factory/factory.py generate <slug>   → branch app/<slug> + PR
Actions           Factory Build on the PR: gate + tests + debug APK
YOU (5 min)       review the PR (screenshots, gate output) → merge
Actions           Factory Build on main: signed APK + AAB artifacts
YOU (10 min)      AppGallery Connect: create app, content rating, countries → paste App ID into factory/apps.json
you               python factory/factory.py store <slug>       → listing (9 langs), icon, screenshots, privacy URL
you               python factory/factory.py publish <slug>     → upload APK, no submission
YOU (2 min)       glance at the console
you               python factory/factory.py publish <slug> --submit --notes "..."
```

"you" lines can be a scheduled task; "YOU" lines are decisions only a person can make.

## Workflows

| Workflow | Trigger | Input | Does |
|---|---|---|---|
| `factory-build.yml` | push/PR touching `apps/**` or `factory/**`, or manual | `app` (optional) | Builds only the apps whose folder changed. `verify`: gate + unit tests + debug APK. `release` (main only): signed APK + AAB as `<slug>-release-apk/-aab`. |
| `factory-store.yml` | manual | `app`, `what`, `lang`, `app_info_fields`, `dry_run` | Pushes listing text, icon, screenshots, and/or app-info (privacy URL by default) to AppGallery Connect. |
| `factory-publish.yml` | manual | `app`, `release_run_id`, `package_type`, `submit_for_review`, `release_notes` | Downloads the signed artifact, verifies the signature, uploads it, optionally submits for review. |

All AppGallery steps run in the `appgallery` environment, which holds `AGC_CLIENT_ID`
and `AGC_CLIENT_SECRET`. Release signing uses the four `RELEASE_*` repository secrets.

## Registry: `factory/apps.json`

One entry per app: slug, name, path, package, `agc_app_id`, spec, store dir, privacy
path, status, current version, and `known_gaps`. `defaults` holds the factory rules,
Java/Gradle versions, the 9 store languages, and the screenshot-folder → AppGallery
language-code mapping (Arabic is `ar`, not `ar-SA`).

## Quality gate: `factory/tools/check_app.py`

Runs in every build and before you open a PR. Checks that Petal Ads is really in
Gradle (repo + dependency + INTERNET permission), that there are no
`Class.forName("com.huawei...")` reflection stubs, no Firebase/GMS/Google-AI
dependencies, that `applicationId` matches the registry, and that icon, ≥3
screenshots, full-language listing, privacy page, and spec exist.

A failure listed in the app's `known_gaps` is reported as `EXCUSED` instead of failing
the build, so gaps are documented rather than hidden. `--strict` ignores excuses and is
required for new apps. ReceiptLens 1.0 has three excused gaps (fake Petal Ads stub, fake
ML Kit stub, missing INTERNET) that 1.1 must close.

## Rules (short form; full text in `factory/prompts/00-factory-rules.md`)

1. Every app ships the real Huawei Petal Ads SDK and shows ads on non-critical screens.
2. No reflection stubs pretending to be SDKs.
3. Offline-first core; no Firebase, GMS, Google AI, backend, or accounts.
4. Copy tells the truth about the shipped build.
5. Secrets never enter the repo.

## What Huawei will not let us automate

Creating the app in AppGallery Connect, the content-rating questionnaire, the Petal Ads
publisher account and ad units, and responding to review results. Budget ~15 minutes of
console time per app for the first three.

## Adding app #2

1. `python factory/factory.py research` → approve the issue.
2. `spec`, then `generate` → PR → merge.
3. Console: create app + rating + countries → paste App ID into `factory/apps.json`.
4. `store`, `publish`, then `publish --submit`.

Lessons from ReceiptLens (errors and their fixes) are in `docs/APPGALLERY_PUBLISHING.md`
and `docs/RELEASE_STATUS.md`.
