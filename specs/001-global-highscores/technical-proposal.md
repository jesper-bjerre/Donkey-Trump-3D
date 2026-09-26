# Global highscores — technical proposal

Date: 2026-09-26. Proposed design accompanying [spec.md](spec.md). Only the ASP.NET Core starter project has been created; highscore endpoints, persistence and iOS integration are not implemented.

The completed [implementation plan](plan.md), [research](research.md) and [HTTP contract](contracts/highscores.openapi.yaml) now refine this initial proposal, including exact error-code handling, retry limits, validation bounds and deployment defaults. Those design artifacts take precedence where this proposal is less specific.

## Recommendation

Use one small ASP.NET Core application in `src/backend`, targeting .NET 10 LTS, with Minimal APIs and one private Azure block blob containing the top 100 results as JSON. The user requested ASP.NET, low cost, simplicity and concurrency control. Microsoft recommends Minimal APIs for new HTTP API projects; .NET 10 is the current LTS, supported through November 2028. Deploy the latest supported servicing patch. The installed SDK is 10.0.302 with runtime 10.0.10: sufficient to build the starter, but older than the currently published runtime patch. Sources: [API guidance](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/apis?view=aspnetcore-10.0), [.NET support policy](https://dotnet.microsoft.com/en-us/platform/support/policy).

Confirmed choices: anonymous play, client-reported scores, no deferred submissions after failure. Rank runs, allowing multiple entries per player/name. This does not claim to prevent fabricated scores.

## Small application structure

Keep a single deployable project, with endpoint definitions, request/response records, a pure ranking function and a small Blob-backed store. Inject the store and Azure client through built-in dependency injection. Add folders as responsibilities appear; no separate domain/application/infrastructure projects, database, message bus or distributed cache are needed.

- Use async Azure SDK calls, propagating cancellation plus an overall operation deadline. Reuse the Azure client through dependency injection.
- Bind storage settings through options and validate required settings at startup once persistence is implemented.
- Use built-in Problem Details for validation, rate-limit and service errors, excluding stack traces and credentials from production responses. The starter already configures Problem Details. [Microsoft error handling guidance](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/error-handling-api?view=aspnetcore-10.0).
- Require HTTPS at public ingress, bound request bodies, validate inputs and apply built-in submission rate limiting. Per-process rate limits are a basic safeguard, not a global limit across replicas. If needed later, enforce global abuse control at shared ingress.
- Log status, duration and contention counts, avoiding names, request bodies and secrets. Start with short log retention and a cost alert.
- Use a managed identity with narrowly scoped Blob permissions in Azure. Prefer `ManagedIdentityCredential` in production and a developer credential chain locally. Keep the container private; no storage key or write-capable SAS belongs in the iPhone app. [Azure SDK authentication guidance](https://learn.microsoft.com/en-us/dotnet/azure/sdk/authentication/best-practices).

## Storage and concurrency

Use a Standard general-purpose v2 account, Hot tier, LRS, with one private container and a blob such as `leaderboards/global-v1.json`. Only the backend accesses it. Hot suits this small, frequently read and rewritten object; cooler tiers trade lower capacity charges for higher access charges and minimum retention periods. [Azure access tiers](https://learn.microsoft.com/en-us/azure/storage/blobs/access-tiers-overview).

| Document field | Purpose |
|---|---|
| `schemaVersion` | Deliberate parsing and future migration |
| `nextSequence` | Monotonic server-owned ordering for equal scores |
| `entries` | At most 100 records with `submissionId`, `displayName`, `score`, `levelReached`, `sequence`, `acceptedAtUtc` |

Sort by score descending, then sequence ascending; derive rank from array position. Store no historical archive or growing request-receipt collection.

Every update uses compare-and-swap:

1. Read JSON and its ETag together.
2. If the run is already ranked, identical data returns its existing position without a write; changed data returns a conflict.
3. Re-evaluate qualification. A full list whose last score is greater than or equal to the candidate returns `notQualified` and that snapshot without writing.
4. Assign the next sequence, sort, keep 100 and increment the counter in the candidate document.
5. Upload with `BlobUploadOptions.Conditions.IfMatch = observedETag`. For first creation, use `IfNoneMatch = ETag.All` to prevent two creators overwriting one another.
6. On a precondition conflict, read again and recompute the whole ranking with short random backoff. Handle the first-create race similarly. Allow at most five write attempts within a six-second server deadline. Exhaustion returns a service error, never unconditional overwrite.

Only the winning conditional write commits the sequence and document. An in-process lock would not protect multiple replicas. Azure Storage documents ETag conditional writes and HTTP 412 for conflicts. [Microsoft concurrency guidance](https://learn.microsoft.com/en-us/azure/storage/blobs/concurrency-manage).

Example: A and B read version 7. A saves version 8. B's version-7 write fails, so B rereads version 8 and merges with A's result. Version 9 contains both if both belong in the best 100.

A stable run ID makes replay idempotent while that run remains ranked. An evicted run replayed with the same payload cannot beat the monotonically rising all-time cutoff. Responses describe the current result, not a replay of an earlier response. Changed payloads for already evicted IDs cannot be detected without a receipt/history store; that stronger guarantee is outside this simple anonymous design.

Provision the container during deployment. A missing blob in an existing container means an empty list. A missing container, storage outage or malformed JSON means an operational error: never silently replace corrupt state with an empty list.

## Proposed HTTP contract

| Route | Behaviour |
|---|---|
| `GET /api/v1/highscores` | Return `{ entries, revision, fetchedAtUtc }`; each public row has `entryId`, `rank`, `displayName`, `score`. Empty array only for a genuinely empty list. |
| `POST /api/v1/highscores` | Accept `{ submissionId, displayName, score, levelReached }`. Recheck and return `{ outcome, entryId, rank, entries, revision }`, with outcome `ranked` or `notQualified`. Omit rank/entry ID for non-qualification. |
| `GET /health/live` | Process liveness, already implemented in the starter. Does not establish storage readiness. |

Use the run UUID as entry identity. Clients cannot choose rank, acceptance timestamp or tie sequence. Validate an integer non-negative score within the supported range, positive level, valid run ID and a trimmed single-line name of 1–20 grapheme clusters; also bound encoded name size. Current scoring awards multiples of 100, so reject impossible increments, while recognising plausible forged scores remain possible.

Return 400 with field errors for invalid data, 409 for changed data under a currently stored run ID, 429 for throttling and 503 for storage failure/exhausted contention. `notQualified` is a normal 200 result. A successful POST returns the snapshot from its own conditional write, including the exact entry to highlight.

No separate qualification endpoint is needed: a fresh GET after Game Over determines whether to prompt, and POST performs the authoritative check. GET does not reserve a place. Disable intermediary caching initially. Previously loaded app-session content can be shown as stale during an error but never determines eligibility. Add conditional GET only if measured request volume warrants it.

## iPhone integration

The client currently has no remote service. Integrate with the SwiftUI model and existing `GameSession`/`GameEngine` state flow:

1. Give each run an identity and capture immutable score/level once on entry to `gameOver`. Never submit the personal best or publish at each `levelComplete`.
2. Add an async `URLSession` highscore service and observable UI state. Network work must not block the main actor or rendering thread. Enforce an eight-second overall UI deadline and ignore/cancel obsolete tasks.
3. Add Highscores to the title. Load independently, permit immediate close/start, and open at rank 1. Title entry may start a background refresh without delaying controls.
4. After Game Over, fetch a fresh list. A qualifying score opens a cancellable name form explaining publication. POST only after explicit confirmation.
5. Scroll by returned entry ID with a centre anchor after layout and keyboard dismissal; clamp at content boundaries. Never locate the player by name or score alone.
6. Non-qualification, including losing a place during name entry, opens at the bottom with the player's final score visible outside the list.
7. On qualification/submission failure, show an error and preserve the local best. No disk queue, reconnect handler, background upload or later submission prompt. List refresh is read-only. A timed-out POST may have committed: describe it as unconfirmed and do not replay it automatically.
8. Leaving the flow cancels its UI work and prevents late responses reopening it. Cancellation cannot roll back a completed server save.
9. Update `Copy.privacy` and help text, which currently say scores stay on-device. Publish only name, score and rank in the list; level supports validation.

Gameplay and bundled content remain available without the service. Audio and intro behaviour are outside this feature.

## Hosting and cost

For a new, lightly used deployment, Azure Container Apps Consumption with `minReplicas: 0` is a reasonable starting option. It can scale to zero, with a cold start on the next request. Keep the client timeout/error handling even if deployment later chooses a warm replica. An existing paid App Service plan may be cheaper incrementally. [Container Apps scaling](https://learn.microsoft.com/en-us/azure/container-apps/scale-app).

Only 100 small records are stored, so bytes should be a small part of cost. Requests, compute, logs, image registry and retained blob versions also cost money. A monthly estimate requires region, traffic and retention settings. Whole-blob rewrites cause contention at high write rates; this design assumes modest traffic and needs load testing before release.

A single blob keeps the bounded ranking in one conditional operation. Azure Table Storage becomes more attractive for score history, player queries or many rankings. It is not necessary simply to hold 100 rows.

## Verification and planning handoff

Plan ranking unit tests and Azurite integration tests for initial creation, competing writers, duplicate IDs, changed payloads, empty storage, malformed storage and missing containers. Force conflicts deterministically and run simultaneous submissions across multiple API instances. Prove retries merge fresh state and never fall back to unconditional writes.

Exercise normal, delayed, failed and late iOS responses: ranks 1/50/100, equal cutoff, cutoff changes during naming, no connection, ambiguous save outcome, restart during request, no deferred upload, landscape, VoiceOver and large text. Validate managed identity and conditional writes in a development Azure account before release; emulator tests cannot establish deployed permissions.

The scaffold has no Azure dependency yet. Add supported `Azure.Storage.Blobs` and `Azure.Identity` packages when implementing persistence. No Azure resources have been provisioned or service deployed. Next workflow step: `$speckit-plan` using this feature directory and proposed design.
