# Xcode backend environment selection — 2026-09-27

## Scope and identity

The owner requested selection of Local, DEV or PROD when running the iOS app in
Xcode. The implementation adds shared schemes and build configuration files,
preserves the existing scheme with DEV as its Run default, and keeps all shared
Archive/Profile actions on HTTPS PROD Release. Local uses the existing permitted
simulator loopback transport. No Swift runtime code, Azure resources or deployments
were changed. Physical-device LAN HTTP was not requested or enabled.

Governing instructions: [AGENTS.md](../../AGENTS.md) and
[constitution 1.0.0](../../.specify/memory/constitution.md), particularly local
transport isolation, non-blocking gameplay and proportional verification.

- Base: `4c191a6c8998c37b6765362b9b17c957fb8ae61f`.
- Final candidate: the same uncommitted 13-file
  [SHA-256 manifest](ios-backend-environments-2026-09-27/manifest.json) in both rounds.
- [Tracked diff](ios-backend-environments-2026-09-27/candidate.diff); all untracked
  candidate files were supplied in full and included in the manifest.
- [Check evidence](ios-backend-environments-2026-09-27/checks.txt) and
  [sanitized metadata](ios-backend-environments-2026-09-27/metadata.json), including
  packet, manifest and final evidence hashes. This review record and its supporting
  records are excluded from the source candidate identity.

## Participants and verification

OpenAI Codex implemented the change. Its exact model identifier and effective
reasoning setting were not exposed in this session.

The independent reviewer was Claude Code 2.1.283 using Anthropic
`claude-opus-5-5`, with both `--effort high` and
`CLAUDE_CODE_EFFORT_LEVEL=high`. The reviewer did not implement any change. It
inspected the complete text packets with tools and MCP disabled, safe mode and
no session persistence, from an isolated temporary directory.

Fresh authenticated plain-text and JSON probes succeeded. The text probe had no
effort-cap warning; each actual review returned success, an assistant response
from the canonical model and nonzero first-party provider usage. The provider
does not separately attest effective effort. No fallback was needed.

## Checks and findings

- All Local, DEV, PROD Run configurations and Release built successfully with
  Xcode 27.0 (27A266a) for iOS Simulator. Inspected actual built Info.plists and
  resolved settings: each origin correct; Release has no ATS exception or DEBUG
  compilation condition. All four shared schemes' action mappings were checked.
- `Debug Local`: 40 existing tests in 11 suites passed on iPhone 13 / iOS 27.0.
- Default `DonkeyTrump3D` Test action, without a configuration override: 40 unit
  tests and 14 UI tests passed; 3 explicitly gated stream/performance/redirect
  cases skipped because their special local test servers were not supplied.
- Fixed-port local helper started on 5281 against owned Azurite 3.37.0 storage;
  health and empty-list GET returned 200. Ctrl-C stopped the API and deleted only
  its owned container, verified against emulator state.
- Project plist syntax, Python syntax, changed Markdown link targets and
  `git diff --check` passed.

| Finding | Discussion and disposition |
|---|---|
| F1, medium, default Test-path evidence missing | The first review correctly identified that only the Local configuration's unit tests had run. The lead ran the default Test action including UI tests and supplied all missing test/coordinator/performance-harness source. Independent re-review confirmed the tests select injected fixtures or explicit loopback integration, while the unit host remains idle. Closed as an evidence gap; no implementation defect or source change. |

The [initial verdict](ios-backend-environments-2026-09-27/review-1.md) and
[focused approval](ios-backend-environments-2026-09-27/review-2.md) preserve the
discussion. Optional socket-reuse and backend-less test configuration suggestions
were not required and remain deferred.

## Consensus and limits

Reviewer verdict: **APPROVE**, F1 resolved and no new material findings.
Lead verdict: **agree**; the scoped implementation satisfies the requested
environment selection and applicable constraints. Final manifest verification
confirmed the candidate remained unchanged. No material disagreements remain.

Test isolation is established by source inspection, not Azure telemetry or a
network-blocked test run. The reviewer did not inspect RootView; the lead also
checked its existing on-launch opening guard, which requires explicit loopback
integration arguments. There is no ordinary automatic title-list request.

No normal Run UI-to-local-API end-to-end check, physical iPhone test, signed archive
or App Store validation was performed. These results establish configuration/build
and regression-test acceptance, not distribution readiness. Review did not commit,
push, deploy or authorize additional release scope.
