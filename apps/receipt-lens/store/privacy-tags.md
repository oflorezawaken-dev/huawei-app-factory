# AppGallery privacy tags checklist: ReceiptLens (receipt-lens)

Console path: **AppGallery Connect > Apps and atomic services > ReceiptLens > Version information > Privacy tags**

Generated from `apps/receipt-lens/store/privacy-tags.json`. Labels are the official English console names; a localized console translates them but keeps the same order and grouping.

1. **Collect personal data** -> **Yes**
2. Select these service scenarios: **App functionality**, **Advertising and marketing**, **Disclosure to third parties**
3. On each scenario tab, tick exactly these data items:

## App functionality

| Data category | Data item | Why |
|---|---|---|
| Transaction information | Transaction records | Receipt content the user captures (merchant, total, date, category), stored in the on-device database only. |
| User information | Image or video | Receipt photos taken with the camera or picked from the gallery; stored in app-private storage on the device only. |

## Advertising and marketing

| Data category | Data item | Why |
|---|---|---|
| Location information | Other approximate location information | Petal Ads derives city/country from the IP address. |
| Identifiers | OAID | Read by the Huawei Petal Ads SDK for ad delivery and measurement. |
| App information | Basic app information | Package name and version sent by the Petal Ads SDK with ad requests. |
| App information | App usage information | Ad events (impressions, clicks) reported by the Petal Ads SDK. |
| Device information | OS information | Petal Ads SDK: Android/EMUI version for ad delivery. |
| Device information | Device status | Petal Ads SDK: battery and storage status. |
| Device information | Network type | Petal Ads SDK: Wi-Fi or mobile network type. |
| Device information | Carrier | Petal Ads SDK: carrier information. |
| Device information | IP address | Petal Ads SDK: network address of each ad request. |
| Device information | Acceleration sensor | Petal Ads SDK: motion data used for ad-fraud detection. |
| Device information | Gyroscope | Petal Ads SDK: motion data used for ad-fraud detection. |
| Device information | Other hardware and software parameters/System settings | Petal Ads SDK: device brand/model, screen resolution, language, region. |

## Disclosure to third parties

| Data category | Data item | Why |
|---|---|---|
| Identifiers | OAID | Read by the Huawei Petal Ads SDK for ad delivery and measurement. |
| App information | App usage information | Ad events (impressions, clicks) reported by the Petal Ads SDK. |
| Device information | OS information | Petal Ads SDK: Android/EMUI version for ad delivery. |
| Device information | Network type | Petal Ads SDK: Wi-Fi or mobile network type. |
| Device information | Carrier | Petal Ads SDK: carrier information. |
| Device information | IP address | Petal Ads SDK: network address of each ad request. |
| Device information | Other hardware and software parameters/System settings | Petal Ads SDK: device brand/model, screen resolution, language, region. |

## Scenarios left unselected

- **Product personalization**: No user profiling; ad personalisation belongs to the Petal Ads scenario.
- **Analytics**: No analytics or crash-reporting SDK.
- **Cross-border transfer**: Scenario means data sent outside the Chinese mainland; the app is not distributed in the Chinese mainland.
- **Others**: not applicable

4. Open the **Summary** tab and compare it with the tables above, then save.
5. Record the date in `factory/apps.json` -> `receipt-lens.privacy_tags_configured` (the publish workflow refuses `submit_for_review` while it is empty).

Keep this file, the privacy policy page and the manifest in sync: a new permission or SDK means a new item here and in the policy. Reference: https://developer.huawei.com/consumer/en/doc/app/privacy-label
