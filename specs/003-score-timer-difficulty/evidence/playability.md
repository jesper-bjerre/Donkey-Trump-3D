# Playability implementation evidence

2026-10-18. Source inspection/calculation only. No gameplay, simulator, physical device or sequence test executed.

## Implemented initial constraints

LevelProgress freezes DifficultyRamp base configuration. With player u=120, jump v=210, gravity g=500 and maximum authored absolute surface slope s, J=(2v+2us)/g. The constant-per-level floor is ceil(10*(J*(b+u)/b+.10))/10, where b is base minimum barrel speed. The .10s margin is initial tuning, not measured reaction-time evidence. Actual interval=max(base*(1-.60p),floor), p=clamp(T/180,0,1).

| Visible level | Base seconds | Floor seconds | Actual at T0 /60 /120 /180 |
| --- | ---: | ---: | --- |
|1|3.200|2.1|3.200 /2.560 /2.100 /2.100|
|2|2.600|2.0|2.600 /2.080 /2.000 /2.000|
|3|2.000|1.9|2.000 /1.900 /1.900 /1.900|
|4|1.904|1.9|1.904 /1.900 /1.900 /1.900|
|5|1.816|1.8|1.816 /1.800 /1.800 /1.800|
|6|1.734|1.8|1.800 /1.800 /1.800 /1.800|
|Ramp limit|.800|1.4|1.400 /1.400 /1.400 /1.400|

From level6 the floor can slow the unpressured cadence. Desired factors remain unchanged; actual40% cadence is not promised at a binding floor. Speeds use1+.25p from one immutable sampled base; gravity/player physics unchanged. Rolling/ordinary falling preserve direction/factor1 or.25; ladder drops use70*m and endpoint snap. Direct ballistic flight preserves aim, including intermediate falling, until actual first landing.

The normalized release schedule retains the1.5s first delay, consumes capped opportunities, retains maxActive5/6/8 and ramp cap12, and does not accumulate pause releases. Seeded Debug cases cover upper/retry-max/limit layouts; malformed or combined fixture flags disable publication and persistent best before injection. Release excludes parsing/injection.

## Acceptance disposition

T027–T029 author observable core/scheduler/real-simulation/fixture boundaries. Full180s upper attempts, retained-maximum retries, every layout/ramp-limit/mixed sequence and iPhone13 touch/readability/frame-pacing are **not run** under the current prompt. The floor does not prove non-convergent mixed routes, safe future jumps or physical acceptance. No tuning based on executed gameplay evidence has occurred.
