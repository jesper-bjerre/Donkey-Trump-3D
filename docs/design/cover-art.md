# Donkey Trump cover artwork

Added to the app's launch/loading screen at the owner's request on 2026-09-26.

## Source and intended use

- Source: [DonkeyTrumpCover.png](images/DonkeyTrumpCover.png), supplied by the owner.
- PNG, 1672 × 941 pixels, opaque, landscape. Preserve this master unchanged.
- The owner describes it as generated from the prompt below. The generation tool/model, date and its licensing terms were not supplied; the prompt records provenance and intent, not a legal clearance.
- The prompt identifies the intended satirical characters as Donald Trump, Lars Løkke Rasmussen ("Jumpman Løkke") and Vivian Motzfeldt. Its references to the original arcade game describe visual inspiration; the implemented product remains the native 3D game.

## App behavior

The asset catalog bundles a byte-identical copy as `LaunchCover`. [LaunchScreen.storyboard](../../src/DonkeyTrump3D/Resources/LaunchScreen.storyboard) shows the complete illustration proportionally inside the safe area over a dark navy background. Both Debug and Release use that system launch screen while the app starts. A visible “Loading…” label and a partially filled progress bar appear on the native launch screen. After the app takes over, the same artwork has a moving, approximate progress bar until SceneKit reports its first rendered frame. The bar indicates activity rather than a measured percentage. There is no artificial minimum display time, download or tap-to-continue gate; readiness removes the cover immediately without waiting for the bar to finish. Audio-player preparation runs on a background queue and does not delay the first screen. One-shot sounds that occur before audio is ready are skipped; active loops/music follow the latest requested state, including stop, skip and pause. Highscores are fetched asynchronously when the list is opened; a slow or unavailable backend does not delay startup or Start Game. The system dismisses it when the app is ready; returning from the background may show the app's own saved snapshot instead.

The title menu, interactive 3D scene and intro remain the game's normal next screens. The illustrated cover is a distinct piece of key art and does not claim to depict the rendered 3D gameplay.

See [validation evidence](cover-validation.md) for the simulator captures, build checks and remaining physical-device release checks.

## Possible App Store use

Retain the image as a candidate for decorative framing or supporting promotional artwork around genuine gameplay captures. It is not itself an App Store gameplay screenshot or a replacement for the required in-use screenshot set. Apple requires screenshots to show the app in use, rather than merely title art or a splash screen; image/text overlays may support the actual app capture. See [App Review Guidelines 2.3.3](https://developer.apple.com/app-store/review/guidelines/#accurate-metadata).

The current master is not automatically a correctly sized screenshot for the required large-iPhone display slots, and this task does not resize it into or upload a store asset. During release preparation, inspect the resulting composition at its submitted size, retain truthful 3D imagery, and complete the content/provenance assessment already required by [FR-006](../../specs/002-app-store-release/spec.md). The cover does not replace the app icon.

## Owner-provided generation prompt

The prompt is retained as supplied, including its original spelling and line-break notation:

```text
create et image, a landing page / game start screen\
for my game
"Donkey Trump"\
**ivian Motzfeldt (født 1972):** Grønlandsk politiker, Lars Løkke Rasmussen og Donald Trump skal være på forsiden. De skal være tegnet i donkey kong stil, skal være satirisk.
Spillet er det gamle klassiske Donkey Kong spil. Spillet skal hedde “Donkey Trump”.
Jumpman skal se ud som den danske udenrigsminister Lars Løkke Rasmussen (tegnet). Han skal hedde “Jumpman Løkke” i spillet.
Han skal redde “Motzfeldt” som står på toppen i hvert level.
Donkey Kong skal ligne en sur Donald Trump (tegnet).\
Lars Løkke er jumpman. Motzfeldt skal reddes.
```
