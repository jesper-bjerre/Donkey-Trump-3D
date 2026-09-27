# Highscore moderation API, operator and migration contract

Planned change. Public compatibility is deliberately bounded; existing 001 contracts
still govern ranking, tie order, input validation and no deferred score uploads.
See [data model](../data-model.md) for storage fields/retention.

## Public routes

| Route | Authentication | Request / successful result |
|---|---|---|
| `GET /api/v1/highscores` | Public | Existing snapshot unchanged: entries(entryId, rank, displayName, score), revision, fetchedAtUtc. No private fields. Read-only. |
| `GET /api/v2/highscores` | Public | Same public snapshot schema and top-100/min-ten rules. |
| `POST /api/v1/highscores` | None accepted | Always 426 `update_required`; no parsing/storage mutation that can bypass v2 safeguards. |
| `POST /api/v2/highscores` | Installation secret | Existing strict submission body (`submissionId`, `displayName`, `score`, `levelReached`) and existing `ranked`/`notQualified` result shape. Enforce moderation before every conditional write. |
| `POST /api/v2/highscore-reports` | Installation secret | `{reportId, entryId, reason}`. 201 newly accepted / 200 identical replay with `{reportId, status, createdAtUtc, acknowledgedAtUtc?, resolvedAtUtc?, disposition?}`. |
| `GET /api/v2/highscore-reports/{reportId}` | Same reporter secret | Same receipt. Other reporter, unknown or expired ID returns 404. Never returns producer identity or offending name. |
| `GET /support`, `GET /privacy` | Public | Accessible English HTML, correct contact/app/data practices, no login/cookies/analytics. |

Authorization: `Bearer <43-character unpadded base64url encoding of 32 random bytes>`.
Decode canonically; wrong length/encoding/duplicate Authorization values fail 401
`installation_credential_invalid`. Never treat it as Entra JWT or trust a public UUID
as credential. Limit header size; do not log headers/body. No redirects carrying
credentials to another origin. Local HTTP remains Debug loopback-only.

Requests use application/json, strict field names/unknown-field rejection, depth <=16
and body <=4096 bytes. Datetimes retain UTC millisecond formatting. Report reason is
one of the four enums in the data model. Entry must exist in the freshly read ranking
projection when accepting the report; snapshot that exact entry under the same ETag.
Blocked installations may read/report; only score publication is blocked. Private
receipt responses use Cache-Control: no-store, including errors/expiry.

New errors supplement existing ProblemDetails `code`, `status`, title and traceId:

| HTTP/code | Meaning and client response |
|---|---|
| 401 `installation_credential_invalid` | No write; online publication unavailable, do not regenerate an existing credential to bypass. |
| 403 `publication_blocked` | No new score write; terminal result for this run. Keep Play Again, local best and contact route. |
| 422 `name_rejected` | No score write; permit editing the name for the current still-active run. Clear actionable validation copy, no repeated public-name warning. |
| 409 `submission_removed` | Removed-ID guard; no publication/retry opportunity for that run. |
| 409 `submission_conflict` / `report_conflict` | Conflicting identity/payload; do not silently change IDs and resend. |
| 404 `entry_not_found` / `report_not_found` | Target no longer available, receipt not owned or expired; no false success. |
| 426 `update_required` | Older writer unsupported; local gameplay remains available. |
| 429 `rate_limited` | Bounded failure; Retry-After is not authority to schedule an upload. |
| 503 `service_maintenance` | Rejected before writes during maintenance or before schema migration; definite no-write, no deferred retry. |
| 503 `moderation_capacity` / `storage_invalid` / `operation_timed_out` | Honest unavailability. If a write may have committed, map instead to the operation's unconfirmed result. |
| 503 `submission_unconfirmed` / `report_unconfirmed` | Possible committed write; never assert “not saved.” Scores are not replayed. A report can be checked read-only using its preallocated ID. |

Server deadlines: <=6 seconds for every store operation including GET/status;
network <=2 seconds, <=5 conditional attempts, SDK retries off. iOS uses <=8-second
foreground deadlines plus generation invalidation on navigation/background. No
background uploads, deferred report/score queue or automatic POST retry. A report
may be explicitly retried with the identical ID/body while its form is still active;
status checking is preferable after ambiguity. Close/start/new run drops active work.

Keep current bounded global read/score limiters; add a separate report bucket of
capacity 5, replenishment 1/second per instance, plus one unresolved report per
(reporter hash, entry ID) returning the existing canonical receipt with `alreadyPending: true` (its reportId
may differ from this request). The client stores the returned canonical ID and does
not claim a new report/reason was recorded. A lost response followed by 404 for the
newly requested ID does not prove no pending report exists; show unconfirmed/contact,
never infer failure or retry automatically. Do not allocate unbounded
per-secret buckets. Global report capacity and queue limits remain authoritative
under multiple workers. API rate limits are not spend or comprehensive abuse guarantees.

DEV capture routes reuse these handlers with a separately configured capture store;
see [store isolation contract](store-release.md#concrete-screenshot-isolation). No capture
routes exist on PROD. Capture seed/delete commands are DEV-container-only, not a general
reset or public administration interface.

## Operator command interface (new mode of existing backend executable)

`dotnet run --project src/backend --no-launch-profile -- moderation <command> --target local|dev|prod ...`

Local invocation above uses Test validation and an explicit loopback emulator/container.
For DEV/PROD the operator MUST execute the published DLL INSIDE the running target
App Service via authenticated `az webapp ssh`. Human Entra authorization opens only
the control-plane session; Blob access uses the app's ManagedIdentityCredential with
its existing narrowly scoped container role. No AzureCliCredential/default credential
chain, shared key, local cloud operator execution or raw-token extraction. Verify
WEBSITE_SITE_NAME against target inventory and the configured storage account/container;
reject mismatches or external overrides. Execute `/home/site/wwwroot/DonkeyTrump.Highscores.Api.dll`
with `dotnet ... moderation <command> --target dev|prod`. The mode initializes shared
storage/domain code and exits without HTTP hosting. Check harmless aggregate metadata
first. Do not dump environment/MI endpoint tokens, snapshots or private names into logs.
No public admin route or additional hosted service. Failure to obtain a supported
SSH session blocks cloud operator work; no human Blob credential fallback.

Commands:
- `list`: report IDs/status/reason/deadline grouped by entry ID with counts, for private
  owner console only (not CI/application logs); `show --report-id UUID`
  reveals necessary private snapshot to the owner, not to CI logs or repository evidence.
- `acknowledge --report-id UUID --operation-id UUID`: record actual owner receipt.
- `resolve --report-id UUID --decision remove|remove-and-block|no-action --operation-id UUID`:
  one ETag mutation removes/tombstones and optionally blocks the snapshot producer,
  removes their currently ranked rows, and records the reporter-visible disposition.
  Legacy/starter origin supports remove/no-action only; never fabricate attribution.
  Only unresolved reports can be resolved. A closed report is immutable except purge;
  an identical operation replay returns the prior receipt, another decision gets409
  `report_resolved`. Reserve accounts for 100 current rows plus 100 unresolved snapshots
  and the 32-entry starter catalog, including off-list offenders.
- `dismiss-spam --report-ids UUID,... --operation-id UUID`: preview up to 100 explicitly
  selected unresolved reports; owner confirms spam classification. One ETag transaction
  immediately removes snapshots and ordinary report records, adding only bounded minimal
  `dismissedSpam` receipts (24 hours, max100, oldest may expire early). No ranking/block
  mutation and no deletion of genuine reports to make room. Already-dismissed IDs are
  idempotent, mixed invalid/resolved IDs reject the whole operation before mutation.
  After receipt expiry a stale command finds no report and cannot affect a new report
  with another UUID; all current ownership/state checks rerun on conflict.
- `remove --entry-id UUID --operation-id UUID`: owner-initiated removal with tombstone.
  Every tombstoning transaction (direct remove, resolve/remove or remove-and-block)
  also closes ALL unresolved reports whose entry IDs were tombstoned, including other
  ranked rows removed by that block. This is one conditional write, never a later
  best-effort loop. Each receipt receives the same operation ID/server resolution time,
  and disposition from its snapshot origin: legacyRemoved/starterRemoved; installation
  reports get removedAndBlocked only if their snapshot producer is blocked in the final
  state, otherwise removed. No-action/spam operations do not close other reports.
  Preserve actual acknowledgedAtUtc; do not invent an acknowledgement for an unread
  report. A resolved receipt may therefore have no acknowledgement time. Existing
  closed receipts remain immutable. Existing tombstones are idempotent and a still-open
  matching report can be closed as removed without requiring its row to be ranked.
  Capacity checks must allow this transition for all100 unresolved reports: it changes
  existing records, allocates no extra ordinary report slots and uses the byte reserve.
- `show-block --installation-hash HASH`: private read of the current blockId for a fresh preview.
- `unblock --installation-hash HASH --expected-block-id UUID --operation-id UUID`: explicit unblock, never
  removes tombstones; hash is private moderation identity, not a raw credential.
  Mismatched blockId fails409 `block_changed` without mutation, preventing an old
  unblock replay from lifting a newer block. Missing block is already-unblocked.
- `purge-expired`: same purge logic as the hourly/startup worker and pre-mutation
  cleanup: ordinary closed reports30d, spam receipts24h, audit30d, backups24h. Never
  purge genuine pending reports, active blocks or removal guards. Receipt GET treats
  expired records as absent without writing. Record oldest overdue age as a count/time
  metric with no content. Worker uses MI/ETags, pauses for migration maintenance;
  verify PROD Always On and recover missed cleanup on startup. Outages delay physical
  deletion beyond the normal one-hour bound, explicitly disclosed in privacy/evidence.
- `migrate --expected-etag ETAG`: validate/convert schema 1 using conditional replace,
  or verify already-migrated schema 2 and exit without rewriting it.

Preview mutation summary then require explicit `--apply` for write commands. This is
an operator safeguard, not a new owner-approval handoff for agent work already
explicitly authorized. Mutations use stable operation IDs; ambiguous results require
readback, never blind duplicate writes. ID-based deduplication lasts only while its
audit receipt is retained; it is not indefinite. After audit eviction, tombstones,
immutable resolved reports (including resolvedOperationId) and expected blockId
provide operation-specific stale/replay protection. No old command may mutate a new
block instance. Every retry reapplies current rules. Avoid
storing raw snapshots or report content in ordinary command logs.

Owner routine: inspect/acknowledge every working day, resolve by the same local clock time on the next
Monday–Friday day in Europe/Copenhagen; check automatic cleanup lag and guard/byte counts.
Bulk-dismiss confirmed spam to restore admission when the queue is full; support contact
remains available during a flood. Anonymous attackers can mint credentials: this remedy
is bounded owner recovery, not guaranteed resistance to sustained Sybil denial of service. A rehearsal
must show a real owner queue read/acknowledgement, a disposition within that target,
and the reporting installation's status read. Saving a report without owner receipt
is not successful delivery. Public contact remains available when reports fail.

## Safe rollout and rollback

1. Test migration/removal/block/report/ambiguous-ack cases against isolated Azurite,
   then DEV, preserving unrelated rows and minimum-ten projection.
2. Produce the schema-2-aware backend artifact through the existing DEV pipeline.
   This code can serve validated schema-1 reads but returns 503 for v2 writes until
   migration; v1 POST is already 426. Record supported storage schema in the release
   manifest and enforce it in PROD promotion/rollback checks.
3. Before each migration, record target resource identity, current schema/ETag,
   count and sequence evidence privately; verify versioning/soft delete/backups policy.
   Create/inspect one MI-owned private pre-migration copy with 24-hour expiry, after
   writers are quiescent in step4 and before conversion. Worker deletes on expiry;
   delete immediately after verified success. Never export to workstation/CI logs.
   Keep the same Blob key and existing workload resources. Never use a missing or
   invalid live Blob as permission to replace it with an empty list.
4. Enable `Moderation__Maintenance=true` only on this game's app, deploy the verified
   schema-aware artifact and restart this app to terminate old workers. This mode
   keeps HTTP validated reads/SSH running but rejects every public write with503 and
   pauses background mutations; v1 POST remains426. Verify running artifact/config
   on every configured instance, no old workers, and wait for the <=6s in-flight
   deadline before backup/migration. Operator migration alone may mutate during this
   gate. Never stop/resize the shared plan/neighbor; no deployment slot assumption.
   Missing proof of quiescence blocks migration. Local gameplay remains usable.
5. Owner-authorized operator mode conditionally converts the current schema-1 Blob
   to schema 2, preserving IDs/name/score/timestamps/sequence and marking old real
   rows `legacy` (no installation hash). Starter IDs remain reserved/unclaimable.
   Lost acknowledgement: inspect current schema/data before retrying; no reset.
6. Verify schema/migration and remove the backup, then clear maintenance/restart only
   this API and verify current artifact/schema, GET and new credentialed
   publication using only test-owned results. Rehearse in DEV before PROD. Existing
   byensgaader apps must pass before/after availability checks; update cost/capacity
   evidence and immutable DEV-to-PROD artifact identity.
7. After migration, rollback ONLY to a tested schema-2-aware artifact. The first
   migrated release must retain its schema-aware read/maintenance mode as recovery
   baseline. If healthy writes cannot be restored, preserve the Blob and serve
   validated reads/503 writes or keep this API unavailable; never resurrect deleted
   data by restoring a pre-moderation Blob. Future data recovery must replay current
   moderation guards and is a separate controlled operation.

Legacy entries remain removable but retrospectively blocking their original
installation is impossible: v1 never recorded identity. Document this limitation;
credential-free v1 writes are retired, and all new release publications have identity.
Do not claim that migrated rows acquired enforceable original-device attribution.
