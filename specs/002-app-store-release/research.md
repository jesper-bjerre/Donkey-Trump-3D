# Release planning research — 2026-09-27

This is design research, not executed release evidence. Repository inspection and
official Apple/Microsoft documentation informed these decisions. The plan skill's
research helpers inspected backend and iOS/store concerns independently; the lead
owns the consolidated design and cross-vendor review.

## 1. Extend the existing native app and service

**Decision:** retain Swift/SceneKit/SwiftUI, iOS 26+, the existing .NET 10 Minimal API,
Azure SDKs and private Blob Storage. Serve `/support` and `/privacy` as static HTML
from the existing PROD API origin, without cookies, analytics or another hosting bill.
Use the deployed DEV/PROD resources in `infra/backend-environments.json`.
**Rationale:** current source already implements ranking, deadlines, conditional
writes and deployment promotion. The missing release scope is moderation, public
pages, candidate hardening, evidence and Connect preparation.
**Alternatives:** another database, admin web app, mail service or new App Service
Plan add operation/cost without being necessary for this first release.

Current source: .NET SDK 10.0.401 (`global.json`), net10.0, Azure.Storage.Blobs
12.29.2 and Azure.Identity 1.21.0. Swift 5 language mode under the installed Xcode
27 toolchain. These are repository baselines, not claims that patch releases never
change; restore and check supported servicing before implementation.

## 2. Anonymous installation credential

**Decision:** the official app generates one 256-bit cryptographic random secret,
stored atomically in protected Application Support, excluded from backup. Reuse it
across runs, upgrades and relaunches; uninstall may clear it. A corrupt existing file
fails publication closed rather than silently minting another identity. No account,
registration request, hardware ID, IDFA or tracking service. The server fingerprints
the secret with SHA-256 and stores only the fingerprint alongside attributed rows,
reports and blocks. The raw secret is sent only in the HTTPS Authorization header
for publication/report routes, never URLs, public responses, logs or screenshots.
**Rationale:** the blocked official installation cannot change its name or run ID to
bypass a block. Startup/local play need not wait for registration or connectivity.
**Alternatives:** a client-chosen public UUID is not a possession credential; a
server-issued token adds issuance/key management but alone does not prevent a
modified client requesting a new identity. Keychain persistence across uninstall
is unnecessary for the agreed scope.
**Limit:** modified clients can mint new secrets without reinstalling. This is
installation-scoped abuse friction, not hardware identity or proof of genuine play.

## 3. Atomic moderation in the existing Blob

**Decision:** schema 2 of the existing `highscores/global-v1.json` Blob contains the
ranking, removed-ID tombstones, blocked fingerprints and bounded reports. The old
filename is retained intentionally to avoid two divergent authoritative stores.
Every mutation reads, validates, computes and writes with the same ETag; a conflict
rereads and recomputes all ranking/block/removal checks. GETs never write. Keep the
existing six-second operation deadline, two-second network timeout, at most five
conditional attempts and disabled SDK retries.
**Rationale:** a separate ban Blob permits a submit already reading an old ban state
to commit after a block. Removal without a tombstone permits replay resurrection.
Microsoft documents [ETag conditional writes and conflict rereads](https://learn.microsoft.com/en-us/azure/storage/blobs/concurrency-manage).
**Alternatives:** leases or a transactional database can serialize the work but add
unnecessary coordination for this small list. Unconditional writes are rejected.

## 4. Retention and capacity are explicit

**Decision:** retain only removed submission IDs until service retirement, and active
blocked fingerprints until explicit unblock or service retirement. Keep pending
reports until disposition; retain closed report content/receipt and operator audit
for 30 days of logical access, then automatically purge as specified below. No indefinite offensive
name retention merely to enforce a block. Aggregate max 1 MiB, max 100 ranked entries,
4,096 tombstones, 1,024 blocks, 100 pending reports, 1,000 total report records and
500 audit records. At 3,800 tombstones or 800 blocks stop accepting NEW score runs;
keep enough reserve to moderate every remaining row, unresolved report snapshot and the finite starter catalog.
Admission must also reserve 64 KiB below the byte cap for safety mutations. Tests
must prove the reserve against maximum validated field sizes. Never evict guards.
At report/audit capacity, reject new report/optional audit-growing actions honestly;
mandatory remove/block/resolve can compact expired audit and omit nonessential audit
history if necessary, with the guard/state change itself retained. Do not erase a
genuine pending report or an unexpired ordinary receipt just to admit more traffic.
Explicit owner classification of spam permits immediate private-snapshot removal and
a 24-hour minimal dismissedSpam receipt, then automatic purge; bounded bulk handling
restores admission without waiting 30 days.
**Rationale:** reusable random submission UUIDs make finite tombstone expiry unsafe.
This bounded small-service choice fails honestly before growth damages integrity.
**Alternatives:** expiring run identities require a different public protocol;
unbounded guard history or silent expiry is not acceptable. Future sharding/epoch
migration is an explicit capacity project, not a fallback during a write.

Automatic expiry is enforced on receipt reads (expired records return404, without
writing) and by purge-before-mutation plus an hourly/startup ASP.NET background worker
in this existing service. Physical removal is due within one hour of expiry while
service/storage are available; outages delay deletion until recovery. PROD Always On
and observed cleanup lag gate readiness; DEV sleeping behavior is recorded honestly.
The worker uses managed identity and the same ETag/deadline rules, never removes guards
or unresolved genuine reports, and pauses during migration maintenance.

Read-only management-plane inspection on 2026-09-27 found both donkeytrumpd/donkeytrumpp:
blob soft delete enabled=false; versioning, container delete, restore and change feed
unset. Keep versioning, soft delete and App Service content backups of player data
disabled; recheck actual policy/history/backup destinations before release. Do not
change shared/unrelated settings silently. No application response/body logs or local
persistent copies of the aggregate. One private pre-migration Blob backup is allowed
per target under `release-backups/`, with UTC expiry 24 hours after creation. Operator
migration mode creates/verifies it with MI, and deletes it after successful validation;
the worker also deletes expired backups hourly/on startup. No general daily data
backup is introduced. Set a prefix-scoped Azure lifecycle delete rule after one day
as a secondary cleanup safeguard, not a precise deletion clock. Backup age/cleanup
lag is monitored; outage exceptions and this extra recovery-copy period appear in
privacy/retention evidence. Inspect any historical versions/deleted copies/exported backups
before claiming the policy; unknown old copies block that claim. Never restore an old
snapshot over current moderation guards. Hard instantaneous physical erasure cannot
be promised during a cloud outage.
[Soft-delete retention](https://learn.microsoft.com/en-us/azure/storage/blobs/soft-delete-blob-overview)
and [lifecycle management](https://learn.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-overview)
explain the storage-side behavior; lifecycle execution is asynchronous.

## 5. Reports, filtering and owner operations

**Decision:** a bundled server-side moderation policy normalizes a comparison copy
of names (Unicode normalization, case folding, common separator/leet evasions) and
rejects prohibited slurs/sexual/violent harassment terms in English and Danish.
Keep the existing canonical stored display-name and scoring rules. Include regression
examples for prohibited inputs, evasions and benign names; operator removal covers
content automated filtering misses. Policy changes review existing rows explicitly.
Players report an entry using a reason enum, no free text or contact collection.
Reports snapshot the offending name and producer fingerprint for triage even if the
row later falls out of the top 100. A private status receipt lets the reporter read
the owner's disposition, without a public report feed or player account.

The same backend executable gets an operator-only command mode run inside the target
App Service container, using that app's scoped managed identity for all Azure Blob
access. The owner enters via Azure control-plane-authenticated SSH; human Azure CLI
credentials never access the Blob data plane. It reuses domain validation/ETag code
and does not start another web server. No public admin API or additional credential. The owner
checks the queue each working day, acknowledges and resolves reports within one
working day; demonstrate actual receipt and disposition before readiness. Define a
working day as Monday–Friday in Europe/Copenhagen, with deadline at the same local clock time on the next
working day. A genuine support contact is the fallback during service/report failure.
**Alternatives:** email-only reporting depends on mail setup and loses atomic entry
context; a new admin website and notification service are unnecessary. A stored
report alone is not proof of owner delivery or timely response.
[App Service authenticated SSH](https://learn.microsoft.com/en-us/azure/app-service/configure-linux-open-ssh-session) and
[ASP.NET rate limiting](https://learn.microsoft.com/en-us/aspnet/core/performance/rate-limit?view=aspnetcore-10.0)
support existing identity/traffic controls; per-process limiting is not a billing cap.

## 6. Explicit migration and compatibility floor

**Decision (owner update 2026-09-28):** evolve the existing `/api/v1` in place,
including credentialed publication and reporting. The app is unreleased and has only
the owner testing it; no second API or old-client retirement mechanism is needed.
New code reads storage schema 1 only for explicit data conversion
and rejects credentialed writes until schema 2 is installed. Deploy schema-aware code first,
quiesce only this game's API, conditionally migrate the current Blob, then resume.
Preserve every existing row and sequence; legacy rows have no fabricated producer
identity. They remain removable, but cannot be retrospectively attributed/blocked.
The old unauthenticated writer route is disabled, and new release submissions are
attributed. Never allow a new credential to claim an existing legacy run.
Rollback after migration requires a schema-2-aware build; never restore an old Blob
snapshot that removes moderation decisions. Migration/rollback rehearsal in DEV
precedes PROD. Exact procedure is in the moderation contract.
**Alternatives:** opportunistic per-request migration and permanently dual writers
increase race and rollback risk. Silent reset loses real scores and is forbidden.

## 7. Store media and candidate identity

**Decision:** five truthful English landscape screenshots for the currently required
6.9-inch set; capture native 2868×1320, 2796×1290 or 2736×1260 using a matching simulator.
The project's five-image choice is within Apple's 1–10 JPG/PNG, no-alpha limits.
Recheck actual Connect slots; iPhone 13 alone is not the larger-set substitute.
[Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/).
Use actual gameplay, control/intro variety and an approved synthetic DEV leaderboard;
store images never include other players' data. Build capture code from the same
source/features and Release optimizations using the explicit non-distributable
AppStoreCapture simulator configuration and isolated DEV capture route/container
defined in the store contract; no
fake game scenes, debug overlays or screenshot-only product features. Document this
configuration difference. Cover art may frame captures, not replace gameplay.

**Decision:** upload a normal App Store-eligible signed archive, then use internal
TestFlight on the owner's existing tester account for physical iPhone 13 acceptance
of that processed version/build. Record source, archive checksum and Connect build
ID, not an impossible byte identity for Apple's thinned device installation. Select
that same build in Connect. Do not choose TestFlight Internal Only and do not use
external beta groups (which may submit for beta review).
[Distribution](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases),
[internal testing](https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers).

## 8. Platform hardening, privacy and truthful declarations

**Decision:** after checking existing distribution history, target app device family
1 only, retain iOS 26 minimum and both landscapes, disable optional Mac/Vision Pro
availability. Add accessible privacy/support links and reporting UI. Guard the
currently unconditional `-autopilot/-autostart/-iconShot/-introAt` parser from Release.
Add `PrivacyInfo.xcprivacy` after auditing app/dependencies; UserDefaults currently
needs the app-private-use reason CA92.1. Confirm archive inclusion and privacy report.
[Required-reason API guidance](https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest).

Inventory public handles/scores, installation fingerprints, reports, retention and
actual platform diagnostics. Determine linked-data/privacy answers from those real
relationships; no-login is not no-data. Explain public publication in existing help
copy without restoring the removed dialog reminder. Audit export/encryption based
on shipped code and actual questionnaire, then set the correct declaration; do not
pre-fill a legal answer here. Assess original assets, public-figure depictions,
reference-game resemblance and starter-character names, including owner-supplied
cover/music provenance. A parody label or owner-provided file alone does not establish
third-party permission. Concrete unresolved issues block the affected release gate.
[App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/),
[privacy details](https://developer.apple.com/app-store/app-privacy-details/),
[encryption](https://developer.apple.com/help/app-store-connect/manage-app-information/determine-and-upload-app-encryption-documentation/).
These are release assessments, not legal conclusions or an Apple approval guarantee.

## 9. Saved, validated and unsent Connect state

**Decision:** complete required fields and eligible territories, select manual release,
verify saved content by fresh read and create only an unsent draft. Stop before Submit
for Review or any equivalent action. Do not wait for Pending Developer Release, which
would require the owner's later submission/Apple approval.
[Submission workflow](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/).
Check text limits against [version fields](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)
(description 4,000 characters, promotional text 170, keywords 100 bytes). Do not invent
owner identity, contact, copyright, trader status or licences. Record territory
exclusions for unmet requirements (notably current China/Vietnam game documentation)
and determine EU trader status from actual facts, not the free price.
[App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/),
[EU trader requirements](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/).

## 10. Resolved design choices vs execution prerequisites

No unresolved architecture/product-choice marker remains. Actual Connect organization,
app history, internal tester eligibility, signing, owner contact/legal facts, asset
rights evidence, committed Azure baseline and hardware availability are explicit
execution gates in the store contract. Discover available account/project facts first,
then bundle only missing owner facts into one request; continue independent work.

A Chrome-skill read-only connection attempt during planning failed before browser
selection with `Importing module "node:process" is not allowed in node_repl`. It
establishes neither a missing extension nor expired login. No account page was read,
no session secret extracted and no alternate browser used. Retry the supported
Chrome connection during execution; this blocks Connect verification, not this design.

The owner subsequently confirmed being signed into Connect in Chrome. A fresh retry
returned the same pre-selection runtime error. Login is owner-reported; organization,
app and permissions remain unverified by the agent. Repeated sign-in is not requested.
