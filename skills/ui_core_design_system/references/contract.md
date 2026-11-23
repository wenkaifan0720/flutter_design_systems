# The contract: ui_core behaves, the look paints

ui_core gives a look every behaviour a part needs and no paint. A look
wraps each part's ui_core widget, reads the states it reports, and draws the
look's face for them. This page lists what ui_core 0.5.3 carries, how to
wire each kind of part, and the three shims a look puts in place until
Flutter's own fixes reach its minimum version.

Names: ui_core names its behaviour widgets in Flutter's `Raw*` form
(`RawButton`, `RawTabBar`, `RawAlertDialog`, `RawMenuEntry`,
`RawWidgetsLocalizations`) and keeps `Design*` for what has no Flutter
counterpart (`DesignStyle`, `DesignDialogRoute`, `DesignCapCenter`). Older
`Design*` names for the behaviours (`DesignMenuEntry`, `DesignCombobox`)
remain as deprecated typedefs that `dart fix --apply` renames. Write new code
with the `Raw*` names only.

## What ui_core carries

| Concern | ui_core | The look |
|---|---|---|
| Pressing | `RawButton`: tap, long press, Enter and Space, focus, hover, the press shown at once for a mouse and after `kPressTimeout` for a touch in a scroll view, haptics, semantics | The face for each state |
| Tap targets | `TapTargetPadding`, `DesignTapTargetScope`, `DesignTapTargets` (44 touch, 24 pointer by default), `DesignInput` | Its floors, if not the defaults |
| Choosing one | Flutter's `RadioGroup` and `RawRadio`, with `RadioGroupKeyboardFix` | The mark and the row |
| Text entry | Flutter's `TextField` (from material_ui) with `decoration: null`; `DesignTextEntryBox`, `RawInputDecorator` (label, help, error, required, invalid, read with the field), `DesignForm`, `DesignFormField` | The box, rule, label, help, error |
| Layout | `DesignControlBox`, `DesignCapCenter`, `DesignDensity`, `DesignSpacingScope`, `DesignKeylineRegion` | Its control height, padding, grid |
| Style | `DesignStyle` (ten `WidgetStateProperty` slots), `DesignStyleOf` | A typedef, a slot per part in its theme, its defaults |
| Motion | `designSpring`, `DesignMotionPolicy`, `springTo`, `designReduceMotionOf` | Its tokens |
| Raised surfaces | `DesignDialogRoute`, `RawModalRoute` (a modal page with no role), `RawAlertDialog`, `RawBottomSheetRoute`, `RawSideSheetRoute`, `RawActionBar` (a dialog's or a sheet's actions), `RawPopover` (`RawPopoverFit.whole` for a picker, `positionDelegate` for a place of the look's own), `RawContextMenu`, `RawToaster` with `RawToasterKeepClear`, Flutter's `RawTooltip` with `RawTooltipPlacement` | Scrim colour, frame, motion values |
| Lists | `RawPopover` (a select's list, a menu), `RawCombobox`, `RawTagInput`, `RawMenuEntry` (with `isDestructiveAction`): placement below the field, keys, highlight, the chosen option focused, announcements | One list surface, one row, the destructive tone |
| Navigation | `RawTabBar`, `RawTabGroup` (tabs the look lays out), `RawRovingFocusGroup` (a toolbar, a grid of choices), `RawMenuBar`, `RawCommandPalette`, `DesignAdaptiveShell`, `SwipeBackPageTransitionsBuilder` | Tabs, bars, rails, page motion |
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
label merges with it (`MergeSemantics`). A row that acts (a list row with an
`onTap`) and holds a control of its own (a "…" menu, a switch) keeps that
control beside the row's button, not inside it: `RawButton` merges what it
holds into its own node and reports focus while anything in it has focus.
Two targets, two nodes, each named; a row face painted round both reads the
row button's states through its `statesController`.

Where ui_core adds only semantics round a control (a labelled `RawButton`'s
face, a `RawInputDecorator`'s control, a `RawTabGroup`'s tabs), the
render object it puts there is a `RenderDesignSemanticsProxy`: it lays out,
paints and takes hits as its child. A look never makes one; a layout that
looks through render objects by type (one that hosts nested flows) names
that one type for all of them.

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

It also offers `padding(TextDirection)`, `overlay` (still a
`WidgetStateProperty`: resolve it with the states), `at(states)` (the same
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
It never moves the tap-target floor. So a compact density is for the
pointer: on touch the floor holds a field's box at 44 while a compact button
shrinks below it, and a row loses its one height. Offer compact where the
pointer is the input (desktop and the web on a desktop), as Material's
`VisualDensity.adaptivePlatformDensity` does, and keep standard on touch. **`DesignSpacingScope`** carries the
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
- **`RawInputDecorator`** takes the field's words and reads them with the
  field, as Material's `TextField` does: `labelText` names the entry,
  `errorText` and `helperText` are its hint, `required: true` puts the
  required flag on its node, and `invalid: true` marks it invalid with no
  words to say why. Its builder gets the parts
  (`RawInputDecoratorDetails`): `control` (the entry, carrying all of
  that), `label`, `helper` and `error` (the words as text a screen reader
  skips, since the control says them; draw these, not copies of your own,
  and the error is announced as it appears), `required` (draw the mark),
  `invalid` (paint the error state from it), `enabled`, `focused`. A tap
  on `label` focuses the control. Words a look draws beside the decorator
  instead are read on a node of their own, apart from the field, and a
  screen reader on the field never hears them: `DesignFieldWordsCheck`
  catches it.
- **The field's words are strings, named as Flutter names them**:
  `labelText`, `hintText`, `helperText`, `errorText`, as `InputDecoration`
  has them. In Flutter `label`, `hint`, `helper` and `error` are `Widget`
  slots, so a `String label` on a field reads as the wrong kind of slot.
- **`DesignForm`** and **`DesignFormField`** validate and save a form.
- `TextField` asks for a `Material` above it; a look on no Material adds a
  transparent one.
- **A press anywhere on the face focuses the entry**, the side padding too.
  Leave that tap out of the semantics tree, as Flutter's own text field
  does: the entry then stays the field's one node while controls come and
  go beside it (a clear key that shows with the first letter). A tap left
  in the tree gives the entry a node of its own once a second control
  joins; a screen reader loses its place, and on the web the browser's
  input is replaced, losing the keys typed meanwhile.
  `DesignFieldNodesCheck` catches it.
- **A tag input's entry is a line, not a lane.** In a `RawInputDecorator`,
  `RawTagInput` reads the field's words on its text entry, on one node
  beside the tags' own, and stands that node and the area a tap on it
  reaches at least a touch target about the entry's middle, inside the tag
  input and off the tags. Lay the entry out at its text's height: it needs
  no box of the floor's height round it for its node.

```dart
if (Material.maybeOf(context) == null) {
  entry = Material(type: MaterialType.transparency, child: entry);
}
// The words go to the decorator, which reads them with the field; the
// look draws the parts it hands back.
return RawInputDecorator(
  labelText: widget.labelText,
  helperText: widget.helperText,
  errorText: widget.errorText,
  required: widget.required,
  enabled: widget.enabled,
  focusNode: _focusNode,
  builder: (context, parts) => Column(
```

```dart
// The field's node carries the required flag; the
// mark is for the eye and says nothing more.
if (parts.required)
  ExcludeSemantics(
    child: Text(' *', style: TextStyle(color: c.danger)),
  ),
```

```dart
// Invalid with or without words to say why.
error: parts.invalid,
```

```dart
child: Semantics(
  hint: widget.hintText,
  child: DesignCapCenter(
    capHeightFactor: theme.capHeightFactor,
    child: DesignTextEntryBox(
```

```dart
child: GestureDetector(
  behavior: HitTestBehavior.opaque,
  excludeFromSemantics: true,
  onTap: widget.enabled ? _focusNode.requestFocus : null,
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

`RawModalRoute<T>` is the same route with no role: a modal page that is
not a dialog (a search over the page, a picture shown large). It takes the
same arguments but `isAlert` and `semanticLabel`, and its `builder` gets
`RawModalDetails` (`animation`, `close`). Its page is a route's scope
that says nothing of itself: a screen reader hears the page's own words,
so give it a heading that names the route, as a page's title does.
`DesignDialogRoute` is a `RawModalRoute` that says dialog.

```dart
// A modal page with no role: the route scopes what a reader hears, and
// the panel's heading names it.
RawModalRoute<T>(
  barrierLabel: words.modalBarrierDismissLabel,
// ...
Semantics(
  header: true,
  namesRoute: true,
  child: Text(title, style: theme.title),
),
```

`RawAlertDialog` lays out an alert: `title`, `content`, `actions` (a list of
`RawDialogAction`: `label`, `onPressed`, `isDefaultAction`,
`isDestructiveAction`, `data`), between 280 and 560 wide, and the focus on
the safe action: while one action is destructive, the first enabled action
that is not (`RawAlertDialog.safeActionIndex`). Actions are given dismissive
first and confirming last (Cancel, Discard, Save): in a row they read in
that order, the confirming one at the end; when they do not fit (long
words, a phone, twice the text size), they stack in one column, each as
wide as the dialog, the confirming one on top, never two on a line and one
under them. A `RawActionBar` lays them out. The look's own
`show<Look>Dialog` takes a list of actions too, as Material's `AlertDialog`
does, never a fixed two, and paints a destructive action in the look's
destructive tone.

The look draws it through four builders:

- `titleBuilder` and `frameBuilder` (`RawAlertDialogFrameDetails`:
  `scrolled`, `overflows`, `stacked`): the title, and the surface round it
  all, with a rule under the top edge while `scrolled`.
- `actionsBuilder` (the same details, and the bar): the room between the
  words and the actions (a gap on the look's grid, and a rule over the
  actions while the words `overflows`). Without it the actions sit right
  under the words.
- `actionBuilder` (`RawDialogActionDetails`: `states`, `stacked`, `index`,
  `count`): each action's face. The bar gives a stacked action the
  dialog's width; `details.stacked` is there for a look that draws a stack
  apart (a divider between keys, say).

```dart
// A gap on the grid between the words and the actions, and a
// rule over the actions while the words scroll under them.
actionsBuilder: (context, frame, bar) => DecoratedBox(
```

```dart
// The dialog makes each action's press and lays the actions
// out; the look draws each face.
actionBuilder: (context, action, details) => AnimatedLookSurface(
```

The route builds under the navigator, not under the opener: capture the
opener's themes and wrap the dialog in them.

### A look's own footer: `RawActionBar`

A dialog or a sheet the look lays out itself (a bottom sheet's actions, a
dialog with a footer of its own) puts its styled actions in a
`RawActionBar` and draws nothing else round them. Give them in reading
order, dismissive first and confirming last. The bar keeps them in one row
while each fits at its widest content (at the end of the row, or sharing it
equally with `expanded: true`, as a phone's dialog spreads two keys), and
mirrors the row right to left; when they don't fit, it stacks them in one
column, each as wide as the bar, the confirming one on top. Whether they fit
is read from the words at the current text size, so text at 2x stacks them
where 1x fits. `onStackedChanged` tells the look when they stack, for a
stack it draws apart. Each action keeps its own node and focus.
`DesignDialogActionsCheck` holds a dialog or a sheet to it.

```dart
// The look's own buttons, given dismissive first and
// confirming last. The bar keeps them in one row while
// they fit; else it stacks them, each as wide as the
// sheet, the confirming one on top.
RawActionBar(
  spacing: 12,
  overflowSpacing: 12,
  children: actions(context),
),
```

## Toasts

A `RawToaster` in the app's builder, under the look's theme and over every
route, holds the toasts: the queue (`maxVisible`), each toast's time
(paused under a pointer or the focus), the swipe away, F6 to reach the
newest and Escape to dismiss it, and what a screen reader hears. The look
paints one toast in `toastBuilder` from `RawToastDetails` (`toast`,
`animation`, `remaining`, `dismiss`, `runAction`) and gives its springs.
The presence animation may pass 1 on its spring: clamp it before an
`Opacity`. An app shows one with `RawToaster.of(context).show(RawToast(...))`;
a look gives that a name of its own.

```dart
// The presence spring may pass 1; an opacity stays within 0 and 1.
builder: (context, toast) => Opacity(
  opacity: details.animation.value.clamp(0.0, 1.0),
  child: toast,
),
```

A toast never covers a bar along the screen's foot or top. A
`DesignAdaptiveShell` keeps its phone bar clear by itself. A bar the look
draws itself (a bottom app bar, a docked composer, its own scaffold's
bottom slot) is wrapped in `RawToasterKeepClear`: the toasts stand above it
(below a top one), follow it as it springs in or away, and stand where they
did once it goes. The bar takes the screen's safe inset itself;
`RawToaster.padding` stays between the bar and the toasts. Never pad the
toaster by a bar's height: the bar comes and goes, and the padding stays.

```dart
// The toasts stand above the bar, and follow it as it comes and goes.
return RawToasterKeepClear(
  child: DecoratedBox(
```

## Tabs, toolbars and roving focus

A tab bar with its own strip and moving indicator is a `RawTabBar`. Tabs
the look lays out itself (words over a rule, tabs in a wrap or between
words, a vertical list) stand in a `RawTabGroup<T>`, shaped as Flutter's
`RadioGroup`: the group is a scope (`groupValue`, `onChanged`,
`selectionFollowsFocus`, `semanticLabel`), and each `RawTabGroupTab<T>`
finds it by its `value` wherever it stands below. The group gives one Tab
stop on the chosen tab, the arrows along `orientation` (mirrored right to
left), Home and End, tabs turned off passed over, the selection, and the
semantics: a tab bar whose every child is a tab, each selected or not.
Words between the tabs join the bar's name. A part with a node of its own
between the group and its tabs (a scroll view, a labelled image) leaves
the group a plain group: put a scroll view round the group, not inside it.
Each tab is a `RawButton` read as a tab; its builder paints the face for
`WidgetState.selected` and the rest. Give the type when `groupValue` may be
null (`RawTabGroup<String>`), so the tabs find the group.

```dart
return RawTabGroup<T>(
  groupValue: value,
  onChanged: onChanged,
  semanticLabel: semanticLabel,
```

```dart
for (final tab in tabs)
  RawTabGroupTab<T>(
    value: tab.value,
    enabled: onChanged != null && tab.enabled,
    builder: (context, states, _) =>
        _lookTab(context, theme, states, tab.label),
  ),
```

The same keys for any group of the look's own (a toolbar, a grid of
swatches, a row of toggles) come from `RawRovingFocusGroup` and a
`RawRovingFocusItem` round each control: one Tab stop, the arrows along
`orientation` (all four when null), `loop`, `homeAndEnd`, items turned off
passed over, and `RawRovingFocusIntent` so an app changes a key the
Flutter way. The item takes the control's own focus node (the caller makes
it, gives the same node to the control, and disposes it). The group moves
the focus only: a selection that follows the focus is made in the item's
`onMovedTo`; a selection on a press stays in the control's press. Tab
enters on the item marked `selected`, else on the first.

```dart
RawRovingFocusItem(
  focusNode: _nodes[i],
  enabled: toggle.onPressed != null,
  child: LookIconButton(
    icon: toggle.icon,
    semanticLabel: toggle.semanticLabel,
    isSelected: toggle.isSelected,
    onPressed: toggle.onPressed,
    focusNode: _nodes[i],
  ),
),
```

## Tooltips

A tooltip is Flutter's `RawTooltip`, with two ui_core pieces: a
`RawTooltipPlacement` round it that places the tooltip (and tells its tail
which side it is on, `RawTooltipPlacement.sideOf(context)`), and a
`RawTooltipFocusFix` round the child that shows it on keyboard focus. Put the
whole in a `MergeSemantics`: `RawTooltip` alone puts the tip on a node of its
own, and a screen reader then reads the tip apart from its control.
`DesignTooltipNodeCheck` catches it.

```dart
return MergeSemantics(
  child: RawTooltipPlacement(
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

## Lists, selects and menus

Every list that opens from something (a select's options, a combobox's
matches, a tag input's suggestions, a menu) is placed by ui_core and painted
by the look. Paint them all with one surface and one row, so a choice is
marked one way across the look:

- **A select** is a `RawPopover` (`arrowKeyNavigation: true`) whose anchor
  is a `RawButton` (`expanded: anchor.isOpen`, the chosen option as its
  `semanticValue`) and whose options are `RawButton`s with `selected:`.
- **A combobox** is a `RawCombobox`: the look paints its field
  (`fieldBuilder`, wiring `controller`, `focusNode` and
  `onEditingComplete: field.submit`), each option (`optionBuilder`, which
  gets `focused` for the keys' highlight, `hovered`, `selected`, `disabled`)
  and the list's panel (`surfaceBuilder`).
- **A menu** is a list of `RawMenuEntry` (`label`, `onPressed`, `children`
  for a submenu, `shortcut`, `checked`, `data`, `isDestructiveAction`) in a
  `RawContextMenu`, a `RawMenuBar`, or the look's menu button on
  `RawPopover`. The item builder gets the entry, so it reads
  `entry.isDestructiveAction` and paints Delete in the destructive tone;
  nothing else about the item changes.

A list opens below its field while below holds it, or 200 px of a longer
list, as Material's menus do; it takes the other side only when below can't
and above has more room, and otherwise fills the room and scrolls.
`RawCombobox` asks for below by default
(`optionsViewOpenDirection: OptionsViewOpenDirection.down`);
`OptionsViewOpenDirection.mostSpace` keeps Flutter's meaning, the larger
side. A `RawPopover` measures its surface before it turns, so a short list
under a low field stays below. `RawPopoverPlacement` sets the side, the
alignment, `fit`, `preferredExtent` (200) and `matchAnchorWidth` (on by
default: a list as wide as its field, wider only for its widest row, up to
`maxWidth`). A list or a menu keeps `RawPopoverFit.scroll`: it shrinks to
its side's room and scrolls. A picker that does not shrink (a calendar, a
grid of swatches, a time picker's wheels) takes `fit: RawPopoverFit.whole`:
it is measured whole, opens below while below holds it, takes the other
side when that holds it, and only scrolls where neither side does.
`DesignListSideCheck` reads both fits.

A popover the look places itself (a menu over its own button, as iOS's
pull-down menus open; a panel at a place the page knows) takes a
`positionDelegate`: it returns the surface's top-left corner in the
overlay from a `RawPopoverPositionContext` (`anchorRect`, `surfaceSize`,
`overlaySize`, `bounds`, `side`, `textDirection`, and `position` for a
popover opened at a point). The surface is still laid out by the placement
(its side, `fit`, widths); the popover still closes on Escape and a tap
outside, moves the focus in and back, and names its surface. `bounds` is
what the popover keeps to on its own (the safe area, the keyboard, the
margin): keep to it too, and mirror the place right to left.

```dart
positionDelegate: (place) {
  final size = place.surfaceSize;
  final room = place.bounds;
  final x = place.textDirection == TextDirection.ltr
      ? place.anchorRect.right - size.width
      : place.anchorRect.left;
```

```dart
placement: const RawPopoverPlacement(
  fit: RawPopoverFit.whole,
  matchAnchorWidth: false,
),
```

`focusOnOpen` moves the focus into the surface as it opens, to a widget
there with `autofocus` first, else the first focusable one. So a select
gives its chosen option `autofocus: true`, and the keys start on it, from
the keys or a pointer; a calendar takes `autofocus: true` and starts on its
chosen day (else today). The anchor's `isOpen` turns the look's chevron. A
combobox's field gets `field.isOpen` too: put it on the text input itself,
`Semantics(expanded: field.isOpen, child: input)`, as the select's button
says `expanded`, so a screen reader hears whether its list shows.

```dart
// The chosen option takes the focus as the list opens,
// from the keys or a pointer, and is kept in view.
autofocus: option == chosen,
```

```dart
// The text input says whether its list shows, as the select's
// button does: on the input itself, not round the whole field.
entry = Semantics(expanded: field.isOpen, child: entry);
```

A calendar sizes its seven day columns from its own
width: on a phone it takes its field's width, so its edges meet the
field's; from 600 px it keeps its own (`matchAnchorWidth: false`, seven
cells at the look's tap size), from the field's start edge.

A select and a combobox size alike. Given room to choose (a start-aligned
column, a toolbar), each is as wide as its label and its widest option,
as Material's `DropdownMenu` is, so it keeps one width as the choice
changes; a form that sets its fields' width (a stretched column, a
`SizedBox`) sets theirs. A text field has no options to measure and fills
what it is given; a form puts all three in one width.
`DesignListSideCheck` catches a list on the wrong side.

```dart
// A destructive row is set apart by its tone, not by anything it
// does: it is pressed, reached and read as any other.
itemBuilder: (context, entry, level, states) => lookOptionRow(
  theme,
  states,
  entry.label,
  destructive: entry.isDestructiveAction,
),
```

```dart
fieldBuilder: (context, field) {
  Widget entry = TextField(
    controller: field.controller,
    focusNode: field.focusNode,
    onEditingComplete: field.submit,
    decoration: null,
```

## Page transitions

A look owns its push and pop. It writes a `PageTransitionsBuilder` and gives
apps a map for `PageTransitionsTheme(builders:)`, keeping the iOS swipe back
with `SwipeBackPageTransitionsBuilder` (or `designSwipeBack(map)`, which wraps
a map's iOS entry and leaves one already wrapped alone):

```dart
TargetPlatform.iOS: SwipeBackPageTransitionsBuilder(
  LookPageTransitionsBuilder(),
),
```

Swipe back is wrapped once, on iOS only. Export the bare builder beside the
map: an app's own page route that wraps `SwipeBackPageTransitionsBuilder`
round the look's push (a go_router `Page`, say) takes the bare builder,
never the map's iOS entry, or the page answers the edge swipe twice.

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
| Date field (a date typed in segments) | `RawDateField` |
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
| Modal page, not a dialog | `RawModalRoute` |
| Bottom sheet | `RawBottomSheetRoute` |
| Side sheet | `RawSideSheetRoute` |
| Popover, hover card | `RawPopover` |
| Menu, context menu | `RawContextMenu` |
| Toast | `RawToaster` |
| Tooltip | `RawTooltip`, `RawTooltipPlacement` |
| Charts | `DesignChart`, `DesignPieChart` |

Read each API's own documentation before painting it: it says which states
its builder gets, what it already announces, and which keys it takes.

Charts: `DesignChart` scales its axis with `DesignLinearScale.nice`, which
counts an all-zero series (an empty week) 0 to 4 in whole steps, as a week
with data counts; `yIncludesZero` is on by default. Pass the caller's
`formatX` and `formatY` through, so an app can name its unit (hours, €) and
the reader's digits show (Arabic-Indic digits in Arabic), and never force a
chart left to right.

Reorderable lists: `reorder.handle(grip)` wraps the grip in a `Focus` that
the keys reach (Alt with Up or Down moves the row), but hands the grip no
state. Build the grip's face in a widget under it that reads
`Focus.of(context).hasPrimaryFocus`, listens for
`FocusManager.instance.highlightMode` changes, and marks keyboard focus in
the look's language, as on every other stop. A grip the keys reach that
nothing marks is a focus nobody can find.

## The shims, and when they go away

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

`DesignRadioGroup` and `DesignTooltip`, the older wrappers these replace,
are deprecated.
