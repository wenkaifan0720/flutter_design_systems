# ui_core_test

Widget-test checks for design systems built on ui_core, of what is wrong in any design: a checkbox that says
it is a button, a radio group the arrows cannot cross, a text field a screen reader calls "text field" alone, a tap
target smaller than it looks, a click cursor missing, a label off its face's middle, a word broken mid-word, words
clipped, a shadow cut flat. Each report names the control and what is wrong with it.

A design system's tests take it as a dev dependency, as an app takes `flutter_test`:

```yaml
dev_dependencies:
  ui_core_test: ^0.2.0
```

```dart
import 'package:ui_core_test/ui_core_test.dart';
```

A test pumps a screen (a gallery page, an app screen), then checks it from its root:

```dart
testWidgets('the settings screen reads right', (tester) async {
  await tester.pumpWidget(const MyApp());
  final screen = tester.element(find.byType(MyApp));
  const DesignCheckableCheck(look: 'Mine').check(screen).verify();
  const DesignTextFieldNameCheck(look: 'Mine').check(screen).verify();
  final labels = await const DesignLabelCheck(look: 'Mine').check(
    screen,
    runAsync: tester.runAsync,
  );
  labels.verify();
});
```

## As Flutter's accessibility guidelines

`package:ui_core_test/guidelines.dart` offers the behaviour checks as guidelines, beside Flutter's
`androidTapTargetGuideline` and `labeledTapTargetGuideline`. Each reads every view's whole screen and fails with the
check's own lines:

```dart
import 'package:ui_core_test/guidelines.dart';

await expectLater(tester, meetsGuideline(checkableRoleGuideline));
await expectLater(tester, meetsGuideline(textFieldNameGuideline));
```

`checkableRoleGuideline`, `fieldSemanticsGuideline`, `textFieldNameGuideline`, `tapTargetReachGuideline`,
`cursorGuideline` and `labelPlacementGuideline`. The radio group check is not one: it presses keys, and a guideline
reads a screen without changing it. The guidelines library imports `flutter_test`; the main library does not, so the
checks also run in an app (each takes the tester's `pump` and `runAsync` as functions).

## The checks

What a control says and does, from the semantics tree, layout boxes and hit testing, each run from a screen's root
(a gallery page, an app screen), but the radio group check, run on one group:
- `DesignCheckableCheck`: each checkbox, radio and switch says what it is, as Flutter's do: a node that says it is
  checked or toggled does not also say it is a button, and a radio says whether it is checked.
- `DesignRadioGroupCheck`: a group of radios answers the keyboard as Flutter's `RadioGroup` does: one tab stop, on
  the chosen radio, and arrow keys that move round the radios that can be chosen and choose them. It moves the focus
  and presses keys, so it takes the tester's `sendKeyEvent` and `pump`.
- `DesignFieldSemanticsCheck`: each control inside a `RawInputDecorator` takes a tap through the semantics tree (a
  screen reader's, or a click on the web with semantics on) on a node of its own, a stepper's buttons lie under no
  node that would take their tap, and the field's label is read once.
- `DesignTextFieldNameCheck`: each text field says a name (a label, a hint or a tooltip) on its own node, so a
  screen reader does not read it as "text field" alone.
- `DesignTapTargetCheck`: every control's tap target reaches the look's floor for the input (a phone's screen is
  read for a finger, a desk's for a pointer), and its target is where it is drawn; a text field's own keys (a clear
  or reveal key whose node lies in the field's) are part of the field's reach.
- `DesignCursorCheck`: a pointer over a live control shows the click cursor over its whole hit area, or one that
  says more (a text field's text cursor, a handle's grab, a divider's resize), and over an off control nothing of
  its own.

The floors are ui_core's (`DesignTapTargetScope`), which a look declares in its theme.

What is drawn wrong, from the painted pixels where only they show it (each check's documentation says what it reads):

- `DesignLabelCheck` needs no list of controls: on any screen (each gallery page, each app screen) it reads every
  control that draws a face around one line of words or an icon, and checks that the label sits on the middle of the
  face (words by their capitals, so descenders do not count; an icon by its ink), giving the offset as laid out and as
  drawn. A label beside a text entry of more than one line (a note field) stands on the entry's first line and is held
  to that line's capitals instead. A painted mark that starts the row of a control's words (a way back's triangle,
  drawn by a custom paint holding no words) is read by its ink, as an icon is. Its `checkDensities` runs a screen
  under each density the look ships. Given a `drawnTolerance` (a look that wraps its labels in `DesignCapCenter` gives
  0.5), it holds each label's capitals, as drawn, to the middle of its face in device pixels, and an icon or a painted
  mark beside a label to the label's capitals.
- `DesignWordBreakCheck` names a word broken across two lines ("Groce" over "ries"): a box too narrow for its longest
  word.
- `DesignClipCheck` names a control a clip round it cuts (a month's Saturday cut by the room it is in), giving how
  much of it shows, and words cut by a clip or by their box (a line past its end, words past their last line with no
  ellipsis); what scrolls is read only against the clips inside its viewport, so the rest of a list is not cut, and a
  control wholly past a clip is hidden, not cut.
- `DesignShadowClipCheck`: no shadow, glow or rim is cut flat by a clip round it, and none shows square behind a
  round face. A scroll view's edge along its scroll, with more content past it, is scrolling, not a cut; at the end
  of its content, and across its scroll, the cut counts. Given `near:` (a control's rect), it reads only the casts
  that reach it, as a test of one control's press, hover or focus needs.

The checks that read pixels read what is painted, and only that: not an `IndexedStack`'s other children, nor what
`Offstage` or `Visibility` keeps laid out, nor what a transform scales to nothing (an empty checkbox's check), nor a
list's rows laid out past what it shows (its cache extent); the rest of the screen is read without them. Before any of
them, a test loads every font family in the package's FontManifest.json and lets the screen's images decode (each
check's documentation shows how); text drawn in the test's own font fails the label check once, with that reason, and
a screen repainted since its last frame stops a check with that reason.

## Versions

Version 0.2.0 supports ui_core ^0.4.0 and requires Flutter 3.47 or later (Dart 3.13). 0.1.x's layout
review (the alignment matrix, the keyline, row, width, spacing and field-parts checks) holds a look's own grid and
taste, and is no longer published.

See the CHANGELOG for changes to measurements and migration instructions.
