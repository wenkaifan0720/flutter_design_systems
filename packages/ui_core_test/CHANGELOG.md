## 0.1.2

- `DesignFieldPartsCheck` holds a field's own parts: each segment of a date or time field keeps its text at least
  4 px from its frame on both sides, and a date field's segments or frame match the height of the button that opens
  its picker, as a stepper's buttons match its field's, within 1 px.
- `DesignFieldSemanticsCheck` holds each control inside a `DesignField` to a node of its own: two controls that a
  tap through the semantics tree reaches as one node fail, as do a stepper's button under a node that takes the tap in
  its place and a field label read more than once.
- List width checks now accept an equally wide field and menu when their painted edges fall between pixels.
- List width checks measure a menu by its painted surface when it draws a frame inside a fill that barely differs
  from the page, instead of by the frame.

## 0.1.1

- Selected-tab fills are measured against the visible tab face, including when a larger touch target surrounds it.
- List width checks follow transparent repaint layers to the page behind the field and its options.
- Row checks measure outlined and bevelled controls against their background and distinguish controls in separate windows.
- Rows on the same surface reuse the captured image and background measurements.

## 0.1.0

The checks a design system's tests run, moved out of ui_core 0.2.1's `package:ui_core/alignment.dart` into a package
of their own, which a design system takes as a dev dependency. Supports ui_core ^0.3.0.

### Moving from ui_core 0.2

- Add `ui_core_test: ^0.1.0` to `dev_dependencies` (and to a gallery example's `dependencies` when a page of it shows
  `DesignKeylineSheet` or `DesignAlignmentSheet`).
- Change `import 'package:ui_core/alignment.dart';` to `import 'package:ui_core_test/ui_core_test.dart';`. Every name
  is as it was: `DesignAlignmentMatrix`, `DesignAlignmentRow`, `DesignAlignmentEntry`, `DesignAlignmentBuilder`,
  `DesignAlignmentTheme`, `DesignInlineControl`, `DesignAlignmentSheet`, `DesignTextEntryCheck`,
  `DesignTextEntryBuilder`, `DesignKeylineCheck`, `DesignKeylineSheet`, `DesignLabelCheck`, `DesignRowCheck`,
  `DesignWidthCheck`, `DesignWidthLimit`, `DesignWidthKind`, `DesignWordBreakCheck`, `DesignClipCheck`,
  `DesignTapTargetCheck`, `DesignCursorCheck`, `DesignShadowClipCheck`, `DesignSpacingCheck`,
  `DesignAlignmentReport` and `DesignAlignmentError`.
- `package:ui_core/alignment.dart` also passed on `DesignSpacing`, `DesignSpacingScope`, `DesignInput`,
  `DesignTapTargets` and `DesignTapTargetScope`; this package does not. They are ui_core's, in
  `package:ui_core/ui_core.dart`, which a look's barrel passes on.

### Fixed since ui_core 0.2.1's checks

- `DesignRowCheck` leaves out a control another surface covers, wholly or in part: a window in front of it, a later
  layer of a `Stack` or an `Overlay`. Where a pointer at its middle, or at the middle of an edge, reaches something
  painted after it that fills there, what is drawn is that surface, not the control's outline. A row left with one
  control is not held. What takes the pointer in front and paints nothing (a barrier with no colour) is no cover.
- `DesignWidthCheck.checkList` reads a list's edges against the page under it. A list drawn in a repaint boundary of
  its own size (a `DesignAnchoredOverlay`'s surface) holds nothing of the page round it in its own pixels, so the
  check took the list's own colour for its ground and a frame line inside the list for its edge (a light list read
  5 px narrower than its field, 2.5 px in on each side).
- `DesignRowCheck` reads a face a look paints itself to every pixel a person tells from the ground, as its outline
  is read (`contrastFloor`). A raised face by night (Retro Platinum: a pale top and left rim, a black bottom and right
  one, on a dialog of #2e2f36) has bottom and right bands within 64 a channel of the dialog, so read by colour it
  stopped 1.3 px short there: its bottom read above its neighbour's, its capitals below the row's line.
- `DesignRowCheck` reads a row drawn in a layer of its own, clear where it stands (a section in a repaint boundary
  over the page), in the layer round it, where what lies under it is drawn too. Read against the clear pixels, taken
  as black, the same black edges were no edge (Retro Platinum's Buttons page by night).
- `DesignWidthCheck.checkList` reads a field drawn in a repaint boundary its own size (a padded `ListView`'s child)
  against the page round it. In its own image nothing of the page is round it, so a field whose rule is its edge had
  that rule read as ground: the field 2 px in on each side as drawn, and its list "2 px out past" it.
- `DesignWidthCheck` leaves out a modal barrier. A dialog's or a sheet's barrier that a tap dismisses is named for a
  screen reader ('Dismiss') and takes taps, so in an app drawn in a repaint boundary it was read as a button as wide as
  the barrier, with no content to need it.
- Every check runs from a navigator (or anything round an `Overlay`) with pages under the top one. A page under an
  opaque route is offstage: never laid out when it was built there, so `DesignCursorCheck` and the others asserted
  "RenderBox was not laid out" on its first transform. The checks read only what is painted: a box never laid out is
  passed by with what it holds, and an overlay's offstage entries too.
- `DesignLabelCheck` reads a label's capitals from the ground under its words, the row of its box nearest the face's
  colour. A chip lit a little on one side of its words (Frosted's chosen filter chip, a sheen 10 a channel lighter
  than its face) stood out by more than a sixteenth of its words' ink in every row, so the capitals read from the
  top of the line box: 30.1 device px high where `DesignCapCenter` gave 25.2, by where the chip stood.
