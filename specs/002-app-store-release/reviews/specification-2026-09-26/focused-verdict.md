# Focused Independent Re-Review: 002-app-store-release (specification only)

**Reviewer role:** Independent re-reviewer. I did not author this spec. Tools and MCP were disabled, and I did not launch another reviewer. My own statement of model or effort is not verification; the lead must record the provider and session metadata for this round.

**Reviewed revision:** base `e323551c…`, final candidate digest `d6af6814…`. I compared the final manifest with the initial one: only `spec.md` (`49f951fa…`) and `source-notes.md` (`ec6ff6a7…`) changed. `.specify/feature.json` and `checklists/requirements.md` are byte-identical by recorded hash.

**Verdict: Approved.** No material findings remain. I agree the specification is ready for planning.

## Disposition of prior findings

### R-001: iPad compatibility-mode gate. **Resolved.**

- **FR-016** (`spec.md:123`) now requires a smoke check of the selected iPhone candidate in iPad compatibility mode.
  - It covers launch, landscape presentation, reachable touch controls, and the highscore, report and privacy flows.
  - A failure blocks readiness.
  - Evidence from a clearly identified simulator is enough, and it must not be presented as native iPad support or physical-device evidence.
  - This is the fix I proposed, including the report and privacy screens added by FR-007 and FR-014.
- **Edge case** (`spec.md:94`) matches it and correctly treats a failure as a readiness defect even though native iPad is out of scope.
- **Consistency with FR-002** (`spec.md:109`):
  - FR-002 still excludes native iPad support, iPad-specific assets and iPad claims.
  - Its "document, don't present as validated native iPad support" wording fits FR-016's labeled gate.
  - The confirmed iPhone-only scope is not widened.
- **Constitution fit:**
  - Product Boundaries requires iPad evidence before any iPad readiness claim. None is made.
  - Principle V forbids passing off simulator results as physical evidence. FR-016 forbids this explicitly.
  - Accepting simulator evidence is proportionate because the claim is limited to "does not break in compatibility mode," not iPad touch usability.
- **Traceability:** US2 already covers FR-016, and US2 scenario 5 ("unresolved material release defect") now has a gate that actually detects this defect. The checklist traceability line stays accurate.

### R-002: Scope of the rights and content assessment. **Resolved.**

- **FR-006** (`spec.md:113`) now covers the full shipped experience:
  - app and character names
  - in-game text
  - names or depictions of real public figures
  - icon, models, audio and marketing
  - overall gameplay and presentation resemblance to the reference game

  It adds "content suitability," so the 1.1.1 concern is included and not only intellectual property.
- The assessment must support FR-009's declarations, which closes the gap where the content-rights attestation could be made on a partial basis.
- An unresolved material issue calls for an explicit product decision, "not a silent rename or an unsupported legal conclusion." This is consistent with the edge case at `spec.md:102` and Assumption `spec.md:156`.
- **Source notes** (`source-notes.md:38`):
  - They describe 2.4.1, 4.1 and 1.1.1 in terms consistent with my understanding of the guidelines, including that the satire exception is qualified, not automatic.
  - They correctly state that no infringement is claimed and no exemption is assumed.
  - Not adopting my "Jumpman" registered-trademark remark is right. I flagged it as unverified reviewer knowledge, and FR-006 does not depend on it: character names are assessed either way.

## Rest of the specification

- **Owner boundary:** unchanged. FR-020, FR-021, US4 and SC-006 still stop at an unsent, validated draft with manual release selected, and the owner performs Submit for Review and the public release.
- **Confirmed scope:** iPhone-only, free in all eligible territories, and English are unchanged. No accounts, tracking or ads are introduced.
- **Counts:** 23 FR IDs (FR-001 to FR-023) and 7 SC IDs (SC-001 to SC-007) are present and unique. The checklist note stays accurate.
- **Quality checklist:** all 16 criteria still hold. The new text adds testable gates without implementation detail. The Apple guideline references stay in source notes, not as spec architecture.
- **Earlier conclusions:** the edits do not affect anything else I verified in the prior round.

## Non-blocking notes (no re-review or owner adjudication needed)

- **N1–N3 (carried over), agreed as plan and execution inputs:**
  - N1: the named operator and their acceptance of the one-working-day response target.
  - N2: privacy copy (`Copy.accountFree`, `Copy.privacy`) must reflect any moderation data, under constitution IV, FR-008 and FR-015.
  - N3: installing the candidate requires signing, TestFlight and export-compliance inputs.
- **N4 (new, optional):**
  - FR-016 states the compatibility check unconditionally, while the edge case says "can run in iPad compatibility mode."
  - If the plan ever restricts device capabilities so the app is not offered on iPad, the plan should record that and mark the check not applicable, with its evidence.
  - The US2 independent test and SC-003 do not name the compatibility check. The task list should trace it explicitly, since requirement-ID coverage alone does not prove scenario coverage. This is a planning note, not a spec defect.

## Limitations

- I did not recompute SHA-256 hashes or rerun the lead's document checks (links, whitespace, ID counts). I rely on the attributed results and my own reading of the numbered final files.
- I could not open the live Apple guidelines page. My agreement with the 2.4.1, 4.1 and 1.1.1 summaries is based on my own knowledge plus the lead's reported live check.
- I did not inspect code, Connect state or runtime evidence. None is claimed or needed for this specification-only review.

## Consensus statement

Both findings are resolved without weakening the confirmed scope or the constitution. I explicitly **approve the final specification** (candidate digest `d6af6814…`) for planning. N1–N4 are non-blocking. With the lead's stated agreement, consensus is reached, and no further review round is needed for this specification.
