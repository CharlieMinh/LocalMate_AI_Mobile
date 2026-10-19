# M2 Offline Authentication

## Scope and contract

This is not Backend authentication or JWT verification. Every request executes
through FailClosedAdapter in memory. No socket adapter is installed, including
for explicit absolute URLs. Production/staging selection cannot enable HTTP.
Only POST /auth/login and GET /users/me have authentication fixtures.

Read-only Backend baseline: f4eeac26cbaccf0bf4e52294211eca9f2a06b810.
Compared with M0 contract 80e7da0ae3109fb080616cdd1613eac3d1f55196:
AuthController, DTOs, profile DTO, JWT and access middleware are unchanged.
AuthService now grants signup trials after OTP registration and new Google
account creation. Neither operation is implemented or invoked here.

Source evidence: LocalMateAI.API/Controllers/AuthController.cs:158 (login),
:183 (Google); LocalMateAI.Application/DTOs/Auth/LoginResponse.cs:3;
LocalMateAI.Application/Services/AuthService.cs:276 (login), :476 (validation).
Email is normalized, password is not trimmed and login does not impose signup
complexity. LoginResponse contains accessToken, tokenType and expiresAt.
Profile uses GET /api/users/me. There is no refresh/logout endpoint to call.
400 validation, 401 invalid_credentials, 403 account_locked and Google-specific
409 conflicts retain typed error codes. Google is deliberately unavailable.

## Disposable fixtures

The screen can fill a clearly labelled disposable example automatically.
traveler@localmate.invalid and other@localmate.invalid use password offline-only.
locked@localmate.invalid simulates a locked account; network@localmate.invalid
simulates transport failure. These are not real accounts or credentials.

Tokens have a mock-only: prefix and opaque synthetic expiry/owner evidence;
they are NOT signed JWTs, verified Google identities or Backend sessions.
No password is persisted. Only the login envelope is stored, not profile data.
The localmate.offline.auth.v1 storage namespace and m2-offline-v1 marker reject
foreign/live session restoration. Real integration needs a separately reviewed
repository, token validation/lifecycle and migration strategy.

## Lifecycle and persistence

Generation fencing cancels obsolete login/restore requests; late success and
failure cannot replace a newer owner. Startup restore cannot cancel an explicit
login. Leaving login invalidates pending work immediately and publishes state
after widget disposal to respect Riverpod lifecycle rules. Double submit is
locked. Secure-storage writes/clears are serialized. A stale in-flight write
is cleared before a newer queued write. Adoption waits for persistence and
checks expiry again. Expiry timer and foreground resume remove private access.

Storage/plugin errors fail closed in the current UI with retry feedback.
No app can guarantee deletion from a malfunctioning OS secure store: a failed
clear may leave persisted material until a successful retry. This is especially
important before live integration; no live token exists in this milestone.
Immediate process termination before the asynchronous clear completes can also
retain the previous envelope. An early ADB tap/force-stop attempt retained it;
the completed logout followed by cold start was verified signed out. Crash-safe
server revocation is not implemented or claimed by offline M2.
Actual Android restart/restore/logout smoke is recorded externally, separately
from deterministic tests using a fake store. FullName null is rendered safely.

## Deferred dependencies

Google: Android client for vn.io.localmate.mobile, debug/release certificate
fingerprints, authorized server audience matching Backend GoogleAuth.ClientId,
operator access and approved disposable accounts remain unverified.
Payment: domain association, assetlinks.json, signing fingerprint, Android
HTTPS App Link delivery and server-owned order recovery remain unverified.
Redirect hints never grant Paid/entitlement. No payment requests are made.
Staging, test data and live acceptance require explicit later authorization.

M2 closeout adds .github/workflows/flutter.yml with pinned Flutter/Java and
read-only repository permissions. No remote run exists. Local results are not CI.
M0_CONTRACT_READY = NO. M2_AUTH_VERIFIED = NO. No M3 authorization.
