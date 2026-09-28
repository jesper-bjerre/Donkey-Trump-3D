# Backend single public API — independent review, 2026-09-28

Local implementation consensus: **APPROVED**. Deployment verification follows separately;
this record does not claim the new service is already live or the App Store task complete.

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
