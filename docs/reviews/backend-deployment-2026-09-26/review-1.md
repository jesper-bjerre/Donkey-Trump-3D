# Independent review: backend DEV/PROD deployment (implementation review)

**Role:** independent reviewer (Anthropic, `claude-opus-5-5`). I stayed read-only, used only the supplied packet, and launched no other reviewer.
**Reviewed:** base `a47af91b`, pushed candidate `db52f2b3`, the supplied manifest (12 files), the scoped diff, the untracked `evidence.json`, and the unchanged backend context.

## Verdict: NOT YET APPROVED

I found no correctness or security defects in the workflows, the release script or the provisioning script. Two material items block approval: one gap in the evidence (BD-01) and one gap against the owner's cost constraint (BD-02). I also need three small pieces of context (CTX-1 to CTX-3). Everything else checked out, as listed under "Verified".

## Findings

### BD-01 — Medium — Evidence does not show the shared PROD B1 plan settled after deployment
- **Location:** `evidence.json:453-612`, and the capacity text in `docs/backend-deployment.md:144-148`.
- **What the evidence shows:**
  - Plan CPU was 15% at 15:20 and rose to 54/92/99% at 15:21–15:23. That is *before* the PROD package was activated (`20260926152408.zip`; the PROD run was created at 15:22:59). The evidence does not explain this rise.
  - CPU was 99% at 15:27, 89% at 15:28 and 70% at 15:29. The series ends there.
  - Memory was 75% before and 76% at the last sample.
- **Consequence:** The last sample is still about 4.7× the pre-deployment CPU on a single-core plan shared with `byensgaader-api-p`. "Declining" is a trend, not a settled state. An idle .NET API plus Always On and Health Check pings should not hold 70% CPU. If this persists, it degrades the existing PROD app. That conflicts with "existing apps preserved" and the no-SKU-increase constraint.
- **Scope of this finding:** The single fast 200 response from the existing app at 15:28 is useful but short. This concerns idle steady state, not sustained-load validation, which is already an accepted limitation.
- **Resolution:**
  - Record a later plan metrics window, for example 30–60 minutes after 15:27, plus existing-app health and latency.
  - If CPU returns near baseline, record that. Attributing the 15:21–15:23 spike would help (for example provisioning, SCM/Kudu inspection, or startup).
  - If CPU stays elevated, investigate before approval.

### BD-02 — Medium — No detection for the DKK 100/month ceiling, and the earlier cost-alert prerequisite was removed
- **Location:**
  - `docs/production-smoke-and-rollback.md`: the diff removes "Set and record a modest log retention period and cost alert using the actual budget".
  - `docs/backend-deployment.md:150-167`.
  - `infra/provision-backend.py`: no budget is created.
- **Consequence:** At the documented rate limits (`HighscoreOptions.cs:55-58`; per process, and PROD has Always On with no quota), the doc's own list prices give:
  - GET at 20/s ≈ 51.8M reads/month ≈ DKK 143.
  - Qualifying POST at 2/s ≈ 5.2M writes plus reads ≈ DKK 194.
  - Total ≈ DKK 337 before VAT, about DKK 420 including VAT, before egress.
  - That is about 4× the owner's ceiling from one abusive client. DEV F1 quotas cap DEV, but nothing caps PROD.
- **What the doc already says:** It correctly states that rate limits do not guarantee the bill. However, the change removes the only detection mechanism the runbook previously required and replaces it with manual review. That is a regression against an explicit owner constraint.
- **Resolution (within authorized scope; costs nothing and does not touch the plan or SKU):** Either
  - (a) provision a subscription- or resource-group-scoped Azure budget alert below DKK 100, covering the storage resource groups and the app's usage (by tag or scope), and record it in the evidence; or
  - (b) at minimum, restore the cost alert as an explicit, unresolved release prerequisite in the runbook and in the evidence limitations.

  I recommend (a).

## Context needed before approval

- **CTX-1 — Revision identity.** Confirm that the tracked manifest files are byte-identical to `db52f2b` (for example `git diff --quiet db52f2b -- <tracked manifest paths>` plus `git status`), and that only `evidence.json` is untracked.
  - The GitHub runs and the deployed artifact are for `db52f2b`. Some doc text is post-deployment wording ("Both environments are deployed; see the dated evidence").
  - If the tracked workflows or scripts differ from what ran, the pipeline evidence does not cover the reviewed content.
- **CTX-2 — Naming parity.** The acceptance criterion requires the verified byens-hemmeligheder `-d/-p` app, storage and group naming.
  - The packet establishes app-name parity (`byensgaader-api-d/p` → `donkeytrump-api-d/p`) and the reuse of the existing plans.
  - It gives no reference storage account, storage resource group or deployment identity names. Supply the sanitized reference names so I can check `donkeytrump-d_rg`, `donkeytrumpd` and `oidc-donkeytrump-d` against them.
- **CTX-3 — Evidence and record links.** `docs/backend-deployment.md:169` links to `docs/reviews/backend-deployment-2026-09-26.md`, which is outside the packet, and `evidence.json` is untracked. Confirm that both are committed with the final record, so the guide's claims resolve.

## Verified (no findings)

- **Exact-artifact promotion.** `backend-deploy-prod.yml:36-55` with `backend-release.py:16-41`:
  - The DEV run is checked for workflow ID, repository, `main`, the push or dispatch event, completion and success.
  - The artifact is downloaded by run ID. It must match `head_sha` in both the manifest and the embedded `deployment.json`, and the SHA-256 must match.
  - PROD never rebuilds.
  - Live evidence shows the same ZIP hash `5a5a0952…` active in DEV and PROD and in the artifact.
- **Input handling.** The run ID is passed through `env`, checked to be numeric, and never interpolated into shell. Public PRs get no `id-token` and no environment.
- **Credentialless OIDC and separation.**
  - Each environment has its own identity, a federated credential using the immutable subject, and a main-only branch policy.
  - Each deploy identity has Website Contributor on its own app only.
  - Basic SCM/FTP publishing is off, and no secrets are used.
- **Runtime identity.**
  - Each app has a system-assigned identity with Storage Blob Data Contributor scoped to its own `highscores` container.
  - Shared-key access and public blob access are disabled, and TLS 1.2 is enforced.
  - The anonymous blob request is denied, and the app code (`HighscoreOptions.cs:44-51`) uses the managed identity.
- **Smoke checks** (`backend-release.py:65-96`):
  - Checks liveness, the storage-backed GET, `no-store` and the HTTP→HTTPS 301 via `NoRedirect`.
  - Errors, bodies and player names are not printed.
  - Retries are bounded within the job timeout.
  - The PROD GET returning 200 with `revision: "empty"` proves read authorization, since a missing role would return 403 and fail closed.
- **Live DEV write path.** Create, persistence across restart, deduplication and changed-payload 409 were all exercised. PROD had no writes, which is correctly stated as a limitation.
- **Plans and existing apps.** Plans are unchanged (F1/B1, capacity 1, 2 sites each), and both existing apps returned 200 afterwards. The provisioning script only reads the plans and refuses unowned name collisions and app moves.
- **Documentation boundary.** The docs keep backend deployment separate from iOS and App Store readiness. Constitution I, III and IV boundaries are preserved: no storage auto-creation, fail-closed reads, and no log or privacy expansion.

## Non-blocking notes (no action required for approval)

- **NB-1:** If a DEV run is fully re-run ("re-run all jobs"), there could be multiple `backend-release` artifacts across attempts, built from the same SHA. The checks prevent a cross-commit mix-up but not an attempt mix-up. This is an edge case; normal operation doesn't hit it.
- **NB-2:** The storage accounts show no soft delete or versioning. The unchanged runbook line 153 refers to a "protected backup" that does not exist. Consider recording that as a limitation.
- **NB-3:** `validate_dev_run` raises `AttributeError` rather than `ValueError` when `head_repository` is null. It still fails safely.

## Limitations of this review

- I could not verify the pinned action SHAs, the GitHub run pages, Azure resource state or the reference repository myself. I relied on the supplied sanitized evidence.
- Rollback is implemented and its validation is unit-tested, but it has not been exercised live, because there was no prior release. This is acceptable for an initial deployment.

## Deployment vs App Store readiness

Even after BD-01 and BD-02 are resolved, approval would cover only the backend DEV/PROD deployment and pipelines. It would not cover iPhone or App Store readiness. Still separate: physical iPhone acceptance, Release `HIGHSCORE_API_BASE_URL` configuration, signing/distribution, and App Store moderation.

**Next step:** resolve BD-01 and BD-02, supply CTX-1 to CTX-3, then send a focused re-review packet with the updated evidence and manifest.
