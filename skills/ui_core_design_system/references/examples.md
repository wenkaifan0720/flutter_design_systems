# Examples from published designs

Excerpts from two published design packages on ui_core, each a different
material. Open a package on pub.dev to read the rest of it and see its
pictures:

- [brutal_ui](https://pub.dev/packages/brutal_ui): hard blocks, hard offset
  shadows, no blur.
- [neumorphism_ui](https://pub.dev/packages/neumorphism_ui): soft surfaces
  extruded from their ground, lit from the top start; focus raises a part.

Each excerpt is quoted from the package's source (the path above it names
the file); `// ...` marks lines left out. The notes after each say what to
take from it.

## A button: behaviour from ui_core, face from the design (brutal_ui)

<!-- source: brutal_ui/lib/src/brutal/button.dart -->
```dart
return RawButton(
  onPressed: busy && onPressed != null ? _stay : onPressed,
  onLongPress: busy ? null : onLongPress,
  focusNode: focusNode,
  autofocus: autofocus,
  semanticValue: busy ? 'busy' : null,
  builder: (context, states, _) {
    // ...
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
      // ...
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
- The label is centred by its capitals (`RawCapCenter`), and the control
  stands at the theme's one control height.
- `TapTargetPadding` lays the whole part out at the floor, so the hit area
  and the screen reader's box agree.

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

- `RawModalDialogRoute` (here a subclass) carries the barrier, Escape, back,
  focus trap and focus return; the design gives the veil's colour, the
  stiffness from its motion tokens, and the transition.
- The opener's themes are carried into the route, which builds under the
  navigator.
- The barrier's name comes from the design's localizations.

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
