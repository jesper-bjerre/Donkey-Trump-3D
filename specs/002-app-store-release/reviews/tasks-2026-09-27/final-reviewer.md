# Focused re-review: `specs/002-app-store-release/tasks.md` (SHA-256 `8c65cac1…5388`)

**Role:** Independent reviewer: Anthropic, Claude Opus 5.5 (`claude-opus-5-5`). This is a focused re-review of an OpenAI-authored task list. It is text-only: I used no tools and launched no sub-review.

**Scope:** The TR-01 to TR-06 remediation and any regressions it introduces. The prior verdict was CHANGES REQUESTED against `c0e8206a…9080`.

**Diff check:** I checked `focused.diff` against the supplied numbered `tasks.md`. Every changed hunk matches the file content at lines 22, 76, 79, 82–83, 120, 130, 136 and 151–152. Task IDs, count (65) and cross-references are unchanged.

## Dispositions

### TR-01 (MEDIUM): RESOLVED

- **T039 (line 79)** records an explicit PASS/BLOCKED for four items: the committed plan-cost baseline, added spend ≤ DKK 100/month including VAT (with capture use), shared capacity, and neighbor before/after health. It is labelled a mandatory pre-draft gate.
- **T055 (line 120)** lists its prerequisite gates by ID: T008 (rechecked), T030, T039, T042, T043, T044, T049–T050, T051 and T054. This covers the minimum set I asked for, and "all readiness gates" can now be checked.
- **Post-capture drift:** T055 requires reconfirming the T039 assumptions after T050.
- **T060 (line 130)** is correctly reduced to a continuity recheck. It can still invalidate an earlier ready status.
- **Dependency graph (lines 151–152)** is consistent with these changes.

This satisfies FR-012 ("before draft readiness"), the edge case at spec.md:110, US5-4 and SC-007.

### TR-02 (MEDIUM): RESOLVED

T003 now runs an early check from a process launched inside the SSH session. The check:

- reports only whether the managed-identity context needed by ManagedIdentityCredential is present and readable, as a boolean;
- never outputs environment values, endpoints or tokens;
- records an absent context as an immediate blocker for cloud-operator work, with no human-credential fallback.

T037 keeps the conclusive aggregate read, and its prerequisite "T003 … access constraints are resolved" enforces the blocker. This matches plan.md:117–120 and moderation-api.md:78–86. The plan could also be read as asking for an actual metadata read this early, but that command does not exist until T023. The presence check is therefore the correct early subset.

### TR-03 (MEDIUM): RESOLVED

T039 now covers everything the finding asked for:

- It records the authorization basis for both PROD promotion and the irreversible migration.
- It honors configured protected-environment approvals before any mutation.
- It forbids re-asking for authorization that was durably given.
- If authorization is missing, only the dependent production action is blocked.

This is consistent with moderation-api.md:180, the constitution's Governance section and AGENTS.md:17–19 and 313–315.

### TR-04 (LOW): RESOLVED

- T036 updates the schema-aware migration, maintenance and recovery procedure in `docs/production-smoke-and-rollback.md` before deployment. It names the schema-2 rollback floor and forbids restoring an old Blob over guards.
- T038 rehearses that procedure before T039.
- T062 is explicitly final reconciliation only and cannot defer the prerequisite.

### TR-05 (LOW): RESOLVED

After its assertions, T043 now:

- reads the current blockId privately and performs the expected-blockId unblock;
- confirms the tombstones remain;
- stops and re-reads on a mismatch instead of overriding a newer block;
- restores the phone's publication ability without resurrecting the removed result;
- keeps a failed cleanup as a blocker for affected retests.

This matches moderation-api.md:123–127 and removes the stale-block hazard for re-executing T042 on a superseding build.

### TR-06 (LOW): RESOLVED, and I accept the lead's qualification

I withdraw the part of my original change that proposed a "named exception" backed by automated evidence. The governing artifacts do not authorize that path:

- FR-016: "Unperformed physical checks remain readiness blockers."
- ios-release-flow.md:93–94 lists failed/lost-ack submission among the required physical checks.
- SC-003 and constitution V apply.

My suggestion would have created a waiver the spec does not grant. The revised T042 is correct:

- It uses a real connection interruption on the test phone with an explicit test-owned submission.
- It records the outcome actually displayed plus a read-only server check.
- It never relabels a definite failure as unconfirmed.
- If the unconfirmed case is not observed, the gate stays BLOCKED, and the T010/T011 automated evidence is kept separately without substituting for it.

Citing T010/T011, rather than my earlier T011/T012, is also the more accurate reference: T012 is UI coverage.

## Regression check

I found no new material issues. Items checked:

- T055's gate list does not drop previously implied prerequisites. T031's live pages are covered by T054, and T035/T040/T041 are upstream through T042.
- T057 still prepares the handoff in US4. It explicitly defers completion until after US5 and final review, and T065 delivers it. This is consistent with the new graph line "owner instructions at final handoff".
- Adding cost PASS/BLOCKED to T039 does not force PROD promotion before the cost check. T037 already requires the T003 cost constraints to be resolved before any cloud deployment.
- The dependency graph remains acyclic, and no new owner-adjudication or re-authorization request was introduced.

## Non-blocking observation (no change required)

A controlled connection interruption may not reliably produce a genuine lost acknowledgement. If the physical unconfirmed case stays unobservable, T042 correctly leaves readiness blocked. Any relief would then need a spec-level decision, reported as a genuine prerequisite, not a task-list edit or a reviewer waiver. This does not affect the task decomposition.

## Limitations

- I did not independently verify the SHA-256 values in `context.json` or `candidate.json`. I relied on the lead's statement that the governing and source contexts are unchanged, and on the diff/file consistency I checked by hand.
- `research.md`, `data-model.md`, `quickstart.md`, `store-release.md` and `review-plan-2026-09-27.md` were not re-supplied. None of the six fixes depends on them.
- No runtime, cloud, device or store state was inspected, and none is needed for this review.
- This verdict covers task generation only. It is not implementation completion or release readiness.

## Verdict: **APPROVED**

All six findings are resolved as scoped. TR-06 is resolved in the stricter form the lead proposed, which I agree the spec requires. No important findings or regressions remain.
