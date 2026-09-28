# Implementation Plan: Global Top 100 Highscores

**Branch**: `main` (actual Git branch; unchanged) | **Date**: 2026-09-26 | **Spec**: [spec.md](spec.md)

**Feature Directory / Spec Kit context**: `specs/001-global-highscores` / `001-global-highscores`. The setup script's `BRANCH` field is the resolved feature context; `git branch --show-current` confirms `main`.

**Input**: Feature specification from `specs/001-global-highscores/spec.md`.

**Status**: Research, design and all [implementation tasks](tasks.md) are complete with [local validation](validation.md). Physical-device, container and live Azure release checks remain pending their actual environments. No deployment was performed.

## Summary

Add an optional shared top-100 ranking to the native iPhone game. Final-life Game Over captures an immutable result. A fresh asynchronous read determines whether to ask for a name; the server rechecks eligibility when saving. A saved result opens centred and highlighted; a non-qualifying result opens the bottom. Title browsing starts at the top. Starting and replaying remain independent of all network work.

Extend the single ASP.NET Core project with two Minimal API routes and one private JSON block blob. Conditional writes protect multiple instances; only confirmed conflicts are retried. Names are public, scores are client-reported, and no login or later submission queue is introduced. Failed/unknown publication retains the local personal best and ends that run's submission opportunity.

## Technical Context

**Language/Version**: C# 14 / .NET 10 (`net10.0`); Swift 5 language mode using Xcode 27. Implementation selects SDK 10.0.401/runtime 10.0.12 from Microsoft release metadata (2026-09-26).

**SDK selection**: T001 creates repository-root `global.json` (SDK 10.0.401, `latestPatch`, no previews) so root-level commands, `src/backend` and sibling `src/backend.tests` share one selected SDK/roll-forward policy. T001/T002 verify resolution from all three working directories; container build SDK verification is included in T043. The implementation validates this pin from each project working directory.

**Primary Dependencies**: ASP.NET Core Minimal APIs, built-in DI/options/Problem Details/rate limiting; Azure.Storage.Blobs 12.29.2 and Azure.Identity 1.21.0. Existing SwiftUI, SceneKit and Foundation/URLSession; no new iOS package dependency.

**Storage**: One private `highscores/global-v1.json` block blob on Standard GPv2 Hot/LRS. UserDefaults retains the existing personal best/settings. Ranking cache and completed-run submission state remain memory-only.

**Testing**: xUnit in one sibling test project, Microsoft.AspNetCore.Mvc.Testing 10.0.12, Azurite 3.37.0, existing Swift Testing plus coordinator/transport tests and a small XCUITest target. Explicit physical iPhone and Azure-managed-identity release checks.

**Target Platform**: Native landscape iPhone, iOS 26+, iPhone 13 baseline; Linux ASP.NET container targeting Azure Container Apps Consumption. Existing iPad target stays supported by the project but is not an expanded product requirement.

**Project Type**: Existing mobile app plus a small HTTP service.

**Performance Goals**: No network-dependent startup and <100 ms added start latency; warm-service p95 list/submission visibility <=2 seconds with <=100 ms RTT. Eight-second UI deadline; six-second server operation deadline; two-second storage network operation budget. Validate 10 GET/s + 1 POST/s for five minutes and a burst of ten submissions. Separate 100-concurrent-writer correctness test allows explicitly reported contention failures.

**Constraints**: No login, verified replay, background upload or later retry of a failed run. Max 100 entries, 4 KiB POST body, 256 KiB stored document. Five total conditional-write attempts; no SDK automatic retries. Public HTTPS; storage credentials absent from the app. Game simulation and audio remain independent of networking.

**Scale/Scope**: One all-time global ranking of runs, multiple entries per person/name. Initial process-wide GET bucket 40/refill 20 per second; POST bucket 10/refill 2 per second; zero queue. Hosting 0–2 replicas. These are engineering starting limits, not global abuse protection, a throughput guarantee or a monthly cost promise.

## Constitution Check

*Reconciled before task generation on 2026-09-26 against [constitution v1.0.0](../../.specify/memory/constitution.md), ratified on that date. The original research/design preceded adoption; this review evaluates the completed design without claiming an earlier review against rules that did not yet exist.*

| Adopted principle | Current design review | Required implementation evidence in [tasks.md](tasks.md) |
|---|---|---|
| I. Native iPhone Play Comes First | Pass at design level: gameplay independent of networking, bounded async requests, generation guards, landscape/accessibility layout | T017, T022, T025, T033–T038, T050; physical-device checks remain release gates |
| II. Simple Components and Explicit Ownership | Pass at design level: framework-independent run snapshot, main-actor coordinator, one Minimal API and sibling tests; server owns ranking | T002, T005–T010, T017–T025 |
| III. Correct Shared Data and Bounded Failures | Pass at design level: conditional Blob writes, reread/recompute, bounded conflict retries, unknown-write outcome, preserved local best and no deferred submission | T019, T022, T039–T041, T044–T049 |
| IV. Original Content and Deliberate Data Use | Pass at design level: original assets retained, explicit public-name consent, minimal data/logging, HTTPS and container-scoped managed identity | T009, T023, T041–T042, T052–T054 |
| V. Evidence Before Completion Claims | Pass at design level: measurable story tests, deterministic fault fixtures, separate simulator/emulator and real-device/Azure evidence | Increment checkpoints T026/T031/T038/T044/T049 and final acceptance T050–T054 |

**Result:** No design-level constitutional exception is required. Implementation and release evidence remain pending; this gate does not certify code, accessibility, deployment or performance. The task list carries the corresponding verification work forward.

## Project Structure

### Documentation (this feature)

```text
specs/001-global-highscores/
├── spec.md
├── technical-proposal.md       # Earlier proposal; research/contracts refine it
├── checklists/requirements.md
├── plan.md                     # This implementation plan
├── research.md                 # Decisions, alternatives and primary sources
├── data-model.md               # Persisted/public/local records and invariants
├── contracts/
│   ├── highscores.openapi.yaml # Public HTTP contract
│   └── ios-flow.md             # Presentation, cancellation and failure contract
├── quickstart.md               # Local and release validation guide
└── tasks.md                    # Dependency-ordered implementation and validation work
```

`tasks.md` contains 54 unchecked tasks across setup, foundation, the five P1 user stories and final acceptance. T026 validates only the initial publication slice. The internal MVP requires T031 as well, including US1's cutoff-race scenario; full US1 acceptance also requires T054's two-installation check. Generating the task list does not implement the feature.

### Source Code (repository root)

The following tree distinguishes the existing project roots from planned additions; it is not a claim that these files already exist.

```text
src/
├── backend/                              # Existing service project
│   ├── DonkeyTrump.Highscores.Api.csproj
│   ├── Program.cs
│   ├── Highscores/                        # Planned
│   │   ├── HighscoreEndpoints.cs
│   │   ├── HighscoreContracts.cs
│   │   ├── HighscoreRanking.cs
│   │   ├── BlobHighscoreStore.cs
│   │   └── HighscoreOptions.cs
│   ├── Dockerfile                        # Planned deployment packaging
│   └── .dockerignore
├── backend.tests/                        # Planned sibling, not nested in web project
│   └── DonkeyTrump.Highscores.Api.Tests.csproj
├── DonkeyTrump3D/                        # Existing synchronized source group
│   ├── Core/CompletedRun.swift           # Planned; Simulation.swift captures it
│   ├── App/                             # Extend GameEngine and GameModel
│   ├── Highscores/                      # Planned service, DTOs, coordinator
│   └── UI/                              # Add name/list views; extend RootView/Copy
├── DonkeyTrump3DTests/                   # Extend existing Swift Testing target
├── DonkeyTrump3DUITests/                 # Planned XCUITest target
└── DonkeyTrump3D.xcodeproj/              # Register UI target/scheme and URL configuration
```

**Structure Decision**: Keep ranking logic and Blob persistence inside one deployable service. A narrow injectable store interface supports API tests; there is no generic repository layer. Existing synchronized Xcode groups include new source/test files automatically. The new UI-test target must be added to the project and shared scheme explicitly.

## Phase 0 — Research outcome

[research.md](research.md) resolves storage race handling, uncertain write acknowledgement, numeric/name validation, rate limits, deployment tradeoffs, run identity, URLSession deadlines, accessibility and test tooling. No implementation question remains unresolved. Configuration values such as subscription, region, resource names and final HTTPS hostname are deployment inputs, not architecture gaps.

## Phase 1 — Design and integration

### Backend boundary

- `GET /api/v1/highscores` returns a complete bounded snapshot. A missing blob in an existing container returns ten deterministic cartoon starters (owner update 2026-09-27); valid lists with fewer than ten entries are filled to ten while preserving players. GET remains read-only; the next new score persists starters in the normal conditional write. Other storage problems return errors.
- `POST /api/v1/highscores` validates and canonicalizes input, detects an existing run, then merges/rechecks against fresh storage with conditional writes. Rank and tie order are server-owned. No caller can edit an existing ranked run.
- Return the successfully written candidate plus its write ETag, not a later read. `notQualified` is a normal 200 outcome. Operational failures use stable Problem Details codes, including `submission_unconfirmed` when a write may have committed.
- Configure six-second cancellation/deadline across reads, credentials, backoff and writes; SDK retries are disabled. A timed-out Blob GET may retry once while the original operation token remains active; backoff and retry share that deadline. Recognized CAS write conflicts alone receive up to five conditional-write attempts. Serialization must fit one small conditional Put Blob.
- Keep `/health/live` dependency-free. Storage errors affect the optional API, not liveness or existing scores. Production container creation is a deployment operation, never request-time repair.
- Bind/validate storage, limits and timeouts at startup. Proposed configuration keys: `Highscores:UseAzurite`, `Highscores:BlobServiceUri`, `Highscores:ContainerName`, `Highscores:BlobName`, `Highscores:ManagedIdentityClientId` (optional for user-assigned identity), and `Highscores:RateLimits:*`. Azurite mode is Development/Test only; production configuration requires a valid HTTPS storage URI.

The complete request/response and error contract is [contracts/highscores.openapi.yaml](contracts/highscores.openapi.yaml); record invariants and the CAS procedure are in [data-model.md](data-model.md).

### iOS boundary

- `GameSession` creates run IDs and freezes completion once. `GameEngine` carries completion in immutable HUD snapshots dispatched to the main queue. No network calls occur in core/render code.
- `GameModel` owns an injectable, main-actor `HighscoreCoordinator`; isolate its UI mutations explicitly and verify existing UIKit/SceneKit callback compatibility when adding actor annotations.
- Start/restart/title actions synchronously invalidate requests before enqueueing engine commands. Observed HUD phase/run changes cover controller paths. Old-generation callbacks are discarded even if cancellation is ignored.
- Name entry is cancellable and explicitly publishes; validation failures permit name correction while still in that flow. Transport/timeout/throttling/server failures retire submission for the run. Read-only refresh never reopens eligibility. Keyboard dismissal precedes scrolling.
- An eight-second independent timer makes loading terminal and cancels the foreground ephemeral session task. No reconnect observer, disk queue, background upload or automatic client resend is added.
- Configure `HighscoreAPIBaseURL` in build/Info.plist settings, require HTTPS for Release, and expose Debug-only service/URL fixtures. Missing URL is an unavailable optional feature. Keep production ATS intact; localhost development access must be Debug-only and verified on the chosen simulator.
- Keep normal deterministic UI fixtures on injected services. A separate explicit Debug integration mode may issue automated GET/POST requests only to a test-run-owned loopback API using isolated Azurite; reject other origins and redirects leaving the selected origin, and never fall back to a production URL. T050/T054 use this mode for warm-service visibility and two-installation checks. Production publication by autopilot/demo/test modes stays disabled, and the integration override is absent from Release.
- Extend English UI/privacy copy and use adaptive landscape layout and semantic text. Keep Play Again/Return to Title reachable outside loading/list content.

The complete UI state and cancellation contract is [contracts/ios-flow.md](contracts/ios-flow.md).

### Validation and release evidence

| Requirement group | Planned evidence |
|---|---|
| FR-001–FR-004, FR-009, FR-016; SC-003/006 | Ranking tests, strict validation, two-instance Azurite CAS tests, initial creation, stable ties, restarts, known conflicts and ambiguous committed writes |
| FR-005–FR-011; SC-002 | Coordinator and UI fixtures for empty/99/100 rows, cutoff ties, cancellation, repeated names, ranks 1/50/100 and displacement during name entry |
| FR-012–FR-015, FR-018; SC-001/004 | Hung/late service fixtures, independent deadline tests, 100 startup/restart measurements and warm-service load profile |
| FR-017; SC-005 | Offline, lost acknowledgement, scene backgrounding, reconnect/refresh/relaunch; assert no second or deferred POST |
| FR-019–FR-020 | Landscape iPhone 13 UI checks, Dynamic Type, physical VoiceOver/keyboard checks and accurate publication/privacy copy |

Use deterministic fault injection for storage failures and URLProtocol/fake-service controls for iOS. An isolated correctness fixture raises rate limits; separately exercise real throttling. The concurrency oracle includes all acknowledged writes and any confirmed committed-but-unacknowledged writes, while recording explicit rejected/unconfirmed outcomes. Never satisfy the test merely by rejecting every writer: require successful progress in the uncontended baseline and both writers in a deterministic two-writer conflict case.

The release guide must record package/runtime versions, warm/cold load results, contention failures, managed-identity permissions and physical-device outcomes. Deploying actual Azure resources and distribution through TestFlight/App Store are separate operations; this plan only defines their validation prerequisites. [quickstart.md](quickstart.md) contains the runnable guide for implementation.

Planning validation on 2026-09-26 passed: OpenAPI 3.1 structural validation, 20 valid/invalid schema examples, local documentation links and syntax checks of seven shell examples. An independent backend review found no unresolved correctness contradiction. These checks validate the design artifacts; they do not establish implemented API behaviour, Swift UI correctness or end-to-end performance.

## Complexity Tracking

No gate violations need exceptions. Revisit a single-blob store only if observed contention, historical queries or additional ranking dimensions outgrow the stated scope. Neither a database migration nor globally coordinated rate limiting is required for the initial implementation.
