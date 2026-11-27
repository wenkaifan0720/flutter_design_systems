## 0.2.2

- `DesignWidthCheck` reads a tree's row as a row, not a select: a control that says it is open or closed beside whether it is chosen (`RawTree`'s rows, as a tree's items do) shows its children under it, no menu, so a tree's folder rows across a 960 column no longer read `a select "Projects": a field of a form, 960 px wide …`. A control that says only open or closed is still a select.
- A group of choices drawn on a band of its own (a filled segmented button's strip, round its choices or painted under them by a stack, as Frosted's glass strip is, showing nothing else) is measured by its band for its form: a band on a text entry's edges joins the form, where its choices, 2 px inside the band, read `a group of choices … (at most 320 …)`. A pill under the chosen choice alone, a card round the group or under it that shows more (a title) or holds another control is no band; alone, the group is still measured by its choices' faces.
- A text entry's field is read to the outline drawn round it: from its face (one inside it, or the well round it), the outermost face round that on its rows that holds no other control. A look that draws its outline round the entry's decorator with room at its sides (Comic's ink outline, 18.5 px out from a decorator that paints a fill of its own) now puts a select under it on the outline's edges in the form's column (`a select "Delivery": 344.5 px wide … at most 320` no longer). A card round the field, taller than it, or a band round two entries side by side, is no field's edge.
- A one-line text entry outside any control is a field of its form too: a read-only field (a specimen showing a value, as Frosted's form gallery does) takes no tap, as Flutter's `TextField` drops its tap when read-only, so a group or select under it on its edges read as alone. Selectable text of more than one line is no field.
- A text entry's face is read as laid out, not by the ink in it: an inset groove's lit edge stops its ink 3 px short (Neumorphism's text field and text area, 40..651 drawn in a 40..654 box), and a select under it on the box's edges is a field of the form, not `… (at most 320 from 600 wide)` alone. A surface round it that draws nothing is no edge.
- `checkList` handed a multi-select's text entry holds its list to the groove round the chosen chips and the entry, not to the entry after the chips: the nearest face round the entry and another control (a chip, a combobox's toggle), all of them on the entry's row, read in the image it is drawn in (an entry drawn in a layer of its own inside a painted groove, as Neumorphism's is, read only the entry's layer and found no groove: `720 px wide … wider than the field (423.6)`, `282.3 px out past the field's`). A strip painted round the entry alone is the entry's, not the field's; a card with a control under the field is not it.

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
