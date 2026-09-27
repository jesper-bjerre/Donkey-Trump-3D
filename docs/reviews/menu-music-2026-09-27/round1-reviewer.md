# Independent Review: Menu/Loading Music (Codex implementation)

**Reviewer:** Anthropic Opus 5.5 (`claude-opus-5-5`), text-only packet, no tools. I cannot attest to my own effective effort setting; the lead's route verification governs.
**Reviewed identity:** base `85fde11c…` plus the captured pre-edit dirty worktree (before.sha256) and candidate.sha256 (6 files). The MP3 was assessed from metadata, SHA and the lead's test evidence only. I did no listening or decoding.

## Verdict: **CHANGES REQUESTED**, on one finding (MM-01)

Everything else meets the acceptance criteria on the supplied evidence. I will approve if MM-01 is fixed as suggested below or dismissed with the requested evidence.

---

## Finding

### MM-01: `initial: true` also changes when the existing highscore background hook runs
- **Severity:** Low. Materiality depends on context I don't have. It blocks only until dispositioned.
- **Location:** `src/DonkeyTrump3D/App/DonkeyTrump3DApp.swift:16-21`
- **Observation:** `initial: true` was added to the pre-existing handler instead of a dedicated one.
  - On the initial call, `old == phase`.
  - Line 19 stays safe, because `old == .active && phase != .active` cannot hold when the two values are equal.
  - Line 20 now runs `model.highscores.background()` once at scene start whenever the first observed App-level phase is `.background`. Before the edit, it ran only on real transitions.
  - Whether the first observed phase is `.background` depends on SwiftUI/OS behaviour, including prewarming and background launch. The passing UI tests do not exercise this.
- **Impact:** Unknown without `HighscoreCoordinator.background()`. This is the highscore lifecycle (cancellation, submission acknowledgement), which AGENTS.md flags for particular attention. The task did not authorize any change to it.
- **Requirement:** AGENTS.md "Preserve unrelated changes"; constitution Development Workflow ("Existing work … MUST be preserved when applying a scoped change").
- **Suggested remediation (preferred, no extra evidence needed):**
  1. Restore the original handler without `initial:`.
  2. Add a separate modifier: `.onChange(of: scenePhase, initial: true) { _, phase in AudioSystem.shared.setMenuMusicActive(phase == .active) }`.
  3. Rerun the build, `IntroAudioTests` and `HighscoreBrowsingUITests`.
- **Alternative:** Supply the `background()` source showing it is idempotent and has no effect on a freshly constructed coordinator. I would then withdraw the finding.

---

## Acceptance trace (independently checked)

| Criterion | Assessment | Basis |
|---|---|---|
| Correct compact, iOS-decodable supplied format | **Met** | The `.m4a` is Opus-in-MP4 with 0 valid frames/duration per `afinfo`. The WAV is 13.7 MB. The MP3 is 1.77 MB, stereo, 48 kHz, 71.64 s. The bundled copy is byte-identical (SHA matches). `AVAudioPlayer` decode test passed. |
| Bundled | **Met** | Release build shows a matching SHA in the app bundle; codesign verified. |
| Async preparation, no launch/gameplay delay | **Met (by inspection)** | Decoding and `prepareToPlay` run on the utility queue outside the lock (`AudioSystem.swift:97-107`). The menu track is published before the effects load. There is no readiness gate. No launch timing benchmark was run, which the lead disclosed. |
| Loops across loading, title and title overlays | **Met (state level)** | `numberOfLoops = -1`. Requested in `GameEngine.init:132-134` before the first frame. Help and highscores don't change the engine phase or `scenePhase`, so the track continues. |
| Sound preference | **Met** | Volume is applied under the lock when published (`:104`) and in the setter (`:80`). Tested before preparation, during playback and across toggles. |
| Stops for intro/game | **Met** | `startIntro:444` and `startMusic:184-185`, which covers autostart via `.levelStarted`. `-introAt` is excluded in init and stopped anyway. |
| Returns on title | **Met** | `.toTitle:395`. `currentTime` resets only on a fresh request (`:215`). I relied on the packet's statement that `.toTitle` is the only path back to title; `GameSession` was not supplied. |
| Pauses while inactive | **Met** | `setMenuMusicActive` is independent of render-thread intent. A title request made while inactive does not play. |
| No stale revival after delayed preparation | **Met** | The publish step checks `menuMusicRequested && menuMusicActive` under the same lock that stop, start and active use (`:102-106`). Tested with a suspended queue. |
| Thread ownership | **Acceptable** | All state is behind `NSLock`. Calls come from main (scene phase, init) and the render thread (commands). Calling `play()` while holding the lock matches the existing `startMusic` pattern. |

## Non-blocking notes (no action required)
- **N1: Render-thread re-prepare.** `stop()` undoes `prepareToPlay`, so `startMenuMusic` on `.toTitle` re-prepares the MP3 on the render thread. The existing `startMusic` does the same, and this transition already runs `buildLevel`. Not material.
- **N2: No auto-resume after some interruptions.** If an audio interruption doesn't change `scenePhase`, the menu track isn't resumed until the next phase change or title entry. Existing gameplay music behaves the same way.
- **N3: Engine wiring is verified by inspection only.** No automated check observes the engine calling AudioSystem (the UI tests don't assert audio). The AudioSystem-level tests cover the concurrency and ordering behaviour that matters. The engine wiring is three calls and reads as correct.
- **N4: Provenance is owner-asserted.** `docs/design/menu-music.md:3-5` accurately records owner authorization rather than a verified licence. This is consistent with constitution IV's "documented permission", and the track adds to the synthesized soundtrack rather than replacing it. Confirm provenance before release.

## Evidence classification
- **Simulator state evidence (executed, iPhone 13 / iOS 27.0 sim):**
  - 11 audio unit tests and 5 UI tests passed.
  - Debug and Release builds succeeded.
  - These establish decodability, `isPlaying`/volume state transitions, and that startup and navigation don't block on the backend or audio.
- **Not established:**
  - Audible output.
  - Loop-seam quality: the MP3 has 576 priming + 1344 remainder frames, so gapless looping via `AVAudioPlayer` is unverified.
  - Level balance against effects (0.35 vs 0.22).
  - Physical silent-switch, speaker and headphone behaviour.
  - Launch timing on iPhone 13.
- Per constitution V, these are required for **release acceptance**, not implementation completion. The design doc (`:28-30`) and checks.txt state this correctly.

## Context limitations
- Not supplied: `HighscoreCoordinator.background()` (needed for MM-01), `GameSession` phase transitions, the omitted `GameEngine` ranges (145–302, 498–566), and the project file.
- Only MM-01 depends on missing context.
