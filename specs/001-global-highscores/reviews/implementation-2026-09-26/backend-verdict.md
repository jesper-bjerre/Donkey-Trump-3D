# Backend implementation review: global highscores (Anthropic reviewer)

**Reviewer:** Claude Opus 5.5 (`claude-opus-5-5`), reasoning `high` as configured by the lead. Read-only; I did not take part in the implementation.

**Scope:** Backend candidate at digest `316a7f40…54f8`, Git base `e323551c`. Untracked sources were compared against the captured pre-edit base, not the Git commit. I inspected every file in the scoped manifest, plus the supplied governing artifacts and boundary contracts.

**Evidence status:** I ran no checks. All test, load and contract results below are the lead's executed evidence, taken as recorded.

## Verdict

**APPROVE. Consensus for the backend scope: no material unresolved findings.**

I found no correctness, security, data-integrity, regression or unmet-acceptance defect that blocks this scope. The observations below are non-blocking.

## Independent verification of the key obligations

| Obligation | Where it is enforced | Assessment |
|---|---|---|
| Conditional writes are enforced by storage (Constitution III, FR-009) | `BlobHighscoreStore.SubmitAsync:72-97` | Satisfied (details below) |
| Ambiguous save acknowledgements are reported honestly (FR-017, SC-005) | `SubmitAsync:82-98` | Satisfied |
| Storage never fails open into an empty list | `ReadDocument:23-39`, `HighscoreDocument.Validate` | Satisfied |
| Ranking and tie order (FR-001, FR-002, US2-2, US1-7, FR-016) | `HighscoreRanking.Evaluate` | Satisfied |
| Request boundary (data-model §Submission) | `HighscoreEndpoints` POST, `HighscoreValidation.Parse` | Satisfied |
| Name rules (FR-007) | `NormalizeName` | Satisfied |
| Public wire contract | `HighscoreContracts` | Satisfied |
| Configuration and security (Constitution IV) | `HighscoreOptions`, Dockerfile | Satisfied |
| Limits and diagnostics | `Program.cs`, `HighscoreDiagnostics` | Satisfied |

**Conditional writes.**
- Each attempt reads the document, then sends one Put Blob with `If-Match` set to the ETag from that same read, or `If-None-Match: *` when the blob does not yet exist.
- Retries happen only after a rejection that proves nothing was written: 412 `ConditionNotMet`, or 409 `BlobAlreadyExists` on first creation. Each retry rereads and recomputes; the old candidate is never reused.
- There are at most five write attempts and four backoffs of 25–100 ms, all inside a linked 6 s deadline.
- The SDK's own retries are disabled (`MaxRetries=0`, 2 s network timeout). No unconditional overwrite path exists.
- The sequence number is part of the same conditional write, so a losing attempt does not consume one.

**Ambiguous acknowledgements.**
- `uncertainWrite` is set immediately before the upload and cleared only on success or a recognized rejection.
- The `catch … when (uncertainWrite)` handler comes first, so a timeout, network loss, token failure or unrecognized status during a write always becomes `submission_unconfirmed`, never a retry or reread.
- A timeout during backoff after a recognized rejection correctly becomes `operation_timed_out`.

**Fail-closed storage.**
- Only a 404 with `BlobNotFound` produces the virtual empty document. `ContainerNotFound` and 403 become `service_unavailable`.
- The read is bounded by both the declared length and a streaming limit.
- Parsing is strict: required members, unmapped members disallowed, strict number handling.
- Validation covers schema version, duplicate IDs and sequences, `sequence < nextSequence`, sort order, NFC-canonical names, UTC timestamps and the 100-entry limit. Overflow is checked in `Evaluate`, and size is checked again before upload.

**Ranking.**
- A replay with identical data causes no write and keeps its original rank. Changed data for the same ID returns 409.
- On a full list, a score equal to or below the cutoff is `notQualified` without a write, so the earlier equal score keeps its place.
- Otherwise entries are ordered by score descending, then sequence ascending, and truncated to 100. A new entry above the cutoff can never be truncated out.
- `HighscoreResult.From` derives `ranked` or `notQualified` from the exact snapshot it returns.

**Request boundary.**
- Checks run in this order: content type (415), declared length (413), then a bounded streamed read of 4,096 bytes that also covers chunked bodies (413).
- Duplicate or unknown keys are rejected as malformed. Numeric strings are rejected.
- Missing fields produce field-keyed validation errors rather than silently becoming zero.
- Scores must be multiples of 100 from 0 to 2,147,483,600. Levels are 1 to int32 max. UUIDs must be non-zero and are emitted in lowercase canonical form.

**Name rules.**
- Controls and line/paragraph separators are rejected before normalization.
- The name is normalized to NFC and trimmed of Unicode space separators.
- Length is checked as 1–20 extended grapheme clusters (.NET 5+ `StringInfo` semantics) and at most 256 UTF-8 bytes.
- Names made only of whitespace or formatting characters are rejected.

**Public wire contract.**
- Public rows expose only `entryId`, `rank`, `displayName` and `score`. Sequence, level and timestamp stay private.
- `EntryId` and `Rank` are omitted for `notQualified` (null values are not written).
- Timestamps use millisecond RFC 3339 UTC. Responses carry `no-store`, including 429s, because the header middleware runs before the rate limiter.
- Problem Details responses carry `code`. No exception text reaches clients.

**Configuration and security.**
- Production requires an HTTPS, non-loopback service URI with no query or user-info, and uses a managed identity.
- The emulator is allowed only in Development/Test, only on loopback, and only for `/devstoreaccount1`.
- Timeouts and attempt counts can only be configured downward.
- The Development settings file is excluded from the Docker build context. The container runs as a non-root user.

**Limits and diagnostics.**
- Token buckets have no queue and return an integer `Retry-After`.
- Logs contain only the route, method, status, duration, CAS attempt number and a bounded error class. Azure SDK logging is disabled.

**Test coverage.**
- The test count checks out: 21 + 4 + 3 + 7 + 8 + 5 + 1 = 49, matching the recorded run.
- The 100-writer oracle is not vacuous. It excludes rejected writers, so any stray save would break the exact-match assertion. It also includes a real committed write whose acknowledgement was lost, on Azurite, and it asserts that progress was made.

## Non-blocking observations (no fix required for consensus)

- **N1 – Low, unverified:** Request bodies containing invalid UTF-8 inside a JSON string, or a lone escaped surrogate such as `"\uD800"`, may reach `JsonElement.GetString()` in `HighscoreValidation.Parse:45-46`. That call can throw `InvalidOperationException`, which the endpoint's catch-all turns into 500 `internal_error` instead of 400 `malformed_request`.
  - There is no storage effect and nothing leaks; the iOS client never sends such names.
  - Optional fix: catch `InvalidOperationException` around parsing, map it to `Malformed()`, and add a regression case.
- **N2 – Informational:** Removing `app.UseStatusCodePages()` changes the starter's behaviour. Unknown routes and 405 responses now return empty bodies rather than Problem Details. The README claim that relied on it was also removed, and no contract depends on it.
- **N3 – Evidence nuance:** In the k6 run, every write uses score 10000 against a container that starts empty. After about 100 writes, the remaining POSTs and the final 10-request burst take the no-write `notQualified` path.
  - The load summary is therefore valid latency and throughput evidence, not write-contention evidence.
  - Contention is separately and adequately covered by the deterministic CAS tests and the 100-writer Azurite oracle.
  - I read the k6 threshold values of `false` as "not crossed", which is consistent with 0 failed checks and a p95 of 5 ms.
- **N4 – Documented design limit:** The token buckets are per process and not per client, so one abusive client can exhaust the POST budget and cause 429s for legitimate players. The contract and README declare this deliberately ("process-wide", "not global abuse prevention"), and a failed publication degrades safely. This is not a defect against the agreed scope.

## Limitations

- These release gates remain unverified, as T054 permits:
  - a Docker build and run;
  - real Azure managed identity, RBAC and HTTPS ingress, and cold-start behaviour;
  - live-Azure 412 and 409 error codes;
  - a physical iPhone.
- The iOS client side of the boundary (decoding, acknowledgement handling, no replay) belongs to the separate iOS review. I assessed only the server half of that contract.
- I checked full shared-fixture row contents only through the lead's recorded cross-runtime test results. My own inspection covered the listed name and numeric cases.

No missing context prevents this conclusion.