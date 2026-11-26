## 0.2.1

- `DesignWidthCheck` reads a text entry on the layer its field is drawn on: an entry drawn in a repaint boundary no larger than its field (Flutter's `TextField` paints its `EditableText` in one, each field its own) is read in the layer round it, its face the one inside it or the well drawn round it. A select under text entries now takes their form's column (`a select "Delivery": 344.5 px wide … at most 320` no longer, for a column of 344.5); one under an entry in a larger layer of its own (a card's) still keeps to its content.

## 0.2.0

- `DesignWidthCheck` holds a form's fields as a column. A select (a date field among them), a segmented control or a group of choices with another field over or under it on the same edges (a text entry, or another of these) takes the form's column, as Material's fields do, and the column is held to `formWidth` (720 by default; `a select "Shelf": a field of a form, 1392 px wide as laid out, 1392 as drawn (a form keeps to 720 from 600 wide)`). One alone, with no field on its edges (a toolbar's filter), still keeps to its content, at most `maxWidth`. A look that set a limit of its own so its form's fields could fill their column drops it.

## 0.1.0

- The layout review leaves ui_core_test 0.2.0 for this package, in the repository alone (`publish_to: none`): the
  alignment matrix and its sheet (`DesignAlignmentMatrix`, `DesignAlignmentRow`, `DesignAlignmentEntry`,
  `DesignAlignmentBuilder`, `DesignInlineControl`, `DesignAlignmentSheet`), `DesignTextEntryCheck` and
  `DesignTextEntryBuilder`, `DesignKeylineCheck` and `DesignKeylineSheet`, `DesignRowCheck`, `DesignWidthCheck`,
  `DesignWidthLimit` and `DesignWidthKind`, `DesignSpacingCheck` and `DesignFieldPartsCheck`, unchanged. They encode a
  look's own grid and taste, not what is wrong in any design, so each look holds them to its own numbers.
- The library re-exports ui_core_test: a test that takes a review check imports
  `package:ui_core_review/ui_core_review.dart` in place of `package:ui_core_test/ui_core_test.dart`.
