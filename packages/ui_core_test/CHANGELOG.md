## 0.5.0

- **Breaking:** needs ui_core 0.7.0. `DesignTapTargetCheck`'s touch floor, read from `RawTapTargets.fallback` where no `RawTapTargetScope` declares one, is 40 by 40 (was 44); a look that declares its own floor is held to it, as before.
- `DesignFaceInsetCheck`: a filled or outlined control face keeps its label's ink at least 4 px inside its edges (`minimum`), the least Material's buttons, chips and segments keep at any text scale; a label with no room above, below or beside it is named, with the edge and the distance. Faces that hold nothing in (an underline, a rule at one side), text entries and badge counts are not read; heights are read from Latin letters and figures, so accents and other scripts don't count as ink at the edge. It reads pixels as `DesignLabelCheck` does, so a face's own painting (a gradient under the words, a bevel or an outline along its edge) is not ink, nor is what shows past a round face's curve inside its box (the page in a circle's corners, read from its pixels when its own painter draws it, filled or outlined), nor an outline's softened edge where a straight top starts to curve, nor an outline a face's own painter draws (read from its pixels where no decoration declares it, on a page or on nothing); the room is counted from the face's outer edge, outline included; it reads only the edges a face shows (one that runs on into the face's colour, as a text button's on its page, a row's on its card or a tab's into the key drawn on past it, holds nothing in) and only a face the screen shows whole; words across one of a face's edges by more than a quarter of their line (a legend on a frame's outline, a day's number on a range's band) are not held in by it, and a face less than half their em high (a band drawn through them) holds nothing in; and words in the test's own font ask for the look's fonts, as `DesignLabelCheck` does.
- `DesignLabelCheck` names a one-line label laid out in a box taller than its line and drawn at that box's top, and says how to fix it: let the box hug the line (`RawControlBox` centres it). A label `RawCapCenter` centres, as ui_core 0.7.0 does, passes.
- `DesignDialogActionsCheck` reads the dialog's actions, the controls with their words drawn last, over a page whose own controls say the same words; it took the first on screen, and named the page's controls' layout as the dialog's.

## 0.4.0

- **Breaking:** needs ui_core 0.6.0.
- The checks name ui_core's 0.6.0 names in their messages and docs (`RawTapTargets`, `RawTapTargetScope`, `RawInput`); the checks keep their own names.

## 0.3.0

- **Breaking:** needs ui_core 0.5.0.
- `DesignOverlayCheck`: each open overlay (a popover, a menu, a list, a picker, a sheet, a dialog) shows whole. All it paints stands on the screen; no control and no line of words in it is cut, as `DesignClipCheck` reads them; and a grid in it (a month, swatches) doesn't shrink and scroll where the other side of its anchor holds it whole, nor scroll sideways by less than one of its controls. A list may shrink and scroll (`DesignListSideCheck`). It reads layout boxes.
- `DesignOverflowCheck`: no row or column holds more than it has room for, the fault large text brings out; run it at text scale 2 too. It reads layout boxes, so it holds where an app's error handler swallows Flutter's overflow report.
- `DesignDialogActionsCheck`: a dialog's or a sheet's actions stand in one row, or else in one column of one width with the confirming action on top and the dismissive one at the foot; never some side by side and one under them. It reads layout boxes and the labels on them.
- `DesignFieldWordsCheck`: a text field's help and error are read with the field (on its node or inside it), as Material's `TextField` reads them, not on a node beside it. It reads the semantics tree.
- `DesignClipCheck` and the new checks share their reading. It reads a line by its words, run between spaces, so the space a wrapped line broke at is not read as cut: a right-to-left paragraph sets that space past its start edge, where nothing is drawn, and left-to-right words wrapping in one (a label at 2x text) were named `cut at their right` by the width of a space. Its other reports are unchanged.
- `DesignRadioGroupCheck` reads a group's own radios, the nodes its widgets make, not another group's drawn over its place: a sheet's group over a page's group was read as the page's, and the page's keys judged by it (`Down moves to "Conditioning" but does not choose it` where both groups worked). A group behind a modal route's barrier, out of the semantics tree, is out of reach and passes unread, where it read as `a group of 0 radios`. Focus outside the group's widgets is outside the group.
- The checks read a line's baseline afresh, in the fonts the engine has now, as ui_core 0.5.0's `DesignCapCenter` does: a font loaded after a test's first frame no longer fails Flutter's dry-baseline check.
- `DesignListSideCheck` holds a popover to its placement's own rule, as `RawPopover` places it: its `preferredExtent` is the least the room below must hold, and a surface placed with `RawPopoverFit.whole` (a month, a grid) needs its whole extent below, so one that fits whole only above opens there and passes. Before, 200 px below was the rule for all, and a 300 px month that opened above a field with 250 px below was named.
- `package:ui_core_test/guidelines.dart` adds `overlayGuideline` and `overflowGuideline`.

## 0.2.1

- `DesignTooltipNodeCheck`: each tooltip is on the node of the control it tips, so a screen reader reads the tip with the control, as Flutter's `Tooltip` gives it. A `Semantics(tooltip:)` round a button that keeps its own node fails. It reads the semantics tree.
- `DesignListSideCheck`: each open list that asks for below (a `RawPopover` placed below, an autocomplete that opens down or on the side with most space) opens below its field while the room below holds it, or 200 px of a longer one. It reads layout boxes.
- `DesignFieldNodesCheck`: a text field keeps its semantics nodes as its text goes from empty to a letter: its text entry is the same node, and no node it had goes or changes role (a clear key that shows is a node added). A test reads the fields, types, then checks them. It reads the semantics tree.
- `package:ui_core_test/guidelines.dart` adds `tooltipNodeGuideline` and `listSideGuideline`.

## 0.2.0

- **Breaking:** needs ui_core 0.4.0. `DesignRadioGroupCheck` checks any group of radios,
  Flutter's `RadioGroup` with `RawRadio` and ui_core's `RadioGroupKeyboardFix` among them.
- **Breaking:** the layout review leaves this package, which keeps the checks of what is wrong in any design. The
  alignment matrix and its sheet (`DesignAlignmentMatrix`, `DesignAlignmentRow`, `DesignAlignmentEntry`,
  `DesignAlignmentBuilder`, `DesignInlineControl`, `DesignAlignmentSheet`), `DesignTextEntryCheck` and
  `DesignTextEntryBuilder`, `DesignKeylineCheck` and `DesignKeylineSheet`, `DesignRowCheck`, `DesignWidthCheck`,
  `DesignWidthLimit` and `DesignWidthKind`, `DesignSpacingCheck` and `DesignFieldPartsCheck` hold a look's own grid and
  taste; they are no longer published. A test that used one keeps it from the design systems repository.
- `DesignTextFieldNameCheck`: each text field on a screen says a name (a label, a hint or a tooltip) on its own node,
  so a screen reader does not read it as "text field" alone. It reads the semantics tree.
- `package:ui_core_test/guidelines.dart` offers the behaviour checks as Flutter accessibility guidelines, beside
  `androidTapTargetGuideline`: `await expectLater(tester, meetsGuideline(checkableRoleGuideline))`, with
  `fieldSemanticsGuideline`, `textFieldNameGuideline`, `tapTargetReachGuideline`, `cursorGuideline` and
  `labelPlacementGuideline`. The package now depends on flutter_test for them; its main library imports none of it.
- Each check's documentation says whether it reads layout boxes and the semantics tree, or the drawn pixels.

## 0.1.4

- `DesignRowCheck` reads the edge of a raised face that matches its background from its cast light and shadow.
- The package metadata links to the design systems documentation.

## 0.1.3

- `DesignRowCheck` gives an edge's offset "as laid out" from the faces' boxes, not their painted ink, and beside a
  bevelled face, whose painted edge it cannot read, holds the row as laid out only.
- `DesignFieldSemanticsCheck` reads a date or time field's segment, a node that steps and takes a tap, as one control:
  a typed date inside a `DesignField` no longer fails.
- `DesignFieldSemanticsCheck` takes a button's own name (a search field's Search) as the button's, not as a reading of
  the field's label. A node that merges several controls is still read line by line.
- `DesignRadioGroupCheck`: a group of radios is one tab stop that lands on the chosen radio, and its arrow keys move
  to the next radio that can be chosen, round the group, and choose it (Left and Right swapped right to left), as
  Flutter's `RadioGroup` does.
- `DesignCheckableCheck`: each checkbox, radio and switch on a screen says what it is: a node that says it is checked
  or toggled does not also say it is a button, and a radio says whether it is checked.

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
