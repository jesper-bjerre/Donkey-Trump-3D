# App Store preparation — execution record

Started 2026-09-27. Status: IN PROGRESS; not a distribution candidate or ready draft.
Base: `94dc44d89929137c4ff02649da58ba8fefa29f1e`; worktree clean before execution.
Feature: `specs/002-app-store-release`; all 16 requirements checklist items passed.

## Identity and tools

- Source settings: version 1.0/build 1, bundle `com.hyldenbrandt.donkeytrump3d`, team `QHL89A7A8J`, iOS 26.0+, families 1,2. These are source values, not verified available Connect identifiers. Do not narrow family until account history is read.
- .NET SDK 10.0.401; Xcode 27.0 (27A266a); existing dependency/runtime pins retained.
- One local Apple Development identity found; distribution signing/account access remains unverified.
- Booted baseline: iPhone 13 simulator, iOS 27, `31C13DEB-E27B-46F9-8598-BB36342D54A6`.
- Available iOS 26.5 iPhone 13: `51A403FE-C882-4147-B7F2-8F64B78AD7EC`; larger iPhone 17 Pro Max: `C47491EF-94B7-435E-B7C7-6660DCA23451`; iPad 13-inch Pro M5: `39826F53-AC15-4DBC-AAD2-B3776EC3387B`.
- Physical owner's iPhone 13 was offline during initial discovery. On 2026-09-27 the owner stated that he is disconnecting it and will perform the physical test himself later. T042 is owner-deferred; no physical check has passed. Device-dependent parts of T043 await that later session; independent preparation continues without requiring reconnection.
- Earlier cover/music/backend review records are historical baselines, not this release's acceptance.

## Durable evidence protocol

Create the version/build package only after Connect identity/history is verified. For each operation record UTC time, target, source/configuration identity, observed before/after state, actual command/result, artifact SHA-256 and next safe action. Keep private contact, report snapshots, credentials, device logs and signing artifacts outside Git. Reference private evidence without copying its contents.

Candidate identity must include candidateId, source revision + dirty SHA manifest, dependencies/configuration fingerprints, version/build/bundle/team, archive SHA, Connect app/build IDs, backend artifact SHA and actual device/OS. None has been frozen for distribution yet.

Phases: `sourceReady → automatedChecked → uploaded/processed → physicalValidated → draftValidated`.
Current state: source changes NOT COMPLETE; later phases NOT RUN. Owner-submitted, Apple-approved and publicly-released are separate states: none observed or performed.

After interruption, read remote state first. An upload/save timeout is ambiguous; never blindly recreate an app/build/draft. A source/configuration/build change invalidates affected tests, archive, physical checks and screenshots; content changes invalidate declarations and media checks. Saved/processed/draft status requires fresh remote reads.

## Evidence and next action

- [Account discovery](account-discovery.md): supported Chrome runtime blocked.
- [Azure discovery](azure-discovery.md): read-only inventory and MI-route prerequisite.
- [Owner inputs](owner-inputs.md): pending genuine facts.
- [Baseline checks](baseline-checks.md): current execution results.
- [Acceptance matrix](acceptance-matrix.md): each requirement and scenario remains individually gated.
- [Rights assessment](rights-assessment.md): distribution blocked pending provenance assessment inputs.

Continue independent local tests/implementation. No cloud migration, signing upload, Connect mutation, submission or publication has been performed in this implementation run.

## Deployed read repair — 2026-09-28

The owner reported that the installed PROD app could not fetch highscores. A separate
reviewed hotfix added the current app's v2 GET route to the stable backend and was
deployed through DEV to PROD (source75cd632). Both public GET versions and the
actual Swift decoder/network client passed live read checks. See
[repair evidence](../../reviews/prod-highscore-read-2026-09-28.md).
The larger moderation implementation, v2 writes/reports and schema2 migration in
this worktree remain unfinished and were NOT included in that deployment. The
owner's physical device tests are still deferred. This hotfix does not pass the
App Store preparation gates.

## Current owner direction — 2026-09-28

The owner approved DEV/PROD deployment and removed the need for a second API version
because only the owner tests this unreleased app. Current work uses `/api/v1` for
reads, publication and reporting, with no legacy-writer retirement. Earlier v2
read-hotfix evidence remains historical, not the target contract for this update.
