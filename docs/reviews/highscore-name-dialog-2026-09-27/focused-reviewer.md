# Focused re-review: name-entry dialog, F1 and C1

**Verdict: APPROVE**

I reviewed only the dispositions of F1 and C1 and the final diff. I did not execute any checks or see any pixels. My conclusions rest on the supplied source, the diff, the manifests, the search output and the `ui-edge.xcresult` log excerpt.

## F1: tap targets smaller than the visible controls. **Resolved.**

**Source check**
- **Submit and Cancel** (`HighscoreNameEntryView.swift:91-95, 107-111`):
  - `.contentShape(RoundedRectangle(cornerRadius: 10))` now comes after the frame and horizontal padding, inside the label. The hit shape therefore covers the whole padded label.
  - The outer `.background` is laid out on the Button's own bounds, which equal the label bounds. The visible fill and the tappable area now match.
- **Name field** (`HighscoreNameEntryView.swift:70-75, 84`):
  - The content shape is applied after the padding, the 48 pt minimum frame and the white background.
  - `.onTapGesture { editing = true }` drives the only `.focused($editing)` binding, so a tap on the padding focuses this field.
  - The overlay stroke has `allowsHitTesting(false)`.
- **Compact icons** (`HighscoreListView.swift:121-132`): the 44×44 frame is followed by `.contentShape(Rectangle())`, so the full target responds.

**Test evidence**
- The edge taps land inside the rounded shape, not in the corner cut-out. The Submit and Cancel offset (0.08, 0.15) is about 7 pt down and more than 10 pt in on these buttons.
- The field tap at `dy: 0.1` lands within the 12 pt vertical padding, below the intrinsic `UITextField`. It therefore exercises the new focus path.
- Coverage by size:
  - **Default size:** Submit (invalid-name path), Cancel, and the field in all three rank tests.
  - **AXXXL:** Submit and the field in the rotation test. Cancel and compact Close, with the keyboard up, in `testLargeNameFormCancelAndCloseEdges`.
- All 15 tests passed in the single `ui-edge` run, including Browsing 3/3. That covers the shared panel footer.

**How to record F1**
- The original defect was never reproduced against the pre-fix code.
- Record this as a **defensive fix with regression tests**, not as a "confirmed defect fixed". The new tests pin the correct behaviour going forward. They do not prove the old code failed.

## C1: remaining references to the removed notice. **Resolved, no change needed.**

**Unit test compilation risk:** closed.
- The search over `src/` finds no remaining `publicScoreNotice` symbol reference.
- The only hit in current source is `HighscorePublicationUITests.swift:10`, which asserts that the literal old text is *absent*. That is intended.

**Stale behaviour descriptions:** none found.
- Every other hit is in dated review packets or diffs (`*/reviews/*`). Under AGENTS.md and Constitution V, those stay tied to the content they reviewed.
- Current documents describe actual behaviour:
  - `README.md:30`: "optional public-name entry"
  - `docs/prd_spec.md:141`: "optional public name"
  - `docs/production-smoke-and-rollback.md:153`: updated
  - `spec.md` FR-008 and scenario 2: updated
  - `ios-flow.md`: updated
  - `tasks.md` T016 and T023: updated

**`plan.md:48` ("explicit public-name consent")**
- This does not claim that the form shows a notice.
- Constitution IV is still met at the same level I accepted last round:
  - Submit is the explicit action.
  - `Copy.privacy` (`Copy.swift:21`) still explains what becomes public.
  - The owner's directive is authoritative under Governance.

## N1 and N2

I accept both dispositions: N1 is recorded as a limitation and N2 needs no change.

## New material findings

None.

## Limitations

- **Untested field interactions:** tap-to-place the cursor and double-tap selection inside an already-focused field. These run alongside the new `onTapGesture` and were not exercised. They matter little for a name of at most 20 characters, and I do not consider them material.
- **Compact icons:** only compact Close was edge-tapped. Play Again and Return to Title use the same pattern.
- **Out of scope:** the non-compact header Close is a small glyph. It predates this task and I did not review it.
- **Environment:** simulator only (iPhone 13, iOS 27). There was no physical device, no VoiceOver session and no pixel review. The redirect integration test was compile-covered only. Nothing was deployed.
- **Lead's remaining duty:** the review record, with configuration, manifests, dispositions and this verdict, still has to be written as AGENTS.md requires. It was not part of this packet.

## Consensus statement

- F1 is resolved: all visible targets now respond across their full area, and edge-tap regression tests cover default size and AXXXL.
- C1 is resolved: no stale current-behaviour references and no dangling symbol.
- No important in-scope findings remain.
- The requirements are satisfied: the in-form notice is removed, the dialog, input and Submit are clear, there are no backend changes, and privacy/help copy is still accurate.

I approve. Once the lead explicitly agrees, review consensus is complete for this task.
