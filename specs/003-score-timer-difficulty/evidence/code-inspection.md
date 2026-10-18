# Lead source/contract inspection

2026-10-18. Owner exception applies; no Claude/substitute review. Inspection is not runtime evidence.

- GameSession centralizes candidate filtering by run/attempt and registered active T, earliest terminal and timeout/collision/rescue ties. Clearance ties at loss are rejected. R expires exactly; final result freezes once.
- LevelProgress retains ≤20 lifetime IDs/T/bases through retry, resets on level/new run. Rewards use checked Int arithmetic and integer bonus seconds; unsupported remote range never changes the local score.
- BarrelSystem assigns per-release identities separately from render IDs, immutable base samples and direct-flight provenance through first landing. Events copy positions/IDs before later ticks/pool reuse.
- GameplayTimeline uses the production engine clock epoch, lock-protected stamped input/commands,32-slice budget with retained debt, inactive-span skipping, once-only edges and phase/attempt retirement. App lifecycle freezes all phases; explicit navigation may abandon old debt. MainActor HUD snapshots remain copied.
- Best persistence uses an ordered utility queue, not render-loop storage. Publication transports/coordinator deadlines/consent/no-replay remain unchanged.
- Common Swift/backend validators govern submission, snapshots, rank and stored schema1/2 validation. Blob CAS/moderation/identity/tie/deadline implementations unchanged. Old totals/best retained; no scoring-season/schema migration.
- Debug fixture service selection precedes all injected/backend/integration selection. Any malformed/combined presence also selects in-memory best and blocks synthetic CompletedRun exception. Release excludes fixture parsing/injection; configuration guard excludes DEBUG and release archive inspection has binary markers.
- Build phases inspected: xcodebuild invokes validate-ios-release.py **build-settings** configuration guard, not archive checks or test functions. No other shell test execution in the app build phase. dotnet build compiles, does not invoke dotnet test. No contract/smoke/release-test script is authorized.

Compilation findings and any focused corrections are recorded in builds.md. Source/design inspection found no remaining known requirement conflict; runtime/physical acceptance stays unexecuted.

## Focused corrections before final builds

- Initial scene inactivity must freeze rather than pause a just-initialized Debug/autostart attempt. Engine now starts activity=false and pauses play only on a true active→inactive boundary; returning active still does not auto-resume real paused play.
- Inactive/paused spans are skipped without burning thousands of physics slices, and discard press edges belonging to those inactive spans. Pre-pause active debt remains chronological.
- Attempt snapshots copy the checked BarrelSystem spawn counter; lifetime/base-speed setters are file-restricted. Pure helper and event ownership inspected against the data model.

- Pending navigation/new-run commands discard already-batched feedback from the older run before rendering it. This prevents an old terminal sound/effect from changing the title/new run after chronological retirement.

- Debug-only fixture UI evidence reads the real stored best on MainActor and compares it with the isolated best before/after a real rescue and relaunch. It contains only integer scores, creates no new persistence, and is excluded from Release. The test is authored, not executed.

- Sequence check authoring explicitly forces rolling/direct/mixed configurations on an upper-half floor where direct throws are legal, exercises both player movement directions and full/cut jumps, and searches bounded button timings. It observes real hits, landings and a subsequent jump instead of labeling one arbitrary failed input as impossible. No sequence has been executed.
