# Release and moderation data model

Design only; new schema and fields are not implemented by this planning command.
Existing ranking/name/score/tie validation remains defined by
[001 specification](../001-global-highscores/spec.md) and its contracts.

## Installation credential (device only)

- `secret`: 32 random bytes, base64url without padding on the wire (43 characters).
- Protected atomic file in Application Support, excluded from backup; never UserDefaults,
  screenshots, diagnostics, URLs or source control. Create once when missing, keep through
  app upgrades, fail online writes if an existing file is unreadable/corrupt. Local play
  and public GET remain available. No silent rotation to bypass a block.
- Server `installationHash = lowercaseHex(SHA256(decodedSecret))` (64 hex characters).
  Possession scopes own reports; it is neither a player account nor hardware attestation.
- Local report receipts contain only report IDs/time/status, max 20, removed after
  expiry/404 and on uninstall. They enable explicit read-only status checks, never an
  upload queue. Pending score/name payloads are never persisted for later publication.

## HighscoreDocument schema 2 (one private aggregate)

Same `highscores/global-v1.json` Blob key, `schemaVersion = 2`.

| Field/entity | Required content and invariants |
|---|---|
| Existing ranking metadata | Existing monotonic sequence, schema and validation; preserve v1 tie order and IDs on migration. |
| `entries` | At most 100 stored rows. Existing run/name/score/level/timestamp/sequence plus `origin` (`installation`, `legacy`, `starter`) and nullable `installationHash`. Only installation rows require a hash. None of this extra metadata enters public ranking DTOs. |
| `removedSubmissionIds` | Unique UUID tombstones; never appear in ranking or generated starter projection. Removed IDs cannot be resubmitted, even with another credential. |
| `blockedInstallations` | Unique hash, blocked UTC timestamp and random `blockId` identifying this block instance. Keep that ID if already blocked; generate a fresh one on a later re-block. Blocks publication under every chosen name/run on that official installation; public read, reporting and local gameplay remain available. |
| `reports` | Stable report ID, reporter hash, entry ID, reason enum, server-created time, snapshot of offending display name and nullable producer hash/origin, status, acknowledgement time, resolved time, disposition code and resolvedOperationId. Snapshot supports triage after rank eviction. |
| `operatorAudit` | Operation ID, action enum, server time, affected counts; no secret, offending name or raw body. Kept only for short operational trace. |

Report reason: `offensiveName`, `impersonation`, `personalInformation`, `other`.
No free-text report or email/phone field. Display-name snapshot has the same validated
bound as a ranked name. Report ID is nonzero UUID; duplicate same-ID same-reporter
same-entry/reason returns the original receipt, never changes the snapshot/timestamp.
Conflicting reuse fails. Private reports are never returned in public highscore GET.

## State transitions and authority

- Publication: credential → validate/filter → read → check block/tombstone/ownership →
  rank → conditional commit → ranked/notQualified. A conflict repeats ALL checks on
  fresh state. A block committed first prevents that installation's later conditional
  submission; a submitted row committed first can then be removed by moderation.
- A run already ranked under a different hash (or legacy/starter origin) cannot be
  claimed by a new credential. Same run/hash and unchanged payload is idempotent
  while ranked; changed payload conflicts. The prior scope does not gain indefinite
  deduplication for merely evicted, never-moderated runs.
- Report: new → pending → acknowledged → resolved (`removed`, `removedAndBlocked`,
  `noAction`, `legacyRemoved`, `starterRemoved`, `dismissedSpam`). Acknowledge records owner receipt;
  resolve contains a fixed explanatory disposition visible only to the reporter.
  A report about a no-longer-ranked unknown entry returns not-found; an already
  accepted snapshot remains actionable if its row subsequently drops out.
- Removal/block/resolve use one ETag transaction, including ID tombstone and optional
  producer block. By default a block removes/tombstones all currently ranked rows of
  that attributed installation, without affecting other rows. Legacy/starter reports
  can remove but cannot invent an installation identity to block.
- Every tombstoning mutation atomically resolves all unresolved reports for all entry
  IDs it removes, with the same resolvedOperationId/time. Derive truthful dispositions
  per snapshot: legacyRemoved/starterRemoved, or removedAndBlocked only if that snapshot
  producer is blocked in the final state, otherwise removed. Do not alter previously
  closed receipts or invent acknowledgedAtUtc; resolved without prior acknowledgement
  is allowed. Duplicate tombstones are idempotent; an already-removed target still permits
  closing an unresolved report. No-action/spam disposition affects only selected reports.
- Unblock is an explicit owner operation requiring the currently expected blockId before removing the block hash; existing tombstones
  remain. It never republishes a removed row. A stale unblock for an earlier blockId must fail
  after a re-block, even if its old operator-audit receipt has expired.

## Retention, limits and reserve

| Data | Retention / maximum |
|---|---|
| Ranked name/result and producer hash | While ranked; snapshots in reports follow report retention. |
| Removed ID | Until service retirement or a separately designed epoch cutover rejecting every earlier ID. |
| Active block hash | Until explicit unblock or service retirement. |
| Pending/acknowledged report | Until resolution; max 100 unresolved. Owner checks every working day. |
| Resolved report including private snapshot and receipt | 30 days after resolution, then logically absent and automatically purged. Total unresolved + closed records max 1,000. Full capacity rejects NEW reports without deleting genuine accepted ones. |
| Owner-classified spam | Remove snapshot/producer identity/reason immediately; keep only report ID/reporter hash/status/resolved time/operation ID for 24 hours, then expire/purge. Max 100 minimal spam receipts separately, oldest may expire early; 404 is honest expiry. This exception frees ordinary queue capacity immediately. |
| Pre-migration backup | One private Blob per target, expires after 24 hours; deleted earlier after successful migration verification. No versioning/soft delete; no restore over live guards. |
| Operator audit | Up to 30 days, max 500. Expired/oldest audit may be compacted for safety mutations; state/guards themselves are authoritative. |
| Operational application diagnostics | Configure max 7 days, route/status/timing/count only; audit actual App Service/storage diagnostics and disclose provider retention separately before release. |

Expiry is checked on every receipt read without a write. Every mutation purges expired
closed reports/audit/spam receipts before recomputing; an hourly/startup worker handles
idle periods and expired backup Blobs using MI/ETags. Deletion due within one hour while
service/storage are available; outages defer to recovery and are recorded as retention
exceptions. No report content in App Service backup/logs. Version history and soft delete
stay disabled; inventory old versions/deleted copies/exported backups, confirm cleanup
and capture actual retention/cost before release. Backup lifecycle rule is secondary,
not a timing guarantee. See research for current management-plane observations.

Max aggregate serialized UTF-8 size 1 MiB; max 4,096 tombstones/1,024 blocks. At 3,800
removed IDs or 800 blocks, reject new score runs with a capacity error, keeping
headroom for all current 100 rows, 100 unresolved report snapshots and a 32-entry starter catalog. Reserve 64 KiB
below byte maximum for remove/block/resolve; byte admission tests use maximum allowed
field sizes, not average rows. If guard capacity is reached, never evict guards or
report a false success. Operator prioritizes safe removal/compaction and records a
capacity blocker; read/local play remain usable whenever the ranking can be safely
projected. No unbounded credential-partitioned rate limiter is introduced.

Starter projection extends the reviewed low-score catalog to 32 vetted entries.
It skips removed IDs and names rejected by current moderation policy. If eligible
starters cannot maintain ten returned entries, removal still succeeds and the read
fails honestly until the owner deploys a vetted replacement catalog; it must never
resurrect removed content or silently return a successful undersized list.

The disposable DEV capture aggregate uses the same schema in a separate
`highscores-capture` container; it is never the authoritative DEV/PROD ranking. Explicit
seed/reset is permitted only for that owned fixture; delete after media acceptance.
Normal datasets cannot be selected through capture route/config overrides. The store
contract defines all isolation and non-distribution gates.

## ReleaseCandidate and evidence

`candidateId`, Git revision plus dirty-content manifest if relevant, dependency locks,
configuration fingerprint, version/build, bundle/team identity, archive checksum,
Connect app/build IDs, deployment artifact SHA, actual supported devices and evidence
references. Phases: sourceReady → automatedChecked → uploaded/processed →
physicalValidated → draftValidated. Failure records the affected phase; it does not
fabricate later transitions. Physical TestFlight installation maps to Connect build
identity; Apple's thinned install need not match archive bytes.

## Listing, media, declarations and readiness record

- `StoreListing`: actual app/version/language, saved metadata, categories, free-price
  schedule, territories/exclusions and verified public URLs.
- `MediaAsset`: source capture checksum, candidate/configuration, native dimensions,
  opaque output checksum, language/order/caption, provenance and observed remote slot.
- `DeclarationEvidence`: field/question, answer, factual source, observation date,
  owner-only fact/confirmation reference if required, expiry/recheck condition. Private
  contact/legal documents stay in owner-controlled private evidence, not Git.
- `ReleaseRecord`: phase status, check command/result/device/build, Chrome readback,
  manual-release proof, unsent draft link, concrete blockers and safe next action.
  No password/cookie/token/private name-report snapshot belongs in this record.
