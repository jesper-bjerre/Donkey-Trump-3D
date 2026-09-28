# Release acceptance matrix

Created 2026-09-27 at base `94dc44d89929137c4ff02649da58ba8fefa29f1e`.
Status codes: NOT RUN means no candidate acceptance; BLOCKED identifies missing external prerequisite; baseline pass is recorded separately and never promotes a gate. No release candidate is frozen.

Evidence owners: automated = backend/Swift tests and validators; simulator = XCUITest/native capture and iPad compatibility; physical = owner-run test later on the exact processed internal TestFlight build on iPhone 13 (deferred on 2026-09-27; phone disconnected by owner, no pass recorded); live = real Azure/owner moderation; Connect = fresh saved-state reads. Task IDs identify enforcing work, not evidence of completion.

## Requirements

| ID | Acceptance evidence required | Tasks | Current state |
|---|---|---|---|
| FR-001 | Connect + owner facts | T002,T004,T041,T053,T054 | BLOCKED: account/private facts |
| FR-002 | Automated + simulator + physical | T001,T032,T040,T042,T044 | NOT RUN |
| FR-003 | Source + automated + live/Connect | T008,T046,T054 | NOT RUN |
| FR-004 | Source + automated + live/Connect | T045,T048,T049,T054 | NOT RUN |
| FR-005 | Source + automated + live/Connect | T047,T049,T050,T059 | NOT RUN |
| FR-006 | Source + automated + live/Connect | T008,T040,T049,T051,T055 | NOT RUN |
| FR-007 | Source + automated + live/Connect | T004,T029,T031,T054 | NOT RUN |
| FR-008 | Source + automated + live/Connect | T030,T051,T054 | NOT RUN |
| FR-009 | Connect + owner facts | T008,T030,T051,T054 | BLOCKED: account/private facts |
| FR-010 | Connect + owner facts | T051,T053,T054 | NOT RUN |
| FR-011 | Source + automated + live/Connect | T032,T034,T040,T041,T054 | NOT RUN |
| FR-012 | Live Azure + capacity + neighbors | T003,T036–T039,T055,T060 | NOT RUN |
| FR-013 | Automated + simulator + physical | T009–T029,T035,T039,T042 | NOT RUN |
| FR-014 | Source + automated + live/Connect | T009–T029,T031,T043 | NOT RUN |
| FR-015 | Source + automated + live/Connect | T009–T030,T038,T043 | NOT RUN |
| FR-016 | Automated + simulator + physical | T001,T012,T035,T042,T044 | NOT RUN |
| FR-017 | Connect + owner facts | T004,T051,T054 | BLOCKED: account/private facts |
| FR-018 | Connect + owner facts | T052–T054 | BLOCKED: account/private facts |
| FR-019 | Connect + owner facts | T002,T053,T054 | BLOCKED: account/private facts |
| FR-020 | Connect + owner facts | T055,T056,T065 | BLOCKED: account/private facts |
| FR-021 | Connect + owner facts | T056,T057,T065 | BLOCKED: account/private facts |
| FR-022 | Source + automated + live/Connect | T005,T058–T061 | NOT RUN |
| FR-023 | Source + automated + live/Connect | T063–T065 | NOT RUN |
| FR-024 | Automated + simulator + physical | T012,T035,T042,T048 | NOT RUN |
| FR-025 | Automated + simulator + physical | T012,T035,T042 | NOT RUN |
| FR-026 | Automated + simulator + physical | T021,T029,T035,T042 | NOT RUN |

## Success criteria

| ID | Tasks | Evidence/current state |
|---|---|---|
| SC-001 | T031,T051,T054,T056 | Final candidate evidence NOT RUN; applicable prerequisite remains visible in preparation record. |
| SC-002 | T048,T049,T054 | Final candidate evidence NOT RUN; applicable prerequisite remains visible in preparation record. |
| SC-003 | T039,T042,T044 | Final candidate evidence NOT RUN; applicable prerequisite remains visible in preparation record. |
| SC-004 | T025,T042,T043 | Final candidate evidence NOT RUN; applicable prerequisite remains visible in preparation record. |
| SC-005 | T053,T054 | Final candidate evidence NOT RUN; applicable prerequisite remains visible in preparation record. |
| SC-006 | T055–T057,T064,T065 | Final candidate evidence NOT RUN; applicable prerequisite remains visible in preparation record. |
| SC-007 | T058–T061 | Final candidate evidence NOT RUN; applicable prerequisite remains visible in preparation record. |
| SC-008 | T012,T035,T042 | Final candidate evidence NOT RUN; applicable prerequisite remains visible in preparation record. |
| SC-009 | T012,T035,T042 | Final candidate evidence NOT RUN; applicable prerequisite remains visible in preparation record. |
| SC-010 | T021,T029,T035,T042 | Final candidate evidence NOT RUN; applicable prerequisite remains visible in preparation record. |

## Every story scenario

| Scenario | Required observation | Tasks | State |
|---|---|---|---|
| US1-1 | its title, subtitle, description, keywords, categories and supporting copy accurately describe the 3D game and distinguish offline gameplay from online highscores. | T046,T049 | NOT RUN |
| US1-2 | five ordered landscape screenshots show representative gameplay and features, without invented scenes, debug controls, real players' personal information or claims absent from the candidate. | T047–T049 | NOT RUN |
| US1-3 | the icon and required screenshot sets meet Apple's current accepted format, size and content requirements; larger-display requirements are not assumed satisfied by iPhone 13 captures alone. | T045,T049,T054 | NOT RUN |
| US1-4 | the page preserves the no-affiliation statement, avoids copied third-party assets and makes no unsupported endorsement or licensing claim. | T008,T046,T049 | NOT RUN |
| US1-5 | the owner's Donkey Trump cover appears proportionally with its full title and characters visible, shows an approximate progress bar and yields to the usable game as soon as required local loading finishes, without an artificial delay or network dependency. Possible store use is supporting key art around actual game captures, never a substitute for the in-use screenshot set. | T012,T035,T042 | NOT RUN |
| US1-6 | it loops across runtime loading and the title menu, stops when the intro starts and returns on title entry; music preparation never delays play. | T012,T035,T042 | NOT RUN |
| US2-1 | gameplay, intro, settings and personal best behave as documented in both landscape orientations; offline or slow highscores never prevent play. | T035,T042,T044 | NOT RUN |
| US2-2 | the shared result appears as advertised; failure preserves the personal best without queuing a later upload or falsely confirming a save. | T025,T039,T042 | NOT RUN |
| US2-3 | prohibited submissions are prevented, reports reach the app owner for a response within one working day, offending entries can be removed and the offending app installation can be blocked from publishing further scores without introducing player accounts; local gameplay remains available. | T025,T042,T043 | NOT RUN |
| US2-4 | public usable pages identify a genuine contact and explain publication, retention and removal/reporting consistently with the store disclosures. | T030,T031,T054 | NOT RUN |
| US2-5 | the candidate is reported as blocked with concrete evidence instead of being called ready because simulator tests passed. | T063,T065 | NOT RUN |
| US2-6 | low-scoring cartoon starter entries keep at least ten ranked entries in the list while the list still supports the best 100; a qualifying player receives a clear name-entry dialog with an obvious input and submit button, without the removed public-name/real-name advisory text. | T021,T029,T035,T042 | NOT RUN |
| US3-1 | an existing matching record is reused; a new record is created only after confirming none exists. Other apps and versions remain unchanged. | T002,T053 | NOT RUN |
| US3-2 | Connect shows the intended saved text, image order, processed build, support/privacy links, categories, free price and eligible territories after a fresh read. | T053,T054 | NOT RUN |
| US3-3 | every answer has an evidence basis; no-login is not treated as proof that no data is collected. | T030,T051,T054 | NOT RUN |
| US3-4 | it is requested in a consolidated owner-input request. No identity, contact detail, rights claim, trader status or legal acceptance is invented. | T004,T051 | NOT RUN |
| US4-1 | the version can be added for review without sending it; the workflow stops before Submit for Review or any equivalent sending action. | T055,T056 | NOT RUN |
| US4-2 | the owner receives its direct Connect link, version/build and concise remaining actions: submit for review, handle subsequent Apple feedback, and manually release after approval. No copy, screenshots or build selection remain for the owner to prepare. | T056,T057,T065 | NOT RUN |
| US4-3 | manual release is selected and automatic release, scheduled publication and pre-order are disabled. | T055,T056 | NOT RUN |
| US4-4 | the agent stops before that action, records the precise state and does not label an unvalidated version ready. | T055,T065 | NOT RUN |
| US5-1 | saved values and processing state are checked first; ambiguous results do not create duplicate apps, builds or drafts. | T058 | NOT RUN |
| US5-2 | affected media, disclosures and checks are reassessed and remain tied to the selected build. | T059 | NOT RUN |
| US5-3 | local preparation, saved Connect data, upload, draft readiness, Apple submission and publication remain distinct, with a concrete next action for outstanding preparation. | T005,T061,T065 | NOT RUN |
| US5-4 | the actual plan and hosted apps are recorded, reuse fits the verified capacity, and existing apps pass documented before/after availability checks. Any required shared-plan change remains a separate owner decision. The owner monitors Azure costs. | T003,T039,T060 | NOT RUN |

## Invalidation and evidence rules

For every pass record command/observation, UTC, exact candidate/source/configuration/build, actual device/environment and evidence checksum/reference. Remote-saved, processed, physical and draft states require their own observations. Private evidence stays outside Git. Recipes and past review records are not current passes.

Source/configuration/build changes invalidate affected automated, archive/upload, physical and media results. Media changes invalidate visual/manifest/remote order checks; data/rights/contact changes invalidate declarations and public pages. A changed shared plan/capacity baseline invalidates T039/T055/T060. After an interruption read remote state before repeating any mutation. Independent agent consensus is T064; no owner adjudication of review findings.
