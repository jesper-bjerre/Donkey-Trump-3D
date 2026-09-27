# Minimum-ten cartoon starters — 2026-09-27

## Task and final behaviour

The owner requested ten cartoon players with low scores and explicitly confirmed
**minimum ten entries, retaining top 100**. The backend now supplies deterministic
starters scoring 100–1,000 when a valid list has fewer than ten rows. Existing
player rows are retained; higher-scoring starters can move their displayed ranks.
All starters can eventually be displaced. Zero still qualifies below 100 entries.

GET remains read-only. A new player submission persists the virtual starter fill
in its normal conditional Blob write. Same-ID replay remains read-only. Missing
containers, corrupt documents and storage failures do not become starter lists.
The literal revision `empty` still means no persisted blob, not zero visible rows.

The local API on `http://127.0.0.1:5281` was rebuilt and restarted through its owned
helper, preserving its container. DEV/PROD were not deployed. No commit or push was
made. Unrelated Xcode/environment changes were preserved.

## Revision and participants

- Base commit: `4c191a6c8998c37b6765362b9b17c957fb8ae61f`.
- Final candidate: [19-file manifest](highscore-starters-2026-09-27/manifest.json).
- [Task-start hashes](highscore-starters-2026-09-27/before-manifest.json) and
  [task-scoped diff](highscore-starters-2026-09-27/task.diff) distinguish this work
  from pre-existing changes, including the quickstart's environment paragraph.
- First review covered [14 files](highscore-starters-2026-09-27/manifest-1.json);
  these hashes remained unchanged during the focused follow-up. Review records
  themselves are excluded from candidate identity.
- Governing instructions: [AGENTS.md](../../AGENTS.md),
  [constitution 1.0.0](../../.specify/memory/constitution.md), updated feature
  specification and HTTP/data contracts.

OpenAI Codex implemented the change; exact lead model ID and effective reasoning
were not exposed. Independent Anthropic review used Claude Code 2.1.283,
`claude-opus-5-5`, explicit `--effort high` and `CLAUDE_CODE_EFFORT_LEVEL=high`.
The reviewer did not implement changes. Tools/MCP were disabled, safe mode and
no session persistence enabled, and packets supplied from an isolated temporary
directory. Fresh authenticated text/JSON probes passed without effort-cap warnings.
Both reviews returned successful canonical model responses and nonzero first-party
usage. Effective effort is not independently attested by provider metadata.
See [sanitized configuration and session evidence](highscore-starters-2026-09-27/metadata.json).

## Checks and dispositions

- `HighscoresTests__UseAzurite=true ~/.dotnet/dotnet test src/backend.tests -c Release`:
  **59 passed, 0 failed, 0 skipped**, including actual Azurite conditional-write
  races, 100 writers, restart/replay, zero-score submission and seed preservation.
- Debug backend build: zero errors or warnings.
- [Local runtime](highscore-starters-2026-09-27/local-evidence.json): health and GET
  200; zero prior rows became ten, points 100–1,000, same container, no test POST to
  the owner's running list.
- OpenAPI parsed and examples checked for 10–100 entries, unique identities,
  contiguous ranks and descending scores. Changed links and whitespace checks passed.
- The two-installation helper's precondition was exercised through isolated mocks:
  ten virtual starters with revision `empty` must stop before process restart;
  persisted revision reaches the intercepted restart boundary. Both passed.

Full command details and scope limits: [checks](highscore-starters-2026-09-27/checks.txt).

| Item | Disposition |
|---|---|
| Initial backend review | [APPROVE](highscore-starters-2026-09-27/review-1.md), no material source findings. |
| F2, lead-confirmed test-evidence defect after following up L1 | Nonempty starter rows could falsely satisfy the two-installation publication precondition. Added the existing storage-revision check, verified both branches, and obtained explicit agreement that the fix is sufficient. |
| Stale current design prose, L2 | Updated research, proposal, iOS flow and affected task wording. Historical validation/reviews retained. |
| Focused final review | [APPROVE](highscore-starters-2026-09-27/review-2.md), no unresolved material findings. |

The lead also checked the non-blocking residual questions after approval: the
performance harness uses increasing scores `2_000_000_000 + i * 100`, so all 100
fresh-container submissions can displace low-scoring starters. Searches of the
root README and active deployment/release/environment guides found no remaining
instruction to expect an empty successful ranking. These are static lead checks,
not an executed iOS integration run; they required no further source changes.

## Consensus and limitations

Reviewer: **APPROVE** the final candidate, F2 correctly resolved. Lead: **agree**;
minimum-ten behaviour, preserved ranking/concurrency and required checks satisfy
the authorized task. Final manifest verification passed. No important findings or
disagreements remain.

The iOS client model was inspected for compatibility, but iOS integration,
performance and two-installation suites were not rerun. No physical-device or
visual acceptance, signed archive, cloud deployment or release-rights assessment
is claimed. The change is running locally; later DEV/PROD deployment will also
make higher-scoring starters appear above existing lower-scoring players.
