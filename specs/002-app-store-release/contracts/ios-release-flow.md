# iPhone release behavior and validation contract

## Preserve existing play and startup

- Retain native 3D gameplay, iOS 26 minimum, landscape left/right, local personal
  best, Reduce Motion, sound and haptics. iPhone 13 is the physical acceptance target.
- Cover keeps its full motif/proportions. Approximate progress exists only while
  required local startup is incomplete. No minimum timer; optional audio/highscore
  work never gates Start or first-frame readiness. Static system launch art cannot
  execute music. Supplied MP3 loops when ready across runtime loading/title/overlays,
  respects mute/activity and stops before intro/game, including late preparation.
- Retain clear name dialog/input/Submit/Cancel and no public-name/real-name reminder.
  The accessible help/privacy view explains public name/score publication and links
  to the actual published policy. Keep explicit Submit and current local-best/no
  deferred-upload semantics. Do not let a blocked publication disable gameplay.
- Global list remains top 100 with low-scoring starters keeping at least ten entries
  in a successful response. This is not ten rows simultaneously visible. Existing
  centering/bottom positioning, stale/error states and large text/VoiceOver remain.

## Reporting UI

Each list entry has an accessible Report action reachable without relying on a tiny
icon/swipe-only gesture. Label it with that row's displayed name/rank. An action
opens a compact landscape form with reason picker, Send, Cancel and support link.
No login/contact/free-text field. Keyboard is unnecessary. VoiceOver focus moves to
form heading, then completion/error message; all controls remain reachable at large
text sizes and both orientations. Do not alter ranking after merely reporting.

The app allocates a report ID before sending, uses the stable installation credential
and a foreground <=8-second deadline. Immediate navigation and Play Again remain
available. Success shows receipt/status; uncertain write says it could not confirm
and offers explicit read-only Check Status with the same ID. Closing/backgrounding
invalidates the request generation. Never convert uncertain failure into “not sent”.
A late response cannot present over gameplay or a different report.

A small Reports section in the help view lists up to 20 locally held receipt IDs
with generic time/status, without retaining reported names. Opening/checking fetches
only that credential's receipt. It is not a background queue or public report feed.
Expired/not-found receipts are removed locally with an honest expiry message. A
pending report and one already acknowledged/resolved remain distinguishable. Owner
responses are fixed disposition text, not an unmoderated message channel.

## Publication through the current API

Use the existing `/api/v1` routes and canonical secret header. If secret storage fails, keep public
browsing and offline play working and report publication unavailable. Never rotate
an existing credential because the API returned blocked/invalid. A generated secret
is reused across name corrections and all later runs on that installation.

`name_rejected` leaves only the active run's name form editable; another chosen name
can be explicitly submitted. `publication_blocked`, removed/conflicting run IDs and
transport/unconfirmed failures retire publication for that run, preserving local
best. Refresh/reconnect/relaunch never sends a retired score. Headers must not leak
through redirected requests or diagnostics. Existing URLSession/coordinator deadline,
explicit generation and immutable-run boundaries apply equally to the new report flow.

## Release-only boundaries

1. Check existing store device-support history before changing app target to device
   family 1. Do not silently expand native iPad scope if narrowing is disallowed.
2. Distributable `Release` always resolves the PROD HTTPS backend; preserve existing
   Local/DEV/PROD development schemes. Add non-distributable `AppStoreCapture` simulator
   configuration/scheme with Release optimizations and no DEBUG, test flags, synthetic
   run controls or development launch arguments. Its sole product-setting difference
   is HTTPS base URL `https://donkeytrump-api-d.azurewebsites.net/capture` (isolated
   dataset defined in store contract). Enforce simulator-only build and archive/export
   rejection for AppStoreCapture; distribution validation requires Release + exact
   PROD URL and no capture host/path. HTTP loopback exceptions stay Debug-only.
3. Add privacy/support URL configuration and validate HTTPS/live anonymous access.
   Keep both links reachable from title/help and Game Over/report error paths.
4. Audit required-reason APIs/dependencies, include a correct app privacy manifest
   and inspect archive/privacy report. UserDefaults reason CA92.1 covers only actual
   app-private preferences; enumerate any additional required-reason access.
5. Perform actual encryption questionnaire before setting export-compliance metadata.
   No invented accessibility support flags; declare only the interactions tested.

## Required evidence

Automated Swift/URLProtocol tests: credential stable across runs/upgrades and atomic
storage, corruption fails closed, canonical header/no cross-origin redirect, payload
privacy, all moderation/error mappings, stale response cancellation, report status
ownership/expiry, no automatic POST retries. Injected fixtures remain Debug-only and
cannot hit PROD. Test names/body never enter normal diagnostics.

UI tests on iPhone 13 simulator: initial cover/progress/music state, title/Start while
backend hangs, name rejection/edit and block, report reason/Send/Cancel/status/support,
Game Over navigation, keyboard/large text/VoiceOver labels. Audio-state tests complement,
not replace, physical listening. Repeat production build/argument isolation checks.

Physical iPhone 13 on the exact processed internal TestFlight build: both landscapes,
clean install and supported update, 15 minutes sustained play, intro skip, menu music,
silent switch, in-game mute, headphones/speaker, haptics, background/foreground,
VoiceOver and largest supported text for applicable UI, online real publication,
multiple devices/runs, failed/lost-ack submission and report/owner-response flow.
Record build/device/OS/date/check results. Existing-build update is marked not
applicable only with evidence that no prior install/distribution path exists.

Also perform a labelled iPad simulator compatibility-mode smoke test on an iPhone-only
build: launch, both landscape presentation, reachable controls, highscore/report/privacy.
This does not imply native iPad support or physical iPad acceptance. Failed applicable
checks block draft readiness, while independent asset/copy preparation can continue.
