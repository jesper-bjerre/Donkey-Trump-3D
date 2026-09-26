# Feature Specification: App Store Release Preparation

**Feature Branch**: `main` (existing branch; no feature branch created)

**Feature Directory**: `specs/002-app-store-release`

**Created**: 2026-09-26

**Status**: Specification; release preparation has not been performed. This document defines the work to plan and implement next.

**Input**: Prepare Donkey Trump 3D for the Apple App Store, create the required descriptions and images, and enter the information in App Store Connect using the owner's signed-in Chrome session. The owner initially requested only the final release action, then explicitly clarified that the owner will also submit the prepared version to Apple's review.

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
5. **Given** a cold app launch, **When** startup is in progress, **Then** the owner's Donkey Trump cover appears proportionally with its full title and characters visible and yields to the usable game without an artificial delay or network dependency. Possible store use is supporting key art around actual game captures, never a substitute for the in-use screenshot set.

### User Story 2 - Receive a working and supportable release (Priority: P1)

As a player, I receive the tested game, can use the advertised highscore list and can find genuine privacy and support information. Other players cannot use public names as an unchecked channel for offensive content.

**Why this priority**: A finished product page cannot compensate for a broken release, unavailable advertised services or missing public-name safeguards.

**Independent Test**: Install the exact distribution candidate on a physical iPhone 13 and complete the release journeys, including offline play, actual online highscore publication, a failed submission, support/privacy access and the public-name abuse workflow. Match the evidence to the uploaded candidate.

**Acceptance Scenarios**:

1. **Given** a clean install and an update where an earlier build exists, **When** the player starts, completes and restarts runs, **Then** gameplay, intro, settings and personal best behave as documented in both landscape orientations; offline or slow highscores never prevent play.
2. **Given** the live service and a qualifying run, **When** the player explicitly publishes a chosen name, **Then** the shared result appears as advertised; failure preserves the personal best without queuing a later upload or falsely confirming a save.
3. **Given** a prohibited name or a displayed entry reported as abusive, **When** the relevant safeguard is exercised, **Then** prohibited submissions are prevented, reports reach a responsible operator, offending entries can be removed and abusive participation can be blocked without introducing player accounts.
4. **Given** the shipped data flows and service operations, **When** a player opens support or privacy information, **Then** public usable pages identify a genuine contact and explain publication, retention and removal/reporting consistently with the store disclosures.
5. **Given** a missing physical-device result, an unreachable service or an unresolved material release defect, **When** readiness is assessed, **Then** the candidate is reported as blocked with concrete evidence instead of being called ready because simulator tests passed.

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

### Edge Cases

- Chrome cannot be connected, the session expires, two-factor authentication is required, the wrong organization is selected or the account lacks a required role.
- A matching app already exists, its name is unavailable, its version is locked for review, or earlier distribution prevents narrowing device support to iPhone.
- The iPhone candidate can run in iPad compatibility mode but fails to launch or leaves landscape controls, reporting or privacy information unreachable; this remains a readiness defect even though native iPad support is excluded.
- Apple changes media/declaration requirements; files pass local checks but fail or reorder during remote processing.
- An upload times out but is already processing; a version/build number is already used; the selected build differs from the tested archive.
- The public service is unavailable, cold or misconfigured; a save acknowledgement is lost; screenshots promise features absent from the actual release.
- Public names contain abuse, impersonation or personal information; removal must not overwrite unrelated scores or reintroduce retired submissions.
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
- **FR-012**: The advertised global top-100 service MUST be working in its real production environment before draft readiness. Establishing the minimal service and public pages is in scope; genuine resource ownership, region, cost constraints and addresses MUST be established before provisioning rather than invented.
- **FR-013**: Release acceptance MUST demonstrate online reading/publication, multiple-player persistence, honest unconfirmed-save handling and bounded failures while preserving offline play, local bests and no deferred uploads. An empty production address is not completion of the advertised feature.
- **FR-014**: Public-name safeguards MUST provide prevention of objectionable submissions, an in-app reporting route, operator removal, blocking of abusive participation and public contact information. A responsible operator, a response target of at most one working day and a demonstrated report-to-disposition flow MUST be established. These minimum safeguards extend the earlier highscore scope; player login, chat and a general social platform remain excluded.
- **FR-015**: Abuse-prevention changes MUST preserve anonymous play, ranking and shared-data integrity. Any added retained information MUST have a defined minimum purpose, retention and access boundary and appear in privacy disclosures. Removal MUST preserve unrelated entries and existing submission/failure guarantees.
- **FR-016**: The candidate MUST pass affected automated checks and relevant gameplay/highscore regressions. Physical iPhone 13 evidence MUST cover both-landscape touch, intro and silent-switch audio, in-game mute, haptics, lifecycle, larger text/VoiceOver for applicable controls and sustained play. Unperformed physical checks remain readiness blockers. The selected iPhone candidate MUST also receive an iPad compatibility-mode smoke check covering launch, landscape presentation, reachable touch controls and highscore/report/privacy flows; failures block readiness. A clearly identified simulator check is sufficient for this compatibility gate and MUST NOT be represented as native iPad support or physical-device evidence.
- **FR-017**: App Review information MUST include genuine reachable contact details and instructions to inspect the full game and highscore flow. The no-login experience MUST be explained without fabricated credentials or review-only behavior differing from the release.
- **FR-018**: All applicable required Connect fields, declarations, images and the selected build MUST be saved and verified by a fresh read of the intended app/version. Local files, successful typing or upload-start events alone do not prove saved/processed content.
- **FR-019**: Browser work MUST use the owner's authorized Chrome session without extracting passwords, cookies or session secrets. Missing access or an owner-only account action MUST be reported concretely while independent preparation continues.
- **FR-020**: Once readiness gates pass, preparation MUST assemble and validate the submission draft with the correct version/build and manual release selected. Adding a version for review is allowed only while it remains unsent. The agent MUST NOT invoke Submit for Review, an equivalent sending action, automatic/scheduled publication or final public release.
- **FR-021**: Completion MUST leave a validated, unsent version ready for the owner's review submission, with no remaining copy, media, declaration or build-selection work. The actual version/draft state and direct Connect link MUST be recorded. Apple review, response to later review feedback and final release belong to the owner and are outside this preparation scope.
- **FR-022**: A durable release record MUST identify artifact and candidate identities, version/build, saved Connect values, media verification, checks, declaration evidence, processing/draft status and blockers. It MUST support safe resumption without duplicate records or blind retries and give the owner concise submission and later manual-release instructions.
- **FR-023**: Preparation MUST preserve the constitution and independent cross-vendor review process. Specification, implementation, candidate readiness, upload, review submission, Apple approval and publication MUST be reported separately. Agent consensus does not authorize sending the owner's submission or publishing the app.
- **FR-024**: The app MUST use the owner-supplied [DonkeyTrumpCover.png](../../docs/design/images/DonkeyTrumpCover.png) during startup, preserving its proportions and the full motif across supported landscape layouts. Startup MUST remain local and automatically yield to the game without a minimum display timer or extra action. The original image and supplied prompt MUST be retained as provenance. Store use is optional supporting artwork subject to FR-004–FR-006; it MUST NOT imply that the illustration is actual 3D gameplay or replace the required in-use screenshots.

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
- **SC-004**: The demonstrated public-name workflow prevents a prohibited submission, delivers a report to its operator, removes an offending entry without altering unrelated results and prevents the blocked participant from publishing again within the documented blocking scope.
- **SC-005**: Reopening the store-management page shows the intended saved text, images and exact tested build, with no duplicate app or accidental changes to other versions.
- **SC-006**: The owner can submit the prepared version for review without supplying further copy, images, declarations or builds. There are zero agent-initiated review submissions or public releases; manual release is selected for later owner control.
- **SC-007**: After an interruption, the release record identifies completed work, external processing, remaining blockers and the next action without reconstructing materials or build identity from chat history.
- **SC-008**: Cold-launch checks show the complete supplied illustration without distortion or cut-off title/characters, followed by a reachable title menu and playable game, with no added waiting period or network requirement. The retained source matches the bundled cover, and any store composition distinguishes the illustration from actual gameplay.

## Assumptions

- **Confirmed by the owner on 2026-09-26:** iPhone only; free in all countries where applicable requirements can be met; the owner personally submits to Apple's review. The original request's final-release wording is narrowed by that later explicit answer. Review submission and final public release are not agent actions.
- **Owner follow-up on 2026-09-26:** use the supplied cover as the loading screen and consider it for App Store artwork. This authorizes the focused launch-screen integration before the broader release plan; [cover-art.md](../../docs/design/cover-art.md) retains the image provenance and store-use boundaries.
- English store and in-game copy follow the existing constitution; additional localization is not in scope. The existing game name and original parody identity remain unless a concrete rights or eligibility problem requires an explicit product decision. Games/Arcade is the category direction, subject to current store choices and truthful classification. No child-directed positioning is assumed.
- The original invocation created the specification and quality evidence. Apart from the explicitly authorized cover integration above, producing release assets, modifying the candidate, publishing pages/services and writing Connect data belong to the subsequent implementation of this specification.
- Highscores remain part of the release with anonymous/no-login play and no deferred uploads. Minimum public-name safeguards are expressly included in this release scope. No chat, player accounts, tracking, purchases or additional language is introduced.
- Public support/privacy pages and necessary production service setup are included. Real hosting ownership, cost constraints, contact details, copyright owner, signing access and legal/trader facts must be established before dependent actions. Secrets and private contact evidence must stay outside the repository.
- The owner's signed-in Chrome session is the intended access route. Actual account access, permissions, app existence and saved values are unverified: browser initialization failed before connection in this specification session. No external reading, saving or submission is claimed.
- The project currently enables iPad. Account history and Apple's support constraints must be checked before narrowing distribution. If narrowing an existing release is prohibited, resolve that concrete decision rather than silently adding iPad scope or claiming success.
- Physical hardware, genuine declarations and owner-only account agreements cannot be fabricated or bypassed. Missing inputs are requested early and together after checking available evidence. The ready-to-submit outcome is achieved only after these prerequisites are fulfilled.
- [Constitution v1.0.0](../../.specify/memory/constitution.md) governs the work. [Source notes](source-notes.md) distinguish local facts, current official references and unverified external state. Five screenshots per required set and the moderation response target are project acceptance choices, not claims that Apple specifies those exact numbers.
