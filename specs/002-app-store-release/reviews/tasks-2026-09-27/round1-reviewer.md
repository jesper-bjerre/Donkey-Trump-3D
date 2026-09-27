# Independent review: `specs/002-app-store-release/tasks.md` (SHA-256 `c0e8206a…9080`)

**Role:** independent reviewer (Anthropic, Claude Opus 5.5). I did not author this task list and used no tools. The review is a text-only design review against the supplied spec, plan, data model, three contracts, quickstart, constitution v1.0.0 and AGENTS.md.

## Findings

### TR-01 — MEDIUM — Cost/shared-plan readiness gate runs after draft readiness

- **Location:** tasks.md:130 (T060), :151 (dependency graph `US3 → US4 … → US5 …cost`), :120 (T055 "all readiness gates" is undefined).
- **Impact:** T055 and T056 can record a validated draft before T060 runs. T060 is the task that states a missing baseline or an over-budget/capacity condition "blocks readiness". T039 refreshes cost evidence, but no task makes a pass on it a named prerequisite of T055. T065's re-check comes after the owner handoff document is already drafted.
- **Requirement:**
  - FR-012 requires verifying the additional-cost estimate and recording the committed baseline "before draft readiness".
  - The spec edge case at spec.md:110 says an unresolved constraint blocks "draft readiness".
  - US5-4 and SC-007 depend on the same gate.
- **Required change:**
  - Make the T060 budget/capacity/neighbor determination, or an explicit pass recorded in T039, a stated prerequisite of T055.
  - Enumerate the readiness gates by task ID, at minimum T008 (rights), T039/T060 (cost and neighbors), T042–T044, T043 and T054. Then "all readiness gates" is checkable rather than interpretive.

### TR-02 — MEDIUM — Managed-identity-from-SSH feasibility probe deferred to T037

- **Location:** tasks.md:22 (T003: "conclusive MI Blob probe occurs at T037"), :77 (T037).
- **Impact:** Every cloud operator function depends on a process launched from an `az webapp ssh` session obtaining the app's ManagedIdentityCredential. Those functions are T023, T024, T033/T047 seed, T050 delete and T037–T039/T043. Whether the SSH shell exposes the managed identity context is exactly the uncertain point the plan wanted checked early. T003 only discovers "SSH availability". An infeasible route would surface after T009–T036 are built around it. The only compliant fallback at that point is a blocker, because contract lines 85–86 allow no human Blob credential.
- **Requirement:** plan.md:117–120 says to probe DEV SSH and a harmless managed-identity metadata read *early*. A missing managed identity context blocks operator-dependent work.
- **Required change:** extend T003 with a read-only SSH-session check. It should confirm that the managed identity context required by ManagedIdentityCredential is available to a process started in that session. Check presence only, without printing values or tokens. Record a blocker immediately if it is absent. The conclusive aggregate read can remain in T037.

### TR-03 — MEDIUM — Irreversible PROD schema migration lacks an explicit authorization and approval precondition

- **Location:** tasks.md:139 (T039).
- **Impact:** After T039, rollback to a schema-1 artifact or restoring the old Blob is prohibited (moderation-api.md:189–194). T039's preconditions cover DEV results, budget and neighbors. It does not name the authorization basis or the existing protected-environment approvals that the contract requires.
- **Requirement:**
  - moderation-api.md:180 says "Owner-authorized operator mode conditionally converts…".
  - plan.md:129 says "authorized PROD promotion".
  - The constitution's workflow and governance sections, and AGENTS.md:313–315, say existing human approvals for production changes still apply.
- **Required change:** add a precondition to T039 to record the authorization basis for PROD promotion and migration and to honor the workflow's protected-environment approval. Do not re-ask the owner for authorization already durably given.

### TR-04 — LOW — Rollback runbook update comes after the PROD migration

- **Location:** tasks.md:138 (T062 updates `docs/production-smoke-and-rollback.md` in Phase 8) versus T039.
- **Impact:** Between T039 and T062, the release runbook may still describe schema-1-era rollback while PROD is on schema 2. T036 enforces the rollback floor in pipeline checks, which limits automated risk. A human following the stale runbook is not covered.
- **Requirement:**
  - The constitution's quality gates require a recorded release/recovery procedure for the real target.
  - moderation-api.md:189–194 applies.
- **Required change:** move the schema-aware rollback and recovery portion of T062 into T036 or T038, before T039.

### TR-05 — LOW — T043 leaves the test installation blocked in PROD

- **Location:** tasks.md:83 (T043).
- **Impact:** If the blocked installation is the T042 physical device, it stays blocked. A later candidate change that requires re-running T042 as an update keeps the credential and cannot publish. That would produce a misleading publication failure. It also leaves a residual PROD block of undocumented intent.
- **Requirement:** tasks.md:155 says a superseding build re-executes T040–T044. The contract's block/unblock semantics apply (show-block and expected-blockId unblock).
- **Required change:** use a dedicated test installation for the block path. Alternatively, end T043 with a recorded expected-blockId unblock, showing that tombstones persist.

### TR-06 — LOW — Method for physical lost-ack/unconfirmed evidence is unspecified

- **Location:** tasks.md:82 (T042: "failure/unconfirmed/no replay … no debug-only failure injection").
- **Impact:** A distribution build cannot inject a lost acknowledgement. Ad-hoc network toggling may produce a definite failure, which could then be recorded as "unconfirmed". That would conflict with constitution V's requirement for accurate evidence.
- **Requirement:**
  - ios-release-flow.md:93–94 requires this physical case.
  - Constitution III requires distinguishing unconfirmed from failed saves.
- **Required change:** require T042 to record which outcome was actually observed. If a genuine unconfirmed case is not reproducible, record it as a named exception backed by the T011/T012 automated evidence, not as a physical pass.

## Checked and found adequate (no finding)

- **Dependency graph:** no cycle.
  - T008 rights are foundational and block distribution only.
  - T033/T034 capture source lands before the T040 freeze, and T047 only enables and seeds.
  - US2 owns the single upload (T041), and US3 reuses it (T053).
  - Candidate invalidation re-runs T035 and T040–T044 plus media.
- **Tests-first ordering:** T009–T012 come before models, and T025/T035 are required green before deployment.
- **Constitution III:** covered by T010, T018, T019 and T024:
  - ETag recompute on conflict
  - no empty replacement
  - unconfirmed-save mapping
  - no deferred or automatic retries
  - atomic multi-report closure
  - stale-unblock protection
- **Managed-identity-only operator:** covered, with no environment or token extraction and no human Blob fallback.
- **Capture isolation:** covered, including PROD 404/startup failure, simulator-only capture and archive rejection.
- **Submission boundary:** covered in T041, T053, T055, T056 and T065. There is no Submit for Review, external beta or automatic/scheduled release, and manual release is selected.
- **FR-001–FR-026, SC-001–SC-010 and all five story scenarios:** traced to implementing and acceptance tasks. The physical, owner and live gates are correctly kept as blockers that simulator passes cannot override.
- **Story structure:** the MVP is correctly labeled an internal MVP, not release acceptance. US2-before-US1 is justified by the candidate dependency.
- **Owner inputs:** handled in T004, consolidated and requested only when not discoverable. Blocked inputs stop only dependent tasks.

## Limitations

- `research.md`, `.agents/skills/speckit-tasks/SKILL.md` and `review-plan-2026-09-27.md` were not in the packet. I verified skill-checklist conformance only against the constraints you summarized and the supplied `validation.json`. I did not re-derive format, ID or path validity myself.
- These gaps do not affect the findings above.
- No runtime, cloud or store state was inspected, and none is required for this task-generation review.

## Verdict: **CHANGES REQUESTED**

TR-01 to TR-03 are material dependency and safety-gate gaps that small, scoped edits to `tasks.md` can fix. TR-04 to TR-06 are low severity and should be fixed in the same pass, but they would not block approval on their own. No other changes are required.
