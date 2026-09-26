# iOS interaction contract

Status: implemented; see [validation evidence](../validation.md) for executed and pending checks. Covers [FR-004–FR-020](../spec.md) with the records in [data-model.md](../data-model.md). Existing gameplay commands and scoring stay authoritative; the optional highscore coordinator owns presentation only.

## Entry points and navigation

| Trigger | Required behaviour |
|---|---|
| Title appears | Start, help, sound and haptics work immediately; an independent refresh may begin |
| Title Highscores action | Open at rank 1; loading/empty/error states can be closed |
| Final-life Game Over | Preserve current final score and local best; begin one fresh qualification read |
| Fresh qualifying result | Open name form with publication notice, Submit and Cancel |
| Successful ranked submission | Dismiss keyboard; show returned snapshot and highlight exact entry UUID; scroll to centre, clamped at edges |
| Fresh non-qualification | Show bottom/last real rank and final score, without requesting a name |
| Qualification lost while entering name | POST returns `notQualified`; explain the changed list and show its bottom |
| Play Again / Return to Title / controller restart | Invalidate current presentation/tasks synchronously or on observed engine transition; no network wait |

Keep game-over navigation outside scrolling or loading content so it remains reachable. Cancelling the name form returns to the normal Game Over actions with no submission. There is no retry-publication action after a transport failure. Cancelling while a POST is in flight does not promise that storage was unchanged.

## Name and submission behaviour

Use the name rules from the data model. Display literal user text, never interpreted markup. The form states in English that the chosen name and score will be visible publicly, with no requirement for a real name. Local validation is advisory; backend validation remains authoritative.

A name-only validation error keeps the form editable; the next explicit Submit is a corrected request after a confirmed validation rejection. Disable Submit while one request is pending. A score/run validation error is terminal. This distinction does not authorize retries after an unknown save outcome. Do not persist unfinished names or payloads for later upload.

## Deadlines, cancellation and failed runs

- Use foreground ephemeral URLSession with connectivity waiting disabled and both request/resource timeouts <=8 seconds. No background session or custom automatic resend.
- Start a separate eight-second coordinator timer for each GET/POST. When it expires, update UI and invalidate the generation immediately, then cancel transport. UI completion must not await a task that ignores cancellation.
- Capture immutable run, presentation source and generation when starting work. Accept a response only while all still match. Leaving Game Over, starting a run, returning to title or backgrounding invalidates them.
- A failed qualification or publication retires submission eligibility for that run. A later read-only refresh, reconnect or relaunch must never produce a name prompt or POST for it.
- Keep the existing UserDefaults best score independent of every remote outcome. A failed request must not set it to the returned list cutoff or remove it.
- If a save was attempted and its response is lost or malformed, say `We couldn't confirm whether your score was saved.` A storage failure known before any attempted save may say `Highscores are unavailable. Your personal best is saved on this iPhone.`
- 429/503 responses may contain Retry-After for service clients, but this game must not schedule a score replay from that header. List refresh remains an explicit read action.

## Snapshot and positioning rules

Use `entryId` for view identity, scrolling and highlighting. Duplicate names and equal scores are valid. Open title browsing at the first real row. Open non-qualification at the last real row, regardless of whether the list currently has 100 entries. A successful submission uses its returned snapshot without an automatic replacing GET.

Apply scrolling after rows exist and after keyboard dismissal. Interior selected rows should be vertically centred; at the start/end use the closest valid position keeping the whole row visible. A subsequent explicit refresh that no longer contains the selected ID explains displacement and opens the bottom. Never highlight another row with the same name or score.

If a session-memory snapshot remains after refresh failure, mark it `Previously loaded — may be out of date.` It is browse-only and must not decide current qualification. Empty means a confirmed empty response, not an error converted into an empty list.

## Layout, accessibility and configuration

Validate landscape iPhone 13 safe areas, software keyboard and Dynamic Type. Rows may grow vertically; do not shrink all text to fixed arcade font sizes. VoiceOver reads rank, name, score and `Your result` when selected. Move accessibility focus to the selected row once after initial result presentation; do not steal focus on every refresh. Close/Play Again/Return to Title must remain reachable at accessibility text sizes.

Read an HTTPS `HighscoreAPIBaseURL` from build configuration for Release. Missing/invalid configuration means highscores are unavailable while gameplay works. Debug-only fixtures or URL overrides support local testing. Allow localhost development transport only in Debug, without disabling Release App Transport Security or accepting arbitrary TLS certificates. Production publication is disabled for autopilot/automation and demo modes.

For automated integration and performance acceptance, provide a separate explicit Debug integration mode using a test-run-owned loopback API backed by isolated Azurite. Allow only the selected local origin, reject redirects leaving it, and never fall back to the production URL. The harness supplies synthetic completed runs and records requests. This exception is limited to that isolated local service; it does not permit automation to publish to production or arbitrary development endpoints. Remove the integration mode and its launch overrides from Release.

## Required deterministic fixtures

Implemented Debug/test fixtures `rank-1`, `rank-50`, `rank-100`, `below-cutoff`, `equal-cutoff`, `empty`, `duplicate-names`, `cutoff-race`, `validation-error`, `unavailable`, `hang`, `slow-stream`, `late-response` and `save-ack-lost`. A fixture service is injected; select these with `-highscoreFixture NAME`, and add `-highscoreCompletedRun` to freeze a synthetic Game Over. They are compiled out of Release.

Provide a Debug-only completed-run fixture so UI tests reach Game Over without automated gameplay publishing to production. Ordinary deterministic fixtures use injected services; only the explicit local integration mode above contacts the isolated real API. Validate ranks at standard/large text sizes, 100 start/restart attempts against hung and normal fixtures, and old-run responses arriving during a new run. Foreground/background and relaunch scenarios must assert no second POST, including after a lost acknowledgement. Physical VoiceOver and keyboard checks complement the automated suite.
