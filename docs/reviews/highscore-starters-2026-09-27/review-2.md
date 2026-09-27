# Focused independent re-review: cartoon starter opponents, final 19-file candidate

**Role:** I am the independent reviewer (Claude Opus 5.5, `claude-opus-5-5`, requested effort `high`). I did not take part in the implementation or the remediation, and I have not launched another reviewer.

**Reviewed revision:** Base `4c191a6c8998c37b6765362b9b17c957fb8ae61f` plus the FINAL MANIFEST (19 files). This is the original 14 files plus 5 focused additions: `contracts/ios-flow.md`, `research.md`, `tasks.md`, `technical-proposal.md` and `src/tests/support/verify-two-installations.py`.

**Method:** Static review of the supplied numbered sources, the focused diff and the lead-reported evidence. I ran no commands, recomputed no hashes and re-executed no tests. I compared the manifest strings: all 14 original entries match byte-for-byte between the ORIGINAL and FINAL manifests, and the 5 additions are the only new paths.

## Verdict: **APPROVE**

The final 19-file candidate has no material unresolved findings. The first review's backend approval still applies, because the 14 reviewed file hashes are unchanged. The lead's reported 59/59 Azurite run was made against that same backend source and tests, so no rerun is needed. The five additions are correct and do not change product behaviour.

## Disposition of lead finding F2 (starter-only list satisfied the publication precondition)

**Valid; fixed correctly and sufficiently. Agreed.**

- **Defect:** Before the fix, `verify-two-installations.py:21` only required a non-empty `entries` list. After the starter change, a fresh container's GET returns 10 virtual starters with `revision: "empty"`. That list is trivially identical across an API restart. So the persistence check (`:28`) and the two-installation comparison (`:43`, `:49`) could pass without any stored document. That is a vacuous SC-006 / US1 two-installation pass.
- **Fix:** `expected['entries'] and expected['revision'] != 'empty'`. This restores the helper's original meaning, because the backend emits `empty` exactly when no blob exists (`BlobHighscoreStore.cs:58,76`). In the test-owned `dt3d-owned-*` container (`:13`), a blob can only come from a successful POST.
- **Ordering:** The assertion runs at `:21`, before `os.kill` at `:22`, so a failed precondition cannot restart the owner process.
- **Evidence:** The reported `runpy`/`unittest.mock` check covers both branches: the fresh 10-row `empty` list fails the assertion, and the persisted revision reaches the intercepted restart boundary. That is proportionate evidence for a helper precondition.
- **Unaffected paths:**
  - After the first app publishes into a fresh container, the persisted document holds 10 starters plus that entry. A zero score still qualifies below 100 rows.
  - The snapshot comparison covers `revision` and `entries` but not `fetchedAtUtc` (`:19`), so it stays stable across restarts.
  - The `assert` idiom and its behaviour under `python -O` predate this change and are not a new defect.

## Disposition of first-review L1 and L2

**L1 (iOS integration code not provided or rerun): narrowed, not closed. Non-blocking, must be reported.**

- The lead's search found and fixed the one real test-evidence gap (F2). This confirms that L1 was worth following up.
- I received the two-installations helper only. I did not see `HighscorePerformanceTests.swift` or `local-highscores.py`, so I rely on the lead's static search for those.
- **Specific residual to check by inspection, not a claimed defect:** T050 records "100 list/confirmed-submit visibility samples" against a fresh isolated container.
  - Before this change, 100 submissions into an empty list were all `ranked`.
  - Now 10 starters occupy slots, so only 90 submissions fill the list. If the synthetic runs use constant or non-increasing scores, submissions 91–100 would get `notQualified`.
  - That matters if a sample waits for a `ranked` highlight or a "Your result" row.
  - The lead should confirm statically that the harness uses increasing scores, fewer than 91 submissions, or treats `notQualified` as a valid visible sample. If not, record it as a known pending risk. This is a count-dependent behaviour rather than an explicit count assertion, so an "absolute count" search could miss it.
- The completion report must not claim the iOS integration, performance or two-installation suites pass or are unaffected by execution. They were not rerun.

**L2 (feature documents not provided): resolved for the supplied documents; residual for unsupplied ones.**

- `ios-flow.md:42`, `research.md:37`, `technical-proposal.md:51,57` and `tasks.md:115` accurately describe the implemented behaviour:
  - at least 10 rows and at most 100;
  - `BlobNotFound` presents a new list;
  - valid undersized lists are filled without replacing players;
  - GET is read-only, and the next new submission persists the fill under CAS;
  - corrupt, missing-container and unavailable storage still fail closed.
- Each owner update is dated 2026-09-27, so historical context is preserved (Constitution V).
- `ios-flow.md:42` correctly separates backend behaviour from the client's retained empty state, which injected fixtures still use (`:54` `empty`).
- `research.md:37` "next new submission persists" is exact. Below 100 rows every valid new ID qualifies and writes, while a same-ID replay does not write.
- Dated `validation.md` evidence unchanged: correct.
- **Residual:** I did not receive the root `README.md` or `docs/*`, which T052/T053 updated. In particular, `docs/production-smoke-and-rollback.md` could contain a smoke step that expects `entries: []` on a fresh deployment. Such a step would now fail or mislead during a later release. The lead should grep these and either confirm there is no present-tense empty-list claim or report them as unreconciled.
  - If any file is edited, the candidate changes and AGENTS.md requires a focused re-review of that doc-only delta.

**L3 (rank shift on deployment):** Agreed, unchanged. When DEV or PROD is deployed, existing players below 1,000 keep their rows and scores but rank below higher starters, and the first new POST persists the fill. State this plainly in the report.

**L4 (character names):** Unchanged and non-blocking. No release-rights conclusion is drawn from the names, and no action is required under this task.

## New findings

None material.

Optional, non-blocking notes (no re-review needed if left as they are):

- **Wording:** Completed-task wording in `tasks.md` T013 (`:64`, "GET empty/populated") and T019 (`:73`, "virtual empty only on BlobNotFound") still reflects the 2026-09-26 design, while T032 was annotated. Both are historical task descriptions and T019 remains technically accurate: `Fill(HighscoreDocument.Empty)` at `BlobHighscoreStore.cs:36`. Annotating them is optional.
- **Evidence record:** `tasks.md:7,298` point to `validation.md` as the evidence record, but the 2026-09-27 starter evidence (the 59-test Azurite run, local runtime check and helper mock check) is not in it. Record that dated evidence in the scoped review record or a dated validation addendum, so the T032 annotation has traceable evidence.

## Limitations of this review

- Static review only. All check results are the lead's reported evidence.
- There was no iOS build or test, no UI visual check, no rerun of the integration, performance or two-installation suites, and no remote deployment.
- I did not inspect `HighscorePerformanceTests.swift`, `local-highscores.py`, root `README.md`, `docs/*` or `validation.md`.

**Summary:** APPROVE the final 19-file candidate. F2 is a confirmed defect, correctly fixed and adequately evidenced. L1 is narrowed, with one specific T050 score-pattern item to confirm or report. L2 is resolved for the supplied documents, with `README.md` and `docs/*` still to grep. L3 and L4 carry into the completion report. The lead's explicit agreement completes consensus unless the residual greps lead to edits.
