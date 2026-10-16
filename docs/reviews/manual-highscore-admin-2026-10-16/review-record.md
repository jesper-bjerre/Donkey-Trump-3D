# Manual highscore administration — 2026-10-16

Status: COMPLETE. Manual operator tool built and installed in PROD; independent review consensus reached.

The owner requested an API endpoint or similar reusable solution to correct a specific highscore, then specified that this is an administrative need, must not be called by iOS, and must be invoked manually. The implementation extends the existing non-HTTP operator mode and installs a private manual tool in the existing PROD app container.

## Delivered behavior and boundaries

- `entry --rank N` / `entry --entry-id UUID` privately shows only one stored score's public fields and ETag. Rank resolves through the public starter projection; virtual unstored rows cannot be renamed.
- `rename --entry-id UUID --display-name NAME` previews. `--apply` performs a fresh preview and pins that read's ETag. Optional `--expected-etag` additionally pins an earlier preview. Storage-enforced `If-Match` rejects concurrent updates; no unconditional replacement or uncertain-write replay.
- Existing name normalization/validation/moderation and existing store limits are reused. Same-name apply is a read-only no-op. Missing/tombstoned rows cannot be created/resurrected.
- Score/tie/identity/producer fields and report snapshots are preserved. Existing ordinary expired-record cleanup still runs before mutation. No incompatible audit enum/schema fields were added; the saved result supplies ID/ETag instead of a persistent operation receipt.
- Bash wrapper derives DEV/PROD from the actual app name. Existing backend checks independently bind site, MI context and configured Blob location. No new HTTP endpoint, iOS changes, scheduled job, service, credential, RBAC change or app restart.
- Installer creates an immutable hash-named directory under `/home/site/tools/highscore-admin` using the existing matching runtime/dependency files and the new reviewed assembly/wrapper; switches only the manual tool's `current` symlink. HTTP application files are not replaced.

See the [manual guide](../../highscore-administration.md) for the exact owner commands. Installer/source were not committed or pushed; no CI/deployment/test workflow was triggered.

## Revision and inputs

Base commit: `368d7001b90ade026efcc71b4b057683eaa4ffaa`; uncommitted ten-file scoped candidate. [Manifest](manifest.json) records all changed/new source, test, contract and documentation SHA256 values; [diff](candidate.diff) includes new files explicitly. The prior PROD rename review records pre-existed and were preserved. This record/evidence is excluded from its own implementation payload identity.

Published/installed operator DLL SHA256: `0c5da81320e936dcbd8ab818c9fe5c67e1b2d99589e186766882ad0bca3b7cc6`.

HTTP application DLL SHA256 before and after installation: `d2c2eb54e354f5d01cdc03b1712a7b66ab239e0756937b9484b77491414d18b7`.

## Checks actually performed

- Exact SDK 10.0.401 installed into a temporary task directory using Microsoft's official installer; repository SDK pin unchanged.
- `dotnet build src/backend.tests -c Release --nologo -p:UseAppHost=false`: succeeded, zero warnings/errors. This compiles the API and five new focused tests; it does not execute tests.
- `dotnet publish src/backend -c Release --no-restore --nologo -p:UseAppHost=false -o TEMP/publish`: succeeded; wrapper included.
- `bash -n` wrapper and installer in the existing PROD SSH session: succeeded.
- Scoped whitespace, guide links, LF shell files and frozen source hashes checked. `.gitattributes` pins only the two new shell scripts to LF.
- Live runtime/dependency inspection: .NET/ASP.NET 10.0.12, Azure.Identity 1.21.0, Azure.Storage.Blobs 12.29.2. Exact uploaded/installed DLL hash verified. Installer completed and the primary HTTP DLL hash stayed unchanged.
- Actual manual owner-command preparation: `entry` for the previously corrected ID returned exit 0/rank 4/ErikB/4000 and revision `0x8DF2B7BF4A6EF9E`. A manual `rename` preview for the same existing name, without `--apply`, returned exit 0, `preview:true`, `changed:false`, unchanged before/after and revision. [Attributed acceptance](live-acceptance.json), [console screenshot](manual-preview.png).

No unit, integration, UI, end-to-end or smoke tests were run, per AGENTS.md. No synthetic score/report was inserted. No new-tool `--apply` mutation was executed; the task requested a reusable solution, not another live name change. Runtime write/concurrency correctness is not claimed as executed evidence; it was assessed through source and independent review. No physical-device or application-release readiness claim.

## Review configuration

Lead: OpenAI Codex (GPT-6 family; exact runtime model ID/reasoning not exposed). Independent reviewer: Anthropic through Claude Code 2.1.296, canonical `claude-opus-5-5`, `--effort high` and `CLAUDE_CODE_EFFORT_LEVEL=high`. Isolated temporary directory, safe mode, tools disabled, strict empty MCP, no session persistence, bounded eight-minute review process.

Harmless text/stream-JSON probes both exited 0 with `REVIEW_ROUTE_OK`; no text effort-cap warning. Stream probe session `5f606def-9eb9-4214-b155-c3f971638d19`, actual assistant model and nonzero provider usage `claude-opus-5-5`, provider `firstParty`. Effective effort is not separately attested by the provider; explicit settings, successful probes and warning inspection are the available evidence. Credentials/raw logs/hidden reasoning excluded.

Packet contains original task and manual-only clarifications, AGENTS.md/constitution/operator contract, all exact changed artifacts, scoped diff/manifest, relevant unchanged storage/config/name/domain code, actual checks and limitations. Reviewer did not implement or install the tool. It independently inspects supplied source; runtime observations and screenshot contents are attributed to the lead.

## Findings, disposition and consensus

[Independent verdict](reviewer-verdict.md): **APPROVE**, no material defects or unmet in-scope requirements, conditional only on source encoding confirmation C-01. Actual final assistant was `claude-opus-5-5`, provider `firstParty`, successful result/exit 0, session `976f75c2-3522-4382-9c93-256449d2b294`; [sanitized configuration](review-configuration.json).

- **C-01 — closed without a source change:** the reviewer saw replacement characters in the transmitted packet and explicitly authorized closing this item with no action if the source's expected name uses U+00E9. [UTF-8 evidence](encoding-evidence.json) confirms both expected-name occurrences are `52 65 6E C3 A9` (`René`), with no U+FFFD; the guide arrows are U+2192. The code and manifest remained unchanged. The lead agrees with the reviewer's conditional disposition; the stated condition is satisfied and no important source issue remains. No ceremonial second review was requested.
- **N-01:** wrapper hash verification in the installer is optional hardening under already-authenticated staging access; not required or added. Source/wrapper are identified in the reviewed manifest; the uploaded DLL was verified.
- **N-02:** irrelevant arguments were already ignored by older operator commands. New `entry`/`rename` commands reject unrelated keys; no unrelated parser refactoring.
- **N-03:** hard byte-cap overflow fails closed with the existing storage error; no corruption or requirement to change unrelated error handling.
- **L-03 follow-up:** after review, the lead read actual `/home/site/wwwroot/deployment.json`: source `bf3c4165650e9bb4ee8aaf4a9efa2542ac8486a7`, storage read=[1,2], write=[2], rollbackFloor=2. `git diff --stat bf3c416 HEAD -- src/backend` is empty; the working candidate changes no storage model or serializer. [Compatibility evidence](deployed-model-compatibility.json) addresses the reviewer's non-blocking recommendation before a future real apply; it is labelled lead follow-up, not reviewer-executed evidence.

The lead explicitly agrees with APPROVE on the unchanged candidate and its stated limitations. No confirmed important problems, unresolved disagreements or additional owner adjudication remain. Completion is for this manual administrator tool, not an application release or an executed real-name mutation/race test.

The temporary PROD staging files were removed using exact paths and a resolved-directory guard; console confirmed `STAGING_REMOVED; INSTALLED_TOOL_RETAINED`. The immutable installed revision/current link remains for manual owner use. Prior rename evidence was preserved. No commit, push, deployment workflow or test run was performed.
