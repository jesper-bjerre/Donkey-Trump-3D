# Release specification inputs — 2026-09-26

Supporting discovery for the specification, not executed release evidence. Refresh these inputs against the actual candidate and App Store Connect before implementation claims are made.

## Confirmed owner decisions

The owner answered the three questions during this specification session:

- First release: **iPhone only**.
- Price/availability: **free in all countries where the requirements can be fulfilled**.
- Handoff: **everything prepared, but the owner submits to Apple's review**. This overrides the earlier inferred endpoint of Apple approval followed only by manual release. Sending the review submission, handling later Apple review and the final public release are outside the preparation scope. Manual release is still selected for the owner's later control.

## Verified repository context

- [Project configuration](../../src/DonkeyTrump3D.xcodeproj/project.pbxproj) declares `com.hyldenbrandt.donkeytrump3d`, version `1.0`, build `1`, team `QHL89A7A8J`, iOS 26.0 and device families `1,2` (iPhone/iPad). These local values do not prove membership, signing availability, rights or an existing Connect record.
- Both configurations have an empty `HIGHSCORE_API_BASE_URL`. The [root guide](../../README.md) explicitly requires a real HTTPS service address. The release cannot advertise working global rankings while leaving this unset.
- [Player copy](../../src/DonkeyTrump3D/UI/Copy.swift) is English, describes original satire/no affiliation and optional public names/scores, and states no accounts/tracking or deferred uploads. No genuine support/privacy website address was established by this discovery.
- [Highscore validation](../001-global-highscores/validation.md) records local evidence and unperformed physical-device, Docker and live Azure checks. Its simulator results do not certify a future release archive.
- The [release runbook](../../docs/production-smoke-and-rollback.md) includes a physical-device matrix and distribution/recovery concerns. Some introductory test-count/deployment statements predate highscores; reconcile them to the actual release rather than copying them into store claims.
- Public names exist; the inspected UI/store files establish no existing reporting, removal or abusive-participant blocking workflow. The spec explicitly adds minimum public-name protection. Its design and privacy impact need planning; no claim is made that a word filter alone satisfies Apple's review.
- `specify preset resolve spec-template` selected `.specify/templates/spec-template.md`, core layer. Sequential numbering selects `002-app-store-release`. No extension hook configuration exists, so no branch hook ran; the Git branch remains `main`.

## Official Apple requirements consulted

These pages were opened on 2026-09-26. Recheck changing requirements and actual Connect validation while preparing the submission. The numeric asset/text examples below belong to planning inputs, not a permanently frozen platform contract.

| Source | Consequence for this specification |
|---|---|
| [Required, localizable and editable properties](https://developer.apple.com/help/app-store-connect/reference/app-information/required-localizable-and-editable-properties/) | Inventory app, version, pricing, privacy and applicable territory fields. Distinguish first-release fields from update-only fields. Text extraction loses some table checkmarks; actual required-field status must be verified in Connect. |
| [Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/) | Prepare copy within current limits. At discovery, description is limited to 4,000 characters and promotional text to 170. Screenshots are required. |
| [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) | Apple accepts 1–10 JPEG/PNG screenshots without transparency. This feature chooses five. iPhone 6.9-inch sets accept landscape 2868×1320, 2796×1290 or 2736×1260; the 6.5-inch set is required if a 6.9-inch set is absent. A 13-inch iPad set is required when shipping iPad support. iPhone 13's 2532×1170 captures alone are not assumed to cover a required larger-display slot. |
| [Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/) | A public privacy-policy URL and accurate data-handling disclosures are required. Include relevant third-party practices and optional remote submissions; no-account operation does not establish no data collection. |
| [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) | Check completeness, truthful media, original/licensed content and public names. Guideline 1.2 calls for filtering, reporting, blocking abusive users and contact details; 5.2 concerns intellectual property. Applying these to publicly submitted names is this spec's conservative product assessment, not a prior Apple ruling on this app. A parody disclaimer is not a guaranteed exemption. |
| [Submit an app](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/) | Required metadata and the correct build precede submission. Adding a version for review creates a draft-ready state; the separate Submit for Review action actually sends it. Preparation stops before that sending action. Account Holder, Admin or App Manager permissions are required. |
| [Select an App Store version release option](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/select-an-app-store-version-release-option/) | Select manual release. Apple approval can later lead to `Pending Developer Release`, where the owner releases the version. That future state is not this feature's completion gate: the owner now explicitly retains review submission too. |
| [EU Digital Services Act trader requirements](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/) | Establish the owner's applicable trader declaration and verified contacts. Do not infer non-trader status from a free app or invent legal facts. Regional availability depends on satisfying its requirements. |

Independent review prompted an additional live check of the same App Review Guidelines: 2.4.1 encourages iPhone apps to run on iPad where possible; 4.1 addresses copycat presentation; 1.1.1 addresses harmful targeted content and includes a qualified exception for professional political satire. Accordingly, FR-016 adds a labeled compatibility smoke check and FR-006 covers all shipped text, public figures and overall resemblance. These are readiness assessments, not claims of native iPad support, infringement or automatic satire exemption. The reviewer's speculation about a particular registered “Jumpman” trademark was not independently established and is not used as a factual basis for this spec.

## Access and inputs not yet verified

The user reports being signed in to Chrome on this Mac. The Chrome skill was read and its prescribed initialization attempted. Initialization returned `Importing module "node:process" is not allowed in node_repl`, before browser selection or account navigation. No alternate browser, cookie/session extraction, app creation, field entry or submission was attempted. This is a tool-initialization failure, not evidence that the user's login or extension is missing.

Implementation must verify the organization/app, account role, prior distribution/device-support constraints, signing/upload access, required account-holder agreements, contact/copyright/trader facts and intended cloud/public-site resources. Request missing facts together after inspecting available account/project evidence. Unknown legal terms or attestations must not be accepted by guessing.

The owner-confirmed scope is complete enough for planning despite those execution dependencies. Browser access, production setup, physical evidence, media creation and Connect entry have not been performed or reported as successful in this specification phase.

## Follow-up: owner-supplied cover

On 2026-09-26 the owner supplied [DonkeyTrumpCover.png](../../docs/design/images/DonkeyTrumpCover.png) and its generation prompt, requesting loading-screen use and possible App Store reuse. The image is a 1672 × 941 opaque landscape illustration; the [provenance/use record](../../docs/design/cover-art.md) preserves the prompt and separates this focused startup change from the remaining release work. FR-024/SC-008 cover this new request. Apple's [Guideline 2.3.3](https://developer.apple.com/app-store/review/guidelines/#accurate-metadata), checked for this follow-up, calls for in-use screenshots rather than only title/splash art; supporting overlays can accompany truthful gameplay captures.
