# LocalMate AI Mobile

Android-first Flutter M3 offline discovery/Metro candidate on the accepted M2
offline authentication baseline. No live authentication, AI, payment or Trip
mutation is authorized.

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
Unmatched mock requests throw typed errors. Bootstrap reads only the isolated
offline secure-storage envelope; restoration uses local fixtures, never HTTP.
Debug INTERNET permission is for Flutter tooling;
it does not authorize Backend access.

## Boundaries

- `lib/app`: bootstrap/configuration/provider composition/router.
- `lib/core`: transport, typed errors, session ownership/cancellation,
  secure-storage interface and untrusted return hints.
- `lib/shared`: theme and accessible loading/error/empty widgets.
- `lib/features/foundation`: local metadata and non-integrated feature skeletons.
- `lib/features/auth`: offline login, secure session storage and route guards.
- `lib/features/discovery`: mock Home/Explore/place details and Metro screens.
- `test`: fail-closed transport, lifecycle/account guards, routing and
  responsive widget regression; secure-storage fake lives only in tests.

Private routes require an explicitly labelled offline mock session in M2.
SessionScope invalidates same-owner reauthentication as well as account
switch/logout/disposal; deferred success and errors are both rejected.
SecureSessionStore is a platform adapter with an offline-only namespace.

Brand logo and Be Vietnam Pro fonts were copied from the existing FE repo
without modifying it. Font OFL license is in assets/fonts/OFL.txt. Only
valid nonempty assets are bundled. Unlicensed place photographs are excluded.
Place cards use native Material category icons and image-unavailable labels;
no place image asset or remote image is loaded.
Theme uses navy #1D3E82, amber #F6A623 and canvas #F4F6FA, Material3.

Public source uses sanitized M1/M2 history. M2 was merged in
[PR #1](https://github.com/CharlieMinh/LocalMate_AI_Mobile/pull/1).
M3 branch `feature/m3-discovery-metro` starts at
main `658b67c16b5dbefa17896c1aec2457e797c3aa4d` and remains mock-only.
CI workflow runs analyze/test/debug APK with Flutter 3.47.6 and Java 21.0.12.
The [M2 PR run](https://github.com/CharlieMinh/LocalMate_AI_Mobile/actions/runs/39206577787)
passed analyze, 79 tests and debug APK build. The separate
[post-merge main run](https://github.com/CharlieMinh/LocalMate_AI_Mobile/actions/runs/39207473566)
does not validate the additional M3 source. M3 CI results must be checked on
the M3 branch/PR, separately from these earlier runs.
Release signing is deferred to M9 and never substitutes a debug signature.

See docs/INTEGRATION_FEASIBILITY.md. OAuth/App Links are not live verified.
See docs/M2_OFFLINE_AUTH.md and docs/M3_OFFLINE_DISCOVERY.md for fixtures and
limitations. M0 contract gate stays NO; M2_AUTH_VERIFIED and
M3_DISCOVERY_VERIFIED stay NO. Live Backend/OAuth/payment are not verified.
