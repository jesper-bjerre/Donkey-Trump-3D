# Independent review: PROD v2 highscore read hotfix

**Reviewer:** Claude Opus 5.5 (`claude-opus-5-5`, Anthropic), high effort, read-only. I did not run any tools. Everything below comes from reading the supplied source and evidence.

**Implementer:** OpenAI Codex GPT-6 (cross-vendor).

**Candidate:** base `94dc44d8…` plus the six-file manifest as supplied, unchanged.

## Verdict: APPROVE

I found no blocking correctness, security or regression problems. The change is ready for the planned DEV CI run and the promotion of the same ZIP to PROD. Deployed behaviour is not verified until the planned post-deploy checks pass.

## Acceptance trace (my own source analysis)

- **Same snapshot:** `HighscoreEndpoints.cs:12-17` maps one shared handler to both GET routes. Both call the same `store.ReadAsync`, use the same `HighscoreJson.Options` and have the same error mapping. No v2-specific code exists that could drift.
- **Same rate limit:** both routes use the `highscore-reads` policy.
  - `AddTokenBucketLimiter` uses a single fixed partition per policy name, so v1 and v2 share one bucket.
  - Total read capacity is therefore unchanged, not doubled.
  - `BothReadVersionsShareOneRateLimitBucket` (`HighscoreBoundaryTests.cs:35-46`) checks this.
- **Same no-store:** `Program.cs:39` extends the existing path check. `PathString` equality is case-insensitive, the same as routing. It applies before the rate limiter (`Program.cs:47`), so 429 and 500 responses on v2 also get `no-store`. Tests cover both cases.
- **No new writes:**
  - No v2 POST is mapped, so `POST /api/v2/highscores` gets routing's 405 without touching storage (`HighscoreEndpointTests.cs:35-41`).
  - Nothing proxies to v1 POST.
  - No blob, schema or data migration is involved.
  - `/api/v2/highscore-reports` stays unmapped.
- **v1 unchanged:** the v1 GET and POST semantics are identical to before.
- **iOS client compatibility:**
  - The app GETs `https://donkeytrump-api-p.azurewebsites.net/api/v2/highscores` with no redirect, so the exact `response.url` check passes.
  - `Results.Json` returns `application/json; charset=utf-8`, and the client's `mimeType` check passes on that.
  - The exact key sets (`entries`, `fetchedAtUtc`, `revision`; row keys `displayName`, `entryId`, `rank`, `score`) and the `.fffZ` timestamp are asserted for both paths (`HighscoreEndpointTests.cs:29-33`).
  - GET sends no `Authorization` header.
- **Smoke check:** `backend-release.py:76-82` now requires both routes to return 200 with `no-store` and a bounded snapshot.
  - Because `HTTPError` is a subclass of `URLError`, a v2 404 fails promotion.
  - `SmokeVersionTests` correctly covers both branches, and its mock redirect satisfies the HTTPS-redirect check.

## Non-blocking findings (no change required before deploy)

- **N1 – Low – `HighscoreDiagnostics.cs:8`:** the route is hard-coded as `/api/v1/highscores`.
  - v2 reads (and v2 405s) are therefore logged as v1.
  - Impact: logs cannot separate installed-app v2 traffic from legacy v1 traffic, for example when deciding whether v1 can be retired.
  - No privacy or correctness impact. It can be fixed later by passing the matched route.
- **N2 – Low – smoke check versus rollback (`backend-deploy-prod.yml:61-72`, `backend-release.py:76`):**
  - PROD rollback runs the smoke check from the current `main` after `az webapp deploy`.
  - Rolling back to a pre-hotfix artifact (for example `66812f7`'s DEV run) would deploy successfully, then fail the v2 smoke check, marking the rollback run red.
  - That red status is expected: such an artifact re-breaks the app's reads.
  - Recommend noting this in the rollback runbook so it isn't misread during an incident. Separately, DEV artifacts are only retained for 30 days.
- **N3 – Low – evidence consistency (`red.log`):**
  - The failure reported for `BothReadVersionsShareOneRateLimitBucket` is `Assert.NotEmpty() … empty` at line 43.
  - The manifest text at lines 41-44 contains no `NotEmpty` assertion. The expected red failure is `Assert.Single` at line 42.
  - The red run may have used an earlier draft of this test.
  - This does not block, because main DEV CI reruns both `dotnet test` and `backend-release-tests.py` on the exact commit. Record that CI result as the authoritative test evidence rather than the local green log alone.
- **N4 – Info, out of scope:** the installed app's POST to v2 gets a 405 with an empty body.
  - `URLSessionHighscoreService.swift:61-67` maps that to `.unconfirmed`, as it already does for today's 404.
  - This is not a regression, and no write can happen.
  - Submission and reporting remain unavailable until the separately authorized migration, as the scope states.

## Limitations

- **Not supplied:** `HighscoreValidation`, `HighscoreStarters`, `HighscoreSnapshot` (C#) and `HighscoreJson`.
  - I relied on the tests plus the stated contract equivalence for serialization details.
  - I also could not confirm that C# `NormalizeName` matches Swift `HighscoreRules.name` (`HighscoreModels.swift:6-14`).
  - Any single stored PROD row that fails the Swift validation would reject the whole list on the phone.
  - **Recommended post-deploy check** (no phone needed, no POST): validate the live v2 GET body against the Swift rules. These are ≤100 rows, unique non-zero UUIDs, ranks 1..N, non-increasing scores that are multiples of 100, Swift-normalized names, and a `Z` timestamp with fractional seconds. Keep the body local and unlogged.
- **Attributed to the lead:** all test runs (red, green 63/63, pipeline 10/10) and all live observations (PROD v2 404, v1 200 with 10 entries, health checks).
- **Not yet done:** DEV CI, PROD promotion, post-deploy checks of both routes with `no-store` and neighbor health, and the owner's physical-device test.
- **Scope:** this approval covers restoring read availability only. It says nothing about App Store readiness or the pending moderation and write migration.
