# Independent review: backend moderation rollout (base `8a68e5b` + supplied manifest)

## Verdict: **BLOCK**

One pipeline defect (R1) needs fixing first, together with its supporting test (R2). The fix is small and makes the rollout simpler. I found no silent-data-loss, auth, receipt-ownership or private-field-leak defect in the backend source. After R1 and R2 are fixed, a focused re-review of only the two workflow diffs and the new test is enough.

## Blocking findings

### R1 — HIGH — Every deploy leaves writes and retention cleanup disabled while reporting success

**Locations:**
- `.github/workflows/backend-deploy-dev.yml:76-77`
- `.github/workflows/backend-deploy-prod.yml:66-67`
- Interacts with `src/backend/Highscores/BlobHighscoreStore.cs:82`, `src/backend/Moderation/ModerationRetentionWorker.cs:13` and `src/scripts/backend-release.py:86-93`

Both workflows set `Moderation__Maintenance=true` on every run. Nothing in the pipeline ever clears it. The smoke check only calls GET, so the run passes while writes are disabled.

**Reproduction (after the migration succeeds and the operator clears maintenance):**
1. Push any change under `src/backend/**` to `main`, or run a PROD promotion or rollback with `dev_run_id`.
2. The job sets maintenance and deploys. The smoke check prints PASS.
3. Every `POST /api/v1/highscores` and `POST /api/v1/highscore-reports` now returns 503 `service_maintenance`.
4. The retention worker skips its purge until someone clears the setting by hand.
5. For PROD first provisioning (R3), rerunning the workflow to get a green smoke turns maintenance back on.

**Requirements this breaks:**
- The contract uses maintenance only as a migration gate that is cleared and verified afterwards (steps 4 and 6).
- The privacy page (`privacy/index.html:11`) promises hourly cleanup while the service is available.
- Constitution V says reports must distinguish what is actually deployed.
- The user asked for simplicity; this adds a manual step to every release.

**Minimal fix:**
- Remove both `appsettings set` lines.
- Make "enable maintenance → quiesce → migrate → clear" an explicit operator step for this migration only.

**Why removing the step is safe:**
- `BlobHighscoreStore.cs:91` already rejects every non-migration mutation while the stored schema is 1. That covers publish, report, the worker and operator commands.
- The zip deploy restart terminates the old workers.
- So between deploy and migration there is no writer, with or without the flag.
- `migrate` still requires `Maintenance=true` (`ModerationMigration.cs:48`, `BlobHighscoreStore.cs:83`), so the operator sets it at migration time.

### R2 — MEDIUM — The schema-1 write guard has no test (required with R1)

**Location:** `BlobHighscoreStore.cs:91`, and its HTTP mapping.

No test covers publish or report against a schema-1 aggregate with `Maintenance=false`:
- `BlobHighscoreStoreTests` and the Azurite fixture always seed schema 2.
- `ModerationMigrationTests` only tests the maintenance paths.

After R1, this guard is the only thing preventing writes between deploy and migration. Constitution III and V require tests for changed persistence behaviour.

**Required tests:**
- With a schema-1 document and `Maintenance=false`, both `PublishAsync` and `ReportAsync` fail with `service_maintenance` and `Writes==0`.
- A credentialed HTTP POST returns 503 with `no-store` and the store is not modified.

## Deployment-phase gates (not code blockers)

### R3 — MEDIUM — PROD first provisioning cannot pass the PROD workflow as written

**Locations:**
- `BlobHighscoreStore.cs:38-39`: a missing Blob now yields 503 `storage_invalid`. This is correct fail-closed behaviour under Constitution III.
- `backend-release.py:81-99`: the smoke check makes 20 attempts, then fails.

If PROD really has no Blob (consistent with your `storage_invalid` observation), this happens:
- The deployed artifact's public GET returns 503.
- The workflow turns red after the deployment has already happened.
- `initialize` only exists in the new DLL, so it cannot run before the deploy.

`ModerationMigration.cs:21-22` and contract line 132 ("currently deployed writer can keep serving") suggest a different order than is actually possible.

**Required runbook ordering:**
1. Prove the container is empty and unused. `initialize` checks current, deleted, snapshot and version Blobs, but it cannot detect a Blob deleted while soft delete and versioning were off. The base artifact would have created the Blob on its first POST, so the evidence of "never used" must come from outside the tool.
2. Deploy. Record the failed smoke honestly.
3. Run `initialize`, first as a preview, then with `--apply`.
4. Run `inspect`.
5. Set maintenance and quiesce (per R1).
6. Run `migrate --apply`.
7. Clear maintenance.
8. Run `backend-release.py smoke` manually, plus a credentialed POST using a test-owned result, and check neighbour health.

### R8 — INFO — Tight time budget for operator commands

- Each operator command is a new process with a cold managed-identity token.
- `ApplyAsync` puts about 7 storage calls inside one 6-second budget (`ModerationMigration.cs:49`).
- This fits the initial timeout you observed.

Recovery is idempotent:
- The backup upload uses `IfNoneMatch`, and a retry accepts the existing backup only if checksum and source ETag match.
- Re-entry on schema 2 only deletes the backup.
- A stale ETag gets `revision_changed`.

Always re-run `inspect` after any failed `migrate` before retrying.

Also, CI never packages a real `dotnet publish` output. The first DEV build job checks that `storage-contract.json` was published, and fails before deploying if it is missing.

## Non-blocking findings

| ID | Severity | Location | Issue |
|---|---|---|---|
| R4 | LOW | `ModerationMigration.cs:59-66` | The backup is a re-serialization, not the original bytes. It adds empty moderation arrays that the old artifact would reject. No fields are lost (unknown members are disallowed and the round trip is validated), and restoring to the old artifact is forbidden anyway. |
| R5 | LOW | `ModerationRetentionWorker.cs:13-19`, `ModerationCommand.cs:80-81`, `BlobHighscoreStore.cs:82` | Backup expiry only runs after a successful non-maintenance mutation. `purge-expired` also cannot run during maintenance. A migration that fails and stays in maintenance keeps the backup past 24 hours until `migrate` is re-run. Step 6 must confirm the backup is gone. |
| R6 | LOW | `HighscoreDiagnostics.cs:8`, `Program.cs:59-65` | Report and receipt requests are logged under the route `/api/v1/highscores`, so report failures look like highscore failures in diagnostics. |
| R7 | LOW | `ModerationService.cs:37-39` | An idempotent replay of an already-ranked run still goes through `CheckGrowth(...,false)`. Within 64 KiB of the byte limit it returns `moderation_capacity` instead of the existing result. |

## Inspected with no findings

- **Uncertain writes:** every upload is conditional on `IfMatch`, with no create path. Only a 412 `ConditionNotMet` is retried (up to 5 attempts). Everything else after the write starts, including cancellation, maps to the operation's `*_unconfirmed` code.
- **Missing or corrupt storage:**
  - A missing Blob or invalid document is `storage_invalid`, with no write.
  - Duplicate JSON keys are rejected.
  - Schema 2 requires all moderation fields to be present.
  - Every write is validated before it is committed.
  - `initialize` uses `IfNoneMatch=*` and refuses if any Blob, including deleted or versioned ones, exists.
- **Bounds:** 1 MiB aggregate with a 64 KiB safety reserve; guard and report counts are limited; request bodies are at most 4096 bytes and depth 16.
- **Migration:**
  - Requires maintenance plus the expected ETag.
  - The backup's checksum is verified before conversion.
  - IDs, sequence and timestamps are preserved; reserved IDs become `starter` and all other rows `legacy`.
  - Readback compares against the expected converted bytes.
  - Re-entry on schema 2 never restores the backup.
- **Auth:**
  - The credential is parsed canonically (43-character base64url, 32 bytes, exact round trip). A duplicate or comma-joined header gets 401 before the body is read.
  - Receipts are scoped to the reporter's hash, and other reporters get 404.
  - Only reporter-owned spam receipts are returned.
- **Private fields:** the public DTOs contain only entry ID, rank, name and score, and receipts contain no hashes or names. ProblemDetails responses stay generic, and `Cache-Control: no-store` is set before rate limiting, so it also covers 401, 404 and 429.
- **Old routes:** the v2 routes are gone and there is no 426 path.
- **Capture:** capture routes fail startup validation outside the DEV site.
- **Promotion:** schema-1-only artifacts cannot be promoted.
- **iOS client:**
  - The Authorization header is sent only on POST and on the receipt GET.
  - A credential failure is thrown before any network request.
  - Redirects are refused.
  - Receipt validation matches the server's dispositions, including `alreadyPending` being omitted when false.

## Limitations

- I reviewed the supplied text only. I ran nothing and used no tools.
- All test, simulator and live results above are the lead's reported evidence.
- These Swift types were not supplied, so I did not inspect them: `HighscoreSnapshot.decoder/decode`, `HighscoreServiceError`, `HighscoreProblem`, and the app UI and error mapping.
- I also could not verify publish contents, App Service SSH environment behaviour, or listing permissions for deleted and versioned Blobs.
- The lead's model and effort are not exposed. My own statement of my model identity is not verification under AGENTS.md.
- Full App Store readiness and physical-device checks are outside this review, and I am not claiming them.