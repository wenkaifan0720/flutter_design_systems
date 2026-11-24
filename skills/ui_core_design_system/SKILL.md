---
name: ui_core_design_system
description: Build a Flutter app's own design on the ui_core package, where ui_core carries the behaviour (focus, keyboard, screen-reader semantics, overlays, tap targets, motion policy, built-in words) and the app paints every part. Use when asked to give a Flutter app a look of its own that is neither Material nor Cupertino (a brand, a designer's mock-ups, or a named style such as Swiss, neumorphic, brutalist or glass), to build the app's screens in that design, to add parts or states to it, or to review it for usability, accessibility, motion and layout. Not for restyling Material's widgets through ThemeData.
---

# An app's own design on ui_core

Written for ui_core 0.6.x and ui_core_test 0.4.x, on Flutter 3.47 or later.

This skill builds one app's design and the screens made of it: the design's
laws, its theme, the face its parts share, then each part the screens need,
in every state, at the widths the app runs at, for every reader. The design
lives in the app, in a folder of its own (`lib/design/`); the screens use its
parts and paint nothing themselves. Only the published API of ui_core and
ui_core_test is used.

ui_core splits the work in two:

- **ui_core owns behaviour.** Focus, keyboard, screen-reader semantics, tap
  targets, overlays and routes, dialog layout, radio-group keys, tooltip
  triggers, Reduce Motion, built-in words in 30 languages. It draws nothing
  you would ship.
- **The design owns paint.** Colour, type, shape, depth, motion tokens and
  its idea of every state. Each part is a ui_core `Raw*` widget (or a
  Flutter one) with a builder that paints the design's face for the states
  it is given.

Do not rebuild what ui_core carries: a hand-rolled `FocusableActionDetector`
or `GestureDetector` button misses the semantics, the focus-visible rule, the
press-inside-a-scroll rule and the tap-target floor that `RawButton` and
`TapTargetPadding` already hold, and the checks will find it.

To install the skill, copy this folder into the project's `.claude/skills/`
(or `~/.claude/skills/` for every project). The app takes:

```text
flutter pub add ui_core:^0.6.0 material_ui
flutter pub add 'dev:ui_core_test:^0.4.0' dev:leak_tracker_flutter_testing
```

material_ui gives the app `MaterialApp`, `TextField` and Flutter's
localizations; the design paints over them.

## Flutter habits that differ

Each line is a Flutter or Material habit that is wrong on ui_core, and the
right form.

- A dialog's title is a `String`, which the design draws:
  `RawAlertDialog(title: 'Delete?', titleBuilder: (context, title) => Text(title, style: …))`,
  never `title: Text(…)`.
- An action is words and a callback, by name:
  `RawDialogAction(label: 'Delete', onPressed: …)`. `actions:` takes
  `RawDialogAction`s, not buttons; the design draws each one in
  `actionBuilder`.
- A dialog opens on a route:
  `Navigator.of(context).push(RawModalDialogRoute(builder: (context, details) => …))`,
  or the design's own `show…Dialog`, not Material's `showDialog`.
- A segmented control is
  `RawSegmentedButton(options: […], selected: {…}, onSelectionChanged: …, itemBuilder: (context, value, states) => …)`.
  ui_core has no `segments:`, `ButtonSegment` or `RawButtonSegment` (those are
  Material's `SegmentedButton`). `segmentBuilder` belongs to `RawDateField`
  and `RawTimeField`. The 0.3 names `DesignToggleGroup` and
  `DesignToggleItemBuilder` are `RawSegmentedButton` and `RawSegmentBuilder`,
  and `dart fix --apply` renames them.
- A screen is pushed with `RawPageRoute` (or listed as a `RawPage`), not
  `MaterialPageRoute` or `CupertinoPageRoute`: it plays the design's
  transition, and the swipe back on iOS.
- A calendar is
  `RawCalendarDatePicker(controller: RawCalendarController(firstDate: …, lastDate: …), dayBuilder: …)`.
  The controller holds the month and the selection, and `onChanged` reports a
  pick; there is no `initialDate` or `onDateChanged`. Each day stands in a
  tap target at least the floor tall (`RawTapTargets.of(context).floorOn()`),
  its face centred: a day face that draws the grid's rules (borders that
  meet the next row's) is built at that height, or the rules gap between
  rows. A day's number is `day.label` (the app's digits, Arabic-Indic in
  Arabic), not `'${day.date.day}'`.
- Built-in words come from `RawWidgetsLocalizations.of(context)`, not
  `MaterialLocalizations`.
- A field's words are strings named as `InputDecoration` names them:
  `labelText`, `hintText`, `helperText`, `errorText`. In Flutter `label`,
  `hint`, `helper` and `error` are `Widget` slots. The label, help and error
  go to `RawInputDecorator`, which reads them with the field; the hint goes
  on the entry (`Semantics(hint:)`), since the drawn hint is not heard.

## Pages

| Page | Read it when |
|---|---|
| [references/contract.md](references/contract.md) | Wiring any part: each `Raw*` widget, the builder pattern, semantics, `RawStyleOf`, tap targets, motion, fields, dialogs, toasts, tabs, lists and menus, routes, words; and the ui_core API each kind of part is painted on. |
| [references/taste.md](references/taste.md) | Designing any state, size or motion; making parts read as one family; deciding what to leave out. |
| [references/examples.md](references/examples.md) | Seeing the pattern in two published designs on ui_core: brutal_ui and neumorphism_ui. |
| [samples/](samples/) | Tend, a small app with a design of its own: `lib/design/` is the design, `lib/screens/` three screens made of it, `test/` the checks. Every Dart block in these pages is taken from it. |

## Workflow

Work in this order. Each step ends with the app building and its checks
green, so a fault is found where it was made.

### 1. Write the design's laws

Before code, write four to eight lines that say what the design is made of
and how that material behaves, from the brief, the brand or the mock-ups:

- what a surface is (paper with ink rules, frosted glass, extruded plastic,
  a terminal's character grid);
- how it shows that something acts, is pressed, chosen, focused, turned off,
  or wrong, *in that material*;
- its type, its one control height, its corner, its motion (stiff and quick,
  soft and slow, or instant);
- whether it follows an established language faithfully (and which), or is
  its own.

Every later decision is derived from these laws; keep them at the top of
the design folder's library file. When a part has no precedent in the
language, design it as the language would have; when unsure, leave it
plainer. See [taste.md](references/taste.md).

### 2. Build the theme

One immutable `ThemeData`-like class for the design (`copyWith`, `lerp`,
`==`) and a widget that installs it, with `of` and `maybeOf`, through an
`InheritedTheme` so dialogs and menus carry it. It holds:

- colours by role, a day set and a night set chosen separately (not
  inverted);
- a type ramp that works with the family the app loads, and that family's
  cap-height factor for `RawCapCenter`;
- **one control height** every part that can share a row stands at, and a
  `RawDensity` that moves faces, never tap targets;
- motion tokens as springs (damping ratio and stiffness);
- a style slot per part the screens restyle (`RawStyle`).

The theme widget also installs the tap-target floors and the spacing grid:

```dart
child: RawTapTargetScope(
  targets: RawTapTargets.fallback,
  child: RawSpacingScope(
    spacing: RawSpacing.fallback,
```

`RawSpacing.fallback` is a 4 px grid; a design on another unit names it
(`RawSpacing(grid: 8)`), and its gaps, insets and control heights are
multiples of it.

The app installs the design in its `MaterialApp`'s `builder`, so every
route, dialog and toast stands under it, with the design's page transitions
in `ThemeData`:

```dart
theme: ThemeData(
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: tendPageTransitions,
  ),
),
builder: (context, child) =>
    tendHost(context, child!, _brightness(context)),
// The first screen stands on the design's route too: Material's
// route under a RawPageRoute is never told to play its exit.
onGenerateRoute: (settings) => TendPageRoute<void>(
  settings: settings,
  builder: (context) => const PlantsScreen(),
),
```

```dart
Widget tendHost(BuildContext context, Widget child, Brightness brightness) {
  final data = TendThemeData.of(brightness);
  return TendTheme(
    data: data,
    // Toasts over every route, under the design's theme.
    child: TendToaster(
      child: ColoredBox(color: data.colors.ground, child: child),
    ),
  );
}
```

The same builder works under `CupertinoApp` and `WidgetsApp`.

### 3. Make the face, then the button

Model what a part looks like at one moment as a value with a `lerp` (a
"face"), and draw it with one animated surface that springs from wherever it
stands to each new face. Every part then animates every state the same way,
and a press released half-way turns back without a jump:

```dart
_from = _now;
_to = widget.face;
final motion = TendTheme.of(context).motion;
_controller
  ..value = 0
  ..springTo(
    1,
    RawMotionPolicy.of(context).effects(
      dampingRatio: motion.stateDampingRatio,
      stiffness: motion.stateStiffness,
    ),
  );
```

Build the button first. It fixes the control height, the label's centring,
focus, press, disabled and the motion every later part reuses:

```dart
return TapTargetPadding(
  child: RawButton(
    onPressed: onPressed,
    focusNode: focusNode,
    autofocus: autofocus,
    builder: (context, states, _) {
      final styled = RawStyleOf([style, theme.buttonStyle], states);
      return AnimatedTendSurface(
        face: tendButtonFace(
// ...
          child: RawControlBox(
            minHeight:
                styled.minimumSize?.height ??
                theme.density.height(theme.controlHeight),
// ...
                  child: RawCapCenter(
                    capHeightFactor: theme.capHeightFactor,
```

- `TapTargetPadding` outermost: the area a tap reaches is the box a screen
  reader outlines, at least 44 by 44 for touch and 24 by 24 for a pointer.
- `RawButton` gives the states: `pressed`, `hovered`, `focused` (only while
  focus should show, as a browser's focus-visible), `disabled`, `selected`,
  `error`.
- `RawStyleOf` reads the part's own `style:`, then the theme's slot, then
  the design's default, state by state.
- `RawControlBox` and `RawCapCenter` put the label's capitals on the
  face's middle, so a button, a field and a select in one row line up.

### 4. Build the parts the screens need

List the parts the app's screens use, and build them in the order a screen
meets them: actions, then fields and choices, then lists and menus, then
what is raised over the screen. Build only those; a part no screen uses is
not built. For each part:

1. Find its ui_core API in [contract.md](references/contract.md) ("Parts
   and the API they are painted on"). A part with a behaviour API (tabs,
   menus, combobox, date picker, data table, carousel, toaster, sheet) is
   painted on that API, never rebuilt.
2. Give it the semantics Flutter's own widget has. A checkbox says
   `checked`, a switch `toggled`, a toggle button `semanticSelected` (still a
   button), a radio is a `RawRadio` in a `RadioGroup`.
3. Draw every state it has, day and night, in the design's material.
4. Reuse what an earlier part decided: a face two parts share (a resting
   panel, a well, a chosen row) is named once, on the face's class or the
   theme, and both use it; a face spelled out in three parts is one the
   theme is missing.
5. Give it the API Flutter's own widget has: `value` and `onChanged`, a null
   callback to turn it off, an optional controller and focus node.

### 5. Raise things the design's way

Each raised part (dialog, sheet, menu, popover, tooltip, toast) is shown by
a function or a widget of the design that owns its route or overlay, scrim,
motion, dismissal (Escape, Android back, a tap outside where it applies) and
the return of focus to its opener. A route builds under the navigator, not
under its opener, so carry the opener's themes into it:

```dart
final themes = InheritedTheme.capture(from: context, to: navigator.context);
```

[contract.md](references/contract.md) has each: dialogs on
`RawModalDialogRoute` with their actions on a `RawActionBar`, a modal page
that is not a dialog on `RawModalRoute`, a sheet's own buttons, a picker
that opens whole, a popover placed where the design wants it, and toasts
that stand clear of the bars.

### 6. Make the screens of the parts

A screen is made of the design's parts and holds no paint of its own: no
colours, borders, `GestureDetector` presses or text styles that are not the
theme's. A screen that needs something the design lacks gets a new part (or
a new slot) in the design folder, so the next screen has it too.

```dart
return TendScaffold(
  title: 'Plants',
  actions: [
    TendIconButton(
      icon: Icons.settings_outlined,
      semanticLabel: 'Settings',
      onPressed: () => Navigator.of(context).push(
        TendPageRoute<void>(builder: (context) => const SettingsScreen()),
      ),
    ),
  ],
```

- **Pages.** Push screens on `RawPageRoute` (here `TendPageRoute`, which
  names the design's transition), the first one included (step 2). A
  screen's bar shows back or close from `RoutePresentation.of(context)`
  ([contract.md](references/contract.md), "Pages and where a screen stands").
- **Widths.** Lay each screen out for the widths the app runs at. Content
  keeps a readable width on a wide screen, and controls keep their own
  width from 600 px ([taste.md](references/taste.md), "Alignment and size").
- **Leaving with changes.** A screen that holds unsaved changes asks before
  it goes, through Flutter's `PopScope` (back, Escape, the swipe back and the
  bar's key all reach it):

```dart
return PopScope<Object?>(
  canPop: !_changed,
  onPopInvokedWithResult: (didPop, result) {
    if (!didPop) unawaited(_leave());
  },
```

- **Figures.** Numbers and dates come from `RawWidgetsLocalizations`
  (`formatDecimal`, `formatFullDate`), and a time's hour and minute from
  its `formatHour` and `formatMinute` (the `RawTimeFormatting` extension,
  ui_core 0.6.1). Never `n.toString().padLeft(2, '0')`, which stays ASCII in
  every language.
- **Toasts.** Shown with the toaster the app's builder holds; a pane's
  toasts go to a `RawToaster` round the pane, centred on it. Each part
  along the bottom toasts must not cover (a page's foot with its Save, a
  status line) stands in `RawToasterKeepClear`
  ([contract.md](references/contract.md), "Toasts"):

```dart
TendToaster.of(context).show(
  RawToast(
    message: 'Watered ${plant.name}',
    actionLabel: 'Undo',
    onAction: () => garden.put(before),
  ),
);
```

### 7. Check every screen, then look at it

A widget test pumps the app as `main` runs it, at each width the app runs
at, by day and by night, left to right and right to left (a right-to-left
locale such as Arabic), at 1x and 2x text, opens each screen, and runs
ui_core_test's checks over what shows:

```dart
List<String> problemsOn(WidgetTester tester, {required bool touch}) {
  final screen = tester.element(find.byType(Navigator).first);
  return [
    for (final report in [
      const DesignCheckableCheck(look: 'Tend').check(screen),
      const DesignTextFieldNameCheck(look: 'Tend').check(screen),
      const DesignFieldSemanticsCheck(look: 'Tend').check(screen),
      DesignTapTargetCheck(
        look: 'Tend',
        input: touch ? RawInput.touch : RawInput.pointer,
      ).check(screen),
      if (!touch) const DesignCursorCheck(look: 'Tend').check(screen),
      const DesignOverflowCheck(look: 'Tend').check(screen),
      const DesignClipCheck(look: 'Tend').check(screen),
      const DesignWordBreakCheck(look: 'Tend').check(screen),
    ])
      ...report.problems,
  ];
}
```

```dart
tester.platformDispatcher
  ..platformBrightnessTestValue = brightness
  ..localesTestValue = [locale]
  ..textScaleFactorTestValue = textScale;
```

Then a test per flow the screens carry: a dialog opened (its actions with
`DesignDialogActionsCheck` at 320 and 390 wide and at 2x text, focus on the
safe action, Escape closing it and focus back on its opener), a field typed
into (`DesignFieldNodesCheck`), a field's help and error read with it
(`DesignFieldWordsCheck`), a list opened (`DesignListSideCheck`), a toast
standing above the bar, a radio group's keys (`DesignRadioGroupCheck`).

| Check | Catches |
|---|---|
| `DesignCheckableCheck` | A checkbox, radio, switch or toggle with the wrong role, no name, or also saying "button" |
| `DesignTextFieldNameCheck` | A text field a screen reader cannot name |
| `DesignFieldSemanticsCheck` | A field whose label, help or error is not on its node, or is read twice |
| `DesignFieldNodesCheck` | A field whose text entry moves to another node as its text goes from empty to a letter |
| `DesignFieldWordsCheck` | A field's help or error read apart from the field; give it the words the screen shows |
| `DesignTooltipNodeCheck` | A tooltip read apart from the control it names |
| `DesignListSideCheck` | An open list above its field while below holds it; a whole picker on a side that cuts it |
| `DesignOverlayCheck` | A popover, list, menu, tooltip or dialog running off the screen |
| `DesignDialogActionsCheck` | A dialog's or sheet's actions out of their row or stack ([contract.md](references/contract.md), "Dialogs and sheets"); it reads the first control on screen with each action's words, so test a dialog over a screen whose keys don't share them |
| `DesignOverflowCheck` | A part that overflows its box or runs off its screen |
| `DesignTapTargetCheck` | A target under the floor, or a semantics box larger than where a tap reaches |
| `DesignCursorCheck` | A live part that shows the arrow, or a handle without grab |
| `DesignRadioGroupCheck` | A radio group that is more than one Tab stop, or whose arrows do not choose, wrap, skip and mirror |
| `DesignLabelCheck` | A label's ink off its face's middle |
| `DesignWordBreakCheck`, `DesignClipCheck` | A word broken across lines; words or a face cut |
| `DesignShadowClipCheck` | A shadow cut by its parent's clip |

They come from `package:ui_core_test/ui_core_test.dart`; each takes a name
for its messages and a `BuildContext`, and its report's `verify()` fails
with one line per problem. The checks that measure ink and words need the
app's real fonts loaded first (in a test, text is drawn in a stand-in font
whose boxes break words a real font keeps whole):

```dart
await tester.runAsync(() async {
  await (FontLoader('Roboto')
        ..addFont(read('Roboto-Regular.ttf'))
        ..addFont(read('Roboto-Medium.ttf')))
```

Every test runs leak-tracked (`test/flutter_test_config.dart`), so a
controller or focus node the design makes and never disposes fails it:

```dart
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (!kIsWeb) {
    LeakTesting.enable();
    LeakTracking.warnForUnsupportedPlatforms = false;
    LeakTesting.settings = LeakTesting.settings.withIgnored(
      createdByTestHelpers: true,
    );
  }
```

Then look: shoot every screen at full size, day and night, at each width,
left to right and right to left, at 1x and 2x text, with each list, menu,
dialog and sheet open, and mid-way through each transition; read every
picture before calling the screen done. Checks pass parts that look wrong.

Never change what a screen says to pass a check: a shorter label, a dropped
helper. The check then passes and the part still fails at the length real
words give it. Fix the part; if the part is right and the check is wrong,
report it to the ui_core maintainers with a test that shows it.

## Done means

- [ ] Every screen the app needs is built of the design's parts, and holds
      no paint of its own.
- [ ] Every interactive part has rest, hover, focus, pressed, disabled and,
      where it has them, selected, error and busy, day and night; each
      differs from rest; each change animates on the design's springs.
- [ ] Keyboard: Tab reaches every part in reading order; Enter and Space
      act; arrows move inside radio groups, tabs, menus and lists; Escape
      closes what was raised and focus returns.
- [ ] Screen readers hear each part as Flutter's own widget: role, name,
      value, state.
- [ ] Tap targets reach the floor; rows line up; labels sit on their faces'
      middles; nothing overflows at the app's widths or at 2x text.
- [ ] Parts of one kind read as one family ([taste.md](references/taste.md), "Parts of one kind").
- [ ] Right to left mirrors; built-in words come from
      `RawWidgetsLocalizations`; dates and numbers follow the locale.
- [ ] Under Reduce Motion nothing overshoots or travels far, and colour
      and opacity changes settle within 150 ms.
- [ ] No part is harder to use than Material's at the same width, text size,
      direction and state.
- [ ] On the final code, after the last edit: `dart format --set-exit-if-changed
      lib test`, `dart analyze --fatal-infos` and `flutter test` are clean, and
      every picture has been read.

## Pitfalls

- **A label nudged by padding until it looks centred.** Use `RawCapCenter`
  with the family's factor and even leading; `DesignLabelCheck` measures it.
- **Disposing a controller or focus node the caller handed in.** Own one
  only when none was given; swap it in `didUpdateWidget`.
- **A control inside a row's button.** `RawButton` merges what it holds into
  its own node: a "…" key inside a row that opens is read and pressed as the
  row. Put it beside the row's button ([contract.md](references/contract.md),
  "Semantics").
