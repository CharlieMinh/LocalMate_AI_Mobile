# M3 Offline Discovery and Metro

## Baseline and safety

M2 offline accepted and merged through public PR #1. This isolated
candidate uses branch feature/m3-discovery-metro, based on sanitized public main
658b67c16b5dbefa17896c1aec2457e797c3aa4d. Original private ancestry is excluded.
M2 remote CI passed (run39206577787, 79 tests). Post-merge main run39207473566
is separate evidence; neither run validates the additional M3 source.
Asset-safe M3 delivery is authorized only after local publication gates pass.
All data requests use Dio with FailClosedAdapter; no socket transport, cookies,
auth headers or production URLs. Public routes do not require authentication.
No user-specific discovery state is stored. Existing M2 owner guards remain.

## Read-only Backend evidence

Source baseline f4eeac26cbaccf0bf4e52294211eca9f2a06b810, not deployed acceptance.
Paths below are relative to the unmodified LocalMate_AI_BE repository.

- LocalMateAI.API/Controllers/SearchController.cs: GET /api/search,
  anonymous, invalid_search_query + field errors. Application/DTOs/Search/
  SearchContracts.cs and Validators/Search/SearchQueryValidator.cs: normalized
  whitespace, Q 2..100 UTF-16 code units; limit1..10 per group, default5.
  Response keeps stations, places, curatedItineraries groups and hasMore.
- Controllers/PlacesController.cs: public metro-clusters and place GUID detail.
  DTOs/Places/PlaceDetailResponse.cs: nullable image/description/rating/Google ID,
  estimated costs are full VND, no invented current availability or rating.
- Controllers/MasterDataController.cs and DTOs/MasterData/
  MetroStationSummaryResponse.cs: station IDs, Order and coordinates. The Mobile
  snapshot matches Infrastructure/Persistence/SeedData/metro-stations.seed.json.
  Compiled fixture and bundled source snapshot equality has regression coverage.
- Services/PlaceQueryService.cs:30,55: cluster places retain distance/name/ID
  ordering; stations sorted by StationOrder. Empty cluster membership is not a
  complete station catalog. Mobile uses master-data to retain all 14 stations.
- Controllers/MetroController.cs:15,44: station departures and journeys from/to
  station order, optional date. DTOs/Metro/MetroTimetablePrecision.cs: Headway
  must not show exact departures. Exact is a precision label, not live arrivals.
  IsWithinEffectivePeriod, IsEstimated, date, notice and Headways preserved.
- Controllers/ItinerariesController.cs:17: curated GET only. Apply POST excluded
  by scope. Read-only curated presentation shows existing IDs/stops, not a saved
  trip or generated user itinerary.

## Fixture limitations

Three disposable place examples and one curated example. Place photographs with
unverified redistribution rights are excluded. Native Flutter Material category
icons and neutral branded surfaces display an image-unavailable label, including
for null, empty or supplied remote URLs. No image request or image asset loading
occurs. Original private source copies are preserved outside this repository.
Null cost fields exercise defensive incomplete-data UX beyond normal non-null
Backend cost DTOs; no financial calculation or live quote is inferred.
The sample cafe is explicitly fictional. Search uses deterministic substring
matching, not the Backend semantic engine; API shape/limits are preserved.
No GPS permission, proximity request or fabricated distance is introduced.

Station names/order/coordinates are a source snapshot, IDs are disposable fixture
IDs. Timetable date is frozen 2026-10-19 and plainly shown, not DateTime.now.
The 1->2 journey has a fixed example; other pairs return unavailable instead of
locally inventing travel time. Headway UI hides exact departures/trips. Unknown
precision or out-of-effective-period values do not expose exact times.

MapsUrlBuilder builds encoded HTTPS walking directions with validated coordinates
and optional Google Place ID. UI only previews the URI in an Android bottom sheet;
no external navigation capability or live Google Maps acceptance is claimed.

## Lifecycle, tests and fixes

Auto-disposed Riverpod request families cancel on route/query disposal. A new
query key owns the new result; late older completions cannot replace it.
Explicit retries disable Riverpod's implicit retry loop so 400/404 remain visible
instead of reverting to loading. Regression verifies no repeated call before retry.
Typed repository search failures are asynchronous, consistent with Future methods.
Shared M1/M2 navigation and auth assertions remain intact.

Test targets include invalid/normalized searches and group limits, exact query
serialization, IDs, nullable evidence, station seed parity/order, Headway/unknown
precision, route and Android Back, maps preview, empty/error/retry states,
stale request disposal, fail-closed requests, 320/390/768 and text scales1/2.
Actual results, APK checksum and emulator screenshots are recorded outside source
in local outputs/mobile-m3-asset-safe-20261019 evidence. The earlier
outputs/mobile-m3-offline-20261019 report describes the pre-migration candidate,
not a substitute for tests on this sanitized-main candidate.

## Unresolved dependencies

M0_CONTRACT_READY = NO. M2_AUTH_VERIFIED = NO. M3_DISCOVERY_VERIFIED = NO.
Live API availability, real search relevance/catalog, real-device acceptance,
Google OAuth, App Links, staging dataset and payment remain NOT_VERIFIED.
M2 logout can fail to clear storage or be interrupted before asynchronous clear
finishes; UI fails closed, explicit retry is tested. No crash-atomic guarantee.
No new Flutter dependency, BE/FE edit, mutation, payment or M4 implementation.
