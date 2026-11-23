---
name: ui_core_design_system
description: Build a complete, production-grade Flutter design-system package (a "look", like material_ui or cupertino_ui) on the ui_core package, where ui_core carries the behaviour (focus, keyboard, semantics, overlays, tap targets, motion policy) and the package paints every part. Use when asked to create a Flutter design system, UI kit, component library or custom visual style that is neither Material nor Cupertino (in a named style, such as Swiss, neumorphic, brutalist or glass, or from a brand), to add parts or states to such a package, or to review one for completeness, accessibility, motion, layout and API quality. Not for styling a single app with Material's ThemeData.
---

# Building a design system on ui_core

Written for ui_core 0.5.x and ui_core_test 0.3.x, on Flutter 3.47 or later.

This skill builds a Flutter package that is a whole design language: a
theme, every part an ordinary app needs, in every state, on every screen size,
for every reader. It uses only the published API of ui_core and ui_core_test
(pub.dev).

To use it, copy this folder into a project's `.claude/skills/` (or your own
`~/.claude/skills/`); the agent reads it when asked to build a design system.
The package it builds starts from:

```text
flutter create --template=package <name>_ui
flutter pub add ui_core:^0.5.5 material_ui
flutter pub add 'dev:ui_core_test:^0.3.0' dev:leak_tracker_flutter_testing dev:flutter_lints
```

A design system on ui_core splits the work in two:

- **ui_core owns behaviour.** Focus, keyboard, screen-reader semantics, tap
  targets, overlays and routes, dialog layout, radio-group keys, tooltip
  triggers, Reduce Motion, built-in words in 30 languages. It draws nothing
  you would ship.
- **The look owns paint.** Colour, type, shape, depth, motion tokens and the
  look's idea of every state. Each part is a ui_core `Raw*` widget (or a
  Flutter one) with a builder that paints the look's face for the states it is
  given.

Do not rebuild what ui_core carries: a hand-rolled `FocusableActionDetector`
or `GestureDetector` button misses the semantics, the focus-visible rule, the
press-inside-a-scroll rule and the tap-target floor that `RawButton` and
`TapTargetPadding` already hold, and the checks will find it.

## Pages

| Page | Read it when |
|---|---|
| [references/contract.md](references/contract.md) | Wiring any part: each `Raw*` widget, the builder pattern, `DesignStyleOf` layering, tap targets, motion, lists and menus, the Flutter shims. |
| [references/inventory.md](references/inventory.md) | Planning and tracking scope: every component an app expects, in build order. |
| [references/taste.md](references/taste.md) | Designing any state, size or motion; making parts read as one family; deciding what to leave out. |
| [references/checks.md](references/checks.md) | Proving a part: the ui_core_test checks, the analyzer, docs, publish, and the screenshot review. |
| [references/examples.md](references/examples.md) | Seeing the pattern in three published looks on pub.dev: minimal_ui, brutal_ui, neumorphism_ui. |
| [samples/](samples/) | A small look that compiles and passes every check. Every Dart block in these pages is taken from it. |

## Workflow

Work in this order. Each step ends with its checks green, so a fault is found
where it was made.

### 1. Write the look's laws

Before code, write four to eight lines that say what the look is made of and
how that material behaves, as its README's first paragraph will:

- what a surface is (paper with ink rules, frosted glass, extruded plastic,
  a terminal's character grid);
- how it shows that something acts, is pressed, chosen, focused, turned off,
  or wrong, *in that material*;
- its type, its one control height, its corner, its motion (stiff and quick,
  soft and slow, or instant);
- whether it follows an established language faithfully (and which), or is
  its own.

Every later decision is derived from these laws. When a part has no
precedent in the language, design it as the language would have; when unsure,
leave it plainer. See [taste.md](references/taste.md).

### 2. Scaffold the package

```text
<name>_ui/
  lib/<name>_ui.dart        # the library: parts, theme, a `show` list of ui_core
  lib/src/...               # one file per part or family of parts
  test/flutter_test_config.dart
  test/...                  # one file per part, named for what it checks
  example/lib/main.dart     # under 150 lines: install the theme, show parts
  dart_test.yaml            # tags: goldens
  analysis_options.yaml
  README.md  CHANGELOG.md  LICENSE
```

Depend on `ui_core: ^0.5.5` and, for the text editing and the localizations a
look reuses, `material_ui`; dev-depend on `ui_core_test: ^0.3.0`,
`leak_tracker_flutter_testing` and `flutter_lints`. Turn on `strict-casts`,
`strict-inference`, `strict-raw-types` and `public_member_api_docs`, and leak
tracking for every test. [checks.md](references/checks.md) has the files.

The library re-exports only the ui_core types the look's own signatures name,
plus what an app needs to set it up:

```dart
export 'package:ui_core/ui_core.dart'
    show
        DesignDensity,
        DesignStyle,
        RawDialogAction,
        RawMenuEntry,
        RawToast,
        RawToasterState,
        RawWidgetsLocalizations;
```

### 3. Build the theme

One immutable `<Look>ThemeData` with `copyWith`, a static `lerp`, `==`,
`hashCode` and `debugFillProperties`; a `<Look>Theme` widget with `of` and
`maybeOf`, installed through an `InheritedTheme` so dialogs and menus carry
it. It holds:

- colours by role, a day set and a night set chosen separately (not
  inverted);
- a type ramp that works with any family the app loads, and that family's
  cap-height factor for `DesignCapCenter`;
- **one control height** every part that can share a row stands at, and a
  `DesignDensity` that moves faces, never tap targets;
- motion tokens as springs (damping ratio and stiffness);
- a style slot per part (`DesignStyle`, aliased to the look's name).

The theme widget also installs the tap-target floors and the spacing grid:

```dart
child: DesignTapTargetScope(
  targets: DesignTapTargets.fallback,
  child: DesignSpacingScope(
    spacing: DesignSpacing.fallback,
```

`DesignSpacing.fallback` is a 4 px grid; a look on another unit names it
(`DesignSpacing(grid: 8)` for an 8 px grid), and its gaps, insets and
control heights are multiples of it.

Apps install it in their app widget's `builder`, so every route and overlay
stands under it, with the look's page transitions in `ThemeData`:

```dart
theme: ThemeData(
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: lookPageTransitions,
  ),
),
builder: (context, child) => MediaQuery.withClampedTextScaling(
// ...
      child: LookTheme(
        data: LookThemeData.of(brightness),
```

The same builder works under `CupertinoApp` and `WidgetsApp`. The look's
toaster (step 6) goes in it too, under the theme, so a toast shows over
every route.

### 4. Make the face, then the button

Model what a part looks like at one moment as a value with a `lerp` (a
"face"), and draw it with one animated surface that springs from wherever it
stands to each new face. Every part then animates every state the same way,
and a press released half-way turns back without a jump:

```dart
_from = _now;
_to = widget.face;
final motion = LookTheme.of(context).motion;
_controller
  ..value = 0
  ..springTo(
    1,
    DesignMotionPolicy.of(context).effects(
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
      final look = DesignStyleOf([style, theme.buttonStyle], states);
      return AnimatedLookSurface(
        face: lookButtonFace(
// ...
          child: DesignControlBox(
            minHeight:
                look.minimumSize?.height ??
                theme.density.height(theme.controlHeight),
// ...
                  child: DesignCapCenter(
                    capHeightFactor: theme.capHeightFactor,
```

- `TapTargetPadding` outermost: the area a tap reaches is the box a screen
  reader outlines, at least 44 by 44 for touch and 24 by 24 for a pointer.
- `RawButton` gives the states: `pressed`, `hovered`, `focused` (only while
  focus should show, as a browser's focus-visible), `disabled`, `selected`,
  `error`.
- `DesignStyleOf` reads the part's own `style:`, then the theme's slot, then
  the look's default, state by state.
- `DesignControlBox` and `DesignCapCenter` put the label's capitals on the
  face's middle, so a button, a field and a chip in one row line up.

### 5. Build the rest in inventory order

Follow [inventory.md](references/inventory.md): actions, then inputs, then
navigation, containers, overlays, feedback and charts. For each part:

1. Find its ui_core API in [contract.md](references/contract.md). A row with
   a behaviour API (tabs, menus, combobox, date picker, data table, carousel,
   toaster, sheet) is painted on that API, never rebuilt.
2. Give it the semantics Flutter's own widget has. A checkbox says
   `checked`, a switch `toggled`, a toggle button `semanticSelected` (still a
   button), a radio is a `RawRadio` in a `RadioGroup`.
3. Draw every state it has, day and night, in the look's material.
4. Reuse what an earlier part decided: a select and a combobox stand on the
   text field's face and end in the same sign; every open list (a select's,
   a combobox's, a menu's) is one surface with one kind of row; every raised
   panel is one material (the samples' select and date field share one
   `LookFieldTrigger`). A part that looks like a cousin of its neighbour
   reads as a fault. [taste.md](references/taste.md) section 8 has the
   pairs that must match. A face two parts share (a resting panel, a well,
   a chosen row) is named once, on the face's class or the theme, and both
   use it; a face spelled out in three parts is one the theme is missing.
5. Write its test (step 7) before moving on.

### 6. Raise things the look's way

Each raised part (dialog, sheet, menu, popover, tooltip, toast) is shown by a
`show<Look>…` function or a widget that owns its route or overlay, scrim,
motion, dismissal (Escape, Android back, a tap outside where it applies) and
the return of focus to its opener. Build dialogs on `DesignDialogRoute` with
`RawAlertDialog`; carry the opener's themes into the route:

```dart
final themes = InheritedTheme.capture(from: context, to: navigator.context);
```

- **Actions.** `RawAlertDialog` lays its actions out on a `RawActionBar`:
  one row while they fit, else one column of one width with the confirming
  action on top. A sheet or a dialog with a footer of its own puts its
  buttons in a `RawActionBar` too, never a `Row` or a `Wrap`.
- **A modal page that is not a dialog.** A search over the page or a
  picture shown large is pushed on `RawModalRoute`: the barrier, spring,
  Escape, back, Tab kept inside and focus back of a dialog, with no role, so
  a screen reader hears the page's own words and never "dialog". Its
  heading names it (`namesRoute`).
- **Pickers.** A calendar or a grid raised from a field opens with
  `RawPopoverPlacement(fit: RawPopoverFit.whole)`, so it lands whole on
  the side that holds it; a list keeps the default and scrolls.
- **A place of the look's own.** A popover that opens where ui_core's
  placement would not put it (a menu over its own button, as iOS's pull-down
  menus open) takes a `positionDelegate`; the popover sizes it by the
  bounds it keeps to, still closes, moves the focus in and back, and names
  itself. A menu's popover takes `role: SemanticsRole.menu`.
- **Toasts.** A `RawToaster` in the app's builder holds them; the look
  paints one. A bar the look draws along the screen's foot is wrapped in
  `RawToasterKeepClear`, so a toast stands above it, never on it.

[contract.md](references/contract.md) has each.

### 7. Prove each part

For every part, a widget test that pumps it in a screen and runs the
ui_core_test checks, the guidelines, an in-motion frame, Reduce Motion,
right to left and twice the text size:

```dart
const DesignCheckableCheck(look: 'Look').check(screen).verify();
const DesignTextFieldNameCheck(look: 'Look').check(screen).verify();
const DesignFieldSemanticsCheck(look: 'Look').check(screen).verify();
const DesignTapTargetCheck(look: 'Look').check(screen).verify();
const DesignCursorCheck(look: 'Look').check(screen).verify();
```

Every screen also takes `DesignOverflowCheck` at twice the text size (no
part overflows or runs off its screen). Parts with a tooltip, a field, a list
or actions take more:

- `DesignTooltipNodeCheck`: the tip is on the control's node.
- `DesignFieldNodesCheck`: a field keeps its nodes as its text changes;
  `DesignFieldWordsCheck`: its help and error are read with it.
- `DesignListSideCheck`: an open list sits below its field while below
  holds it; `DesignOverlayCheck`: a raised surface stays on a phone's
  screen, its anchor high, in the middle or low.
- `DesignDialogActionsCheck`: a dialog's or a sheet's actions stand in one
  row or one column, at 320 and 390 wide, at 1x and 2x text.

Then look at it: shoot every part in every state at full size, day and
night, at 390 and 1440 wide, left to right and right to left, and read every
picture before calling the part done. [checks.md](references/checks.md) has
the whole list and what each check catches.

### 8. Answer the inventory

A `DesignInventory` names a live specimen for every row the look carries and
a reason for every row it leaves out. Its test calls `verify()`; a gallery
lists it with `DesignInventoryGallery`, so an absent part reads as a decision,
not a gap:

```dart
const DesignInventoryEntry.absent(
  'FloatingActionButton',
  'A floating action button is Material vocabulary; the page puts its '
      'main action in its top bar.',
),
```

### 9. Make it a package people can adopt

- A README with the look in a paragraph, install, setup under `MaterialApp`,
  `CupertinoApp` and `WidgetsApp`, five or six everyday snippets, pictures,
  accessibility and languages, and the Flutter range and platforms. The
  pictures are the review shots, day and night, copied into `doc/`, listed
  under `screenshots:` in the pubspec and shown in the README.
- Every public member documented in plain words; `dart doc` with 0 warnings.
- A short `example/lib/main.dart` that installs the theme and shows parts.
- A CHANGELOG entry per version: short present-tense lines naming the API.
- `repository:` in the pubspec names where the source really lives; never
  invent one. Until the owner gives it, the publish dry-run's warning about
  it is the one warning left.
- `dart pub publish --dry-run` with 0 warnings, but for that one.
- Nothing in `lib`, `test` or `example` but what a user of the package
  needs: no working notes, dates, review names or to-dos.

## Done means

- [ ] Every inventory row is present with a live specimen, or absent with a
      reason a designer would give; `DesignInventory.verify()` passes.
- [ ] Every interactive part has rest, hover, focus, pressed, disabled and,
      where it has them, selected, error and busy, day and night; each differs
      from rest; each change animates on the look's springs.
- [ ] Keyboard: Tab reaches every part in reading order; Enter and Space
      act; arrows move inside radio groups, tabs, menus and lists; Escape
      closes what was raised and focus returns.
- [ ] Screen readers hear each part as Flutter's own widget: role, name,
      value, state.
- [ ] Tap targets reach the floor; rows line up; labels sit on their faces'
      middles; nothing overflows at 390, 768, 1024, 1440 or at 2x text.
- [ ] Parts of one kind read as one family: a select and a combobox share
      a face and a sign; every open list is the field's own material, its
      chosen row marked one way and filled edge to edge; a disabled part
      looks unavailable; the error state is the empty state's sibling;
      destructive actions in menus and dialogs take the danger tone.
- [ ] Right to left mirrors; built-in words come from
      `RawWidgetsLocalizations`; dates and numbers follow the locale.
- [ ] Under Reduce Motion nothing overshoots or travels far, and colour
      and opacity changes settle within 150 ms.
- [ ] `dart analyze --fatal-infos`, `flutter test`, `dart doc` and
      `dart pub publish --dry-run` are clean (but for a repository not yet
      given), and every picture has been read.

## Pitfalls

- **Drawing a ring for focus because it is easy.** Focus speaks the look's
  material: a rule that thickens, a shadow that deepens, a lamp that lights.
  A part that already changes its edge gets nothing more. No halo on a ring.
  A thickened rule grows by 1 px at most, as Material's field rule does.
- **A hover wash on every part.** Outside Material-like looks, hover is the
  cursor and, at most, a quiet change the material allows.
- **Faces at different heights in one row.** One control height per density;
  the field's box, the button and the select all use it.
- **A label nudged by padding until it looks centred.** Use `DesignCapCenter`
  with the family's factor and even leading; check it with `DesignLabelCheck`.
- **A selection that fills part of its cell.** A chosen day, segment or row
  fills its whole cell, concentric with its container's corners.
- **A press that shows late.** A touch inside a scroll view waits
  `kPressTimeout` before it shows; a mouse press shows at once. Do not add
  delays of your own.
- **Disposing a controller or focus node the caller handed in.** Own one
  only when none was given; swap it in `didUpdateWidget`.
- **Two kinds of field for one kind of choice.** A select that is a raised
  key beside a combobox that is a bare text box: a reader can't tell the
  combobox opens a list. Same face, same height, same sign at the end.
- **A list that is not its field's.** A hairline panel with a soft shadow
  under a field drawn in a heavy rule; a see-through list over words; a
  chosen row marked in the accent of the screen's main action.
- **A selected row with a notch.** Its fill stops before its trailing
  button. Fill the whole row; the trailing control stands on the fill.
- **A disabled button that still looks pressable.** Full raised body, lit
  face, only the words greyed. Take away what says "press me".
- **A dialog that takes two actions.** A general dialog takes a list, as
  Material's `AlertDialog` does, and stacks them, the confirming one on top,
  all one width.
- **Words changed to pass a check.** A shorter label, a dropped word, a
  hidden helper: the check then passes and the part still fails at the
  length a real app gives it. Fix the part; if the part is right, tell the
  ui_core maintainers what the check got wrong.
- **A field's words as `label` or `hint`.** In Flutter those are `Widget`
  slots. A field's strings are `labelText`, `hintText`, `helperText` and
  `errorText`, as in `InputDecoration`, and they go to `RawInputDecorator`,
  which reads them with the field.
- **A toast over a bar.** A bottom bar the look draws is wrapped in
  `RawToasterKeepClear`; padding the toaster by the bar's height leaves a
  gap once the bar goes.
- **A card in a card.** Never nest a container in another of the same look,
  and never pad one on some sides only.
- **Re-exporting all of ui_core.** Its surface and its versions then become
  the look's.
