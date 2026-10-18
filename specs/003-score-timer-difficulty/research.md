# Research: Score, Attempt Timer and Level Pressure

Date: 2026-10-18. Method: source inspection by the lead and three read-only research helpers (timing/ownership, physics/playability, highscore compatibility). No tests, simulations, builds, app runs or cloud operations were performed. Source baseline: `9483e8eff3732cb4816942f6c9988ac1165ec537`; current feature specification is pre-existing untracked input.

## R1 — Retain the current ownership and inventory rewards

**Decision**: Extend GameSession with per-level progress and per-attempt state. Keep GameSimulation for movement/contact candidates, BarrelSystem for hazards and GameEngine for adapter/rendering. Store a single run score and update best through its existing path. Reward events become immutable values with actual points and location.

**Evidence**: `src/DonkeyTrump3D/Core/Simulation.swift:198-229` has only two production award paths: +100 per barrel and +1000 per rescue. `Core/Rules.swift:3-8` declares an unused combo constant; no production caller was found. `Simulation.swift:3-16` currently places mutable pooled Barrel references in events; `App/GameEngine.swift:569-600` batches events across ticks before rendering them. `UI/RootView.swift:449` and `GameEngine.swift:632` repeat the old completion constant.

**Rationale**: Replace both old award paths; remove the obsolete combo rule/copy without inventing another bonus. Authoritative awarded values prevent non-paying clearances from showing +points and prevent pool reuse from changing delayed effects. The existing completion banner receives the two bonuses and cumulative score, rather than a new screen.

**Alternatives considered**: Renderer-owned scoring or a second rule engine would duplicate state. Keeping mutable Barrel events as reward identity would allow later pool reuse to change historical payloads. The old constant may remain only where unrelated historical evidence quotes it, not in active scoring/help.

## R2 — Exact active duration and bounded work

**Decision**: Use one injected Swift ContinuousClock domain with engine-origin integral nanosecond stamps for render samples and queued input/pause/activity commands. The core accepts durations/stamps, not SceneKit or a system clock. Use checked Int64 duration arithmetic; derive floating seconds only for existing movement/pressure. One second is 1,000,000,000 ns. Compute fixed slice boundaries from the cumulative index, `floor(n × 1e9 / 120)`, using quotient/remainder arithmetic to avoid intermediate overflow. Split at commands/expiry exactly.

**Evidence**: `GameEngine.swift:331-345` clips every frame to 0.05 s; `:557-577` then feeds its 120 Hz accumulator. This would lose foreground time below 20 fps or during stalls. `DonkeyTrump3DApp.swift:19-22` sends pause only on leaving active; the engine accepts pause only in play (`:388-394`). Adding repeated Double(1/120) can also cross an integer bonus boundary numerically.

**External basis**: Apple's [ContinuousClock documentation](https://developer.apple.com/documentation/swift/clock/continuous) says the clock continues through system sleep; the explicit app-activity gate therefore excludes inactive periods. The [Swift clock proposal](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0329-clock-instant-duration.md) defines monotonic instant/duration use. Apple's [SceneKit callback documentation](https://developer.apple.com/documentation/scenekit/scnscenerendererdelegate/renderer%28_%3Aupdateattime%3A%29) describes a per-frame callback; it is not permission to mix unrelated clock epochs. These support clock selection, not a claim that the proposed adapter already works.

**Rationale/design**: Retain raw foreground interval debt and recorded input changes, process oldest first with at most 32 physics slices per render callback, and retain the remainder. At 30/60/120 callbacks per second normal demand is 4/2/1 slices. A timestamped inactive/pause boundary closes the preceding active segment even if delivered after suspension. All phase progression suspends while app inactive; returning active rebases presentation time and does not automatically unpause play. Preserve pre-boundary debt rather than discarding it. Coalesce adjacent identical input spans; a jump press is a single dated edge, not repeated in every catch-up step.

Only simulation registration time advances T/R. Under a long foreground stall, backlog can delay visible timer/terminal presentation while chronological physics catches up; elapsed active time is retained, never silently clipped. This is an explicit limitation outside the ordinary-rate tolerance, not an instantaneous wall-clock guarantee after arbitrary stalls. A terminal event closes the attempt; later recorded time belonging to it is inactive and cannot advance the retry/next level. Start transition presentation at delivery with its existing visible duration.

**Alternatives considered**: Reusing the clamped frame delta loses active time. Advancing a separate wall-clock timer ahead of unresolved physics can timeout an earlier valid completion. An unbounded catch-up loop risks blocking rendering. A repeating UI timer drifts, duplicates ownership and does not solve event ordering. A small epsilon around bonus boundaries can award a real fractional second incorrectly; integral duration avoids it.

## R3 — Terminal registration, identities and reset semantics

**Decision**: Resolve terminal candidates centrally before applying mutations: earliest registered occurrence wins; exact ties use timeout, collision, rescue. Current contact detection is sampled at the end of each 120 Hz physics slice. That slice-end registration is the occurrence time for collision/rescue; split a slice at R=0 and register timeout there. This preserves existing registration semantics and does not claim swept, sub-slice physical contact ordering. A strictly earlier registered rescue remains final.

**Evidence**: `Simulation.swift:70-119` detects clearances, collision and rescue in that order, returning on hit. `:212-229` currently applies array events without one terminal guard. `:45-53,238-247` reloads the simulation on retry/new level and resets barrel IDs/time. `Barrels.swift:113-137` reuses object IDs and clears jumpAwarded.

**Rationale/design**: Add attempt serial and per-release spawn serial under run identity; retain existing object IDs only for scene-node reuse. Session level progress retains at most 20 rewarded lifetime IDs across all lives. A reward candidate must match run/attempt, be at or before the valid completion boundary and be strictly before a loss boundary; ties at collision/timeout earn no barrel reward. Process equal-time eligible barrels by stable lifetime order and remaining capacity. No stale attempt or completed level may reward again. Reset only attempt on retry; reset level progress only on next level/new run. See gameplay contract for the exact acceptance sequence.

**Alternatives considered**: Callback ordering or object identity cannot enforce deterministic outcomes across pool reuse and retries. Swept contacts would change the collision system; existing 120 Hz registration plus exact terminal injection covers the requested registered-boundary semantics. If later physical evidence demands finer contact ordering, it must receive movement regression evidence before acceptance.

## R4 — Preserve base difficulty; apply pressure by motion mode

**Decision**: Freeze each `DifficultyRamp.level(at:)` output as this level's base. Recompute pressure from retained T and immutable sampled per-lifetime base speeds, never previously scaled values. Scale rolling/normal falling horizontal speed and ladder-drop speed; preserve gravity, vertical ballistic motion and direct-throw aiming until first landing.

**Evidence**: `Core/Level.swift:109-140` bounds base interval at 800 ms, speed 240–280, direct chance .55 and active count 12. `Barrels.swift:79-109` computes direct vx from distance/fall time, capped ±320. `:154-178` changes thrown to falling before landing; checking only mode == thrown would accidentally overwrite remaining aim. Ladder drops use horizontal zero and base speed70; ordinary girder-edge falling uses horizontal factor .25.

| Movement | Derived state |
| --- | --- |
| Rolling | direction × immutable baseSpeed × m |
| Normal initial fall | base horizontal factor1 × baseSpeed × m |
| After girder edge | base horizontal factor.25 × baseSpeed × m |
| Ladder drop | vx0; vy = 70 × m; retain endpoint snap |
| Direct ballistic flight, including pre-landing falling | retain launch vx, gravity and existing vertical integration; mark flight until first actual landing |
| After direct first landing | use the same current scaled rolling base as other barrels |

**Rationale**: Multiplying direct vx would overshoot its target without changing fall time. The ballistic phase is the explicit movement-type limitation permitted by FR-014. First-release delay remains1.5 s; existing maxActive and direct/ladder route probabilities remain unchanged by time pressure.

**Alternatives considered**: Multiply all velocity components, multiply each frame or modify the immutable DifficultyRamp result in place: respectively breaks aiming/gravity, compounds scaling or loses the original base. A new spawn while-loop could replay inactive backlog; consume at most one due opportunity per bounded slice and schedule from that active point, even when maxActive prevents a release.

## R5 — Initial playability floor derived from existing movement

**Decision**: For each new level calculate one constant minimum release interval from its immutable base minimum rolling speed b and maximum absolute girder slope s:

```text
u = 120                          # existing player horizontal speed
v = 210                          # existing jump velocity
g = 500                          # existing gravity
J = (2*v + 2*u*s) / g             # nominal downhill full-jump duration
minimumInterval = ceil(10 * (J * (b + u) / b + 0.10)) / 10
actualInterval(T) = max(baseInterval * (1 - 0.60*p), minimumInterval)
```

**Evidence/rationale**: `Player.swift:4-28` sets those movement constants; full flat jump lasts .84 s and apex is44.1 units. Layout slope maxima are20/740,26/740,32/740 (each `Resources/Levels/level*.json:32-56`), producing J≈.853/.857/.861 s. The speed ratio reserves time for a player running toward an incoming equal-speed rolling stream. The extra .10 s is a deliberate initial release-headway margin, then rounded up to .1 s; it is tuning, not a measured reaction-time guarantee. Desired .32 s at the ramp limit would permit equal-speed head-on encounters only .32×300/(300+120)≈.229 s apart. Existing visual windup .55 s plus post-release pose .35 s also exceeds that desired cadence (`Barrels.swift:45`, `GameEngine.swift:644-646,711-715`).

| Base level | Base interval | Floor | Actual at T=0 / 60 / 120 / 180 s |
| --- | ---: | ---: | --- |
| 1 | 3.200 s | 2.1 s | 3.200 / 2.560 / 2.100 / 2.100 s |
| 2 | 2.600 s | 2.0 s | 2.600 / 2.080 / 2.000 / 2.000 s |
| 3 | 2.000 s | 1.9 s | 2.000 / 1.900 / 1.900 / 1.900 s |
| 4 | 1.904 s | 1.9 s | 1.904 / 1.900 / 1.900 / 1.900 s |
| 5 | 1.816 s | 1.8 s | 1.816 / 1.800 / 1.800 / 1.800 s |
| 6 | 1.734 s | 1.8 s | 1.800 / 1.800 / 1.800 / 1.800 s |
| Existing ramp limit | .800 s | 1.4 s | 1.400 / 1.400 / 1.400 / 1.400 s |

All layouts reach the floor within an attempt. From level6 it can already slow the unpressured base cadence. Desired multipliers remain the approved formulas; actual cadence is explicitly constrained, while speed continues increasing. This is the FR-015 tradeoff, not a claim of full 60% actual interval reduction at every level.

Different sampled speeds, routes and direct targeting can converge despite release spacing. This calculation is an initial safety envelope, not proof of all sequences or physical acceptance. Future repeatable rolling/direct/mixed sequence checks and reference-iPhone jumps/landings remain gates; a failure requires tuning interval/spacing within scope and rerunning affected authorized checks.

**Alternatives considered**: No floor leaves intervals far below a full jump. A global2.1 s floor unnecessarily flattens higher levels. Changing jumps/gravity or removing direct throws changes established gameplay and is outside this design.

## R6 — Score compatibility, old clients and historical comparability

**Decision**: Widen the common predicate to integer multiples of5 in0…2,147,483,600. Keep `/api/v1/highscores`, exact returned scores, current public/request shape, installation credentials, private schema1/2, Blob name, one all-time list, rank/ties and ETag/moderation behaviour.

**Evidence**: Swift `HighscoreModels.swift:5,23-28,57-84` validates submissions, every snapshot row and qualification. Backend `HighscoreValidation.cs:9-10,48-50` is also used by `HighscoreDocument.cs:20-40,76-99` and `HighscoreRanking.cs:8-10`. `HighscoreConfiguration.swift:9` and `HighscoreEndpoints.cs:7-17` expose one route. `schemaVersion` is a storage/moderation format, not a scoring season. Public records have no reliable old/new rules tag; divisibility cannot infer one because new scores may also be divisible by100.

**Existing authorization and limitation**: [Single-API rollout decision, 2026-09-28](../../docs/releases/app-store/backend-single-api-rollout.md) records owner authorization to evolve v1 in place, rebuild the owner-only app and make no older-client compatibility promise. [Release record, 2026-09-29](../../docs/releases/app-store/1.0-2/release-record.md) describes a prepared, unsubmitted draft. These are dated source evidence, not current Apple/distribution verification. Design follows the recorded in-place compatibility boundary. A future rollout must confirm installation/distribution constraints; if continued old-client online support is newly required, resolve that prerequisite before deployment.

Strict old apps reject entire mixed snapshots as soon as one score is not divisible by100, including a successful POST response whose write may already have committed. Never describe those binaries as compatible or replay their failed save. New apps must accept mixed old/new exact scores. Future sequence: compatible widened-reader backend first, rebuilt participating clients next. Once a non-hundred score persists, old strict backend binaries cannot deserialize the aggregate; rollback must retain widened score validation/readability and all existing data. No deletion, rounding, schema migration or operator rewrite is needed/authorized.

**Comparability recommendation**: Retain the single all-time historical archive and document that it spans a scoring-rules change; old farming totals are not directly comparable to new totals. Do not re-score history or infer a rules tag. A new season/segmented board would require separate scope. Preserve local best unchanged, even if earned under old rules.

**Alternatives considered**: Changing only POST validation still breaks serialization/readback/client snapshots. A new route alone cannot make an old decoder read five-point values. Filtering or rounding creates different list semantics or false scores. Separate boards, new fields/services and automatic history conversion exceed scope.

## R7 — Persistence, numeric safety and acceptance boundaries

**Decision**: No active-run save system. Session memory retains state through pause and retries; only existing best/settings/credential persistence remains. Keep Int run score and checked reward multiplication/addition, preserving exact values within representable bounds. The remote ceiling remains unchanged; an exact local result above it stays local with existing unsupported-result handling, no quantization/upload. Any representational arithmetic failure must be explicit and fail closed for scoring/publication, preserve the last valid score/best and restart navigation, never wrap or silently clamp a credited award.

**Evidence**: `GameEngine.swift:111-120`, `Simulation.swift:125-142,198-203,218-227` and `docs/architecture_options.md:112-119` show in-memory run and independent saved best. `HighscoreCoordinator.swift:21-29` rejects unsupported results before publication. Endless progression makes remote-range exclusion possible in principle; it is not a reason to raise the API ceiling.

**Validation decision**: Cover all19 intent cases, exact rounding boundaries, actual engine adapter/lifecycle and retained backlog, immutable events/pool reuse, old/new score document round-trips and unchanged failures. Synthetic completed-run fixtures prove transport/UI, not gameplay earning. Real loopback API + helper-owned Azurite proves serialization/storage boundaries. Physical gameplay/touch/readability/frame pacing is a separate reference-iPhone gate. Tests are only executed on a future explicit request; no runtime acceptance is claimed now.

**Alternatives considered**: Saving/replaying runs or failed uploads is unnecessary and violates scope. Lowering local score to the remote ceiling alters earned points. Assuming existing helper starts with a missing blob is wrong: `src/tests/support/local-highscores.py:73-76` explicitly initializes an isolated empty schema2 aggregate.
