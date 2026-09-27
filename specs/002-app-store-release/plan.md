# Implementation Plan: App Store Release Preparation

**Branch:** `main` (existing Git branch; feature pointer `002-app-store-release`)
**Date:** 2026-09-27 | **Spec:** [spec.md](spec.md)
**Input:** `specs/002-app-store-release/spec.md`
**Status:** Phase 0 research and Phase 1 design. No implementation/deployment/store
submission is performed by this plan. Task generation is the next command.

## Summary

Prepare a complete iPhone-only, free English App Store version with truthful artwork,
a tested signed candidate, working privacy/support and public-name safeguards. Save
and validate it in the owner's Chrome App Store Connect session, leaving an unsent
draft and manual release. The owner submits to Apple and releases after approval.

Reuse the native 3D app, existing .NET API, DEV/PROD pipelines and shared Azure plans.
Extend the single private Blob with conditional moderation transactions, installation
credentials, reports and operator CLI mode. Preserve startup/progress/music, clear
name entry, minimum-ten/top-100 rankings and offline play already implemented under
separate authorizations. Historical evidence is a baseline, not release acceptance.

## Technical Context

**Language/Version:** Swift 5 language mode, Xcode 27/iOS 26+; C#/.NET 10 (SDK10.0.401).
**Primary Dependencies:** SwiftUI, SceneKit, AVFoundation, URLSession, Security random
bytes/file protection; ASP.NET Core built-ins, Azure.Storage.Blobs12.29.2,
Azure.Identity1.21.0; existing GitHub Actions OIDC deployment tooling. No new hosted
service, database, account system, tracking SDK, frontend framework or mail provider.
**Storage:** device local best/settings and protected installation secret/receipt IDs;
one private schema-versioned Blob aggregate with ETags (Azure version history disabled); static HTML bundled with API;
local versioned release artifacts and private owner evidence where sensitive.
**Testing:** Swift Testing, XCTest/XCUITest, xUnit/Azurite, Python pipeline/asset/contract
checks, physical iPhone13 via internal TestFlight, labelled iPad simulator compatibility.
**Target Platform:** native landscape iPhone iOS26+, existing Linux App Services/Blob,
owner's Chrome Connect session. No native iPad/Mac/Vision Pro release scope.
**Project Type:** native mobile app + small API + documentation/static support pages.
**Performance Goals:** no backend/audio startup gate; preserve fixed120Hz simulation and up-to120fps requested presentation, profile actual
iPhone13 pacing, and retain <100ms added latency across 100 start/restart attempts; app network deadlines <=8s, backend
operation<=6s/network<=2s, <=5 conditional attempts, no SDK/application upload retries.
**Constraints:** DKK100/month including VAT incremental operation; keep shared plan
tier/scale and unrelated apps; no login, no deferred uploads, no agent Apple submission.
**Scale/Scope:** top100, minimum10 successful-list entries, bounded 1MiB moderation
aggregate and caps in the data model; small-launch costing baseline 1,000 GET/100
POST per day across environments, refreshed for new report traffic and diagnostics.

## Constitution Check

Constitution v1.0.0. Pre-research gate: PASS at design boundary; no exception needed.
Existing implementation gaps are explicit work, not claims of current compliance.

| Principle | Before research | Post-design evidence/gate |
|---|---|---|
| I — Native iPhone/offline | Preserve app/sound/accessibility and optional async backend. | iOS contract keeps loading/play independent; report/score deadlines and navigation; physical both-landscape/VoiceOver/audio checks gate readiness. |
| II — Simple ownership | Existing UI/main actor, engine/render loop and API/store boundaries. | Protected credential and report coordinator; one API/aggregate; same executable operator mode, no admin web service. |
| III — Data integrity | Existing ETag design; removal/block requires atomic extension. | Single conditional mutation rechecks bans/tombstones; bounded failure, no score replay; migration and schema-aware rollback preserve guards. |
| IV — Content/data | Originality and truthful privacy remain gates; owner removed dialog reminder only. | Existing help explanation retained/tested, real privacy link, provenance/rights and actual data inventory before declarations; credentials private; operator Blob access via app MI inside App Service, human Entra only for control-plane SSH. |
| V — Evidence | Simulator and dated deployment records are baselines only. | Exact processed build physical checks, media/readback identity, source/check records and independent review before completion. |

Post-design gate: PASS for the planned approach. Runtime/store gates remain UNEXECUTED;
no physical acceptance, signed archive, account declaration or Connect state is asserted.
Any discovered constitutional or unresolved material product conflict blocks dependent
implementation until a compliant design or explicit amendment exists. No waiver here.

## Project Structure

```text
specs/002-app-store-release/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── moderation-api.md
│   ├── ios-release-flow.md
│   └── store-release.md
└── tasks.md                  # future speckit-tasks output, not created here

src/DonkeyTrump3D/
├── App/                     # Release launch flags, existing lifecycle
├── Highscores/              # v2 credential/report service and coordinator
├── UI/                      # report/status/support/privacy flows
└── Resources/               # privacy manifest, existing cover/music/icon
src/DonkeyTrump3DTests/       # existing Swift targets, new credential/report cases
src/DonkeyTrump3DUITests/     # existing UI targets, report/accessibility/regressions
src/Configuration/           # existing environment configs + public page URLs
src/backend/
├── Highscores/              # schema2 ranking/store/validation
├── Moderation/              # planned policy, report/domain and operator command mode
└── wwwroot/                 # planned accessible support/privacy HTML
src/backend.tests/           # schema/race/migration/operator/API tests
src/scripts/                 # existing release tools + planned local smoke/media checks
infra/                       # existing resource inventory/budget, no new App Service Plan
.github/workflows/           # extend existing backend CI/DEV/PROD artifact promotion
docs/releases/app-store/    # future release packages, non-secret evidence only
```

**Structure decision:** extend existing targets; a DEV-only capture container and isolated
route group reuse the DEV service to isolate synthetic media data without touching real rows; operator CLI is a mode of the same
backend executable sharing its validated mutation code. No additional deployable API
or operator authentication endpoint. Sensitive owner documents stay outside Git.

## Phase 0 — Research decisions

[research.md](research.md) records decisions/rationale/alternatives, current official
Apple/Microsoft references, code gaps, bounded storage/retention and unknown account
facts as execution gates. Required skill research agents examined backend moderation
and iOS/Apple requirements independently; their findings were consolidated by lead.
No unresolved design clarification remains. Supported Chrome bootstrap failed before
browser selection; actual account state was not read. This is an execution prerequisite,
not a missing product choice or permission to fabricate facts.

## Phase 1 — Design and dependency order

1. **Inventory and private input register:** actual account/app/history/signing,
   rights/contact/trader facts, physical device, Azure inventory/cost baseline. Resolve
   missing owner facts together after discovery. Probe DEV SSH and harmless aggregate
   metadata read via app MI early; a missing supported MI context blocks operator-dependent
   work, never permits token/environment extraction or human Blob credential fallback.
   Independent code/copy work continues.
2. **Backend safety foundation:** schema2, canonical credential ownership, filtering,
   ETag-atomic reports/removal/block, bounded capacities/retention and shared operator
   mode. Add migrations and explicit v1 writer retirement; establish rollback floor.
3. **iOS and public pages:** v2 publication/report/status flows, protected credential,
   privacy/support links and pages; release argument/fixture isolation, manifest,
   iPhone-only configuration after history check. Preserve reviewed UX/audio behavior.
4. **Integration and operator rehearsal:** deterministic local tests, DEV migration
   and concurrency/lost-ack cases, real owner daily report workflow. Extend existing
   pipelines/manifest/schema checks, then authorized PROD promotion with neighboring
   app health/cost/capacity evidence. Never reset a live ranking for a test.
5. **Release package:** truthful editable listing/media and rights/declaration matrix;
   signed archive/normal upload/internal TestFlight, exact-build physical checks,
   iPad compatibility smoke. Refresh affected package parts when candidate changes.
6. **Connect completion:** save/read back fields/images/build, eligible free territories,
   manual release, validated unsent draft. Stop before owner's submission/release.
   Independent review applies after completed scoped implementation/checks.

Detailed decisions/contracts: [data model](data-model.md),
[moderation/API/migration](contracts/moderation-api.md),
[iOS flows](contracts/ios-release-flow.md), [store/handoff](contracts/store-release.md).
Validation instructions: [quickstart.md](quickstart.md).

## Requirement-to-design coverage

| Spec requirements | Design / acceptance owner |
|---|---|
| FR001,018–023 | Store contract identity, Chrome readback, unsent state/resumption and independent review. |
| FR002,011,016 | iOS release boundaries, signing/internal TestFlight identity, physical/iPad compatibility matrix. |
| FR003–006 | Store copy/media provenance, native captures and rights/territory research. |
| FR007–010,017 | Public pages/data inventory, genuine contact, truthful declarations and eligible free territories. |
| FR012–013 | Shared-resource/cost gate, existing CI/DEV/PROD artifacts, live/race/failure checks. |
| FR014–015 | Credential, filter/report/operator, bounded aggregate/retention/migration contract. |
| FR024–026 | iOS contract startup/music/name-entry/min-ten regression gates; retain earlier accepted choices. |
| SC001–010 | Quickstart scenarios plus per-candidate store/iOS/operator evidence; not satisfied by plan existence. |

## Risks and execution gates

- Browser connection currently fails during supported bootstrap; retry without session
  extraction or changing browsers. Missing organization/history/role/agreements/signing
  blocks related external actions. No repeated permission for already authorized work.
- Real rights/trader/contact facts and moderation privacy answers need actual evidence;
  do not silently rename/disable advertised features or claim legal clearance.
- Single-Blob growth is bounded with moderation reserve; capacity exhaustion is an
  honest service limitation needing operator action, never guard eviction/data reset.
- Anonymous secrets are not hardware attestation. Legacy rows cannot gain retrospective
  attribution; credential-free writes retire before new release. Describe both limits.
- Schema2 requires migration-aware recovery. Old schema1 builds/data snapshots cannot
  safely be restored after moderation starts. Quiesce only this game's API.
- Shared plan/cost evidence must be refreshed; no extra tier/scale/budget without the
  already specified separate owner decision. Public report storage/rate controls are
  not guarantees against malicious cost or all offensive names.
- Physical iPhone13 and genuine owner moderation participation cannot be fabricated.
  Missing gates block readiness but not remaining independent preparation.

## Complexity Tracking

No constitution exception. The extra protocol version and operator mode are justified
by installation blocking, atomic removal and anonymous owner-operated reports. Their
simpler alternatives (credential-free writes or raw ad-hoc Blob editing) cannot retain
these guarantees. Future task decomposition belongs to `speckit-tasks`.
