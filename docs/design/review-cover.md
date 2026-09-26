# Independent cover integration review — 2026-09-26

## Task and result

The owner requested `docs/design/images/DonkeyTrumpCover.png` as the loading screen and possible App Store artwork. The focused implementation adds a native local launch screen, keeps the original image unchanged, preserves the full illustration proportionally, records its prompt/provenance and adds truthful optional store use to the existing release specification. It adds no delay, network dependency or new interaction.

**Consensus reached.** The independent reviewer approved the final candidate after one documentation correction. The lead explicitly agrees: the authorized cover integration meets its applicable requirements and no important in-scope findings remain unresolved. This does not complete the wider App Store release specification or its future physical-device/content/account gates.

## Participants and verified route

| Role | Tool / vendor | Model and reasoning | Evidence |
|---|---|---|---|
| Lead implementer | Codex / OpenAI | Exact runtime model ID and reasoning setting unavailable in session metadata | Lead performed implementation, builds, simulator capture, document checks and F1 remediation. |
| Independent reviewer | Claude Code 2.1.283 / Anthropic | `claude-opus-5-5`; explicit `--effort high` and `CLAUDE_CODE_EFFORT_LEVEL=high` | Successful harmless plain-text and stream-JSON preflight; both review rounds returned actual assistant output and nonzero first-party usage for the canonical model. |

The reviewer did not implement the change. It ran read-only in an isolated temporary directory with safe mode, tools and MCP disabled, no session persistence and no fallback model. Round 1 received the full scoped source/requirements/diff/check evidence plus four image attachments. Round 2 received the prior discussion and a focused final packet.

The plain-text probe returned `REVIEW_ROUTE_OK` with no stderr or effort-cap warning. The JSON probe session was `6bd5ae26-c880-483e-a879-05c1c5658828`. Review sessions were `8f75688e-efbe-42e7-b8b3-ab3e9bf496e4` and `85bd41c4-fd81-4d09-8b71-373a382509b8`. All exited successfully; review stderr was empty. Provider metadata verifies the actual model but does not separately attest effective reasoning effort. No cap warning or access error occurred; the same successful preflight was reused for the focused round.

[Sanitized route evidence](reviews/cover-2026-09-26/route-evidence.json) records the actual configuration/results without credentials or hidden reasoning.

## Frozen scope

- Governing instructions: repository `AGENTS.md` and constitution v1.0.0, included in the packets.
- Git base: `e323551c539e40edbc7b8e57dda3ed2ee5735e09`, existing `main` worktree. No commit was created.
- Existing untracked files were captured before editing; [base.json](reviews/cover-2026-09-26/base.json) identifies that snapshot separately from Git HEAD.
- Final candidate: [manifest.json](reviews/cover-2026-09-26/manifest.json), SHA-256 `0ff45c2029885a1f0cf255bc332a70692338a7541c8f03f8f1c09f9303a4093d`.
- Final [scoped patch](reviews/cover-2026-09-26/scoped.patch) includes new text files against an empty base and edits against the captured pre-edit files. Binary contents are identified by the manifest and supplied as images.
- [Context manifest](reviews/cover-2026-09-26/context-manifest.json) identifies unchanged governing/source context, including in-app copy added for round 2.
- The [original packet](reviews/cover-2026-09-26/review-packet.txt), round-1 manifest/patch and [focused packet](reviews/cover-2026-09-26/focused-review-packet.txt) preserve both review rounds. The original packet is intentionally tied to its original candidate, not relabeled as final.
- Review records are excluded from their own candidate identity. Changed source, specifications, docs and acceptance evidence are included. Final candidate/context hashes were rechecked after approval. Historical release-specification review files remain unchanged.

## Finding and disposition

| ID | Impact | Resolution | Re-review |
|---|---|---|---|
| F1, Medium | README's blanket claim that every visual asset was generated in code became inaccurate when the supplied raster cover was bundled. This could mislead later provenance/declaration work. | Lead agreed. README now limits code generation to 3D gameplay graphics, discloses the supplied cover and missing generation terms, links its provenance and leaves FR-006 assessment open. In-app copy was inspected and has no equivalent blanket claim. | Reviewer explicitly marked F1 **RESOLVED** and approved the final candidate. |

Only README changed between review candidates. Local document links and the content manifest were refreshed. The fix changed no runtime inputs, so builds/UI tests were not repeated for that prose correction. The reviewer's audio-wording note was explicitly optional and required no action; “the project's synthesized audio” also covers the existing native intro effects.

The lead accepts the reviewer's final verdict: **“APPROVED. F1 is resolved.”** See the full [first verdict](reviews/cover-2026-09-26/round-1-verdict.md) and [final verdict](reviews/cover-2026-09-26/final-verdict.md).

## Checks and limitations

The [validation record](cover-validation.md) contains commands, actual output and screenshots. Debug and Release builds passed; three existing UI tests passed, and the Start/hung-fetch test passed again with simulator signing enabled. Ordinary signed Release launch showed the cover and automatically reached the 3D title. Source and bundled PNG bytes match. XML/JSON/project syntax, specification IDs, local links and whitespace checks passed. The disposable simulator used for capture was shut down and deleted; the owner's simulator was preserved.

An initial unsigned simulator capture was black because SpringBoard rejected the storyboard resource signature (`-67056`). It is explicitly excluded from acceptance. Local ad-hoc simulator signing and reinstall resolved that observation without an app-source change.

The first reviewer independently inspected the supplied illustration, ordinary launch frame, held layout screenshot and final title screenshot. It did not watch the whole video; automatic transition evidence is attributed to the lead's observation and the native launch-only implementation. The second reviewer inspected `Copy.swift` and relied on the lead's attributed search for other hard-coded UI strings; the first packet includes the unchanged `RootView.swift`.

No physical iPhone, minimum-supported iOS 26, distribution archive or Apple account validation was performed. The cover's store composition and FR-006 content/rights assessment remain future release work. No upload, review submission or publication occurred.
