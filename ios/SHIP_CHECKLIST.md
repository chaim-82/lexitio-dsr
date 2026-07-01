# Ship checklist — TestFlight (v1)

A short, ordered path to a first TestFlight build. Assumes the app opens and
tests pass locally (`xcodebuild ... build test`).

## 1. Project & signing
- [ ] `brew install xcodegen && cd ios && xcodegen generate`
- [ ] Open `AskLexi.xcodeproj`; set your team (Signing & Capabilities) or
      `DEVELOPMENT_TEAM` in `Configs/Shared.xcconfig`.
- [ ] Confirm bundle ID `legal.asklexi.app` matches the App ID in the portal.
- [ ] Enable capabilities on the App ID: **Sign in with Apple**,
      **Associated Domains**, **Keychain Sharing**.

## 2. Config
- [ ] Set the real `API_BASE_URL` in `Configs/Prod.xcconfig` if not
      `https://asklexi.legal`.
- [ ] When the backend is confirmed, set `USE_STUB_SERVICES = NO` and smoke-test
      auth → chat → deposit → handoff against the live API.
- [ ] Keep `IAP_ENABLED = NO` for the first submission.

## 3. Deep links
- [ ] Host `apple-app-site-association` at
      `https://asklexi.legal/.well-known/` (JSON, no redirect) with
      `TEAMID.legal.asklexi.app` and `"/auth*"` (README §Deep links).
- [ ] Verify a magic link opens the app and signs in.

## 4. Assets & metadata
- [ ] Replace the placeholder app icon with the final 1024×1024 asset.
- [ ] Reconcile brand hex values in `tools/gen_assets.py` with the live site,
      re-run `python3 tools/gen_assets.py`.
- [ ] App Store Connect: name, subtitle, description, keywords, screenshots
      (iPhone 6.7" + 6.1"), support/marketing URLs.

## 5. Privacy & compliance
- [ ] App Privacy nutrition labels per README (Email, User Content, Coarse
      Location; no tracking). Confirm `PrivacyInfo.xcprivacy` matches.
- [ ] Terms / Privacy / Disclaimer URLs resolve (Settings → Legal opens them in
      SafariViewController).
- [ ] Verify the UPL framing is visible: onboarding acknowledgment, chat footer,
      Settings disclaimer. No "attorney-client" or "legal advice" claims.
- [ ] Confirm in-app **account deletion** works (Settings → Delete account).

## 6. Verify the required flows on device
- [ ] Onboarding (3 screens, disclaimer acknowledgment gates Continue).
- [ ] Sign in with Apple **and** magic link.
- [ ] Chat streams, renders markdown, shows follow-up chips + jurisdiction badge.
- [ ] Security Deposit flow: intake → rights summary + deadline math → demand
      letter → copy/share sheet.
- [ ] Attorney handoff: form → confirmation copy.
- [ ] Settings: subscription status, jurisdiction change, legal pages, sign out.
- [ ] Dynamic Type (largest size) and VoiceOver pass on each screen.

## 7. Archive & upload
- [ ] Select "Any iOS Device", Product → Archive (Release config).
- [ ] Validate, then distribute to App Store Connect → TestFlight.
- [ ] Add App Review notes + demo credentials (README §App Review notes).
- [ ] Ship to internal testers first.
