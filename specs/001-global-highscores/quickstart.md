# Quickstart and validation: Global Top 100 Highscores

The API and native iPhone integration are implemented. Commands below run from repository root. [Validation](validation.md) records actual results and remaining release checks; [HTTP](contracts/highscores.openapi.yaml) and [iOS flow](contracts/ios-flow.md) remain the behavior contracts.

## Tools and SDK selection

Use Xcode 27, an iPhone 13 simulator on iOS 26+, the .NET SDK selected by root `global.json`, Python 3, Node/npm for Azurite and k6 for load tests. Selected SDK/runtime: 10.0.401/10.0.12. Validated emulator: Azurite 3.37.0; load tool: k6 2.2.0. No Azure account or production key is needed for local tests. Docker is optional and currently unverified locally.

```sh
export PATH="$HOME/.dotnet:$PATH"
dotnet --version
(cd src/backend && dotnet --version)
(cd src/backend.tests && dotnet --version)
dotnet build src/backend -c Release
```

All three directories follow the root SDK pin with `latestPatch` roll-forward. The local API helper expects `~/.dotnet/dotnet`.

## Owned local storage and API

In terminal A:

```sh
DT3D_AZURITE_DATA=$(mktemp -d /tmp/dt3d-highscores-azurite.XXXXXX)
npx --yes --package azurite@3.37.0 azurite-blob \
  --blobHost 127.0.0.1 --blobPort 10000 \
  --location "$DT3D_AZURITE_DATA" --silent --disableTelemetry
```

Use a fresh directory/free port. Do not suppress API-version compatibility checks. In terminal B:

```sh
python3 src/tests/support/local-highscores.py --state-file /tmp/dt3d-local-api.json
```

The helper creates a unique private emulator container and loopback API; prints its origin and records owned PIDs. Ctrl-C cleans up only its own API/container. `kill -USR1 OWNER_PID` restarts that API without changing stored data. For another Azurite port, supply `--azurite-endpoint http://127.0.0.1:PORT/devstoreaccount1`. Application code never creates containers. The emulator key is Microsoft's public test key; never use cloud secrets in test commands/files.

Read the actual origin in terminal C:

```sh
DT3D_ORIGIN=$(python3 -c 'import json; print(json.load(open("/tmp/dt3d-local-api.json"))["origin"])')
curl --fail "$DT3D_ORIGIN/health/live"
curl --fail "$DT3D_ORIGIN/api/v1/highscores"
```

Liveness returns `Healthy` without storage access. Fresh GET returns ten cartoon starters scoring 100–1,000 points, revision `empty` (no persisted blob yet), UTC fetched time and `Cache-Control: no-store`. GET does not write storage; the next new submission persists starters with the player result. POST JSON has exactly `submissionId` (nonzero UUID), `displayName`, `score` (multiple of 100) and `levelReached` (positive integer). See executable examples in [shared fixtures](../../src/tests/fixtures/highscores.json). On fresh storage an explicit submission returns `ranked`; an identical ranked-ID replay preserves the row/revision; a changed payload for that ID is 409. A full-list equal cutoff returns `notQualified`. Unknown/invalid fields, malformed JSON, >4 KiB bodies, unsupported media and throttling return safe Problem Details. The iPhone never retries a failed POST, including after `Retry-After`.

## Backend checks

```sh
dotnet test src/backend.tests -c Release --filter 'Category!=StorageIntegration'
HighscoresTests__UseAzurite=true dotnet test src/backend.tests -c Release \
  --filter 'Category=StorageIntegration'
```

Set `HighscoresTests__AzuriteEndpoint` for another local port. Integration fixtures own separate containers, use independent instances and fail if explicitly requested without Azurite. Fault tests exercise the real Azure SDK pipeline. Required outcomes include valid Unicode/numeric boundaries, stable ties, conditional first creation/updates, five-write limit, one attempted upload after lost acknowledgement, corrupt/missing-container failure without overwrite and bounded cancellation. The 100-writer oracle includes known committed/unacknowledged writes and rejects a vacuous all-failed pass. It exercises stores directly so HTTP rate limiting cannot obscure CAS correctness; separate boundary tests use unchanged production buckets.

## iPhone UI, timeout and performance checks

List destinations with `xcodebuild -showdestinations -project src/DonkeyTrump3D.xcodeproj -scheme DonkeyTrump3D`. Select a specific OS/UDID because iPhone 13 exists on multiple runtimes.

Ordinary Debug fixtures use injected services and never contact the backend:

```sh
xcodebuild -project src/DonkeyTrump3D.xcodeproj -scheme DonkeyTrump3D \
  -destination 'platform=iOS Simulator,name=iPhone 13,OS=27.0' \
  -collect-test-diagnostics never -parallel-testing-enabled NO test
```

Without the integration environment variables below, the external redirect/stream/performance cases explicitly skip. Do not call that a full acceptance run. For all tests, start these two local HTTP fixtures in additional terminals:

```sh
python3 src/tests/support/highscore-http-fixture.py --state-file /tmp/dt3d-redirect.json
python3 src/tests/support/highscore-http-fixture.py --state-file /tmp/dt3d-stream.json --slow-stream
```

Use a **fresh helper-owned API/container for each full performance run**, since it publishes 100 monotonically increasing synthetic scores. It must not share the load driver's container. Then:

```sh
DT3D_REDIRECT=$(python3 -c 'import json; print(json.load(open("/tmp/dt3d-redirect.json"))["origin"])')
DT3D_STREAM=$(python3 -c 'import json; print(json.load(open("/tmp/dt3d-stream.json"))["origin"])')
TEST_RUNNER_DT3D_PERFORMANCE_ORIGIN="$DT3D_ORIGIN" \
TEST_RUNNER_DT3D_REDIRECT_TEST_ORIGIN="$DT3D_REDIRECT" \
TEST_RUNNER_DT3D_STREAM_TEST_ORIGIN="$DT3D_STREAM" \
xcodebuild -project src/DonkeyTrump3D.xcodeproj -scheme DonkeyTrump3D \
  -destination 'platform=iOS Simulator,name=iPhone 13,OS=27.0' \
  -collect-test-diagnostics never -parallel-testing-enabled NO test
```

`TEST_RUNNER_` forwards variables to the XCUITest runner. The tests launch the app with explicit `-highscoreIntegration -highscoreLocalOrigin ORIGIN`. That route accepts only loopback HTTP, refuses redirects and never falls back to a configured production URL. Release excludes fixtures, synthetic Game Over, integration overrides, counters and performance instrumentation. `HIGHSCORE_API_BASE_URL` is empty by default; configure a real HTTPS origin before release. Missing/invalid configuration leaves gameplay usable with unavailable highscores. Debug also accepts a bundled localhost URL; a physical iPhone's localhost is not the Mac.

Fixture names: `rank-1`, `rank-50`, `rank-100`, `below-cutoff`, `equal-cutoff`, `empty`, `duplicate-names`, `cutoff-race`, `validation-error`, `unavailable`, `hang`, `slow-stream`, `late-response`, `save-ack-lost`, `offline-first`, `refresh-fails`. Use `-highscoreFixture NAME -highscoreUITest`, adding `-highscoreCompletedRun` for Game Over. Synthetic personal best uses a separate preferences suite; request counters persist only for Debug accounting. The ordinary slow-stream fixture simulates an unresolved service; the real chunked HTTP fixture proves network progress does not extend the deadline.

The performance harness drives 100 paired baseline/normal-delayed-unavailable starts/restarts and 100 real GET/confirmed POST samples. Timing ends after mounted SwiftUI content has a window, nonzero layout and two display refreshes, not at HTTP completion. Raw JSON is attached to xcresult and stored as the test app's `Documents/highscore-performance.json`. A 7.8-second coordinator timer reserves 200 ms for presenting failure within the eight-second UI ceiling. Tests require every added start latency <100 ms, visible warm p95 <=2 s and a visible terminal hung/stream state <=8 s. Local loopback is the <=100 ms RTT environment; physical/network/Azure cold-start behavior is separate.

For two-installation persistence, keep the helper's container, restart its API with SIGUSR1, install the Debug app on two separate iPhone 13 simulator UDIDs and launch each with the same integration origin plus `-highscoreOpenOnLaunch`. Both show the real list and write `Documents/highscore-integration-snapshot.json`. Obtain each data directory with `xcrun simctl get_app_container UDID com.hyldenbrandt.donkeytrump3d data`; compare ordered rows and revision, then compare the fresh API GET. This file is emitted only in explicit Debug loopback integration mode. Record distinct app containers, API PIDs before/after and screenshots; do not equate two HTTP clients with two app installations. The reproducible helper is:

```sh
python3 src/tests/support/verify-two-installations.py --state-file /tmp/dt3d-local-api.json \
  --app /PATH/TO/Debug-iphonesimulator/DonkeyTrump3D.app \
  --devices FIRST_SIMULATOR_UDID SECOND_SIMULATOR_UDID --output-dir /tmp/dt3d-two-installations
```

It requires an already published result (for example from the first app's performance run), preserves the ranking during restart, installs on the two selected simulators and compares fresh app-rendered snapshots against the API. It never provisions cloud resources.

## Load and release checks

Run the [k6 driver](../../src/backend.tests/Performance/highscores-load.js) against a separate owned API using the [backend commands](../../src/backend/README.md#load-test): five minutes at 10 GET/s + 1 POST/s followed by a ten-submission burst, with default rate limits. Keep status/429/error counts and p95; HTTP results do not replace visible UI measurements.

[Release/recovery](../../docs/production-smoke-and-rollback.md) requires real subscription/region/hostname inputs, same-region private Hot/LRS storage, Container Apps Consumption 0–2 replicas, HTTPS ingress, container-scoped managed identity, bounded log retention and a cost alert. Verify the exact container image, live RBAC/CAS/restart behavior and cold-start limits in the real environment. Physical iPhone 13 VoiceOver, both landscapes, large text, keyboard, input and silent-switch/intro audio remain required release checks. Local success does not deploy Azure or publish an app.
