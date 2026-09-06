# Step: write the store listing in every language

Read `factory/prompts/00-factory-rules.md` first. Input: `specifications/<slug>.json`
and `apps/<slug>/store/listing.json` (English may already be written).

## Rules

- Fields per language: `lang`, `appName`, `briefInfo` (≤ 80 chars), `appDesc`
  (300-1500 chars, plain text with line breaks and `•` bullets), `newFeatures`
  (10-300 chars, required by AppGallery for submission).
- Language codes must be the AppGallery Connect codes from `factory/apps.json`
  `defaults.languages` (note: Arabic is `ar`, not `ar-SA`).
- Describe only what the shipped build does. Disclose that the app shows ads. Do not
  promise features listed as "not in V1".
- Keep the app name untranslated unless the spec says otherwise.
- Same structure and meaning in every language; natural phrasing, not word-for-word.
- Add to the file's `_notes` that translations are machine-drafted and should get a
  native review before a real launch.

Remove any `"_todo": true` markers you resolve. Validate with
`python factory/tools/agc_update_listing.py --app-id 0 --listing apps/<slug>/store/listing.json --all --dry-run`.
Commit as `store(<slug>): listing in <n> languages`.
