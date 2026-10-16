# Donkey Trump — iPhone release artwork

Created 29 September 2026. Open **START_HERE.html** for the visual overview.

## What is ready

| Folder | Contents | Use |
|---|---|---|
| `01_App_Icons` | Opaque 1024 × 1024 PNG icons in light, dark and neutral tinted appearances; smaller PNG exports | App icon artwork |
| `02_Xcode/Assets.xcassets` | Single-size iOS AppIcon set with appearance variants, two loading-image sets, logo image set, background color | Import into the Xcode project |
| `02_Xcode/Legacy_Alternative` | An alternative iPhone icon catalog with explicit @2x/@3x sizes | Only if the project requires individual-size icon slots |
| `03_Game_Artwork` | Landscape and portrait artwork, 16:9 hero art, transparent logo | In-app loading/start backgrounds and brand artwork |
| `04_AppStore_Screenshots` | Five editable screenshot layouts in English and Danish, at two iPhone size groups, plus assembly script | Add genuine gameplay captures before submission |
| `05_Marketing` | Trailer thumbnail, social link image, portrait poster, story art and square avatar | Website, social and launch promotion |
| `06_Source_Masters` | Original generated PNGs, generation prompts and original dimensions | Future edits and provenance |
| `07_Character_References` | Trump, Jumpman Løkke and Vivian character sheets | Consistent future illustration/video work |

## The remaining submission asset

**No genuine gameplay screenshots were supplied.** The screenshot layouts deliberately contain visible placeholders and are labeled `TEMPLATES_NOT_FOR_UPLOAD`. They are not finished App Store screenshots. Replace them with actual iPhone app captures using the supplied script or editable SVGs.

The generated art is promotional/loading artwork. It does not establish what the running game looks like. Apple guideline 2.3.3 requires screenshots to show the app in use. Likewise, the separately discussed animated teaser is marketing material; an App Store app preview should use video screen captures of the app itself under guideline 2.3.4.

This is an artwork package, not a signed app build. It does not include an app binary, a rendered video, App Store submission, or account-specific release settings.

## Xcode integration

1. Back up or commit the app project before importing assets.
2. Merge the asset sets from `02_Xcode/Assets.xcassets` into your app's asset catalog. Do not replace unrelated existing assets.
3. Select `AppIcon` as the target's app icon source. The modern set contains 1024 × 1024 any/light, dark and tinted entries. The tinted source is grayscale so iOS can apply the user's tint.
4. Use the **modern set OR the legacy alternative**, not both with the same name. The legacy alternative contains iPhone 20, 29, 40 and 60 point slots at @2x/@3x and the 1024 marketing icon.
5. The icons are full opaque squares with no baked rounded mask. Let iOS apply its corner treatment. A flattened PNG catalog is supplied; this is not a multilayer Icon Composer `.icon` document.
6. Use `LoadingLandscape` for the landscape game loading/start view. `LoadingPortrait` is an optional portrait artwork resource; including it does not imply that the game supports portrait play. `DonkeyTrumpLogo` has true transparency.
7. These are runtime loading/start backgrounds. Configure the native system launch screen in Xcode to match your first view; no obsolete `LaunchImage` catalog or forced startup delay is included.
8. Build, archive and validate in your own Xcode project. JSON references and image properties were checked here, but Xcode compilation and App Store validation were not run in this environment.

App icons reach App Store Connect with the uploaded build; simply uploading this ZIP does not set the app icon.

## Exact export sizes

| Asset | Pixels |
|---|---|
| Main app icons | 1024 × 1024 |
| Small icon exports | 180, 120, 87, 80, 60, 58 and 40 square |
| Landscape loading artwork | 2868 × 1320; 2796 × 1290; 2778 × 1284; 2688 × 1242; 2622 × 1206; 2556 × 1179; 2532 × 1170; 2436 × 1125 |
| Portrait artwork | 1320 × 2868; 1290 × 2796; 1242 × 2688; 1170 × 2532 |
| 16:9 hero art | 1920 × 1080 |
| Transparent logo | 1600 × 800; 800 × 400; 400 × 200 |
| Screenshot layouts, 6.9-inch group | 2868 × 1320 landscape |
| Screenshot layouts, 6.5-inch group | 2688 × 1242 landscape |
| Social link | 1200 × 630 |
| Story | 1080 × 1920 |
| Social avatar | 1080 × 1080 |

The landscape scene was recomposed for the wider iPhone aspect ratio, with important characters and title away from the edges. Exact exports use proportional resampling and tiny edge crops where needed; characters are not stretched. The 9:16 Story export contains the complete tall poster with navy side margins.

**Resolution honesty:** generated masters range from 851 × 1849 for the tall composition to 1848 × 851 for the wide one, with 1254 × 1254 icon masters. Several delivery sizes are resampled exports, not native renders at that size. Original dimensions are in `06_Source_Masters/source_dimensions.json`.

## Screenshot workflow

See `04_AppStore_Screenshots/CAPTURE_GUIDE.md`. The 6.9-inch set is the primary iPhone set. The 6.5-inch set is an optional alternative, not an additional mandatory set when the accepted larger set is supplied. Portrait key art belongs with promotional art, not in the gameplay screenshot upload slots.

The script keeps the full authentic capture visible at its original aspect ratio beneath the editorial headline. It never invents or paints gameplay. Layout copy describes the game concept; keep only the captions that accurately reflect the shipped build.

## Design and sources

- Visual direction: warm polished 3D caricature, Arctic scenery, red girders, cyan ladders, gold title and barrel action.
- Character/color lock: Trump red tie; Løkke blue tie; Vivian white outfit with colorful beaded collar.
- Brand colors: midnight `#06162C`, cyan `#22B5C9`, warm gold `#FFD051`, red `#DF3147`, ivory `#FFF5DE`.
- Template typography: DejaVu Sans Bold / regular. Editable SVGs retain live text; install DejaVu Sans or choose your own font before editing. Exported PNGs already contain the intended typography.
- Artwork was generated with the built-in image generator. Technical exports were sized/formatted with ImageMagick; screenshot layout PNGs were rendered from original SVG templates with Inkscape. Full new generation prompts are included.
- No Apple, Pixar or Nintendo logos or App Store badges have been added to the marketing artwork.

## Apple references checked on 29 September 2026

- Screenshot formats, dimensions and transparency rules: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
- App icons and build delivery: https://developer.apple.com/help/app-store-connect/manage-app-information/add-an-app-icon/
- Icon asset catalogs: https://developer.apple.com/documentation/xcode/configuring-your-app-icon
- Accurate screenshots and app-preview footage (2.3.3 / 2.3.4): https://developer.apple.com/app-store/review/guidelines/

Apple's documentation specifies PNG/JPEG screenshot uploads without alpha, with one to ten screenshots. The kit uses opaque RGB PNGs for icons and capture-template previews. Only the reusable brand logo carries alpha. See `VALIDATION_REPORT.md` for the exact package checks.
