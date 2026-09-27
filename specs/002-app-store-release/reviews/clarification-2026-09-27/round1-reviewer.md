# Independent review: speckit-clarify synchronization for `specs/002-app-store-release`

**Role:** Independent Anthropic reviewer (not the author). Read-only. No tools, no other reviewer invoked.
**Reviewed candidate:** `spec.md` after-hash `5831a63b…590f9`, checklist `112e887c…6695` (unchanged), base commit `05238815…5099094`, `task.diff` and `validation.json` as supplied. I did not recompute hashes or resolve links.

## Verdict

**CHANGES REQUESTED. Scoped spec edits only; no owner questions needed.**

- **Zero questions is correct.** Every owner follow-up is an explicit decision, and the earlier three answers are settled. No candidate question meets the skill's materiality or uncertainty bar. Leaving out new Q/A bullets is also correct, because nothing was asked in this session.
- **Fidelity to the owner's instructions is good.** I traced each item:
  - "Mindst 10, stadig top 100" → FR-026 and SC-010.
  - "Low points" → low-scoring starters, which matches the backend's 100–1,000.
  - The dialog with a clear input and submit, with the public-name and real-name text omitted.
  - Loading "mindst mulig tid", with highscores loaded asynchronously and a waiting state allowed if opened early → FR-024 and SC-008.
  - An approximate progress bar.
  - Music during loading and the menu → FR-025, SC-009 and US1-6.
  - DEV/PROD deployment is cited as dated evidence, with a live refresh still required.
- **Status separation is sound.** The Status line, the Assumptions and FR-023 keep implemented or deployed slices separate from store readiness. The owner's boundary around submitting for review and releasing is intact in FR-020, FR-021 and SC-006.
- **"Ready for speckit-plan" does not yet follow** because of R-01. With R-01 fixed, and R-02 and R-03 fixed or explicitly dispositioned, I expect to approve on a focused re-review.

## Findings

### R-01: HIGH. FR-026 removes the in-dialog public-name text without stating how Constitution IV is still met

- **Location:** `spec.md:147` (FR-026), `spec.md:56` (US2-6), `spec.md:171` (SC-010). Governing rule: `constitution.md:60`, "Public name/score publication MUST require an explicit player action **and explain what is public**." AGENTS.md:236 also flags public-name consent.
- **Evidence:**
  - FR-026 requires the advisory text to be omitted. It then defers to "FR-007–FR-008 and the highscore contract".
  - FR-007 covers public web pages and in-app access to the privacy policy.
  - FR-008 covers the App Store privacy answers.
  - Neither says that the app itself explains that the name and score become public. SC-010 tests only that the text is absent.
- **Impact:**
  - The plan's Constitution Check could find either compliance or a conflict, depending on interpretation.
  - Release acceptance has no check that the "explain what is public" duty is met anywhere in the app.
  - The taxonomy entry "Security & privacy: Clear" is overstated on this point.
- **Fix within scope (no owner question):** The owner removed the text from the dialog only, not the explanation everywhere. Amend FR-026 and SC-010 to:
  1. Name where the app explains that the name and score appear on the public list, for example the in-app privacy/help copy required by 001 FR-020 and FR-007.
  2. State that this satisfies Constitution IV without any reminder in the dialog.
  3. Make that location part of acceptance.
- **Escalation:** If the lead concludes that nothing short of the dialog text can satisfy Constitution IV, the finding is a CRITICAL constitution conflict. It then needs an explicit amendment or product decision. It must not be passed as Clear.

### R-02: MEDIUM. FR-012's "cost estimate before provisioning" was not reconciled with the recorded deployment

- **Location:**
  - `spec.md:133` (FR-012): "Record the traffic/storage assumptions and cost estimate before provisioning."
  - `spec.md:110` (edge case): "…blocks provisioning."
  - `spec.md:180`, the new sentence citing the 2026-09-27 release.
  - SC-007 at `spec.md:168`.
- **Evidence:**
  - `backend-release-2026-09-27.md` shows DEV and PROD apps and storage already exist. There is an earlier DEV run `36251495999` and a pre-existing DEV row.
  - That record includes CPU and memory samples but no cost estimate or baseline for committed plan charges.
  - The synchronized Assumption cites the deployment but does not say whether the FR-012 estimate exists.
- **Impact:** For resources that already exist, FR-012's ordering is either already met, with the estimate absent from the evidence, or can no longer be met. The plan inherits either a stale gate or a silently unsatisfiable one. This is exactly the contradiction the skill's step 6 and 7 checks for obsolete text are meant to remove.
- **Fix:** State one of the following:
  - Link the estimate if it exists.
  - Otherwise, the release record must record the assumptions, the additional-cost estimate and the committed baseline for the resources already deployed before draft readiness. Any further provisioning still needs an estimate first.

### R-03: MEDIUM. "Ten visible entries" and "ten ranked players" conflict with the governing terms and with accessibility acceptance

- **Location:** `spec.md:56` ("fewer than ten ranked players … ten visible entries"), `spec.md:147` ("at least ten visible entries"), `spec.md:171` ("ten visible … when fewer than ten real results").
- **Evidence:**
  - 001 FR-001 uses "at least ten entries".
  - 001 Assumptions and Edge Cases say the list ranks runs, not people, and names are not unique.
  - FR-016, 001 FR-019 and Constitution I require larger text and VoiceOver in landscape. At larger text sizes, ten rows cannot all be visible on screen at once.
- **Impact:**
  - A literal acceptance test could require ten rows visible at the same time, which contradicts the accessibility requirements.
  - "Players" suggests counting people. This breaks the skill's check for terminology consistency.
- **Fix:** Normalize the wording to "at least ten ranked entries in the list (fewer than ten real results)". Drop "visible" and "players".

## Checks on the other claims

- **Checklist 16/16 → 16/16 with no toggles:** agreed. FR-025 is covered by US1-6 and SC-009, and FR-026 by US2-6 and SC-010. Non-blocking: the traceability note at checklist lines 36 and 39 does not mention FR-025, FR-026, SC-009 or SC-010. The skill forbids editing non-checkbox content, so the report should just mention it.
- **ID counts:** 26 FRs and 10 SCs are unique, which matches `validation.json`.
- **Sections touched:** the list is accurate against `task.diff`.
- **Hooks:** there is no `extensions.yml`, so skipping them is correct.
- **Other categories:** I agree they are Clear at requirement level. This includes the fact that FR-024 sets no numeric loading-time target. "As soon as required local loading finishes" plus no timer is testable, and the plan can set a budget.
- **Out of bounds:** the report makes no claim of runtime, cloud or store activity. That is appropriate.

## Missing essential context and limitations

1. `docs/reviews/loading-progress-2026-09-27.md` and the highscore-starter and dialog review were not supplied. I cannot verify the "recorded evidence" in the Status line for the loading and dialog work.
2. **"iOS environment selection"** (`spec.md:178`) is described as owner-authorized, but it is not among the quoted follow-ups. The lead should confirm the source instruction or remove the wording.
3. I don't know whether a cost estimate was made before provisioning. This affects how R-02 is resolved.
4. I don't know whether the highscore-starter change's own review assessed Constitution IV. If it did, cite it in resolving R-01.
5. I did not recompute hashes, resolve links or inspect live services.

## Requested next step

Apply R-01, and fix or disposition R-02 and R-03 with reasons. Then refresh the manifest and validation and send a focused re-review packet with the prior verdict, these IDs and the lead's responses.
