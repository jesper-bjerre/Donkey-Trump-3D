# Backend App Service deployment and independent review — 2026-09-26

**Complete: DEV and PROD deployed; implementation/reviewer consensus reached.**
The owner requested both deployments, GitHub pipelines following existing actions,
Azure naming parity and reuse of the existing PROD plan. DEV also reuses its existing
plan. No plan was created or resized, and neither existing app was changed.
This record does not approve an iOS or App Store release.

## Delivered and deployed

| Environment | API origin | Existing plan | Storage |
|---|---|---|---|
| DEV | `https://donkeytrump-api-d.azurewebsites.net` | `asp-vejles-koder-d` (F1) | `donkeytrumpd` |
| PROD | `https://donkeytrump-api-p.azurewebsites.net` | `asp-vejles-koder-p` (B1) | `donkeytrumpp` |

DEV deploys on relevant `main` pushes. PROD manually promotes an artifact from a
successful main-branch DEV run after provenance and content checks. Both runtime
identities have only their own container's Blob data role, and separate OIDC
identities can deploy only to their own apps. Basic publishing and public/shared-key
storage access are disabled. See the [operating guide](../backend-deployment.md).

- [Backend CI: success](https://github.com/jesper-bjerre/Donkey-Trump-3D/actions/runs/36251496007).
- [DEV build/deploy/smoke: success](https://github.com/jesper-bjerre/Donkey-Trump-3D/actions/runs/36251495999).
- [PROD promotion/deploy/smoke: success](https://github.com/jesper-bjerre/Donkey-Trump-3D/actions/runs/36251740755).

Both run the package built from `db52f2b359945d5b1a4584f8fa7718509a14eca9`, SHA-256
`5a5a095217d4c38b96aaa801e05d3998fbde3382d14a3d6be77d045d28dfc2a3`.
Authenticated reads of each Azure app's active `SitePackages` ZIP confirmed its bytes
match that GitHub artifact. SCM `wwwroot/deployment.json` was not visible (404);
no mounted-filesystem claim is inferred from that unsuccessful check.

The subscription budget `donkeytrump-monthly-budget` tracks `Project=DonkeyTrump`
resources at DKK 80 net/month (100 with 25% VAT), with actual warnings at 50/75/100%
and a forecast warning at 90%. The recipient is only the signed-in owner, already
configured for the existing budget. Tokens and the address were never written into
repo evidence. Live readback and an idempotent rerun passed; no test email was sent.
Warnings are delayed notifications, not a hard spending cap.

## Validation actually performed

- Backend: 49 tests passed locally and in GitHub, including the real isolated
  Azurite 3.37.0 persistence/concurrency tests. No failures or skipped tests.
- Release validation: nine tests passed locally and in GitHub. Failed/foreign/non-main/
  wrong-workflow run selection, wrong commits, changed ZIPs and unsafe paths fail closed.
- Budget helper: three tests passed for currency/recipient rejection and correct
  VAT-adjusted amount, project scope and thresholds. Live provisioning/readback passed.
- actionlint 1.7.12 passed all three workflows. Python compilation, scoped whitespace
  checks and the changed documentation's local links passed.
- Both deployed APIs passed liveness, storage-backed GET, `no-store` and HTTPS redirect
  checks. PROD stayed empty; smoke checks did not publish fake PROD scores.
- DEV created one synthetic test row through the API, retained it after an app restart,
  deduplicated its identical submission and rejected a changed same-ID payload with 409.
  The intentionally synthetic row remains in DEV only.
- Anonymous storage access was denied. Actual runtime/configuration, role scopes,
  OIDC subjects, main-only environment policies, publishing controls and storage settings
  were read back from Azure/GitHub.
- Both plans retain capacity 1 and their original F1/B1 SKUs, now with two sites each.
  All four apps returned 200 in twelve later warm health checks. The existing PROD
  app's three responses took approximately 0.13–0.20 seconds.

PROD initially encountered a platform volume-remount failure and slow startup.
Azure recovered automatically, followed by three bounded smoke retries and success.
Initial shared-plan CPU rose to 99%. Later evidence about 32 minutes after successful
smoke showed a 20-minute range of 16–54% CPU (mean 26.1), against a pre-change hour of
10–41% (mean 18.92). Memory was 77–83%, versus 70–75% before. The earlier spike
coincided with app provisioning/container starts; exact process attribution is not
claimed. Shared memory headroom is an operational watch item, not a load-test pass.

Commands, observation windows, resource readbacks, hashes, run IDs, reference naming
and limitations are in [the sanitized acceptance evidence](backend-deployment-2026-09-26/evidence.json).

## Revision identity and preservation

- Base: `a47af91b5f6e9c9514613f7e55b3e593367116ab`.
- Deployed runtime/pipeline implementation: `db52f2b359945d5b1a4584f8fa7718509a14eca9`.
- [Round 1 manifest](backend-deployment-2026-09-26/candidate-manifest-r1.json): 12 files.
  Its two post-commit file snapshots are preserved as
  [original evidence](backend-deployment-2026-09-26/evidence-r1.json) and the
  [archived guide](backend-deployment-2026-09-26/deployment-guide-r1.txt).
- [Approved round 2 manifest](backend-deployment-2026-09-26/candidate-manifest-r2.json):
  14 source/document/evidence files, including the new operator budget helper/tests.
  Hashes were checked again after approval with no differences.
- The final follow-up commit contains documentation, review evidence and the separately
  executed operator budget helper/tests. It uses `[skip ci]` to avoid an unnecessary
  API rebuild/redeployment. All runtime files, workflow files, release helpers, original
  provisioning code and the environment manifest are byte-identical to deployed
  `db52f2b`; `git diff --exit-code` verified this. The new helper's focused checks and
  actual Azure execution are recorded above.
- Unrelated App Store clarification changes in `specs/002-app-store-release` were
  preserved and excluded from deployment commits and review scope.

Review records themselves are excluded from candidate identity as required by
AGENTS.md; the acceptance evidence remains included. Source and evidence were frozen
during each review round. Commits needed to activate the pipelines were not created
merely to obtain a review identity.

## Independent configuration and consensus

Lead: OpenAI Codex. Exact underlying model ID and effective reasoning setting were
not exposed by this session and are not invented.

Reviewer: Anthropic, Claude Code **2.1.283**, exact **`claude-opus-5-5`**, explicit
**`high`** effort in both CLI flag and environment. The reviewer did not implement
any part of this task. Safe mode, no tools, no MCP servers and no session persistence
were used from an isolated temporary directory with governing instructions supplied
in the packet.

Fresh plain-text and JSON probes returned `REVIEW_ROUTE_OK`, exit 0 and no effort-cap
warning. The JSON probe and both reviews contained actual assistant responses and
nonzero first-party provider usage for the canonical model. The provider response
does not separately attest effective effort; the explicit settings and warning
checks are the evidence available. [Sanitized configuration/result metadata](backend-deployment-2026-09-26/review-metadata.json)
records both review sessions; no hidden reasoning or raw debug logs are committed.

| Finding | Lead/reviewer disposition |
|---|---|
| BD-01: shared-plan CPU had not yet settled in initial evidence | Confirmed evidence gap. Added a later window and repeated existing-app checks; reviewer explicitly resolved it. |
| BD-02: missing budget detection and removed runbook prerequisite | Confirmed. Provisioned/read back project budget, added tested operator helper and restored operational requirements; reviewer explicitly resolved it. |
| CTX-1: deployed vs reviewed revision | Clarified exact runtime/workflow equality and separately hashed later docs/helper changes; satisfied. |
| CTX-2: reference naming | Supplied live storage/group/identity names and documented meaningful OIDC names; satisfied. |
| CTX-3: final records committed | Existing record and final evidence/commit process confirmed; satisfied. |

[Round 1](backend-deployment-2026-09-26/review-1.md) withheld approval for the two
important findings. [Focused round 2](backend-deployment-2026-09-26/review-2.md)
returned **APPROVED**, with both findings resolved and no new material issues.
**Lead agreement:** I agree with the reviewer's final verdict and dispositions.
The authorized backend deployment and pipelines satisfy the applicable requirements;
no important in-scope implementation finding remains unresolved. Consensus is complete.

Non-blocking notes remain explicit: reduced shared memory headroom; no live rollback
exercise because this was the first release; no PROD write test; no sustained-load
validation of shared Azure capacity; no automated Blob backup/versioning; email
notification delivery not tested; per-meter attribution of App Service egress to a
tagged app rather than the untagged shared plan is not yet confirmed. The original
subscription-wide budget remains in place. The helper's conflict/readback paths were
reviewed, with its successful update path also exercised live.

The earlier budget was created at subscription scope with a storage-group filter and
updated in place at the same budget URI; no resource-group budget was created. A
post-review read-only listing checked for the optional duplicate-budget concern.
This additional check did not change the approved candidate.

The iPhone production endpoint, physical-device acceptance, moderation, signing and
App Store submission remain separate release work.
