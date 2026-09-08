# Step: write the App Store listing in every language

Read `factory/prompts/00-factory-rules.md` first. Input: `specifications/<slug>.json`
and `apps-ios/<slug>/store/listing.json` (English may already be written).

## Rules

- Fields per language, with Apple's limits — the quality gate enforces them, so an
  over-long field fails the build instead of the review:

  | Field | Limit |
  |---|---|
  | `name` | 30 |
  | `subtitle` | 30 |
  | `promotional_text` | 170 |
  | `description` | 4000 |
  | `keywords` | 100 total, comma-separated, no spaces after commas |
  | `release_notes` | 4000 |

  Also `privacy_policy_url` and `support_url`, which Apple requires.
- **Language codes are Apple's**, from `factory/apps.json` `defaults.ios.languages`:
  `en-US`, `es-ES`, `pt-PT`, `fr-FR`, `de-DE`, `it`, `tr`, `ar-SA`, `zh-Hans`. They
  differ from Huawei's — Arabic is `ar-SA` not `ar`, Chinese is `zh-Hans` not `zh-CN`,
  Italian and Turkish carry no region. Never copy `defaults.languages`.
- `keywords` is not prose: comma-separated terms, no repetition of words already in
  `name` or `subtitle` (Apple indexes those separately, so repeating wastes the 100
  characters), no competitor names, no spaces after the commas.
- `subtitle` should say what the app is in a few words, not repeat the name.
- Describe only what the shipped build does. Disclose that the app shows ads and that
  a one-time purchase removes them. Do not promise anything listed as "not in V1".
- Keep the app name untranslated unless the spec says otherwise.
- Same structure and meaning in every language; natural phrasing, not word-for-word.
- Add to the file's `_notes` that translations are machine-drafted and should get a
  native review before a real launch.

Remove any `"_todo": true` markers you resolve. Validate with:

```bash
python factory/tools/check_ios_app.py <slug>
```

and confirm the `listing` rule passes. Commit as `store(<slug>): listing in <n> languages`.
