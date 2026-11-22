# Checks: proving a look

A part is done when its checks are green **and** its pictures have been read.
The checks catch what can be measured (a role, a tap target, a label a pixel
off its middle, a clipped word); the pictures catch what cannot (a state
that breaks the material, a focus that is hard to find, a motion that
snaps). Do both for every part, as you build it.

## The package's test setup

`pubspec.yaml` dev dependencies:

```yaml
dev_dependencies:
  flutter_lints: ^6.0.0
  flutter_test:
    sdk: flutter
  leak_tracker_flutter_testing: any
  ui_core_test: ^0.2.1
```

`analysis_options.yaml`, the options the analyzer holds every package to:

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true

linter:
  rules:
    public_member_api_docs: true
    implementation_imports: true
    avoid_dynamic_calls: true
    missing_code_block_language_in_doc_comment: true
    unawaited_futures: true
```

`dart_test.yaml`, so picture comparisons run apart from the rest:

```yaml
tags:
  goldens:
```

`test/flutter_test_config.dart`, so every test fails on a leaked
controller, focus node or notifier, as Flutter's own tests do:

```dart
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (!kIsWeb) {
    LeakTesting.enable();
    LeakTracking.warnForUnsupportedPlatforms = false;
    LeakTesting.settings = LeakTesting.settings.withIgnored(
      createdByTestHelpers: true,
    );
  }
  await testMain();
}
```

## The commands

Run these from the package's folder before calling anything done. Each must
end clean.

```sh
flutter pub get
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
flutter test --exclude-tags goldens
flutter test --tags goldens            # on the machine the goldens were made on
dart doc --dry-run                     # 0 warnings, 0 errors
dart pub publish --dry-run             # 0 warnings
```

Run the analyzer and the tests on the minimum Flutter the pubspec allows and
on the current stable.

## ui_core_test: what is wrong in any design

`ui_core_test` holds the checks that are faults whatever the look. Each takes
the look's name (for its messages), checks the screen under a `BuildContext`,
and returns a report whose `verify()` fails with one line per problem, naming
the part and what to change.

| Check | Catches | Reads |
|---|---|---|
| `DesignCheckableCheck` | A checkbox, radio, switch or toggle with the wrong role, no name, or also saying "button" | Semantics |
| `DesignTextFieldNameCheck` | A text field a screen reader cannot name | Semantics |
| `DesignFieldSemanticsCheck` | A field whose label, help or error is not on its node, or is read twice | Semantics, layout |
| `DesignFieldNodesCheck` | A field whose text entry moves to another semantics node, or whose nodes change role, as its text goes from empty to a letter (a clear key showing) | Semantics |
| `DesignTooltipNodeCheck` | A tooltip on a node of its own, read apart from the control it names | Semantics |
| `DesignListSideCheck` | An open list (a select's, a combobox's, a menu from a field) above its field while the room below holds it, or 200 px of a longer one | Layout |
| `DesignTapTargetCheck` | A target under the floor, or a semantics box larger than where a tap reaches | Semantics, hit testing |
| `DesignCursorCheck` | A live part that shows the arrow, or a handle without grab | Mouse regions |
| `DesignRadioGroupCheck` | A radio group that is more than one Tab stop, or whose arrows do not choose, wrap, skip and mirror | Focus, keys |
| `DesignLabelCheck` | A label's or icon's ink off its face's middle (as laid out and as drawn) | Pixels |
| `DesignWordBreakCheck` | A word broken across lines | Layout |
| `DesignClipCheck` | Words or a face cut by a clip or an overflow | Layout |
| `DesignShadowClipCheck` | A shadow cut by its parent's clip | Pixels |

The checks come from `package:ui_core_test/ui_core_test.dart`.
`package:ui_core_test/guidelines.dart` offers the same rules as Flutter
accessibility guidelines (`checkableRoleGuideline`, `fieldSemanticsGuideline`,
`textFieldNameGuideline`, `tapTargetReachGuideline`, `cursorGuideline`,
`labelPlacementGuideline`, `tooltipNodeGuideline`, `listSideGuideline`) for
`meetsGuideline`, beside Flutter's own. The radio group and field nodes
checks are not guidelines: one presses keys and the other types.

A screen of parts, every check and guideline over it:

```dart
await tester.pumpWidget(lookApp(home: const PartsScreen()));
final screen = tester.element(find.byType(PartsScreen));
const DesignCheckableCheck(look: 'Look').check(screen).verify();
const DesignTextFieldNameCheck(look: 'Look').check(screen).verify();
const DesignFieldSemanticsCheck(look: 'Look').check(screen).verify();
const DesignTapTargetCheck(look: 'Look').check(screen).verify();
const DesignCursorCheck(look: 'Look').check(screen).verify();
await expectLater(tester, meetsGuideline(checkableRoleGuideline));
await expectLater(tester, meetsGuideline(textFieldNameGuideline));
await expectLater(tester, meetsGuideline(fieldSemanticsGuideline));
await expectLater(tester, meetsGuideline(cursorGuideline));
// The look's floor is 44 by 44, Apple's; Flutter's iOS guideline holds
// it. A look on Material's 48 holds androidTapTargetGuideline.
await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
await expectLater(tester, meetsGuideline(tapTargetReachGuideline));
await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
await expectLater(tester, meetsGuideline(textContrastGuideline));
```

### Pixel checks need the look's real fonts

A test draws text in a stand-in font unless the look's families are loaded:
`DesignLabelCheck` then reads boxes, not capitals, and `DesignWordBreakCheck`
and `DesignClipCheck` measure square glyphs that break words a real font
keeps whole. Load every family the look uses, in every weight it draws (its
icon font too), before
these checks and the pictures, and pass the tester's `runAsync`. The files
come from the package's own `fonts/` folder for the families it bundles;
Flutter's Roboto and Material icons sit in the SDK, under
`$FLUTTER_ROOT/bin/cache/artifacts/material_fonts/`, for a family the look
leaves to the app.

```dart
await tester.runAsync(() async {
  await (FontLoader('Roboto')
        ..addFont(read('Roboto-Regular.ttf'))
        ..addFont(read('Roboto-Medium.ttf')))
      .load();
```

```dart
final labels = await const DesignLabelCheck(
  look: 'Look',
  drawnTolerance: 0.5,
).check(screen, runAsync: tester.runAsync);
labels.verify();
```

`drawnTolerance: 0.5` holds the capitals to half a device pixel as drawn,
which parts wrapped in `DesignCapCenter` meet. `checkDensities` runs the same
check under each density the look offers.

### The radio group check drives the keys

It needs a focusable control just before the group and a group whose
`onChanged` keeps the choice, as an app's does:

```dart
final report = await const DesignRadioGroupCheck(look: 'Look').check(
  tester.element(find.byKey(const ValueKey('plan'))),
  before: before,
  sendKeyEvent: tester.sendKeyEvent,
  pump: tester.pump,
);
report.verify();
```

Run it on every radio group and single-choice segmented control: chosen,
none chosen, and with the chosen option turned off; left to right and right
to left.

### The field nodes check types

It reads every field's nodes, then compares them after the first letter, so
a clear key or a counter that appears with the text cannot move the entry to
a new node. Settle after typing: a combobox's list opening is still
scrolling a frame later, and a check run mid-scroll fails. Each field needs
a node of its own (`RawInputDecorator` gives it one); a field without one
is read with the whole screen round it:

```dart
const check = DesignFieldNodesCheck(look: 'Look');
final empty = check.read(screen);
await tester.enterText(find.byType(EditableText).first, 'A');
await tester.pumpAndSettle();
check.check(empty, screen).verify();
```

Run it on every kind of text field: plain, search (with its clear key),
password (with its reveal key), combobox, number field.

### The list side check opens a list

Open each list, then check the screen. Put the field low on a phone-sized
screen too, where below still holds the list and an older placement chose
the larger side above:

```dart
await tester.tap(find.byType(LookSelect<String>));
await tester.pumpAndSettle();
expect(find.text('Month'), findsOneWidget);
const DesignListSideCheck(look: 'Look').check(screen).verify();
```

## Behaviour the checks cannot see

Write these as widget tests per part.

**In motion.** Sample a frame mid-way through each state change and find it
between the two ends; release a press half-way and find it turning back:

```dart
final gesture = await tester.startGesture(
  tester.getCenter(save),
  kind: PointerDeviceKind.mouse,
);
await tester.pump();
await tester.pump(const Duration(milliseconds: 30));
final midway = fill();
await tester.pumpAndSettle();
final pressed = fill();
expect(midway, isNot(rest));
expect(midway, isNot(pressed));
```

**Reduce Motion.** Under `MediaQueryData(disableAnimations: true)` a colour
or opacity change has settled 150 ms after it starts, and nothing that moves,
resizes or reshapes overshoots.

**Right to left and large text.** Pump every gallery page at
`TextDirection.rtl` and at twice the text size, at 390 and 1440 wide; fail on
any overflow, clip or broken word; assert mirrored positions:

```dart
expect(tester.takeException(), isNull);
final screen = tester.element(find.byType(PartsScreen));
const DesignClipCheck(look: 'Look').check(screen).verify();
const DesignWordBreakCheck(look: 'Look').check(screen).verify();
```

**Keyboard.** Tab reaches every part in reading order and Shift+Tab reverses
it; Enter and Space act; a raised part takes focus on its safe action,
closes on Escape, and gives focus back to its opener.

**Platforms.** On iOS a drag from the leading edge pops a page under the
look's transition (`variant: TargetPlatformVariant.only(TargetPlatform.iOS)`);
on Android, back closes the top dialog, sheet or menu first:

```dart
await tester.binding.handlePopRoute();
await tester.pumpAndSettle();
expect(find.text('Share the link?'), findsNothing);
expect(find.text('Share'), findsOneWidget);
```

**Semantics per part.** A `matchesSemantics` (or `isSemantics`, which
leaves out what it doesn't name) test for each kind of part:
role, name, value, state and actions, as Flutter's own widget has them.

**Languages.** Pump the gallery under a few locales (`ar`, `de`, `ja`) and
find each built-in word in that language, each date and number in its
format.

**The inventory.** `lookInventory.verify()` in a test.

## Rows, widths and the look's own layout rules

Where parts line up, how wide they stand and the grid they sit on are the
look's own decisions, not faults in any design, so ui_core_test leaves them
to the look. Test them with `flutter_test` alone. Measure the painted faces,
not the tap targets round them:

```dart
// The faces, not their tap targets: each part's painted surface.
Rect face(Finder part) => tester.getRect(
  find.descendant(of: part, matching: find.byType(LookSurface)).first,
);
```

- **One height in a row.** A text field, a select, a combobox and a button
  in one `Row` have faces of one height, and the fields one centre line.
- **No stretch from 600 px.** In a 1440-wide column with start alignment, a
  button, a stepper and a segmented control keep their content's width, and
  a select and a combobox the width of their label and widest option: one
  width whatever is chosen, the same for both. In a stretched column both
  fill it.
- **Keylines.** A card's rows start and end on the card's inner edges.
- **The grid.** Gaps between parts are multiples of the look's unit.

`ui_core_review`, an optional, unpublished package in the
[design systems repository](https://github.com/wenkaifan0720/flutter_design_systems),
holds fuller versions of these checks, each against the look's own numbers.
A look that wants them takes it as a git dev dependency (it does not stop
the look from publishing) and imports it in place of `ui_core_test`, which
it re-exports:

```yaml
dev_dependencies:
  ui_core_review:
    git:
      url: https://github.com/wenkaifan0720/flutter_design_systems
      path: packages/ui_core_review
```

| Check | Holds |
|---|---|
| `DesignAlignmentMatrix`, `DesignAlignmentSheet` | Every control of one size at one height and one centre, labels' capitals on it, per platform; the sheet draws them four times their size |
| `DesignTextEntryCheck` | A text entry's line, hint and caret on the row's centre |
| `DesignRowCheck` | Controls in a row (dialog actions, a field and its button) one height by their drawn outline |
| `DesignKeylineCheck`, `DesignKeylineSheet` | A card's rows on its leading and trailing keylines (`DesignKeylineRegion`) |
| `DesignWidthCheck` | From 600 px wide, no select, button, stepper or segmented control stretched to its column |
| `DesignSpacingCheck` | Gaps on the look's grid |
| `DesignFieldPartsCheck` | A field's own parts (prefix, suffix, segments) with room |

Each is called like the pixel checks:
`await const DesignRowCheck(look: 'Look').check(screen, runAsync: tester.runAsync)`,
then `verify()` on the report.

## The screenshot review

Checks pass parts that look wrong. Before a part is done, shoot it and read
every picture at full size. A golden of a widget below the app's builder has
no ground behind it unless the test paints one, so wrap the shot in the
look's ground. Two mice hovering in one test need a device each:
`createGesture` takes no device, so build them as
`TestGesture(dispatcher: tester.sendEventToBinding, kind: PointerDeviceKind.mouse, pointer: n, device: n)`.
Shoot a state after its springs settle (`pumpAndSettle`); one long pump
after a pointer event draws the face before the spring has moved.
Read:

- every part, in every state it has (rest, hover, Tab focus, pressed,
  disabled, selected, error, busy);
- day and night, in every preset;
- at 390 and 1440 wide, left to right and right to left, at 1x and 2x text;
- mid-way through each state change and each route transition, not only
  settled.

Use golden tests (`matchesGoldenFile`, tagged `goldens`) with the look's real
fonts loaded, or a headless run of the example app.

Shoot these pairs and groups side by side, in one frame each, since their
faults live between parts ([taste.md](taste.md) section 8):

- a text field, a select and a combobox in one form, closed and each open;
  a menu open beside them;
- a list whose chosen row has a trailing button;
- a disabled and an enabled primary button;
- the loading, empty, error and success states of one region;
- a form with a segmented control and its Save button;
- a three-action dialog with a destructive action, at 390 wide and at 2x
  text;
- a row's menu with Rename and Delete;
- a chart with data and the same chart all zero, in English and in Arabic;
- a date picker opened from a field near the foot of a 390-wide screen;
- a card holding a list section, with every container's insets measured. Read each image at its
native size, compare it with the same part in material_ui at the same
condition and with the previous release, and ask of each: does this state
keep the material, is focus findable at a glance, do the edges line up, is
anything cut, crowded or stretched? Fix and shoot again; never accept a part
from its checks alone.

## Production grade

Before a release, nothing in `lib`, `test` or `example/lib` names a working
process (review notes, dates, internal names), and test files are named for
what they check:

```sh
grep -rIniwE "todo|fixme|hack|wip|self-review|round [0-9]+" lib test example/lib
```

## How this skill's samples are checked

Every Dart block in `SKILL.md` and these references is taken from
`samples/`, a small look that depends only on published packages.
`samples/test/docs_test.dart` fails if a block is not found, token for token,
in the samples' sources; `examples.md`'s excerpts are matched against the
published looks' sources: the `packages/` folder of the repository the skill
ships in, or the folders listed in `LOOK_SOURCES`. From `samples/`, on
Flutter 3.47 or later:

```sh
flutter pub get
dart analyze --fatal-infos
flutter test
```
