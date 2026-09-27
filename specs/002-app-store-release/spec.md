# Feature Specification: App Store Release Preparation

**Feature Branch**: `main` (existing branch; no feature branch created)

**Feature Directory**: `specs/002-app-store-release`

**Created**: 2026-09-26

**Status**: Specification for the remaining App Store preparation. Separately authorized startup/audio, highscore and backend deployment work has recorded evidence; store assets, declarations, distribution-candidate acceptance and Connect preparation are not thereby complete.

**Input**: Prepare Donkey Trump 3D for the Apple App Store, create the required descriptions and images, and enter the information in App Store Connect using the owner's signed-in Chrome session. The owner initially requested only the final release action, then explicitly clarified that the owner will also submit the prepared version to Apple's review.

## Clarifications

### Session 2026-09-26

- Q: Must a highscore publication block survive uninstalling and reinstalling the app on the same iPhone? → A: No. Block only the current app installation; reinstallation may reset the block. Local gameplay remains available.
- Q: Who is responsible for handling reports of inappropriate highscore names after release? → A: The app owner handles reports, responds within one working day and is responsible for removing offending entries and blocking abusive app installations.
- Q: What is the monthly operating budget for the backend, storage and support/privacy pages? → A: DKK 100 including VAT, excluding Apple Developer membership and domain purchases. Reuse the existing PROD App Service Plan; the owner expects that it currently hosts one ASP.NET app, which must be verified.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Understand the game from its store page (Priority: P1)

As a prospective player, I can understand the native 3D arcade game, its controls, its satire and its optional online highscores from accurate English descriptions and attractive pictures of the actual game.

**Why this priority**: The owner explicitly requested ready-to-use descriptions and images, and players should receive the experience advertised.

**Independent Test**: Compare the complete local listing and image set with the release candidate. Verify every advertised capability, read each caption at its intended display size, and confirm that all required iPhone image slots have suitable assets.

**Acceptance Scenarios**:

1. **Given** the verified game and selected release scope, **When** the listing is prepared, **Then** its title, subtitle, description, keywords, categories and supporting copy accurately describe the 3D game and distinguish offline gameplay from online highscores.
2. **Given** the candidate's normal player experience, **When** screenshots are prepared, **Then** five ordered landscape screenshots show representative gameplay and features, without invented scenes, debug controls, real players' personal information or claims absent from the candidate.
3. **Given** iPhone-only distribution, **When** media is validated, **Then** the icon and required screenshot sets meet Apple's current accepted format, size and content requirements; larger-display requirements are not assumed satisfied by iPhone 13 captures alone.
4. **Given** original satirical content, **When** copy and images are reviewed, **Then** the page preserves the no-affiliation statement, avoids copied third-party assets and makes no unsupported endorsement or licensing claim.
5. **Given** a cold app launch, **When** startup is in progress, **Then** the owner's Donkey Trump cover appears proportionally with its full title and characters visible, shows an approximate progress bar and yields to the usable game as soon as required local loading finishes, without an artificial delay or network dependency. Possible store use is supporting key art around actual game captures, never a substitute for the in-use screenshot set.
6. **Given** Sound is enabled and the app is active, **When** the supplied music becomes ready, **Then** it loops across runtime loading and the title menu, stops when the intro starts and returns on title entry; music preparation never delays play.

### User Story 2 - Receive a working and supportable release (Priority: P1)

As a player, I receive the tested game, can use the advertised highscore list and can find genuine privacy and support information. Other players cannot use public names as an unchecked channel for offensive content.

**Why this priority**: A finished product page cannot compensate for a broken release, unavailable advertised services or missing public-name safeguards.

**Independent Test**: Install the exact distribution candidate on a physical iPhone 13 and complete the release journeys, including offline play, actual online highscore publication, a failed submission, support/privacy access and the public-name abuse workflow. Match the evidence to the uploaded candidate.

**Acceptance Scenarios**:

1. **Given** a clean install and an update where an earlier build exists, **When** the player starts, completes and restarts runs, **Then** gameplay, intro, settings and personal best behave as documented in both landscape orientations; offline or slow highscores never prevent play.
2. **Given** the live service and a qualifying run, **When** the player explicitly publishes a chosen name, **Then** the shared result appears as advertised; failure preserves the personal best without queuing a later upload or falsely confirming a save.
3. **Given** a prohibited name or a displayed entry reported as abusive, **When** the relevant safeguard is exercised, **Then** prohibited submissions are prevented, reports reach the app owner for a response within one working day, offending entries can be removed and the offending app installation can be blocked from publishing further scores without introducing player accounts; local gameplay remains available.
4. **Given** the shipped data flows and service operations, **When** a player opens support or privacy information, **Then** public usable pages identify a genuine contact and explain publication, retention and removal/reporting consistently with the store disclosures.
5. **Given** a missing physical-device result, an unreachable service or an unresolved material release defect, **When** readiness is assessed, **Then** the candidate is reported as blocked with concrete evidence instead of being called ready because simulator tests passed.
6. **Given** fewer than ten real ranked results, **When** the highscore list is read, **Then** low-scoring cartoon starter entries keep at least ten ranked entries in the list while the list still supports the best 100; a qualifying player receives a clear name-entry dialog with an obvious input and submit button, without the removed public-name/real-name advisory text.

### User Story 3 - Have a complete and correct Connect version (Priority: P1)

As the app owner, I want the correct app record filled out and its build uploaded, so I do not have to copy descriptions, resize images, complete technical declarations or repair submission errors myself.

**Why this priority**: Entering and verifying the information in App Store Connect is an explicit part of the requested end result.

**Independent Test**: Reopen the target version in the owner's Chrome session, compare saved fields, processed images and the selected build with the release package, and confirm that preparation for submission has no unresolved validation errors.

**Acceptance Scenarios**:

1. **Given** authenticated access to the intended organization, **When** the app is located, **Then** an existing matching record is reused; a new record is created only after confirming none exists. Other apps and versions remain unchanged.
2. **Given** completed copy, images and a valid distribution candidate, **When** the release package is entered and uploaded, **Then** Connect shows the intended saved text, image order, processed build, support/privacy links, categories, free price and eligible territories after a fresh read.
3. **Given** the actual candidate and verified ownership information, **When** privacy, age, content-rights, encryption and applicable territory declarations are completed, **Then** every answer has an evidence basis; no-login is not treated as proof that no data is collected.
4. **Given** a required fact unavailable from the project or authorized account, **When** it blocks a declaration, **Then** it is requested in a consolidated owner-input request. No identity, contact detail, rights claim, trader status or legal acceptance is invented.

### User Story 4 - Retain control of review submission and release (Priority: P1)

As the owner, I receive a fully prepared version and draft submission, ready for me to submit to Apple's review. After approval, I also retain the final public release decision.

**Why this priority**: The owner explicitly chose to submit to Apple personally. Completing preparation must not trigger review or automatic publication.

**Independent Test**: Inspect the correct app/version and its draft in Connect. Confirm the intended build and listing are complete, submission validation is clear and the owner's Submit for Review action is available. Verify that manual release is selected and nothing has been sent to Apple for review or publicly released by the agent.

**Acceptance Scenarios**:

1. **Given** all candidate, content and account prerequisites pass, **When** the submission draft is assembled, **Then** the version can be added for review without sending it; the workflow stops before Submit for Review or any equivalent sending action.
2. **Given** the prepared draft, **When** completion is reported, **Then** the owner receives its direct Connect link, version/build and concise remaining actions: submit for review, handle subsequent Apple feedback, and manually release after approval. No copy, screenshots or build selection remain for the owner to prepare.
3. **Given** release settings are inspected, **When** readiness is recorded, **Then** manual release is selected and automatic release, scheduled publication and pre-order are disabled.
4. **Given** Connect requires an unexpected action that would immediately submit or publish, **When** preparation reaches that boundary, **Then** the agent stops before that action, records the precise state and does not label an unvalidated version ready.

### User Story 5 - Resume safely and inspect the result (Priority: P2)

As the owner, I can inspect and resume preparation without duplicate uploads, lost metadata or confusion over which tested build and screenshots belong together.

**Why this priority**: Uploads and processing can span work sessions; continuity avoids making the owner reconstruct completed work.

**Independent Test**: Interrupt preparation after saving metadata or uploading a build, then resume using the release record. Verify remote state before continuing and detect differences rather than blindly repeating actions.

**Acceptance Scenarios**:

1. **Given** an interrupted browser or upload session, **When** work resumes, **Then** saved values and processing state are checked first; ambiguous results do not create duplicate apps, builds or drafts.
2. **Given** a candidate change after screenshots or tests, **When** the package is updated, **Then** affected media, disclosures and checks are reassessed and remain tied to the selected build.
3. **Given** a blocked prerequisite, **When** status is recorded, **Then** local preparation, saved Connect data, upload, draft readiness, Apple submission and publication remain distinct, with a concrete next action for outstanding preparation.
4. **Given** the existing PROD App Service Plan, **When** production preparation is validated, **Then** the actual plan and hosted apps are recorded, reuse fits the verified capacity and DKK 100/month additional-cost budget, and existing apps pass documented before/after availability checks. Any required plan change or budget increase remains a separate owner decision.

### Edge Cases

- Chrome cannot be connected, the session expires, two-factor authentication is required, the wrong organization is selected or the account lacks a required role.
- A matching app already exists, its name is unavailable, its version is locked for review, or earlier distribution prevents narrowing device support to iPhone.
- The iPhone candidate can run in iPad compatibility mode but fails to launch or leaves landscape controls, reporting or privacy information unreachable; this remains a readiness defect even though native iPad support is excluded.
- Apple changes media/declaration requirements; files pass local checks but fail or reorder during remote processing.
- An upload times out but is already processing; a version/build number is already used; the selected build differs from the tested archive.
- The public service is unavailable, cold or misconfigured; a save acknowledgement is lost; screenshots promise features absent from the actual release.
- The existing PROD App Service Plan cannot be uniquely identified, hosts more apps than expected, lacks compatible runtime/capacity, or the projected additional cost exceeds DKK 100/month including VAT. Verify actual shared resources and preserve their workloads; an unresolved constraint blocks further provisioning and draft readiness, not independent release preparation.
- Public names contain abuse, impersonation or personal information; removal must not overwrite unrelated scores or reintroduce retired submissions.
- A blocked player reinstalls the app. The block applies only to the previous installation and may reset; preventing this bypass is outside the agreed blocking scope. Ordinary play remains available while an installation is blocked.
- A public support/privacy page requires login or describes different data flows from the app, service, diagnostics or abuse-prevention controls.
- Export, trader, content-rights or territory answers require owner-only facts or an account-holder agreement. Unknowns block only dependent work while independent preparation continues.
- Connect changes its workflow so the next available button submits immediately. The owner's review-submission boundary still applies.
- A material rename, new monetization or player account system appears necessary for eligibility. That is an explicit product decision, not a silent change to obtain a green status.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Preparation MUST establish and record the intended owner organization, app identity, existing store record, version and build before external changes, reusing matching records and preserving unrelated apps, versions and user work.
- **FR-002**: The release MUST target iPhone, landscape, with the existing minimum supported system version. Native iPad support and iPad-specific assets/claims are excluded; any compatibility behavior imposed by Apple MUST be documented rather than presented as validated native iPad support. Optional Mac or other-platform availability MUST be disabled where offered. Existing distribution history MUST be checked before narrowing support; an incompatible prior release is a concrete blocker requiring a resolved product decision.
- **FR-003**: The English listing MUST contain the complete name, subtitle, description, keywords, categories and real copyright attribution. Promotional copy is included; update notes are supplied when an existing version makes them applicable. All text MUST fit current field limits and match the candidate, preserving original parody/no-affiliation copy.
- **FR-004**: The package MUST contain five ordered screenshots per required iPhone display set and an accepted app icon. Screenshots MUST come from the release-equivalent game, show supported functionality and pass format, dimensions, orientation, opacity and legibility checks. Captions/design framing are allowed without fabricated gameplay. Optional preview video is outside scope.
- **FR-005**: Every visual asset and description MUST be traceable to the candidate, language, display set, order and uploaded version. Source captures and editable copy MUST be retained; real-player information and development-only UI MUST not appear in store media.
- **FR-006**: Rights, originality and content suitability MUST be assessed for the full shipped experience: app/character names, in-game text, real public figures' names/depictions, icon, models, audio, marketing and the overall gameplay/presentation resemblance to its reference game. The assessment MUST use project provenance and current store rules and support FR-009's declarations. Copied assets, unsupported rights claims and implied endorsement MUST be removed or treated as concrete blockers. Parody wording alone is not proof of permission or approval; an unresolved material naming/content issue requires an explicit product decision, not a silent rename or an unsupported legal conclusion.
- **FR-007**: Public support and privacy pages MUST be created or updated, published at genuine owner-controlled addresses and reachable without login before readiness. They MUST identify the app and a working contact route and explain actual public submissions, supporting data, retention, reporting/removal and third-party processing. The shipped app MUST make its privacy policy easily accessible.
- **FR-008**: Store privacy answers MUST reflect the shipped app, third-party components and live service/diagnostics, including optional public submissions and abuse-prevention data. Local-only settings MUST be distinguished from transmitted data; accounts, tracking and advertising MUST not be added incidentally.
- **FR-009**: Age ratings, content rights, export/encryption declarations, accessibility claims and applicable territory requirements MUST have a factual basis. Missing facts MUST be obtained before attestation; a desired rating or unchecked assumption is not evidence.
- **FR-010**: The release MUST be free, without purchases, advertising or subscriptions, in all territories whose applicable requirements can be fulfilled. Each excluded territory MUST have a recorded reason. Automatic inclusion of future territories MUST not bypass verification; pre-order MUST be disabled.
- **FR-011**: Preparation MUST produce, validate, upload and select a signed distribution candidate accepted for processing by Apple. The selected build MUST match the tested candidate, contain the intended icon and production configuration and exclude development-only behavior. Processing completion MUST be verified.
- **FR-012**: The advertised global top-100 service MUST be working in its real production environment before draft readiness. The backend MUST reuse the owner's existing PROD App Service Plan. Preparation MUST identify the actual subscription, resource group and plan, verify ownership/access, current hosted apps, runtime compatibility and available capacity, and preserve existing workloads. The owner's expectation of one existing ASP.NET app is an input to verify, not an established inventory. The game's additional recurring cost for backend, storage, support/privacy pages and necessary monitoring MUST fit within DKK 100 per month including VAT; the already-committed plan cost MUST be recorded separately. Apple Developer membership and domain purchases are excluded from this budget. For already deployed resources, preparation MUST verify the recorded traffic/storage assumptions and additional-cost estimate and record the existing committed plan-cost baseline before draft readiness; the [deployment cost notes](../../docs/backend-deployment.md#capacity-and-cost) are dated inputs to refresh, not an automatic release pass. Any further provisioning MUST have its traffic/storage assumptions and cost estimate recorded beforehand. Creating a replacement/additional plan, changing the existing plan's tier or scale, or exceeding this budget requires a separate owner decision. If the existing plan cannot meet the requirements, report that concrete constraint without silently altering the shared plan or its apps.
- **FR-013**: Release acceptance MUST demonstrate online reading/publication, multiple-player persistence, honest unconfirmed-save handling and bounded failures while preserving offline play, local bests and no deferred uploads. An empty production address is not completion of the advertised feature.
- **FR-014**: Public-name safeguards MUST provide prevention of objectionable submissions, an in-app reporting route, operator removal, blocking of abusive participation and public contact information. The app owner MUST be the responsible operator after release, handling reports and responding within at most one working day. Preparation MUST establish a genuine contact route to the owner and demonstrate the report-to-disposition flow, including the owner's ability to remove offending entries and block abusive app installations. Blocking MUST prevent further highscore publication by the current app installation, including under a different chosen name, while preserving local gameplay. Reinstallation MAY reset the block; player login and persistent identification across installations MUST NOT be required. These minimum safeguards extend the earlier highscore scope; player login, chat and a general social platform remain excluded.
- **FR-015**: Abuse-prevention changes MUST preserve anonymous play, ranking and shared-data integrity. Any added retained information MUST have a defined minimum purpose, retention and access boundary and appear in privacy disclosures. Removal MUST preserve unrelated entries and existing submission/failure guarantees.
- **FR-016**: The candidate MUST pass affected automated checks and relevant gameplay/highscore regressions. Physical iPhone 13 evidence MUST cover both-landscape touch, intro and silent-switch audio, in-game mute, haptics, lifecycle, larger text/VoiceOver for applicable controls and sustained play. Unperformed physical checks remain readiness blockers. The selected iPhone candidate MUST also receive an iPad compatibility-mode smoke check covering launch, landscape presentation, reachable touch controls and highscore/report/privacy flows; failures block readiness. A clearly identified simulator check is sufficient for this compatibility gate and MUST NOT be represented as native iPad support or physical-device evidence.
- **FR-017**: App Review information MUST include genuine reachable contact details and instructions to inspect the full game and highscore flow. The no-login experience MUST be explained without fabricated credentials or review-only behavior differing from the release.
- **FR-018**: All applicable required Connect fields, declarations, images and the selected build MUST be saved and verified by a fresh read of the intended app/version. Local files, successful typing or upload-start events alone do not prove saved/processed content.
- **FR-019**: Browser work MUST use the owner's authorized Chrome session without extracting passwords, cookies or session secrets. Missing access or an owner-only account action MUST be reported concretely while independent preparation continues.
- **FR-020**: Once readiness gates pass, preparation MUST assemble and validate the submission draft with the correct version/build and manual release selected. Adding a version for review is allowed only while it remains unsent. The agent MUST NOT invoke Submit for Review, an equivalent sending action, automatic/scheduled publication or final public release.
- **FR-021**: Completion MUST leave a validated, unsent version ready for the owner's review submission, with no remaining copy, media, declaration or build-selection work. The actual version/draft state and direct Connect link MUST be recorded. Apple review, response to later review feedback and final release belong to the owner and are outside this preparation scope.
- **FR-022**: A durable release record MUST identify artifact and candidate identities, version/build, saved Connect values, media verification, checks, declaration evidence, processing/draft status and blockers. It MUST support safe resumption without duplicate records or blind retries and give the owner concise submission and later manual-release instructions.
- **FR-023**: Preparation MUST preserve the constitution and independent cross-vendor review process. Specification, implementation, candidate readiness, upload, review submission, Apple approval and publication MUST be reported separately. Agent consensus does not authorize sending the owner's submission or publishing the app.
- **FR-024**: The app MUST use the owner-supplied [DonkeyTrumpCover.png](../../docs/design/images/DonkeyTrumpCover.png) during startup, preserving its proportions and the full motif across supported landscape layouts. A progress bar MUST indicate that loading is underway; approximate progress is acceptable. Startup MUST remain local and automatically yield to the game as soon as required local loading finishes, without a minimum display timer or extra action. Optional highscore loading MUST remain asynchronous and MUST NOT hold the cover or prevent starting a game; opening highscores before a response MAY show a waiting state with usable navigation. The original image and supplied prompt MUST be retained as provenance. Store use is optional supporting artwork subject to FR-004–FR-006; it MUST NOT imply that the illustration is actual 3D gameplay or replace the required in-use screenshots.
- **FR-025**: The app MUST use the owner-supplied music from [docs/design/music](../../docs/design/music/) during runtime loading and the title menu, including menu overlays. Preparation MUST be asynchronous and MUST NOT delay startup or play. Playback MUST respect Sound, pause when the app becomes inactive, resume only while the menu is still requested, stop for the intro/game and return on title entry. Late preparation MUST NOT restart music for a departed menu. The static system launch screen is not required to execute audio. The selected bundled asset and its provenance MUST be recorded and included in FR-006 and FR-016 acceptance.
- **FR-026**: The release MUST retain the agreed highscore behavior: at least ten ranked entries in the list using low-scoring cartoon starter names when necessary, while preserving the top-100 capacity and ranking rules. Qualification MUST present a dialog with a clear name input and submit action. The dialog MUST omit the public-name and real-name advisory text removed at the owner's request; the existing in-app privacy/help copy MUST explain that a submitted name and score appear on the public list, satisfying the public-explanation requirement without a reminder in the dialog. Explicit submission and the remaining privacy disclosures remain governed by FR-007–FR-008 and the highscore contract.

### Key Entities

- **Release candidate**: The game version/build, supported devices, source identity, distribution artifact and corresponding test evidence.
- **Store listing**: Language-specific copy, categories, public addresses, price, territories and the app/version they describe.
- **Media asset**: Icon or screenshot, its source capture, display set, language, order, candidate provenance and upload validation.
- **Release declaration**: A privacy, age, rights, export, accessibility or territory answer with supporting facts and any required owner input.
- **Public-name report**: Offending entry reference, report status and minimum information needed for removal or abuse prevention, without becoming a player account or tracking profile.
- **Submission draft and release record**: The prepared but unsent candidate/listing, observed Connect status, validation evidence and owner-controlled next steps.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every applicable required field and declaration is complete and verified, with zero placeholder identities, broken support/privacy links or unresolved submission-validation errors.
- **SC-002**: Every required iPhone screenshot set contains five correctly ordered accepted images; every image and listing claim matches the candidate, with zero debug artifacts, fabricated features or real-player personal information.
- **SC-003**: All required release journeys pass on the identified candidate, including physical iPhone checks, real online publication and service-failure play; no simulator result is counted as physical evidence.
- **SC-004**: The demonstrated public-name workflow prevents a prohibited submission, delivers a report to the app owner and records the owner's response within one working day, removes an offending entry without altering unrelated results and rejects further submissions from the blocked app installation, including a changed public name, while allowing local gameplay. Survival of a block after uninstall/reinstall is not an acceptance requirement.
- **SC-005**: Reopening the store-management page shows the intended saved text, images and exact tested build, with no duplicate app or accidental changes to other versions.
- **SC-006**: The owner can submit the prepared version for review without supplying further copy, images, declarations or builds. There are zero agent-initiated review submissions or public releases; manual release is selected for later owner control.
- **SC-007**: After an interruption, the release record identifies completed work, external processing, remaining blockers and the next action without reconstructing materials or build identity from chat history. It identifies the reused PROD plan and verified existing apps, records the existing cost baseline and an additional-cost estimate of at most DKK 100/month including VAT under stated usage assumptions, and retains before/after availability evidence for the existing apps.
- **SC-008**: Cold-launch checks show the complete supplied illustration without distortion or cut-off title/characters and an approximate progress bar while loading, followed by a reachable title menu and playable game, with no added waiting period or network requirement. A slow or unavailable highscore response does not extend loading or block Start. The retained source matches the bundled cover, and any store composition distinguishes the illustration from actual gameplay.
- **SC-009**: Candidate checks demonstrate the supplied music during runtime loading when ready and in the title menu; Sound toggling, leaving/returning to the active app, Start/Skip and returning to title produce the expected playback without stale menu music or an audio-readiness gate. Physical-device audio evidence remains required by FR-016.
- **SC-010**: Release journeys demonstrate at least ten ranked entries in the highscore list when fewer than ten real results exist, continued top-100 ranking, and qualifying-score entry through the clear dialog without the removed advisory text. The in-app privacy/help view explains that a submitted name and score appear on the public list, and publication still requires an explicit submit action.

## Assumptions

- **Confirmed by the owner on 2026-09-26:** iPhone only; free in all countries where applicable requirements can be met; the owner personally submits to Apple's review. The original request's final-release wording is narrowed by that later explicit answer. Review submission and final public release are not agent actions.
- **Owner follow-up on 2026-09-26:** use the supplied cover as the loading screen and consider it for App Store artwork. This authorizes the focused launch-screen integration before the broader release plan; [cover-art.md](../../docs/design/cover-art.md) retains the image provenance and store-use boundaries.
- English store and in-game copy follow the existing constitution; additional localization is not in scope. The existing game name and original parody identity remain unless a concrete rights or eligibility problem requires an explicit product decision. Games/Arcade is the category direction, subject to current store choices and truthful classification. No child-directed positioning is assumed.
- The original invocation created the specification and quality evidence. Later owner instructions separately authorized backend deployment, iOS environment selection, highscore starter entries/dialog changes, minimal loading with progress and supplied menu music. This clarification incorporates those existing decisions without treating their individual implementation evidence as completion of the App Store release. Producing remaining release assets, completing candidate acceptance, publishing support/privacy pages and writing Connect data remain subsequent work.
- Highscores remain part of the release with anonymous/no-login play and no deferred uploads. Minimum public-name safeguards are expressly included in this release scope. No chat, player accounts, tracking, purchases or additional language is introduced.
- Public support/privacy pages and necessary production service setup are included. The owner selected DKK 100/month including VAT and reuse of the existing PROD App Service Plan. Because this plan is already in use, budget accounting treats the DKK 100 as the game's additional recurring spend and records existing committed plan charges separately. This is a planning constraint, not a verified price or an automatic billing cap. The original expectation of one existing ASP.NET app was an input to verify. The [2026-09-27 backend release record](../../docs/reviews/backend-release-2026-09-27.md) now records DEV/PROD deployment and shared-plan availability evidence; preparation MUST refresh relevant live state for the selected release candidate rather than treating this dated deployment as all release gates passing. Contact details, copyright owner, signing access and legal/trader facts must be established before dependent actions. Secrets and private contact evidence must stay outside the repository.
- **Owner follow-ups incorporated on 2026-09-27:** retain at least ten cartoon-seeded highscore entries with top-100 capacity; use a clear name-entry dialog without public-name/real-name reminders; show the loading cover only for required startup work, with approximate progress; and play supplied music during runtime loading and the title menu. [Loading evidence](../../docs/reviews/loading-progress-2026-09-27.md), [menu music evidence](../../docs/reviews/menu-music-2026-09-27.md) and the [highscore specification](../001-global-highscores/spec.md) document those separate changes. Physical-device and distribution-candidate checks remain outstanding until performed for the selected release.
- The owner's signed-in Chrome session is the intended access route. Actual account access, permissions, app existence and saved values are unverified: browser initialization failed before connection in this specification session. No external reading, saving or submission is claimed.
- The project currently enables iPad. Account history and Apple's support constraints must be checked before narrowing distribution. If narrowing an existing release is prohibited, resolve that concrete decision rather than silently adding iPad scope or claiming success.
- Physical hardware, genuine declarations and owner-only account agreements cannot be fabricated or bypassed. Missing inputs are requested early and together after checking available evidence. The ready-to-submit outcome is achieved only after these prerequisites are fulfilled.
- [Constitution v1.0.0](../../.specify/memory/constitution.md) governs the work. [Source notes](source-notes.md) distinguish local facts, current official references and unverified external state. Five screenshots per required set and the moderation response target are project acceptance choices, not claims that Apple specifies those exact numbers.
