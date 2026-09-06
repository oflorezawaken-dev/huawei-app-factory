# huawei-app-factory

A pipeline that takes an Android utility app from idea to Huawei AppGallery with a
human deciding at four points and GitHub Actions plus a handful of Python tools doing
the rest. First app: **ReceiptLens**, a privacy-first receipt organizer, submitted for
review on 2026-09-06.

- **How the factory works, triggers, and rules:** [factory/README.md](factory/README.md)
- **App registry:** [factory/apps.json](factory/apps.json)
- **AppGallery Connect publishing guide and API notes:** [docs/APPGALLERY_PUBLISHING.md](docs/APPGALLERY_PUBLISHING.md)
- **Release log, lessons, known bugs:** [docs/RELEASE_STATUS.md](docs/RELEASE_STATUS.md)
- **ReceiptLens privacy policy (live):** https://oflorezawaken-dev.github.io/huawei-app-factory/privacy/

```text
apps/<slug>/            Android project + store/ (icon, screenshots, listing.json)
specifications/         APP_SPEC template and one spec per app
factory/                registry, tools, prompts, local CLI
.github/workflows/      factory-build, factory-store, factory-publish
docs/                   guides, release log, privacy pages (GitHub Pages)
```

No secrets live in this repository. Signing and AppGallery credentials are GitHub
secrets; ad unit IDs and App IDs are configuration, not code.
