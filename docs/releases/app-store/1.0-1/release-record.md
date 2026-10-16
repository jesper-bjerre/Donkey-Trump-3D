# App Store release — version 1.0, preparation in progress

Observed 2026-09-28, approximately 19:20–19:25 UTC. Source baseline:
`368d7001b90ade026efcc71b4b057683eaa4ffaa`. Build 1 is a source setting only;
no distribution candidate has been frozen, archived or uploaded in this workflow.

## Authorization and target

Owner authorized release and submission on 2026-09-28; this supersedes the historical
unsent-only handoff. Chrome was explicitly selected. No new test execution was
authorized, and no tests ran. Physical iPhone 13 testing is owner-reported, without
an identified processed distribution build. It is not agent-run acceptance evidence.

- Apple Developer team: `QHL89A7A8J`, Jesper Bjerre, observed in Chrome.
- Bundle ID: `com.hyldenbrandt.donkeytrump3d`, newly registered after absence check.
- App Store Connect ID: `6817091486`, newly created after absence check.
- Name/platform/language: Donkey Trump 3D / iOS / English (U.S.).
- SKU: `donkeytrump3d-ios`.
- [Version](https://appstoreconnect.apple.com/apps/6817091486/distribution/ios/version/inflight)
  status: Prepare for Submission.

## Observed operation states

| Operation | Before | After / actual evidence |
|---|---|---|
| Chrome connection | Historical import failure | Plugin26.820.60940 initialized; Connect and Developer pages read |
| Bundle registration | Absent from Developer identifier list | Exact explicit ID visible in refreshed list |
| App creation | Absent from Connect app list | App6817091486 and version1.0 visible after reload |
| App access | New record | Limited Access with existing owner selected; no extra user selected |
| Version copy | Empty | [Exact listing](listing-en.md) saved and matched after reload |
| Sign-in requirement | Checked by default | Unchecked, verified after reload |
| Release mode | Automatic default | Manual, verified after reload |
| Subtitle/categories | Empty | Entered subtitle `Climb. Dodge. Rescue.`, Games / Action / Casual; save/readback incomplete due dialog |
| EU trader status | Existing account default | UI states developer identified as non-trader for this app; not changed |
| Screenshots | Empty | None uploaded; displayed slot requested6.5-inch1242×2688/2688×1242 or1284×2778/2778×1284 |
| Build | No selected/uploaded build shown | No build uploaded or selected |
| Submission/release | Prepare for Submission | No Add for Review/Submit/Release action performed |

## Immediate resumption

The original Connect tab is on App Information with a blocking confirmation dialog
after a navigation attempt. Browser getJsDialog recovery timed out twice. Owner was
asked to select Cancel and report ready. Read App Information first to establish
whether subtitle/categories saved; do not assume the click was acknowledged.

Missing genuine inputs requested: review email/phone and cover/music AI services and
distribution licence details. Owner's earlier rights assertion remains valid evidence
of their assertion; tool/licence details are not fabricated. Connect subsequently
showed an existing non-trader declaration, so that state is already discoverable.

Remaining work includes distribution signing/archive/upload and candidate identity,
screenshots, privacy/content/age/export declarations, pricing/territories and alternate
platform settings, final acceptance evidence and the required independent review.
Only an Apple Development signing identity was found locally. The usual Xcode
Archives directory contained no Donkey/Trump-named archive in the inspected listing.
No distribution-access failure has been established by an attempted export.

This record does not mark implementation or assessment complete. Per AGENTS.md,
independent review starts after the authorized work and required inputs/checks are
complete; no unfinished package was submitted for review. Historical checks remain
historical. No tests, smoke tests, app builds or deployments ran in this retry.

## Resumed after owner dismissed dialog — 2026-09-28, 20:28–20:33 UTC

Owner replied “klar”. A fresh supported Chrome session read the existing version
and App Information. Subtitle and Games / Action / Casual were present, resolving
the earlier save uncertainty without repeating creation or edits.

Saved and read back:

- Free price schedule: all175 stored price rows showed0,00, with no nonzero rows.
- Availability:173 countries/regions on future release. China mainland and Vietnam
  show Not Available. The [full rendered table](territory-readback.json) preserves
  all175 country/region states. No pre-order was configured.
- Future-territory auto-expansion remained unchecked on reopening Manage Availability.
- Apple silicon Mac and Apple Vision Pro availability unchecked, saved and observed
  again after navigation.
- Privacy policy URL saved and read back after reload:
  `https://donkeytrump-api-p.azurewebsites.net/privacy`.

The territory exclusions follow the existing store contract: no China/Vietnam game
licence documents are available. Apple's current [app-information reference](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)
states the game approval/document requirements for mainland China and the game
licence requirement for Vietnam. Other territory selections remain contingent on
the remaining content/age/privacy and rights gates; this is not a claim of universal
legal clearance. Price configuration includes excluded territories but does not make
them available.

The browser-dialog blocker is resolved. Remaining genuine inputs are the requested
Apple review contact email/phone and the AI cover/music service/licence provenance.
Content-rights and privacy collection declarations, age ratings, signed distribution
candidate, final media, candidate acceptance and independent release review remain
unfinished. No build was uploaded, no review submission/release occurred, and no
tests, app builds or deployments ran during this resumption. New document whitespace
was checked with `git diff --check`; that is not application acceptance evidence.
