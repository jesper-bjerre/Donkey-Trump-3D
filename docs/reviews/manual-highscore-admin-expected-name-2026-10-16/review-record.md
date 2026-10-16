# Mandatory current-name guard for manual highscore rename

## Task and scope

The owner requested that a manual rename specify the existing value because new
highscores may have changed the ranking. Rename now requires both a stable entry
UUID and `--expected-name`. The name must match case-sensitively after normal NFC
normalization and trimming. Missing/invalid expected names fail argument validation;
a stale name returns 409 `entry_changed`, including before an otherwise matching
new-name no-op. The match is repeated inside the conditional mutation.

This is an incremental implementation follow-up to the already installed manual
operator tool. No HTTP endpoint, iOS change, storage schema change, new permission,
live HTTP deployment or highscore write was performed. The prior correction and
manual-tool review records retain their original identities and verdicts.

Governing documents: [AGENTS.md](../../../AGENTS.md),
[constitution v1.0.0](../../../.specify/memory/constitution.md),
[operator contract](../../../specs/002-app-store-release/contracts/moderation-api.md)
and the owner's manual-only PROD scope. Tests were not authorized and were not run.

## Participants and verified route

| Role | Tool/vendor/model | Reasoning and independence |
|---|---|---|
| Implementer | Codex / OpenAI / GPT-6, as exposed by this session; finer model ID unavailable | Runtime reasoning setting unavailable |
| Reviewer | Claude Code 2.1.296 / Anthropic firstParty / `claude-opus-5-5` | Explicit `--effort high` and `CLAUDE_CODE_EFFORT_LEVEL=high`; no implementation participation |

The CLI version/help were inspected. Harmless text and stream-json probes both
returned `REVIEW_ROUTE_OK` with exit 0 and empty stderr; no effort-cap warning was
observed. Stream provider usage and an actual assistant message identified the
canonical model. Probe session: `fdc0710a-bbb5-4f38-861d-a9416d97d2e4`.
See [configuration evidence](review-configuration.json).

The review used the same configuration from an isolated temporary directory,
safe mode, tools/MCP disabled, no session persistence, and explicit UTF-8 stdin.
Actual assistant messages and nonzero firstParty usage again identified
`claude-opus-5-5`. Review session: `dfd4109c-44ef-49a2-a5ce-bde5e0b60f58`.
See [sanitized result metadata](review-result.json). Effective effort is not
separately provider-attested; evidence is the explicit settings and successful
warning-free probes. The primary route worked; no fallback was used.

## Frozen review inputs

- Git base: `368d7001b90ade026efcc71b4b057683eaa4ffaa`.
- Incremental base: the captured pre-edit uncommitted worktree, including relevant
  untracked files, preserved in [before/](before/). These are not files claimed to
  have existed in the committed base.
- Seven changed files and exact before/candidate SHA-256 identities:
  [manifest](manifest.json).
- [Incremental before/after diff](incremental.diff) and
  [tracked diff against HEAD](tracked.diff). Full candidate contents, including
  untracked source/tests/wrapper/guide, were included in the review packet.
- The packet also included governing instructions/constitution, relevant unchanged
  validation/store/model/starter/interface/installer/project sources, actual build
  and publish output, and attributed live acceptance evidence. Packet SHA-256:
  `be8f350e82f379e4b9bb94b7083a91a4534065024221489e72d04d9b5a4f5dc9`.
- The source stayed unchanged during review. Final manifest comparison passed.
  Record-only additions and the derived screenshot crop do not change the reviewed
  candidate. Historical review records were not rewritten.

## Findings and agreed dispositions

The reviewer returned **APPROVE**, with no material unresolved finding and two
explicitly non-blocking advisories. The lead agrees with that verdict and their
non-blocking disposition. No source remediation or ceremonial second round was
required.

| ID | Severity | Evidence and disposition |
|---|---|---|
| R1 | Low, optional | The existing parser rejects values beginning with `--`. An existing such name remains correctable by prefixing a space in the argument; normal name trimming removes that space before comparison. Fails closed. No required change. |
| R2 | Low, optional/conditional | Console JSON may escape a name's Unicode characters. The operator must use the decoded name, or bash Unicode escapes, rather than copying JSON escape characters literally. A mismatch fails closed. No required change. |

The [unaltered reviewer verdict](reviewer-verdict.md) records the review's actual
limitations. The reviewer approved source and did not independently attest a
production binary. The lead subsequently recorded the direct build/publish/transfer
hash chain in [binary provenance](binary-provenance.json): built, published and
installed DLL hashes match, and the source manifest remained unchanged. This is
lead-observed provenance, not an additional independent binary review.

The reviewer did not receive several unchanged helper definitions. Subsequent lead
inspection confirmed `ModerationRetention.Purge` changes only reports/audit/spam
receipts (`ModerationReport.cs:48`), `HighscoreFailure` preserves status/code
(`HighscoreContracts.cs:25`), and `HighscoreJson` uses the default encoder
(`HighscoreContracts.cs:41`), consistent with the safe-failure advisory R2.

## Checks actually run

| Check | Result and limits |
|---|---|
| SDK setup | A previous temporary SDK path no longer existed, so the initial invocation did not build anything. Microsoft SDK 10.0.401 was then installed in the task's temporary directory. |
| `dotnet build src/backend.tests -c Release --nologo -p:UseAppHost=false` with SDK 10.0.401 | Succeeded, 0 warnings/errors. Backend and test code compiled; no tests executed. [Output](build.txt). |
| `dotnet publish src/backend -c Release --no-restore --nologo -p:UseAppHost=false -o TEMP/publish` | Succeeded. [Output](publish.txt); [binary identity](binary-provenance.json). |
| `git diff --check` | Exit 0. |
| Changed documentation's relative file links | All referenced local files exist; anchors/external sites were not runtime-tested. |
| `bash -n` on wrapper and existing installer | Succeeded inside PROD before installation. Syntax checking only. |
| Manual PROD installation | Installed immutable revision `60b5c449f15ea66246e5ed4b904ebd1ad786969871356f22986255a49366efaf` and switched only `/home/site/tools/highscore-admin/current`. Previous revision retained. Temporary transfer files removed. |
| Actual read-only manual preview | Known UUID with matching expected/current name returned exit 0, `preview:true`, `changed:false`, score 4000, current rank 7. No `--apply`; no highscore write. [Evidence](live-acceptance.json), [screenshot](manual-preview.png). |
| Live HTTP assembly before/after | Unchanged SHA-256 `d2c2eb54e354f5d01cdc03b1712a7b66ab239e0756937b9484b77491414d18b7`. No HTTP restart/deployment. |
| Unit/integration/UI/end-to-end/smoke tests | **Not run**, as required by the owner's policy without an explicit request. |

New assertions cover missing expected-name, case-sensitive/canonical comparison,
stale-name rejection before preview/no-op, the mutation-time recheck and correction
of a prohibited old name. They were compiled only. Runtime mismatch, apply,
concurrency and lost-acknowledgement cases were not exercised in this follow-up;
their behavior was source-inspected, not claimed as an executed pass.

## Final verdict

**Consensus reached.** The independent reviewer approves the unchanged candidate;
the lead explicitly agrees. No important finding or review disagreement remains.
The requested guard is implemented, documented and installed for manual PROD use.
This scoped administrative change does not establish wider App Store release
acceptance or runtime test coverage.
