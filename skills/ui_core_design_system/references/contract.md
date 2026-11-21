# The contract: ui_core behaves, the look paints

ui_core 0.4.0 gives a look every behaviour a part needs and no paint. A look
wraps each part's ui_core widget, reads the states it reports, and draws the
look's face for them. This page lists what ui_core carries, how to wire each
kind of part, and the three 0.4.0 shims a look puts in place until Flutter's
own fixes reach its minimum version.

Names: ui_core 0.4.0 renamed its behaviour widgets to Flutter's `Raw*` form
(`RawButton`, `RawTabBar`, `RawAlertDialog`, `RawWidgetsLocalizations`) and
kept `Design*` for what has no Flutter counterpart (`DesignStyle`,
`DesignDialogRoute`, `DesignCapCenter`). The 0.3 names remain as deprecated
typedefs; `dart fix --apply` moves a package to the new names. Write new code
with the 0.4.0 names only.

## What ui_core carries

| Concern | ui_core | The look |
|---|---|---|
| Pressing | `RawButton`: tap, long press, Enter and Space, focus, hover, the press shown at once for a mouse and after `kPressTimeout` for a touch in a scroll view, haptics, semantics | The face for each state |
| Tap targets | `TapTargetPadding`, `DesignTapTargetScope`, `DesignTapTargets` (44 touch, 24 pointer by default), `DesignInput` | Its floors, if not the defaults |
| Choosing one | Flutter's `RadioGroup` and `RawRadio`, with `RadioGroupKeyboardFix` | The mark and the row |
| Text entry | Flutter's `TextField` (from material_ui) with `decoration: null`; `DesignTextEntryBox`, `RawInputDecorator`, `DesignForm`, `DesignFormField` | The box, rule, label, help, error |
| Layout | `DesignControlBox`, `DesignCapCenter`, `DesignDensity`, `DesignSpacingScope`, `DesignKeylineRegion` | Its control height, padding, grid |
| Style | `DesignStyle` (ten `WidgetStateProperty` slots), `DesignStyleOf` | A typedef, a slot per part in its theme, its defaults |
| Motion | `designSpring`, `DesignMotionPolicy`, `springTo`, `designReduceMotionOf` | Its tokens |
| Raised surfaces | `DesignDialogRoute`, `RawAlertDialog`, `RawBottomSheetRoute`, `RawSideSheetRoute`, `RawPopover`, `RawContextMenu`, `RawToaster`, Flutter's `RawTooltip` with `RawTooltipPlacement` | Scrim colour, frame, motion values |
| Navigation | `RawTabBar`, `RawMenuBar`, `RawCommandPalette`, `DesignAdaptiveShell`, `SwipeBackPageTransitionsBuilder` | Tabs, bars, rails, page motion |
| Words | `RawWidgetsLocalizations` (30 languages) | Its own words, if any |
| Checklist | `package:ui_core/inventory.dart`: `DesignInventoryRow`, `DesignInventory`, `DesignInventoryGallery` | Its answers |

`package:ui_core/inventory.dart` and `package:ui_core/host.dart` are outside
semantic versioning: use them in tests and galleries, never in the look's
public signatures.

## The builder pattern

Every `Raw*` part takes a builder that receives the part's states and returns
what to paint. `RawButton`'s is `(BuildContext context, Set<WidgetState>
states, Widget? child)`:

- `WidgetState.pressed`, `hovered`, `disabled` as their names say;
- `WidgetState.focused` only while focus should show: after a key moved it
  there, not after a pointer press, as a browser's `:focus-visible`;
- `WidgetState.selected` from `selected:`, `WidgetState.error` from
  `isError:`.

The builder is pure: it reads states and the theme and returns widgets. Keep
state (hover memory, animation controllers) in the face's own widget, not in
the builder.

`RawButton` also takes `onPressed` (null disables), `onLongPress`, `focusNode`,
`autofocus`, `mouseCursor`, `minimumSize`, `statesController`, `shortcuts`,
`actions`, `onKeyEvent`, `onStatesChanged`, `enableFeedback` and the semantics
of the part (next section).

## Semantics: say what Flutter's own widget says

A screen reader hears a part by its flags. Pick the one Flutter's matching
widget uses; never two.

| Part | `RawButton` flags | Heard as |
|---|---|---|
| Button | (none) | button |
| Toggle button (pin, Bold) | `selected: on, semanticSelected: on` | button, selected |
| Checkbox | `checked: value ?? false, mixed: value == null` | checkbox, checked, mixed |
| Switch | `toggled: value` | switch, on or off |
| Link | `link: true` | link |
| Disclosure | `expanded: open` | button, expanded |

`checked` and `toggled` drop the button role, as Flutter's `Checkbox` and
`Switch` do; `semanticSelected` keeps it, as `IconButton(isSelected:)` does.
Composite parts announce for themselves: a `RawTabBar`'s tabs, a
`RawRadio`'s radio, a `RawSegmentedButton`'s segments.
A part whose words do not name it passes `semanticLabel:`; a part beside its
label merges with it (`MergeSemantics`).

```dart
// A checkbox is a checkbox to a screen reader, never also a button.
checked: value ?? false,
mixed: value == null,
```

```dart
// A switch says toggled, which drops the button role.
toggled: value,
semanticLabel: semanticLabel,
```

```dart
selected: isSelected ?? false,
semanticSelected: isSelected,
```

## Style: `DesignStyle` and `DesignStyleOf`

`DesignStyle` has ten slots, each a `WidgetStateProperty`: `fill`,
`foreground`, `edge`, `overlay`, `side`, `shape`, `padding`, `minimumSize`,
`textStyle`, `iconSize`. It has `copyWith`, `merge` and `lerp`;
`DesignStyle.layered(layers)` forwards several layers as one style and
`DesignStyle.first(layers, slot, states)` reads one slot through them. A look gives it its own name and puts one slot per part in its
theme:

```dart
typedef LookStyle = DesignStyle;
```

`DesignStyleOf(layers, states)` resolves the layers nearest first, slot by
slot: the part's own `style:`, then its theme slot, then any theme-wide
knob. A slot no layer sets is null, and the look's default fills it:

```dart
final look = DesignStyleOf([style, theme.buttonStyle], states);
```

```dart
fill: look.fill ?? c.ground,
rule: look.edge ?? c.rule,
foreground: look.foreground ?? c.mutedInk,
```

It also offers `padding(TextDirection)`, `overlay`, `at(states)` (the same
layers for other states), `shapes(fallback)` (the shape slot as a
`WidgetStateProperty`) and `freeze()` (the resolved values as a plain
style). Give a part a style only for what a
designer would change on that part; decide per look which slots mean
something in its material (a glass look may not take a `side`).

## Tap targets and layout

**`TapTargetPadding`** lays a part out at the floor for the input that
reaches it (`DesignTapTargets.of(context).floorOn()`), centring its face in
the larger box, so layout, hit testing and the semantics box agree. Put it
outermost, outside `RawButton`. `alignment: AlignmentDirectional.centerStart`
keeps a checkbox's or radio's box at the start edge of its row. A row whose
gaps should also take the press wraps its content in
`MetaData(behavior: HitTestBehavior.opaque)`.

A text field is reached through its box: `DesignTextEntryBox` passes a press
anywhere in it to the editable, so make the box itself at least the floor
tall, and let a press on the rest of the face focus the entry:

```dart
minHeight: math.max(
  theme.density.height(theme.controlHeight),
  DesignTapTargets.of(context).floorOn().height,
),
```

**`DesignControlBox(minHeight:, alignment:, child:)`** stands a control's
content in a box of the control height, centred, with even leading.

**`DesignCapCenter(capHeightFactor:, child:)`** moves a one-line label so its
capitals, not its line box, sit on the face's middle. The factor is the
family's cap height over its size (Roboto 0.711; read it from the font's
`OS/2` table for another family). Use the same factor for every label and for
the text field's entry, so a row of mixed parts lines up.

**`DesignDensity`** shrinks or grows faces (`height`, `padding`,
`heightDelta`, `paddingDelta`; `standard`, `comfortable`, `compact`; `lerp`).
It never moves the tap-target floor. **`DesignSpacingScope`** carries the
spacing grid. **`DesignKeylineRegion`** and **`DesignKeylineFace`** mark the
faces a keyline check compares.

## Motion

ui_core runs motion on springs, written as a damping ratio and a stiffness:
`designSpring(dampingRatio:, stiffness:)`, and
`controller.springTo(target, spring)` (the `DesignSpringDrive` extension on
`AnimationController`), settling within `designSpringTolerance`.

`DesignMotionPolicy.of(context)` turns a token into the spring to run:

- `spatial(...)` for anything that moves, resizes or reshapes. Under Reduce
  Motion it is critically damped: no overshoot, no bounce.
- `effects(...)` for opacity and colour. Under Reduce Motion it settles
  within 150 ms: a short fade, never a cut that reads as a flash.

Read the policy where the motion starts (`didUpdateWidget`, a callback),
which is under the current `MediaQuery`. A widget that builds differently
under Reduce Motion reads `designReduceMotionOf(context)` in `build`, so it
rebuilds when the setting changes.

```dart
final motion = LookTheme.of(context).motion;
_controller.springTo(
  widget.value,
  DesignMotionPolicy.of(context).spatial(
    dampingRatio: motion.stateDampingRatio,
    stiffness: motion.stateStiffness,
  ),
);
```

## Radio groups

A radio group is Flutter's `RadioGroup<T>`, a `RawRadio<T>` per choice, and
ui_core's `RadioGroupKeyboardFix<T>` round the choices. `RawRadio` takes a
focus node of its own (own one per radio and dispose it), the group's
registry, and a builder that receives a `ToggleableStateMixin`: its `states`,
its `value` (chosen or not) and its `downPosition` (non-null while pressed).

```dart
return RadioGroup<T>(
  groupValue: value,
  onChanged: (next) {
    if (change == null || next == null || next == value) return;
    // The look's haptic for a choice, from the table an app can swap.
    DesignHaptics.of(context).selectionChanged?.call();
    change(next);
  },
  child: RadioGroupKeyboardFix<T>(
```

```dart
child: RawRadio<T>(
  value: widget.option.value,
  mouseCursor: WidgetStateMouseCursor.clickable,
  toggleable: false,
  focusNode: _node,
  autofocus: false,
  groupRegistry: RadioGroup.maybeOf<T>(context),
  enabled: widget.enabled,
  builder: (context, radio) {
    final states = radio.states;
    final chosen = radio.value ?? false;
```

`RadioGroup` takes no null `onChanged`: a group offered nothing gives a
no-op and draws its radios turned off.

## Text fields

Typing is Flutter's `TextField`: the IME, selection, autofill, spell check,
the text-field role. The look sets its `decoration` to null and draws
everything round it.

- **`DesignTextEntryBox`** stands the editable at the control height with
  one line centred, the hint drawn on the typed text's baseline while the
  text is empty, and a press anywhere in the box reaching the editable. Wrap
  it in `DesignCapCenter` with the family's factor, and in
  `Semantics(hint:)`, since the drawn hint is not heard.
- **`RawInputDecorator`** gives the field's parts to a builder
  (`RawInputDecoratorDetails`): `control` (the entry, carrying the field's
  name, hint and validity), `label`, `helper`, `error` (draw this one: it is
  announced as it appears), `labelText`, `helperText`, `errorText`,
  `required`, `enabled`, `focused`. A tap on `label` focuses the control.
- **`DesignForm`** and **`DesignFormField`** validate and save a form.
- `TextField` asks for a `Material` above it; a look on no Material adds a
  transparent one.

```dart
if (Material.maybeOf(context) == null) {
  entry = Material(type: MaterialType.transparency, child: entry);
}
return RawInputDecorator(
  labelText: widget.label,
  helperText: widget.helperText,
  errorText: widget.errorText,
  enabled: widget.enabled,
  focusNode: _focusNode,
  builder: (context, parts) => Column(
```

```dart
child: Semantics(
  hint: widget.hint,
  child: DesignCapCenter(
    capHeightFactor: theme.capHeightFactor,
    child: DesignTextEntryBox(
```

Own a controller and a focus node only when the caller gave none, dispose
only those, and drop them when the caller hands one in later.

## Dialogs

`DesignDialogRoute<T>` raises a dialog: barrier, spring in and out, Escape
and Android back, Tab kept inside, focus back to the opener, and the dialog
named for a screen reader. Its `builder` gets `DesignDialogDetails`
(`animation`, `isAlert`, `close`). It takes `isAlert`, `semanticLabel`,
`dampingRatio` and `stiffness` (and `closeDampingRatio`, `closeStiffness`),
`barrierColor` or `barrierBuilder`, `barrierLabel`, `barrierDismissible`,
`anchorPoint` and `settings`.

`RawAlertDialog` lays out an alert: `title`, `content`, `actions` (a list of
`RawDialogAction`: `label`, `onPressed`, `isDefaultAction`,
`isDestructiveAction`, `data`), between 280 and 560 wide, actions in a row
that stack (the confirming one on top) when they do not fit, and the focus on
the safe action. The look draws it through `titleBuilder`, `frameBuilder`
(`RawAlertDialogFrameDetails`: `scrolled`, `overflows`, `stacked`) and
`actionBuilder` (`RawDialogActionDetails`: `states`, `stacked`, `index`,
`count`):

```dart
// The dialog makes each action's press; the look draws its face.
actionBuilder: (context, action, details) => AnimatedLookSurface(
  face: lookButtonFace(
    theme,
    details.states,
```

The route builds under the navigator, not under the opener: capture the
opener's themes and wrap the dialog in them.

## Tooltips

A tooltip is Flutter's `RawTooltip`, with two ui_core pieces: a
`RawTooltipPlacement` round it that places the tooltip (and tells its tail
which side it is on, `RawTooltipPlacement.sideOf(context)`), and a
`RawTooltipFocusFix` round the child that shows it on keyboard focus.

```dart
return RawTooltipPlacement(
  builder: (context, positionDelegate) => RawTooltip(
    semanticsTooltip: message,
    positionDelegate: positionDelegate,
    hoverDelay: const Duration(milliseconds: 500),
    tooltipBuilder: (context, animation) => FadeTransition(
      opacity: animation,
```

```dart
child: RawTooltipFocusFix(child: child),
```

## Page transitions

A look owns its push and pop. It writes a `PageTransitionsBuilder` and gives
apps a map for `PageTransitionsTheme(builders:)`, keeping the iOS swipe back
with `SwipeBackPageTransitionsBuilder` (or `designSwipeBack(map)`, which wraps
a map's iOS entry):

```dart
TargetPlatform.iOS: SwipeBackPageTransitionsBuilder(
  LookPageTransitionsBuilder(),
),
```

Drive transitions with `animation.drive(...)` rather than a
`CurvedAnimation` made in `buildTransitions`: a `CurvedAnimation` must be
disposed, and leak tracking reports one made per build.

## Words and languages

`RawWidgetsLocalizations.of(context)` gives the words ui_core's parts say
(`cancelButtonLabel`, `okButtonLabel`, `closeButtonLabel`,
`modalBarrierDismissLabel` and more) in 30 languages. An app registers
`RawWidgetsLocalizations.delegate` beside Flutter's delegates and uses
`RawWidgetsLocalizations.supportedLocales`; a look re-exports the class so
apps need no direct ui_core dependency. Words of the look's own go in its own
localizations class, built the same way; extend
`DefaultRawWidgetsLocalizations` to change ui_core's.

```dart
localizationsDelegates: const [
  RawWidgetsLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
],
supportedLocales: RawWidgetsLocalizations.supportedLocales,
```

## Haptics

`RawButton` plays the platform's feedback on a press when `enableFeedback`
is true. `DesignHaptics` is the table of the other moments ui_core marks with
a haptic: `selectionChanged` (a step, a choice), `longPress` and
`thresholdCrossed` (a drag passing the point where letting go acts). A look's
own behaviours play from the same table,
`DesignHaptics.of(context).selectionChanged?.call()`, so an app can swap or
silence every haptic at once with a `DesignHapticsScope`
(`const DesignHaptics.silent()` for none).

## Parts painted on a ui_core behaviour

Each row on the left is built on the API on the right, painted by the look.
[inventory.md](inventory.md) has the whole checklist.

| Part | Build on |
|---|---|
| Toggle group, segmented control | `RawSegmentedButton` |
| Split button | `RawSplitButton` |
| Password field | `RawPasswordReveal` |
| Input group (add-ons) | `DesignInputGroup` |
| One-time code | `RawOtpField` |
| Number field, stepper | `RawNumberField` |
| Combobox | `RawCombobox` |
| Multi-select, tag input | `RawTagInput` |
| Range slider | `RawRangeSlider` |
| Rating | `RawRating` |
| Calendar, date and date-range picker | `RawCalendarDatePicker` |
| Time field | `RawTimeField` |
| Wheel picker | `RawPicker` |
| Colour picker | `RawColorPicker` |
| Form field | `RawInputDecorator` |
| App shell, navigation bar, rail, drawer | `DesignAdaptiveShell` |
| Tabs | `RawTabBar` |
| Menubar | `RawMenuBar` |
| Command palette | `RawCommandPalette` |
| Data table | `RawDataTableController` |
| Scroll area | `RawScrollArea` |
| Resizable panels | `RawSplitView` |
| Carousel | `RawCarousel` |
| Reorderable list | `RawReorderableList` |
| Swipe actions | `RawSwipeActions` |
| Pull to refresh | `RawRefreshIndicator` |
| Tree | `DesignTree` |
| Dialog | `DesignDialogRoute`, `RawAlertDialog` |
| Bottom sheet | `RawBottomSheetRoute` |
| Side sheet | `RawSideSheetRoute` |
| Popover, hover card | `RawPopover` |
| Menu, context menu | `RawContextMenu` |
| Toast | `RawToaster` |
| Tooltip | `RawTooltip`, `RawTooltipPlacement` |
| Charts | `DesignChart`, `DesignPieChart` |

Read each API's own documentation before painting it: it says which states
its builder gets, what it already announces, and which keys it takes.

## The 0.4.0 shims, and when they go away

Three ui_core widgets cover Flutter faults that are fixed, or being fixed, in
Flutter itself. Use them now; remove each when the look's minimum Flutter
version includes the fix.

| Shim | Put it | It fixes | Remove when |
|---|---|---|---|
| `RadioGroupKeyboardFix<T>` | Inside `RadioGroup<T>`, round the radios | One Tab stop when the chosen radio cannot take focus (it is turned off), on the first radio Tab can reach; and Left and Right following right-to-left text, so each arrow chooses the radio on its side | The minimum Flutter has both of Flutter's own fixes: the Tab stop (flutter/flutter#197072, fixed by flutter/flutter#197073) and the right-to-left arrows (on Flutter's main branch, not yet in a stable release) |
| `RawTooltipFocusFix` | Round the tooltip's child | Shows the tooltip while the child has the keyboard's focus, as a hover does, and Escape hides it (flutter/flutter#196554) | The minimum Flutter's `RawTooltip` shows on keyboard focus |
| `RawTooltipPlacement` | Round `RawTooltip` | Places the tip as ui_core places a popover (clear of the screen's edges and the keyboard) and tells it which side it took | Flutter's `RawTooltip` gives its `tooltipBuilder` the side itself |

Each shim adds no layout, semantics or focus of its own, so removing it
changes nothing but the fault it fixed.

`DesignRadioGroup` and `DesignTooltip`, the 0.3 wrappers these replace, are
deprecated.
