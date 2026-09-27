# Validation quickstart for App Store preparation

This guide defines checks to run during implementation. Planning has not executed
these release scenarios. Existing commands below work against today's baseline;
new moderation commands/routes/scripts are explicitly **planned**, to be implemented
from the contracts before use. No example authorizes resetting production data.

## 1. Prerequisites and scope

From repository root, use the pinned .NET SDK, Xcode 27 with iOS 26+ simulators,
Azurite and the existing Local/DEV/PROD schemes. Check:

```sh
git status --short
dotnet --version
xcodebuild -version
xcrun simctl list devices available
```

Preserve unrelated work. Select an actual installed iPhone 13 simulator UDID and a
larger iPhone matching an accepted store resolution; do not assume a device exists
from an old record. Physical iPhone 13, valid signing/account and internal TestFlight
access are required later. New owner facts follow the store contract's input matrix.

## 2. Existing baseline checks

```sh
python3 src/scripts/backend-release-tests.py -v
HighscoresTests__UseAzurite=true dotnet test src/backend.tests -c Release
xcodebuild -project src/DonkeyTrump3D.xcodeproj -scheme DonkeyTrump3D -showdestinations
```

Run Azurite first, as documented in `src/backend/README.md`; tests must use isolated
containers and never PROD. Run iOS tests using the chosen UDID:

```sh
xcodebuild -project src/DonkeyTrump3D.xcodeproj -scheme 'DonkeyTrump3D Local'   -destination 'platform=iOS Simulator,id=ACTUAL_SIMULATOR_UDID'   -resultBundlePath /tmp/dt3d-release-validation.xcresult test
```

Replace the clearly marked device value; choose a fresh result path if it exists.
Expected: affected Swift/backend/UI suites pass with actual counts recorded, not
copied from historical review records. Include the planned moderation tests in
these same targets; no separate pretend test harness is sufficient.

## 3. Isolated local moderation integration (planned feature)

Run the API and operator mode against one dedicated local container, never the
ordinary local/dev ranking. `Highscores__ContainerName` is the shared local override
for both processes; Azure target overrides are not allowed by operator mode.

```sh
export Highscores__UseAzurite=true
export Highscores__ContainerName=highscores-release-validation
ASPNETCORE_ENVIRONMENT=Development dotnet run --project src/backend --launch-profile http
```

Use localhost:5281 only after confirming that port is free or belongs to this test
instance. Do not stop someone else's process. The planned smoke helper explicitly
creates an owned schema-1 fixture in this dedicated container, invokes conditional
migration and validates the result. `moderation list` is read-only and never initializes
or migrates state. A missing live Blob is not permission to seed one.

The implementation adds `src/scripts/release-moderation-smoke.py` for the following
contract checks. It generates throwaway credentials internally, keeps them out of
argv/logs, uses only an explicit loopback origin/container, and refuses Azure targets:

```sh
python3 src/scripts/release-moderation-smoke.py   --origin http://127.0.0.1:5281 --container highscores-release-validation
```

Expected assertions:
- migrate a populated schema-1 fixture conditionally, preserve all real rows/ties;
  corrupt/missing state is not replaced; repeated/lost-ack migration is safe;
- v1 GET public shape unchanged, v1 POST426, v2 missing/malformed secret401;
- two installation credentials publish independent scores; wrong-owner replay409;
- prohibited name422 allows current-run correction; benign names accepted;
- report → owner acknowledge → remove/block/resolve → same reporter status succeeds;
  other credential cannot read receipt, report snapshot survives rank eviction;
- multiple reporters on one entry and on a producer's other rows: direct removal or
  remove-and-block closes all affected unresolved reports atomically with truthful
  per-reporter disposition; preserves closed receipts and actual acknowledgement times,
  frees pending capacity, and survives ETag conflicts/already-tombstoned targets;
- blocked credential with a changed name/new run gets403; unblocked credential and
  local gameplay still work; removed ID remains rejected even under another credential;
- submit/delete/block races across independent store instances preserve bans, unrelated
  ranking, order and guards; retry recomputes after ETag conflicts;
- removed starter never reappears, approved replacement maintains ten returned entries;
  depleted catalog causes honest unavailable response, never resurrection;
- report/canonical-ID duplicates, lost acknowledgements, deadlines and stale responses
  preserve honest state and never schedule a deferred POST;
- stale unblock cannot lift a later re-block after audit expiry/compaction; matching
  block instance unblocks without reviving tombstoned rows;
- max field sizes, serialized-byte reserve and count boundaries retain ability to
  remove/block/resolve every current row; fake-clock30d expiry is invisible on reads,
  startup/hourly/opportunistic cleanup removes content while preserving guards/pending
  genuine reports; storage outage defers cleanup honestly and recovery removes it;
- fill pending/closed queues with controlled spam, bulk-dismiss only selected spam,
  prove admission recovers, minimal receipts expire24h, guards/genuine reports survive;
- migration backup expires24h, early success deletion works, maintenance pauses workers,
  Azure policy checks detect unexpected versions/soft-delete/backup copies;
- logs/public DTOs contain no credentials, producer hashes, names/bodies or report data
  outside their explicitly intended public-name/owner interfaces.

## 4. DEV → PROD rehearsal and deployment (implementation only)

Use the existing backend CI, DEV deploy and PROD promotion workflows. Run the DEV
checks/migration first with test-owned rows and the [migration contract](contracts/moderation-api.md).
Record exact run IDs, artifact SHA, supported schema and rollback floor. Refresh
`infra/backend-environments.json` against actual account state, scoped identity/RBAC,
plan/tier/scale, storage and neighboring-app health. Only this game's API may be
quiesced; preserve shared plan settings and other apps.

Verify both public pages and current PROD configuration after deployment. Compare
incremental cost assumptions (including moderation/report retention and bandwidth)
against DKK100/month including VAT; record existing committed plan charges separately.
Do not treat budget alerts as a hard cap. Retain before/after health/capacity evidence.
No synthetic automated POSTs to PROD: production publication evidence uses an explicitly
identified human-controlled test run and owner moderation of that test-owned result.

Operator session uses Azure CLI only for control-plane SSH authentication:

```sh
az account show --query '{subscription:id,tenant:tenantId}' -o json
az webapp ssh --resource-group Gulvet --name donkeytrump-api-d --subscription 6b6dcc04-7490-42ed-bedf-68f60946485e
```

Inside that verified DEV container, the **planned** read-only command is:

```sh
dotnet /home/site/wwwroot/DonkeyTrump.Highscores.Api.dll moderation list --target dev
```

Verify managed identity is the only Blob credential; cloud target execution outside
that app must fail. No printenv/token extraction. Repeat through the PROD app only
when appropriate; do not transfer DEV target flags. These checks make no data writes. Mutation command previews and explicit `--apply` follow the
contract. For actual production reports, only authorized owner operations apply;
never bulk-delete/reset the ranking as validation setup.

## 5. Candidate, screenshots and distribution

Build Release with the PROD scheme and inspect the archive before uploading:

```sh
xcodebuild -project src/DonkeyTrump3D.xcodeproj -scheme 'DonkeyTrump3D PROD'   -configuration Release -destination 'generic/platform=iOS'   -archivePath /tmp/DonkeyTrump3D-release.xcarchive archive
```

Requires actual signing access. Inspect embedded Info.plist (family1, iOS minimum,
PROD HTTPS URL, truthful export metadata), icon, PrivacyInfo.xcprivacy and Xcode
privacy report. Verify development arguments and fixture origins are absent/inert.
Record archive checksum/source/config/version/build. Run archive validation through
Xcode; no simulator build or ad-hoc code signature substitutes for this.

Prepare five native larger-iPhone captures per required display set with the planned
`AppStoreCapture` simulator scheme/configuration. Enable the isolated DEV `/capture`
route group and seed only its `highscores-capture` container using the store contract;
never reset normal DEV rows. Verify all visible names against the fixture before capture.
Record source/config/dataset hashes. Test capture archive rejection, PROD route404 and
unchanged normal DEV data; disable capture routes/delete its dataset after the session. The planned `src/scripts/validate-app-store-assets.py` validates final
format/dimensions/opacity/order and prints a manifest; run it against the actual
package directory after implementation. Inspect actual image legibility separately.
Compare every caption/claim with the candidate and record rights provenance.

Upload the App Store-eligible archive once through Xcode/authorized Apple tooling;
check Connect before retrying interrupted uploads. Wait for processing, install that
build through internal TestFlight and perform [iOS acceptance](contracts/ios-release-flow.md).
No external beta group or review submission. Screenshots may use a release-equivalent
simulator build; physical acceptance must reference the processed Connect build.

## 6. Physical and operator acceptance

Record device/OS/build/date for every journey in the iOS contract, including 15-minute
play, both landscapes, large text/VoiceOver, silent switch/music/mute, offline start,
actual online publication, failure/no replay, reports and support/privacy. For the
one-working-day report target, the actual owner reads/acknowledges and dispositions
an identified test report; the reporting installation retrieves the answer. Do not
simulate owner participation by silently operating both roles and label it delivery.
Run the labelled iPad compatibility-mode simulator smoke check separately.

## 7. Connect readback and handoff

Through supported Chrome access, reopen each saved area and compare all required
metadata/declarations/territories, processed image order, selected tested build and
manual release with the local package. Make an unsent draft only after all gates
pass. Record zero validation errors and direct app/version/draft link.

STOP before Submit for Review, equivalent sending actions or public release.
The final owner action is submitting the complete version, later handling Apple's
feedback and manually releasing. If a gate is missing, report its exact state and
continue independent preparation; do not label the draft ready.

Finish authorized implementation with passing checks and independent cross-vendor
review/focused fixes per AGENTS.md. Planning approval is not that future code review.
