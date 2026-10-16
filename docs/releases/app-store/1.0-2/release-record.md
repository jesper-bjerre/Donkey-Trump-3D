# Donkey Trump 3D — 1.0 (2), Connect draft prepared

## Current status — 2026-09-29

**Store artifact implementation and Connect draft are prepared. Not submitted or released.**
Build 2 is uploaded/processed/selected; the new icon and all five real screenshots
are saved in order. Connect accepted Add for Review and shows Ready for Review / one
Item Ready to Submit. [Exact readback](connect-readback.md), [declarations](declarations.md),
[territories](territories.md), [candidate identity](candidate.json).

Independent review round 1 accepted the icon/configuration/images/draft. Its six
findings are preserved in [the verdict](review/round1-verdict.md). Documentation
corrections are being finalized for focused re-review. **Submission is held for the
owner's broader final-content rights confirmation**, requested after R-01;
[content-rights basis](content-rights.md). Existing Connect non-trader status was
not set/changed by the lead, resolving the missing-record question R-02.

Release acceptance remains unestablished for T042 exact-build physical iPhone 13,
T044 iPad compatibility behavior and T043 report-to-disposition workflow. T008
final rights confirmation remains pending. See [acceptance boundaries](acceptance-status.md).
No tests were requested or run. No old owner result is represented as a build 2 pass.
Manual release remains enabled, separating submission from publication.

Next action: record the requested owner fact, finish focused independent review,
and only then perform the already-authorized submission if its prerequisites pass.
No repeat build/media upload is needed. Do not infer release readiness from Connect's label.

## Historical working notes — superseded by the current status above

The sections below preserve earlier observations and failed attempts chronologically.
Statements that screenshots are missing or review has not started describe those
earlier stages; they are not the current state.

# Earlier preparation record

Observed 2026-09-29. App Store Connect app `6817091486`, bundle
`com.hyldenbrandt.donkeytrump3d`, team `QHL89A7A8J`, Jesper Bjerre.
[Version in Connect](https://appstoreconnect.apple.com/apps/6817091486/distribution/ios/version/inflight).
The owner authorized submission/release and supplied the review contact privately.
This record contains no private email or phone number.

## Local candidate and artwork

- Base commit: `368d7001b90ade026efcc71b4b057683eaa4ffaa`; uncommitted candidate.
  [Source manifest](candidate-source-manifest.json) and [archive/export identity](candidate.json).
- Imported the supplied light, dark and tinted 1024-pixel AppIcon catalog; removed
  the superseded AppIcon.png. The three PNGs match the supplied artwork byte for byte.
- App build number increased to 2 in all five app configurations. The previously
  reviewed iPhone-only orientation fix is preserved. Gameplay source is unchanged.
- Pre-edit copies, including the already corrected iPhone-only project, are in
  `/tmp/dt3d-release-20260929/pre-edit/`. This captured base differs from Git HEAD.
- Release archive succeeded using `DonkeyTrump3D PROD`, configuration Release,
  generic iOS device destination. Archive inspection confirms version 1.0/build 2,
  iPhone family `[1]`, minimum iOS 26, landscape orientations, AppIcon and PROD URL.
- `python3 src/scripts/validate-ios-release.py archive <archive>` returned
  `Validated archive identity: 1.0 2`; `codesign --verify --deep --strict <app>` exited 0.
  These are artifact/configuration checks, not runtime tests.
- App Store distribution export succeeded with automatic signing and build-number
  management disabled. IPA SHA-256 is recorded in candidate.json. No claim is made
  that a subsequently re-signed/thinned Apple download has the same IPA bytes.

## Five real screenshots

[Final images](screenshots-en/) are ordered 01–05, English, opaque JPEG, 2868×1320.
`sips` confirmed dimensions and no alpha for all five. Actual pixels were inspected.
[Raw captures](raw-captures/) and [editable layouts](screenshot-layouts/) are retained;
[asset hashes](asset-manifest.json) identify the files.

Source: clean iPhone 17 Pro Max simulator, iOS 26.5, simulator UUID
`D8200BBF-081E-428B-954F-582ED5249596`, AppStoreCapture build 1.0 (2), using the same
source and Release optimizations with the isolated DEV capture origin. A first
capture containing an Apple sign-in prompt was rejected and is not in this package.

The supplied folder contains templates explicitly marked NOT FOR UPLOAD. Those
were not submitted. Its original branding/layout frames the complete real app
capture at its original aspect ratio. The final sequence shows gameplay, barrels,
actual control instructions, title screen and actual highscore UI. Image 03 is the
help screen, not the second-level/rescue image proposed in the older store contract;
that specific story is not claimed as captured. Captions describe the actual images.

Highscore capture used only the disposable DEV `highscores-capture` container,
the existing DEV managed identity and the approved synthetic starter entries.
The correctly invoked `moderation capture-seed --target dev --apply` acknowledged
capture-only application. Actual visible names were inspected. The capture-delete
command subsequently acknowledged deletion; Capture__Enabled was removed, the
temporary container-scoped role was removed (readback `[]`), and the disposable
container was deleted (management-plane readback `[]`). Ordinary DEV/PROD data
and PROD configuration were not changed. No storage account keys were used.

## Connect changes saved/read back

- [English listing](listing-en.md), subtitle and Games / Action / Casual retained.
- Genuine review contact saved and visually checked; contact values are intentionally
  redacted by the browser's DOM view and must not be overwritten based on that view.
- Sign-in not required; Game Center off; manual release remains selected.
- Content Rights: necessary rights to third-party content, based on the owner's
  recorded rights assertion. The new artwork README documents its image-generator
  provenance. This is not independent legal/licence verification; music generator
  details were requested and remain unspecified.
- Age questionnaire saved: public names/UGC, frequent cartoon violence, harmful
  objects and contests; other queried mature/gambling/medical content absent.
  Apple calculated global 13+, with regional 16+ Brazil/Vietnam and 12+ Korea.
- Privacy published and observed as “Published ... by Jesper Bjerre”: Gameplay
  Content, Customer Support, User ID and Device ID linked for App Functionality;
  Other Diagnostic Data not linked, for App Functionality; no tracking.
  Basis: public handles/scores, installation safeguard identifier, reports/receipts,
  bounded request diagnostics. Current PROD HTTP logging, request tracing and
  detailed errors were disabled. Provider retention was not independently established.
- Privacy URL is `https://donkeytrump-api-p.azurewebsites.net/privacy`.
- Existing free pricing/173 planned territories retained; China and Vietnam excluded.
  Current readback still shows Mac and Vision Pro unavailable. Age-based regional
  restrictions are separate from this configured availability count.

## Outstanding state and evidence limits

Screenshot upload was rejected by the Chrome extension with `Not allowed`. Its
documented recovery requires the owner to enable “Allow access to file URLs” for
the ChatGPT browser extension. All five local images are prepared; none is yet
confirmed uploaded/processed in Connect.

The command-line build upload failed with an App Store Connect credential/provider
error. Organizer reached upload but reported “Couldn’t communicate with a helper
application.” A fresh Connect read showed only build 1 before the retry. The single Organizer
retry then succeeded at 16:11:47 UTC, with no reported warnings/errors. Connect
subsequently displayed version 1.0 (2), Processing, created 6:11 PM local time.
Apple then marked build 2 Complete. It was selected on version 1.0; the Missing
Compliance requirement was resolved with “None of the algorithms mentioned above”.
Source imports only Apple frameworks; online transport uses URLSession HTTPS and
installation randomness/file protection use Security/Foundation OS APIs. No custom
cryptographic implementation or third-party encryption library is bundled.
Connect build ID: `00b725f5-5680-407b-81ac-bd35104a1a42`. Do not upload again.

After saving build 2, Add for Review was attempted. Connect returned “Unable to
Add for Review” with exactly one listed requirement: “You must upload a screenshot
for 6.5-inch iPhone displays.” No review draft/submission/release was created.
The Media Manager accepts the prepared 2868×1320 images in its 6.9-inch group,
which explicitly covers 6.5-, 6.7- and 6.9-inch displays. Complete that upload,
confirm processing/order, then repeat the required-field check.

No Submit for Review or release action has been performed.
No tests were requested or run. The owner previously reported iPhone 13 testing;
the OS/scenarios and exact processed candidate were not supplied. Simulator capture
is not physical acceptance evidence. The five-image preparation does not prove all
historical release acceptance scenarios.

Independent review of the finished release package has not started: remote screenshot upload
and required preparation remain incomplete. The required Claude Code route was
successfully probed (2.1.283, claude-opus-5-5, explicit high effort, actual provider
usage; session `23528edd-1343-4885-bac1-221df526c655`). That is access evidence only,
not a review verdict. No complete/release-ready claim is made.


## Resumed with file access enabled — 2026-09-29, 16:40–16:47 UTC

The owner replied ready after enabling file-URL access. The original Documents
paths produced no saved media despite no error. Byte-identical copies under
`/tmp/dt3d-release-20260929/browser-upload/` uploaded successfully. Five images
processed. Apple initially ordered concurrent uploads 01,04,02,03,05; the title
image was moved to fourth. After a reload and navigation back to the version,
Connect showed exactly 01-overview, 02-barrels, 03-controls, 04-title, 05-highscores.
The 6.5-inch set explicitly uses the 6.9-inch images. Final thumbnails were inspected.
No placeholder image was uploaded, and the new build icon is visible in Connect.

Add for Review then succeeded: version 1.0 is Ready for Review with one Draft
Submission, build 2, all five images, manual release and no required-field errors.
No Submit for Review action has been taken. The screenshot blocker is resolved.
The finished store-artifact implementation is now frozen for independent review;
release/device acceptance limitations above remain explicit and are not a pass.
