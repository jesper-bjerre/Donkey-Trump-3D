# Store package, account and unsent handoff contract

## Deliverables and identity

Working release package: `docs/releases/app-store/<version>-<build>/` (created during
implementation). Keep editable listing text, source screenshots, final ordered PNGs,
asset/candidate SHA manifests, anonymized acceptance evidence and release-record.md.
Large archives/device logs and private legal/contact/report evidence live in an
owner-controlled private location; the record holds non-secret references/checksums.
No placeholder field value may be uploaded.

Before external changes, inspect the intended Chrome session, organization/team,
existing app/bundle ID and version/history. Reuse a matching record; create only when
absence is established. Current repo bundle ID is `com.hyldenbrandt.donkeytrump3d`,
team `QHL89A7A8J`; these are source values, not proof of account ownership/access.
Record the actual app ID, version/build, role and relevant agreements. Do not extract
cookies/tokens or use an unapproved substitute browser to bypass authentication.

## Required account/input matrix

| Input | Discovery and action if missing |
|---|---|
| Intended organization, app/history, role | Read Connect via supported Chrome access; unresolved access blocks only account-dependent actions. |
| Signing and internal tester eligibility | Inspect local signing/account and existing owner tester membership; verify upload/internal install without external beta review. |
| Genuine support/review contact, copyright owner | Obtain from verified account/project facts; ask owner together for missing name/email/phone/copyright facts, store private evidence outside Git. |
| Trader, territorial licences, agreements | Determine from actual owner facts and current questionnaire. Owner-only legal acceptance cannot be guessed or bypassed. |
| Public asset provenance | Retain owner cover/prompt/music provenance and assess names/models/audio/starter names; concrete unresolved issues block related declarations/media. |
| Hardware and candidate checks | Record actual physical iPhone availability and OS; missing hardware evidence blocks readiness, not design/independent media work. |
| Shared Azure inventory/cost baseline | Refresh existing plans/apps, permissions, current plan charges/capacity, incremental estimate including moderation/pages/diagnostics. |

Discover first, request only missing facts in a consolidated owner-input request;
no invented data or repeated authorization for already approved ordinary preparation.
A tool connection failure is not proof the user's login/account is wrong.

## Listing and media

English app name/subtitle, description, promotional text, keywords, categories,
copyright, support/privacy URLs and genuine review contact/instructions. Current
limits are checked against Apple/Connect during execution; research records 4,000
characters for description, 170 promotional characters and 100 keyword bytes.
Use truthful 3D arcade/satire wording, offline-play versus online-highscore distinction,
original no-affiliation copy. No copied competitor names as keyword bait, invented
endorsement or unverified licensing claim. Supply What's New only if applicable.

Five images per required iPhone display set:
1. Representative 3D gameplay and objective.
2. Jumping/dodging and readable landscape controls.
3. Another real level/rescue moment.
4. Real title/intro presentation, with optional clearly distinguished supporting art.
5. The real highscore UI with approved synthetic DEV entries only.

Capture at an accepted native larger-iPhone landscape resolution (research baseline
2868×1320, 2796×1290 or 2736×1260 for 6.9-inch). Record exact simulator/model/OS/source.
No stretching iPhone 13 captures, fake gameplay, debug controls or real-user names.
Media source build must match release source/features/optimizations except the explicit
AppStoreCapture HTTPS base URL and simulator platform. See isolation procedure below. Final image pipeline validates dimension,
orientation, opaque JPG/PNG, order and caption legibility, retains unedited captures
and outputs a checksum manifest. Review actual pixels at intended size. Icon must
match candidate asset catalog, current format requirements and truthful branding.
Optional video and native iPad assets remain outside scope.

## Concrete screenshot isolation

Create `AppStoreCapture` configuration/scheme based on Release compiler/optimization
settings, no DEBUG/test launch parsers or injected UI/game state. Set base URL to
`https://donkeytrump-api-d.azurewebsites.net/capture`; normal `/api/v2/...` path composition
then uses `/capture/api/v2/...`. A build-phase check requires iphonesimulator SDK for
this configuration; archive/export validation additionally requires configuration
Release, exact PROD origin and no capture path. CI tests both valid capture build and
rejected device/archive capture configuration. The upload manifest records only the
separately validated Release archive. Capture is not a distribution exception.

The existing DEV API conditionally maps the same v2 handlers under `/capture`, with a
separate store bound to `highscores-capture` container on donkeytrumpd. It must never
fallback to the normal DEV/PROD container. Enable only when deployment inventory,
WEBSITE_SITE_NAME=donkeytrump-api-d and storage account all match DEV; enabling in PROD
fails startup and PROD contract tests require capture routes404. Ordinary DEV routes
and data remain untouched. Give only DEV MI the additional container-scoped permission;
no account-wide role/new compute service. Same validation/ranking/moderation/ETags apply.

Operator `capture-seed --target dev --dataset capture --apply` inside DEV App Service
initializes or replaces only this disposable capture dataset with approved synthetic
names/low scores and schema2 state. It refuses other targets/containers and records
fixture checksum, not secrets. This explicit owned-fixture command is the sole reset
exception; all normal/live missing-state rules stay unchanged. Any capture test scores
are synthetic and never promoted or copied to live stores. Preserve snapshot/content
identity for the capture session, inspect every visible row, and reseed if unapproved
entries arrive (route remains publicly reachable). Image acceptance requires the actual
pixels contain only approved synthetic names, regardless of fixture seed evidence.
After capture, disable the DEV-only route and delete the capture dataset using MI;
include this small additional storage/operation cost in estimates. Tests assert route,
container and credential separation, no fallback and no ordinary DEV data changes.

## Public pages, privacy and territory declarations

Default real URLs are `https://donkeytrump-api-p.azurewebsites.net/support` and
`https://donkeytrump-api-p.azurewebsites.net/privacy`, served by the existing owner
controlled app. Revalidate the actual configured PROD host before publication.
Pages must load anonymously on mobile/desktop, identify app and genuine contact,
explain public submission, installation-based safeguards, reports/status, retention,
removal requests, hosting/processors and contact. No login/cookies/analytics.
Local-gameplay data remains distinguishable from transmitted data.

Complete privacy inventory for public handle (Apple's screen-name/User ID category),
scores/game content, installation fingerprint, private reports and actual diagnostics.
Determine linkage/purpose/retention from the final model, not “no accounts.” Recheck
platform HTTP/IP logging and provider retention. Validate privacy manifest and store
answers separately; one does not replace the other. Do not freeze existing help copy
if moderation adds new retained data. Audit rights, content/age, export/encryption and
accessibility claims with dated evidence and current questions; record unresolved
facts as gates rather than chosen answers.

Price is free, no purchases/subscriptions/ads. Maintain an eligibility matrix for
all territories. Exclude only where applicable requirements cannot be met, recording
why (including current China/Vietnam game-licence requirements if no documents exist).
Determine EU trader status from real facts; free pricing is not the answer. Disable
future-territory auto-expansion unless newly eligible countries are verified. Inspect
and disable optional Apple-silicon Mac/Vision Pro availability, pre-order and any
scheduled/automatic release. Check device-history restrictions before iPhone-only
configuration, without silently adding native iPad scope.

## Candidate and Connect sequence

1. Finish candidate/moderation/pages and automated checks; freeze candidate source,
   config and dependency identity. Record backend artifact/schema and real PROD URL.
2. Archive with valid signing and normal App Store Connect distribution (NOT TestFlight
   Internal Only). Validate archive: iPhone family/min OS, correct icon, privacy manifest,
   production endpoints, release flags excluded, export answer from actual evidence.
3. Upload once. After timeout inspect existing processing/version/build before any
   retry. Wait for processed success and resolve actual validation errors. Use internal
   TestFlight with the existing authorized owner account for physical acceptance.
   Do not add an external tester group or send a beta/App Store review submission.
4. Record physical acceptance against that exact processed build ID/version/build.
   Apple's thinning changes binary packaging; retain archive/source/Connect identity,
   not an assertion that device IPA bytes equal the archive. A changed candidate
   requires affected tests/media/declarations and a new uploaded build identity.
5. Save listing, processed images/order, declarations, price/territories, real URLs,
   review instructions and selected tested build. Reopen each area and compare saved
   state against the local package; “typed” or “upload started” is insufficient.
6. With all readiness gates passed, select manual release and assemble an unsent
   review draft using Add for Review only if that action remains unsent. Stop before
   Submit for Review or any equivalent sending action. A changed workflow/button
   boundary blocks that step; never guess a click that could submit/publish.
7. Reopen the intended app/version/draft. Confirm zero required-field errors, correct
   selected build, processed media, manual release and owner Submit action available.
   Record direct Connect link and actual state. Completion requires no remaining
   owner copy/media/declaration/build work. Owner submits, handles later review feedback
   and releases after approval. No agent Apple submission/publication is allowed.

## Evidence/resumption contract

Each release-record step has: target identity, intended change, observed before/after,
result, observation time, candidate/media hashes, non-secret proof and next action.
Separate local-ready, remote-saved, build-uploaded/processed, device-validated,
draft-validated, owner-submitted, approved and released states. Last three remain
outside this agent's completion scope. Resume by reading remote state first; do not
blindly repeat app creation, uploads or draft assembly. Failed checks preserve their
evidence and block the dependent readiness claim. Independent cross-vendor approval
is required after completed artifacts/checks and any material fixes, per AGENTS.md.
