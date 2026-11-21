# ui_core_review

Our looks' layout review on ui_core: whether a look's controls line up where they share a row, its cards keep
their keylines, its controls take the widths it allows, its gaps sit on its grid and a field's own parts have room.
These are a look's own rules, its grid and its taste, so each look passes its own numbers; what is wrong in any design
(a role, a radio group's keys, a field's name, a tap target, a cursor, a clipped word, a cut shadow, an overflow) is
[ui_core_test](https://pub.dev/packages/ui_core_test)'s.

It lives in the repository alone (`publish_to: none`). A look's tests take it as a dev dependency, and a gallery that
shows its sheets in its example's dependencies:

```yaml
dev_dependencies:
  ui_core_review: ^0.1.0
```

It re-exports ui_core_test, so a test that takes a review check imports it in place of that one:

```dart
import 'package:ui_core_review/ui_core_review.dart';
```

pub accepts the unpublished dev dependency when the look publishes, and pub.dev's analysis leaves dev dependencies and
`test/` out, so a look's score does not change.

## Pixels and boxes

Each check reads layout boxes where they show what it holds and the drawn pixels only where they alone do (a face's
painted edge, a label's ink, a fill that differs from the page): its doc says which. A check that reads pixels takes
the tester's `runAsync`, and its tests are tagged as goldens are where they compare pictures.

## Lining controls up

Controls that share a line drift apart in ways no one control's test sees: two controls of "the same size" a few
pixels apart, a label a pixel low, a field that shrinks on desktop. `DesignAlignmentMatrix` checks a design system's
controls row by row, as Android, iOS and macOS, from their drawn pixels, and `DesignAlignmentSheet` draws them four
times their size for review; `DesignTextEntryCheck` checks each text entry the same way. ui_core's README says
what keeps a line straight (`DesignControlBox`, `DesignTextEntryBox`, `DesignCapCenter`).

What the eye compares in a row is the capitals: a 13 px button label and a 14 px field's text look level when their
capitals' middles are, whatever their baselines. So the alignment matrix holds baselines only among labels of one size
and style, and every label's and text entry's capitals on the row's centre line, as drawn, to half a device pixel; a
design system whose labels and entries are wrapped in `DesignCapCenter` passes.

A card's contents drift the same way across rows: a title at 16, rows' words at 26, a checkbox at 22, a chevron that
stops short of the switches above it. A design system's card and section widgets put ui_core's
`DesignKeylineRegion` around their content; `DesignKeylineCheck` then checks every such card on a screen: each row's
first edge on the leading keyline, its last on the trailing one, and the controls a row holds one height on one centre
line. Words are read by their line boxes, a control by its drawn face (not its tap box or its shadow), an icon that
ends a row by its ink; what lies inside a face or a well (a field's, a table's) is not an item of the card around it.
A look marks a face its pixels cannot show (one the colour of the ground, a pane of glass) or a picture with things
placed on it with `DesignKeylineFace`, which both checks take as it is. A gallery marks each section's column of
examples with `startAligned: true`, and runs the check on each gallery page too: there every row starts on the
leading keyline, so a stepper, a sum or a line of words centred in the column (or set at its end) is named, where a
card may centre an empty state. `DesignKeylineSheet` draws the keylines over a screen.

A control's box is not always what a person sees as its outline: a glass button whose outer ring barely stands off a
light dialog reads smaller than the filled button beside it, though their boxes match. `DesignRowCheck` reads each
control in a row (a dialog's actions, a split button's halves, a field and its button) by its drawn outline: inside
its face's shape, so a shadow never counts, the outermost pixels whose contrast with the surface reaches
`contrastFloor` (1.25 to 1). It holds one top and one bottom across the row, and equal sides where the row is laid
out with equal sides on its surface, to half a device pixel, and each control's capitals (a label's, or a text
entry's typed text or hint) on the row's centre line, and gives each problem as laid out and as drawn. A control with
no face of its own (an icon button drawn as a bare glyph, a text button, a navigation destination whose indicator
holds only its icon, an icon whose only face is its badge, a tab whose face shows only the line under it) has no
outline to compare and is read by its capitals, or its icon's middle, on that line. Words and icons drawn over a face
are never read as it, whichever control holds them; a card's title over its body is placed, not centred; a text
field's own parts (its entry and the toggle or switch inside its face) are one field, not a row. A row inside a
`DesignKeylineRegion` whose `mixedHeights` says why its controls differ (a gallery's ladder of one control per
size) is not held. The chips of a `Wrap` are read run by run, each run a row; a control a clip partly hides (a
week scrolled in its strip, its weekend past the strip's edge) is not held, as what shows of it is not its outline;
nor is a control another surface covers (a window in front of it, a later child of a `Stack`). Run on a screen's
root, so its bars (an app bar, a gallery's own bar) are read with the rest.

On a wide screen a control stretched across its column reads as a banner: a dropdown's closed face spanning a desktop
page is the common case. From 600 logical pixels wide, `DesignWidthCheck` holds each select, button, stepper and
segmented control to the width its content and its own padding take, or to 320 (a form grid's cell), whichever is
larger, as drawn; a group of choices apart (choice chips, choice cards, icon tiles, by their chosen state) and a tab
bar are held to 320 or the room their items take, each its content and padding and 40 px more, so three words spread
over a 1440 column are named and tabs or chips that keep to their words pass. A button whose words wrap onto two lines
though on one line they would fit 320 is named however wide it is. Free text entries, search, tables and list rows may
span (as may a header: two buttons round a heading marked `Semantics(header: true)`), and a design system can give a
kind of control another limit with its reason. A list's rows are read from Flutter's own semantics
(`SemanticsRole.list` and `listItem`) or from how they stand (a stack of rows as wide as each other, touching or a
heading apart, a section's one row edge to edge, a row between paragraphs with its words leading and a glyph or value
trailing), and a search bar from `SemanticsInputType.search`. Its `checkList`, run with a list open, holds a list
opened from a field to at least the field's width, on its leading edge, with its words on the field's words, whatever
paints the list's surface, a popup over the field's page (a menu's route, an overlay portal's child) holding one row or
only a "no matches" note included; the list's edges are read against the page under it. A combobox's field is the face
round its entry and toggle, and a disabled field has nothing to check.

## Spacing and a field's parts

- `DesignFieldPartsCheck`: a date or time field's segments hold their text at least 4 px in from their frame on both
  sides, and the parts of one field that stand in a row share one height (within 1 px): a date field's segments, or
  its frame, and the button that opens its picker; a stepper's buttons and its field. Run it at 100% and 200% text.
- `DesignSpacingCheck`: a page's margin, the insets of shapes set in shapes (concentric corners), and gaps on the
  grid; `literals` reads a look's sources for spacing off the grid its `DesignSpacingScope` declares.

The grid they hold a look to is ui_core's (`DesignSpacingScope`), which a look declares in its theme.
