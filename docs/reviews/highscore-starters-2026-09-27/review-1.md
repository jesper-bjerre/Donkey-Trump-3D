# Independent review: cartoon starter opponents (minimum 10, top 100 kept)

**Role:** Required Anthropic reviewer (Claude Opus 5.5, `claude-opus-5-5`). I did not take part in the implementation, and I have not launched another reviewer.

**Reviewed revision:** Base `4c191a6c8998c37b6765362b9b17c957fb8ae61f`, plus the frozen candidate manifest in the packet (14 files, including the untracked `HighscoreStarters.cs` and `HighscoreStarterTests.cs`).

**Method:** Static review of the numbered sources, diff and lead-reported evidence in the packet. I ran no commands, did not recompute hashes, and did not re-execute tests. All test and runtime results below are the lead's reported evidence.

## Verdict: **APPROVE**

I found no material, actionable defects in the backend change, tests or updated contract/docs. The limitations listed below should be reflected in the completion report, but none of them blocks this candidate.

## Acceptance trace

| Criterion | Evidence | Result |
|---|---|---|
| Fresh or valid undersized lists get at least 10 cartoon starters | `HighscoreStarters.cs:18-30`. If `k` starter IDs are already occupied, they are among the `c` existing rows, so at least `10−k ≥ 10−c` names remain and the loop always reaches 10. | Met |
| Existing real rows untouched; earlier equal scores keep precedence | Only new rows are appended. Starter sequences start at `NextSequence`, so they sort after any existing equal score (`:20,28,33`). Covered by the test at `HighscoreStarterTests.cs:23-35`. | Met |
| Scores 100–1000, deterministic IDs, no duplicate starters | `(10−i)*100`, `d7c30000-…-{i+1:D12}`, and a skip on existing IDs (`:23-24`). After the first persisted write, the count is at least 11 and never decreases (`HighscoreRanking.cs:17,24`), so `Fill` becomes a no-op. | Met |
| Ordering, ties, top 100 and CAS unchanged | `Evaluate` is unchanged. `Fill` is deterministic for a given ETag, so racing writers compute identical fills. The losing writer rereads and sees the persisted starters (`BlobHighscoreStore.cs:73-94`). Two-writer tests cover both the fresh and existing cases. | Met |
| All starters can be displaced; a zero score qualifies below 100 rows | There is no replenishment once the count is at least 10 (`HighscoreStarterTests.cs:48-57`). `count < 100` accepts 0. | Met |
| GET is read-only; corrupt or unavailable storage is not repaired or faked | `Fill` calls `Validate()` first (`:17`). A missing container or auth failure still throws before `Fill`. `CorruptReadNeverBecomesAStarterList` and the smoke test assert the blob is absent after GET. | Met |
| A new POST persists the virtual fill via normal CAS; same-ID replay does not write | `decision.Document` includes the fill and is written with `If-Match`/`If-None-Match:*`. Replay returns `RequiresWrite=false` on the filled snapshot. | Met |
| Contract `minItems: 10` holds for every 200 response | GET is at least 10 after `Fill`. Ranked POST is at least 11. Replay is at least 10. `notQualified` only occurs at 100. | Met |
| iOS client compatibility | `HighscoreModels.swift:58-80` accepts 10–100 rows and treats revision as opaque. `qualifies` still depends only on `count < 100`. Starter names pass `HighscoreRules.name`. | Met (static) |

Other checks with no issues:
- Overflow near `long.MaxValue` still maps to `storage_invalid`.
- `HighscoreFailure` from `Fill` inside `SubmitAsync` happens while `uncertainWrite` is false, so it is not misreported as unconfirmed.
- Revision semantics (`empty` means no blob yet; an ETag otherwise, including for a virtually filled legacy document) are consistent across the code, README, data model and OpenAPI.

## Findings

None material.

## Missing context and limitations (non-blocking; report them accurately)

- **L1: iOS integration code not provided or rerun.** I did not receive the Debug-integration and performance XCUITests, `local-highscores.py` or `verify-two-installations.py`, and the lead did not run them. These consume the real local API. If any of them asserts a fresh list is empty, or checks absolute ranks or row counts after N synthetic POSTs, it would now fail. This is uncertainty, not an observed defect.
  - Recommended: grep those sources for empty-list or rank/count assumptions.
  - Do not claim the iOS integration suite is unaffected until that is checked.
- **L2: Some feature documents not provided.** I did not see `validation.md`, `tasks.md`, `contracts/ios-flow.md`, `research.md`, `technical-proposal.md` or `docs/*`. They may still describe a fresh list as `entries: []` or a real-only list.
  - Dated historical evidence in `validation.md` may stay as it is (Constitution V).
  - Present-tense behaviour statements elsewhere should be grepped and reconciled if found.
- **L3: Rank shift on deployment (expected, worth stating).** When DEV or PROD is deployed later, existing real players scoring below 1,000 keep their rows and scores unchanged. However, they will rank below higher-scoring starters. The first new POST will then persist the starters. This matches the owner's request; just state it plainly in the completion report.
- **L4: Trademarked character names (release consideration, not a code defect).** Names such as Bugs Bunny, Garfield and Snoopy are third-party trademarked characters shown in the app. Constitution IV governs assets, not names, and the owner asked for cartoon names, so this does not block. It may be worth noting it as a release/App Review consideration alongside the existing parody/no-affiliation copy.

Optional and cosmetic: `RankedResult.entries` `minItems: 1` is now redundant because `Entries` requires at least 10. It is harmless.

**Summary:** APPROVE. There are no findings requiring changes, and the lead's agreement completes consensus under `AGENTS.md`. Limitations L1–L4 should appear in the final report, and "iOS integration unaffected" must not be claimed as verified.
