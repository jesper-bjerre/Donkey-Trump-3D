# Finish the App Store screenshot set

The included PNGs are **preview templates**, not upload-ready screenshots. Their SVG counterparts are editable. Capture the actual release build on an iPhone or iPhone simulator at the target size, with its real controls and HUD.

Use landscape captures for this landscape-game package:

- Primary 6.9-inch group: **2868 × 1320** pixels.
- Optional 6.5-inch group: **2688 × 1242** pixels.

Do not stretch a capture from another device into these dimensions. The script rejects a size mismatch. If your UI differs on another size, capture that size separately.

## Capture list

| Filename | Capture from the real app | Editorial theme |
|---|---|---|
| `01-overview.png` | A clear view of active gameplay and the objective | Jump into the chaos / Hop ind i kaosset |
| `02-barrels.png` | A real barrel-dodging or jumping moment | Dodge the barrels / Undvig tønderne |
| `03-climb.png` | A climbing section that shows the level route | Climb to the top / Klatr mod toppen |
| `04-rescue.png` | The implemented rescue objective or approach to Vivian | Rescue Motzfeldt / Red Motzfeldt |
| `05-challenge.png` | A different genuine action moment | Jump. Climb. Survive the chaos. |

Keep only images and claims that are present in your shipped app. No multiplayer, achievements, highscore systems or other unverified features are implied. One to ten screenshots are accepted by Apple; you may use fewer than these five.

## Generate the finished PNGs

Requirements: Python 3, Inkscape CLI, ImageMagick CLI. Put your genuine PNG captures in one folder using the names above.

From the package root:

```bash
python3 04_AppStore_Screenshots/build_screenshots.py \
  --captures /absolute/path/to/real-captures \
  --locale en --device 6.9 \
  --output /absolute/path/to/finished-en
```

For Danish, change `--locale en` to `--locale da` and use a different output folder. For the smaller set, change `--device 6.9` to `--device 6.5` and supply captures from that device size. The script skips missing captures, refuses to overwrite outputs, replaces the placeholder area, and removes the template notice only for files with a real input image.

Inspect every finished output before upload. All gameplay must remain legible, including any touch controls; all captions must be true. Upload finished PNGs to the corresponding App Store Connect display group. Do not upload the SVGs or files under `TEMPLATES_NOT_FOR_UPLOAD`.

The marketing poster and animated trailer concept are separate promotional assets. They are not substitutes for real gameplay screen captures.
