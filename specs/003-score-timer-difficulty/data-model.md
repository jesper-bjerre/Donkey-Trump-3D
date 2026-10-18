# Data Model: Score, Attempt Timer and Level Pressure

Design only — 2026-10-18. Implements [spec.md](spec.md) within the existing GameSession/GameSimulation ownership. No persisted schema migration is introduced. Fields below are intended additions/value contracts, not claims about current implementation.

## Run state — owned by GameSession

| Field | Representation / invariant |
| --- | --- |
| runID | Existing UUID; fresh on new game/restart; absent at title |
| score | Existing nonnegative Int; one authoritative accumulated total, exact checked reward arithmetic |
| lives | Existing life count; at most one decrement per attempt terminal commit |
| levelIndex / visibleLevel | Existing zero-based index / L=index+1, checked conversion; repeated layout does not reset L |
| levelProgress | Exactly one current LevelProgress |
| attempt | Exactly one current AttemptState while playing/retrying |
| completedRun | Existing immutable final UUID/score/visible-level tuple, frozen once on final-life Game Over |
| best | Existing max(saved best, earned valid totals); retained independently of network |

A result outside the existing remote score range stays exact locally and is ineligible for publication. A failed arithmetic operation must not mutate the previous valid total, wrap or falsely acknowledge an award. Preserve restart navigation and best; no invalid result may publish.

## LevelProgress — survives life loss

| Field | Representation / invariant |
| --- | --- |
| visibleLevel | Int L≥1; fixed until progression |
| baseBarrelConfiguration | Immutable DifficultyRamp output for this visible level |
| totalActiveNs | Int64 T≥0, accumulated only in eligible active slices; retained on retry |
| rewardedLifetimes | Set of BarrelLifetimeID; count0…20; at most20 retained identifiers |
| completionReward | Optional immutable LevelRewardBreakdown; set once on valid completion |
| minimumReleaseInterval | Positive seconds derived once from immutable player/base-speed/layout inputs; constant for this level |

Derived p = min(1, T/180s). Desired interval/base speed use the exact spec multipliers. `actualInterval=max(desiredInterval,minimumReleaseInterval)`. Completion bonus uses L; bonus seconds are integral `max(0,180e9-totalActiveNs)/1e9` with integer division. A new level/reset clears history and reward breakdown; death does not.

## AttemptState — replaced on retry

| Field | Representation / invariant |
| --- | --- |
| attemptSerial | Increasing UInt64 within run; never reused; checked rather than wrapping |
| remainingNs | Int64 R in0…180e9; fresh retry180e9 |
| outcome | active / lifeLost(collision or timeout) / completed; one terminal transition only |
| terminalAt | Optional integral registered active timestamp; immutable after resolution |
| spawnSerial | Increasing per attempt on every release including pool reuse |

Do not use GameSimulation's reset time or render object IDs as cross-life history. No subsequent callback can change a terminal attempt or another generation. Retry retains level T/history/score and replaces attempt/simulation; fresh whole game replaces both.

## Barrel lifetime — owned by current BarrelSystem

- **BarrelLifetimeID**: `(runID, attemptSerial, spawnSerial)`, assigned on release, immutable for that lifetime. Object/pool `Barrel.id` is a separate render-node key.
- **Immutable baseSpeed**: one existing random sample from this level's base min/max; pressure never resamples it or compounds its changed value.
- **Movement provenance**: rolling / ordinary fall(horizontal factor1 or.25) / ladder drop / direct ballistic until first actual landing. Preserve direct-flight provenance through the existing thrown→falling intermediate mode.
- **Reward detection flag**: marks a detected clearance for this lifetime; authoritative eligibility and the cap remain in LevelProgress. New release resets its flag and gets a fresh lifetime ID; recycle cannot alter copied historical events.
- Existing x/y/velocity, direction, gravity, routes, maximum active count and node reuse remain with current movement ownership.

## Immutable events and result presentation

| Value | Required fields / meaning |
| --- | --- |
| ClearanceCandidate | run/attempt/lifetime IDs, registeredAtNs, copied position; does not imply awarded points |
| TerminalCandidate | run/attempt IDs, registeredAtNs, timeout/collision/rescue; no mutation until arbitration |
| ScoreAward | IDs, registeredAtNs, source(barrel/completion/time), exact awarded points, copied effect position; positive feedback only for an actual positive award |
| LevelRewardBreakdown | visible L, completionPoints, bonusSeconds, timePoints, totalAfterCompletion; immutable one-time result, includes timePoints0 |
| LifeLossSnapshot | reason(timeout/collision), remaining lives and attempt identity; timeout does not masquerade as a barrel hit |
| HUDState additions | remaining display seconds, level reward breakdown and last loss reason; all values copied with existing score/phase/run identity |

Batched events must not retain mutable pooled Barrel references as authoritative identity/feedback. Rendering may locate live nodes by the separate pool key but must use event-time copied positions for historical effects. Immutable HUD publication remains on the existing main-actor boundary.

`registeredAtNs` and `terminalAt` mean cumulative active level time T at registration, scoped by run/attempt identity. Adapter command stamps instead mean monotonic nanoseconds since engine origin. The timeline projects adapter intervals into active T; comparisons must never mix these two coordinate systems or compare candidates from different attempts.

## Gameplay timeline — engine-owned adapter, pure duration input to core

- One injected monotonic source and origin produces nonnegative integral ns stamps for renderer and queued UI/activity/input events. No comparisons between different clock epochs.
- The first renderer sample establishes its anchor without inventing a default frame duration. Starting a run clears prior title/demo accumulator state and anchors play at its stamped start.
- Stamped commands include a stable enqueue sequence for equal stamps. Activity false and explicit pause close active intervals. Activity true rebases presentation but does not resume a paused game without its existing explicit action.
- Ordered interval/input spans retain foreground debt. Coalesce adjacent identical spans; one press edge is consumed once. At most32 chronological slices are drained per render turn; remaining debt is retained and source time never clipped to the presentation cap.
- Integer 120 Hz slice boundaries are computed from cumulative index and an anchor, including partial slices at commands/expiry. Fractional active time must be consumed before a pause boundary rather than dropped; resume starts a new phase anchor.
- For equal-stamp state changes, inactivity/pause takes effect before advancing beyond that stamp. Start/restart/title abandons the old run generation, so its debt/events cannot appear in a new run. Abandonment/navigation may retire old debt immediately; normal pause preserves it.
- When an attempt terminates, discard only its later gameplay interval as inactive, never apply it to retry/new level. Preserve visible death/retry/celebration timing from presentation delivery. Continue processing lifecycle/navigation boundaries to avoid stale app activity.

The clocks reflect resolved simulation time. During a large foreground backlog their presentation can lag the source clock; no elapsed active time is silently lost. Neither a lagging HUD nor injected timestamps establish physical timing acceptance.

## Persistence and highscore projection

Current runs are memory-only; no process-death recovery is added. Preserve existing UserDefaults best/settings and installation credential lifetime. FR-021 would apply only if implementation inspection discovers a real existing same-run restore path; then it must serialize the same progress/attempt invariants rather than reset them.

The existing CompletedRun freezes the final authoritative score. [Score-domain contract](contracts/highscore-score-domain.md) defines valid remote numbers. Do not add a score/rules version field, new board, deferred payload or hidden conversion. Stored moderation entries, identity, origin, successful-save sequence, timestamps and aggregate schemas remain unchanged.

## State transitions

| Event | Attempt / R | Level T and history | Score and outcome |
| --- | --- | --- | --- |
| New game / explicit Restart from Level1 | Fresh active attempt180s when play starts | New level0/empty | score0; existing lives; old generation retired |
| New level after valid completion | Fresh attempt180s | New base/T0/history empty | Prior one-time bonuses/score retained |
| Collision/timeout, lives remain | Commit loss once; R stops; fresh180s only when retry starts | Retained | Preserve score; timeout awards no completion/time bonus |
| Final-life loss | Terminal, no replacement attempt | Frozen | Freeze CompletedRun once; preserve local best |
| Pause / app inactive | Freeze; later resume preserves R | Preserve T/history | No new gameplay reward; app inactive also freezes phase progression |
| Successful rescue before expiry | Commit completion once and stop R | Freeze T for bonuses | Add completion + time once, expose breakdown |
| Duplicate/stale event | No transition | No mutation | No points, duplicate life loss or replacement outcome |
