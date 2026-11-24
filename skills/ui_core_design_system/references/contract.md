# The contract: ui_core behaves, the design paints

ui_core gives the design every behaviour a part needs and no paint. The
design wraps each part's ui_core widget, reads the states it reports, and
draws its own face for them. This page says how to wire each kind of part
on ui_core 0.6.0, and ends with the API each kind of part is painted on.

ui_core names its parts in Flutter's `Raw*` form, as Flutter names its
unstyled widgets. Older `Design*` names stay through 0.6 as deprecated
aliases, and `dart fix --apply` renames them; write new code with the
`Raw*` names only.

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
state (animation controllers) in the face's own widget, not in the builder.

`RawButton` also takes `onPressed` (null disables), `onLongPress`, `focusNode`,
`autofocus`, `mouseCursor`, `minimumSize`, `statesController`, `shortcuts`,
`actions`, `onKeyEvent`, `onStatesChanged`, `enableFeedback` and the semantics
of the part (next section). A press inside a scroll view shows after
`kPressTimeout`, a mouse press at once; add no delays of your own.

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
`RawRadio`'s radio, a `RawSegmentedButton`'s segments. A part whose words
do not name it passes `semanticLabel:`; a part beside its label merges with
it (`MergeSemantics`).

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

A row that acts and holds a control of its own (a "…" menu, a switch) keeps
that control beside the row's button, not inside it: `RawButton` merges what
it holds into its own node and reports focus while anything in it has
focus. Two targets, two nodes, each named; a row face painted round both
reads the row button's states through its `statesController`:

```dart
child: RawButton(
  onPressed: widget.onPressed,
  statesController: _states,
```

## Style: `RawStyle` and `RawStyleOf`

`RawStyle` has ten slots, each a `WidgetStateProperty`: `fill`,
`foreground`, `edge`, `overlay`, `side`, `shape`, `padding`, `minimumSize`,
`textStyle`, `iconSize`, with `copyWith`, `merge` and `lerp`. A design may
give it its own name and put a slot per part in its theme:

```dart
typedef TendStyle = RawStyle;
```

`RawStyleOf(layers, states)` resolves the layers nearest first, slot by
slot: the part's own `style:`, then its theme slot. A slot no layer sets is
null, and the design's default fills it:

```dart
final styled = RawStyleOf([style, theme.buttonStyle], states);
```

```dart
fill: styled.fill ?? c.ground,
rule: styled.edge ?? c.rule,
foreground: styled.foreground ?? c.mutedInk,
```

It also offers `padding(TextDirection)`, `at(states)` (the same layers for
other states) and `freeze()` (the resolved values as a plain style). Give a
part a style only for what a screen would change on it, and only the slots
that mean something in the material (a glass design may not take a `side`).

## Tap targets and layout

**`TapTargetPadding`** lays a part out at the floor for the input that
reaches it (`RawTapTargets.of(context).floorOn()`: 44 for touch, 24 for a
pointer by default), centring its face in the larger box, so layout, hit
testing and the semantics box agree. Put it outermost, outside
`RawButton`. `alignment: AlignmentDirectional.centerStart` keeps a
checkbox's or radio's box at the start edge of its row; a row whose gaps
should also take the press wraps its content in
`MetaData(behavior: HitTestBehavior.opaque)`.

**`RawControlBox(minHeight:, alignment:, child:)`** stands a control's
content in a box of the control height, centred, with even leading.

**`RawCapCenter(capHeightFactor:, child:)`** moves a one-line label so its
capitals, not its line box, sit on the face's middle. The factor is the
family's cap height over its size (Roboto 0.711; read it from the font's
`OS/2` table for another family). Use the same factor for every label and
the text field's entry, so a row of mixed parts lines up.

**`RawDensity`** shrinks or grows faces (`height(double)`,
`padding(EdgeInsets)`, never directional insets; `standard`,
`comfortable`, `compact`) and never moves the tap-target floor. So compact
is for the pointer: on touch the floor holds a field at 44 while a compact
button shrinks below it, and a row loses its one height. Offer compact
where the pointer is the input, as Material's
`VisualDensity.adaptivePlatformDensity` does. **`RawSpacingScope`** carries
the spacing grid.

## Motion

ui_core runs motion on springs, written as a damping ratio and a stiffness:
`rawSpring(dampingRatio:, stiffness:)`, and
`controller.springTo(target, spring)` (the `RawSpringDrive` extension on
`AnimationController`). `RawMotionPolicy.of(context)` turns a token into the
spring to run:

- `spatial(...)` for anything that moves, resizes or reshapes. Under Reduce
  Motion it is critically damped: no overshoot, no bounce.
- `effects(...)` for opacity and colour. Under Reduce Motion it settles
  within 150 ms: a short fade, never a cut that reads as a flash.

Read the policy where the motion starts (`didUpdateWidget`, a callback). A
widget that builds differently under Reduce Motion reads
`rawReduceMotionOf(context)` in `build`, so it rebuilds when the setting
changes. Drive transitions with `animation.drive(...)`, not a
`CurvedAnimation` made per build: that one must be disposed, and leak
tracking reports it.

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
    // The design's haptic for a choice, from the table an app can swap.
    RawHaptics.of(context).selectionChanged?.call();
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
no-op and draws its radios turned off. Flutter's group gives the
radio-group role, the arrows, wrapping and Space; the fix gives the Tab
stop when the chosen radio is turned off, and right-to-left arrows.

## Text fields

Typing is Flutter's `TextField`: the IME, selection, autofill, spell check,
the text-field role. The design sets its `decoration` to null and draws
everything round it. `TextField` asks for a `Material` above it; a design on
no Material adds a transparent one. Give it the design's cursor, selection and
handle colours (`cursorColor`, a `TextSelectionTheme`), or Material's show.

- **`RawTextEntryBox`** stands the editable at the control height with
  one line centred, the hint drawn on the typed text's baseline while the
  text is empty, and a press anywhere in the box reaching the editable. Make
  the box at least the floor tall, wrap it in `RawCapCenter` with the
  family's factor, and in `Semantics(hint:)`, since the drawn hint is not
  heard.
- **`RawInputDecorator`** takes the field's words and reads them with the
  field, as Material's `TextField` does: `labelText` names the entry,
  `errorText` and `helperText` are its hint, `required: true` puts the
  required flag on its node, and `invalid: true` marks it invalid with no
  words to say why. Its builder gets `RawInputDecoratorDetails`: `control`
  (the entry, carrying all of that), `label`, `helper` and `error` (the
  words as text a screen reader skips, since the control says them: draw
  these, not copies, and the error is announced as it appears),
  `required`, `invalid`, `enabled`, `focused`. Words drawn beside the
  decorator instead are read on a node of their own, apart from the field.
- **A press anywhere on the face focuses the entry.** Leave that tap out of
  the semantics tree, as Flutter's own field does, so the entry stays the
  field's one node while controls come and go beside it.
- **`RawForm`** and **`RawFormField`** validate and save a form.

```dart
if (Material.maybeOf(context) == null) {
  entry = Material(type: MaterialType.transparency, child: entry);
}
// The words go to the decorator, which reads them with the field; the
// design draws the parts it hands back.
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
  child: RawCapCenter(
    capHeightFactor: theme.capHeightFactor,
    child: RawTextEntryBox(
```

```dart
child: GestureDetector(
  behavior: HitTestBehavior.opaque,
  excludeFromSemantics: true,
  onTap: widget.enabled ? _focusNode.requestFocus : null,
```

Own a controller and a focus node only when the caller gave none, dispose
only those, and drop them when the caller hands one in later.

## Dialogs and sheets

`RawModalDialogRoute<T>` raises a dialog: barrier, spring in and out, Escape
and Android back, Tab kept inside, focus back to the opener, and the dialog
named for a screen reader. Its `builder` gets `RawDialogDetails`
(`animation`, `isAlert`, `close`); it takes `isAlert`, `semanticLabel`,
`dampingRatio`, `stiffness`, `barrierColor`, `barrierLabel`,
`barrierDismissible` and `settings`. `RawModalRoute<T>` is the same route
with no role, for a modal page that is not a dialog (a search over the
page, a picture shown large): its builder gets `RawModalDetails`, and a
heading names it. Either takes `closeOnEscape: false` for a page whose
Escape is its own.

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
the safe action: while one action is destructive, the first enabled one
that is not, so Enter never confirms a loss.

**A dialog takes a list of actions**, as Material's `AlertDialog` does
(Keep editing, Discard, Save), never a fixed two. They are given dismissive
first and confirming last: in a row they read in that order; when they do
not fit (long words, a phone, twice the text size), they stack in one
column, each as wide as the dialog, the confirming one on top, never two on
a line and one under them. A `RawActionBar` lays them out; whether they fit
is read from the words at the current text size. A destructive action takes
the design's destructive tone, and only the tone changes.

The design draws the dialog through four builders: `titleBuilder`,
`frameBuilder` (`RawAlertDialogFrameDetails`: `scrolled`, `overflows`,
`stacked`; a rule under the top edge while `scrolled`), `actionsBuilder`
(the room between the words and the actions; a rule over them while the
words `overflows`) and `actionBuilder` (`RawDialogActionDetails`: `states`,
`stacked`, `index`, `count`). The samples' `showTendDialog`:

```dart
Future<T?> showTendDialog<T>(
  BuildContext context, {
  required String title,
  Widget? content,
  required List<RawDialogAction> Function(BuildContext context) actions,
  bool isAlert = true,
}) {
// ...
  return navigator.push(
    RawModalDialogRoute<T>(
      isAlert: isAlert,
      barrierLabel: words.modalBarrierDismissLabel,
      barrierColor: theme.colors.ink.withValues(alpha: .32),
      dampingRatio: theme.motion.routeDampingRatio,
      stiffness: theme.motion.routeStiffness,
// ...
          child: RawAlertDialog(
            title: title,
            content: content,
            actions: actions(context),
            titleBuilder: (context, title) => Text(title, style: theme.title),
// ...
            actionBuilder: (context, action, details) => AnimatedTendSurface(
              face: tendButtonFace(
                theme,
                details.states,
                variant: details.index == details.count - 1
                    ? TendButtonVariant.filled
                    : TendButtonVariant.outlined,
                destructive: action.isDestructiveAction,
```

```dart
answer = await showTendDialog<bool>(
  context,
  title: 'Delete the draft?',
  content: const Text('It cannot be brought back.'),
  actions: (context) => [
    RawDialogAction(
      label: 'Cancel',
      onPressed: () => Navigator.pop(context, false),
    ),
    RawDialogAction(
      label: 'Delete',
      isDestructiveAction: true,
      onPressed: () => Navigator.pop(context, true),
    ),
  ],
);
```

A sheet, or a dialog the design lays out itself, puts its buttons in a
`RawActionBar`, never a `Row` or a `Wrap`, and draws nothing else round
them: one row while each fits at its widest content (at the end, or sharing
the row with `expanded: true`), mirrored right to left, else the same stack.
`onStackedChanged` says when they stack.

```dart
// The design's own buttons, laid out as a dialog's.
RawActionBar(
  spacing: 12,
  overflowSpacing: 12,
  children: actions(context),
),
```

`RawBottomSheetRoute` and `RawSideSheetRoute` raise sheets
(`RawBottomSheetPage` in a page list).

## Toasts

A `RawToaster` in the app's builder, under the design's theme and over every
route, holds the toasts: the queue (`maxVisible`), each toast's time (paused
under a pointer or the focus), the swipe away, F6 to reach the newest and
Escape to dismiss it, and what a screen reader hears. The design paints one
toast in `toastBuilder` from `RawToastDetails` (`toast`, `animation`,
`remaining`, `dismiss`, and `runAction`, null when the toast has no
action). The presence animation may pass 1 on its spring: clamp it before
an `Opacity`.

```dart
// The presence spring may pass 1; an opacity stays within 0 and 1.
builder: (context, toast) => Opacity(
  opacity: details.animation.value.clamp(0.0, 1.0),
  child: toast,
),
```

A toast never covers a bar. A bar the design draws (a bottom bar, a docked
composer) is wrapped in `RawToasterKeepClear`: the toasts stand above it,
follow it as it comes and goes, and stand where they did once it goes. The
bar takes the screen's safe inset itself. Never pad the toaster by a bar's
height: the bar comes and goes, and the padding stays.

```dart
// The toasts stand above the bar, and follow it as it comes and goes.
return RawToasterKeepClear(
  child: DecoratedBox(
```

## Tabs, toolbars and roving focus

A tab bar with its own strip and moving indicator is a `RawTabBar`. Tabs the
design lays out itself stand in a `RawTabGroup<T>`, shaped as Flutter's
`RadioGroup`: the group is a scope (`groupValue`, `onChanged`,
`selectionFollowsFocus`, `semanticLabel`), and each `RawTabGroupTab<T>` finds
it by its `value`. The group gives one Tab stop on the chosen tab, the
arrows (mirrored right to left), Home and End, tabs turned off passed over,
and a tab bar's semantics. Put a scroll view round the group, not inside
it. Give the type when `groupValue` may be null (`RawTabGroup<String>`).

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
    order: tab.order,
    builder: (context, states, _) =>
        _tendTab(context, theme, states, tab.label),
  ),
```

Any other group of the design's (a toolbar, a grid of swatches, a row of
toggles) takes the same keys from `RawRovingFocusGroup` and a
`RawRovingFocusItem` round each control: one Tab stop, the arrows along
`orientation` (all four when null), `loop`, `homeAndEnd`. The item takes the
control's own focus node (the caller makes it and disposes it). The group
moves the focus only: a selection that follows the focus is made in the
item's `onMovedTo`. Tab enters on the item marked `selected`, else the first.

```dart
RawRovingFocusItem(
  focusNode: _nodes[i],
  enabled: toggle.onPressed != null,
  child: TendIconButton(
    icon: toggle.icon,
    semanticLabel: toggle.semanticLabel,
    isSelected: toggle.isSelected,
    onPressed: toggle.onPressed,
    focusNode: _nodes[i],
  ),
),
```

## Tooltips

A tooltip is Flutter's `RawTooltip`, with `RawTooltipPlacement` round it
(placing the tip clear of the edges and the keyboard, and telling its tail
the side, `RawTooltipPlacement.sideOf(context)`) and `RawTooltipFocusFix`
round the child (showing it on keyboard focus, hiding it on Escape). Put the
whole in a `MergeSemantics`: `RawTooltip` alone puts the tip on a node of
its own, read apart from its control.

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

Every list that opens from something is placed by ui_core and painted by
the design, all with one surface and one row ([taste.md](taste.md), "Parts
of one kind"):

- **A select** is a `RawPopover` (`arrowKeyNavigation: true`) whose anchor
  is a `RawButton` (`expanded: anchor.isOpen`, the chosen option as its
  `semanticValue`) and whose options are `RawButton`s with `selected:`.
- **A combobox** is a `RawCombobox`: the design paints its field
  (`fieldBuilder`, wiring `controller`, `focusNode` and
  `onEditingComplete: field.submit`), each option (`optionBuilder`, which
  gets `focused` for the keys' highlight, `hovered`, `selected`, `disabled`)
  and the panel (`surfaceBuilder`).
- **A menu** is a list of `RawMenuEntry` (`label`, `onPressed`, `children`
  for a submenu, `shortcut`, `checked`, `isDestructiveAction`) in a
  `RawContextMenu`, a `RawMenuBar`, or the design's menu button on
  `RawPopover` with `role: SemanticsRole.menu`. The item builder reads
  `entry.isDestructiveAction` and paints Delete in the destructive tone.

A list opens below its field while below holds it, or 200 px of a longer
list, and takes the other side only when below can't and above has more
room. `RawPopoverPlacement` sets the side, `fit`, `preferredExtent` (200) and
`matchAnchorWidth` (on by default, up to `maxWidth`). A list keeps
`RawPopoverFit.scroll`; a picker that does not shrink (a calendar, a grid of
swatches) takes `fit: RawPopoverFit.whole`, and caps its surface at the
`maxSize` its `RawPopoverInfo` gives, scrolling inside, for a screen where
neither side holds it. A popover the design places
itself (a menu over its own button) takes a `positionDelegate` returning
the surface's top-left from a `RawPopoverPositionContext` (`anchorRect`,
`surfaceSize`, `overlaySize`, `bounds`, `side`, `textDirection`); keep to
`bounds` and mirror right to left.

```dart
positionDelegate: (place) {
  final size = place.surfaceSize;
  final room = place.bounds;
  final x = place.textDirection == TextDirection.ltr
      ? place.anchorRect.right - size.width
      : place.anchorRect.left;
```

`focusOnOpen` moves the focus into the surface as it opens, to a widget with
`autofocus` first: a select gives its chosen option `autofocus: true`, so the
keys start on it. A combobox puts `field.isOpen` on its text input, so a
screen reader hears whether its list shows.

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

```dart
fieldBuilder: (context, field) {
  Widget entry = TextField(
    controller: field.controller,
    focusNode: field.focusNode,
    onEditingComplete: field.submit,
    decoration: null,
```

A calendar takes its field's width on a phone; from 600 px it keeps its own
(`matchAnchorWidth: false`, seven cells at the design's tap size).

## Pages and where a screen stands

The design owns its push and pop: a `PageTransitionsBuilder` and a map for
`PageTransitionsTheme(builders:)`, keeping the iOS swipe back with
`SwipeBackPageTransitionsBuilder`:

```dart
TargetPlatform.iOS: SwipeBackPageTransitionsBuilder(
  TendPageTransitionsBuilder(),
),
```

`RawPageRoute` (`Navigator.push`, with a `transitionsBuilder`) and `RawPage`
(a router's pages) play the design's builder, wrap the swipe back round it
on iOS alone, and fade under Reduce Motion.

```dart
class TendPage<T> extends RawPage<T> {
// ...
  const TendPage({
    required super.child,
    super.fullscreenDialog,
    super.key,
    super.name,
    super.arguments,
  }) : super(transitionsBuilder: const TendPageTransitionsBuilder());
}
```

A screen's bar follows how its route is presented:
`RoutePresentation.of(context)` is `root` (no back or close), `pushed` (a
back key) or `sheet` (a popup or a `fullscreenDialog` page: a close key).
`dismissLabel(context)` gives that key's words. Never read the navigator's
`canPop`: a sheet over a root makes it true for the root too.

```dart
final at = RoutePresentation.of(context);
final label = at.dismissLabel(context);
if (label == null) return const SizedBox.shrink();
return TendIconButton(
  icon: at == RoutePresentation.sheet ? Icons.close : Icons.arrow_back,
  semanticLabel: label,
  onPressed: () => Navigator.maybePop(context),
);
```

## Words and haptics

`RawWidgetsLocalizations.of(context)` gives the words ui_core's parts say
(`cancelButtonLabel`, `okButtonLabel`, `closeButtonLabel`,
`modalBarrierDismissLabel` and more) in 30 languages. Register
`RawWidgetsLocalizations.delegate` beside Flutter's delegates (SKILL.md, step
2); extend `DefaultRawWidgetsLocalizations` to change the words.

`RawButton` plays the platform's feedback on a press when `enableFeedback`
is true. The design's own moments play from `RawHaptics`
(`selectionChanged`, `longPress`, `thresholdCrossed`), as
`RawHaptics.of(context).selectionChanged?.call()`, so an app can swap or
silence them all with a `RawHapticsScope`.

## Parts and the API they are painted on

Each part is built on the API beside it and painted by the design. A part
drawn by the design alone (an app bar, a card, a badge, a progress bar)
still takes its press from `RawButton` wherever it acts. Read each API's own
documentation before painting it: it says which states its builder gets,
what it already announces, and which keys it takes.

| Part | Build on |
|---|---|
| Button, icon button, chip, card or row that acts | `RawButton` |
| Checkbox, switch, toggle button | `RawButton(checked:, mixed:)`, `RawButton(toggled:)`, `RawButton(semanticSelected:)` |
| Radio group | `RadioGroup`, `RawRadio`, `RadioGroupKeyboardFix` |
| Text field, search field | `TextField`, `RawTextEntryBox`, `RawInputDecorator` |
| Segmented control | `RawSegmentedButton` |
| Split button | `RawSplitButton` |
| Toolbar, a grid of choices | `RawRovingFocusGroup`, `RawRovingFocusItem` |
| Password, one-time code, number field | `RawPasswordReveal`, `RawOtpField`, `RawNumberField` |
| Input group (add-ons) | `RawInputGroup` |
| Select, popover, hover card | `RawPopover` |
| Combobox | `RawCombobox` |
| Tag input, multi-select | `RawTagInput` |
| Slider, range slider, rating | `RawValueHandle`, `RawRangeSlider`, `RawRating` |
| Calendar, date picker | `RawCalendarDatePicker` in a `RawPopover` (`RawPopoverFit.whole`) |
| Date field, time field | `RawDateField`, `RawTimeField` |
| Wheel picker, colour picker | `RawPicker`, `RawColorPicker` |
| App shell, navigation bar, rail, drawer | `RawAdaptiveShell` |
| Tabs | `RawTabBar`, `RawTabGroup` |
| Menubar, command palette | `RawMenuBar`, `RawCommandPalette` |
| Menu, context menu | `RawContextMenu`, `RawPopover`, `RawMenuEntry` |
| Data table | `RawDataTableController` |
| Scroll area, resizable panels | `RawScrollArea`, `RawSplitView` |
| Carousel, tree | `RawCarousel`, `RawTree` |
| Reorderable list | `RawReorderableList` |
| Swipe actions, pull to refresh | `RawSwipeActions`, `RawRefreshIndicator` |
| Dialog | `RawModalDialogRoute`, `RawAlertDialog` |
| Modal page, not a dialog | `RawModalRoute` |
| Bottom sheet, side sheet | `RawBottomSheetRoute`, `RawSideSheetRoute`, `RawActionBar` |
| Toast | `RawToaster`, `RawToasterKeepClear` |
| Tooltip | `RawTooltip`, `RawTooltipPlacement`, `RawTooltipFocusFix` |
| Charts | `RawChart`, `RawPieChart` |

A reorderable list builds each row's grip with `reorder.buildHandle`: the
grip takes the keys (Alt with Up or Down moves the row), and its builder
gets the grip's states as a `RawButton`'s does, so mark its focus as every
other stop's.

```dart
reorder.buildHandle((context, states, _) => _tendGrip(theme, states)),
```
