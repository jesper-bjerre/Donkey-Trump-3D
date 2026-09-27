# Independent focused re-review, round 2: specs/002-app-store-release plan

**Reviewer:** Anthropic Opus 5.5 (`claude-opus-5-5`). I did not author these artifacts, used no tools and launched no sub-review.

**Candidate:**
- The seven artifacts with the hashes listed in `candidate.json`.
- Governing context as listed in `context.json`.
- Base commit `05238815…`.

I did not recompute any hash. I assessed the numbered final text and `focused.diff` as supplied.

## Verdict: CHANGES REQUESTED (one new MEDIUM finding; F-01 to F-06 resolved)

All six round-1 findings are adequately resolved by the plan changes. One design ambiguity remains, F-07. I missed it in round 1; it is not introduced by the remediation. It affects the reporter-visible disposition and queue capacity, so tasks would otherwise have to invent it. The fix is a small contract edit, after which a focused check of that edit should be enough.

## Dispositions of round-1 findings

### F-01 (CRITICAL) — Resolved

**What changed:**
- Blob access for DEV and PROD operator work now happens only through the app's `ManagedIdentityCredential`, inside the target App Service, reached via `az webapp ssh`.
- `AzureCliCredential`, the default credential chain, shared keys and local cloud execution are all excluded (`contracts/moderation-api.md:74-85`).
- The human identity authenticates only the control-plane session (`research.md:125-129`, `quickstart.md:116-131`).

**Why this is compliant:**
- It satisfies `constitution.md:64-65` as written.
- It reuses the existing MI construction in `HighscoreOptions.cs:48-50`, with no amendment needed.

**Supporting integrity observation:** old schema-1 code cannot silently corrupt a migrated Blob.
- `HighscoreDocument.Validate` rejects `SchemaVersion != 1` (`HighscoreDocument.cs:17`).
- Unmapped members are disallowed (`HighscoreDocument.cs:6`).
- ETag replaces fail on stale state.

So the maintenance gate adds defence in depth rather than being the only protection.

**Residual (non-blocking, see S-1 and S-2):**
- `plan.md:56` row IV still says "MI/scoped operator auth" and does not name the chosen mechanism.
- Whether MI works from an SSH shell is an execution prerequisite that is discovered late in the dependency order.

### F-02 (HIGH) — Resolved

**Evidence and policy:**
- `storage-properties.json` shows soft delete disabled and versioning, change feed, restore and container delete unset on both accounts. It was read through the management plane only.
- The policy keeps versioning, soft delete and App Service player-data backups disabled.
- There is one private pre-migration backup per target, with a 24-hour expiry and early deletion after verified success. A lifecycle rule acts as a secondary cleanup safeguard (`research.md:92-110`, `data-model.md:72,76-83`, `contracts/moderation-api.md:150-155`).

**Gates:**
- Unknown historical copies block the retention claim.
- The backup period and outage exceptions go into privacy and cost evidence.

**Assessment:**
- The backup holds schema-1 content, which has no reports, hashes or audit data, so the added privacy exposure is small and bounded.
- Rolling forward only (`moderation-api.md:174-179`) is consistent with deleting the backup early.

### F-03 (MEDIUM) — Resolved

Expiry is now enforced by the system, not by the owner remembering to purge:
- Reads apply logical expiry without writing.
- Every mutation purges expired records before recomputing.
- A worker purges hourly and on startup, using the same ETag and MI rules.

**Supporting points:**
- The worker pauses during maintenance.
- The bound is one hour while the service is available.
- Outage deferral is disclosed.
- PROD Always On is a readiness gate (`research.md:84-90`, `data-model.md:76-80`, `moderation-api.md:113-119`).
- Deterministic fake-clock and outage checks are planned (`quickstart.md:90-92`).

Several instances running the worker at once is safe under conditional writes.

### F-04 (MEDIUM) — Resolved, with the triage gap noted under F-07

**What changed:**
- `dismiss-spam` bulk-dismisses selected reports in one ETag transaction, up to 100 at a time, all-or-nothing.
- Snapshots are removed immediately.
- Minimal receipts are kept for 24 hours, capped separately.

**Why this is enough:**
- It restores queue admission without deleting genuine reports (`moderation-api.md:99-106`, `data-model.md:71`).
- Blocked hashes may still report (`moderation-api.md:29`).
- The Sybil limit is disclosed honestly (`moderation-api.md:135-137`).
- Tests are planned (`quickstart.md:93-94`).

### F-05 (MEDIUM) — Resolved

**Capture build:**
- A named non-distributable `AppStoreCapture` configuration is simulator-only.
- Its single stated product-setting difference is the base URL (`ios-release-flow.md:61-68`, `store-release.md:64-71`).
- Archive and export are rejected for it.
- Distribution validation requires Release and the exact PROD origin.

**Capture data:**
- A separate `highscores-capture` container is used, with no fallback to other containers.
- Capture is gated on DEV identity, and PROD startup fails if capture is enabled.
- Ordinary DEV data is untouched.
- An owned-fixture reseed is the single, explicitly bounded reset exception.
- Every visible row is inspected in the pixels, and the dataset is deleted after capture (`store-release.md:73-92`).

**Cost:** the added DEV MI role is container-scoped and its cost is included.

### F-06 (LOW) — Resolved

`quickstart.md:58-61` now says `list` is read-only. The smoke helper creates the fixture and invokes migration.

## New finding

### F-07 — MEDIUM — Reports on an entry already removed by another action have no defined resolution

**Location:**
- `contracts/moderation-api.md:55-56` (one unresolved report per reporter and entry, so many reporters may report the same entry)
- `contracts/moderation-api.md:88-98` (`list` fields; `resolve` semantics)
- `contracts/moderation-api.md:107` (`remove --entry-id`)
- `data-model.md:49-57`
- `quickstart.md:77-78`

**Evidence:**
- When several installations report the same offensive entry, resolving one report with `remove` tombstones the entry.
- `remove-and-block` also tombstones the producer's other ranked rows, and `remove --entry-id` removes rows directly. In all these cases, other unresolved reports for the affected entries stay pending.
- The contract does not say whether:
  - a later `resolve --decision remove` on an already-tombstoned entry succeeds idempotently;
  - it fails;
  - the owner must choose `no-action`, which would tell those reporters the untrue "no action" disposition.
- `list` returns only IDs, status, reason and deadline, with no entry ID or grouping. The owner cannot see duplicates, or select spam for `dismiss-spam`, without running `show` on each report individually.

**Impact:**
- The disposition shown to reporters can be inaccurate or undefined in a likely path: several players reporting one offensive name. This affects FR-014, US2-3, SC-004 and the one-working-day response for every reporter.
- Genuine pile-on reports use up the 100-report unresolved cap. The only remedy is resolving each one individually, because `dismiss-spam` would mislabel genuine reports.
- Tasks would have to invent these semantics.

**Required resolution:** a plan-document edit. Choose one of these and add a quickstart assertion for it:
- **(a)** Any transaction that tombstones an entry also resolves all unresolved reports for that entry ID with the matching disposition (`removed`, `removedAndBlocked`, `legacyRemoved` or `starterRemoved`).
- **(b)** `resolve --decision remove` on an already-tombstoned entry is defined as a successful, idempotent `removed` disposition, and `list` groups by entry ID with counts.

In either case, `list` should show the private entry ID for grouping in the owner console only, never in logs, so that `dismiss-spam` selection is practical.

## Non-blocking suggestions

- **S-1:** Update `plan.md:56` row IV to name the chosen compliant mechanism explicitly, for example "operator Blob access only via app MI inside App Service; human Entra for control-plane SSH only". Plan-level governance citation then matches the contracts.
- **S-2:** Move the harmless read-only DEV probe earlier in the Phase 1 order, into inventory or step 1.
  - The probe runs over SSH and makes a MI metadata read of the aggregate.
  - Every cloud moderation and migration path depends on MI being usable from an SSH shell, including managed-identity environment availability in that session. Failure currently surfaces only at step 4.
  - If the environment is missing, the plan should keep its stated outcome (blocked). It must not improvise environment or token extraction, which `quickstart.md:130` forbids.
- **S-3:** Name the ProblemDetails code for maintenance and pre-migration write rejection (`moderation-api.md:147-148,157-159`), for example `service_maintenance`. The iOS client can then treat it as a definite no-write rather than as unconfirmed.

## Limitations

- **Text-only review.** I did not independently verify:
  - the Apple and Microsoft pages (App Service SSH environment behaviour, lifecycle timing, screenshot specifications);
  - Azure state beyond the supplied `storage-properties.json`;
  - any Connect state.
- **Inputs I have not seen:**
  - the 001 highscore spec and contracts;
  - the 2026-09-27 backend release record;
  - current iOS coordinator and UI source;
  - the storage account kind and lifecycle eligibility;
  - PROD plan tier and Always On availability;
  - the MI's current role scope.

  Conclusions depending on these are execution gates, not verified facts.
- **Hashes.** Hashes are taken as supplied. The review payload is the candidate as shown.
- **Scope of this verdict.** It concerns plan and design acceptance only. No implementation, test, deployment or store action is claimed or required for it.
