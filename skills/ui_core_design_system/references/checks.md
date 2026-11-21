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
  ui_core_test: ^0.2.0
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
| `DesignTapTargetCheck` | A target under the floor, or a semantics box larger than where a tap reaches | Semantics, hit testing |
| `DesignCursorCheck` | A live part that shows the arrow, or a handle without grab | Mouse regions |
| `DesignRadioGroupCheck` | A radio group that is more than one Tab stop, or whose arrows do not choose, wrap, skip and mirror | Focus, keys |
| `DesignLabelCheck` | A label's or icon's ink off its face's middle (as laid out and as drawn) | Pixels |
| `DesignWordBreakCheck` | A word broken across lines | Layout |
| `DesignClipCheck` | Words or a face cut by a clip or an overflow | Layout |
| `DesignShadowClipCheck` | A shadow cut by its parent's clip | Pixels |

`package:ui_core_test/guidelines.dart` offers the same rules as Flutter
accessibility guidelines (`checkableRoleGuideline`, `fieldSemanticsGuideline`,
`textFieldNameGuideline`, `tapTargetReachGuideline`, `cursorGuideline`,
`labelPlacementGuideline`) for `meetsGuideline`, beside Flutter's own.

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

A test draws text in a stand-in font unless the look's families are loaded;
`DesignLabelCheck` then reads boxes, not capitals. Load every family the look
uses (its icon font too) before a pixel check, and pass the tester's
`runAsync`:

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

**Reduce Motion.** Under `MediaQueryData(disableAnimations: true)` a state
change has settled 150 ms after it starts, and nothing overshoots.

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

**Semantics per part.** A `matchesSemantics` test for each kind of part:
role, name, value, state and actions, as Flutter's own widget has them.

**Languages.** Pump the gallery under a few locales (`ar`, `de`, `ja`) and
find each built-in word in that language, each date and number in its
format.

**The inventory.** `lookInventory.verify()` in a test.

## ui_core_review: the look's own layout rules

`ui_core_review` checks what is a look's own decision rather than a fault in
any design: rows in line, keylines, widths, spacing and a field's parts, each
against the look's own numbers. It lives in the repository and is not on
pub.dev; take it as a git dev dependency, and import it in place of
`ui_core_test`, which it re-exports:

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
then `verify()` on the report. A dev dependency that is not on pub.dev does
not stop the look from publishing.

## The screenshot review

Checks pass parts that look wrong. Before a part is done, shoot it and read
every picture at full size:

- every part, in every state it has (rest, hover, Tab focus, pressed,
  disabled, selected, error, busy);
- day and night, in every preset;
- at 390 and 1440 wide, left to right and right to left, at 1x and 2x text;
- mid-way through each state change and each route transition, not only
  settled.

Use golden tests (`matchesGoldenFile`, tagged `goldens`) with the look's real
fonts loaded, or a headless run of the example app. Read each image at its
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
grep -rniwE "todo|fixme|hack|wip|self-review|round [0-9]+" lib test example/lib
```

## How this skill's samples are checked

Every Dart block in `SKILL.md` and these references is taken from
`samples/`, a small look that depends only on published packages.
`samples/test/docs_test.dart` fails if a block is not found, token for token,
in the samples' sources; `examples.md`'s excerpts are matched against the
looks' sources (the repository's `packages/` folder, or the folders listed in
`LOOK_SOURCES`). From `samples/`, on Flutter 3.47 or later:

```sh
flutter pub get
dart analyze --fatal-infos
flutter test
```
