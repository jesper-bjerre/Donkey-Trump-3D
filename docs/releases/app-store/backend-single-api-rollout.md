# Single-API backend rollout — 2026-09-28

Status: final artifact deployed and verified in DEV and PROD; maintenance disabled in both.
Owner authorized DEV and PROD deployment and confirmed the app is unreleased,
with only the owner testing it. Evolve `/api/v1` in place. The iPhone build must
be rebuilt from the updated local source; no older client compatibility is promised.

## Readiness evidence

- Base `8a68e5b155b07b16af57382443280db5e818be0d`; review candidate is identified by a SHA-256 content manifest, not a fabricated commit.
- Backend: 109 passed, 0 failed/skipped against real loopback Azurite. Pipeline: 11 passed. Full owned local moderation/migration smoke passed. The isolated deployment worktree repeated these checks successfully, proving it does not require unrelated App Store WIP.
- iPhone 13 simulator: 8 focused wire/credential/moderation tests passed. Full app/distribution/physical acceptance remains separate and unfinished.
- Public pages now pass anonymous HTML checks with and without trailing slashes; removed a redirect loop found by those tests.
- DEV: conclusive in-container MI metadata read, schema1, one existing entry, zero reports/guards; preserve it during conversion.
- PROD: successful in-container MI container listing, zero objects/versions/deleted objects and target absent. Old backend previously returned synthesized ten-entry projection with revision `empty`. A read-only first-provisioning preview passed. This was the preflight state. Explicit initialize subsequently created the original three-field schema1 document with If-None-Match, allowing the previous backend to keep reading it. This is first provisioning of the unused store, not recovery of missing data.
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

## Final artifact and deployment

Source `27aa8104de27c998526e5844e3264457ca9f1d7a`; same immutable ZIP promoted from DEV:
`eeaf2ab3a905202a31e0e8c45f956b344eb480f2e485547b027c2b8066efc79b`.
CI [36422957011](https://github.com/jesper-bjerre/Donkey-Trump-3D/actions/runs/36422957011),
DEV [36422957246](https://github.com/jesper-bjerre/Donkey-Trump-3D/actions/runs/36422957246),
PROD [36423489382](https://github.com/jesper-bjerre/Donkey-Trump-3D/actions/runs/36423489382)
all succeeded. Actual `/home/site/wwwroot` revision and all 29 artifact file hashes
match the ZIP in both environments; pipeline success alone was not accepted as proof.

DEV: actual published operator cold inspect and publication → report → acknowledge →
remove/block → private receipt → blocked publication smoke passed. Original rows were
preserved, test rows removed and minimum ten maintained. Maintenance is disabled.

PROD: actual published operator cold inspect passed before conversion. Schema1→2
conditional migration preserved all 11 public rows exactly. Independent in-container
MI listing afterward found one object, zero versions/deleted objects, target present:
the temporary backup is absent. Maintenance is disabled. Credentialed POST returned200/ranked; explicit cleanup and
readback restored the original ten rows. No test-owned rows remain.
Storage schema2 is internal; the public API remains exclusively `/api/v1`.

## Operational findings retained

- Earlier `b04ffe3` rollout went green while PROD still mounted the older `75cd632`
  package. Checking live deployment.json and endpoint behavior exposed it. A game-app
  stop/start loaded the selected package; neither shared plan nor neighboring app was
  changed. Final deployment identity is verified by all file hashes.
- Cold operator managed-identity startup exceeded the six-second data-operation budget.
  Reviewed repair `27aa810` acquires an in-memory MI token with a separate bounded
  startup deadline before data operations. Public requests retain their short deadline.
- App restart/configuration changes invalidate SSH connections and can cause transient
  unavailability. At resumption one public read returned operation_timed_out/503;
  subsequent read and migration preservation checks passed. Do not blindly replay writes.
- An early zero-point probe was accepted by the old runtime (a list below100 can accept
  zero points). Its owned ID was a74946cc-8030-44a6-a1de-a758cbc01ba7; published operator removal and readback passed.
- An interrupted first DEV operator smoke left owned row e00c2408-317f-44bc-aa3e-67d0366ad35f;
  it was explicitly removed and its receipt closed before the final successful smoke.
- The first read-only inventory helper timed out with cold MI; the final helper used
  the verified operator authentication startup and succeeded. This helper lists object
  counts only and never mutates storage. Migration ran from the published wwwroot DLL.
- Temporary alternative operator assemblies were removed. No diagnostic DLL was used
  as evidence that the deployed package itself worked.

No App Store submission, public-launch load acceptance or physical-device test is
included. Rebuild/reinstall the iPhone app from updated source to replace its older
v2 binary. Full App Store preparation remains a separate unfinished task.

## Final acceptance and limits

[Sanitized live evidence](../../reviews/backend-single-api-2026-09-28/final-public-checks.json)
confirms both environments: v1 GET200/no-store/minimum10, v2 GET404, support/privacy200
HTML, uncredentialed POST401, game and neighboring app health200. Actual management
settings report maintenance=false in both; the fresh PROD process also reported false.
PROD [write result](../../reviews/backend-single-api-2026-09-28/prod-final-live-result.json)
records one credentialed POST200/ranked. Its first operator cleanup failed; a public
read confirmed the row remained before explicit published-operator removal. Readback
proved both owned probes absent and original public rows unchanged. No POST replay.

PROD reads/CLI operations timed out during and shortly after the configuration recycle.
These failures are retained, not counted as passed checks. Subsequent complete public
checks passed, and three consecutive PROD reads returned200 in0.178/0.142/0.129 seconds.
Cold-start/overloaded-worker timeouts remain possible under the deliberate short request
budget; this finite smoke does not establish a production availability SLO. No capacity
increase or neighboring-app mutation was performed. Owner-only usage is unchanged.

Independent source review approved the unchanged deployed candidate; lead agrees and
R10's actual-artifact/cold-operator/migration/readback/cleanup gates are now satisfied.
Final data state is internal schema2 with ten public rows in each environment.
