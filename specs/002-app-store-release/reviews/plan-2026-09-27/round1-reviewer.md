# Independent review: specs/002-app-store-release plan (Phase 0/1 artifacts)

**Reviewer:** Anthropic Opus 5.5, independent. I did not author these artifacts, used no tools and launched no sub-review.
**Candidate:** the seven artifacts in `candidate.json`, reviewed against base `05238815…` and the context hashes as supplied. I did not recompute any hashes.

## Verdict: CHANGES REQUESTED

The overall design is sound and traces to the spec. Six areas meet the acceptance criteria without changes:

- **Store boundary.** The draft stays unsent and release stays manual. Upload is normal, followed by internal TestFlight only, with no external groups and no "Internal Only" build.
- **Chrome handling.** There is no session extraction and no repeated login request.
- **Shared data.** The plan uses ETag conditional writes with full recheck on conflict, handles lost acknowledgements honestly and has no deferred uploads.
- **Guard reserves.** The capacity arithmetic holds: 296 spare tombstones cover 232 needed, and 224 spare blocks cover 200.
- **Stale unblock.** Binding unblock to a `blockId` closes this case.
- **Preserved behaviour.** Loading, music and highscore choices are unchanged.

However, one constitution conflict and one privacy/retention gap make the post-design **"PASS"** unsupported. Three further design gaps should be resolved before `speckit-tasks`, because the fixes change the contracts that tasks will be built from. All the fixes are plan-document edits.

## Findings

### F-01 — CRITICAL — Operator storage access conflicts with the managed-identity rule

**Location:**
- `constitution.md:64-65`
- `plan.md:56` (row IV), `plan.md:98-100`
- `research.md:94-96`
- `contracts/moderation-api.md:69-75`
- `quickstart.md:113-118`

**Evidence:**
- The constitution says: "Azure-hosted storage access MUST use managed identity with permissions scoped to the required data resources."
- The operator mode instead uses `AzureCliCredential`, which is the owner's personal Entra user identity. It uses this for PROD Blob data-plane reads, mutations and the schema-2 `migrate` command.
- The post-design row says "MI/scoped operator auth" but gives no justification. Complexity Tracking says "No constitution exception."
- Read plainly, the rule covers any access to Azure-hosted storage, not only access from the App Service.
- Governance (`constitution.md:147-148`) says a plan's reinterpretation is not an amendment.

**Impact:**
- The PROD migration and every moderation mutation would run under a human identity with a new data-plane role assignment.
- The gate claims PASS on a MUST it does not address.

**Required resolution (choose one and record it in the Constitution Check):**
- (a) A compliant path: run the same executable's operator mode inside the game's App Service using its existing managed identity. `HighscoreOptions.cs:48-50` already builds a `ManagedIdentityCredential`. This keeps "no public admin route."
- (b) An explicit constitution amendment covering human operator access via scoped Entra RBAC without keys.

If you (the lead) read the rule as limited to hosted workloads, record that disagreement explicitly rather than silently passing the gate.

### F-02 — HIGH — Retention design omits Blob versions and backups

**Location:**
- `plan.md:30` ("one private versioned Blob aggregate")
- `contracts/moderation-api.md:124-126` ("inspect a validated recoverable backup"), `contracts/moderation-api.md:141-146`
- `data-model.md:62-72` (retention table)
- `contracts/store-release.md:67-69`

**Evidence:**
- The retention table bounds report snapshots, reporter and producer hashes, and removed offensive names (30 days after resolution, or while ranked).
- It says nothing about:
  - previous Blob versions or soft-deleted copies, if versioning or soft delete is enabled;
  - the pre-migration backup the contract requires.
- Every mutation of a ≤1 MiB aggregate would keep a full prior copy. That copy includes removed names, report snapshots and installation hashes.

**Impact:**
- The disclosed retention and removal behaviour would not match actual data flows. This conflicts with constitution IV ("Privacy/help copy MUST match implemented data flows"), FR-015 ("defined … retention and access boundary") and FR-007/FR-008.
- A removed name or report could persist indefinitely in storage history.

**Required resolution:**
- Record whether versioning and soft delete are enabled on `donkeytrumpd` and `donkeytrumpp`, or make that an explicit inventory gate.
- Define a bounded lifecycle for previous versions, soft-deleted copies and migration backups, with their access boundary.
- Include that bound in the privacy inventory and pages, and include its cost in the DKK 100 estimate.

### F-03 — MEDIUM — 30-day retention depends only on a manual daily purge

**Location:**
- `research.md:63-64`
- `data-model.md:70`
- `contracts/moderation-api.md:95-96`, `contracts/moderation-api.md:110-111`

**Evidence:** Expired closed reports and audit records are deleted only when the owner runs `purge-expired`. There is no enforcing component.

**Impact:**
- A missed day, a holiday or illness silently breaks the disclosed 30-day retention.
- This violates the same constitution IV and FR-015 obligations as F-02.

**Required resolution:** Specify an enforcing mechanism and disclose the worst-case bound. For example:
- treat expired records as absent on every read;
- purge them opportunistically inside every conditional mutation's ETag transaction;
- keep the manual command for idle periods only.

### F-04 — MEDIUM — The in-app report route can be exhausted, and the owner has no remedy

**Location:**
- `contracts/moderation-api.md:29` ("Blocked installations may read/report"), `contracts/moderation-api.md:53-61`
- `data-model.md:69-70`
- `research.md:41` (modified clients mint secrets freely)

**Evidence:**
- Each installation hash may hold one unresolved report per entry.
- New secrets are free, and the report bucket refills at 1/s per instance.
- Unresolved reports are capped at 100 and total records at 1,000, including closed reports kept for 30 days.
- The operator surface has only per-report `resolve` and no early purge.
- Blocking an installation does not stop it from reporting.

**Impact:**
- One scripted client can fill the unresolved queue within minutes.
- After about ten resolve cycles it can disable in-app reporting for up to 30 days.
- The owner must resolve each spam report individually through the CLI.
- This undermines the FR-014 "in-app reporting route" and the US2-3 flow. The plan's general "not a guarantee" caveat does not cover the complete absence of an owner remedy.

**Required resolution:** Add a bounded owner remedy, for example:
- a `dismissed` disposition whose record and receipt may be purged immediately;
- and/or a bulk dismiss by reporter hash.

Also state whether reports from blocked hashes are still accepted.

### F-05 — MEDIUM — Screenshot capture build and data source are unresolved

**Location:**
- `research.md:131-135`
- `contracts/ios-release-flow.md:61-63`
- `contracts/store-release.md:50`, `contracts/store-release.md:55-56`
- `plan.md:126`
- `contracts/moderation-api.md:73`

**Evidence:**
- The research says capture builds use "same source/settings as Release, changing only service origin to isolated DEV data."
- The iOS contract says "Release always resolves the PROD HTTPS backend" and compiles out fixture origins.
- Operator mode rejects Azure container overrides, and "never reset a live ranking" applies.
- The plan does not say:
  - which scheme or configuration produces the release-equivalent DEV capture build;
  - how DEV comes to contain only "approved synthetic entries," given any existing DEV rows (post-migration `legacy`) without a reset.

**Impact:**
- Tasks cannot satisfy FR-004, FR-005 and SC-002 ("zero real-player information," release-equivalent) without inventing this design.
- The capture configuration difference cannot be documented as research §7 requires.

**Required resolution:**
- Name the capture configuration and its enforced differences from the distribution configuration.
- Define how the leaderboard data is controlled, for example:
  - verify that DEV rows are test-owned and remove the rest through moderation tombstones; or
  - add a dedicated DEV container via inventory.

### F-06 — LOW (non-blocking) — Quickstart describes `list` as initializing or migrating

**Location:** `quickstart.md:59-63`, compared with `contracts/moderation-api.md:78` and `contracts/moderation-api.md:97-98`.

The quickstart says the command "initializes/migrates" a fixture but then shows `moderation list`, which the contract defines as read-only. Clarify that the fixture is prepared with `migrate --expected-etag` or seeded separately.

## Optional suggestions (non-blocking)

- Mark private receipt responses `Cache-Control: no-store`.
- The working-day definition ignores Danish public holidays. That is stricter than required, so it is acceptable.

## On the proposed assessment

- "Seven artifacts complete, 26 FR/10 SC traced, no unresolved architecture choices" is substantially accurate.
- "Both design constitution gates pass" is not accurate until F-01 is resolved and F-02 is addressed.
- "Ready for speckit-tasks" should wait for F-01 through F-05 to be fixed and a focused re-review.
- Nothing in the artifacts claims execution, release readiness or any App Store action. I agree with that boundary.

## Limitations

- The review is text-only. I did not independently verify the Apple and Microsoft pages (screenshot resolutions, field limits, TestFlight and review workflow, Blob concurrency). Those claims are attributed to the lead and helpers.
- I did not see the following inputs, so conclusions depending on them are unconfirmed:
  - the 001 highscore spec and contracts;
  - the 2026-09-27 backend release record;
  - the current iOS highscore coordinator and UI;
  - the storage accounts' versioning and soft-delete settings.
- Whether a precedent exists for human data-plane access in 001 is unknown. A precedent would not amend the constitution anyway.
- SC coverage is mapped only coarsely (`plan.md:150`). I checked scenario coverage manually and found no missing SC. Finer per-SC mapping is left to tasks.
