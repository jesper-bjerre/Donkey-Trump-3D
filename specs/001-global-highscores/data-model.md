# Data model: Global Top 100 Highscores

Design contract, 2026-09-26. No database or persistence implementation is created by this document. See [HTTP schemas](contracts/highscores.openapi.yaml) for wire types and [iOS flow](contracts/ios-flow.md) for presentation transitions.

## CompletedRun — iOS memory

| Field | Type | Rule |
|---|---|---|
| `id` | UUID | Fresh non-zero random ID for every new game and restart |
| `score` | Swift integer | Final run score, not personal best |
| `levelReached` | Swift integer | One-based final level |

`GameSession` owns the active run ID. It creates an immutable, Equatable/Sendable completion only after the final life is lost. Retain that value throughout Game Over, include it in HUD equality and clear it on new game/title. Rescues and ordinary life loss do not create a completion. The core never knows HTTP, storage or display names. Automation/demo modes are ineligible for publication.

The publication flow owns this snapshot until dismissed, completed or failed. It is never persisted as pending work. A score outside the publication contract is reported as invalid without affecting the saved local personal best.

## Submission — request and canonical value

| Field | Wire type | Validation |
|---|---|---|
| `submissionId` | UUID string | Non-zero UUID; canonicalize to lowercase hyphenated form |
| `displayName` | string | See normalization below |
| `score` | int32 | 0–2,147,483,600 inclusive; multiple of 100 |
| `levelReached` | int32 | 1–2,147,483,647 inclusive |

Require all four fields, valid JSON object, JSON numbers rather than numeric strings, and `application/json`. Reject unknown fields, including client-supplied rank/sequence/timestamp. Bound the received body to 4,096 bytes, including chunked input, before materializing it. Use explicit validation so missing integers cannot silently become valid zero scores.

Name normalization is deterministic: reject control characters (Unicode category Cc) and line/paragraph separators (Zl/Zp) anywhere, normalize to NFC, trim surrounding Unicode space separators (Zs), then require 1–20 extended grapheme clusters and at most 256 encoded UTF-8 bytes. Reject empty names and names containing only whitespace/formatting marks. Preserve internal spaces, punctuation, case, Danish letters and printable emoji; no case folding or name uniqueness. Combining/emoji sequences count as perceived characters rather than UTF-16 units. Shared Swift/.NET fixtures cover `Løkke`, decomposed accents, emoji sequences, 20/21 characters, multiline and invisible-only input. Backend validation is authoritative.

Canonical payload equality compares normalized name, score and level for the same run ID. Repeating a currently ranked ID with identical canonical data returns its current rank; changed data returns 409. Two different runs with the same name and score remain separate entries.

## LeaderboardDocument — private blob

| Field | Type | Invariant |
|---|---|---|
| `schemaVersion` | integer | Exactly 1; unknown versions fail closed |
| `nextSequence` | positive int64 | Next assignable tie sequence; starts at 1 and exceeds every stored sequence |
| `entries` | array of StoredEntry | 0–100, sorted by score descending then sequence ascending |

The blob is private `highscores/global-v1.json`. It contains no account or device identity, IP address, request log or unbounded receipt archive. Its full UTF-8 document must fit 256 KiB. Read bounded content with its ETag from one storage response. Invalid fields, duplicate IDs/sequences, unsorted entries, excessive size or overflow make it unavailable, never an empty replacement.

### StoredEntry

| Field | Type | Rule |
|---|---|---|
| `submissionId` | UUID | Unique within the document |
| `displayName` | string | Canonical validated name |
| `score` | int32 | Validated score |
| `levelReached` | int32 | Validated level, private supporting data |
| `sequence` | positive int64 | Unique server-assigned successful-save order |
| `acceptedAtUtc` | UTC timestamp | Server clock; informational, not used to break ties |

The sequence counter belongs to the same conditional write as the entry. A losing attempt does not consume a persisted sequence; its next attempt takes a sequence from the newly read document. Removing the lowest-ranked entry never resets the counter. There is no scheduled pruning, reset, update or delete endpoint in v1.

### Conditional update lifecycle

1. Validate/canonicalize input before storage. Read a valid document and matching ETag. Only `BlobNotFound` in an existing container produces a virtual empty document with sequence 1; a missing container is an error.
2. If the ID exists, compare the canonical payload and return current ranked snapshot or 409 without a write.
3. If the list is full and the candidate score is <= the last score, return `notQualified` and the read snapshot. This check is authoritative at that read; it reserves nothing.
4. Otherwise build a new candidate with the next sequence and server timestamp, sort, truncate to 100 and increment `nextSequence`. Validate size and overflow before attempting upload.
5. Atomically upload the candidate using `If-Match` for an existing document or `If-None-Match: *` for first creation. Return that exact candidate and the write response's ETag on success.
6. On a recognized precondition race, reread/recompute within five total write attempts and the six-second deadline, with 25–100 ms random backoff. Do not reuse the old candidate or assign rank before this process finishes.
7. Any ambiguous write failure ends the request as `submission_unconfirmed`, with no further write. A save may still have committed. No storage/SDK retry is permitted after such a failure.

The all-time cutoff never decreases under these v1 operations. Consequently an evicted ID with the same score cannot newly qualify. Changed payloads for IDs no longer stored cannot be detected: there is deliberately no full idempotency-history guarantee. The API guarantees at most one current entry per ID, not an indefinitely replayable historical response.

## Public snapshot and submission outcome

| Entity/field | Meaning |
|---|---|
| `entries[]` | Public rows `{ entryId, rank, displayName, score }`; no private sequence or level |
| `entryId` | Same UUID as the stored run; UI identity and highlight target |
| `rank` | Contiguous index starting at 1, derived per snapshot |
| `revision` | Opaque ETag text for an existing document, or `empty` before first creation; not an integer or freshness guarantee |
| `fetchedAtUtc` | Server UTC timestamp when the snapshot was observed/constructed |
| `outcome` | POST only: `ranked` or `notQualified` |
| `entryId`, `rank` at POST root | Present only for `ranked`, matching one row in the returned snapshot |

Serialize timestamps as RFC 3339 UTC with milliseconds, for example `2026-09-26T12:00:00.000Z`. The client must explicitly support fractional seconds when decoding. A revision identifies observed content, not a promise that no other writer has since changed it. A new empty-list observation can share revision `empty` but have a different fetch time.

Successful responses are complete snapshots, not patches. They use `Cache-Control: no-store`; no HTTP 304 path is provided initially. Swift decoding ignores unknown response fields for additive evolution but verifies the known invariants: max 100, unique IDs, contiguous ranks, non-increasing scores, valid rows and consistent ranked entry/rank. Invalid response data becomes a service error and never establishes eligibility.

## Local ranking presentation state

| State | Data and allowed transitions |
|---|---|
| `closed` | No presentation; start/restart/title always allowed |
| `loading` | Source `title` or `completedRun(id)`, generation, deadline; controls remain active |
| `browsing` | Snapshot plus top/bottom/highlight anchor, optional stale marker and final score |
| `enteringName` | Immutable run and a fresh qualification observation; submit or cancel |
| `submitting` | One canonical payload in memory, generation/deadline; repeated taps disabled |
| `failed` | Readable error; optional stale browse-only snapshot; completed run's submission opportunity retired |

Track a separate terminal outcome for the current run: published, notQualified, cancelled or failed. A validation response for an editable name is the one non-terminal rejection: return to the form without automatic retry. Network/timeout/429/409/5xx errors retire publication. Read-only refresh never reopens a retired opportunity. On scene backgrounding, invalidate the generation and cancel in-flight work; returning to the app cannot resume the upload.

The coordinator owns tasks and an injectable deadline clock on the main actor. UI events and observed engine phase/run changes invalidate the request generation immediately; callbacks must match generation, source and run ID. A late result cannot update an active game's presentation even if underlying cancellation was ignored.

## Persistence and lifecycle boundary

Only the top-100 document and existing local best/preferences persist. Displaced scores have no application archive. There is no automatic resubmission, per-player profile, saved run or durable name draft. Operational backup/retention configuration does not imply an application-visible score history. Normal server restarts retain Blob data; unavailability never triggers deletion or reset.
