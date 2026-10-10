# Package validation

Checked 29 September 2026.

- 88 PNG images and 5 JPEG images fully decoded successfully.
- All app-icon exports are opaque RGB; primary light/dark/tinted icons are exactly 1024 × 1024.
- Full-bleed icon artwork has no baked rounded-corner mask.
- Transparent logo files contain a real alpha channel, with both transparent and opaque pixels.
- Filename-based export dimensions match the actual image dimensions.
- 20 editable screenshot SVGs parse successfully.
- 10 JSON documents parse; every Xcode image filename points to an existing file.
- Twenty screenshot layouts cover five concepts × two languages × two display-size groups.
- Screenshot template PNGs are opaque RGB, with exact 2868 × 1320 or 2688 × 1242 canvas sizes.
- Capture rectangles preserve the corresponding device aspect ratio to rounding precision.
- The screenshot assembly script was run successfully with one internal, clearly labeled calibration image at 2868 × 1320. This fixture is not included in the package and is not gameplay.
- English and Danish template layouts were visually inspected. Generated icons, logo and key art were visually reviewed.
- SHA256SUMS.txt records every final package file other than itself.
- The final ZIP is reopened and each member CRC is verified by the packaging script.

## Boundaries

No genuine gameplay screenshot or app-preview movie is included. No iOS app binary was supplied, so actual display behavior, Xcode compilation and App Store review have not been tested. The source dimensions and resampled exports are documented in README.md.
