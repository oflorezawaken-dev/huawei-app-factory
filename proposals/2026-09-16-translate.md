# Proposal: Translate — the portfolio's best app, rebuilt around an engine the factory has never landed

**Date:** 2026-09-16
**Slug:** `translate`
**Verdict:** build it, but **the engine is a gate, not a detail**. Nothing below is worth
writing until Huawei ML Kit on-device translation is proven running on a real phone.

## Why this one

Of the four apps in the owner's old portfolio (2026-03-01 to 2026-08-28), this is the one
that worked:

| App | Impressions | CTR | Conversion | Downloads |
|---|---|---|---|---|
| **Translate Everything** | **245,518** | **4.26%** | **30.58%** | **5,114** |
| HashTags for Instagram | 195,198 | 0.46% | 3.85% | 127 |
| All GTA Cheats Codes | 114,858 | 4.01% | 6.07% | 970 |
| Sudoku - Sudoku Puzzles | 108,967 | 4.85% | 48.05% | 3,177 |

More impressions than anything else, and **more downloads than the rest of the portfolio
combined**. Sudoku converts better once someone is on the page, but this app is shown to
more people and brings in more of them. It is the largest single thing the owner lost when
the keystores went, and the only rebuild left that is worth more than the two already done.

Unlike Hashtags, nothing here is broken. 4.26% CTR and 30.58% conversion are healthy
numbers; the job is not to fix a listing, it is to **not lose what already works**. That
changes the risk profile completely: the failure mode for this app is shipping something
that does less than the app it replaces.

## The engine is the whole project

Every other app in this factory was arithmetic and storage. This one needs a real
translation model, and rule 3 rules out the easy answers: no backend, no Google AI, no
cloud API with a bill. That leaves exactly one option:

**Huawei ML Kit on-device translation** — `com.huawei.hms:ml-computer-translate`, 37
languages, models of 25-30 MB downloaded once and then working with no network at all.
It is the right shape for this factory: HMS is already a dependency for Petal Ads, the
audience is AppGallery users who have HMS Core, and after the first download the app is
genuinely offline.

Four things about it are unresolved, and each can sink the build:

1. **HMS Core (APK) 4.x or later must be on the device.** Every Huawei phone has it. The
   factory's only test phone is a Samsung SM-A045M that does not. Rule 8 says the app is
   verified on a real phone, so either HMS Core gets installed on that Samsung — the
   owner's personal phone, their call — or the core feature ships unverified, which is
   how ReceiptLens ended up with an OCR that does not exist.
2. **An ML Kit API key is required** (`MLApplication.setApiKey`). It comes from the AGC
   project's `agconnect-services.json`, which rule 5 keeps out of the repo. It is a
   credential like the keystore password: GitHub secret, injected through `BuildConfig`,
   never printed. This part is solved in principle, untested in practice.
3. **The first translation of a language pair needs network**, to fetch a 25-30 MB model.
   "Offline-first" survives this only if the app is honest about it: an explicit
   *download this language* step, a visible size, and a clear state when a pair is not
   downloaded yet. It must never look like a broken translator.
4. **This factory has already faked ML Kit once.** ReceiptLens ships
   `Class.forName("com.huawei...")` and an OCR that silently degrades to typing. Rule 2
   exists because of it. If ML Kit cannot be made to work here, the answer is to say so
   and stop — not to ship a translator that cannot translate.

**Proposed gate: a throwaway spike before any spec is written.** One screen, one language
pair, ML Kit wired for real, running on the phone. If the spike translates, the app is a
week of ordinary work. If it does not, this proposal is void and the next candidate is
weather (blocked on a data provider) or a fifth iOS research round.

## Store name

The old name, "Translate Everything", is brandless and says nothing a search matches. Rule
10 wants the keyword in the name, translated per language. Proposed:

- en-US: `Translate - Offline Translator`
- es-ES: `Traductor - Traduce sin internet`
- pt-PT: `Tradutor - Traduza sem internet`

"Offline" is the differentiator worth putting in the name: it is what this app has that a
web page does not, and it is true only once the model is downloaded, which the listing
must say in the first two lines rather than the sixth.

## What the app does (v1, subject to the spike)

- Type or paste text, pick source and target language, translate.
- Automatic source-language detection (`ml-computer-language-detection`), overridable.
- Language pack manager: what is downloaded, how big, delete to reclaim space.
- History of recent translations, on device, deletable.
- Copy the result, and share it out.
- No camera, no microphone, no account. Both are obvious v2 candidates and both are extra
  SDKs and permissions; v1 earns the right to them.

## Ads placement

Banner on the language-pack and settings screens; interstitial after a translation
completes, never while the user is typing and never over a result they are reading. Same
rule as everywhere: no ad on the screen where the work happens.

## Open risks

- **The spike may fail.** Stated above; it is the reason this document has a gate.
- **Model size.** 25-30 MB per pair on a phone where the user came for a free translator.
  The pack manager has to make that cost visible before the download, not after.
- **37 languages is not "everything".** The old name promised more than ML Kit delivers.
  The listing must not repeat that promise.
- **Testing on a non-Huawei phone.** Even with HMS Core installed, a Samsung is not the
  device the audience uses. Anything that works there should still be treated as verified
  only for that configuration.
