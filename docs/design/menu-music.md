# Loading and menu music

The owner supplied the three `Donkey Trump 2` files in [music](music/) and explicitly
requested their use for loading and menu playback on 2026-09-27. This records that
project authorization, not an independently verified third-party licence.

The app bundles an unchanged copy of `Donkey Trump 2.mp3` as
[`menu-music.mp3`](../../src/DonkeyTrump3D/Resources/Audio/menu-music.mp3).
Inspection with macOS `afinfo` found stereo MP3 at 48 kHz, approximately 71.6 seconds
and 1.7 MB. The supplied `.m4a` contains Opus rather than AAC, with duration reported
as zero by `afinfo`; the PCM WAV is about 13 MB. MP3 provides a compact supplied
asset that is verified to decode with the app's `AVAudioPlayer` path, without
transcoding or adding a decoder dependency. Original files remain unchanged.

The track prepares first on the existing background audio queue. Once ready and
the app is active, it loops continuously across the runtime loading cover, title
menu, help and highscores opened from that menu. It does not delay the first frame
or wait for the backend. The system's static launch storyboard cannot execute
audio code; playback starts once the app is running, active and the player is ready.

Starting the intro stops the menu track. Intro effects and gameplay music retain
their existing roles. Returning to the title starts the menu track again. Leaving
the active app pauses it; returning resumes only if the menu is still requested.
Late audio preparation cannot restart a departed menu or play it in the background.

The existing Sound setting controls its volume, including changes during loading.
The existing playback audio-session category is retained for sound in silent mode.
Physical silent-switch and speaker/headphone listening checks remain device checks;
simulator decoding/playback-state tests do not establish acoustic quality or release
acceptance on a physical iPhone.
