# Feature Specification: Global Top 100 Highscores

**Feature Branch**: `main` (existing branch; no feature branch created)

**Feature Directory**: `specs/001-global-highscores`

**Created**: 2026-09-26

**Status**: Implemented and locally validated; see [validation.md](validation.md). Physical-device, container and live Azure release checks remain pending. No deployment or release claim.

**Input**: The iPhone game needs a shared top-100 highscore list. After Game Over, qualifying players enter a name and see their score centred in the list. Non-qualifying players see the bottom. The list is also available from the title screen and must never delay starting a game. Scores must survive service restarts and simultaneous submissions. Keep the solution simple and inexpensive.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Publish a qualifying result (Priority: P1)

After losing my last life, I want to enter a name for a qualifying score and see my position among other players, so my achievement feels recognised.

**Why this priority**: A persistent shared ranking is the main value of the feature.

**Independent Test**: Complete a run against a prepared list with a known cutoff. Submit a qualifying result, verify its highlighted position, and reopen the list from another installation to confirm it was saved.

**Acceptance Scenarios**:

1. **Given** fewer than 100 saved results, **When** a run ends with a valid score, **Then** the player is invited to enter a name, including when the score is zero.
2. **Given** a full list, **When** a completed run scores more than rank 100, **Then** the player sees a clear name-entry dialog with Submit and Cancel.
3. **Given** a qualifying run and a valid name, **When** submission succeeds, **Then** the player sees the saved list with their entry highlighted and vertically centred. Near either end, use the nearest available position keeping the whole row visible.
4. **Given** a name prompt, **When** the player cancels, **Then** nothing is submitted and Play Again and Return to Title remain available.
5. **Given** an empty, whitespace-only, multiline, control-character or over-20-character name, **When** submission is attempted, **Then** an inline explanation appears and nothing is published until the name is valid.
6. **Given** the list changes while a name is entered, **When** the score no longer qualifies at save time, **Then** no success is claimed and the updated bottom of the list is shown with an explanation.
7. **Given** a submitted entry remains ranked, **When** the identical submission is repeated, **Then** it has one entry and retains its original tie position; changing its name or score under the same run identity is rejected.

### User Story 2 - See the next target after missing the list (Priority: P1)

After a run that does not reach the top 100, I want to see the lowest listed scores and my own result, so I know what to aim for next.

**Why this priority**: This completes the end-of-run experience for most players and encourages another attempt.

**Independent Test**: Complete runs below and exactly at the cutoff in a prepared full list; confirm there is no name prompt and rank 100 is visible.

**Acceptance Scenarios**:

1. **Given** 100 results and a score below rank 100, **When** qualification is checked after Game Over, **Then** the bottom opens with rank 100 visible, the final score remains visible, and no name is requested.
2. **Given** a full list and a score equal to the cutoff, **When** qualification is checked, **Then** the previously saved equal score keeps its place and the new run does not qualify.
3. **Given** the result list, **When** Play Again or Return to Title is selected, **Then** that action proceeds without waiting for another highscore operation.

### User Story 3 - Browse from the title without delaying play (Priority: P1)

I want to open Highscores from the title screen while always being able to start playing, even when the shared service is slow or unavailable.

**Why this priority**: The online feature must preserve the game's immediate, offline-capable start.

**Independent Test**: Launch with a service that responds normally, responds late, and never responds. Start a game during each condition and inspect list loading/error states independently.

**Acceptance Scenarios**:

1. **Given** the title screen, **When** Highscores is selected, **Then** the list opens from the top with rank, name and score and clear loading, empty and unavailable states.
2. **Given** a background list load is pending or failed, **When** Start Game is selected, **Then** the normal intro/game flow begins immediately, with no network gate or disabled Start button.
3. **Given** a list view is loading, **When** the player closes it and starts a run, **Then** a late response cannot reopen the list, show a name prompt or interrupt the run.
4. **Given** an unavailable service, **When** Highscores is opened, **Then** loading ends within eight seconds with a readable error and a list-refresh action; the list can always be closed.
5. **Given** a list loaded earlier in this app session, **When** refresh fails, **Then** those entries may remain visible only with a clear indication that they may be out of date. They cannot establish current qualification.
6. **Given** larger text or VoiceOver on an iPhone in landscape, **When** the list is opened, **Then** rank, name and score can be read, navigation remains reachable, and the highlighted row is not hidden by the keyboard or screen edges.

### User Story 4 - Preserve the ranking during simultaneous submissions (Priority: P1)

As a player, I want simultaneous results evaluated together so another player's submission cannot accidentally erase mine.

**Why this priority**: A shared highscore list needs consistent ranking across devices.

**Independent Test**: Submit many distinct prepared results concurrently, then compare the saved ranking with the expected best 100, including stable ties and repeated submissions.

**Acceptance Scenarios**:

1. **Given** a populated list, **When** two different qualifying results are saved simultaneously, **Then** both are considered against the latest saved scores, with only scores below the resulting cutoff removed.
2. **Given** simultaneous equal scores, **When** saved, **Then** the first successfully saved result ranks ahead of later equal results, consistently on every device.
3. **Given** a successful save, **When** the service restarts, **Then** the result remains unless legitimately displaced by higher-ranked results.
4. **Given** excessive contention or unavailable storage, **When** a result cannot be confirmed within the deadline, **Then** an error replaces any success claim and the player can immediately play again.
5. **Given** malformed scores or excessive submission traffic, **When** requests arrive, **Then** invalid results do not change the ranking and excessive submissions receive a clear temporary rejection.

### User Story 5 - Keep playing when publication fails (Priority: P1)

If the service cannot be reached after Game Over, I want an error and my local personal best retained, without a pending score being submitted later.

**Why this priority**: The user explicitly chose no deferred score submission and no account requirement.

**Independent Test**: Finish offline, restore connectivity, then restart the app. Verify the personal best remains and the failed run is never submitted later.

**Acceptance Scenarios**:

1. **Given** Game Over without connectivity, **When** qualification cannot be checked, **Then** no name is requested, the local best is preserved, and an error replaces any claim that the score did or did not qualify.
2. **Given** a valid name and a failed submission, **When** the error appears, **Then** the local best remains and no automatic or deferred publication is queued.
3. **Given** a failed run submission, **When** connectivity returns, a list is refreshed, or the app relaunches, **Then** that run is not submitted again.
4. **Given** a save may have completed but its response was lost, **When** an error appears, **Then** it says publication could not be confirmed, rather than asserting the score was not saved.

### Edge Cases

- Owner update 2026-09-27: valid lists always contain at least ten entries. The backend supplies deterministic cartoon starters with 100–1,000 points for a new or undersized list. Preserve existing players; starters use ordinary ranking and can eventually all be displaced. Storage/network errors remain errors, never fabricated successful lists.
- Game Over means loss of the last life. A rescue, single lost life, pause-menu restart, abandoned run or return to title does not publish a result.
- Use the run's final score, never the previously saved personal best or the next run's score.
- Equal scores have consecutive ranks ordered by successful save order. A full list never replaces an earlier equal cutoff score.
- Names need not be unique, and one person may hold multiple places; a name does not identify a run or person.
- A result can be displaced after successful submission. The initial view shows the saved snapshot; a later refresh explains displacement and shows the bottom instead of highlighting another same-name entry.
- Negative, excessively large or malformed scores are rejected. Valid-looking scores do not prove genuine gameplay.
- Cancelling a view during submission stops further UI transitions but cannot undo an already completed save.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Maintain one shared, all-time list of the best 100 completed-run scores, with at least ten entries supplied by low-scoring cartoon starters until enough results exist. Keep the maximum of 100; start scores are 100–1,000 and are displaced by the same ranking rules.
- **FR-002**: Rank by descending score, then first successful save for ties; show consecutive ranks starting at 1.
- **FR-003**: Persist the list independently of any individual device and service process lifetime.
- **FR-004**: Evaluate only the final score of a run reaching Game Over through loss of all lives, independently of the local personal best.
- **FR-005**: Check current qualification after Game Over without blocking Play Again or Return to Title. Fewer than 100 entries accepts any valid non-negative score; a full list requires beating its current cutoff.
- **FR-006**: Request a name only after a successful qualification check; allow cancellation without publication.
- **FR-007**: Accept a single-line name of 1–20 visible characters after trimming surrounding spaces; reject control characters and explain validation failures. Display names as plain text.
- **FR-008**: Require an explicit Submit action in a clearly bounded name-entry dialog, with a visible name field and Cancel. Owner update 2026-09-27: omit the in-form public-name/real-name explanation. No account, email or real name is required; existing privacy/help data-flow information remains accurate.
- **FR-009**: Re-evaluate qualification when saving. Concurrent submissions must not cause lost updates, duplicate run entries or more than 100 ranked entries.
- **FR-010**: Following a confirmed save, highlight that exact run and centre it vertically where content permits. Keep the whole highlighted row visible at list boundaries.
- **FR-011**: Following confirmed non-qualification, show the bottom with the lowest rank visible, retain the player's final score, and offer another game. Do not request a name.
- **FR-012**: Provide a title-screen Highscores action that opens the beginning of the list and can be closed at any time.
- **FR-013**: Load and refresh independently of gameplay startup. Starting, restarting and playing must remain possible without a working network connection.
- **FR-014**: Provide loading, empty, available and error states; end visible loading/submission waits within eight seconds. Reading the list can be retried explicitly.
- **FR-015**: Suppress obsolete results from earlier screens or runs so a late operation cannot navigate away from an active game or attach a score to the wrong run.
- **FR-016**: Reject invalid result data and limit excessive submissions. Identical repeated submissions for a currently ranked run retain one entry; changed data for that run is rejected.
- **FR-017**: On a failed qualification check or submission, show an error, preserve the local best, and perform no automatic, later or next-launch submission of that run. Describe a failed save with an unknown outcome as unconfirmed.
- **FR-018**: Distinguish previously loaded content from confirmed current results. Stale content must not cause a name prompt, non-qualification claim or publication-success claim.
- **FR-019**: Keep list content and navigation usable in landscape on the supported iPhone baseline, including VoiceOver and larger text. Use the existing English UI language.
- **FR-020**: Update privacy/help copy to describe the optional public list separately from the local best; after implementation it must no longer claim all game data stays exclusively on-device.

### Key Entities *(include if feature involves data)*

- **Completed run**: A finished game's unique identity, immutable final score and level reached. It belongs to the current result flow, not a deferred-submission record.
- **Highscore entry**: A qualifying run's identity, public name, score and successful-save order. Rank is derived from its place in the list.
- **Highscore list snapshot**: Up to 100 ordered entries and information distinguishing the observed version and freshness. Successful submission returns the snapshot in which the result was evaluated.
- **Local personal best**: The existing device-local maximum score, independent of participation in the shared list and preserved during failures.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Across 100 startup/restart attempts covering normal, delayed and unavailable services, every attempt can start without waiting for highscores; added start latency stays below 100 ms against the same-device baseline.
- **SC-002**: For controlled acceptance runs at ranks 1, 50 and 100, the exact submitted entry is highlighted and fully visible, centred for interior ranks. Every non-qualifying run shows the lowest rank without a name prompt.
- **SC-003**: After 100 concurrent valid submissions, the saved ranking exactly matches the best 100 successfully considered results, including earlier entries, with no duplicates or lost higher scores. Transient failures are reported, and equal scores preserve successful-save order.
- **SC-004**: In normal conditions, 95% of list loads and confirmed submissions become visible within two seconds over 100 attempts with a warm service and at most 100 ms network round-trip latency. All stalled attempts leave loading within eight seconds.
- **SC-005**: Across connection interruptions before qualification, before save and after save but before acknowledgement, every run preserves its local best and none is queued or resubmitted after reconnection or relaunch.
- **SC-006**: A successfully saved ranking remains identical after a service restart when no new results arrive; two installations observe the same ranking version.

## Assumptions

- The user confirmed on 2026-09-26: **no login**, with scores reported by the app. Validation and submission limits reduce malformed traffic but do not verify gameplay or prevent determined cheating.
- The user confirmed on 2026-09-26: connection failure means an error and the local personal best only. There is **no offline queue or later submission**.
- The list ranks runs, not unique people. It is global and all-time, without seasons, country filters, prizes or cross-device personal profiles.
- First successfully saved wins equal-score ties. Names are non-unique and not editable after submission in this version.
- Existing scoring, three-life rules, looping levels, audio, intro and local best behaviour remain the game's basis.
- Network access is required only for fresh highscores, qualification and publication. Gameplay remains independent of the shared service.
- Moderation tools, verified replays, score archives and regional rankings require separate scope decisions.
- Hosting access and a deployed service address are dependencies for end-to-end release validation. User-specified backend constraints and storage recommendations appear separately in [technical-proposal.md](technical-proposal.md).
- [Constitution v1.0.0](../../.specify/memory/constitution.md), ratified 2026-09-26, governs this feature; the plan's current review and implementation tasks apply its principles. The implemented highscore feature supersedes the earlier product document's exclusion of public leaderboards and preserves the existing gameplay rules.
