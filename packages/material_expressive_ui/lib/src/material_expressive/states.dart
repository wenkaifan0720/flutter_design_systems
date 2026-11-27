/// Press, hover, focus and selection feedback for Expressive controls.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'component_themes.dart';
import 'elevation.dart';
import 'internal/focus_ring.dart';
import 'internal/group_tap_target.dart';
import 'internal/width_probe.dart';
import 'motion.dart';
import 'theme.dart';
import 'internal/style_layers.dart';

/// A pressable's shapes (Compose's `ButtonShapes`, plus a toggle's
/// `checkedShape`): at rest, while pressed, and while selected. Pressed
/// wins over selected, selected over rest.
@immutable
class ExpressivePressShapes with Diagnosticable {
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<OutlinedBorder>('shape', shape))
      ..add(
        DiagnosticsProperty<OutlinedBorder?>(
          'pressed',
          pressed,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<OutlinedBorder?>(
          'selected',
          selected,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<OutlinedBorder?>(
          'focused',
          focused,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<OutlinedBorder?>(
          'hovered',
          hovered,
          defaultValue: null,
        ),
      );
  }
}

/// What a pressable is to assistive technology.
enum ExpressivePressRole {
  /// A button (Compose `Role.Button`).
  button,

  /// A toggle button: a button that is selected or not (Compose's
  /// toggleable buttons). It is announced as a selected button, as Flutter's
  /// `IconButton(isSelected:)` is, not as a switch.
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
    this.expanded,
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
    this.tapTargetAlignment = AlignmentDirectional.center,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
    this.mouseCursor,
    this.stateLayers = true,
    this.focusRect,
    this.focusShape,
    this.focusInward = false,
    this.focusRing = true,
    this.markFace = false,
    this.focusTarget,
    super.key,
  }) : assert(
         focusTarget == null || (focusNode == null && !autofocus),
         'The focus target takes the focus: give it the node.',
       );

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

  /// Waiting on its own action (the shared busy press): it keeps its
  /// focus, its face and its node for a screen reader, draws no ripple, and
  /// a press does nothing, so a control at work changes neither its node
  /// nor its actions.
  final bool busy;

  /// Whether the pressable is selected (checked): the selected shape, and
  /// the role's selected or checked semantics.
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

  /// Whether the content opened by this control is expanded, when applicable.
  final bool? expanded;

  /// What a screen reader says, over the content's own text.
  final String? semanticLabel;

  /// A tooltip message: what a screen reader calls the pressable when it
  /// has no [semanticLabel] (a [semanticLabel] names it alone).
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

  /// Whether a smaller container keeps the touch target, the floor, around
  /// it ([ExpressiveMinimumInteractiveSize]).
  final bool minimumInteractiveSize;

  /// Where a smaller container stands in its touch target: centred, as
  /// Compose centres it, or on the edge a keyline holds (a stepper's end
  /// circles: [AlignmentDirectional.centerStart] and `centerEnd`), the
  /// target growing away from it.
  final AlignmentGeometry tapTargetAlignment;

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

  /// Whether keyboard focus draws the focus indicator. False where the part
  /// shows where it stands another way: a menu's row the pointer lit keeps
  /// the focus (the keys go on from it) on the hover layer, with no ring.
  final bool focusRing;

  /// Whether its drawn face (the surface, inside any touch target around it)
  /// is marked for the alignment checks ([RawKeylineFace]): a face too
  /// faint on its page to read by its pixels (an unchosen tonal segment) is
  /// then read by the face's own box, never by the target around it.
  final bool markFace;

  /// What takes the keyboard focus in the pressable's place, laid over it:
  /// a radio's `RawRadio`, which keeps the focus, its group's keys and the
  /// radio's semantics, as Flutter's radios do. The pressable keeps the
  /// tap, the ripple and the state layers, and shows the focus (its state
  /// layer and ring) while the target holds it; Enter on the target presses
  /// the pressable as Enter on the pressable itself would. Its own
  /// [focusNode] and [autofocus] then go unused: the target takes them.
  ///
  /// The target should draw nothing and take no pointer of its own.
  final Widget? focusTarget;

  @override
  State<ExpressivePressable> createState() => _ExpressivePressableState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<ExpressiveComponentThemeData?>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<ExpressiveComponentThemeData?>(
          'componentStyle',
          componentStyle,
          defaultValue: null,
        ),
      )
      ..add(DiagnosticsProperty<ExpressivePressShapes>('shapes', shapes))
      ..add(EnumProperty<ExpressiveMotionKey>('motion', motion))
      ..add(ColorProperty('color', color))
      ..add(ColorProperty('contentColor', contentColor))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onPressed', onPressed))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onLongPress', onLongPress))
      ..add(
        ObjectFlagProperty<ValueChanged<bool>?>.has(
          'onPressedChanged',
          onPressedChanged,
        ),
      )
      ..add(FlagProperty('busy', value: busy, ifTrue: 'busy'))
      ..add(FlagProperty('selected', value: selected, ifTrue: 'selected'))
      ..add(FlagProperty('dragged', value: dragged, ifTrue: 'dragged'))
      ..add(FlagProperty('error', value: error, ifTrue: 'error'))
      ..add(
        EnumProperty<ExpressivePressRole>(
          'role',
          role,
          defaultValue: ExpressivePressRole.button,
        ),
      )
      ..add(
        DiagnosticsProperty<SemanticsRole?>(
          'semanticsRole',
          semanticsRole,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<bool?>('expanded', expanded, defaultValue: null),
      )
      ..add(StringProperty('tooltip', tooltip, defaultValue: null))
      ..add(
        DiagnosticsProperty<BorderSide>(
          'side',
          side,
          defaultValue: BorderSide.none,
        ),
      )
      ..add(
        DiagnosticsProperty<ExpressiveStateElevation>(
          'elevation',
          elevation,
          defaultValue: ExpressiveStateElevation.none,
        ),
      )
      ..add(
        EnumProperty<ExpressiveMotionKey>(
          'elevationMotion',
          elevationMotion,
          defaultValue: ExpressiveMotionKey.defaultEffects,
        ),
      )
      ..add(
        EnumProperty<ExpressiveElevationLevel>(
          'tonalElevation',
          tonalElevation,
          defaultValue: ExpressiveElevationLevel.level0,
        ),
      )
      ..add(
        EnumProperty<ExpressiveMotionKey>(
          'colorMotion',
          colorMotion,
          defaultValue: ExpressiveMotionKey.fastEffects,
        ),
      )
      ..add(DiagnosticsProperty<bool>('bounded', bounded, defaultValue: true))
      ..add(DoubleProperty('rippleRadius', rippleRadius, defaultValue: null))
      ..add(
        ObjectFlagProperty<Rect Function(Size size)?>.has('inkRect', inkRect),
      )
      ..add(
        DiagnosticsProperty<bool>(
          'minimumInteractiveSize',
          minimumInteractiveSize,
          defaultValue: true,
        ),
      )
      ..add(
        DiagnosticsProperty<AlignmentGeometry>(
          'tapTargetAlignment',
          tapTargetAlignment,
          defaultValue: AlignmentDirectional.center,
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode?>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        DiagnosticsProperty<WidgetStatesController?>(
          'statesController',
          statesController,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<MouseCursor?>(
          'mouseCursor',
          mouseCursor,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<bool>(
          'stateLayers',
          stateLayers,
          defaultValue: true,
        ),
      )
      ..add(
        ObjectFlagProperty<Rect Function(Size size)?>.has(
          'focusRect',
          focusRect,
        ),
      )
      ..add(
        DiagnosticsProperty<OutlinedBorder?>(
          'focusShape',
          focusShape,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty('focusInward', value: focusInward, ifTrue: 'focusInward'),
      )
      ..add(
        FlagProperty('focusRing', value: focusRing, ifFalse: 'no focus ring'),
      )
      ..add(FlagProperty('markFace', value: markFace, ifTrue: 'markFace'))
      ..add(
        DiagnosticsProperty<Widget?>(
          'focusTarget',
          focusTarget,
          defaultValue: null,
        ),
      );
  }
}

class _ExpressivePressableState extends State<ExpressivePressable> {
  WidgetStatesController? _ownController;
  bool _pressed = false;

  /// Read the current focus highlight mode while building. Connecting a mouse
  /// can change the default mode without notifying highlight listeners.
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
        (widget.componentStyle ?? const ExpressiveComponentThemeData())
            .layeredUnder(widget.style);
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
    final ringOn =
        widget.focusRing &&
        _keyboard &&
        enabled &&
        states.contains(WidgetState.focused);

    Widget paint(Color color, Color content, double ringT) =>
        ExpressiveSpringShape(
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
                ? layers.layerOf(content, const <WidgetState>{
                    WidgetState.dragged,
                  })
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
              child: widget.markFace ? RawKeylineFace(child: surface) : surface,
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
      pressable = ExpressiveMinimumInteractiveSize._inGroup(
        alignment: widget.tapTargetAlignment,
        child: pressable,
      );
    }
    // Whether the parent fixed the width (a button group squishing its
    // members): content under a [ExpressiveFillProbedWidth] then fills it and centres.
    pressable = ExpressiveWidthProbe(child: pressable);
    return ExpressiveSemanticsGroup(
      interactive: enabled,
      child: Semantics(
        enabled: enabled,
        role: widget.semanticsRole,
        expanded: widget.expanded,
        button:
            widget.role == ExpressivePressRole.button ||
            widget.role == ExpressivePressRole.toggle,
        selected:
            widget.role == ExpressivePressRole.tab ||
                widget.role == ExpressivePressRole.toggle
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
        // A semanticLabel names the control alone: its tooltip, often the
        // shorter word ("Delete" by "Delete Dune"), is not said after it.
        tooltip: widget.semanticLabel == null ? widget.tooltip : null,
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

  /// Extend the material by the halo radius so Flutter can paint the entire
  /// circular ink response around a smaller control.
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
          canRequestFocus: enabled && widget.focusTarget == null,
          statesController: _controller,
          mouseCursor: widget.mouseCursor,
          containedInkWell: true,
          splashColor: none,
          splashFactory: NoSplash.splashFactory,
          highlightColor: none,
          overlayColor: WidgetStatePropertyAll<Color>(none),
          child: _focusTarget,
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
          canRequestFocus: enabled && widget.focusTarget == null,
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
          child: _focusTarget,
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
        canRequestFocus: enabled && widget.focusTarget == null,
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
        child: _focusTarget,
      ),
    );
  }

  /// [ExpressivePressable.focusTarget] inside the ink: its focus is then
  /// the ink's, which shows the focus layer, and the ring, while it lasts.
  Widget? get _focusTarget {
    final target = widget.focusTarget;
    return target == null ? null : _InkFocusTarget(child: target);
  }
}

/// Holds an [ExpressivePressable.focusTarget] inside the pressable's ink.
/// Enter (and the numeric pad's) on the target goes to the ink's own
/// activation, the ripple and press it shows from the keyboard, as on a
/// pressable that holds its own focus; the target's activation is not run.
class _InkFocusTarget extends StatelessWidget {
  const _InkFocusTarget({required this.child});

  final Widget child;

  static const _keys = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.enter): _InkActivateIntent(),
    SingleActivator(LogicalKeyboardKey.numpadEnter): _InkActivateIntent(),
  };

  @override
  Widget build(BuildContext context) => Shortcuts(
    shortcuts: _keys,
    child: Actions(
      actions: <Type, Action<Intent>>{
        // This widget's context is under the ink's own actions.
        _InkActivateIntent: CallbackAction<_InkActivateIntent>(
          onInvoke: (_) => Actions.maybeInvoke(context, const ActivateIntent()),
        ),
      },
      child: child,
    ),
  );
}

class _InkActivateIntent extends Intent {
  const _InkActivateIntent();
}

/// Dimensions of the keyboard focus ring, Material 3's focus indicator. The
/// ring follows the component's shape and uses the theme's secondary color.
abstract final class ExpressiveFocusRing {
  /// `md.comp.*.focus.indicator.thickness`: 3dp, the width of the focus
  /// outline.
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
    super.child,
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      FlagProperty('interactive', value: interactive, ifTrue: 'interactive'),
    );
  }
}

// A [RenderMergeSemantics]: what reads a field's controls (ui_core's
// decorator) sees each one as a node of its own.
class _RenderMergeSemantics extends RenderMergeSemantics {
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

  /// The parts inside kept out of this node's box
  /// ([ExpressiveOutsideOutline]).
  final Set<_RenderOutsideOutline> _outside = <_RenderOutsideOutline>{};

  /// This node's box, short of each part kept out of it, from the side
  /// that part stands nearer.
  @override
  Rect get semanticBounds {
    var bounds = Offset.zero & size;
    for (final part in _outside) {
      if (!part.attached || !part.hasSize) continue;
      final box = MatrixUtils.transformRect(
        part.getTransformTo(this),
        Offset.zero & part.size,
      );
      bounds = box.left - bounds.left <= bounds.right - box.right
          ? Rect.fromLTRB(
              math.min(math.max(bounds.left, box.right), bounds.right),
              bounds.top,
              bounds.right,
              bounds.bottom,
            )
          : Rect.fromLTRB(
              bounds.left,
              bounds.top,
              math.max(math.min(bounds.right, box.left), bounds.left),
              bounds.bottom,
            );
    }
    return bounds;
  }
}

/// Keeps [child] out of the box a screen reader outlines for the pressable
/// round it, cut from the side it stands on: a search bar's trailing
/// actions, controls with nodes of their own, take the taps there, so the
/// bar's node ends where its own tap does.
class ExpressiveOutsideOutline extends SingleChildRenderObjectWidget {
  /// A part kept out of the enclosing pressable's node.
  const ExpressiveOutsideOutline({required Widget super.child, super.key});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderOutsideOutline();
}

class _RenderOutsideOutline extends RenderProxyBox {
  _RenderMergeSemantics? _group;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    var above = parent;
    while (above != null && above is! _RenderMergeSemantics) {
      above = above.parent;
    }
    _group = (above as _RenderMergeSemantics?)?.._outside.add(this);
  }

  @override
  void detach() {
    _group
      ?.._outside.remove(this)
      ..markNeedsSemanticsUpdate();
    _group = null;
    super.detach();
  }

  @override
  void performLayout() {
    super.performLayout();
    _group?.markNeedsSemanticsUpdate();
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

/// Compose's `Modifier.minimumInteractiveComponentSize()` on ui_core's
/// padded tap target ([TapTargetPadding]): [child] keeps its size, centred in
/// at least [size] × [size] (the floor at the context when null:
/// [RawTapTargets.floorOn], 40dp under Expressive's theme), and a tap
/// anywhere in that area reaches it. The layout, the area a
/// tap reaches and the box a screen reader outlines are one: the target is
/// one node, [child]'s semantics merged into it, so wrap one control, never
/// a group.
class ExpressiveMinimumInteractiveSize extends StatelessWidget {
  /// A scope keeping [child] at least [size] square to touch, or at the
  /// floor at the context when [size] is null.
  const ExpressiveMinimumInteractiveSize({
    this.child,
    this.size,
    this.alignment = AlignmentDirectional.center,
    super.key,
  }) : assert(
         size == null || size >= 0,
         'a tap target is never negative: $size',
       ),
       _node = true;

  /// An [ExpressivePressable]'s target: its [ExpressiveSemanticsGroup] is
  /// the node and already spans the target, keeping a control inside (a
  /// card's button, a row's switch) a node of its own, which a merging node
  /// here would take in.
  const ExpressiveMinimumInteractiveSize._inGroup({
    required Widget this.child,
    required this.alignment,
  }) : size = null,
       _node = false;

  final bool _node;

  /// The control the target stands round.
  final Widget? child;

  /// Where [child] stands in the target: centred (Compose's), or on the
  /// edges it names, the target growing away from them, mirrored right to
  /// left.
  final AlignmentGeometry alignment;

  /// The smallest touch target, in dp; null: the floor at the context
  /// ([RawTapTargets.floorOn]).
  final double? size;

  /// Expressive's floors ([RawTapTargetScope] in [ExpressiveTheme]): ui_core's
  /// touch floor, 40 × 40, for a finger and for a pointer alike, as Compose
  /// keeps one `minimumInteractiveComponentSize` on every platform (48 in
  /// Compose). An app's [RawTapTargetScope] under the theme raises them.
  /// Density tightens a control's face (compact under a pointer), never its
  /// target.
  static final RawTapTargets targets = RawTapTargets(
    pointer: RawTapTargets.fallback.touch,
  );

  /// Whether touch targets are kept at [context]: false inside an
  /// [ExpressiveShrinkTapTargets].
  static bool enforcedAt(BuildContext context) =>
      !(context
              .dependOnInheritedWidgetOfExactType<_ShrunkTapTargets>()
              ?.shrink ??
          false);

  /// The least target at [context]: the floor ([RawTapTargets.floorOn] of
  /// the nearest [RawTapTargetScope], 40 × 40 under Expressive's theme), or
  /// none inside an [ExpressiveShrinkTapTargets].
  static Size floorAt(BuildContext context) =>
      enforcedAt(context) ? RawTapTargets.of(context).floorOn() : Size.zero;

  @override
  Widget build(BuildContext context) {
    final size = this.size;
    final minSize = size == null
        ? floorAt(context)
        : Size.square(enforcedAt(context) ? size : 0);
    final child = this.child ?? const SizedBox.shrink();
    if (_node) {
      return TapTargetPadding(
        minSize: minSize,
        alignment: alignment,
        child: child,
      );
    }
    return ExpressiveGroupTapTarget(
      minSize: minSize,
      alignment: alignment,
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('size', size, defaultValue: null));
    properties.add(
      DiagnosticsProperty<AlignmentGeometry>(
        'alignment',
        alignment,
        defaultValue: AlignmentDirectional.center,
      ),
    );
  }
}

/// Shrinks the touch targets of everything below it to their drawn size
/// (Compose's `LocalMinimumInteractiveComponentSize provides 0.dp`): for a
/// dense layout that keeps its own spacing.
class ExpressiveShrinkTapTargets extends StatelessWidget {
  /// A scope shrinking the touch targets below it to their drawn size.
  const ExpressiveShrinkTapTargets({required this.child, super.key})
    : shrink = true;

  /// Gives the touch targets below a shrinking ancestor their floor back: a
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('shrink', shrink));
  }
}

class _ShrunkTapTargets extends InheritedWidget {
  const _ShrunkTapTargets({required this.shrink, required super.child});

  final bool shrink;

  @override
  bool updateShouldNotify(_ShrunkTapTargets oldWidget) =>
      oldWidget.shrink != shrink;
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ExpressiveComponentThemeData>('style', style))
      ..add(IterableProperty<WidgetState>('states', states))
      ..add(DiagnosticsProperty<EdgeInsetsGeometry>('inset', inset));
  }
}
