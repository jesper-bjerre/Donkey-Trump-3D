# Independent review: `specs/003-score-timer-difficulty` (specify phase)

**Reviewer:** Claude Opus 5.5 (`claude-opus-5-5`), effort high, read-only and tool-free. This is my own assertion of identity. It is not verification; the lead must record the provider/session metadata.

**Author:** OpenAI Codex lead. I did not take part in authoring.

**Candidate reviewed:** the frozen identity above:
- `spec.md` `6b75005…`
- `checklists/requirements.md` `6bc35466…`
- `.specify/feature.json` `c3aaaf25…`
- base `9483e8e`

## Verdict: **APPROVE** (unchanged candidate)

I found no material findings. The optional suggestions below do not block approval.

## Missing or partial context

I checked whether any of these gaps blocks a conclusion. None does, because the spec states each one as a planning dependency rather than a settled fact.

- **`docs/architecture_options.md` was not supplied.** I cannot confirm the claim that runs are held in memory (`spec.md:183`). It is worded as an assumption with "Planning must confirm", so it does not block.
- **The UI, renderer, help text and `BarrelSystem` source were not supplied.** I cannot confirm that a level-result view exists (FR-017, Story 4 scenario 1) or how barrel movement types work. The `levelComplete` phase and its 3.2 s timing (`Rules.swift:14`, `Simulation.swift:243`) suggest some level-complete presentation exists.
- **I don't know whether `002-app-store-release` has shipped a client.** This matters for compatibility with clients already in the field (see S-1).
- **I did not see the contents of `.specify/init-options.json` or `.specify/extensions.yml`.** For numbering and hook absence I relied on the lead's document checks.

## Independent verification of lead conclusions

| Lead claim | My assessment |
|---|---|
| All 19 intent acceptance items covered | **Confirmed, with one traceability caveat.** Every item has a matching requirement or scenario. Intent item 15 (frame rate) is covered by FR-009 and SC-003, not by a Story 2 scenario as the checklist note at `checklists/requirements.md:37` says. See S-2. |
| Reference arithmetic | **Confirmed.** 1000+100+600=1,700. 2000+100+600=2,700. Total 4,400. T=60.2 gives floor(119.8)=119 bonus seconds. 200×L cap. |
| Exact goal/timeout tie resolves as timeout | **Supported.** The intent (`Svaerhedsgrad.md:206-208`) leaves the exact tie open. The spec records the default as an assumption (`spec.md:181`), and the default is deterministic. |
| Collision/goal tie before expiry costs a life | **Supported.** It matches existing behaviour: a hit returns before the rescue check (`Simulation.swift:106-119`). It is documented as a default. |
| Display rounds R up; bonus seconds round down | **Confirmed.** This matches the intent (`:86`, `:142`) and FR-016 / FR-005. |
| Multiple-of-100 validators create a dependency | **Confirmed.** New scores are always multiples of 5: 1000L, 10L and 5L·s. The current validators reject them at `HighscoreModels.swift:5`, `HighscoreValidation.cs:10,50` and the OpenAPI `multipleOf: 100`. FR-018, Story 4 scenario 2 and SC-008 capture this. Keeping exact values without rounding follows intent item 18. Both example scores can occur: 10 (one barrel, then Game Over) and 1,005 (completion with 1 bonus second). |
| All four stories make up full completion | **Confirmed** at `spec.md:179`. |
| All 16 checklist criteria pass | **Agreed.** The formulas are business rules. No frameworks or APIs leak into the requirements. |
| No clarification needed | **Agreed.** The remaining unknowns (other reward sources, playability floor, restore, leaderboard versioning) are evidence-gathering tasks the intent itself assigns. They are not open player rules. |

## Other checks with no material issue

- **Scope:** one feature, no plan or tasks, pointer persisted.
- **Constitution:** offline play, bounded failures, no deferred upload, consent, and physical-device versus simulator evidence are covered by FR-020, FR-022 and SC-006.
- **Inactive states:** listing intro as inactive (FR-008) correctly matches the `.intro` phase.
- **Combo removal:** supported by the intent (`:117`) and the existing `comboBonusPerExtraBarrel` constant.
- **Highest-difficulty playability:** the ramp has fixed limit values (`Level.swift:110-115`). The spec's "highest existing base difficulty" in SC-006 can be tested against those limits, and planning must inspect them (`spec.md:184`).
- **Leaderboard recommendation timing:** FR-019 asks for the recommendation before implementation, while the intent asks for it in the delivery. Asking earlier is stricter and still within scope.

## Optional suggestions (non-blocking)

**S-1: Field and deploy compatibility (planning).**
- An installed client using the current `HighscoreSnapshot.validate` (`HighscoreModels.swift:63`) rejects the whole list as soon as it contains one score that isn't a multiple of 100.
- A new client submitting such a score to an un-updated backend gets a terminal `validation_failed`.
- If any build has shipped, planning should cover deployed clients and the order in which backend and client changes go live, as part of FR-018/FR-019.

**S-2: Frame-rate traceability (checklist and stories).**
- Either correct the checklist note to say intent item 15 maps to FR-009/SC-003, or add a Story 2 scenario.
- That scenario should check that equal active durations at different update rates give identical points, not only identical expiry timing.

**S-3: Feedback when timeout and collision happen together.** FR-020 requires timeout feedback to be accurate, but nothing says which life-loss message to show when both happen in the same update. Planning could pick one.

**S-4: Demo and autopilot mode.** The spec doesn't say whether the timer and pressure apply in demo or autopilot mode (see `ios-flow.md:48`). Planning could state it.

## Limitations

- This is a document review only. No tests, builds, gameplay or device checks were run, and none were needed at the specify phase.
- The runtime source excerpts were used as context only. I have not fully reviewed or verified them.
- This approval says nothing about implementation correctness or release readiness.
