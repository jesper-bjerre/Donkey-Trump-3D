# iPhone-only archive configuration fix — 2026-09-28

## Scope and result

Owner requested a fix for Validate App rejecting landscape-only iPad multitasking
orientations. Implemented the previously chosen iPhone-only scope: main app target
family 1 in Debug, Release, Debug Local, Debug PROD and AppStoreCapture; removed the
five unused iPad orientation settings. Both iPhone landscapes remain. Test target
settings and unrelated release-preparation edits were preserved.

Governing sources: AGENTS.md, constitution 1.0.0, spec002 FR-002, plan, T032 device
scope, ios-release-flow contract. The earlier same-session Chrome discovery recorded absence of the app/bundle
followed by creation of app
6817091486/version1.0; no prior native iPad release blocks narrowing. See
[account discovery](../../account-discovery.md) and [owner inputs](../../owner-inputs.md).

## Frozen implementation and evidence

- Base: `368d7001b90ade026efcc71b4b057683eaa4ffaa`.
- Uncommitted candidate: [source manifest](source-manifest.sha256) and
  [complete scoped diff](source.diff). Only project.pbxproj is implementation scope.
- Actual archive fields: [archive-properties.json](archive-properties.json).
- [Archive hashes](archive-manifest.sha256) identify archive Info.plist, app Info.plist
  and executable; this is not a full recursive archive manifest.
- Evidence/review records are excluded from the source identity. Existing unrelated
  uncommitted account-discovery and release-preparation documents are preserved.
- Original archive: `~/Library/Developer/Xcode/Archives/2026-09-28/DonkeyTrump3D PROD 28-09-2026, 22.35.xcarchive`.
  Actual app plist had family `[1,2]` and landscape-only iPad/iPhone arrays.
- Replacement: `~/Library/Developer/Xcode/Archives/2026-09-28/DonkeyTrump3D PROD iPhone-only.xcarchive`.
  Version1.0/build1; family `[1]`; only the two iPhone landscapes; iPhoneOS;
  minimum iOS26.0; exact PROD backend. Do not validate/upload the original archive.

Apple's [UIDeviceFamily reference](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/iPhoneOSKeys.html)
explains that Xcode inserts this key from the target setting and family1 denotes iPhone/iPod.

## Executed checks

- `git diff --check`: exit0.
- `plutil -lint src/DonkeyTrump3D.xcodeproj/project.pbxproj`: OK, exit0.
- `xcodebuild -project src/DonkeyTrump3D.xcodeproj -scheme 'DonkeyTrump3D PROD' -configuration Release -destination 'generic/platform=iOS' -archivePath '<replacement path above>' archive`:
  exit0, `ARCHIVE SUCCEEDED`, Xcode27.0 (27A266a).
- `python3 src/scripts/validate-ios-release.py archive '<replacement path above>'`:
  exit0, `Validated archive identity: 1.0 1`.
- Python plist inspection confirmed the fields retained in archive-properties.json.
- `codesign --verify --deep --strict '<replacement path>/Products/Applications/DonkeyTrump3D.app'`:
  exit0. Archive is locally Apple Development-signed for team QHL89A7A8J;
  App Store distribution export/re-signing has not been performed.
- Only archive warning: AppIntents metadata extraction skipped because no
  AppIntents.framework dependency was found.
- No unit, integration, UI, smoke or runtime tests were run: the user did not
  explicitly authorize tests. Apple's server-side Validate App was not rerun.

## Independent review route

Lead: OpenAI Codex, GPT-6 family; exact internal model identifier and reasoning
setting are not exposed in available session metadata. Reviewer: independent
Anthropic Claude Code2.1.283, canonical model `claude-opus-5-5`, provider `firstParty`.
The reviewer did not implement this change; tools/MCP and automatic instructions
were disabled, and current instructions were supplied in the complete text packet.

Installed `claude --version` and `claude --help` were inspected. From an isolated
`/tmp/dt3d-orientation-review` directory, all probes/review used:

```sh
CLAUDE_CODE_EFFORT_LEVEL=high claude --safe-mode --print   --model claude-opus-5-5 --effort high --tools ''   --strict-mcp-config --mcp-config '{"mcpServers":{}}'   --no-session-persistence
```

Harmless prompt: `Reply exactly REVIEW_ROUTE_OK. Do not use any tools.` Both text
and stream-json probes exited0 and returned REVIEW_ROUTE_OK. Text stdout/stderr
had no effort-limit warning; JSON stderr was empty. JSON probe actual assistant
model and nonzero provider usage confirmed canonical model claude-opus-5-5, provider
firstParty; session `cfecaee8-acd7-4f36-aac2-952cd4550b43`.

Review used `--output-format stream-json --verbose`; exited0 with successful result,
actual assistant model claude-opus-5-5 and nonzero usage for the same canonical model
and firstParty provider; session `42ce651a-0a6f-411d-9439-507cdc98554b`. Stderr empty.
Explicit high settings and warning-free probes establish the configured route;
provider output does not independently attest effective reasoning effort.

Packet contained user task, scope, exact base/manifest/diff, full candidate project,
AGENTS/constitution/contract, relevant spec/plan/tasks/owner/history excerpts,
Release plist, PROD config, archive scheme, validator source and actual check results.
The complete temporary packet is at `/tmp/dt3d-orientation-review/review-packet.txt`;
its persistence is not guaranteed. Sanitized final reviewer text is retained in
[reviewer-verdict.md](reviewer-verdict.md); no hidden reasoning/debug logs retained here.

## Verdict and limits

Reviewer: **APPROVED, no material findings**, sufficient context, no further round
required for the unchanged candidate. Lead explicitly agrees: source and resulting
archive metadata satisfy the bounded iPhone-only orientation correction. Consensus
reached; no material disagreements or unresolved in-scope defects.

Non-blocking notes accepted: use the replacement archive; do not mark all of T032
complete; descriptive constitution baseline about iPad is now stale but needs no
scope-expanding governance edit; iPad compatibility behavior remains unverified.

Configuration fix and replacement archive are complete. This is not full release
acceptance: no Apple validation/upload/submission/publication was performed. Device
and simulator acceptance, store declarations/assets and other existing release
prerequisites remain separate. Reviewer inspected source and reported evidence,
not the archive directly, and did not recompute archive/source hashes.
