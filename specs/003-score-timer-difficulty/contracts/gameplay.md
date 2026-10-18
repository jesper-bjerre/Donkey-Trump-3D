# Gameplay and Presentation Contract

Normative planned interface for [spec.md](../spec.md); types/invariants are in [data-model.md](../data-model.md). Existing Core remains independent of SceneKit, SwiftUI and networking. Design date:2026-10-18; no runtime checks executed.

## Ownership and command boundary

GameEngine owns a single monotonic clock adapter, stamped lock-protected input/command queue, scene graph and bounded physics delivery. GameSession owns phase, score, lives, LevelProgress, AttemptState and the sole terminal commit. GameSimulation proposes movement/contact events; BarrelSystem owns current hazard motion and release lifetimes. GameModel/observable HUD stays on MainActor. No view mutates progress directly; no network/storage work enters the render/core path.

New helpers are value/timeline support in existing Core, not a new engine or service. Clock values are injected: production uses one ContinuousClock origin, deterministic validation uses an owned source. Presentation/camera interpolation may retain a capped delta but gameplay duration must not inherit the old 50ms cap.

## Active time and event chronology

1. Record monotonic render/input/control/lifecycle stamps in one origin, as integral nanoseconds. Record the app's inactive state even during intro, life-loss, retry or level completion; suspend phase progression as well as T/R. Inactivity means app lifecycle, not a player standing still.
2. Build ordered spans split at state/input changes. Charge T/R only for spans in app-active play with an active attempt. Input holds describe their recorded spans; jump press is a single edge. Do not apply a newly sampled control retroactively to earlier backlog.
3. Drain at most32 slices per render callback. Normal fixed slice boundaries are cumulative `floor(n×1e9/120)`; split at a command/expiry boundary and use exact integral duration. Retain older foreground debt on budget exhaustion. Coalesce equal input spans; do not truncate time or process an unbounded catch-up loop.
4. On pause, finish only eligible pre-pause time, preserve progress/debt and exclude the paused gap. On app activation, rebase presentation timestamps, keep the game paused until explicit Resume and never import background time. Navigation/abandonment may immediately retire the prior run and its debt; normal pause is not abandonment.
5. For each active slice, bound duration to remaining R. Advance movement for that slice, register contact candidates at its end, and include timeout at the exact expiry if reached. Current120Hz contact registration is retained; no sub-slice swept collision claim.
6. Resolve the earliest terminal registration; exact ties: timeout before collision before rescue. An earlier registered rescue wins even if reported after a later timeout. A candidate must match current run/attempt. The resolver's answer cannot depend on array/callback order.
7. Commit once. A loss removes one life, freezes clocks and follows existing1.4s loss/.6s retry presentation or Game Over. A valid rescue adds the one-time reward breakdown and follows existing3.2s level-complete presentation. Later same-attempt time is inactive and cannot fast-forward a replacement attempt/celebration. Apply pending activity/navigation changes even when that attempt has closed.

Clocks/terminal presentation can lag while a large foreground backlog drains; original chronological time/outcomes remain authoritative. Ordinary30/60/120Hz accuracy and bounded stall recovery must be validated through this adapter, not only direct session calls. This design does not promise instantaneous results after arbitrary unrendered time.

## Reward protocol

- L is visible one-based level. Rewarded lifetime set contains at most20 distinct IDs and survives retry.
- A clearance candidate is eligible only for the current active attempt and an uncredited lifetime below the cap. At a loss boundary it must be strictly earlier than the loss; at valid completion it may be at the completion timestamp. Apply eligible candidates chronologically, then stable lifetime order for equal times. At most remaining cap entries pay `10×L`; every other clearance pays0 and emits no positive point effect.
- Completion adds `1000×L` once; bonus seconds are integer `max(0,180e9−Tns)/1e9`; time points=`5×L×bonusSeconds`. Use completion-time T, not reset R. A zero time bonus is still shown in the result breakdown but is not a positive point effect.
- Ordinary jumps pay0. Multi-barrel jumps sum only each eligible barrel's normal award; no combo bonus. Remove old parallel +100/+1000 reward paths/copy.
- Use checked numeric conversion/multiplication/addition before committing a reward transaction. No partial bonus, wrap, silent ceiling clamp or false positive acknowledgement. Keep the last valid total/best and navigation if a representational calculation fails; do not publish an invalid result.
- A ScoreAward carries copied IDs/time/position and exact value. All batched hazard/terminal feedback needed after a slice must be copied; a later pooled object state cannot rewrite an earlier award or effect.

## Pressure and release scheduling

`p=clamp(T/180s,0,1)`, interval multiplier=`1−.60p`, speed multiplier=`1+.25p`. Always use unchanged level base inputs. [Research R5](../research.md#r5--initial-playability-floor-derived-from-existing-movement) defines the constant-per-level floor and its checkpoint table. Actual interval is max(desired,floor); document the actual constraint, including base cadence slowed from level6. Do not claim actual40% interval where the floor binds.

Use a normalized release-progress accumulator. Preserve the first1.5s delay separately. After the first release, increment progress by active dt/current actual interval and, at a due opportunity, consume one opportunity and reset progress. If maxActive prevents release, still consume it, matching current no-backlog behaviour. In a normal ≤1/120s slice at most one opportunity is possible; no while-loop to flush past pauses. Pauses/background advance neither schedule nor pressure. Visual timeToNextSpawn uses remaining normalized progress and current interval so windup follows the same due opportunity.

A retry starts a fresh hazard system and first-release delay, with T's pressure already retained; new level resets T/base/floor. Preserve maxActive5/6/8 and existing ramp cap12; do not use player position to choose p. Existing direct targeting can still depend on position.

Movement scaling follows the R4 table: immutable sampled base speed for rolling/ordinary fall; preserve factor1/.25; ladder vx0/vy70×m; direct ballistic aim/gravity frozen until first actual landing, including intermediate falling mode. After landing use current scaled rolling speed. No compounding/resampling and no scaling of gravity/player jumps.

## HUD, result and help

- HUD includes total score, remaining attempt time and existing level/lives/Pause. Display `ceil(Rns/1e9)` as M:SS: start3:00; positive fractional remainder never0:00. The display must not drive gameplay timing.
- Reuse the existing levelComplete banner with completion points, time bonus including0 and cumulative score. Keep current flow duration/actions and original English parody text. No separate result screen.
- Life-loss feedback distinguishes timeout from collision; when timeout and collision tie, timeout reason wins. Existing retry and Game Over flow remains.
- Float positive points only for actual awards; reflect real L-scaled points. CompletedRun/local best/public submission receive that same unquantized score.
- Landscape iPhone13: readable timer/score, no controls/safe-area overlap, reachable existing actions; preserve applicable larger text, VoiceOver, Reduce Motion, sound and haptics. Validate reference-device touch/visual use separately from simulator evidence.
- Demo uses an isolated non-awarding simulation/pressure state; never mutates the real run. Autopilot sessions use the same gameplay/timer/pressure rules for repeatability, while existing production-publication restrictions remain enforced. Only explicit Debug loopback integration can submit synthetic owned results; Release has no override.

## Required observable boundaries

[Quickstart](../quickstart.md) assigns future checks for exact reference scores/rounding, cross-life cap, pooled identity, timeout/final life, contact/event ties, inactive timestamps, actual clock adapter/frame rates/stalls, pressure/floor/mode cases, existing banner/help, unchanged result publication and physical maximum-pressure sequences. These are planned checks, not passing outcomes.

## Debug acceptance fixtures

Planned, Debug-only command: `-gameplayFixture CASE -gameplaySeed UINT64`. Allowed cases: `upper-1`, `upper-2`, `upper-3`, `retry-max-1`, `retry-max-2`, `retry-max-3`, `limit-layout-1`, `limit-layout-2`, `limit-layout-3`. No arbitrary production state injection.

- Upper cases use visible levels1/2/3, T0/R180, score0, normal lives and a valid standing position on the top girder outside the rescue zone. Derive the position from current layout geometry, verify no initial collision/goal, and leave real movement/reward/timeout rules active for the full attempt.
- Retry-max cases use the same layout/position with retained T180 and fresh R180, representing a retry at capped pressure. The cap/history setup is explicitly labeled synthetic; separate core checks prove real cross-life retention.
- Limit-layout cases use DifficultyRamp indices999/1000/1001 (layouts1/2/3 at the existing rounded limits) with T180/R180 and otherwise real hazard/player rules. Confirm the produced base values equal the existing limits rather than assuming an unbounded level index is needed.
- Every case is tagged as fixture state, uses a reproducible supplied seed, and is prohibited from production publication. GameModel must select UnavailableHighscoreService whenever the flag is present, including malformed/unknown values, before default backend selection. GameEngine's parser only injects valid cases under `#if DEBUG`; malformed input fails closed, never enables online submission. Existing highscore fixtures/integration flags must not override this prohibition when combined with a gameplay fixture.
- GameEngine must also use an in-memory best/save closure whenever a gameplay-fixture flag is present, including malformed flags. Fixture totals must never replace the real UserDefaults personal best; ordinary saved best/settings remain untouched. Future boundary checks compare the real best before/after fixture termination and restart.
- A Debug gameplay fixture is for actual gameplay acceptance, not the existing synthetic CompletedRun API integration exception. Never combine them to publish. Existing explicit loopback CompletedRun integration remains separately available without a gameplay fixture.
- Release must compile out fixture parsing/state injection and test-only clock inputs. A future Release configuration/binary/launch-boundary check must establish that the flags cannot change gameplay or service selection. No fixture result qualifies as a genuine published run.
