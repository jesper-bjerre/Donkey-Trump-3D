# Donkey Trump 3D Constitution

## Core Principles

### I. Native iPhone Play Comes First

The product MUST remain a native 3D arcade game with iPhone as its primary acceptance target.
Starting, restarting and playing installed game content MUST work without a backend connection.
Optional online features MUST load asynchronously, have finite user-visible deadlines, and leave
navigation usable while loading or failing. A late response MUST NOT interrupt a newer game or
change a different run's result. Network or storage work MUST NOT block the render loop or UI thread.

New or changed player-facing screens MUST work in landscape with safe areas, readable text and
reachable actions. Applicable menu/list controls MUST support VoiceOver and larger text. Changes
MUST preserve the existing Reduce Motion, sound and haptics settings unless the feature explicitly
changes their behaviour. These rules keep short play sessions usable on the baseline iPhone.

### II. Simple Components and Explicit Ownership

Gameplay rules, scoring, collision logic and run transitions MUST remain testable independently of
SceneKit, SwiftUI and networking. Rendering presents simulation state; UI presents player actions
and results. Cross-thread state transfers MUST use snapshots or an explicit synchronization boundary;
new UI state MUST have a defined main-thread/main-actor owner.

The backend default is one small ASP.NET Core service in `src/backend`, using built-in platform
facilities and a separate test project when needed. Additional services, stores, frameworks or
architectural layers MUST have a feature-level justification explaining the requirement they solve
and why the existing structure is insufficient. Package versions and runtime baselines belong in
project files and feature plans, rather than being frozen permanently in this constitution.

Each state has a clear owner: the app owns local gameplay and its personal best; the backend owns
validation, ordering and persistence of shared rankings. Accepting a client-reported score MUST NOT
be described as proof of genuine gameplay. Simplicity does not remove these ownership boundaries.

### III. Correct Shared Data and Bounded Failures

Shared read-modify-write state MUST use storage-enforced concurrency control that works across
multiple service instances. An in-process lock alone is insufficient. A conflict retry MUST read
current state and recompute the result; unconditional overwrite MUST NOT be a fallback. Duplicate
submissions MUST use a stable result identity, with the supported deduplication scope documented.

Remote operations MUST define deadlines, cancellation behaviour, retry conditions and finite retry
limits. A potentially committed write with a lost acknowledgement MUST be reported as unconfirmed;
retry behaviour MUST NOT imply that a failed response proves no save occurred. Missing, corrupt or
unavailable storage MUST NOT silently become an empty replacement. Tests MUST cover these distinctions
when shared persistence is introduced or changed.

Local personal-best data MUST survive remote failures. Cached results MUST be identifiable as stale
and MUST NOT establish fresh qualification or confirmed publication. For the agreed highscore v1,
a failed qualification or submission MUST NOT create an automatic, deferred or next-launch upload.

### IV. Original Content and Deliberate Data Use

Game models, textures, animation and audio MUST remain original project material or have documented
permission compatible with their use. Copied Nintendo/Donkey Kong assets MUST NOT replace the
project's procedural characters or synthesized soundtrack. References to the original game's feel
are design inspiration, not authorization to copy its assets. Player copy MUST preserve the original
parody/no-affiliation description.

Public name/score publication MUST require an explicit player action and explain what is public.
Data collection and logs MUST be limited to the feature's documented purpose; diagnostics MUST NOT
record secrets, full submission bodies or player names. Storage credentials MUST stay out of the
app, repository and logs. Public service traffic MUST use HTTPS; local development exceptions MUST
remain isolated from release configuration. Azure-hosted storage access MUST use managed identity
with permissions scoped to the required data resources.

Privacy/help copy MUST match implemented data flows. A new account, analytics, advertising or
tracking capability MUST be an explicit product-scope change, never an incidental dependency.

### V. Evidence Before Completion Claims

Changed gameplay rules, persistence, concurrency, retry and cancellation behaviour MUST have
repeatable checks for their observable outcomes and relevant failure cases. Use deterministic
inputs, clocks or service/storage substitutes where timing and randomness would hide defects.
Cross-component contracts MUST be checked at their boundaries; a test that only mirrors an
implementation detail is not sufficient evidence for the player's requirement.

Verification MUST be proportional to the change. Run the affected build/tests and relevant existing
regression checks; documentation-only edits need document validation, not an unrelated full build.
Device-dependent claims, including physical silent-switch behaviour, touch usability and sustained
performance, MUST be backed by checks on the relevant physical device before release acceptance.
A simulator pass MUST NOT be presented as physical-device evidence.

Reports and documentation MUST distinguish planned, implemented, tested and deployed behaviour,
identify what was actually checked, and record material limitations. Test instructions or a scaffold
MUST NOT be reported as a passing feature. Historical results MUST retain their date/context rather
than silently becoming evidence for a newer build.

## Product and Technology Boundaries

- The current app baseline is Swift, SceneKit and SwiftUI, iOS 26+, landscape, with iPhone 13 as the
  reference device for acceptance. iPad is enabled in the project but needs its own evidence before
  iPad release-readiness claims. A platform or rendering-engine change requires an explicit design
  decision and appropriate regression coverage.
- Game content remains bundled for offline play. The imported 2D/browser project is a reference,
  not the deployment architecture. Player-facing copy and repository product documentation remain
  in English unless localization is explicitly scoped.
- In-game Sound controls game audio. With Sound enabled and audible output volume, physical silent
  mode MUST NOT suppress it; the in-game mute setting MUST silence active game audio. Intro skip or
  exit MUST stop intro audio without playing queued effects afterward.
- The agreed online extension is a global all-time top 100 of completed runs, without login or
  server-verified replays. Failed publication leaves the local personal best; no offline submission
  queue is in scope. Exact tie, name, scrolling, timeout and endpoint rules belong in its feature spec
  and contracts, not as duplicated constants here.
- The initial backend design uses ASP.NET Core Minimal APIs and private Azure Blob Storage with
  conditional writes. Hosting and storage choices MUST document expected traffic, contention and
  running-cost tradeoffs. Use supported stable platform releases and serviced production runtimes;
  adding infrastructure requires a concrete feature or measured operational need.
- Accounts, online multiplayer, cloud-saved runs, purchases, advertising and extra languages are not
  implicitly authorized by this baseline. They require their own explicit feature scope. Release
  channel, cloud resource identifiers and organizational ownership MUST use real supplied values.

## Development Workflow and Quality Gates

For features managed through Spec Kit, the specification MUST state player outcomes, failure cases,
measurable acceptance criteria and explicit scope decisions. Clarification MUST address meaningful
unknowns without asking the user to reconfirm decisions already made. The plan MUST record a
Constitution Check against the current version before detailed design and recheck it after design.

The task list MUST map buildable requirements to concrete implementation and validation work with
correct dependency order. Cross-artifact analysis requires a complete task list; missing artifacts
MUST be reported rather than invented. A principle conflict MUST be resolved before implementation
through compliant design or an explicit constitution amendment, not by silently weakening the rule.

Implementation completion MUST include the required checks for the changed scope and documentation
updates describing actual behaviour. Release readiness additionally requires the selected simulator
and physical-device evidence, valid configuration/credentials outside source control, and a recorded
release/recovery procedure for the real target. A local build, commit or push does not itself establish
that an app or service was published.

The existing [product specification](../../docs/prd_spec.md),
[architecture](../../docs/architecture_options.md), [backlog](../../docs/backlog.md) and
[release runbook](../../docs/production-smoke-and-rollback.md) provide the baseline. Feature-specific
requirements and contracts extend it explicitly. Existing work and unrelated user changes MUST be
preserved when applying a scoped change.

## Governance

This is the first adopted project constitution, version 1.0.0, established on 2026-09-26 at the user's
request. It governs cross-cutting project decisions; feature specifications define product detail,
plans define design, and tasks define execution. Explicit user instructions remain authoritative.
Routine work already authorized within an agreed scope does not require repeated permission.

An amendment MUST state the intended rule change, its rationale, affected artifacts and any migration
or validation work. Update this file, its version and Last Amended date, and include a temporary Sync
Impact Report for review. Remove that scratch report before committing the amended constitution.
Preserve the original Ratified date. A governance conflict requires a deliberate amendment; changing
an unrelated plan or interpreting a placeholder example as policy is not an amendment.

Version changes use semantic versioning: MAJOR for incompatible principle removal or redefinition,
MINOR for new principles or materially expanded guidance, PATCH for wording corrections that do not
change obligations. First adoption starts at 1.0.0. Every feature plan and pre-implementation review
MUST use the current version; existing plans with obsolete governance claims MUST be reconciled when
that feature's artifacts are next updated, before relying on their old gate result.

MUST and MUST NOT are requirements. A compliance review MUST cite applicable principles and the
relevant design or verification evidence; it MUST report unmet requirements and cannot waive them by
marking a checklist complete. Adoption of these rules does not assert that all existing code or
unreleased features have already passed their future implementation and release gates.

**Version**: 1.0.0 | **Ratified**: 2026-09-26 | **Last Amended**: 2026-09-26
