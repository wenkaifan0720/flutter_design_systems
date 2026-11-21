# Examples from published looks

Excerpts from three looks built on ui_core 0.4.0, each a different material:
**brutal_ui** (hard blocks, hard shadows, no blur), **minimal_ui** (quiet
neutral surfaces, a thin accent ring) and **neumorphism_ui** (soft surfaces
extruded from their ground). Each excerpt is quoted from the package's
source; `// ...` marks lines left out. The notes after each say what to take
from it.

## A button: behaviour from ui_core, face from the look (brutal_ui)

<!-- source: brutal_ui/lib/src/brutal/button.dart -->
```dart
return RawButton(
  onPressed: busy && onPressed != null ? _stay : onPressed,
  onLongPress: busy ? null : onLongPress,
  focusNode: focusNode,
  autofocus: autofocus,
  semanticValue: busy ? 'busy' : null,
  builder: (context, states, _) {
    final layered = DesignStyleOf(
      _buttonLayers(theme, _kind, isDestructiveAction, style),
      states,
    );
    final face = _face(theme, states);
// ...
    final minimum = layered.minimumSize ?? Size(0, theme.controlHeight);
    final words = DefaultTextStyle.merge(
      // The face's words: the label's own colour is ink, which on
      // signal by night would be light words on orange.
      style: theme.textTheme.label
          .copyWith(color: face.foreground)
          .merge(layered.textStyle),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      child: DesignCapCenter(
        capHeightFactor: BrutalTheme.of(context).capHeightFactor,
        child: Text(label),
      ),
    );
// ...
    return TapTargetPadding(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minimum.width,
          minHeight: minimum.height,
        ),
```

- `RawButton` carries the press, keys, focus and semantics; a busy button
  keeps its focus and says "busy" as its value rather than turning off.
- The builder resolves the style layers for the states, computes one face,
  and draws it. Nothing in it remembers anything.
- The label is centred by its capitals (`DesignCapCenter`), and the control
  stands at the theme's one control height.
- `TapTargetPadding` lays the whole part out at the floor, so the hit area
  and the screen reader's box agree.

## Style layers, nearest first (brutal_ui)

<!-- source: brutal_ui/lib/src/brutal/button.dart -->
```dart
List<BrutalStyle?> _buttonLayers(
  BrutalThemeData theme,
  _ButtonKind kind,
  bool destructive,
  BrutalStyle? style,
) => [
  style,
  if (destructive) theme.destructiveButtonStyle,
  switch (kind) {
    _ButtonKind.framed => theme.framedButtonStyle,
    _ButtonKind.filled => theme.filledButtonStyle,
    _ButtonKind.text => theme.textButtonStyle,
  },
];
```

- The button's own `style:` wins, then a destructive slot, then the slot for
  its kind; the look's defaults fill whatever no layer sets.
- `BrutalStyle` is ui_core's `DesignStyle` under the look's name.

## A face that springs between states (brutal_ui)

<!-- source: brutal_ui/lib/src/brutal/surface.dart -->
```dart
BrutalFace get _now => BrutalFace.lerp(_from, _to, _controller.value);

@override
void didUpdateWidget(AnimatedBrutalSurface old) {
  super.didUpdateWidget(old);
  if (widget.face == _to) return;
  _from = _now;
  _to = widget.face;
  _controller.value = 0;
  _controller.springTo(
    1,
    DesignMotionPolicy.of(context).effects(
      dampingRatio: BrutalMotion.dampingRatio,
      stiffness: widget.stiffness,
    ),
  );
}
```

- A face is a value with a `lerp`; the surface springs from wherever it
  stands (`_now`) to the new face, so a press released mid-way turns back
  without a jump.
- `DesignMotionPolicy.effects` makes the same code honour Reduce Motion.
- One mechanism serves every part of the look.

## Focus in the look's own idiom (brutal_ui)

<!-- source: brutal_ui/lib/src/brutal/surface.dart -->
```dart
void _paintFocusBar(Canvas canvas, Rect bounds, Color color) {
  if (bounds.isEmpty) return;
  final thickness = BrutalMetrics.focusWidth.clamp(0.0, bounds.height);
  canvas.drawRect(
    Rect.fromLTRB(
      bounds.left,
      bounds.bottom - thickness,
      bounds.right,
      bounds.bottom,
    ),
    Paint()..color = color,
  );
}
```

- Keyboard focus is a solid colour block along the hard shadow's edge: the
  look's own material, no ring and no blur.

## A radio group on Flutter's RadioGroup (minimal_ui)

<!-- source: minimal_ui/lib/src/minimal/components/radio.dart -->
```dart
child: RadioGroup<T>(
  groupValue: value,
  // RadioGroup takes no null: a group that takes no choice gives a
  // no-op, and its options show the choice without offering it.
  onChanged: (next) {
    if (onChanged == null || next == null || next == value) return;
    HapticFeedback.selectionClick();
    onChanged(next);
  },
  child: RadioGroupKeyboardFix<T>(
```

<!-- source: minimal_ui/lib/src/minimal/components/radio.dart -->
```dart
// The target is the outermost layer, as a pressable's: the area a tap
// reaches is the box a screen reader outlines.
return minimalInlineNode(
  context,
  TapTargetPadding(
    alignment:
        MinimalTapAlignment.maybeOf(context) ?? AlignmentDirectional.center,
    child: Semantics(
      enabled: enabled,
      // One node: the radio, its label and its description.
      child: MergeSemantics(
        child: RawRadio<T>(
          value: option.value,
          mouseCursor: WidgetStateMouseCursor.clickable,
          toggleable: false,
          focusNode: _node,
          autofocus: false,
          groupRegistry: RadioGroup.maybeOf<T>(context),
          enabled: enabled,
          builder: (context, radio) {
            final pressed = enabled && radio.downPosition != null;
            final focused =
                enabled && radio.states.contains(WidgetState.focused);
```

- The group is Flutter's; `RadioGroupKeyboardFix` sits inside it, round the
  options, and adds nothing but the two key fixes.
- Each option is one semantics node (the radio and its words), with the
  target outermost.
- Pressed is read from `downPosition`, focus from `states`.

## A form field's parts (minimal_ui)

<!-- source: minimal_ui/lib/src/minimal/components/form_field.dart -->
```dart
builder: (context, parts) {
  final name = parts.label;
  final help = parts.helper;
  final wrong = parts.error;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (name != null) ...[
// ...
      MinimalFieldErrorScope(wrong: wrong != null, child: parts.control),
```

- `RawInputDecorator` hands over the parts; the look only lays them out and
  styles them. The error widget it gives is the one that is announced as it
  appears, so the look draws that one, not its own.

## A dialog that rises its own way (neumorphism_ui)

<!-- source: neumorphism_ui/lib/src/neumorphism/raised.dart -->
```dart
final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
final carried = _Carried(context, navigator.context);
return navigator.push(
  _NeumorphicDialogRoute<T>(
    barrierColor: neumorphicVeil(carried.theme.colors),
    barrierLabel: closeLabel ?? NeumorphicLocalizations.of(context).close,
    barrierDismissible: barrierDismissible,
    stiffness: neumorphicRouteStiffness(carried.theme.motion.raise),
    builder: (context, details) => carried.wrap(
      // The slab fades in as it rises a step (2.5% of the screen) to its place.
      FadeTransition(
        opacity: details.animation,
        child: SlideTransition(
          position: details.animation.drive(
            Tween(begin: const Offset(0, .025), end: Offset.zero),
          ),
          child: Builder(builder: builder),
        ),
      ),
    ),
  ),
);
```

- `DesignDialogRoute` (here a subclass) carries the barrier, Escape, back,
  focus trap and focus return; the look gives the veil's colour, the
  stiffness from its motion tokens, and the transition.
- The opener's themes are carried into the route, which builds under the
  navigator.
- The barrier's name comes from the look's localizations.

## Focus that raises the surface instead of outlining it (neumorphism_ui)

<!-- source: neumorphism_ui/lib/src/neumorphism/controls.dart -->
```dart
// Keyboard focus lifts the face: never a line, and never sunk, since pressed in means on. The wrapper stays
// in the tree: inserting it only on focus remounts stateful faces and resets their value animations.
final risen = showFocus && states.contains(WidgetState.focused);
// The hollows inside a risen face keep their depth; the wrapper stays in the tree for the same reason.
final content = child == null
    ? null
    : NeumorphicRisenFocus(risen: risen, child: child!);
```

- Focus is expressed in the material: a raised part rises further, its
  paired shadows deeper and crisper.
- The focus wrapper stays in the tree whether focused or not: inserting a
  widget on focus would remount the stateful face under it and reset its
  animations.
