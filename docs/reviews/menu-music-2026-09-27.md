# Loading and menu music — 2026-09-27

## Outcome and scope

The owner requested music during loading and the menu, selected from `docs/design/music`.
The app now bundles the supplied MP3 unchanged, prepares it first on the background
queue and loops it across runtime loading, title, help and title highscores. It
stops before the intro, returns on title entry, respects Sound and pauses while
inactive. Deferred preparation checks current playback intent. There is no added
loading delay or backend dependency. The system launch storyboard cannot execute
audio; playback starts once the app is active and the player is ready.

[Design and asset selection](../design/menu-music.md). MP3 is stereo, 48 kHz,
approximately 71.6 seconds and 1.7 MB. The supplied M4A contains Opus rather than AAC;
the WAV is approximately 13 MB. Original supplied files remain unchanged.

## Participants and route

- Lead: OpenAI Codex; exact runtime model ID, tool version and reasoning setting
  are not exposed in this session.
- Independent reviewer: Anthropic Claude Code 2.1.283, `claude-opus-5-5`, explicit
  `--effort high` and `CLAUDE_CODE_EFFORT_LEVEL=high`; did not implement the change.
- Fresh harmless text and stream-JSON probes passed, with canonical assistant model,
  nonzero first-party provider usage and no stderr/effort-cap warning.
  [Route metadata](menu-music-2026-09-27/route.json). Effective effort is not separately
  attested by the provider; the explicit configuration and warning check are recorded.
- Both rounds used an isolated temporary directory, safe mode, no tools/MCP and no
  persistence. Each completed successfully with the requested actual assistant model
  and no stderr. [Round 1 metadata](menu-music-2026-09-27/round1-review-metadata.json),
  [final metadata](menu-music-2026-09-27/review-metadata.json). No fallback was needed.

## Revision and evidence

Git base: `85fde11c86213b3876b4a5504afb20fe492a455e`. The task base is the captured
pre-edit dirty worktree, not a claim that those files matched HEAD. Six scoped
files: AudioSystem, App, GameEngine, IntroAudioTests, new MP3 and new design doc.
New files have empty-before hashes. All earlier unrelated work was preserved.

[Before hashes](menu-music-2026-09-27/before.sha256),
[final hashes](menu-music-2026-09-27/candidate.sha256),
[scoped patch](menu-music-2026-09-27/task.diff).
Round-1 hashes and patch are retained separately. Only App lifecycle wiring changed
between review rounds. Final hashes were checked unchanged after approval.
This record and its evidence copies are excluded from source payload identity.
No commit, push or deployment was performed for this task.

The first review packet contained user scope/acceptance criteria, governing policy
and constitution, full changed text files except selected relevant GameEngine
ranges, supporting loading/menu/UI-test context, scoped patch/manifests and attributed
check results. The binary was represented by metadata, hash and decode/build evidence.
The focused round included the prior verdict/discussion, governing requirements,
final App source, patch/manifests and newly executed checks. Reviewer did not run
checks, recompute source hashes or listen to the audio.

## Checks actually run

[Commands and limitations](menu-music-2026-09-27/checks.txt),
[asset inspection](menu-music-2026-09-27/asset-info.txt).

- iPhone 13 / iOS 27.0 simulator: **11 audio tests and 5 browsing UI tests passed**,
  initially and after the review fix. Includes bundled MP3 decode/preparation,
  late-load cancellation, foreground/background and late title requests, mute before
  and after preparation, gameplay transition, existing intro timing, progress
  dismissal and Start/Skip with unavailable/slow highscores.
- Debug app/test build and Release simulator build passed. Release codesign check
  passed; bundled MP3 SHA256 matches the supplied source:
  `55f763b5e79c4c7ffef3c37726d873164240901c9180cef67b6dade79d110d58`.
- `git diff --check` passed; links in the design doc resolve.
- [Final test output](menu-music-2026-09-27/final-tests-results.txt),
  [final Release output](menu-music-2026-09-27/final-release-results.txt).
  Initial outputs are also retained. These are selected actual output, not full logs.

Simulator playback-state checks do not prove audible output, loop-seam quality,
volume balance, speaker/headphone behaviour or the physical silent switch.
No physical-device acceptance, full launch benchmark or distribution archive is claimed.

## Findings and consensus

[Round 1](menu-music-2026-09-27/round1-reviewer.md) requested disposition of **MM-01**:
adding `initial: true` to the existing scene-phase handler could also invoke the
highscore background hook on an initial background state. No actual highscore
failure was reproduced. Lead agreed to preserve the original hook semantics and
applied the preferred fix: a dedicated initial audio handler and the original
transition-only gameplay/highscore handler. All affected tests/build checks were rerun.

[Focused final verdict](menu-music-2026-09-27/reviewer.md): **APPROVED**.
MM-01 resolved; no new material findings or important disagreements.

Non-blocking observations remain documented in the reviewer record: returning to
title may re-prepare a stopped player (the existing gameplay player follows the same
pattern); interruptions without scene-phase changes do not gain new automatic resume;
engine wiring is checked by source inspection rather than acoustic UI assertions;
asset permission is owner-supplied, not an independently verified third-party licence.
These do not require expanding this task.

Lead: **I agree with the final approval.** The requested music behaviour, selected
asset, preservation of unrelated lifecycle behaviour and passing checks satisfy
this implementation scope. No important in-scope finding remains unresolved.
Implementation consensus is complete; physical-device release acceptance is separate.
