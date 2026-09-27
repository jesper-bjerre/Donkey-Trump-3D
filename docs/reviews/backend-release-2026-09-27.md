# Backend release to DEV and PROD — 2026-09-27

## Released version

The owner explicitly authorized release to both environments. Deployed source commit:
`66812f7b802b2d3a697a9db4eec0d6dcf4add7e0`.

The release includes the already-reviewed minimum-ten cartoon starter feature. A new or undersized ranking contains at least ten entries while retaining top 100. Existing players are preserved. GET remains read-only; no synthetic submission was sent to either environment during this release.

| Stage | GitHub run | Result |
|---|---|---|
| Backend CI | [36320605599](https://github.com/jesper-bjerre/Donkey-Trump-3D/actions/runs/36320605599) | Success |
| DEV deployment | [36320605615](https://github.com/jesper-bjerre/Donkey-Trump-3D/actions/runs/36320605615) | Success |
| PROD promotion | [36320852774](https://github.com/jesper-bjerre/Donkey-Trump-3D/actions/runs/36320852774) | Success |

DEV built and tested one immutable ZIP; PROD downloaded and promoted that exact artifact after live DEV verification. Local artifact verification also checked the package SHA and embedded source commit. SHA-256:
`9165d96e7e61e49a3fc567accf0b8102fb636e619e93eb67040b4f08a9884ab2`.

## Source and authorization boundaries

An isolated checkout applied only the previously approved starter-feature patch and its review evidence. Existing iOS/environment/UI/audio/loading and design-music work was not included in the release commit. The shared primary checkout was advanced to the published commit with a mixed index reset; all 106 pre-existing changed/untracked file contents were verified byte-for-byte unchanged. No forced push, shared-plan change, new infrastructure or storage rewrite was performed.

The [starter implementation review](highscore-starters-2026-09-27.md) already reached explicit cross-vendor consensus. All nine backend source/test/README content hashes in the release commit match that approved candidate. No new implementation or workflow changes were made in this release operation, so this is deployment evidence for that reviewed implementation, not a claim of a fresh independent deployment review. Historical review metadata and limitations remain unchanged.

## Executed validation

- Before pushing: release pipeline tests passed; `HighscoresTests__UseAzurite=true ~/.dotnet/dotnet test src/backend.tests -c Release` in the isolated checkout: **59 passed, zero failures/skips**, including real emulator concurrency/persistence.
- GitHub CI and DEV build/test steps passed. PROD verified successful main-branch DEV provenance, embedded commit and package digest before deployment.
- Both pipeline and local `backend-release.py smoke` checks passed: process liveness, authenticated storage-backed GET, `Cache-Control: no-store`, and HTTP-to-HTTPS redirect.
- DEV: **10 entries**, comprising the existing row plus nine starters. Prior row identity/name/score fingerprint remained present and the storage revision stayed unchanged.
- PROD: previously zero entries; now **10 starters**, scoring 100–1,000. Storage revision stayed unchanged, consistent with read-only virtual filling. Both lists have contiguous ranks and descending scores.
- All four apps subsequently returned HTTP 200: the new DEV/PROD APIs and the pre-existing `byensgaader-api-d`/`byensgaader-api-p` apps.
- PROD remains on the existing B1 plan, capacity 1. Before: sampled CPU mean 22.5%, max 36%; memory mean 76.35%, max 78%. After: CPU mean 23.83%, max 35%; memory mean 79.5%, max 80%. Windows differ and this is operational smoke/capacity observation, not a controlled load benchmark.

Initial read-only baseline requests encountered a DEV timeout, a transient PROD HTTP error, and transient existing-app network failures. Later pre-/post-release reads succeeded; final deployment gates and all final health checks passed. No settings changes or retries of player POSTs were used to hide those transient observations.

Scoped whitespace checks passed; the preserved historical `task.diff` contains intentional single-space blank context lines and was excluded from the new-file whitespace check. [Sanitized evidence](backend-release-2026-09-27/evidence.json) records run/step status, source hashes, package identity, read-only behavior checks and plan metrics without player names, raw bodies, tokens or credentials.

## Outcome and rollback

Both backends are released and healthy:
[DEV liveness](https://donkeytrump-api-d.azurewebsites.net/health/live),
[PROD liveness](https://donkeytrump-api-p.azurewebsites.net/health/live).

Previous successful DEV run `36251495999` is the rollback source if its retained package remains available and compatible. Use the existing manual PROD promotion workflow; never restore or clear the ranking blob for a code rollback. No iOS binary or App Store release was performed.
