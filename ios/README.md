# Lexi by Lexitio — iOS app (v1)

Native SwiftUI app for **AskLexi** (asklexi.legal): an AI legal *educator* for
consumers. Lexi explains rights, options, deadlines, and documents, and hands off
to a licensed-attorney marketplace. **Lexi provides legal information, not legal
advice** — this UPL boundary is enforced throughout the UX.

> Built as a real SwiftUI app (MVVM + `@Observable`, Swift Concurrency), not a
> WebView wrapper.

---

## Requirements

- **Xcode 15.3+** (Swift 5.10), iOS 17.0+ deployment target, a Mac.
- **[XcodeGen](https://github.com/yonwoo9/XcodeGen)** to generate the project:
  `brew install xcodegen`.
- Zero third-party Swift packages.

## Generate & open

```bash
cd ios
xcodegen generate         # reads project.yml → AskLexi.xcodeproj (git-ignored)
open AskLexi.xcodeproj
```

If you regenerate assets (colors / placeholder icon):

```bash
python3 tools/gen_assets.py
```

## Build, run, test (from the CLI)

```bash
cd ios
xcodebuild -scheme AskLexi \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build test
```

> This project was scaffolded on Linux (no macOS toolchain available in the
> build environment), so the `xcodebuild ... build test` gate has **not** been
> run here — run it once on your Mac. Every file is written to compile against
> iOS 17 / Swift 5.10; the deadline math, SSE parser, API decoding, Keychain,
> markdown parser, and email validation are covered by unit tests, plus one
> onboarding→Home UI test.

---

## Configuration

Runtime config comes from the active `.xcconfig` (via `Info.plist`), read by
`Config.swift`. Two configs are provided:

| Setting | Debug (`Configs/Dev.xcconfig`) | Release (`Configs/Prod.xcconfig`) |
|---|---|---|
| `API_BASE_URL` | `https://asklexi.legal` | `https://asklexi.legal` |
| `IAP_ENABLED` | `NO` | `NO` |
| `USE_STUB_SERVICES` | `YES` | `YES` |

- **`USE_STUB_SERVICES = YES`** runs the whole app against in-memory stubs so it
  is fully demoable offline. The live backend endpoints were **not reachable**
  from the scaffold environment (org egress policy blocked `asklexi.legal`), so
  the request/response models are assumptions documented in
  [`BACKEND_TODO.md`](./BACKEND_TODO.md). Flip to `NO` once those endpoints are
  confirmed, then run against the real API.
- **`API_BASE_URL`**: if the production API lives on a dedicated host
  (e.g. `api.asklexi.legal`), update `Configs/Prod.xcconfig`.
- **Team ID / signing**: set `DEVELOPMENT_TEAM` in `Configs/Shared.xcconfig`, or
  just enable *Automatically manage signing* in Xcode's Signing & Capabilities
  tab and pick your team. (No Team ID was available at scaffold time.)

## Monetization (v1)

Ships **Free tier only**. The paywall UI is present but StoreKit purchases are
gated behind `Config.iapEnabled` (currently `false`). `SubscriptionManager` is a
complete StoreKit 2 implementation (`Product`, `Transaction.currentEntitlements`,
purchase/restore, transaction listening, backend entitlement sync) using product
IDs `legal.asklexi.plus.monthly` and `legal.asklexi.pro.monthly`. Flipping
`IAP_ENABLED = YES` (after products exist in App Store Connect and are reviewed)
is the only change needed. A local `AskLexi/Resources/Legal.storekit` config lets
you exercise purchases in the simulator.

---

## Architecture

```
App/            App entry, RootView, AppState (phase/router), AppEnvironment (DI)
Config/         Config.swift (xcconfig-backed)
DesignSystem/   Theme (semantic color tokens), Typography, Components, Wordmark
Networking/     APIClient (actor), Endpoint, SSEParser, DTOs, SessionStore
  Services/     AuthService, ChatService, MarketplaceService, SubscriptionService
                (each: protocol + Live + Stub)
Persistence/    KeychainStore, SwiftData models (conversation cache, drafts)
Features/       Onboarding, Auth, Home, Chat, Deposit, Handoff, Settings, Paywall
Common/         Strings, USState, StateViews, ShareSheet, SafariView, StatePicker
Resources/      Assets.xcassets, Info.plist, entitlements, PrivacyInfo, StoreKit
```

- **Networking**: a single `APIClient` actor over `URLSession`, snake_case
  JSON coding, ISO-8601 dates, transparent silent-refresh on 401.
- **Streaming chat**: SSE via `URLSession.bytes(for:).lines` + a pure `SSEParser`
  (`data:` lines, `[DONE]` sentinel), with a non-streaming fallback.
- **Persistence**: SwiftData for the local conversation cache and deposit drafts;
  Keychain (`KeychainStore`) for tokens.
- **Services** are protocol-based with Live (network) and Stub (in-memory)
  implementations selected by `Config.useStubServices`.

## Deep links (magic-link auth)

Two paths back into the app after tapping an emailed link:

1. **Universal Links** — `applinks:asklexi.legal` (see `AskLexi.entitlements`).
   Host this JSON at `https://asklexi.legal/.well-known/apple-app-site-association`
   (served as `application/json`, no redirect):

   ```json
   {
     "applinks": {
       "apps": [],
       "details": [
         { "appID": "J72CHKVAHR.legal.asklexi.app", "paths": ["/auth*"] }
       ]
     }
   }
   ```
   

2. **Custom scheme fallback** — `asklexi://auth?token=…` (registered in
   `Info.plist`). Handled in `AppState.handleDeepLink(_:)`.

Both resolve to `POST /auth/magic-link/verify` (see `BACKEND_TODO.md`).

---

## App Store submission notes

### App Privacy nutrition labels (answers)

Data collected, all **linked to identity**, **not used for tracking**:

| Data type | Purpose | Notes |
|---|---|---|
| Email address | App Functionality (account, magic-link) | From sign-in |
| User Content | App Functionality | The questions/intake shared with Lexi |
| Coarse Location | App Functionality | The **US state** the user selects — not precise GPS |

- **Tracking:** No. No third-party analytics/ads SDKs; `NSPrivacyTracking=false`.
- Kept in sync with `Resources/PrivacyInfo.xcprivacy`.

### App Review notes (paste into App Review Information → Notes)

> Lexi is a legal-**information** and self-help education app for consumers. It
> explains rights, deadlines, and documents in plain language and does **not**
> provide legal advice or create an attorney-client relationship — this is stated
> in onboarding (with an explicit acknowledgment), as a persistent footer in
> chat, and in Settings. The "Talk to a lawyer" feature hands off to Lexitio's
> licensed-attorney marketplace, where independent licensed attorneys respond
> with flat-fee quotes; Lexi/Lexitio is not a law firm. v1 ships Free-only; the
> paywall UI is visible but in-app purchases are disabled. Account creation uses
> Sign in with Apple or a magic email link; in-app account deletion is in
> Settings → Delete account.

- **Demo account:** `TODO` — provide an email + pre-issued magic token or a
  reviewer bypass. With `USE_STUB_SERVICES = YES`, tapping *Email me a sign-in
  link* then Sign in with Apple both succeed against the stub for review.
- **Sign in with Apple** is enabled (entitlement + capability required on the
  App ID).
- **Account deletion** (guideline 5.1.1(v)) is implemented in Settings.

## Brand

Palette is defined once as semantic tokens in `Theme.swift`, backed by
`Assets.xcassets` color sets with dark-mode variants (deepened pine, warm-dark
cream). The exact hex values live in `tools/gen_assets.py`. **These are
documented approximations** — the live asklexi.legal CSS was unreachable at
scaffold time, so reconcile the hex values against the site before launch (the
token *names* are the stable contract). Headlines use New York (serif); body/UI
use SF. The wordmark is "**Lexi** by Lexitio".

## Open items

- Reconcile brand hex values with live site CSS.
- Replace the placeholder app icon (pine field + gold "L") with the final asset.
- Confirm backend endpoints and flip `USE_STUB_SERVICES = NO` (`BACKEND_TODO.md`).
- Set `DEVELOPMENT_TEAM` and host the `apple-app-site-association` file.

See [`SHIP_CHECKLIST.md`](./SHIP_CHECKLIST.md) for the TestFlight path.
