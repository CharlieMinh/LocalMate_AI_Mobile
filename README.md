# LocalMate AI Mobile

Android-first Flutter M1 Foundation candidate. No authentication, AI, payment,
Trip mutation or live Backend integration is implemented or authorized.

## Run and verify

Use Flutter 3.47.6 / Dart 3.13.5. Direct dependencies have exact versions in
pubspec.yaml; pubspec.lock pins transitive dependencies. Android toolchain:
JDK 21.0.12, template AGP 9.1.0 / Gradle 9.3.1, compile/target API36 and
minSdk24. The Flutter SDK template provides these Android levels. API35 is
the initial emulator smoke target. Application ID: `vn.io.localmate.mobile`.

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter run -d emulator-5554
```

Development defaults to mock-only. `--dart-define=APP_ENV=staging` or
`production` changes only the environment label: no URL or live adapter can
be enabled in this milestone. Unknown environment names fail explicitly.
Unmatched mock requests throw typed errors. Bootstrap does not read tokens
or issue API requests. Debug INTERNET permission is for Flutter tooling;
it does not authorize Backend access.

## Boundaries

- `lib/app`: bootstrap/configuration/provider composition/router.
- `lib/core`: transport, typed errors, session ownership/cancellation,
  secure-storage interface and untrusted return hints.
- `lib/shared`: theme and accessible loading/error/empty widgets.
- `lib/features/foundation`: local metadata data/application boundaries and
  five native presentation skeletons, not fake integrated screens.
- `test`: fail-closed transport, lifecycle/account guards, routing and
  responsive widget regression; secure-storage fake lives only in tests.

Private routes stay closed in M1. No mock logged-in session is established.
SessionScope invalidates same-owner reauthentication as well as account
switch/logout/disposal; deferred success and errors are both rejected.
SecureSessionStore is a platform adapter, unused by bootstrap until M2.

Brand logo and Be Vietnam Pro fonts were copied from the existing FE repo
without modifying it. Font OFL license is in assets/fonts/OFL.txt. Only
valid nonempty logo/font files are bundled; no place photo is invented.
Theme uses navy #1D3E82, amber #F6A623 and canvas #F4F6FA, Material3.

This is a local Git repository on feature/m1-app-foundation with unborn
HEAD, no commits, no remote, no push or PR. Main remains the planned base
branch; it cannot point to a commit until separate Git delivery approval.
Release signing is deferred to M9 and never substitutes a debug signature.

See docs/INTEGRATION_FEASIBILITY.md. OAuth/App Links are not live verified.
M0 contract gate stays NO; stop at WAIT_FOR_M1_REVIEW, not M2.
