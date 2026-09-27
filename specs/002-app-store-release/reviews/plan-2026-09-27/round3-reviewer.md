# Independent focused re-review, round 3: specs/002-app-store-release plan

**Reviewer:** Anthropic Opus 5.5 (`claude-opus-5-5`), independent of the authoring vendor (OpenAI Codex). I used no tools and launched no sub-review. I assessed the numbered final text and `round3.diff` as supplied and did not recompute hashes.

**Scope:** the F-07 remediation, suggestions S-1 to S-3, and regressions introduced by the round-2 → round-3 diff. F-01 to F-06 stay resolved as stated in round 2; nothing in this diff reopens them.

## Verdict: APPROVE

F-07 is resolved using option (a). S-1, S-2 and S-3 are addressed. I found no new material regression. Three wording notes below are non-blocking and do not need another review round.

## F-07 (MEDIUM): Resolved

Each part of the required resolution is present:

| Requirement | Where it is met |
|---|---|
| Every tombstoning transaction closes all unresolved reports on all removed entries atomically | `moderation-api.md:110-113`, `data-model.md:58-59`. Covers direct remove, resolve/remove and remove-and-block, including a blocked producer's other ranked rows. One conditional write, "never a later best-effort loop". |
| Truthful disposition for each snapshot | `moderation-api.md:114-116`, `data-model.md:60-61`. Legacy and starter origins map to `legacyRemoved`/`starterRemoved`. `removedAndBlocked` is used only if the snapshot producer is blocked in the final state, otherwise `removed`. No-action and spam affect only the selected reports. |
| Closed receipts and real acknowledgements preserved | `moderation-api.md:117-119`, `data-model.md:61-63`. Closed receipts are immutable, and `acknowledgedAtUtc` is never invented. |
| Existing tombstones supported | `moderation-api.md:119-120`, `data-model.md:63-64`. Tombstones are idempotent, and a still-open report can close without its row being ranked. |
| Capacity handled | `moderation-api.md:121-122`. All 100 unresolved reports can transition. This mutates existing records, allocates no new report slots and uses the 64 KiB reserve. That is plausible: 100 × (disposition + time + operation ID) is well under the reserve. |
| Owner triage is practical | `moderation-api.md:89-91`. `list` is grouped by entry ID with counts, shown in the private owner console only. |
| Checks planned | `quickstart.md:79-82`. Covers multiple reporters, a producer's other rows, pending capacity, ETag conflicts and already-tombstoned targets. |

**Cross-checks:**
- **The race is well defined.** A report and a removal on the same entry are serialized by the ETag. If the report commits first, the removal closes it. If the removal commits first, the report gets `404 entry_not_found`, because tombstoned IDs never appear in the ranking projection (`moderation-api.md:27-28`). Both outcomes are honest.
- **Resolving an auto-closed report is well defined.** Running `resolve` on a report that was already closed automatically now returns `409 report_resolved` (`moderation-api.md:97-99`). The ambiguity from round 2 is removed.
- **Evicted rows are still covered.** A block tombstones only currently ranked rows. Reports on a blocked producer's evicted rows therefore stay pending. If they are later resolved with `remove`, the "blocked in final state" rule gives a truthful `removedAndBlocked`. This is consistent.

## Suggestions

- **S-1: Addressed.** `plan.md:56` now names app MI inside App Service for Blob access and human Entra only for control-plane SSH.
- **S-2: Addressed.** `plan.md:117-120` moves the probe into step 1. A missing MI context blocks operator-dependent work, with no token or environment extraction and no human Blob fallback.
- **S-3: Addressed.** `moderation-api.md:44` adds `503 service_maintenance`, meaning a definite no-write with no deferred retry. It is correctly separated from the unconfirmed codes.

## Non-blocking notes

1. **`moderation-api.md:120`:** "can be closed as removed" could be misread as a literal `removed` disposition for legacy, starter or blocked-producer snapshots. The per-snapshot rule just above it (lines 114-116) governs. When writing tasks, read it as "closed with its per-snapshot disposition".
2. **`plan.md:117-118`:** the step-1 probe comes before the operator mode exists in any deployed DLL, and the probe tool is not named. Tasks should specify:
   - a read-only mechanism that uses the app MI inside the container and prints no token or environment values; or
   - that the first conclusive probe happens at the first DEV deployment containing the read-only `list` or metadata command.

   Either choice is still earlier than step 4, and the blocked outcome is already defined.
3. **`data-model.md:49`:** the transition line still reads `pending → acknowledged → resolved` as if linear. Lines 62-63 now allow resolution without acknowledgement, and `dismissedSpam` also closes from pending. Tasks should follow the later, more specific text.

## Limitations

- These are the same limitations as round 2. Review was text-only. I did not verify Apple or Microsoft pages, including App Service SSH environment and MI availability in SSH sessions. I did not verify Azure state beyond `storage-properties.json`, or any Connect state.
- I did not see 001 contracts, the iOS sources or the backend sources beyond the prior citations.
- Hashes were taken as supplied.
- This verdict covers plan and design acceptance only. No implementation, runtime check, deployment or store action is claimed or required for it. Future execution gates (Chrome access, signing, owner facts, physical iPhone 13, PROD Always On, MI role scope) remain gates, not verified facts.

**Consensus:** Once the lead explicitly agrees, review of this Phase 0/1 plan revision is complete. F-01 to F-07 are resolved, and the notes above are non-blocking.
