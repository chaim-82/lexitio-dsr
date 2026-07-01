# Backend TODO — endpoints the iOS app expects

The AskLexi API (`https://asklexi.legal`) was **not reachable** from the
environment where this app was scaffolded (organization egress policy returned
403 at the gateway for `asklexi.legal`), so `{API_BASE_URL}/openapi.json` could
not be read. The request/response shapes below are therefore **assumptions**.
The app currently runs against in-memory stubs (`Config.useStubServices == true`).

**To go live:** confirm/adjust each endpoint, update the DTOs in
`AskLexi/Networking/DTOs.swift` and the paths in
`AskLexi/Networking/Services/*` if they differ, then set
`USE_STUB_SERVICES = NO` in both xcconfigs.

Conventions assumed: JSON bodies are **snake_case**; dates are **ISO-8601**;
authenticated requests carry `Authorization: Bearer <access_token>`.

---

## Auth

| Method | Path | Body | Response | Notes |
|---|---|---|---|---|
| POST | `/auth/magic-link` | `{ email }` | `204`/`200` | Emails a sign-in link |
| POST | `/auth/magic-link/verify` | `{ token }` | `{ access_token, refresh_token, expires_in?, user? }` | From deep link `?token=` |
| POST | `/auth/apple` | `{ identity_token, authorization_code?, full_name?, email? }` | same as above | Sign in with Apple |
| POST | `/auth/refresh` | `{ refresh_token }` | `{ access_token, refresh_token, expires_in? }` | Called on 401; must **not** itself require the expired access token |
| GET | `/me` | — | `{ id, email?, name?, jurisdiction?, tier? }` | Current user |
| POST | `/me/disclaimer` | `{ acknowledged_at, version }` | `200` | Records UPL acknowledgment |
| DELETE | `/me` | — | `200`/`204` | **In-app account deletion (mandatory, App Store 5.1.1(v))** |

The magic-link deep link must land on `https://asklexi.legal/auth?token=…`
(Universal Link) and/or `asklexi://auth?token=…` (custom scheme). See README
§Deep links for the `apple-app-site-association` file the backend must host.

## Chat

| Method | Path | Body | Response | Notes |
|---|---|---|---|---|
| POST | `/chat` | `{ conversation_id?, content, jurisdiction }` | **SSE** stream | `Accept: text/event-stream`. Emit `data:` chunks shaped `{ delta?, conversation_id?, done?, suggestions? }`, terminated by `done: true` or a `data: [DONE]` line. Falls back to a single JSON body if not streamed. |
| GET | `/conversations` | — | `[{ id, title?, jurisdiction?, updated_at?, messages? }]` | Recent list |
| GET | `/conversations/{id}` | — | `{ id, title?, jurisdiction?, updated_at?, messages: [{ id, role, content, created_at? }] }` | Full thread |

`role` is one of `user` \| `assistant` \| `system`.

## Attorney marketplace (handoff)

| Method | Path | Body | Response | Notes |
|---|---|---|---|---|
| POST | `/marketplace/requests` | `{ category, jurisdiction, summary, budget_cents? }` | `{ id, status? }` | Creates a reverse-auction request; bidding UI is out of scope for v1 |

## Billing / entitlements (needed when IAP is enabled)

| Method | Path | Body | Response | Notes |
|---|---|---|---|---|
| POST | `/billing/entitlement` | `{ transaction_id, product_id }` | `{ tier, active, expires_at? }` | Sync a verified StoreKit 2 transaction server-side |
| GET | `/billing/entitlement` | — | `{ tier, active, expires_at? }` | Server view of entitlement |

`tier` is one of `free` \| `plus` \| `pro`. Product IDs:
`legal.asklexi.plus.monthly`, `legal.asklexi.pro.monthly`.

---

## Non-endpoint follow-ups

- **Brand hex values**: `tools/gen_assets.py` uses documented approximations of
  the pine/gold/cream palette because the live CSS was blocked. Confirm against
  asklexi.legal.
- **Security-deposit rules**: `DepositDeadline.swift` ships a small, simplified
  state→return-window table (NY = 14 days, etc.) used for the deadline math. The
  backend should eventually own the authoritative, per-state rules; until then
  these drive the client-side calculation and demand-letter generation.
