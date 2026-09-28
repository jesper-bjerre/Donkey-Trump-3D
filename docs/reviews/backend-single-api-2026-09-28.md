# Backend single public API — independent review, 2026-09-28

Implementation consensus: **APPROVED**. DEV and PROD deployment verification completed;
this record does not claim the broader App Store task is complete.

Owner authorized DEV/PROD deployment and explicitly requested one existing `/api/v1`
for the unreleased owner-tested app. Removed v2/426 retirement paths. The existing
App Store scope supplies publication attribution, reporting/removal/blocking,
private MI operator commands, bounded Blob concurrency/retention and public pages.

## Review identity and independence

- Lead: OpenAI Codex; exact model ID/reasoning not exposed by this runtime.
- Independent reviewer: Claude Code2.1.283, actual firstParty `claude-opus-5-5`, explicit CLI `--effort high` and `CLAUDE_CODE_EFFORT_LEVEL=high`; safe-mode, tools/MCP disabled, no persistence, isolated temporary directory. Reviewer did not implement any changes.
- Fresh text probe returned REVIEW_ROUTE_OK with no effort warning. JSON probe session `70195bd3-49c4-49c9-bd11-fc03f09bd2a8` returned successful actual model/nonzero usage. Effective effort is not separately attested by provider. Every real round returned the same actual model and successful result; sanitized metadata linked below.
- One initial attempt was cancelled because its working directory was the repository rather than the required isolated temporary directory. It produced no review verdict and is not review evidence. No hidden reasoning/raw streams are included.
- Base `8a68e5b155b07b16af57382443280db5e818be0d`; uncommitted source is identified by [initial](backend-single-api-2026-09-28/manifest.json) and [final](backend-single-api-2026-09-28/final-manifest.json) SHA-256 manifests. Full source including untracked files was supplied. Dockerfile/ignore were added explicitly to focused-round scope. The review record is excluded from its own payload identity.

## Findings and consensus

[Round1](backend-single-api-2026-09-28/round1-verdict.md) blocked on R1/R2. Lead agreed:
remove unconditional maintenance settings from both deployment workflows, then test
schema1 rejects publish/report without a maintenance flag, with zero upload attempts,
unchanged ETag, HTTP503/no-store and working reads. These tests pass.

[Round2](backend-single-api-2026-09-28/round2-verdict.md), session
`0a5779de-ddec-4009-8c06-cee3534cd601`, explicitly APPROVES; no material code findings
remain. Lead agrees. R3 is an operational gate: unused PROD first provisioning via
the reviewed temporary in-container DLL, then verified conversion/backup deletion,
maintenance off, live reads and a test-owned credentialed POST. R4–R8 remain recorded
non-blocking limitations: reserialized backup, maintenance-paused backup cleanup,
diagnostic route categorization, bounded-capacity replay rejection and cold-MI command
time budget. Never blindly retry an uncertain migration; inspect first.

## Actual checks and limits

[Check output](backend-single-api-2026-09-28/checks.txt):109 backend tests pass/0 skip
against Azurite,11 pipeline tests pass; full owned local API/report/operator/receipt/
migration smoke passes. Initial106/11/smoke also passed in the isolated deployment
worktree; final changes match the reviewed manifest. Eight focused Swift tests passed
on iPhone13 simulator. Local dotnet publish includes storage-contract.json. Docker
image build not run; Azure rollout uses ZIP. Full iOS regression, physical device,
owner moderation participation and App Store draft remain separate unfinished gates.

Cloud rollout state is recorded in
[backend rollout evidence](../releases/app-store/backend-single-api-rollout.md).

## Follow-up: cold operator identity startup

A separate operational defect appeared during PROD rollout: the cold CLI token
request repeatedly consumed the six-second store deadline. A bounded30-second
MI-only startup handshake now precedes the unchanged store deadline and reuses the
credential in memory. Public API authentication/deadlines are unchanged. This is
new evidence; historical R8 is not relabeled as a review of this repair.

Source commit `27aa8104de27c998526e5844e3264457ca9f1d7a` on `b04ffe3` changes only
four files (full `git diff --stat` and `git diff --name-status` confirm four M entries,
20insertions/2deletions). Committed file SHA256 values match the
[repair manifest](backend-single-api-2026-09-28/auth-manifest.json).
The first primary-worktree diff mistakenly represented two still-untracked files as
deleted relative to the newer base. R9 confirmed this evidence problem. That diff is
preserved as `auth-incorrect-superseded.diff`, not an implementation change. The
[corrected tracked diff](backend-single-api-2026-09-28/auth-corrected.diff) and explicit
committed-blob verification resolve R9. No source content changed between reviews.

Fresh text/JSON access probes after resumption succeeded with no effort warning;
probe session`5ed56d68-a214-44ea-88ac-77e181ab2256`, ClaudeCode2.1.283,
firstParty claude-opus-5-5, explicit high settings as above. Lead exact model/effort
remain unavailable. [Initial repair review](backend-single-api-2026-09-28/auth-review-verdict.md)
and [identity correction review](backend-single-api-2026-09-28/auth-correction-verdict.md)
both APPROVE the manifest content; final session`c8514c96-1a27-4fc7-b51c-b41de338fa59`.
Lead agrees; no material code findings remain. R10 requires actual loaded package
identity and cold wwwroot operator checks in DEV/PROD before conversion. The /tmp
read-only success is diagnostic, not that rollout proof. Capture stays disabled in
cloud; local integration checks cover its changed client factory path.

After repair:109 backend tests/0skip and owned local migration/operator smoke PASS;
local publish PASS. Final cloud evidence is recorded separately below the rollout
record; until those gates pass this approval alone does not claim deployment complete.

## Completed rollout acceptance

Unchanged reviewed source27aa810 is live in DEV/PROD; all29 mounted artifact file
hashes match the promoted ZIP. Both cold published operators were exercised before
conversion. PROD conversion preserved all11 rows, backup absence was independently
verified, maintenance is now false, and test-owned publication/cleanup restored ten
rows. DEV report/acknowledge/remove/block/receipt smoke passed. Public API/pages/auth
and all four game/neighbor health checks passed. Detailed failures and subsequent
readback/cleanup evidence are preserved in the linked rollout record, including
post-recycle transient timeouts and an explicit retry of cleanup only after readback.
Lead agrees the unchanged implementation and completed R10 deployment gates satisfy
the authorized backend task. Public App Store release and physical testing are not
claimed. Cold-start timeout limitations remain documented.
