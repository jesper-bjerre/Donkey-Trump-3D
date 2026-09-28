# 2600-point submission investigation — 2026-09-28

User explicitly requested iOS testing after entering a name and receiving
“Highscores are unavailable.” Tests are authorized for this task under AGENTS.md.

## Reproduction and scope

PROD GET returned503 `operation_timed_out`; subsequent DEV/PROD reads returned200
with ten starter rows and no2600 score. This establishes an intermittent cloud
failure, not the exact response or cause of the owner's historical POST.

An actual iPhone13/iOS27 simulator XCUITest entered a name and submitted2600 through
URLSession to the running local ASP.NET service (no fake response service). It passed
in15.034seconds, highlighted rank1, and independent backend readback found the exact
owned run c84f2d38-4d35-46aa-b96b-070944a25f6e at2600. See
[screenshot](highscore-submit-2600-2026-09-28/ios-2600-published.png) and test output.
This is a simulator/local-backend test, not physical-iPhone or PROD UI acceptance.
Computer-use initialization was unavailable; XCUITest supplied the actual UI interaction.

Inside PROD, a read-only managed-identity diagnostic measured identity startup1868ms,
first Blob read1638ms, later reads11/18ms. No credentials or player data were emitted.
The first request approaches the configured2second per-network deadline. Microsoft
[documents the distinction between network timeout and retries](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-retry-policy).

## Bounded correction

Retry one Blob GET after a network timeout only if the caller/overall operation
has not expired. Backoff/retry use the original six-second deadline. No upload or
app POST replay, offline queue, API version change, storage reset or plan change.

A DEBUG-only score argument is confined to the existing loopback integration mode.
Synthetic game completion cannot select production; release builds omit the hook.
The new UI test requires explicit owned origin/run inputs, otherwise skips.

Four new timeout cases reproduced three failures before correction. After correction,
24focused backend tests pass, including read recovery before publish, exhaustion,
overall deadline, conditional writes and lost acknowledgements without replay.
Broader iOS suites were not run. Existing App Store WIP is outside this change.

## Review and deployment

Independent source consensus: APPROVED; lead explicitly agrees. Reviewer ClaudeCode2.1.283,
firstParty claude-opus-5-5, explicit --effort high and CLAUDE_CODE_EFFORT_LEVEL=high;
isolated safe-mode/no tools/MCP. Fresh text probe REVIEW_ROUTE_OK, no effort warnings,
JSON probe c9685cbc-426d-4776-a86b-57ab20c27f63 showed actual model/nonzero usage.
Effective effort is not separately attested. Lead OpenAI Codex; model/effort unavailable.
Initial review03a8d7d4-5487-4110-a1eb-1d823b34fe1b approved source but required F1
evidence clarification. Follow-up307385bb-110f-4a44-ad37-afb28de6319d approved final
candidate with no open material findings. F2 recovered-retry telemetry is optional/deferred.
No source changed between rounds. Reviewer saw only the quoted changed001plan line;
its full file SHA256 is included in the final manifest. OtherWIP is preserved.

F1 resolved: XCTest asserted selected name/2600. Rank1 was visually inspected in the
screenshot. A separate lead-run GET read back2600/rank1 after the test; the original
console observation was[(2600,1)]. The retained readback.json comes from a repeatedGET,
not the original console output. c84f2d38-4d35-46aa-b96b-070944a25f6e was the exact
TEST_RUNNER_DT3D_SCORE_TEST_RUN supplied to Xcode. The command's returned score/rank
and owned origin establish readback, not its self-declared independentReadback flag.
Both rounds' sanitized verdict/configuration are attached; no hidden reasoning saved.

Source implementation and independent review complete; deployment results and remaining verification blocker follow below.

Second focused UI run used a freshly built current Release backend DLL against a
new isolated dt3d-test-score2600-aaef514e24ac Azurite container, not the preexisting
local service. Same UI test passed; separate GET asserted run
ef8ab2d5-9b84-4b9a-94f3-b21b706ee914 at2600/rank1. Owned API and test container were
stopped/deleted in finally. Runtime source unchanged from review.

## Deployment acceptance

Runtime sourcebf3c4165650e9bb4ee8aaf4a9efa2542ac8486a7 contains only backend read
retry, its tests and contract/plan wording. The UI test/hook remain in the primary
working tree alongside prior iOS WIP; no unrelated App Store work was pushed.
CI36428503259 succeeded. DEV36428503271 succeeded, and all29 mounted files matched
ZIP3ca6bb2fba6f9f5fab30e35f067dd85cb811e938255a9eaeb847310fdae217ba.
DEV live credentialed2600POST returned200/ranked; independentGET confirmed2600;
published operator removed the owned test row and GET proved original entries
restored (ten entries, no test rows). This is a live HTTP check, not a cloud UI test.
PROD run36428990707 completed successfully, promoting the verified DEV ZIP. No schema conversion/maintenance or shared plan
change is involved. Initial local UI row was also removed using conditionalIf-Match
against its known owned Azurite container, with readback; other local rows preserved.

## Remaining PROD verification blocker

The PROD pipeline succeeded and a subsequent live v1 GET returned200 (1.486s, then
2.104s). However, fresh Azure tunnels repeatedly closed or timed out after the SSH
password prompt, including an explicit READY-instance tunnel. No final PROD
wwwroot hash verification or operator preflight could be completed. The broader
public-check script also encountered TCP connection refusal and TLS handshake
timeout; no failure was silently counted as a pass. This is a verification blocker,
not evidence that the historical owner POST cause is fully fixed.

No PROD test POST was sent in this remediation because the operator cleanup path
was unavailable. DEV live2600save/readback/cleanup passed; PROD live publication
remains unverified. No shared-plan/neighbor restart, scale change, storage reset, maintenance
change, user-score replay or original2600 restoration was performed. The source
fix addresses transient per-network read timeouts, not every source of unavailability.
The owner's exact testing environment was asked asynchronously but not supplied.

Local UI tests and backend regression checks are complete. The final backend
release must not be described as fully verified in PROD until mounted-artifact and
live write/readback/cleanup checks are completed through restored operator access.

A later PROD read returned503 (response body was not retained). A controlled
stop/start of only donkeytrump-api-p was then performed: ARM confirmedStopped
beforeStart. Afterward health returned200 in0.170seconds and v1 GET returned200
in4.037seconds. The current instance was freshly checked as READY with the same
instance ID. A final instance-specific tunnel still did not become usable while
SCM answered401 (expected unauthenticated), so it was closed without a PROD test
write. This remains a concrete operator-access/runtime-verification blocker; the
restart and two successful reads do not establish that all failures are resolved.
