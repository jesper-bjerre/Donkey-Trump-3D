# Implementation Plan: Score, Attempt Timer and Level Pressure

**Branch**: `main` (actual Git branch) | **Date**: 2026-10-18 | **Spec**: [spec.md](spec.md)

**Input**: `specs/003-score-timer-difficulty/spec.md`. The setup script reports the resolved feature identity `003-score-timer-difficulty` as `BRANCH`; it did not create or switch a Git branch.

**Review policy**: The owner's [feature-specific exception](review-policy.md) prohibits/revokes Claude Code review, including implementation. The in-progress review was stopped; completion uses lead inspection and authorized document checks without a substitute external-review gate.

## Summary

Keep the existing native game/session/rendering ownership. Add retained level progress, a separately reset attempt budget, immutable reward events and pressure derived from unchanged level bases. Use integral active durations and a single injected monotonic timeline for render samples and input/lifecycle commands, retaining foreground elapsed time rather than the current 50 ms clipping. Resolve each attempt once and keep HUD, result, local best and optional publication on the same score.

Widen the existing app/server/storage score domain from multiples of 100 to multiples of 5 without changing values, routes, storage schema or the one all-time ranking. Apply an evidence-derived per-level minimum release interval, with explicit ballistic-flight exceptions to speed scaling. [Research](research.md) records decisions and source evidence; [data model](data-model.md), [gameplay contract](contracts/gameplay.md), [score-domain contract](contracts/highscore-score-domain.md) and [quickstart](quickstart.md) define the design and future acceptance.

This command ends after design. No application code, product requirements or checklist is changed; no tasks.md, build, application test or deployment is produced/run. Review-policy metadata and the scoped repository exception record the owner's later instruction. Lead source/document inspection and document checks are the acceptance evidence for this planning deliverable; no completed independent planning review is claimed.

## Technical Context

**Language/Version**: Swift 5 language mode, Xcode 27.0 (27A266a); C# / .NET 10, repository-root SDK pin 10.0.401 with latestPatch. Inspected local tools report those Xcode/SDK versions.

**Primary Dependencies**: Existing SceneKit, SwiftUI, UIKit, GameController, AVFoundation and Swift standard-library clocks; ASP.NET Core Minimal APIs, Azure.Storage.Blobs 12.29.2, Azure.Identity 1.21.0. No package, runtime, rendering-engine or hosting change.

**Storage**: In-memory active run; existing UserDefaults personal best/settings and existing installation credential storage. Existing private Blob `highscores/global-v1.json` with storage/moderation schema 1/2, stable identities, ETag writes and existing managed identity. No saved active-run system or rules-version field.

**Testing**: Existing Swift Testing app tests, XCTest UI tests and xUnit backend tests; isolated loopback Azurite 3.37.0 for real storage boundaries. Tests, smoke/contract scripts and gameplay checks are future work and require an explicit request under AGENTS.md. None executed in this planning workflow.

**Target Platform**: iOS 26+, landscape iPhone; reference acceptance device iPhone 13. Simulator evidence is distinct from physical-device acceptance. iPad release acceptance is outside this change. Existing .NET 10 service remains on its existing App Service/Blob topology.

**Project Type**: Native mobile app plus its existing optional highscore API.

**Performance Goals**: Preserve 120 Hz core physics and usable rendering/UI; normal 30/60/120 Hz input timelines must meet the spec's 0.02 s timing tolerance and exact reference rewards. Initial catch-up budget is 32 physics slices/render callback, retaining remaining duration for later callbacks; no I/O or unbounded catch-up loop on the render/UI thread. Bounded recovery and ordinary-rate frame pacing need future runtime evidence, not an invented measured result.

**Constraints**: Offline play/start/restart; bounded asynchronous online failure; no deferred uploads; integral duration precision; at most 20 rewarded lifetime IDs per level; one terminal commit per attempt; initial minimum throw interval from jump/spacing analysis; exact five-point score domain with unchanged remote ceiling. Preserve accessibility, settings, content, moderation, consent and private-data boundaries.

**Scale/Scope**: Three repeating authored layouts with existing bounded endless base-difficulty ramp, at most 12 active barrels, one current run and one all-time top 100. No new telemetry, accounts, services, boards, migration or release operation.

## Constitution Check

Current constitution: [v1.0.0, 2026-09-26](../../.specify/memory/constitution.md). The pre-research check assessed the proposed scope/ownership before selecting detailed mechanisms; the post-design check assesses the artifacts below. PASS means compliant design, not passing future runtime acceptance.

| Principle / gate | Before research | After design and evidence |
| --- | --- | --- |
| I. Native iPhone/offline/non-blocking UI | PASS: retain native local gameplay and optional existing API | PASS: core remains local; bounded slices; existing asynchronous highscore deadlines/navigation; landscape HUD and physical acceptance in quickstart |
| II. Simple components/explicit ownership | PASS: extend existing GameSession/GameSimulation/BarrelSystem | PASS: session owns level/attempt/rewards; engine owns clock adapter/input queue; immutable events/HUD cross to main actor; no parallel engine/framework |
| III. Shared data/bounded failure | PASS: no new persistence topology or retry policy | PASS: common score predicate covers stored reads/writes and snapshots; ETags/moderation/deadlines/unconfirmed/no-replay preserved; rollback must retain widened readability |
| IV. Original content/deliberate data use | PASS: no content or data-collection change | PASS: no new assets, publication fields, credentials, tracking or logs; existing consent and HTTPS/loopback boundaries retained |
| V. Evidence before claims | PASS: document-only acceptance now, future observable checks specified | PASS: quickstart maps every story scenario and all 19 intent cases to repeatable checks; fixtures and real API/storage and physical checks distinguished; no tests/builds claimed run |
| Platform/scope/governance | PASS: same iOS/Swift/backend baseline, English documentation | PASS: no unjustified exception; old score-granularity rule explicitly superseded for this feature and reconciled during implementation; no release/production mutation |

No constitution amendment or complexity exception is required. Future implementation must execute only checks authorized by its current prompt and disclose deliberately unrun tests. Physical-device evidence remains required before physical acceptance/release claims, not to finish a written plan.

## Project Structure

### Documentation (this feature)

```text
specs/003-score-timer-difficulty/
├── spec.md                         # Existing approved input; unchanged
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── gameplay.md
│   ├── highscore-score-domain.md
│   └── highscore-score.schema.json
├── checklists/requirements.md      # Existing specification checklist; unchanged
└── tasks.md                        # Future speckit-tasks output; not created now
```

Scoped review evidence is recorded separately and does not alter previously reviewed specification manifests.

### Source Code (repository root)

```text
src/DonkeyTrump3D/
├── Core/
│   ├── Rules.swift                 # Reward formulas and existing phases
│   ├── Simulation.swift            # Session/attempt arbitration and rewards
│   ├── GameplayProgress.swift      # Planned pure value state/reward data
│   ├── GameplayTimeline.swift      # Planned integral duration/timeline helper
│   ├── Barrels.swift               # Lifetime identity, immutable speed bases/schedule
│   ├── Level.swift                 # Existing DifficultyRamp; base inputs retained
│   └── Player.swift                # Existing movement retained; source for floor
├── App/GameEngine.swift            # Clock/input boundary, immutable effects/HUD
├── App/DonkeyTrump3DApp.swift       # Timestamped activity commands/main-actor UI
├── UI/{RootView,Copy}.swift         # Timer, actual rewards and timeout/help copy
└── Highscores/HighscoreModels.swift # Widen common validator; no transport redesign
src/DonkeyTrump3DTests/              # Existing core/clock/score/transition tests
src/DonkeyTrump3DUITests/            # Existing UI and real-loopback boundary tests
src/backend/Highscores/             # Shared validation and unchanged CAS/storage
src/backend.tests/                  # Score/ranking/document/endpoint/storage checks
src/tests/fixtures/highscores.json  # Cross-language score contract cases
```

**Structure Decision**: Add only small pure state/timeline helpers under existing Core; no new engine, package, service or store. File names above are intended implementation locations, not files created by this plan. Keep the existing rendering command queue and main-actor HUD publication boundary.

## Phase 0 — Research decisions

Resolved in [research.md](research.md): active timing/precision and bounded catch-up, deterministic terminal registration, reward-source inventory and pooling, physics/interval floor and mode exceptions, score-domain/storage compatibility, same-run persistence, historical comparability and rollback. No product clarification or unresolved technology choice remains. Runtime validation is future evidence, not unresolved research.

## Phase 1 — Design and integration order

1. Establish pure level/attempt/reward state and integral clock/terminal contracts. Preserve existing public GameSession flow and freeze completed results once.
2. Integrate clock/input/lifecycle accounting through the actual engine adapter, not only pure session calls. Keep presentation delta separate, bound catch-up work and retain unsimulated foreground intervals.
3. Give each barrel release a lifetime ID; derive pressure/speed from immutable bases; implement the initial interval floor and documented ballistic exception. Preserve existing maximum active count and first-release delay.
4. Present authoritative awarded values, attempt timer and correct life-loss reason via immutable HUD snapshots; update the existing completion banner and English help. Do not create a separate results screen.
5. Widen the common score predicate in iPhone, backend, active API schema and cross-language fixtures. Preserve aggregate schema, stored history, moderation, identities and storage-enforced writes. Reconcile active numeric statements in prior feature contracts/docs; retain dated test/review/release evidence unchanged.
6. Add observable acceptance work from quickstart, including real engine clock/lifecycle, exact storage round-trips and physical playability. Source inspection alone cannot close those gates. Generate dependency-ordered tasks with speckit-tasks after this design.

The backend/client changes are one feature dependency; local gameplay work can proceed independently. A later separately authorized rollout must verify actual distribution constraints, deploy a widened-reader backend before updated clients submit new scores, and use a widened-reader rollback artifact. No production operation is authorized by this plan.

## Complexity Tracking

No constitution violations or additional architectural layers. The interval floor, integral timeline and immutable event payloads address concrete correctness constraints in the current code; their reasons and alternatives are documented in research.
