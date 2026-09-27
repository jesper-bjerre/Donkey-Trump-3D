# Focused re-review: speckit-clarify, `specs/002-app-store-release`

**Role:** Independent Anthropic reviewer (Claude Opus 5.5). I am not the author. This review is read-only, used no tools, and launches no further reviewer.
**Reviewed candidate:**
- `spec.md` after-hash `4c0c8324…d8e5`.
- Checklist `112e887c…6695`, unchanged from round 1.
- Base commit `05238815…9094`, with the supplied `task.diff` and `validation.json` (`ee082de0…1700`).

I did not recompute hashes, resolve links or inspect live services.

## Verdict

**APPROVE.** R-01, R-02 and R-03 are resolved. There are no new material findings.

- Zero questions asked or answered is correct.
- All prior owner answers and follow-ups are preserved.
- Checklist 16/16 and all taxonomy categories Clear are now supported.
- The specification is ready for `speckit-plan`.
- This approval covers the specification only. It does not cover release readiness, runtime privacy or billing.

## Finding dispositions

### R-01 (HIGH): Resolved

- **Where the explanation lives:**
  - FR-026 (`spec.md:147`) now requires the in-app privacy/help copy to explain that a submitted name and score appear on the public list.
  - SC-010 (`spec.md:171`) makes this an acceptance check, alongside explicit Submit.
- **Existing source already complies:**
  - `Copy.swift:21` reads: "If you choose to submit a highscore, your chosen name and score are public."
  - `RootView.swift:207` renders this text in `HowToPlayView`.
- **Constitution IV is met:**
  - `constitution.md:60` requires an explicit action plus an explanation of what is public. It does not prescribe where the explanation appears.
  - The owner's instruction to remove the dialog text is authoritative (`constitution.md:141`).
  - The dialog review record (`highscore-name-dialog-2026-09-27.md:7`) reached the same conclusion.
  - There is no constitution conflict, so no CRITICAL escalation is needed.
- **Limitation:** I saw the `HowToPlayView` definition but not its presentation site in RootView. The spec does not depend on this: if the view is unreachable, SC-010 fails at release acceptance.

### R-02 (MEDIUM): Resolved

- **Already-deployed resources:** FR-012 (`spec.md:133`) now requires three things before draft readiness:
  - verifying the recorded assumptions and the additional-cost estimate;
  - recording the committed plan-cost baseline;
  - treating the linked notes as dated inputs, not an automatic pass.
- **Further provisioning:** still needs its own estimate first.
- **The linked notes contain what FR-012 refers to** (`backend-deployment.md:156–169`):
  - an assumption of 1,000 GETs and 100 POSTs per day;
  - an estimate of about DKK 0.25 per month including VAT, from 2026-09-26 list prices;
  - a tagged DKK 80 + VAT budget.
- **The baseline gap is handled:** the notes give no committed plan-cost figure (only "existing plan charges are separate"). FR-012 correctly makes recording it a draft-readiness gate.
- **Consistency:** the edge case (`spec.md:110`) and SC-007 (`spec.md:168`) agree with this. The `#capacity-and-cost` anchor matches the heading at line 143.

### R-03 (MEDIUM): Resolved

- US2-6, FR-026 and SC-010 now say "at least ten ranked entries in the list" and "fewer than ten real (ranked) results".
- "Visible" and "players" are gone.
- Assumption `spec.md:181` ("cartoon-seeded highscore entries") is consistent.
- The words "cartoon players" in the starter review record are historical owner wording, not spec text.

## Round-1 missing-context items

| # | Item | Status |
|---|---|---|
| 1 | Loading, dialog and starter evidence | Supplied. These records, plus the environment record, support the Status line's "recorded evidence". `menu-music-2026-09-27.md` and `backend-release-2026-09-27.md` were not supplied. The spec cites them only as dated evidence with live refresh required, so this is not material. |
| 2 | iOS environment selection | Resolved. The owner's quoted instruction and `ios-backend-environments-2026-09-27.md` support `spec.md:178`. |
| 3 | Cost estimate existence | Resolved under R-02. |
| 4 | Earlier Constitution IV assessment | The dialog review addressed it. |

## Non-blocking observations

- **N-1 (planning input):** FR-014 and FR-015 may add installation-scoped blocking data. If so, `Copy.privacy` ("No accounts or tracking… stay on this iPhone") must be rechecked against the actual data flows (Constitution IV, FR-007/008). The word "existing" in FR-026 should not be read as freezing that copy.
- **N-2 (carried over):** The checklist traceability notes (`requirements.md:36,39`) do not list FR-025, FR-026, SC-009 or SC-010. The final report should say so rather than edit non-checkbox content.

## Limitations

- My evidence is the supplied source, excerpts and attributed records only.
- The historical 2026-09-27 evidence is not newly repeated live checks.
- No physical-device, distribution-candidate or App Store evidence exists or is claimed.
