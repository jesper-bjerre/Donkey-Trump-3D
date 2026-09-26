# Independent review — round 1: I1/I2/A1 planning remediation

**Role:** independent reviewer (Anthropic). I did not author the analysis or the remediation. Everything below comes from inspecting the supplied full artifacts and the scoped diff. I did not run any tools. Lead-reported checks are treated as claims, not evidence.

## 1. Disposition of the original findings

### I1 (HIGH): US1 scenario 6 and second-installation acceptance vs. the T026/MVP claim — **Resolved**

**Requirement.**
- `spec.md:30` (US1 scenario 6): qualification can be lost during name entry. The player then gets the updated bottom, an explanation and no success claim.
- `spec.md:21` (US1 Independent Test): the list must be reopened "from another installation".

**Evidence that the fix preserves the requirement without weakening it.**

- **T026 is limited to an initial slice.**
  - `tasks.md:11`, `tasks.md:52` and `tasks.md:58` (new Acceptance boundary) say T026 is the initial slice only.
  - Scenario 6 is assigned to T027–T031.
  - The installation check is assigned to T054.
  - Line 58 says explicitly: "Neither is waived or represented as passing at T026."
- **T026 no longer claims full completion.**
  - `tasks.md:80` marks "only this initial slice complete" and states both items remain pending.
  - The checkpoint at `tasks.md:82` denies both full US1 acceptance and MVP status.
- **Scenario 6 has concrete, dependency-reachable work.**
  - Tests: T027 (`tasks.md:94`, "server notQualified after name entry") and T028 (`tasks.md:95`, "cutoff change between GET and POST").
  - Implementation: T029 (`:99`) and T030 (`:100`, "changed-cutoff explanation").
  - Validation: T031 (`tasks.md:101`) checks "a qualifying GET followed by a non-qualifying POST that shows the updated bottom with an explanation and no success claim". It now also cites FR-009.
  - Chain: T026 → T027/T028 → T029/T030 → T031. Every step is backward-referencing, so it is executable.
- **Second installation has a concrete check.**
  - T054 (`tasks.md:181`) compares "two isolated app installations" using the integration mode, and states "Complete US1's second-installation acceptance".
- **The MVP definition is consistent everywhere.**
  - `tasks.md:273-276`: T001–T031 is the MVP, which is not complete US1 acceptance.
  - Also consistent: `tasks.md:192-193` (graph), `:207`, `:209`, `:210`, `:280`, `plan.md:49` and `plan.md:72`.
  - I found no remaining text claiming that US1 is complete at T026.

### I2 (MEDIUM): SDK pin scope — **Resolved**

- **Root pin and verification.**
  - T001 (`tasks.md:28`) now records the SDK and roll-forward policy in repository-root `global.json`.
  - It verifies resolution from the root and from `src/backend`.
  - T002 (`tasks.md:29`) verifies `src/backend.tests` after creating it. This avoids verifying a directory before it exists.
- **Container build.** T043 (`tasks.md:145`) ties the build image's SDK to the root `global.json`.
- **Other documents align.**
  - `plan.md:21` labels this as planned, not existing.
  - `quickstart.md:29-39` has the three-directory check and states that the planning fixes create no pin.
  - `research.md:7` does not contradict it.
- **Status claims are accurate.** The plan and quickstart both mark this as future work, so there is no false implementation claim.

### A1 (MEDIUM): blanket "no real endpoint" rule vs. T050/T054 end-to-end evidence — **Resolved**

- **One consistent model across all four artifacts.**
  - Ordinary fixtures stay on injected services.
  - A separate, explicit Debug integration mode is limited to a test-run-owned loopback API with isolated Azurite.
  - It allows only the selected origin, rejects redirects leaving that origin, never falls back to the production URL, and is absent from Release.
  - Locations: `tasks.md:48` (T012), `tasks.md:79` (T025), `plan.md:130`, `ios-flow.md:50` and `:56`, and `quickstart.md:142`.
- **Consumers and dependencies.**
  - T050 (`tasks.md:177`) and T054 (`:181`) name the mode explicitly.
  - Both reach T012 and T025 transitively through the phase gates.
- **The production restriction is not weakened.**
  - `ios-flow.md:48` still disables production publication for automation and demo modes.
  - `ios-flow.md:50` explicitly excludes production and "arbitrary development endpoints".
- **Defence in depth exists outside the app.** T009 (`tasks.md:45`) allows Azurite only in Development/Test and requires managed identity for production storage. A local API therefore cannot trivially target production Blob storage.

## 2. Remaining and new findings

I found **no material (blocking) in-scope findings**. The items below are non-blocking. The lead may address them at its discretion.

**R1-01 — LOW: where the integration-mode guards are implemented and tested is not pinned down**
- **Where.** `tasks.md:48` (T012), `tasks.md:75` (T021) and `tasks.md:79` (T025).
- **Implementation owner is ambiguous.**
  - T012 places the origin and redirect restriction in `HighscoreFixtures.swift`.
  - Redirect rejection, however, lives in the URLSession delegate of the real transport, which T021 creates. T021 does not mention it.
- **No named evidence file.** T025 says "Verify origin restrictions, redirect rejection, no production fallback and Release exclusion", but names no test file and no validation record.
- **Why it is only LOW.** The dependencies still make this executable, because the Foundation gate means T021 runs after T012, and T025 depends on T021 transitively.
- **Impact.** An implementer could put the guard in a fixture wrapper that the real service never uses. Verification could then be manual rather than repeatable.
- **Suggestion.** Name the enforcing component in T021, or say that T021 adopts T012's guard. Name the test file, for example `HighscoreServiceTests.swift`, and record the result in `validation.md`.
- **Not a blocker.** The obligation is explicit, and T054 re-validates Release fixture exclusion.

**R1-02 — Informational: shell block count in `plan.md:149`**
- `plan.md:149` records "syntax checks of seven shell examples". The new `quickstart.md:33-37` block brings the total to eight.
- The sentence is a dated historical record, so it is not false. Optionally annotate it, or leave it as is.

**R1-03 — Informational: two points left to the implementer**
- **Docker build context.**
  - `src/backend/.dockerignore` implies the Docker build context is `src/backend`, which does not contain the root `global.json`.
  - T043's wording ("verified against") covers this by comparison, so no change is required.
- **Two isolated installations.**
  - T054's "two isolated app installations" cannot be two copies of one bundle ID on a single simulator. Two simulator devices would work.
  - This is an implementation detail and does not create a contradiction.

**AGENTS.md:85 (auxiliary change).**
- `claude-opus-5-5` matches Anthropic's canonical ID format for Opus 5.5. The edit is a one-line identifier correction and changes no policy obligations.
- I cannot verify the Copilot fallback identifier, the external documentation or the preflight. Per AGENTS.md:92-93, my own statement of which model I am is not verification of my configuration.

## 3. Verdict

**I agree that the remediation satisfies the applicable requirements, with no material unresolved in-scope findings.**

- I1, I2 and A1 are each fixed consistently across tasks, plan, quickstart and the iOS contract.
- The spec's acceptance criteria are kept intact: scenario 6 and the second installation are deferred explicitly, not waived.
- The dependencies are executable and reference backward.
- No task is ticked, and no implementation or check result is claimed.
- The production-publication safeguards are preserved.
- R1-01 is recommended but does not block.

**Limitations of this review.**
- This was text inspection only. I did not recompute the hashes, run bash, apply the patch or check links.
- The "unchanged spec and constitution" claim rests on the supplied full texts and the manifest.
- All tests in tasks.md and quickstart.md are future work and were not executed. Nothing in this review is evidence of implemented behaviour, performance, container, device or Azure results.
