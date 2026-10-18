# Feature Specification: Score, Attempt Timer and Level Pressure

**Feature Branch**: `main` (existing branch; no branch-creation hook configured)

**Created**: 2026-10-18

**Status**: Draft — specification ready for planning

**Review policy**: Owner-directed [exemption from Claude Code review](review-policy.md), including implementation, effective 2026-10-18. Product requirements and acceptance criteria are unchanged.

**Input**: User description: `docs/intents/Donkey_Trump_3D_Codex_Point_Timer_Svaerhedsgrad.md`; approved intent dated 2026-10-17 ([source](../../docs/intents/Donkey_Trump_3D_Codex_Point_Timer_Svaerhedsgrad.md)).

Players should earn more by rescuing Motzfeldt and progressing quickly than by staying on an easy level and repeatedly clearing slow barrels. This feature combines level-scaled rewards, a limit on rewarded barrels, a three-minute attempt timer and pressure that increases with active time on the same level.

This invocation specifies the feature. Implementation, builds, executed gameplay checks and publication are outside this specification phase. Acceptance scenarios below describe future verification, not checks already performed.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Earn bounded rewards and progress bonuses (Priority: P1)

As a player, I earn a small reward for clearing a barrel and a larger reward for completing a level quickly. Repeating an easy obstacle or losing a life cannot replenish the available rewards.

**Why this priority**: This removes the incentive to farm points instead of progressing and defines the score all other views present.

**Independent Test**: Evaluate reward events and completion using known active durations and barrel histories. This journey independently demonstrates bounded barrel rewards and worthwhile progression.

**Acceptance Scenarios**:

1. **Given** a new run on visible level 1, **When** the player clears 10 different barrels and completes it at exactly 60 active seconds, **Then** it contributes 100 barrel points, 1,000 completion points and 600 time-bonus points, for 1,700 total.
2. **Given** that run continues to visible level 2, **When** the player clears 5 different barrels and completes it at exactly 120 active seconds on that level, **Then** it contributes 100 barrel points, 2,000 completion points and 600 time-bonus points, adding 2,700 for a run total of 4,400.
3. **Given** level 1, **When** the player clears 20 different barrels, repeats a rewarded barrel and clears a twenty-first barrel, **Then** barrel rewards total 200 points and neither repeated nor excess clearances add points or positive point feedback.
4. **Given** 12 rewarded barrels on the current level, **When** the player loses a life and retries, **Then** the score is retained and only 8 additional different barrels can earn points on that level.
5. **Given** a previously rewarded barrel, **When** it is crossed again or its clearance is reported repeatedly, **Then** no further points are awarded; **Given** it leaves play and a newly released barrel replaces it, **When** that new barrel is successfully cleared below the cap, **Then** it earns points even if it reuses the previous barrel's resources.
6. **Given** a jump without clearing a barrel, **When** it finishes, **Then** no barrel points or positive point feedback are given. A jump clearing multiple eligible barrels earns only their individual rewards within the remaining cap, with no extra combo reward.
7. **Given** completion at total active level time T = 60.2 seconds, **When** the time bonus is awarded, **Then** only 119 bonus seconds count; **Given** T is at least 180 seconds across one or more lives, **Then** the time bonus is zero even after a retry.
8. **Given** a valid completed level, **When** completion is reported repeatedly, **Then** its completion and time bonuses are added exactly once and no legacy reward is added for the same events.

---

### User Story 2 - Play a fair three-minute attempt (Priority: P1)

As a player, I see how long my current attempt has left. Timeout costs one life, while pauses and interruptions do not consume play time. A new life gives another three-minute attempt without resetting my level history.

**Why this priority**: A bounded attempt prevents indefinite waiting, while correct timing and life-loss handling make the rule predictable.

**Independent Test**: Advance one attempt through active play, interruption and expiry with known event times. This independently demonstrates the time budget and existing retry/Game Over flow.

**Acceptance Scenarios**:

1. **Given** a new level or a retry after any life loss, **When** active play begins, **Then** exactly 180 attempt seconds remain and the HUD starts at `3:00`.
2. **Given** a live attempt, **When** exactly 180 active seconds elapse without completion, **Then** exactly one life is lost, no completion or time bonus is awarded and the existing retry flow starts a fresh `3:00` attempt if a life remains.
3. **Given** the last life, **When** the attempt expires, **Then** the existing Game Over flow shows the retained final score and no new active attempt begins.
4. **Given** 60 active level seconds before a life loss, **When** the player retries and plays 60 more active seconds, **Then** T = 120 and the current attempt has 120 seconds left; time bonuses and pressure use the 120-second level history.
5. **Given** pause, inactivity/background, introduction, death animation, respawn, level transition or Game Over, **When** time passes, **Then** neither gameplay clock advances and no new gameplay rewards accrue. Resuming excludes the entire inactive interval.
6. **Given** simultaneous timeout and collision, **When** the attempt resolves, **Then** at most one life is lost; **Given** competing timeout and goal arrival, **Then** exactly one terminal outcome is applied, independent of notification order.
7. **Given** the goal reached before expiry, **When** completion registers, **Then** clocks stop and bonuses use that completion time; **Given** the goal reached at or after expiry, **Then** timeout wins without completion rewards.
8. **Given** a finished attempt, **When** delayed reward, collision or timeout notifications arrive during its transition, **Then** they cannot add points, remove another life or restart a completed level.

---

### User Story 3 - Face increasing but playable pressure (Priority: P2)

As a player, I face more frequent and faster barrels the longer I stay on a level, including after losing lives. A new level resets time-based pressure to that level's own starting difficulty.

**Why this priority**: Pressure discourages waiting on the upper part while retaining physically possible jumps and landings.

**Independent Test**: Observe one level at known active-time checkpoints, after a retry and after progression. This independently demonstrates pressure without requiring highscore publication.

**Acceptance Scenarios**:

1. **Given** unchanged base throw interval and barrel speed, **When** T is 0, 60, 120 and 180 seconds, **Then** the desired interval is respectively 100%, 80%, 60% and 40% of its base and speed is 100%, approximately 108.33%, approximately 116.67% and 125% of its base.
2. **Given** T is at least 180 seconds, **When** a life is lost and a fresh attempt starts, **Then** pressure stays at maximum. Repeated updates at the same T do not further increase speed or shorten the interval.
3. **Given** pause or background, **When** play resumes, **Then** pressure is unchanged and no accumulated burst of delayed throws occurs.
4. **Given** level completion, **When** the next level starts, **Then** T and rewarded-barrel history reset, the attempt starts at `3:00`, that level's own base difficulty applies and all previously earned score is retained.
5. **Given** the player stays near the upper part for a full attempt, **When** pressure increases, **Then** barrel rewards remain capped and representative incoming sequences still permit physically possible jumps and landings at maximum pressure. Any needed minimum interval is documented with concrete movement/spacing evidence.
6. **Given** different player positions at the same T, **When** time-based pressure is evaluated, **Then** its multiplier is identical. New and active barrels follow the same scaling wherever their movement permits it.

---

### User Story 4 - Understand and retain the exact final result (Priority: P2)

As a player, I see a consistent score during play, after rescue, at Game Over and when I explicitly submit a highscore. Existing records remain available, and instructions explain the new rewards and timer.

**Why this priority**: The player must understand and preserve the exact earned result through the existing highscore flow.

**Independent Test**: Follow known totals through results and an optional submission, including a total not divisible by 100. This independently demonstrates consistent presentation and publication compatibility.

**Acceptance Scenarios**:

1. **Given** an earned total, **When** the player views HUD, level result and Game Over, **Then** each shows the accumulated score at that point; the existing level-result view separately identifies the actual completion and time bonuses.
2. **Given** a completed run whose valid score is 10 or 1,005, **When** it qualifies and the player explicitly submits it, **Then** the exact score can be accepted, returned and displayed without rounding or rejection merely because it is not divisible by 100.
3. **Given** older saved scores/personal bests, **When** new rules are introduced, **Then** no existing records are automatically deleted or recalculated and remote failure cannot erase the local best.
4. **Given** updated help and life-loss displays, **When** a player reads them, **Then** they accurately describe level-scaled capped barrel rewards, completion/time bonuses and a three-minute attempt; timeout is not described as being hit by a barrel.
5. **Given** failed or unconfirmed highscore publication, **When** the player starts or restarts, **Then** play remains available without waiting for the service and no deferred submission is created.

### Edge Cases

- The first visible level uses L = 1 even if internal numbering starts at zero. Repeated layouts use the current visible level number and their own base difficulty.
- Clearing multiple barrels in one jump cannot exceed the remaining cap. With one rewarded barrel left, the jump earns at most one barrel reward and no additional combo bonus.
- A replacement barrel is distinct, including after life loss; a still-existing barrel never becomes eligible a second time on the same level.
- Fractional seconds remain meaningful: bonus seconds round down; display rounding cannot change expiry, rewards or pressure.
- At R = 0, timeout wins exactly simultaneous goal arrival. An earlier valid completion remains final even if presented later.
- Inactive time cannot reappear as a large active interval, change pressure or trigger catch-up throws on resume.
- If an attempt ends during an update, only time up to its terminal event contributes to T and R; the remainder is not active time.
- If same-run restoration already exists, it preserves clocks, score, barrel count/history and terminal status; it cannot replenish rewards. No new saved-run facility is required.
- Old score-granularity assumptions cannot invalidate mixed highscore lists containing old and newly attainable totals.

## Requirements *(mandatory)*

### Functional Requirements

**Scoring and level identity**

- **FR-001**: All rewards MUST use the visible one-based level number L, including when layouts repeat at higher levels.
- **FR-002**: Successful level completion MUST add `1,000 × L` points exactly once.
- **FR-003**: Each of the first 20 different successfully cleared barrels on a level MUST add `10 × L` points once per barrel lifetime. The cap and reward history MUST span all lives on that level. Ordinary jumps, repeated clearances and barrels beyond the cap MUST earn zero barrel points.
- **FR-004**: A newly released replacement barrel MUST be a distinct reward opportunity below the cap, regardless of reuse of resources or identifiers. Multiple eligible barrels in one jump MUST earn only the sum of their individual rewards within the cap, without an extra combo bonus.
- **FR-005**: Successful completion MUST additionally award `5 × L × floor(max(0, 180 − T))` exactly once, where T is total active time on the current level across lives. Life loss MUST NOT restore bonus seconds.
- **FR-006**: FR-002–FR-005 MUST replace old rewards for the same events. All other reward sources MUST be inventoried in implementation evidence; none may bypass the barrel cap or reward passive waiting. Life loss MUST preserve earned points and MUST NOT introduce a new point penalty.

**Attempt and active-time rules**

- **FR-007**: Total active level time T MUST be distinct from remaining attempt time R. A new level starts with T = 0 and R = 180 seconds. Retries start with R = 180 while retaining T and rewarded-barrel count/history.
- **FR-008**: Both clocks MUST advance only during active gameplay. Pause, inactivity/background, introduction, death animation, respawn, level transition and Game Over MUST consume neither clock. Resumption MUST exclude inactive intervals.
- **FR-009**: Time and rewards MUST depend on elapsed active duration rather than update count, retaining fractional precision until display or whole-bonus-second calculation. Equivalent active durations at different update frequencies MUST produce equivalent outcomes, with at most 0.02 seconds timing difference and identical points away from a rounding boundary.
- **FR-010**: R = 0 MUST end the attempt and remove exactly one life. Remaining lives MUST lead through the existing retry flow; no lives MUST lead to existing Game Over. Timeout MUST award neither completion nor time bonus. Clocks MUST stop as soon as the attempt ends.
- **FR-011**: Each attempt MUST have at most one terminal outcome. Timeout plus collision MUST cost at most one life. Goal arrival at or after expiry MUST resolve as timeout; a valid completion strictly before expiry MUST stop timing and use its completion-time T. Notification order MUST NOT change the result. Finished attempts MUST reject further gameplay rewards and life losses.
- **FR-012**: Starting or explicitly restarting a whole game MUST reset score to zero, T to zero, R to 180 and reward history. Advancing a level MUST retain score including bonuses while resetting T, R and that history. Pause MUST preserve all of them. Game Over MUST freeze the final result.

**Level pressure and playability**

- **FR-013**: Pressure MUST use `p = clamp(T / 180, 0, 1)`. Desired throw interval MUST be `base interval × (1 − 0.60 × p)` and desired barrel speed MUST be `base speed × (1 + 0.25 × p)`, relative to unchanged base values for this level rather than previously scaled values.
- **FR-014**: Pressure MUST increase continuously over the first 180 active level seconds, remain capped afterward, persist through life loss and reset on a new level. The time-based multiplier MUST be independent of player position. New and active barrels MUST use the same scaling wherever their movement type permits it; movement-specific limitations MUST be explained in implementation evidence.
- **FR-015**: Resuming after pause/background MUST NOT cause a burst of delayed throws. Increasing throw frequency and speed MUST preserve physically possible jumps and landings. If needed, a minimum throw interval MUST limit the desired interval while retaining its decrease above that floor. The chosen floor, affected levels and resulting intervals MUST be justified by existing jump/landing timing and barrel-spacing evidence; the approved multipliers remain the starting values.

**Presentation, continuity and highscore compatibility**

- **FR-016**: The HUD MUST clearly show accumulated score and R as `M:SS`, beginning at `3:00`. Positive remaining fractions MUST display the next whole second so `0:00` denotes expiry, without affecting actual timing.
- **FR-017**: Brief positive point feedback MUST show the actual awarded value only when points are earned. The existing level-result presentation MUST show actual completion and time bonuses, including zero time bonus, and cumulative score without adding rewards again.
- **FR-018**: HUD, level results, Game Over, local personal best and highscore submission MUST derive from one authoritative run score. Highscores MUST preserve newly attainable totals within the existing supported score range, including scores not divisible by 100, without changing their value. New and historical records MUST remain readable and valid.
- **FR-019**: Existing highscores/personal bests MUST NOT be automatically deleted or recalculated. Planning MUST inspect leaderboard-version support and state a concrete recommendation about old/new score comparability before implementation. This does not authorize a new service, deletion, migration of old scores or a separate leaderboard.
- **FR-020**: Relevant scoring/time instructions and result text MUST be updated in English. Timeout feedback MUST identify time expiry accurately. Changed HUD/result screens MUST remain readable and usable in landscape on the reference iPhone, respect safe areas and preserve applicable accessibility support, sound, haptics and Reduce Motion settings.
- **FR-021**: If same-run saving/restoration already exists, new state MUST follow that lifetime and preserve reward limits and time history. This feature MUST NOT require a new saved-game system.
- **FR-022**: Starting, restarting and playing MUST remain available offline. Optional publication MUST retain explicit consent, bounded asynchronous failures, local-best preservation, accurate unconfirmed-save messaging and no automatic/deferred upload. No accounts, tracking or additional data collection may be introduced.

### State Transition Rules

| Event | Attempt time R | Total active level time T | Rewarded barrels and history | Run score |
| --- | --- | --- | --- | --- |
| New game or Restart from Level 1 | 180 at play start | 0 | Reset | 0 |
| New level | 180 at play start | 0 | Reset | Retained with previous bonuses |
| Life loss with lives remaining | Stopped, then 180 at retry start | Retained | Retained | Retained |
| Pause or background | Frozen | Frozen | Retained | Retained |
| Successful completion | Stopped at completion | Stopped at completion | No further rewards on completed level | Add completion/time bonuses once |
| Game Over | Stopped | Stopped | No further rewards | Final retained total |

### Key Entities *(include if feature involves data)*

- **Run**: One game from start/restart to Game Over; accumulated score, lives and visible level provide the final personal-best and optional highscore result.
- **Level progress**: Visible level L, unchanged starting difficulty, total active time T, rewarded-barrel count and history; persists through retries on that level.
- **Attempt**: One life's active play, remaining time R and terminal outcome so collision, expiry and completion cannot apply competing outcomes.
- **Barrel lifetime**: One released barrel until removal, distinct from replacements using the same resources; includes whether it already earned points.
- **Level reward**: Individually identifiable barrel, completion and time rewards contributing to the single run score.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The reference journeys contribute exactly 1,700 and 2,700 points and yield 4,400 combined, without duplicated legacy, combo or completion rewards.
- **SC-002**: A level awards no more than `200 × L` barrel points across all lives; a replacement barrel below the 20-barrel cap can still earn points.
- **SC-003**: Every uncompleted attempt expires after 180 active seconds, within 0.02 seconds across 30, 60 and 120 updates per second, loses exactly one life and restarts at `3:00` or ends the run. A 60-second pause/background interval changes both clocks by zero and creates no catch-up throws.
- **SC-004**: After 60 active seconds, life loss and 60 more active seconds, T = 120 governs pressure and bonus calculation. At T ≥ 180 the time bonus stays zero and pressure stays capped regardless of retries.
- **SC-005**: At T = 0, 60, 120 and 180, desired intervals/speeds match Story 3's percentages within 0.01 percentage point. Actual intervals follow these values or a documented playability floor; repeated evaluations at unchanged T produce no drift.
- **SC-006**: Repeatable upper-area full-attempt and maximum-pressure checks cover each authored layout and the highest existing base difficulty: rewards remain capped, pressure increases and representative sequences allow a jump and safe landing before the next necessary jump. Device-dependent acceptance uses the reference iPhone, distinguished from simulator evidence.
- **SC-007**: All specified collision/expiry/completion boundaries produce exactly one terminal outcome, no duplicate life loss, no points after attempt end and no outcome difference caused solely by notification order.
- **SC-008**: At each result boundary, displays and submitted/returned highscores match the authoritative total exactly, including 10 and 1,005. Existing records remain unchanged; publication failures never prevent starting another game.
- **SC-009**: Timer and score remain readable without overlapping controls/safe areas on the landscape reference iPhone. Help and results explain the cap, level-scaled rewards, time bonus and three-minute attempt without conflicting old rules.

## Assumptions

- This approved intent supersedes older proposals for these rules. The full feature includes all four stories; their priorities order delivery and do not redefine an initial slice as complete acceptance.
- Existing movement, layouts, life count and retry/Game Over flows are retained. The reference platform, English documentation/copy and governance follow [constitution v1.0.0](../../.specify/memory/constitution.md).
- Exactly simultaneous goal arrival and expiry is timeout. For an otherwise valid life-ending collision and goal arrival at the exact same active timestamp before expiry, life loss takes precedence; a strictly earlier valid completion remains final. This default removes notification-order dependence.
- Timer display rounds positive remaining fractions upward; bonus seconds round downward. The 0.02-second comparison tolerance is timekeeping accuracy, not permission to award the wrong bonus at an exact boundary.
- Current runs are in memory according to the existing [architecture baseline](../../docs/architecture_options.md); no durable same-run restore is assumed. Planning must confirm this for FR-021. Ordinary pause/resume is always in scope.
- Planning must inspect reward sources, jump/landing timing, barrel movement types, existing base-difficulty limits and any playability floor before finalizing design. These are evidence-gathering dependencies, not undecided player rules.
- Current highscore validation assumes multiples of 100, while these rules produce multiples of 5. Coordinated compatibility of score acceptance and mixed old/new records is required by FR-018. The existing [highscore flow](../001-global-highscores/contracts/ios-flow.md) and [score contract](../001-global-highscores/contracts/highscores.openapi.yaml) govern unchanged consent/failure behaviour; the old score-granularity rule must be reconciled during planning and implementation.
- Leaderboard versioning/comparability is an assessment and concrete recommendation deliverable. Existing records/ranking arrangements remain unless separately authorized; a new season or service is not implied.
- Implementation evidence must inventory other reward sources, justify any minimum interval, describe leaderboard compatibility/comparability and distinguish executed, planned and unavailable checks. Tests run only when explicitly requested in the then-current user prompt under [AGENTS.md](../../AGENTS.md); this specification does not authorize execution.
- App Store/TestFlight submission, production deployment, new services, new save systems, accounts, analytics, new languages, asset replacement and unrelated changes are outside the feature's implementation scope. A completed specification does not establish release readiness.
