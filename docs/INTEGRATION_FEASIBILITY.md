# M1 Integration Feasibility - 2026-10-19

## Scope and verdict

Source/configuration assessment only. Google OAuth and payment return:
PARTIAL (local architecture and source contract understood); deployed
configuration, device round trip and sandbox acceptance: NOT_VERIFIED.
No Backend requests, checkout, order lookup, reconciliation or credentials
operations were performed for this milestone. Existing Backend running on
the workstation is not authorization to connect this app.

## Google OAuth

Android application ID: vn.io.localmate.mobile. A native Android OAuth
client needs that package and appropriate debug/release signing SHA-1
(and SHA-256 where required by configuration). Release signing identity
must be owned and backed up outside Git; debug identity is not release.
The Backend validates ID token audience against GoogleAuth.ClientId:
BE/LocalMate_AI_BE/LocalMateAI.Infrastructure/Security/GoogleIdentityTokenValidator.cs:23.
Android server-client ID/token audience must match that Backend value;
do not assume the Android client ID itself is the expected audience.
Debug signing fingerprints must be generated locally with keytool and registered with the OAuth operator. They are not shared in public source.

Release fingerprints remain unverified until signing is provisioned in M9.

No keystore or private key is included in this repository.

Obtain Android client + server/web client configuration from the OAuth
operator without copying client secrets to Flutter. Verify consent/testing
access, email-verified behavior and account-link-required/conflict errors
at M2. M1 has no Google plugin or login flow.

## Android HTTPS App Links

No external intent filter/domain is activated yet: domain ownership and
authorized return paths remain unknown. A later verified configuration
needs HTTPS host/path, Android VIEW/DEFAULT/BROWSABLE autoVerify filter and
domain `/.well-known/assetlinks.json` with package and signing SHA-256.
Use controlled staging association; do not change production domain.
Source: Android official App Links documentation:
https://developer.android.com/training/app-links/verify-applinks

Internal /payment-return accepts only a GUID orderId and explicit flow
subscription/single. Duplicate/malformed identifiers and unknown flow are
rejected. Status/cancel URL claims never grant Paid or entitlement. The
screen only says verification is not connected. It makes no request.
This internal abstraction is not proof of HTTPS link association.

## Owned-order recovery (future M7)

Persist owner + flow + owned order + clientAttemptId for Single, and an
appropriate session generation. Links are untrusted wake-up hints, not
ownership evidence. After return/restart, restore and validate session;
ignore or quarantine an intent for another owner. Only the matching flow's
owned-order endpoint may verify status. No unresolved Subscription-to-Single
fallback. Do not create a new checkout on lookup retry; Single retries reuse
the same clientAttemptId. Paid without authoritative entitlement evidence
remains verifying; countdown zero is not Expired. Account change aborts
polling and rejects stale completions before state or navigation updates.

Backend sources: Infrastructure/Payments/PayOSGatewayOptions.cs:10,20
requires HTTP(S) ReturnUrl/CancelUrl; PayOSPaymentGateway.cs:35 uses server
configuration. Application/Services/PaymentService.cs:123,134 and
ItineraryPurchaseService.cs:75,79 show owned lookup and reconciliation.
Those GETs can change server reconciliation state, so M1 never calls them.

## External dependencies and owners

| Dependency | Owner | Next checkpoint | External ETA |
| --- | --- | --- | --- |
| HTTPS staging URL, TLS and release mapping | Backend environment operator | 21/10 internal | NOT_VERIFIED |
| Disposable users and reset/isolation policy | Backend test-data operator | 21/10 internal | NOT_VERIFIED |
| OAuth client/audience and certificate registration | OAuth operator + Mobile engineer | 21/10 internal; M2 smoke | NOT_VERIFIED |
| Return/cancel paths and assetlinks ownership | Domain/payment operator + Mobile engineer | 20/10 internal feasibility | NOT_VERIFIED |
| Sandbox acceptance and provider behavior | Payment environment operator | Before M7 | NOT_VERIFIED |
| Physical Android acceptance device | User + Mobile engineer | Before M9 | NOT_VERIFIED |

Internal checkpoints are not external commitments. Backend was separately
updated to f4eeac26cbaccf0bf4e52294211eca9f2a06b810 before this milestone.
It contains changes beyond M0's BE contract snapshot 80e7da0ae3109fb080616cdd1613eac3d1f55196;
future integrations must reconcile current DTOs instead of claiming cached
M0 contracts describe every newer response. FE reference remains
ae3c26054817435353ccfdbc456a726980bb48fd. No FE/BE edits in M1.
