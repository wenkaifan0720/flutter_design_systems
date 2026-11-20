# ui_core_test

Widget-test helpers for design systems built on ui_core. Compare painted control edges, label alignment,
spacing, touch targets and clipping. Reports give the control name and the measured difference.

A design system's tests take it as a dev dependency, as an app takes `flutter_test`:

```yaml
dev_dependencies:
  ui_core_test: ^0.1.4
```

```dart
import 'package:ui_core_test/ui_core_test.dart';
```

A gallery that shows a sheet on a review page (`DesignKeylineSheet`, `DesignAlignmentSheet`) takes it in its example
app's `dependencies`. It depends on Flutter and ui_core alone, never on `flutter_test`: each check takes the
tester's `pump` and `runAsync` as functions, so a review page in a running app calls the same code.

A test pumps a screen (a gallery page, an app screen), then checks it from its root:

```dart
testWidgets('the settings screen lines up', (tester) async {
  await tester.pumpWidget(const MyApp());
  final screen = tester.element(find.byType(MyApp));
  final labels = await const DesignLabelCheck(look: 'Mine').check(
    screen,
    runAsync: tester.runAsync,
  );
  labels.verify();
  final rows = await const DesignRowCheck(look: 'Mine').check(
    screen,
    runAsync: tester.runAsync,
  );
  rows.verify();
});
```

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

`DesignLabelCheck` needs no list of controls: on any screen (each gallery page, each app screen) it reads every control
that draws a face around one line of words or an icon, and checks that the label sits on the middle of the face (words
by their capitals, so descenders do not count; an icon by its ink), giving the offset as laid out and as drawn. A
label beside a text entry of more than one line (a note field) stands on the entry's first line and is held to that
line's capitals instead. A painted mark that starts the row of a control's words (a way back's triangle, drawn by a
custom paint holding no words) is read by its ink, as an icon is. Its `checkDensities` runs a screen under each
density the look ships. Given a `drawnTolerance` (a look that wraps its labels in `DesignCapCenter` gives 0.5), it
holds each label's capitals, as drawn, to the middle of its face in device pixels, and an icon or a painted mark
beside a label to the label's capitals.

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

Two checks read words and clips. `DesignWordBreakCheck` names a word broken across two lines ("Groce" over
"ries"): a box too narrow for its longest word. `DesignClipCheck` names a control a clip round it cuts (a month's
Saturday cut by the room it is in), giving how much of it shows, and words cut by a clip or by their box (a line past
its end, words past their last line with no ellipsis); what scrolls is read only against the clips inside its
viewport, so the rest of a list is not cut, and a control wholly past a clip is hidden, not cut.

These checks read what is painted, and only that: not an `IndexedStack`'s other children, nor what `Offstage` or
`Visibility` keeps laid out, nor what a transform scales to nothing (an empty checkbox's check), nor a list's rows
laid out past what it shows (its cache extent); the rest of the screen is read without them. Before any of them, a
test loads every font family in the package's FontManifest.json and lets the screen's images decode (each check's
documentation shows how); text drawn in the test's own font fails the label check once, with that reason, and a
screen repainted since its last frame stops a check with that reason.

## The checks a look is held to

Beside the alignment checks, seven read any screen, each from its root (a gallery page, an app screen), and one a
group of radios; each says what it finds in words:
- `DesignTapTargetCheck`: every control's tap target reaches the look's floor for the input (a phone's screen is
  read for a finger, a desk's for a pointer), and its target is where it is drawn; a text field's own keys (a clear
  or reveal key whose node lies in the field's) are part of the field's reach.
- `DesignCursorCheck`: a pointer over a live control shows the click cursor over its whole hit area, or one that
  says more (a text field's text cursor, a handle's grab, a divider's resize), and over an off control nothing of
  its own.
- `DesignShadowClipCheck`: no shadow, glow or rim is cut flat by a clip round it, and none shows square behind a
  round face. A scroll view's edge along its scroll, with more content past it, is scrolling, not a cut; at the end
  of its content, and across its scroll, the cut counts. Given `near:` (a control's rect), it reads only the casts
  that reach it, as a test of one control's press, hover or focus needs.
- `DesignFieldPartsCheck`: a date or time field's segments hold their text at least 4 px in from their frame on both
  sides, and the parts of one field that stand in a row share one height (within 1 px): a date field's segments, or
  its frame, and the button that opens its picker; a stepper's buttons and its field. Run it at 100% and 200% text.
- `DesignFieldSemanticsCheck`: each control inside a `DesignField` takes a tap through the semantics tree (a
  screen reader's, or a click on the web with semantics on) on a node of its own, a stepper's buttons lie under no
  node that would take their tap, and the field's label is read once. It reads the semantics tree.
- `DesignCheckableCheck`: each checkbox, radio and switch says what it is, as Flutter's do: a node that says it is
  checked or toggled does not also say it is a button, and a radio says whether it is checked.
- `DesignRadioGroupCheck`: a group of radios answers the keyboard as Flutter's `RadioGroup` does: one tab stop, on
  the chosen radio, and arrow keys that move round the radios that can be chosen and choose them. It moves the focus
  and presses keys, so it takes the tester's `sendKeyEvent` and `pump`.
- `DesignSpacingCheck`: a page's margin, the insets of shapes set in shapes (concentric corners), and gaps on the
  grid; `literals` reads a look's sources for spacing off the grid its `DesignSpacingScope` declares.

The floors and the grid they hold a look to are ui_core's (`DesignTapTargetScope`, `DesignSpacingScope`), which
a look declares in its theme.

## Versions

Version 0.1.4 supports ui_core ^0.3.4 and requires Flutter 3.47 or later (Dart 3.13).

See the CHANGELOG for changes to measurements and migration instructions.
