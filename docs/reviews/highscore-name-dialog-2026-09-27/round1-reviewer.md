# Independent review: name-entry dialog redesign

**Verdict: REQUEST_CHANGES.** There is one blocking finding (F1) and one context request (C1).

I did not run any builds or tests and saw no screenshots. This review relies only on the supplied source, the diff, the log excerpts and the lead's summary.

## Blocking finding

### F1: Submit, Cancel and the name field look much larger than the area that responds to taps (Medium-High, blocking for this UI task)

**Where**
- `src/DonkeyTrump3D/UI/HighscoreNameEntryView.swift:88-98` (Submit)
- `src/DonkeyTrump3D/UI/HighscoreNameEntryView.swift:100-113` (Cancel)
- `src/DonkeyTrump3D/UI/HighscoreNameEntryView.swift:64-78` (name field)
- The same pattern appears in `src/DonkeyTrump3D/UI/HighscoreListView.swift:121-129` (compact icon buttons)

**Cause**
- Each button label is a `Text` inside `.frame(maxWidth: .infinity, minHeight: 48)` plus padding, using `.buttonStyle(.plain)`.
- The yellow or translucent fill is applied with `.background(...)` outside the `Button`.
- SwiftUI treats the transparent parts of a frame or padding as non-hittable unless `.contentShape` is set. A plain-style button responds only to taps on its label's content. A background attached outside the `Button` is not part of the button's gesture.
- So only the "Submit" and "Cancel" text rectangles respond to taps, roughly one text line high (about 20–22 pt at default size). The visible 48 pt rounded rectangles do not.
- The name field has the same problem. Tapping the white 12 pt vertical and 14 pt horizontal padding will not focus the field.
- The compact icon buttons are 44×44 frames with default style and no `contentShape`. Only the glyph responds.

**Impact**
- The task's core requirement is an obvious dialog with a clear Submit button.
- A player tapping near the edge of the large yellow Submit area gets no response. The effective target is below 44 pt.
- This conflicts with the requested design and with Constitution I ("reachable actions").

**Why the tests miss it**
- XCUITest's `tap()` and `isHittable` both use the element's centre point (`HighscoreUITestSupport.swift:35`, `HighscorePublicationUITests.swift:11-12, 35-37`). The centre is exactly where the text sits.
- The accessibility frame reports the full label frame, so every current assertion passes whether or not the edges respond.

**Reproduction or disproof** (my conclusion comes from SwiftUI hit-testing rules, not an executed check)
1. After the layout settles, tap `app.buttons["highscoreSubmit"].coordinate(withNormalizedOffset: CGVector(dx: 0.08, dy: 0.15)).tap()`.
2. Assert that the submitting state or result appears.
3. Repeat for Cancel. Returning to Play Again should mean no POST was sent.
4. For the name field, tap at `(dx: 0.5, dy: 0.1)` and assert that the keyboard or focus appears.
5. Run these at default size and at AXXXL.

**Suggested fix**
- Add `.contentShape(RoundedRectangle(cornerRadius: 10))` to both labels. Alternatively, move the fill inside the label and add the content shape.
- For the field, make the padded white box focus the field, for example with `.contentShape(...)` and `.onTapGesture { editing = true }` on the padded container.
- Add `.contentShape(Rectangle())` to the three compact icon labels.
- Then rerun Publication, Failure, Nonqualification and Browsing. Browsing matters because `HighscorePanel`'s footer is shared.

## Context request

### C1: Remaining references to the removed notice

Please provide the output of a repo-wide search over `src/`, `specs/`, `docs/` and `README.md`, for example:

```
rg -n "publicScoreNotice|will be public|real name|public-name notice|publication notice"
```

This covers two risks I cannot check from the packet:

1. **Unit test compilation.** If `DonkeyTrump3DTests` references `Copy.publicScoreNotice`, it will no longer compile. It is not clear that `-only-testing:DonkeyTrump3DUITests/...` built that target.
2. **Stale behaviour descriptions.** `plan.md` (its Constitution Check for Principle IV), `data-model.md`, `quickstart.md`, `README.md`, `docs/prd_spec.md` or `docs/backlog.md` may still say the form shows the notice. Constitution V requires documentation to describe actual behaviour. Dated historical entries in `validation.md` can stay as they are.

If there are no current-behaviour hits, C1 is resolved with no finding.

## Assessment of the rest of the scope (no other material findings)

**Owner directive and Constitution IV**
- Principle IV requires an explicit publication action and an explanation of what is public. It does not say where the explanation must appear.
- `Copy.privacy` (`Copy.swift:21`) still says the chosen name and score become public, and it is shown in How to Play (`RootView.swift:198`).
- Submit remains the explicit action, and the owner's instruction is authoritative.
- I therefore see no constitution conflict, subject to C1's check of the plan's gate text.

**Behaviour preserved**
- **Submit:** there is still an explicit Submit; `publish()` resigns the keyboard and then calls `submit`.
- **Validation and errors:** inline validation still works, and `highscoreNameError` is kept.
- **Cancel:** Cancel still calls `coordinator.cancel()`.
- **Pending state:** while a request is pending, the form is replaced by the `.submitting` progress view.
- **Coordinator:** there are no coordinator or backend changes.

**State and identity**
- The `name` draft and focus should survive the compact/regular switch. `AnyLayout` keeps child identity.
- The panel's `if !compact` header is an optional slot, so the `Group` and switch identity are stable.
- An error re-entering `.enteringName` hits the same switch case, so the draft is kept.
- There is no layout feedback loop. Both size thresholds read `GeometryReader` sizes that do not depend on the dialog's content, because the dialog sits in a `ScrollView`.

**Navigation**
- The compact footer keeps Play Again, Return to Title and Close. These have accessibility labels, and the `highscoreClose` identifier is never duplicated at the same time.
- Game-over navigation stays outside the scrolling content.

**Test-support fix**
- `waitForNameFormLayout` requires stable frames for 0.5 s, controls inside the window and above the keyboard, and hittable controls. This is a reasonable response to the ui-final lost-ack failure, which tapped Submit mid-animation.
- It would fail, not hide, a layout that keeps moving.

**Evidence**
- Final app source passed all 14 relevant UI scenarios across two runs: Browsing in ui-final, the other 11 in ui-stable. That is acceptable, but it is not one clean run.
- The transport-boundary test skips without its environment variable. Its helper substitution is compile-covered because the UI test target built.

## Non-blocking notes (no change required)

- **N1:** `testLargeNameFormKeepsKeyboardAndNavigationUsable` re-taps the field after each rotation (`HighscorePublicationUITests.swift:32`). It therefore cannot detect whether rotation drops keyboard focus. It does prove the draft is kept and the controls stay reachable after re-focusing. Record this as a limitation.
- **N2:** The non-compact footer now applies `.foregroundStyle(.primary)` in every panel state (`HighscoreListView.swift:146`). This slightly recolours bordered and icon buttons outside the name form. The change is cosmetic only.

## Limitations

- **Hit-testing claim:** F1 is based on reasoning about SwiftUI hit-testing semantics. It was not executed, so the reproduction above should confirm or disprove it.
- **Evidence scope:** there was no physical device, no VoiceOver session and no pixel review. I did not see `plan.md`, `validation.md`, `README.md`, `data-model.md`, the unit test sources or the fixture service.
- **Next round:** after F1 is fixed and C1 is answered, send a focused re-review packet containing the updated diff, manifest and test evidence.
