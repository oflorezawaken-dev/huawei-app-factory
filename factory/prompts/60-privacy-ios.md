# Step: write the privacy policy and support pages

Read `factory/prompts/00-factory-rules.md` first. Input: `specifications/<slug>.json`
and the app's real `Sources/Info.plist` and `Sources/PrivacyInfo.xcprivacy` — read the
permissions and declared data types the app actually ships, not the ones the spec
planned.

## Produce two pages

Apple requires **both** a privacy policy URL and a support URL; the quality gate checks
for both files. Self-contained static HTML (GitHub Pages serves `docs/` with Jekyll
disabled).

### 1. `docs/<slug>/privacy/index.html`

Must cover, truthfully for THIS app:

- What is stored on the device and that nothing is sent to servers we operate.
- Each permission and why, matching the `NS*UsageDescription` strings actually in
  `Info.plist`. No permission → do not mention it.
- **Google AdMob**, in plain language: that the app shows ads; that the Google Mobile
  Ads SDK may collect device and advertising identifiers, coarse location and usage
  data to deliver them; a link to Google's advertising privacy documentation.
- **App Tracking Transparency**: that iOS asks for permission before the app can use
  the advertising identifier for tracking, that saying no keeps every feature working
  and only makes ads less relevant, and that the answer can be changed at any time in
  Settings > Privacy & Security > Tracking.
- **Remove Ads**: that buying it stops the ad SDK from running, and that the purchase
  is handled by Apple — we never see payment details.
- Data the app keeps in its own store, and that deleting the app removes it. If the
  app has no iCloud or backup exclusion, say plainly that an iPhone backup may include
  the app's data.
- Deletion (in-app delete, uninstall), children (not directed at children), changes,
  and a contact email (use the one in an existing policy page unless told otherwise).
- "Last updated" date = today.

The page must agree with `PrivacyInfo.xcprivacy` and with the spec's
`privacy.app_privacy_answers`: every data type the manifest declares has to be
described here, and the page may not deny something the manifest declares. A mismatch
between the two is the iOS equivalent of the AppGallery privacy-tag rejection that
cost ReceiptLens its 1.0 review.

### 2. `docs/<slug>/support/index.html`

A real support page, not a placeholder: what the app does in two sentences, a short
FAQ answering the questions the proposal predicted users would ask (especially any
limitation stated honestly there, such as a feature that cannot work offline), how to
report a problem, and the same contact email. Apple opens this URL during review.

## Then

Set the URLs in the spec and, once the app exists in App Store Connect,
`factory-ios-store.yml` pushes them with the rest of the metadata:

- privacy: `<defaults.privacy_base_url>/<slug>/privacy/`
- support: `<defaults.privacy_base_url>/<slug>/support/`

Verify with `python factory/tools/check_ios_app.py <slug>` that `privacy_page` and
`support_page` pass. Commit as `docs(<slug>): privacy and support pages`.
