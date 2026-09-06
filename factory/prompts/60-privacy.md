# Step: write the privacy policy page

Read `factory/prompts/00-factory-rules.md` first. Input: `specifications/<slug>.json`,
the app's manifest and Gradle files (to see real permissions, SDKs, and backup rules).

## Produce

`docs/<slug>/privacy/index.html`, self-contained static HTML (GitHub Pages serves
`docs/` with Jekyll disabled). Start from `docs/privacy/index.html` and rewrite.

Must cover, truthfully for THIS app:

- What is stored on the device and that nothing is sent to servers we operate.
- Each permission and why (camera, storage, sensors...). No permission → don't mention.
- **Huawei Petal Ads**: that the app shows ads, that the ad SDK may collect device
  identifiers and usage data for ad delivery, link to Huawei's Petal Ads / AppGallery
  privacy documentation, and how users can limit ad personalization on their device.
- Backup: if `allowBackup` is true without excludes, say OS backups may include app data;
  if false or excluded, say data never leaves the device.
- Deletion (in-app delete, uninstall), children (not directed at children), changes,
  and a contact email (use the one in the existing policy unless told otherwise).
- "Last updated" date = today.

Then set the URL: `<defaults.privacy_base_url>/<slug>/privacy/`. Commit as
`docs(<slug>): privacy policy`. The Factory Store Setup workflow pushes the URL to
AppGallery Connect (`what: app-info`).
