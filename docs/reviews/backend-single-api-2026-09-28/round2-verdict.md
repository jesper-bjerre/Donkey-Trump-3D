# Focused re-review: backend moderation rollout (R1–R8 plus Docker supplement)

## Verdict: **APPROVE**

This approval covers the local backend implementation and pipeline. The deployment gates listed below still apply to the operator rollout; they are not code blockers. I found no new material defects.

## Dispositions

| ID | Prior severity | Disposition | Basis |
|---|---|---|---|
| R1 | HIGH | **Resolved** | See below |
| R2 | MEDIUM | **Resolved** | See below |
| R3 | MEDIUM (deployment gate) | **Accepted**, gate remains open until the verification list below passes | See below |
| R4 | LOW | Accepted, non-blocking | Agreed: the backup is a validated, field-preserving reserialization, and restoring to the old schema is forbidden. |
| R5 | LOW | Accepted as a recorded operational limitation | Leaving maintenance requires a verified-absent backup. Any failed conversion goes to `inspect`/readback first, never a blind retry. |
| R6 | LOW | Accepted, non-blocking | Mis-categorized routes only; no private data is exposed. |
| R7 | LOW | Accepted, non-blocking | The rejection is fail-closed. There is no mutation and no ambiguous acknowledgement. |
| R8 | INFO | Acknowledged | The CI publish step exists at `backend-deploy-dev.yml:38`. Recovery is `inspect` and then a retry with the expected ETag. |

### R1 — Resolved

- `backend-deploy-dev.yml:71-78` and `backend-deploy-prod.yml:61-68` now only deploy, read the hostname and run the GET smoke. There is no `appsettings set` in either workflow, so deploy, promotion and rollback leave the existing setting unchanged.
- Leaving writes unprotected between deploy and migration is safe. The schema-1 guard does that job, and `ModerationMigrationTests.cs:109` shows GET still serves schema 1, so the smoke check correctly passes on unmigrated storage.

### R2 — Resolved

**Store-level test (`ModerationMigrationTests.cs:91-110`):**
- With `Maintenance=false` and a schema-1 document, both `PublishAsync` and `ReportAsync` return `service_maintenance`.
- The PUT counter hooks `Before`, so it counts attempted uploads, not just completed ones. That is stronger than what I asked for.
- The ETag is unchanged and the read still returns 10 entries.
- The test is not vacuous. If the seeded document were schema 2, the publish would succeed and the test would fail.

**HTTP test (`ModerationEndpointTests.cs:34-56`):**
- It covers both POST routes with a canonical credential and checks for 503, `no-store`, `code=service_maintenance`, zero PUTs and an unchanged ETag.
- The 503 comes from the store guard, not from a factory-level maintenance flag. The test at lines 12-32 in the same file gets 201 through the same factory path.

### R3 — Accepted

**Sequence:**
- Running the reviewed DLL out-of-band in operator mode before the HTTP deploy removes the red-pipeline step that I previously said was unavoidable.
- `initialize` uses `IfNoneMatch=*` and refuses on any current, deleted or versioned Blob (tested at `ModerationMigrationTests.cs:73-88`), so it cannot overwrite existing data.
- If the still-live old writer creates the Blob first, `initialize` fails with `storage_not_empty` and nothing is lost.

**Evidence that PROD is empty and unused** now comes from outside the tool, which is what I required:
- the release record,
- the Sep 28 hotfix record,
- the owner's statement,
- the managed-identity listing of zero objects, versions and deleted Blobs.

**Accuracy caveat on "old writer readability":**
- The supplied test only proves that the *new* code reads the initialized payload as schema 1 (line 84).
- Whether the base artifact can read it rests on the lead's statement, not on a test in this packet.
- This does not affect data integrity. At worst, old-code reads keep failing until the deploy, which is today's state. The rollout record should state this as reported evidence only.

**Verification still required before reporting PROD writes as live:**
1. Enable maintenance and confirm the restart completed.
2. Run `inspect` and record the ETag.
3. Run `migrate --apply` with that ETag.
4. Confirm schema 2 and that the backup is absent.
5. Clear maintenance.
6. Run the GET smoke.
7. Make a credentialed POST with a test-owned result and confirm it succeeds.

**Why step 7 matters:**
- Because R1 now preserves the existing setting, the GET-only pipeline smoke cannot tell whether writes are enabled.
- Constitution V reporting must use the result of step 7, not the green workflow.

## Supplement: Dockerfile and dockerignore

**Dockerfile:**
- `Dockerfile:5` copies the file to `/source/infra/backend-environments.json`, which keeps the repo-root-relative layout.
- `restore` (line 8) runs before the file is needed, and `publish` (line 10) runs after it is present.

**Dockerfile.dockerignore:**
- `!infra/` (line 3) re-includes the whole `infra/` directory in the build context, so the narrower line 4 is redundant.
- This matches the existing `!src/` pattern.
- Only the one file is copied into the image, so this does not matter.

**Deploy path:** the deploy uses a ZIP, not Docker, so this change does not affect the rollout.

## Limitations

- I reviewed the supplied text only and ran nothing. The 109/0/0 backend, 11 pipeline, migration-smoke, Swift, publish and App Service operator-mode results are the lead's reported evidence.
- The csproj text is not in this packet. I cannot re-confirm that its embed path resolves under `/source`; that relies on the unchanged prior source and the successful local publish. The container build was not run.
- I cannot verify:
  - App Service SSH environment propagation after settings changes;
  - that operator mode starts no hosted services;
  - the listing permissions for deleted and versioned Blobs.
- My own statement of model identity is not verification under AGENTS.md.