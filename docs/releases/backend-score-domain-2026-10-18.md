# Backend score-domain deployment — 2026-10-18

Completed UTC: 2026-10-18T16:53:12.808972+00:00. **DEV and PROD deployed.**

The owner requested backend deployment to PROD. Existing owner policy prohibits automatic tests and smoke tests; none were run or triggered. This feature is exempt from Claude Code/substitute review. Lead: Codex (OpenAI), exact runtime model/reasoning metadata unavailable. This is operational deployment evidence, not a new independent review or functional test verdict.

## Source and immutable artifact

- Source: clean main at `dc26816631a9d4656e37a7711c43ba33fd0a4b86`, frozen with git archive before deployment records were written.
- .NET SDK10.0.401, restore plus Release publish, UseAppHost=false and explicit SourceRevisionId. No test project/runner was invoked.
- ZIP SHA-256: `3a8f3fa6c93cafdb6dc55f2c8d78146ecabfca3d1155aeaea03d4b5835d3b88f`.
- API assembly SHA-256: `c7c0e0891ea0b8b475b06ae14c05bf22ff759ba0412cce3ca55504abe14a285c`.
- 29 packaged files, embedded source identity and schema1/2-read/schema2-write contract checked using the existing package/verify subcommands. No smoke subcommand.
- Retained immutable package: `.build/backend-releases/dc26816631a9d4656e37a7711c43ba33fd0a4b86-20261018/app.zip`, with release.json and per-file hashes. It is outside /tmp and ignored by Git. [Artifact metadata](backend-score-domain-2026-10-18/artifact.json).

## Deployment route and result

Current GitHub DEV/PROD workflows execute tests/smoke. The latest previously successful DEV artifact did not contain the five-point change. Following the existing [manual no-tests deployment precedent](app-store/backend-redeploy-2026-09-28.md), this operation used Azure CLI2.88.0 directly: same ZIP to DEV, wait for successful startup, verify retained package again, then exact same ZIP to PROD. CI definitions and requirements were not modified. No GitHub workflow success is claimed for this release.

Both commands used existing subscription/resource mapping from infra/backend-environments.json, `az webapp deploy --type zip --clean true --restart true --timeout 600000`. Only the two API apps restarted. No shared plan resize/restart, provisioning, app setting or credential change.

| Environment | App | Azure deployment ID | Azure startup status | Successful / failed instances |
| --- | --- | --- | --- | --- |
| DEV | donkeytrump-api-d | 1f37cf3f-10b9-4953-8ff8-9b5fa8ed45b6 | RuntimeSuccessful | 1 / 0 |
| PROD | donkeytrump-api-p | ab775f79-fd1b-49d8-9c50-8d1897757f52 | RuntimeSuccessful | 1 / 0 |

Exact responses: [DEV](backend-score-domain-2026-10-18/dev-deployment.json), [PROD](backend-score-domain-2026-10-18/prod-deployment.json).

## Actual PROD artifact and admin reader

Authenticated Azure operator TCP tunnel plus SSH inspected the actual app worker filesystem. WEBSITE_SITE_NAME matched donkeytrump-api-p, deployment.json matched the source commit, and **all29 artifact files** matched the retained ZIP hashes. This addresses the earlier project incident where pipeline success alone did not establish the mounted revision. [Worker artifact identity](backend-score-domain-2026-10-18/prod-artifact-inspection.json).

Initial SCM filesystem metadata access could not establish identity (VFS404 / missing files in the SCM context); direct az webapp ssh returned without a usable shell. Neither was treated as evidence of the worker contents. The supported TCP tunnel gave the conclusive worker inspection. Authentication material remained in process memory and is not in records/logs/commands.

The separately installed manual admin/current symlink also needed the widened reader before any five-point score could be stored. The existing installer installed the same published DLL/dependencies/wrapper under its immutable SHA directory and switched the existing current link. The previous revision was preserved. Current helper DLL hash matches the deployed API. No entry/rename/initialize command or highscore write was executed. [Manual reader update](backend-score-domain-2026-10-18/prod-manual-admin-update.json).

## Data, recovery and operational limits

The package widens exact score validation to multiples of5 with the existing0…2,147,483,600 bound. No direct Blob edits, migrations, deletions, rescores, synthetic submissions or POST replays were performed. Historical entries remain governed by the existing unchanged store/CAS/moderation logic.

The retained package is the widened-reader recovery artifact for this change. Once a non-hundred score persists, do not deploy an old strict100 validator over the aggregate. Reuse a retained widened-reader package; never round/delete data to fit an older binary. Old strict iOS decoders remain incompatible with mixed lists; iOS distribution is separate and this operation does not publish an app.

Azure ARM reports the API and neighboring byensgaader-api-p Running on the original asp-vejles-koder-p plan. PROD remains HTTPS-only, DOTNETCORE|10.0, AlwaysOn with its existing platform health path. [App metadata](backend-score-domain-2026-10-18/post-deployment-app-state.json).

Read-only platform metrics for the15-minute deployment window: CPU average32.27%, maximum89%, last84%; memory average78.53%, maximum83%, last83%. This includes startup activity, is not a sustained-load/capacity test and does not prove functional availability. [Metrics](backend-score-domain-2026-10-18/prod-plan-metrics.json).

No unit/integration/UI/contract/smoke tests or functional public API requests were run. No highscore save/read round-trip, client publication or iPhone acceptance is claimed. Azure startup and exact worker file identity are confirmed. Deployment records remain local/uncommitted; no additional source commit/push was performed.
