/// Expressive's interaction states: [ExpressiveStateLayers] (Compose's
/// `StateTokens`: the hover, focus, pressed and dragged overlays),
/// [ExpressivePressable] — the one pressable every button, icon button,
/// split button, button group, FAB, chip, navigation item and list row is
/// built on — and [ExpressiveMinimumInteractiveSize] (Compose's
/// `minimumInteractiveComponentSize`). Owner: w1-host, with
/// `test/states_test.dart` and the gallery's states demo.
///
/// What Compose does, and what the pressable does for a component:
///
/// - **State layers.** Hover, focus and drag draw an overlay of the content
///   colour at the `StateTokens` opacity (0.08 · 0.10 · 0.16) over the
///   container (Compose's `StateLayer`, drawn by `ripple()` over the
///   content). Focus is the focus state layer: Compose's default
///   `RippleThemeConfiguration` (`OpacityFocusThemeConfiguration`) draws no
///   ring.
/// - **Focus ring.** Under keyboard focus (Flutter's traditional highlight
///   mode, as a desktop or a hardware keyboard brings), the pressable also
///   draws the M3 focus indicator around its shape ([ExpressiveFocusRing]):
///   3dp in `secondary`, 2dp out from the edge, from the Material token
///   DB's `md.comp.*.focus.indicator.*` (the 1.5 jar carries the colour,
///   not the thickness or the offset). A layer alone is not seen at 3:1; the
///   ring is. A touch never shows it.
/// - **Ripple.** A press draws the platform ripple in the content colour at
///   the pressed opacity (0.10): the sparkle ripple on Android, the radial
///   ripple elsewhere (whatever splash the host's
///   Material theme names), bounded by the component's shape
///   or unbounded at a token radius (checkbox, radio, switch handles),
///   centred on the pressable or on the part [ExpressivePressable.inkRect]
///   names (the switch's thumb, as Compose puts its unbounded ripple on the
///   thumb while the toggleable is the whole switch).
///   Pressed draws no separate state layer, as on Compose's Android ripple.
/// - **Press and selected shape morph.** A component passes its token
///   shapes ([ExpressivePressShapes]: rest, pressed, selected — Compose's
///   `ButtonShapes` and toggle `checkedShape`) and its motion key
///   (`ButtonBehavior.pressMotion`, `ToggleButtonBehavior.shapeMotion`, …).
///   The pressable springs the corners between them: pressed wins, then
///   selected, then rest (Compose's `shapeByInteraction`).
/// - **Width.** A button group widens the pressed button and squeezes its
///   neighbours: the group listens to [ExpressivePressable.onPressedChanged]
///   and springs the widths itself (`ButtonGroupBehavior`).
/// - **Elevation** by state on a spring ([ExpressiveStateElevation],
///   `elevation.dart`), **semantics** by role ([ExpressivePressRole]),
///   keyboard focus and activation, and the 48dp minimum touch target.
/// - **Controls inside.** Compose's `clickable` leaves a clickable inside it
///   alone (a search bar's trailing icons and avatar, a list item's
///   trailing button, a button on a card): the child consumes its own
///   press, and `mergeDescendants` stops at it. So the pressable hit-tests
///   its content before its ink, a touch on a pressable inside that takes
///   input is that one's alone, and the semantics merge the content except
///   such a pressable, which keeps a node of its own
///   ([ExpressiveSemanticsGroup]).
///
/// A component never reimplements any of this (wave decision F3).
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show TargetPlatform, kIsWeb, setEquals;
import 'package:material_ui/material_ui.dart'
    show
        InkResponse,
        InkRipple,
        InkSparkle,
        InteractiveInkFeatureFactory,
        Material,
        MaterialType,
        NoSplash,
        RectCallback,
        Theme;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'component_themes.dart';
import 'elevation.dart';
import 'internal/focus_ring.dart';
import 'internal/tokens/behavior.g.dart';
import 'internal/width_probe.dart';
import 'motion.dart';
import 'theme.dart';

/// A pressable's shapes (Compose's `ButtonShapes`, plus a toggle's
/// `checkedShape`): at rest, while pressed, and while selected. Pressed
/// wins over selected, selected over rest.
@immutable
class ExpressivePressShapes {
  /// Shapes of a pressable: [shape] at rest, with [pressed], [selected],
  /// [focused] and [hovered] variants.
  const ExpressivePressShapes({
    required this.shape,
    this.pressed,
    this.selected,
    this.focused,
    this.hovered,
  });

  /// One shape in every state: no morph.
  const ExpressivePressShapes.all(this.shape)
    : pressed = null,
      selected = null,
      focused = null,
      hovered = null;

  /// The shape at rest.
  final OutlinedBorder shape;

  /// The shape while pressed; [shape] when null.
  final OutlinedBorder? pressed;

  /// The shape while selected (checked); [shape] when null.
  final OutlinedBorder? selected;

  /// The shape while focused from the keyboard; [shape] when null.
  final OutlinedBorder? focused;

  /// The shape while a pointer hovers it; [shape] when null.
  final OutlinedBorder? hovered;

  /// The shape for the interaction (Compose's `shapeByInteraction`, as
  /// `ListItemShapes.shapeForInteraction` orders it): pressed, then
  /// selected, then focused, then hovered, then [shape].
  OutlinedBorder resolve({
    required bool pressed,
    bool selected = false,
    bool focused = false,
    bool hovered = false,
  }) {
    if (pressed && this.pressed != null) return this.pressed!;
    if (selected && this.selected != null) return this.selected!;
    if (focused && this.focused != null) return this.focused!;
    if (hovered && this.hovered != null) return this.hovered!;
    return shape;
  }

  @override
  bool operator ==(Object other) =>
      other is ExpressivePressShapes &&
      other.shape == shape &&
      other.pressed == pressed &&
      other.selected == selected &&
      other.focused == focused &&
      other.hovered == hovered;

  @override
  int get hashCode => Object.hash(shape, pressed, selected, focused, hovered);
}

/// What a pressable is to assistive technology.
enum ExpressivePressRole {
  /// A button (Compose `Role.Button`).
  button,

  /// A toggle button: a button that is on or off (Compose's toggleable
  /// buttons, `Role.Checkbox` semantics; announced as toggled).
  toggle,

  /// A tab: one of a set, selected or not (`Role.Tab`). Its node holds its
  /// tap, so its label is the control's (a navigation item, whose pill,
  /// icon and label stand beside its pressable, states its own).
  tab,

  /// A checkbox (`Role.Checkbox`).
  checkbox,

  /// A radio button, one of a mutually exclusive group (`Role.RadioButton`).
  radio,

  /// A link.
  link,

  /// No role of its own: the component states its semantics itself.
  none,
}

/// The one pressable of Expressive (see the library doc): a surface on a
/// spring-morphing shape, filled with [color], casting [elevation], its
/// content in [contentColor], with state layers, the ripple, focus,
/// keyboard activation, semantics and the minimum touch target.
///
/// Disabled when both [onPressed] and [onLongPress] are null: no ripple,
/// no state layers, no focus; the component passes its disabled colours.
class ExpressivePressable extends StatefulWidget {
  /// A pressable showing [child] on [shapes], filled with [color].
  const ExpressivePressable({
    required this.shapes,
    required this.motion,
    required this.color,
    required this.contentColor,
    required this.child,
    this.style,
    this.componentStyle,
    this.onPressed,
    this.onLongPress,
    this.onPressedChanged,
    this.busy = false,
    this.selected = false,
    this.dragged = false,
    this.error = false,
    this.role = ExpressivePressRole.button,
    this.semanticsRole,
    this.semanticLabel,
    this.tooltip,
    this.side = BorderSide.none,
    this.elevation = ExpressiveStateElevation.none,
    this.elevationMotion = ExpressiveMotionKey.defaultEffects,
    this.tonalElevation = ExpressiveElevationLevel.level0,
    this.colorMotion = ExpressiveMotionKey.fastEffects,
    this.bounded = true,
    this.rippleRadius,
    this.inkRect,
    this.minimumInteractiveSize = true,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
    this.mouseCursor,
    this.stateLayers = true,
    this.focusRect,
    this.focusShape,
    this.focusInward = false,
    this.markFace = false,
    super.key,
  });

  /// Per-widget visual overrides, ahead of [componentStyle].
  final ExpressiveComponentThemeData? style;

  /// The containing component's theme.
  final ExpressiveComponentThemeData? componentStyle;

  /// The shapes the container morphs between: a component's tokens.
  final ExpressivePressShapes shapes;

  /// The spring the shape morphs on: the component's motion key.
  final ExpressiveMotionKey motion;

  /// The container colour (the component's disabled colour when disabled).
  final Color color;

  /// The content colour: text and icons inherit it; state layers and the
  /// ripple are drawn in it.
  final Color contentColor;

  /// The content, laid out by the component (padding, row, sizes).
  final Widget child;

  /// What a tap (or Enter/Space when focused) does.
  final VoidCallback? onPressed;

  /// What a long press does.
  final VoidCallback? onLongPress;

  /// Told when the press starts and ends: a button group springs widths on
  /// it.
  final ValueChanged<bool>? onPressedChanged;

  /// Waiting on its own action (the design kit's busy press): it keeps its
  /// focus, its face and its node for a screen reader, draws no ripple, and
  /// a press does nothing, so a control at work changes neither its node
  /// nor its actions.
  final bool busy;

  /// Whether the pressable is selected (checked): the selected shape, and
  /// the role's selected or toggled semantics.
  final bool selected;

  /// Whether the pressable is being dragged: the dragged state layer.
  final bool dragged;

  /// Whether validation failed; available to stateful visual overrides.
  final bool error;

  /// What the pressable is to assistive technology.
  final ExpressivePressRole role;

  /// The node's role for assistive technology beyond [role], as Flutter's
  /// `Semantics.role` sets it: [SemanticsRole.tab] for a tab bar's tab or a
  /// navigation item, as Flutter's `TabBar` and `NavigationBar` mark theirs.
  final SemanticsRole? semanticsRole;

  /// What a screen reader says, over the content's own text.
  final String? semanticLabel;

  /// A tooltip message, announced as the pressable's hint.
  final String? tooltip;

  /// The outline stroke (outlined components).
  final BorderSide side;

  /// Shadow elevation by state.
  final ExpressiveStateElevation elevation;

  /// The spring elevation changes run on.
  final ExpressiveMotionKey elevationMotion;

  /// Tonal elevation (a `surface`-coloured container only).
  final ExpressiveElevationLevel tonalElevation;

  /// The spring a change of [color] or [contentColor] runs on: the fast
  /// effects spring unless set, so a press, a choice, a hover's colour or
  /// a part turning disabled cross-fades from where it is, never jumps
  /// (Compose's buttons change at once; the package animates every state
  /// change). Null changes them at once.
  final ExpressiveMotionKey? colorMotion;

  /// Whether the ripple and state layers are clipped to the shape (true)
  /// or drawn as a halo of [rippleRadius] around the centre (false:
  /// checkbox, radio and switch handles). The halo takes the pressable's
  /// own shape: a circle where that shape is round on a square (Compose's
  /// state layer), a square where an app's shape scale made it square.
  final bool bounded;

  /// The unbounded ripple's radius (a component token); ignored when
  /// [bounded].
  final double? rippleRadius;

  /// Where the unbounded ripple and state layers centre: the rect, in the
  /// pressable's own box of [Size], they are drawn around (a part that
  /// moves, like the switch's thumb, is read again each time ink starts).
  /// The whole pressable when null; ignored when [bounded]. The ink then
  /// reaches [rippleRadius] past the pressable, so a circle about a part at
  /// its edge is drawn whole.
  final Rect Function(Size size)? inkRect;

  /// Whether a smaller container keeps Compose's 48dp touch target around
  /// it ([ExpressiveMinimumInteractiveSize]).
  final bool minimumInteractiveSize;

  /// The focus node; one is made when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// A controller reporting and driving the interaction states.
  final WidgetStatesController? statesController;

  /// The mouse cursor; the clickable cursor when enabled.
  final MouseCursor? mouseCursor;

  /// Whether hover, focus, drag and a press draw their state layers and the
  /// ripple. False for a part whose touch target is larger than anything it
  /// draws (a sheet's drag handle): a layer there fills the invisible
  /// target, a box whose edges nothing on screen explains. Keyboard focus
  /// still draws the focus ring, around [focusRect].
  final bool stateLayers;

  /// Where the focus ring goes, in the pressable's own box of [Size]: the
  /// part a person sees (a drag handle's bar), when it is smaller than the
  /// pressable. The whole pressable when null.
  final Rect Function(Size size)? focusRect;

  /// The outline the focus ring follows around [focusRect]; the
  /// pressable's own shape when null.
  final OutlinedBorder? focusShape;

  /// Whether the focus ring stands inside the part, its outer edge on the
  /// part's edge (Material's web list items): for rows stacked flush, where
  /// a ring outside would lie under the next row's container.
  final bool focusInward;

  /// Whether its drawn face (the surface, inside any 48dp target around it)
  /// is marked for the alignment checks ([DesignKeylineFace]): a face too
  /// faint on its page to read by its pixels (an unchosen tonal segment) is
  /// then read by the face's own box, never by the target around it.
  final bool markFace;

  @override
  State<ExpressivePressable> createState() => _ExpressivePressableState();
}

class _ExpressivePressableState extends State<ExpressivePressable> {
  WidgetStatesController? _ownController;
  bool _pressed = false;

  /// Whether focus is a keyboard's: read when built, never kept. On a phone
  /// whose highlight mode is still the platform's default, a mouse
  /// connecting turns it traditional without telling any listener, so a
  /// copy kept from before would never ring a part Tab later reaches (the
  /// bottom sheet's drag handle, 11-09).
  bool get _keyboard =>
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  WidgetStatesController get _controller =>
      widget.statesController ?? (_ownController ??= WidgetStatesController());

  bool get _enabled =>
      widget.busy || widget.onPressed != null || widget.onLongPress != null;

  static void _wait() {}

  @override
  void initState() {
    super.initState();
    _controller.addListener(_statesChanged);
    _controller.update(WidgetState.disabled, !_enabled);
    FocusManager.instance.addHighlightModeListener(_highlightModeChanged);
  }

  void _highlightModeChanged(FocusHighlightMode mode) {
    if (mounted && _controller.value.contains(WidgetState.focused)) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(ExpressivePressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statesController != widget.statesController) {
      (oldWidget.statesController ?? _ownController)?.removeListener(
        _statesChanged,
      );
      if (widget.statesController != null) {
        _ownController?.dispose();
        _ownController = null;
      }
      _controller.addListener(_statesChanged);
    }
    _controller.update(WidgetState.disabled, !_enabled);
    if (!_enabled) _controller.update(WidgetState.pressed, false);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_highlightModeChanged);
    _controller.removeListener(_statesChanged);
    _ownController?.dispose();
    super.dispose();
  }

  void _statesChanged() {
    final pressed = _controller.value.contains(WidgetState.pressed);
    if (pressed != _pressed) {
      _pressed = pressed;
      widget.onPressedChanged?.call(pressed);
    }
    if (mounted) setState(() {});
  }

  Set<WidgetState> get _states => <WidgetState>{
    ..._controller.value,
    if (!_enabled) WidgetState.disabled,
    if (widget.selected) WidgetState.selected,
    if (widget.dragged) WidgetState.dragged,
    if (widget.error) WidgetState.error,
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.expressiveTheme;
    final layers = theme.states;
    final states = _states;
    final enabled = _enabled;
    final resolved =
        (widget.componentStyle ?? const ExpressiveComponentThemeData()).merge(
          widget.style,
        );
    final target =
        resolved.shape?.resolve(states) ??
        widget.shapes.resolve(
          pressed: _pressed,
          selected: widget.selected,
          focused: _keyboard && states.contains(WidgetState.focused),
          hovered: states.contains(WidgetState.hovered),
        );

    // The focus ring fades in and out on the fast effects spring (ringT,
    // 0 to 1) rather than appearing at once.
    final ringOn = _keyboard && enabled && states.contains(WidgetState.focused);

    Widget paint(
      Color color,
      Color content,
      double ringT,
    ) => ExpressiveSpringShape(
      value: target,
      motion: widget.motion,
      builder: (context, shape, _) {
        final outlined = shape is OutlinedBorder ? shape : target;
        final ink = _ink(
          layers,
          content,
          outlined,
          enabled,
          resolved.overlayColor,
        );
        final dragLayer = widget.dragged && enabled && widget.stateLayers
            ? layers.layerOf(content, const <WidgetState>{WidgetState.dragged})
            : null;
        final outline = resolved.outline?.resolve(states);
        final side =
            resolved.side?.resolve(states) ??
            widget.side.copyWith(
              color: outline,
              style: outline == null ? null : BorderStyle.solid,
            );
        final surface = ExpressiveSurface(
          shape: outlined,
          side: side,
          color: color,
          contentColor: content,
          tonalElevation: widget.tonalElevation,
          shadowElevation: widget.elevation.resolve(states),
          elevationMotion: widget.elevationMotion,
          clipBehavior: widget.bounded ? Clip.antiAlias : Clip.none,
          child: _PressableLayers(
            enabled: enabled,
            children: <Widget>[
              ExpressiveStyleScope(
                style: resolved,
                states: states,
                inset:
                    (resolved.shape?.resolve(states) != null ||
                        resolved.side?.resolve(states) != null ||
                        outline != null)
                    ? outlined.copyWith(side: side).dimensions
                    : EdgeInsets.zero,
                child: widget.child,
              ),
              if (dragLayer != null)
                Positioned.fill(
                  child: IgnorePointer(child: ColoredBox(color: dragLayer)),
                ),
              _inkLayer(ink),
            ],
          ),
        );
        // Always the one CustomPaint, so the ring coming and going never
        // remounts the surface (and the focus node inside it).
        return CustomPaint(
          foregroundPainter: ringT > 0
              ? _FocusRingPainter(
                  shape: widget.focusShape ?? outlined,
                  rect: widget.focusRect,
                  inward: widget.focusInward,
                  // A filled row or segment keeps the surface between its
                  // face and an inward ring (paintExpressiveFocusRing).
                  gap: widget.focusInward && color.a > 0
                      ? theme.colors.surface.withValues(
                          alpha: theme.colors.surface.a * ringT,
                        )
                      : null,
                  color: theme.colors.secondary.withValues(
                    alpha: theme.colors.secondary.a * ringT,
                  ),
                  textDirection: Directionality.maybeOf(context),
                  thickness: ExpressiveFocusRing.thickness,
                )
              : null,
          child: widget.markFace ? DesignKeylineFace(child: surface) : surface,
        );
      },
    );

    Widget pressable = ExpressiveSpringTween<double>(
      value: ringOn ? 1 : 0,
      motion: ExpressiveMotionKey.fastEffects,
      lerp: (a, b, t) => a + (b - a) * t,
      builder: (context, ringT, _) => widget.colorMotion == null
          ? paint(
              resolved.backgroundColor?.resolve(states) ?? widget.color,
              resolved.foregroundColor?.resolve(states) ?? widget.contentColor,
              ringT,
            )
          : ExpressiveSpringColor(
              value: resolved.backgroundColor?.resolve(states) ?? widget.color,
              motion: widget.colorMotion!,
              builder: (context, color, _) => ExpressiveSpringColor(
                value:
                    resolved.foregroundColor?.resolve(states) ??
                    widget.contentColor,
                motion: widget.colorMotion!,
                builder: (context, content, _) => paint(color, content, ringT),
              ),
            ),
    );

    if (widget.minimumInteractiveSize) {
      pressable = ExpressiveMinimumInteractiveSize(child: pressable);
    }
    // Whether the parent fixed the width (a button group squishing its
    // members): content under a [ExpressiveFillProbedWidth] then fills it and centres.
    pressable = ExpressiveWidthProbe(child: pressable);
    return ExpressiveSemanticsGroup(
      interactive: enabled,
      child: Semantics(
        enabled: enabled,
        role: widget.semanticsRole,
        button:
            widget.role == ExpressivePressRole.button ||
            widget.role == ExpressivePressRole.toggle,
        toggled: widget.role == ExpressivePressRole.toggle
            ? widget.selected
            : null,
        selected: widget.role == ExpressivePressRole.tab
            ? widget.selected
            : null,
        checked:
            widget.role == ExpressivePressRole.checkbox ||
                widget.role == ExpressivePressRole.radio
            ? widget.selected
            : null,
        inMutuallyExclusiveGroup: widget.role == ExpressivePressRole.radio
            ? true
            : null,
        link: widget.role == ExpressivePressRole.link ? true : null,
        // A tab's node holds its tap, as Flutter's tab does (an InkWell
        // round its label): the ripple's InkResponse here is a layer over
        // the content, not round it, so the tab node is what a reader takes
        // as the control, label and all.
        onTap: widget.role == ExpressivePressRole.tab && enabled
            ? (widget.busy ? _wait : widget.onPressed)
            : null,
        label: widget.semanticLabel,
        tooltip: widget.tooltip,
        child: pressable,
      ),
    );
  }

  /// Places [ink] over the content: over the whole pressable, or, when the
  /// ink is unbounded, reaching the ripple's radius past it.
  Widget _inkLayer(Widget ink) {
    final overhang = _inkOverhang;
    if (overhang == 0) return Positioned.fill(child: ink);
    return Positioned(
      left: -overhang,
      top: -overhang,
      right: -overhang,
      bottom: -overhang,
      child: ink,
    );
  }

  /// How far an unbounded ink reaches past the pressable: the halo's
  /// radius. Flutter clips ink to the material it paints on, so a material
  /// only the part's size would cut a 40dp circle about a 24dp checkbox or
  /// radio to a 24dp square: a square over the target, the fault the
  /// state-matrix sheets showed (11-09).
  double get _inkOverhang => widget.bounded ? 0 : widget.rippleRadius ?? 0;

  /// An unbounded halo's shape when it is not Compose's circle: the
  /// pressable's own shape, when that shape keeps a corner on a square
  /// (an app's square shape scale). Null for a round part, drawn as a
  /// circle.
  OutlinedBorder? _haloShape(OutlinedBorder? shape) {
    if (widget.bounded || shape == null || widget.rippleRadius == null) {
      return null;
    }
    final d = widget.rippleRadius! * 2;
    final square = Offset.zero & Size.square(d);
    // A round shape leaves its corner out; a square one keeps it.
    return shape
            .getOuterPath(
              square,
              textDirection: Directionality.maybeOf(context),
            )
            .contains(const Offset(1, 1))
        ? shape
        : null;
  }

  /// The ink layer over the content: Flutter's ink (the host's splash
  /// factory) on a transparent material, drawing the ripple and the hover
  /// and focus layers in the content colour.
  Widget _ink(
    ExpressiveStateLayers layers,
    Color content,
    OutlinedBorder shape,
    bool enabled,
    WidgetStateProperty<Color?>? customOverlay,
  ) {
    if (!widget.stateLayers) {
      // No layer and no ripple: an explicit transparent overlay, since a
      // null one falls back to the host theme's hover and focus colours.
      final none = content.withValues(alpha: 0);
      return Material(
        type: MaterialType.transparency,
        child: InkResponse(
          onTap: widget.busy ? _wait : widget.onPressed,
          onLongPress: widget.busy ? null : widget.onLongPress,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          canRequestFocus: enabled,
          statesController: _controller,
          mouseCursor: widget.mouseCursor,
          containedInkWell: true,
          splashColor: none,
          splashFactory: NoSplash.splashFactory,
          highlightColor: none,
          overlayColor: WidgetStatePropertyAll<Color>(none),
        ),
      );
    }
    final ripple =
        customOverlay?.resolve({..._states, WidgetState.pressed}) ??
        content.withValues(alpha: layers.pressedOpacity);
    final overlay = WidgetStateProperty.resolveWith<Color?>(
      // The pressed layer is the ripple itself (Compose's Android ripple
      // draws no separate pressed state layer).
      (states) =>
          customOverlay?.resolve(states) ??
          (states.contains(WidgetState.pressed)
              ? null
              : layers.layerOf(content, states)),
    );
    final splash = _splashFactory(Theme.of(context).platform);
    final overhang = _inkOverhang;
    final inkRect = widget.inkRect;
    final halo = _haloShape(shape);
    if (overhang > 0 && (inkRect != null || halo != null)) {
      // Unbounded ink about a part of the pressable ([inkRect]), or about
      // its centre in a halo of the part's own corner-family shape.
      final radius = widget.rippleRadius!;
      return Material(
        type: MaterialType.transparency,
        child: _CentredInkResponse(
          rect: (box) {
            final own = (Offset.zero & box).deflate(overhang);
            if (inkRect != null) return inkRect(own.size).shift(own.topLeft);
            return Rect.fromCircle(center: own.center, radius: radius);
          },
          onTap: widget.busy ? _wait : widget.onPressed,
          onLongPress: widget.busy ? null : widget.onLongPress,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          canRequestFocus: enabled,
          statesController: _controller,
          mouseCursor: widget.mouseCursor,
          highlightShape: halo == null ? BoxShape.circle : BoxShape.rectangle,
          containedInkWell: halo != null,
          customBorder: halo,
          radius: radius,
          splashColor: widget.busy ? ripple.withValues(alpha: 0) : ripple,
          splashFactory: splash,
          highlightColor: content.withValues(alpha: 0),
          overlayColor: overlay,
        ),
      );
    }
    return Material(
      type: MaterialType.transparency,
      child: InkResponse(
        onTap: widget.busy ? _wait : widget.onPressed,
        onLongPress: widget.busy ? null : widget.onLongPress,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        canRequestFocus: enabled,
        statesController: _controller,
        mouseCursor: widget.mouseCursor,
        customBorder: widget.bounded ? shape : null,
        containedInkWell: widget.bounded,
        highlightShape: widget.bounded ? BoxShape.rectangle : BoxShape.circle,
        radius: widget.bounded ? null : widget.rippleRadius,
        splashColor: widget.busy ? ripple.withValues(alpha: 0) : ripple,
        splashFactory: splash,
        highlightColor: content.withValues(alpha: 0),
        overlayColor: overlay,
      ),
    );
  }
}

/// The M3 focus indicator a pressable draws under keyboard focus: a ring of
/// [thickness] in `secondary`, [offset] out from the component's edge,
/// following its shape (Material's token DB, `md.comp.button.focus.
/// indicator.thickness` and `.outline.offset`, the same for every
/// component that has them).
abstract final class ExpressiveFocusRing {
  /// `md.comp.*.focus.indicator.thickness`: 3dp.
  static const double thickness = 3;

  /// `md.comp.*.focus.indicator.outline.offset`: 2dp between the
  /// component's edge and the ring.
  static const double offset = 2;
}

/// Strokes [ExpressiveFocusRing] around [shape]: concentric with a rounded
/// rectangle (each corner's radius grown by the gap, a square corner kept
/// square), the shape's own outline grown outward otherwise.
class _FocusRingPainter extends CustomPainter {
  const _FocusRingPainter({
    required this.shape,
    required this.color,
    required this.textDirection,
    this.rect,
    this.thickness = ExpressiveFocusRing.thickness,
    this.inward = false,
    this.gap,
  });

  final double thickness;
  final OutlinedBorder shape;

  /// The surface band between an inward ring and a filled face.
  final Color? gap;

  /// Whether the ring stands inside the part (paintExpressiveFocusRing).
  final bool inward;

  /// The part the ring goes round, in the painted box; the whole box when
  /// null.
  final Rect Function(Size size)? rect;
  final Color color;
  final TextDirection? textDirection;

  @override
  void paint(Canvas canvas, Size size) => expressivePaintFocusRing(
    canvas,
    rect?.call(size) ?? Offset.zero & size,
    shape,
    color: color,
    thickness: thickness,
    offset: ExpressiveFocusRing.offset,
    textDirection: textDirection,
    inward: inward,
    gap: gap,
  );

  @override
  bool shouldRepaint(_FocusRingPainter old) =>
      old.inward != inward ||
      old.gap != gap ||
      old.thickness != thickness ||
      old.shape != shape ||
      old.rect != rect ||
      old.color != color ||
      old.textDirection != textDirection;
}

/// The ink an Expressive press draws on [platform] (Compose's ripple): the
/// sparkle ripple on Android, the radial ripple elsewhere and on the web —
/// what Material 3's `ThemeData` picks by default. Pinned in every
/// pressable, so a host's `splashFactory` (`NoSplash`, `InkSplash`) leaves
/// Expressive's ink as it is. Private: Material's ink type stays out of the
/// look's API.
InteractiveInkFeatureFactory _splashFactory(TargetPlatform platform) =>
    platform == TargetPlatform.android && !kIsWeb
    ? InkSparkle.splashFactory
    : InkRipple.splashFactory;

/// Flutter's [InkResponse], its unbounded ink centred on [rect] of its box
/// ([ExpressivePressable.inkRect]).
class _CentredInkResponse extends InkResponse {
  const _CentredInkResponse({
    required this.rect,
    super.onTap,
    super.onLongPress,
    super.focusNode,
    super.autofocus,
    super.canRequestFocus,
    super.statesController,
    super.mouseCursor,
    super.highlightShape,
    super.containedInkWell,
    super.customBorder,
    super.radius,
    super.splashColor,
    super.splashFactory,
    super.highlightColor,
    super.overlayColor,
  });

  final Rect Function(Size box) rect;

  @override
  RectCallback? getRectCallback(RenderBox referenceBox) =>
      () => rect(referenceBox.size);
}

/// A pressable's layers, first to last: its content, the drag layer and
/// the ink. The ink paints over the content (Compose draws the indication
/// over it) but is hit-tested after it, never instead of it — a [Stack]
/// stops at its topmost hit child, which would give the ink every touch —
/// so a control inside takes its own taps, as a child `clickable` does in
/// Compose. A touch on a pressable inside that takes input is that one's
/// alone (Compose's child consumes the press): this ink is not hit, so this
/// pressable neither ripples nor presses under it. A disabled one consumes
/// nothing, and the touch is this pressable's.
class _PressableLayers extends Stack {
  const _PressableLayers({required this.enabled, required super.children})
    : super(clipBehavior: Clip.none);

  /// Whether the pressable takes input.
  final bool enabled;

  @override
  RenderStack createRenderObject(BuildContext context) =>
      _RenderPressableLayers(
        enabled: enabled,
        alignment: alignment,
        textDirection: textDirection ?? Directionality.maybeOf(context),
        fit: fit,
        clipBehavior: clipBehavior,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderPressableLayers renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    renderObject.enabled = enabled;
  }
}

class _RenderPressableLayers extends RenderStack {
  _RenderPressableLayers({
    required this.enabled,
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
  });

  /// Whether the pressable takes input: whether a touch on a pressable
  /// inside another is its own.
  bool enabled;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    bool hit(RenderBox child) => result.addWithPaintOffset(
      offset: (child.parentData! as StackParentData).offset,
      position: position,
      hitTest: (result, transformed) =>
          child.hitTest(result, position: transformed),
    );

    final ink = lastChild;
    if (ink == null) return false;
    final before = result.path.length;
    var content = false;
    for (var child = firstChild!; child != ink; child = childAfter(child)!) {
      content = hit(child) || content;
    }
    final owned = result.path.skip(before).any((entry) {
      final target = entry.target;
      return target is _RenderPressableLayers && target.enabled;
    });
    if (owned) return true;
    return hit(ink) || content;
  }
}

/// Compose's `semantics(mergeDescendants = true)`: one node, [child]'s
/// semantics merged into it, except a node inside that takes input (an
/// enabled pressable), which keeps a node of its own there — Compose's
/// merge stops at a descendant that merges its own semantics. Every
/// pressable is one; so is a static list item.
///
/// Flutter's [MergeSemantics] cannot leave a descendant out: while such a
/// node sits inside, this one stops merging. It stays the node — its
/// content's semantics that are not a node of their own (the pressable's
/// role and label, its text) still join it, as Flutter joins them to the
/// nearest node — and each node inside is a child of it.
class ExpressiveSemanticsGroup extends SingleChildRenderObjectWidget {
  /// A scope merging the semantics of [child] into one node.
  const ExpressiveSemanticsGroup({
    required super.child,
    this.interactive = false,
    super.key,
  });

  /// Whether this node takes input (an enabled pressable's): inside
  /// another, it keeps a node of its own.
  final bool interactive;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMergeSemantics(interactive);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderMergeSemantics).interactive = interactive;
  }
}

class _RenderMergeSemantics extends RenderProxyBox {
  _RenderMergeSemantics(this._interactive);

  bool _interactive;
  set interactive(bool value) {
    if (value == _interactive) return;
    _interactive = value;
    if (!attached) return;
    if (value) {
      _MergeSemanticsRegistry.instance.add(this);
    } else {
      _MergeSemanticsRegistry.instance.remove(this);
    }
  }

  /// The nearest merging node above this interactive one, told while this
  /// one is attached.
  _RenderMergeSemantics? _enclosing;
  bool _joined = false;

  /// How many interactive nodes have this one as their nearest merging
  /// node.
  int _interactiveInside = 0;

  bool get _merges => _interactiveInside == 0;

  /// [_merges] as this node last described it: what its semantics hold.
  bool? _describedMerges;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (_interactive) _MergeSemanticsRegistry.instance.add(this);
  }

  @override
  void detach() {
    if (_interactive) _MergeSemanticsRegistry.instance.remove(this);
    super.detach();
  }

  void _join() {
    if (_joined) return;
    _joined = true;
    var above = parent;
    while (above != null && above is! _RenderMergeSemantics) {
      above = above.parent;
    }
    _enclosing = above as _RenderMergeSemantics?;
    _enclosing?._interactiveInsideChanged(1);
  }

  void _leave() {
    if (!_joined) return;
    _joined = false;
    _enclosing?._interactiveInsideChanged(-1);
    _enclosing = null;
  }

  void _interactiveInsideChanged(int by) {
    _interactiveInside += by;
    // Only a change from what the semantics hold asks for an update. A
    // subtree a GlobalKey moves detaches and re-attaches the controls
    // inside, which leaves this node as it was: an update asked from
    // there would rebuild it under the semantics parent it is leaving.
    if (_describedMerges != null && _merges != _describedMerges) {
      markNeedsSemanticsUpdate();
    }
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    // Always the node, merging or not: a control inside that gains or
    // loses input leaves this node (and assistive focus on it) in place.
    _describedMerges = _merges;
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = _merges;
  }
}

// Flutter collects semantics only when the platform or a caller requests it.
// Keep the same lifetime for our nested-control bookkeeping: ordinary layout
// need not walk every control's render ancestors. Activation joins every
// attached interactive node before the next semantics pass; deactivation
// clears the counts. A single listener serves the currently attached nodes.
class _MergeSemanticsRegistry {
  static final instance = _MergeSemanticsRegistry();
  final _nodes = <_RenderMergeSemantics>{};

  void add(_RenderMergeSemantics node) {
    if (!_nodes.add(node)) return;
    final binding = SemanticsBinding.instance;
    if (_nodes.length == 1) {
      binding.addSemanticsEnabledListener(_enabledChanged);
    }
    if (binding.semanticsEnabled) node._join();
  }

  void remove(_RenderMergeSemantics node) {
    if (!_nodes.remove(node)) return;
    node._leave();
    if (_nodes.isEmpty) {
      SemanticsBinding.instance.removeSemanticsEnabledListener(_enabledChanged);
    }
  }

  void _enabledChanged() {
    final enabled = SemanticsBinding.instance.semanticsEnabled;
    for (final node in _nodes) {
      if (enabled) {
        node._join();
      } else {
        node._leave();
      }
    }
  }
}

/// Compose's `Modifier.minimumInteractiveComponentSize()`: [child] keeps
/// its size but is centred in at least [size] × [size]
/// (`HostBehavior.minimumInteractiveComponentSize`, 48dp), and a touch in
/// the margin reaches it.
class ExpressiveMinimumInteractiveSize extends SingleChildRenderObjectWidget {
  /// A scope keeping [child] at least [size] square to touch.
  const ExpressiveMinimumInteractiveSize({
    super.child,
    this.size = HostBehavior.minimumInteractiveComponentSize,
    super.key,
  });

  /// The smallest touch target, in dp.
  final double size;

  /// Whether touch targets are kept at [context]: false inside an
  /// [ExpressiveShrinkTapTargets].
  static bool enforcedAt(BuildContext context) =>
      !(context
              .dependOnInheritedWidgetOfExactType<_ShrunkTapTargets>()
              ?.shrink ??
          false);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMinimumInteractiveSize(enforcedAt(context) ? size : 0);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderMinimumInteractiveSize).minSize =
        enforcedAt(context) ? size : 0;
  }
}

/// Shrinks the touch targets of everything below it to their drawn size
/// (Compose's `LocalMinimumInteractiveComponentSize provides 0.dp`): for a
/// dense layout that keeps its own spacing.
class ExpressiveShrinkTapTargets extends StatelessWidget {
  /// A scope shrinking the touch targets below it to their drawn size.
  const ExpressiveShrinkTapTargets({required this.child, super.key})
    : shrink = true;

  /// Gives the touch targets below a shrinking ancestor their 48dp back: a
  /// control a dense layout holds that still stands on its own (a kit's
  /// composite at the end of a list item).
  const ExpressiveShrinkTapTargets.restore({required this.child, super.key})
    : shrink = false;

  /// What the shrunk (or restored) targets apply to.
  final Widget child;

  /// Whether the targets below are shrunk.
  final bool shrink;

  @override
  Widget build(BuildContext context) =>
      _ShrunkTapTargets(shrink: shrink, child: child);
}

class _ShrunkTapTargets extends InheritedWidget {
  const _ShrunkTapTargets({required this.shrink, required super.child});

  final bool shrink;

  @override
  bool updateShouldNotify(_ShrunkTapTargets oldWidget) =>
      oldWidget.shrink != shrink;
}

class _RenderMinimumInteractiveSize extends RenderShiftedBox {
  _RenderMinimumInteractiveSize(this._minSize) : super(null);

  double _minSize;

  set minSize(double value) {
    if (value == _minSize) return;
    _minSize = value;
    markNeedsLayout();
  }

  Size _grown(Size child, BoxConstraints constraints) => constraints.constrain(
    Size(math.max(child.width, _minSize), math.max(child.height, _minSize)),
  );

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(super.computeMinIntrinsicWidth(height), _minSize);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(super.computeMaxIntrinsicWidth(height), _minSize);

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(super.computeMinIntrinsicHeight(width), _minSize);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(super.computeMaxIntrinsicHeight(width), _minSize);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.constrain(Size.square(_minSize));
    return _grown(child.getDryLayout(constraints), constraints);
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.constrain(Size.square(_minSize));
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    size = _grown(child.size, constraints);
    (child.parentData! as BoxParentData).offset = Alignment.center.alongOffset(
      size - child.size as Offset,
    );
  }

  /// The drawn component, not the grown touch target: what Compose reports
  /// as the bounds of a component under `minimumInteractiveComponentSize`
  /// (an icon button in a toolbar's 48dp slot measures 40dp). No semantics
  /// node is created here, so accessibility keeps the 48dp target.
  @override
  Rect get semanticBounds {
    final child = this.child;
    if (child == null || !child.hasSize) return super.semanticBounds;
    return (child.parentData! as BoxParentData).offset & child.size;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    if (super.hitTest(result, position: position)) return true;
    final child = this.child;
    if (child == null) return false;
    // A touch in the margin reaches the child at its centre.
    final center = child.size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(center),
      position: center,
      hitTest: (result, position) => child.hitTest(result, position: center),
    );
  }
}

/// The stateful styling a pressable passes to its content.
///
/// ```dart
/// final resolved = ExpressiveStyleScope.maybeOf(context);
/// final padding = resolved?.style.padding?.resolve(resolved.states);
/// ```
class ExpressiveStyleScope extends InheritedWidget {
  /// Publishes the resolved layers, interaction states and safe shape inset.
  const ExpressiveStyleScope({
    required this.style,
    required this.states,
    required this.inset,
    required super.child,
    super.key,
  });

  /// Widget style merged over the component theme.
  final ExpressiveComponentThemeData style;

  /// Current interaction states.
  final Set<WidgetState> states;

  /// The shape's reserved content inset.
  final EdgeInsetsGeometry inset;

  /// The nearest style scope, or none outside a styled pressable.
  static ExpressiveStyleScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ExpressiveStyleScope>();

  @override
  bool updateShouldNotify(ExpressiveStyleScope oldWidget) =>
      style != oldWidget.style ||
      !setEquals(states, oldWidget.states) ||
      inset != oldWidget.inset;
}
