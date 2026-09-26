# Donkey Trump Highscores API

One ASP.NET Core 10 Minimal API stores the all-time top 100 completed runs in one private Azure Block Blob. The native iPhone app loads asynchronously and never queues a failed submission. See the [HTTP contract](../../specs/001-global-highscores/contracts/highscores.openapi.yaml), [quickstart](../../specs/001-global-highscores/quickstart.md) and [executed validation](../../specs/001-global-highscores/validation.md).

## Build and local integration

Repository-root `global.json` selects SDK 10.0.401 with `latestPatch` roll-forward, including the sibling test project. Selected runtime: 10.0.12. Azure.Storage.Blobs 12.29.2 and Azure.Identity 1.21.0 are pinned. Run from repository root:

```sh
dotnet --version
dotnet build src/backend -c Release
dotnet test src/backend.tests -c Release --filter 'Category!=StorageIntegration'
```

Start an isolated Azurite 3.37.0, with a fresh data directory:

```sh
DT3D_AZURITE_DATA=$(mktemp -d /tmp/dt3d-azurite.XXXXXX)
npx --yes --package azurite@3.37.0 azurite-blob --blobHost 127.0.0.1 \
  --blobPort 10000 --location "$DT3D_AZURITE_DATA" --silent --disableTelemetry
```

In another terminal, start the integration helper. It creates one uniquely named private emulator container, builds the API and binds it to a free loopback port. The printed state file contains the origin and owned process IDs. Ctrl-C terminates its API and deletes only its own temporary container. SIGUSR1 restarts only its API, preserving the container for persistence checks.

```sh
python3 src/tests/support/local-highscores.py --state-file /tmp/dt3d-local-api.json
```

The helper expects the selected SDK at `~/.dotnet/dotnet`. The API itself can use any installation that resolves `global.json`. For the fixed development profile, explicitly create `highscores-local` in Azurite first, then `dotnet run --project src/backend --launch-profile http`; it binds `http://localhost:5281`. Application code never creates containers. No Azure credentials are needed locally; the emulator key is Microsoft's public development key.

```sh
HighscoresTests__UseAzurite=true dotnet test src/backend.tests -c Release \
  --filter 'Category=StorageIntegration'
```

Set `HighscoresTests__AzuriteEndpoint=http://127.0.0.1:PORT/devstoreaccount1` if using another port. Integration tests reject non-loopback storage, own unique containers and fail explicitly if their emulator prerequisite is absent.

## API and persistence

- `GET /health/live`: process liveness, independent of storage.
- `GET /api/v1/highscores`: complete ordered snapshot, revision and UTC timestamp; `Cache-Control: no-store`, no 304 path.
- `POST /api/v1/highscores`: `{ submissionId, displayName, score, levelReached }`, returning `ranked` with exact run ID/rank or `notQualified`, plus the complete snapshot from that decision.

Names are optional to publish, public after submission, normalized to NFC and restricted to 1–20 grapheme clusters / 256 UTF-8 bytes. The score is a client-reported multiple of 100 from 0 to 2,147,483,600. There is no login, secret embedded in the app or claim of cheat-proof verification. Public rows omit private sequence, final level and acceptance timestamp. Request bodies are limited to 4,096 bytes, including streaming bodies; stored documents to 256 KiB.

Sorting is score descending, then server-assigned successful-save sequence ascending. The full-list cutoff must be beaten. A conditional `If-Match`/`If-None-Match` single Put Blob protects simultaneous updates. Only recognized rejected writes are retried: at most five write attempts within a six-second total deadline, including reads and backoff. SDK retries are disabled; network timeout is two seconds. An ambiguous attempted save returns `submission_unconfirmed` and is never automatically uploaded again. The app also never retries, persists or defers an unsuccessful POST.

Identical same-ID submissions are deduplicated only while the result remains ranked. A changed canonical payload for a ranked ID is 409. This is not a historical receipt archive. Only `BlobNotFound` in an existing container means empty; missing container, invalid schema/data and authorization failures fail closed without repair or overwrite.

## Configuration and operations

All settings use the `Highscores` configuration section (`Highscores__...` in environment variables):

| Setting | Default / constraint |
|---|---|
| `BlobServiceUri` | Required HTTPS storage service URI in production; no SAS, user-info or loopback |
| `ContainerName` / `BlobName` | `highscores` / `global-v1.json`; provision private container outside the app |
| `ManagedIdentityClientId` | Optional user-assigned identity client ID; otherwise system-assigned identity |
| `UseAzurite` / `AzuriteEndpoint` | False in production; emulator only in Development/Test and only loopback `/devstoreaccount1` |
| `OperationTimeoutSeconds` / `NetworkTimeoutSeconds` | 6 / 2, configurable downward only |
| `MaxWriteAttempts` | 5 maximum |
| `RateLimits:GetCapacity` / `GetPerSecond` | 40 burst / 20 per second |
| `RateLimits:PostCapacity` / `PostPerSecond` | 10 burst / 2 per second |

Token buckets are per process/replica, with zero queue and integer `Retry-After`; they are modest load protection, not global abuse prevention. Logs contain only route, method, status, duration, CAS attempt and bounded error class. No player name, complete submission, IP or raw exception is logged by highscore code. Keep platform/ingress diagnostic settings consistent with this privacy boundary.

Build from repository root, with Docker available:

```sh
docker build -f src/backend/Dockerfile -t dt3d-highscores .
```

The Dockerfile-specific ignore file includes only the SDK pin and API sources/settings. Build verifies SDK 10.0.401; runtime image is ASP.NET 10.0.12, non-root `APP_UID`, port 8080. Docker is not a local emulator prerequisite. Actual container execution and live Azure managed-identity/RBAC validation remain environment-dependent checks.

Release target: same-region Container Apps Consumption (0–2 replicas), HTTPS ingress, a private Hot/LRS Blob container and container-scoped managed-identity Blob data access. Cold starts can exceed the app's bounded wait; gameplay remains available. Subscription, region, hostname, retention/cost-alert settings and deployment authorization must come from real release inputs. Nothing here provisions or deploys Azure.

## Load test

With a fresh helper-owned API/Azurite and the unchanged production limits, use its printed loopback origin:

```sh
HIGHSCORE_TEST_ORIGIN=http://127.0.0.1:PORT k6 run \
  --summary-export /tmp/dt3d-load-summary.json \
  --out json=/tmp/dt3d-load-samples.jsonl \
  src/backend.tests/Performance/highscores-load.js
```

Validated tooling: k6 2.2.0. The script rejects non-loopback origins. It drives 10 GET/s plus 1 POST/s for five minutes, then ten concurrent submissions; records status counts, failures and percentiles. HTTP timing is separate from visible iPhone timing. Local loopback supplies the <=100 ms network RTT environment. The 100-writer correctness suite remains separate and asserts exact ranking, known committed/unacknowledged writes, explicit contention failures and non-vacuous successful progress.
