# PROD iPhone highscore read repair — 2026-09-28

Status: COMPLETE for highscore read availability. DEV and PROD deployed; live HTTP and actual Swift client reads pass. App Store preparation and v2 writes/moderation remain separate unfinished work.

The installed app's current client requests `GET /api/v2/highscores`, while the
previous production package only mapped v1. Read-only probes reproduced v2 HTTP404
and v1 HTTP200 with ten entries. An initial v1 request also timed out (503
`operation_timed_out`); four subsequent reads succeeded. No production test scores
were submitted. The owner's phone is disconnected; physical testing remains owned
by the user and deferred.

## Delivered scope and identity

- Stable base: `94dc44d89929137c4ff02649da58ba8fefa29f1e` (backend equivalent to
  previously deployed `66812f7b802b2d3a697a9db4eec0d6dcf4add7e0`).
- Hotfix source: `75cd63253b21e47927b1c620ff88bfea8460598a`.
- The same GET handler serves v1 and v2 with unchanged public JSON, shared rate
  limiting and no-store/error treatment. Pipeline smoke requires both versions.
- No storage/schema migration, new v2 writes, report routes, shared-plan change or
  synthetic PROD POST. This restores reads; new v2 score publication/reporting
  remain part of the unfinished moderation release. Existing v1 writes are unchanged.
- Isolated worktree excluded the primary checkout's unfinished App Store work.
  Before advancing the primary base, all 97 pre-existing modified/untracked file
  hashes were checked unchanged. Only the two reviewed smoke-check changes were
  then integrated into its pending schema2 packaging code; its pipeline tests pass
  11/11. The rollback note was appended separately without overwriting pending text.
- Immutable DEV ZIP SHA256:
  `8770509f23c6355b5ed6dea55f5e470c62ea7306aaa23728784949fe1e0f106c`.

## Checks and deployment

- Initial targeted test run: 4 expected failures, 11 passes. This was the earlier
  test draft with `Assert.NotEmpty`; the shared-bucket assertion was then strengthened
  to require exactly one success and one429 for concurrent v1/v2 reads.
- Final exact source: `HighscoresTests__UseAzurite=true dotnet test src/backend.tests
  -c Release --nologo`: **63 passed, zero failures/skips**; real isolated Azurite.
- `python3 src/scripts/backend-release-tests.py -v`: **10 passed**. Includes rejecting
  a v1-only deployment in the release smoke check. Scoped whitespace check passed.
- [Backend CI](https://github.com/jesper-bjerre/Donkey-Trump-3D/actions/runs/36408244482): success.
- [DEV deployment](https://github.com/jesper-bjerre/Donkey-Trump-3D/actions/runs/36408244479): success.
  Fresh DEV v2 GET returned200/10 entries; downloaded package digest and embedded
  source commit verified locally.
- [PROD promotion](https://github.com/jesper-bjerre/Donkey-Trump-3D/actions/runs/36409934428): success; promoted the verified DEV ZIP unchanged.
- Initial app/neighbor health checks succeeded except one DEV-neighbor timeout;
  its subsequent `/health` check returned200. PROD remains `asp-vejles-koder-p`,
  AlwaysOn true and DOTNETCORE|10.0. No plan or app-setting changes were made.
- A Swift read-only harness compiled the primary app's actual networking,
  configuration and decoder source (hashes retained). A premature call while the
  PROD deployment was still running returned unavailable; it is not a pass.
  After successful deployment, the same harness passed three consecutive actual
  PROD v2 reads, returning and validating ten rows each. This is actual client-code
  evidence on macOS, not a physical-iPhone test. No credentials are needed/generated for GET.

## Independent review and consensus

Author: OpenAI Codex (GPT-6 family; exact runtime model ID and reasoning setting not
exposed in this session). Reviewer: Anthropic via Claude Code2.1.283,
`claude-opus-5-5`, explicit `--effort high` and `CLAUDE_CODE_EFFORT_LEVEL=high`.
Isolated temporary work, safe mode, tools/MCP disabled, no session persistence.
Text and stream-JSON harmless probes succeeded; no effort-cap warning. Provider
usage identifies the actual canonical model; effective effort is not independently
attested by the provider. No credentials/raw debug logs/hidden reasoning retained.

The first attempt printed invented tool invocations/results despite tools being
disabled. It was rejected and terminated, with no accepted verdict. The second
review explicitly assessed only supplied source/evidence and attributed executed
checks to the lead. Actual successful result/session/configuration is recorded in
[review configuration](prod-highscore-read-2026-09-28/review-configuration.json).

[Final independent verdict](prod-highscore-read-2026-09-28/reviewer-verdict.md):
**APPROVE**, no blocking findings. The lead explicitly agrees for this narrow read
repair. The subsequent live checks passed, completing acceptance for this fix.

Non-blocking dispositions:

- N1: existing diagnostic route label aggregates v2 reads under v1. Accepted as a
  pre-existing observability limitation; no data/security or read correctness impact.
- N2: pre-hotfix rollback would re-break v2 reads and fail smoke after deployment.
  Recorded in the rollback runbook; choose a compatible retained artifact. This
  does not waive the pending moderation release's separate schema2 rollback floor.
- N3: red-log test draft differs from final strengthened assertion. Recorded above;
  final green run and CI on the exact committed source are authoritative.
- N4: v2 writes/reporting remain unavailable; this was explicitly outside the
  read-only fix, not a new regression or a claim of App Store readiness.

[Six-file manifest](prod-highscore-read-2026-09-28/manifest.json) and
[scoped diff](prod-highscore-read-2026-09-28/candidate.diff) identify the reviewed
candidate. Review records are excluded from that payload identity. The same six
hashes were verified before commit; documentation does not retroactively change
review evidence. No physical iPhone or full App Store acceptance is claimed.

## Final live results

- [Six consecutive PROD reads](prod-highscore-read-2026-09-28/after-reads.json):
  three each to v1 and v2, all HTTP200, ten rows, no-store, matching revision.
  Response times0.13–0.19s. Earlier transient timeouts remain recorded above; no
  guarantee against future service/network outages is implied.
- [Actual Swift client](prod-highscore-read-2026-09-28/after-swift.json): three
  successful anonymous reads using the unmodified app service/configuration/decoder
  sources identified by the source manifest. No POST or secret access was needed.
- [App/neighbor health](prod-highscore-read-2026-09-28/after-health.json): DEV and
  PROD game apps and both existing byensgaader neighbors all returned HTTP200.
- Owner can refresh/open the highscore list in the installed PROD app; no app
  reinstall is required for this server route fix. Physical acceptance remains
  owner-deferred, and no new app binary or Apple submission was performed.
