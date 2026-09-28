# Single-API backend rollout — 2026-09-28

Status: locally checked and independently approved; new rollout not yet deployed.
Owner authorized DEV and PROD deployment and confirmed the app is unreleased,
with only the owner testing it. Evolve `/api/v1` in place. The iPhone build must
be rebuilt from the updated local source; no older client compatibility is promised.

## Readiness evidence

- Base `8a68e5b155b07b16af57382443280db5e818be0d`; review candidate is identified by a SHA-256 content manifest, not a fabricated commit.
- Backend: 106 passed, 0 failed/skipped against real loopback Azurite. Pipeline: 11 passed. Full owned local moderation/migration smoke passed. The isolated deployment worktree repeated these checks successfully, proving it does not require unrelated App Store WIP.
- iPhone 13 simulator: 8 focused wire/credential/moderation tests passed. Full app/distribution/physical acceptance remains separate and unfinished.
- Public pages now pass anonymous HTML checks with and without trailing slashes; removed a redirect loop found by those tests.
- DEV: conclusive in-container MI metadata read, schema1, one existing entry, zero reports/guards; preserve it during conversion.
- PROD: successful in-container MI container listing, zero objects/versions/deleted objects and target absent. Old backend previously returned synthesized ten-entry projection with revision `empty`. A read-only first-provisioning preview passed. No provision/reset/write has occurred yet. Explicit initialize may create the original three-field schema1 document with If-None-Match, allowing the currently deployed backend to keep reading it. This is first provisioning of the unused store, not recovery of missing data.
- PROD storage: soft delete disabled; versioning, container retention and restore unset. No storage policy changed.
- Existing PROD plan `asp-vejles-koder-p`, B1, capacity1; app `donkeytrump-api-p`, one worker, Always On, HTTPS, DOTNETCORE|10.0. No tier/scale/shared-plan change. Last observed hour: CPU31.27% average/97% peak, memory80.05% average/84% peak. This is owner-only test traffic, not a public-launch load acceptance. Check game and neighboring app availability after rollout.
- Before: game DEV/PROD `/health/live` and neighboring byensgaader DEV/PROD `/health` all HTTP200.

## Supported operator access

`az webapp ssh` returned success without an actual usable shell. A supported
`az webapp create-remote-connection` tunnel plus standard SSH succeeded. Keep
one SSH ControlMaster connection for sequential commands; repeated websocket
reconnections sometimes failed502 or timed out. Use a new tunnel/connection
after an app restart. Source the normal login profile in the remote shell so
managed identity configuration is available; never print/export raw environment,
credentials or tokens. Human CLI authentication opens the tunnel only. All Blob
operations above ran inside the target app with its managed identity.

Temporary diagnostic/published assemblies were placed under the app container's
`/tmp`, outside the live deployment directory. The diagnostic output contained
only schema/count/ETag or container object counts, never names, secrets or snapshots.

## Remaining rollout steps

Independent consensus → explicit PROD first provisioning → verified pipeline
artifact to DEV with game-only write quiescence → MI conversion/readback,
backup cleanup and maintenance off → DEV owned publication/report/operator/
receipt smoke → exact immutable artifact to PROD → conversion/readback and
maintenance off → live read/pages/auth/no-v2 checks and neighbor availability.
No App Store submission or release is included in this backend deployment.
