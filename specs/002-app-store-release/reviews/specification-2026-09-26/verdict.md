# Independent Specification Review: 002-app-store-release

**Reviewer:** Claude Code 2.1.283, `claude-opus-5-5`, high effort, read-only. Tools and MCP were disabled. This is my own assessment of the packet; I did not launch another reviewer.
**Candidate:** base `e323551c…`, candidate digest `f97ec290…`, the four files in the manifest.
**Verdict:** **Changes requested.** There are two MEDIUM findings, each fixable with a one- or two-sentence edit. Everything else is sound and ready for planning. After those edits, a focused re-review of FR-002, FR-006 and FR-016 is enough.

## What I verified as sound

- **Owner boundary.**
  - FR-020, FR-021, US4 and SC-006 stop at an unsent draft created by Add for Review. Manual release is selected.
  - The agent never uses Submit for Review, publication, or rejection handling. Pending Developer Release is correctly not a completion gate (source-notes line 35).
  - This matches the Apple submit-an-app and release-option excerpts.
- **iPhone only.**
  - The source notes correctly record `TARGETED_DEVICE_FAMILY = "1,2"`. FR-002 excludes native iPad and gates narrowing on distribution history.
  - The screenshot rules match the excerpt: 6.9″ or 6.5″ set required, iPad set not required, and iPhone 13 at 2532×1170 not assumed to cover a larger-display slot.
- **Free, eligible territories.** FR-010 requires a recorded reason for each excluded territory and does not infer DSA trader status from the free price.
- **No invented facts or premature claims.**
  - Status line 9, Assumptions 156 and 159, and source-notes line 44 keep the specification separate from execution.
  - The failed Chrome initialization is described accurately and not misread as a missing login.
  - The five-screenshot count and the moderation target are labelled as project choices.
- **Constitution.**
  - Physical iPhone 13 evidence is a readiness gate (FR-016, SC-003).
  - The spec requires real supplied values for resources, ownership and contacts (FR-012, US3-4).
  - Content stays English, and no accounts, tracking or ads are added.
  - Shared-data integrity for removals is preserved (FR-015).
- **Scope expansion.** The UGC safeguards (FR-014, FR-015) are a justified, explicitly declared delta. The game already publishes player-chosen names, and Guideline 1.2 is conservatively applied. Accounts and chat stay excluded.
- **Traceability.** The checklist note maps all 23 FRs and all 7 SCs to stories. Every acceptance scenario has a testable outcome.

## Findings

### R-001 — MEDIUM — The iPhone-only release has no gate for iPad compatibility mode

- **Where:** `spec.md` lines 108 (FR-002) and 122 (FR-016); edge cases lines 92–101.
- **Problem:**
  - FR-002 only requires that "any compatibility behavior imposed by Apple MUST be documented".
  - No requirement or scenario checks that the candidate actually works when an iPhone-only app runs on iPad.
  - All device evidence in FR-016 is iPhone 13.
- **Why it matters:**
  - Apple normally makes iPhone-only apps available on iPad in compatibility mode.
  - Guideline 2.4.1 says iPhone apps should run on iPad whenever possible, and App Review commonly exercises them there.
  - The game is landscape-only, uses split-screen touch zones, and adds new report and privacy screens. A crash, clipped layout or unreachable control would be a likely rejection cause.
  - US2 scenario 5 blocks readiness on an "unresolved material release defect", but no gate would ever look for this one. The draft could be marked ready despite a predictable rejection path.
- **Evidence:** Constitution Product Boundaries requires iPad to have its own evidence before claims are made. Guideline 2.4.1 comes from my own knowledge, not the provided excerpts, so the lead should confirm it against the live guidelines page.
- **Suggested fix:** Add to FR-002 or FR-016 a requirement that the selected candidate is smoke-checked in iPad compatibility mode:
  - launch
  - landscape presentation
  - reachable touch controls
  - highscore, report and privacy flows

  Label the evidence by environment. A simulator is acceptable if it is labelled as such, and it must not be presented as native iPad support or physical-device evidence. A failure blocks readiness. Optionally, add an edge case for it.

### R-002 — MEDIUM — The rights and content assessment leaves out in-game text, real people, and resemblance to the original game

- **Where:**
  - `spec.md` line 112 (FR-006) lists only "name, icon, models, audio and marketing content".
  - It feeds FR-009 (line 115, content-rights declaration) and US1 scenario 4 (line 28).
- **Problem:** The shipped content in `Copy.swift` includes several items outside that list:
  - the character name "Jumpman Løkke" (`cardGoal`)
  - real politicians' names (Trump in the app name; Løkke and Motzfeldt in game copy)
  - White House framing (`orderSeal`)
  - gameplay and structure closely modelled on Donkey Kong: barrels, slanted girders, ladders, rescue at the top
- **Why it matters:**
  - "Jumpman" is associated with Nintendo's original Donkey Kong protagonist. To my knowledge it is also a registered Jordan/Nike brand mark; this needs verification.
  - Depicting real public figures raises Guideline 1.1.1 (satire of targeted individuals) and publicity-rights questions.
  - The overall resemblance raises Guidelines 4.1 (copycats) and 5.2.
  - As written, an implementation could complete FR-006 and attest the Connect content-rights declaration without assessing the content most likely to draw a 5.2, 4.1 or 1.1.1 rejection. That is a gap in the evidence basis FR-009 requires.
- **Evidence:** The 5.2 excerpt in the packet, constitution IV, and `Copy.swift`. My references to 1.1.1, 4.1 and the Jumpman mark come from reviewer knowledge and should be verified against the live guidelines.
- **Suggested fix:** Extend FR-006 to cover:
  - in-game text and character names
  - names or depictions of real public figures
  - overall resemblance of gameplay and presentation to the referenced game

  The results should feed the FR-009 declaration. An unresolved risk follows the existing edge case on line 101: an explicit product decision, not a silent rename.

## Non-blocking notes (no re-review needed)

- **N-1:** FR-014's response target of at most one working day is an operational commitment for the owner. The plan should record the owner's acceptance of it, and of who the responsible operator is, as an execution input.
- **N-2:** If abuse prevention keeps any identifier, the in-app strings `Copy.accountFree` ("No tracking") and `Copy.privacy` must be updated to match. Constitution IV already requires this; the plan should list it under FR-015.
- **N-3:** Installing the "exact distribution candidate" on a physical iPhone (US2) in practice means TestFlight internal testing, which has an export-compliance precondition. The plan should state this explicitly.

## Limitations

- I inspected only the packet. I did not see the README, the runbook, `validation.md`, `docs/prd_spec.md` or the full `project.pbxproj`.
- Apple claims beyond the provided excerpts (2.4.1, 1.1.1, 4.1, the status of the Jumpman mark) come from my knowledge and are flagged for verification.
- I did not verify any Connect account state, consistent with the recorded failure to initialize Chrome.
