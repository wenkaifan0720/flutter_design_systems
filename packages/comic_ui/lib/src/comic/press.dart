// The one press every control in Comic stands on: the design kit's pressable (focus, Enter and Space, hover, one
// semantics node, the states) with Comic's face on it, in print (laws 1 and 4): the pointer lays a plain ink
// shade on the part's own outline, a press swells it and sinks the face (onto its hard print, for a part that stands
// on one), a disabled face is screened back toward its paper, and the keyboard's part pops off a hard print. Each
// moves on Comic's motion tokens.
import 'package:flutter/foundation.dart';

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/geometry.dart';
import 'internal/lettered.dart';
import 'internal/pop.dart';
import 'internal/reach.dart';
import 'theme.dart';

/// A press's states read by name, for a face that draws its own: `states.hovered`, `states.pressed` and so on.
extension ComicPressStates on Set<WidgetState> {
  /// Under the pointer.
  bool get hovered => contains(WidgetState.hovered);

  /// Holding the keyboard's focus.
  bool get focused => contains(WidgetState.focused);

  /// Under a press.
  bool get pressed => contains(WidgetState.pressed);

  /// Taking presses: not disabled.
  bool get enabled => !contains(WidgetState.disabled);

  /// Chosen, or on.
  bool get selected => contains(WidgetState.selected);

  /// Holding something wrong.
  bool get error => contains(WidgetState.error);
}

/// Minimum hit areas for Comic controls, in logical pixels.
/// [ComicTheme] uses 44 for a pointer and 48 for touch. An enclosing
/// [DesignTapTargetScope] can supply different sizes.
abstract final class ComicTapTarget {
  /// Every control's least target for a pointer.
  static const double target = 44;

  /// Every control's least target for a finger: Android's 48, as Material's padded tap target.
  static const double touchTarget = 48;

  /// Comic's floors: [touchTarget] for a finger, [target] for a pointer, the input by platform.
  static const DesignTapTargets targets = DesignTapTargets(
    touch: Size.square(touchTarget),
    pointer: Size.square(target),
  );

  /// Whether a finger reaches the controls at [context] (by the nearest [DesignTapTargetScope], else by platform).
  static bool padded(BuildContext context) =>
      DesignTapTargets.of(context).inputOn() == DesignInput.touch;

  /// The least target at [context]: the floor for what reaches the controls there, [touchTarget] or [target] under
  /// Comic's own floors. None inside a row that takes the press itself (a check row's box).
  static double targetOf(BuildContext context) => RowMark.inRow(context)
      ? 0
      : DesignTapTargets.of(context).floorOn().shortestSide;
}

/// The curve every change of a face's state moves on: a quick cut that lands without a drift.
const Curve comicStateCurve = Curves.easeOutCubic;

/// The look's one state motion. A face resolves what it draws (its decoration, its ink) for its current states, and
/// this carries [value] from where the face is to where those states now put it, by [lerp], on [ComicMotion.state];
/// under Reduce Motion it changes at once. A change that comes mid-way turns from where the face is, with no jump back.
///
/// ```dart
/// ComicStateLerp<Color?>(value: ink, lerp: Color.lerp, builder: (context, ink, _) => Icon(icon, color: ink))
/// ```
class ComicStateLerp<T> extends StatelessWidget {
  /// Creates a [ComicStateLerp].
  const ComicStateLerp({
    super.key,
    required this.value,
    required this.lerp,
    required this.builder,
    this.child,
  });

  /// What the face's states resolve to now: the value the animation moves to.
  final T value;

  /// Interpolates two values: the class's own `lerp`, such as [Color.lerp] or [Decoration.lerp].
  final T? Function(T? a, T? b, double t) lerp;

  /// Builds the face from the value as it moves.
  final ValueWidgetBuilder<T> builder;

  /// A subtree that does not depend on the value, built once.
  final Widget? child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<T>(
    tween: _LerpTween<T>(value, lerp),
    duration: ComicMotion.of(context).state,
    curve: comicStateCurve,
    builder: builder,
    child: child,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(
        ObjectFlagProperty<T? Function(T? a, T? b, double t)>.has('lerp', lerp),
      )
      ..add(ObjectFlagProperty<ValueWidgetBuilder<T>>.has('builder', builder));
  }
}

class _LerpTween<T> extends Tween<T> {
  _LerpTween(T end, this.by) : super(end: end);

  final T? Function(T? a, T? b, double t) by;

  @override
  T lerp(double t) => by(begin, end, t.clamp(0, 1)) as T;
}

/// A face's decoration, moving from one state's to the next with [ComicStateLerp]: what a part draws its fill, rim
/// and print with in place of a [DecoratedBox], or, with [ComicStateDecoration.box], of a [Container] that decorates.
///
/// ```dart
/// ComicStateDecoration(decoration: ShapeDecoration(color: fill, shape: shape), child: label)
/// ```
class ComicStateDecoration extends StatelessWidget {
  /// Creates a [ComicStateDecoration].
  const ComicStateDecoration({
    super.key,
    required this.decoration,
    this.position = DecorationPosition.background,
    this.child,
  }) : padding = null,
       constraints = null,
       width = null,
       height = null,
       _box = false;

  /// Creates one that lays out as a [Container] does: [padding] round the child with the decoration's own padding
  /// added (a rim's width), inside [constraints], [width] and [height].
  const ComicStateDecoration.box({
    super.key,
    required this.decoration,
    this.padding,
    this.constraints,
    this.width,
    this.height,
    this.child,
  }) : position = DecorationPosition.background,
       _box = true;

  final bool _box;

  /// The decoration the face's states resolve to now.
  final Decoration decoration;

  /// Whether the decoration is painted behind the child or in front of it.
  final DecorationPosition position;

  /// Room inside the decoration round the child, as a [Container]'s ([ComicStateDecoration.box]).
  final EdgeInsetsGeometry? padding;

  /// Constraints round the decorated box, as a [Container]'s.
  final BoxConstraints? constraints;

  /// A fixed width, as a [Container]'s.
  final double? width;

  /// A fixed height, as a [Container]'s.
  final double? height;

  /// The face's content.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    // A container's padding takes the decoration's own (its rim): the target state's, so the layout holds still.
    final room = !_box
        ? null
        : (padding ?? EdgeInsets.zero).add(decoration.padding);
    final inner = room == null ? child : Padding(padding: room, child: child);
    Widget box = ComicStateLerp<Decoration>(
      value: decoration,
      lerp: Decoration.lerp,
      child: inner,
      builder: (context, decoration, child) {
        // Under a disabled face's screen an ink fill leaves the face: its solid tint is painted beneath the words.
        final ground = _ScreenScope.groundOf(context);
        final fill = ground == null || position != DecorationPosition.background
            ? null
            : _InkFill.of(decoration, ground);
        return _FillMark(
          fill: fill,
          child: DecoratedBox(
            decoration: fill?.hollow ?? decoration,
            position: position,
            child: child,
          ),
        );
      },
    );
    final sized = width != null || height != null
        ? constraints?.tighten(width: width, height: height) ??
              BoxConstraints.tightFor(width: width, height: height)
        : constraints;
    if (sized != null) box = ConstrainedBox(constraints: sized, child: box);
    return box;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Decoration>('decoration', decoration))
      ..add(
        EnumProperty<DecorationPosition>(
          'position',
          position,
          defaultValue: DecorationPosition.background,
        ),
      )
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'padding',
          padding,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<BoxConstraints>(
          'constraints',
          constraints,
          defaultValue: null,
        ),
      )
      ..add(DoubleProperty('width', width, defaultValue: null))
      ..add(DoubleProperty('height', height, defaultValue: null));
  }
}

/// An accessible press target for a custom control.
///
/// [builder] receives the current widget states. Hover and press animate a
/// plain tint across the face. [plate] gives the face a hard ink shadow and
/// lets it sink when pressed. Keyboard focus draws an outline around the face.
/// Enter and Space activate it. A null [onPressed] disables it.
///
/// Supply [label] to name the control or omit it to merge the child's semantics.
/// [busy] temporarily suspends activation while retaining focus.
///
/// ```dart
/// ComicPressable(onPressed: open, label: 'Issue 12', child: tile)
/// ```
class ComicPressable extends StatelessWidget {
  /// Creates a [ComicPressable].
  const ComicPressable({
    super.key,
    this.child,
    this.builder,
    this.onPressed,
    this.onLongPress,
    this.label,
    this.hint,
    this.value,
    this.button = true,
    this.link = false,
    this.selected,
    this.checked,
    this.mixed = false,
    this.toggled,
    this.inGroup = false,
    this.expanded,
    this.error = false,
    this.focusNode,
    this.autofocus = false,
    this.statesController,
    this.radius = 0,
    this.ring = true,
    this.wash = true,
    this.washColor,
    this.sink = true,
    this.plate = false,
    this.target = false,
    this.targetAlignment = AlignmentDirectional.center,
    this.busy = false,
    this.keys,
    this.outline,
    this.overlay,
    this.mouseCursor,
  }) : assert(child != null || builder != null);

  /// The face. Give this or [builder].
  final Widget? child;

  /// A face that draws its own states.
  final Widget Function(BuildContext context, Set<WidgetState> states)? builder;

  /// Called on a press: a tap, Enter or Space. Null is disabled.
  final VoidCallback? onPressed;

  /// Called on a long press. Null: none.
  final VoidCallback? onLongPress;

  /// The control's one name. Null: its own words are its name.
  final String? label;

  /// What a press does, read after the name: 'Opens the menu'. Null: none.
  final String? hint;

  /// Its value, read after the name: '3 new'. Null: none.
  final String? value;

  /// Read as a button. False for a face that is no button: a tile, a row.
  final bool button;

  /// Read as a link: it goes somewhere.
  final bool link;

  /// A checkbox partly ticked.
  final bool mixed;

  /// One of a set where only one is selected: a radio.
  final bool inGroup;

  /// Chosen, for a tab or an option. Null: it is no choice.
  final bool? selected;

  /// Ticked, for a checkbox or a radio. Null: it is neither.
  final bool? checked;

  /// On, for a switch. Null: it is no switch.
  final bool? toggled;

  /// Open, for a disclosure. Null: it opens nothing.
  final bool? expanded;

  /// What it holds is wrong: the face is told ([WidgetState.error]).
  final bool error;

  /// An optional focus node to use as the focus node for this widget.
  final FocusNode? focusNode;

  /// Whether it takes the focus when it first shows.
  final bool autofocus;

  /// The states, when the caller watches or drives them.
  final WidgetStatesController? statesController;

  /// A corner its pop and wash follow when [outline] is null; 0 takes the theme's control step (`shapes.small`).
  final double radius;

  /// False when the face draws its focus itself.
  final bool ring;

  /// Whether hover and press tint the face.
  final bool wash;

  /// The tint on a face that isn't paper: the letters' colour.
  final Color? washColor;

  /// The face lands a pixel under the finger.
  final bool sink;

  /// Whether the face rises on an ink shadow and sinks when pressed.
  final bool plate;

  /// A face under 44: its target is 44 round it on every platform (48 where a finger reaches it, as every press).
  final bool target;

  /// Where the face stands in its target when the target is larger: centred, or on the edges named
  /// ([AlignmentDirectional.centerStart] keeps a bare face on its column's start keyline), the target growing away
  /// from them. A tap anywhere in the target reaches the face.
  final AlignmentGeometry targetAlignment;

  /// Waiting: takes no press, keeps its focus and its face.
  final bool busy;

  /// More keys, on top of Enter and Space: arrows on a radio group, a slider.
  final KeyEventResult Function(FocusNode node, KeyEvent event)? keys;

  /// A styled part's outline, for its states: the pop and the wash follow it in place of [radius]. Null keeps [radius].
  final WidgetStateProperty<OutlinedBorder?>? outline;

  /// A styled part's wash for its states, as `ButtonStyle.overlayColor`: drawn as given in place of the look's ink at
  /// 10% under the press (and nothing under the pointer). Null for a state keeps the look's.
  final WidgetStateProperty<Color?>? overlay;

  /// The pointer over the part. Null: [SystemMouseCursors.click] while it takes presses,
  /// [SystemMouseCursors.basic] while it is disabled or busy.
  final MouseCursor? mouseCursor;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final motion = ComicMotion.of(context);
    // Busy keeps the node and its focus only for a press that has somewhere to go; with none it is disabled, busy or not.
    final holds = onPressed != null || onLongPress != null;
    final live = holds && !busy;
    final tap = onPressed;
    final press = DesignPressable(
      onPressed: live && tap != null
          ? () {
              HapticFeedback.selectionClick();
              tap();
            }
          : null,
      onLongPress: live ? onLongPress : null,
      enabled: holds,
      selected: selected ?? checked ?? toggled ?? false,
      isError: error,
      statesController: statesController,
      focusNode: focusNode,
      autofocus: autofocus,
      onKeyEvent: keys,
      semanticLabel: label,
      semanticHint: hint,
      semanticValue: value,
      button: button,
      link: link,
      semanticSelected: selected,
      checked: checked,
      mixed: mixed,
      toggled: toggled,
      expanded: expanded,
      inMutuallyExclusiveGroup: inGroup,
      excludeSemantics: label != null,
      enableFeedback: false,
      mouseCursor:
          mouseCursor ??
          (live ? SystemMouseCursors.click : SystemMouseCursors.basic),
      builder: (context, states, _) {
        // A busy face is not lit by a pointer: it takes nothing.
        final shown = live
            ? states
            : states.difference({WidgetState.hovered, WidgetState.pressed});
        Widget face = child ?? builder!(context, shown);
        // Disabled screens the face back toward its paper, opaque (law 1: nothing see-through); the change of state
        // moves, as every change of a face does.
        face = ComicScreened(on: !holds, child: face);
        // The marks take the face's own outline; a small face's larger target stays unmarked around it.
        final drawn = outline?.resolve(shown) ?? _defaultOutline(radius, t);
        final over = live ? overlay?.resolve(shown) : null;
        // A raised face stands on its print and sinks onto it; a disabled one has none, it can't be pressed.
        final printed = plate && holds;
        face = ComicHighlight(
          states: shown,
          shape: drawn,
          wash: wash && live,
          washColor: washColor,
          overlay: over,
          ring: ring,
          printed: printed,
          child: face,
        );
        if (printed) {
          face = ComicPlated(down: shown.pressed, shape: drawn, child: face);
        }
        if (target) {
          face = ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: ComicTapTarget.target,
              minHeight: ComicTapTarget.target,
            ),
            child: Center(widthFactor: 1, heightFactor: 1, child: face),
          );
        }
        if (sink && !printed) {
          face = TweenAnimationBuilder<double>(
            tween: Tween(end: shown.pressed ? 1 : 0),
            duration: motion.press,
            // A pop: the face lands past its pixel and settles, and springs back the same way.
            curve: Curves.easeOutBack,
            child: face,
            builder: (context, y, face) =>
                Transform.translate(offset: Offset(0, y), child: face),
          );
        }
        return DesignTapTarget(
          minSize: Size.square(ComicTapTarget.targetOf(context)),
          alignment: targetAlignment,
          child: face,
        );
      },
    );
    return error
        ? MergeSemantics(
            child: Semantics(
              validationResult: SemanticsValidationResult.invalid,
              child: press,
            ),
          )
        : press;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<
          Widget Function(BuildContext context, Set<WidgetState> states)
        >.has('builder', builder),
      )
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(ObjectFlagProperty<VoidCallback>.has('onLongPress', onLongPress))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('hint', hint, defaultValue: null))
      ..add(StringProperty('value', value, defaultValue: null))
      ..add(
        FlagProperty(
          'button',
          value: button,
          ifFalse: 'button: false',
          defaultValue: true,
        ),
      )
      ..add(
        FlagProperty('link', value: link, ifTrue: 'link', defaultValue: false),
      )
      ..add(
        FlagProperty(
          'mixed',
          value: mixed,
          ifTrue: 'mixed',
          defaultValue: false,
        ),
      )
      ..add(
        FlagProperty(
          'inGroup',
          value: inGroup,
          ifTrue: 'inGroup',
          defaultValue: false,
        ),
      )
      ..add(DiagnosticsProperty<bool>('selected', selected, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('checked', checked, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('toggled', toggled, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('expanded', expanded, defaultValue: null))
      ..add(
        FlagProperty(
          'error',
          value: error,
          ifTrue: 'error',
          defaultValue: false,
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      )
      ..add(
        DiagnosticsProperty<WidgetStatesController>(
          'statesController',
          statesController,
          defaultValue: null,
        ),
      )
      ..add(DoubleProperty('radius', radius, defaultValue: 0))
      ..add(
        FlagProperty(
          'ring',
          value: ring,
          ifFalse: 'ring: false',
          defaultValue: true,
        ),
      )
      ..add(
        FlagProperty(
          'wash',
          value: wash,
          ifFalse: 'wash: false',
          defaultValue: true,
        ),
      )
      ..add(ColorProperty('washColor', washColor, defaultValue: null))
      ..add(
        FlagProperty(
          'sink',
          value: sink,
          ifFalse: 'sink: false',
          defaultValue: true,
        ),
      )
      ..add(
        FlagProperty(
          'plate',
          value: plate,
          ifTrue: 'plate',
          defaultValue: false,
        ),
      )
      ..add(
        FlagProperty(
          'target',
          value: target,
          ifTrue: 'target',
          defaultValue: false,
        ),
      )
      ..add(
        DiagnosticsProperty<AlignmentGeometry>(
          'targetAlignment',
          targetAlignment,
          defaultValue: AlignmentDirectional.center,
        ),
      )
      ..add(
        FlagProperty('busy', value: busy, ifTrue: 'busy', defaultValue: false),
      )
      ..add(
        ObjectFlagProperty<
          KeyEventResult Function(FocusNode node, KeyEvent event)
        >.has('keys', keys),
      )
      ..add(
        DiagnosticsProperty<WidgetStateProperty<OutlinedBorder?>>(
          'outline',
          outline,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<WidgetStateProperty<Color?>>(
          'overlay',
          overlay,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<MouseCursor>(
          'mouseCursor',
          mouseCursor,
          defaultValue: null,
        ),
      );
  }
}

/// A press's own outline when none is given: its [ComicPressable.radius] when set, the control step otherwise.
OutlinedBorder _defaultOutline(double radius, ComicThemeData t) => radius > 0
    ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius))
    : t.shapes.small;

/// A plain ink tint under the pointer or a press, and the keyboard's pop: under the focus the part lifts up and to the
/// start off a hard print of its outline, down and to the end, its words on a plain fill. The tint is uniform across the
/// lettering.
///
/// [ComicPressable] draws it over its whole face. A face whose pressable part is smaller than its target (a tab bar's
/// indicator above its word) turns the press's own marks off and puts this around that part.
///
/// ```dart
/// ComicHighlight(states: states, shape: theme.shapes.small, child: indicator)
/// ```
class ComicHighlight extends StatelessWidget {
  /// Creates a [ComicHighlight].
  const ComicHighlight({
    super.key,
    required this.states,
    required this.shape,
    required this.child,
    this.wash = true,
    this.washColor,
    this.overlay,
    this.ring = true,
    this.ringGap,
    this.printed = false,
  });

  /// Whether the face stands on its print ([ComicPlated]): lifted, that print shows wider, and no second one is drawn.
  final bool printed;

  /// The press's states: hovered and pressed shade it, focused pops it.
  final Set<WidgetState> states;

  /// The plain fill a part with no fill of its own stands on while it pops: the face its words were written on (a
  /// split button's half on the act face, a trough's cell on the trough). Null: the card. Where the part pops inside
  /// its row ([PopInside]), the band laid inside its print.
  final Color? ringGap;

  /// The part's outline, from the look's shape theme.
  final OutlinedBorder shape;

  /// The part.
  final Widget child;

  /// Shades under the pointer and the press.
  final bool wash;

  /// The tint on a part that isn't paper: the letters' colour. Null: the ink.
  final Color? washColor;

  /// A styled part's wash for these states, drawn as given.
  final Color? overlay;

  /// Pops under the keyboard's focus.
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final ringed = ring && states.focused;
    final over = overlay;
    // A styled overlay keeps its own strength. The default is a light, even tint.
    final washTo = over != null
        ? 1.0
        : !wash
        ? 0.0
        : states.pressed
        ? 1.0
        : states.hovered
        ? _hoverShade
        : 0.0;
    final tint = over ?? (washColor ?? t.colors.text).withValues(alpha: .10);
    final motion = ComicMotion.of(context);
    final direction = Directionality.maybeOf(context);
    final end = direction == TextDirection.rtl ? -1.0 : 1.0;
    // The wash and the pop each move from where they are: under the keyboard the part pops off the page, lifting up
    // and to the start off a hard print of its outline, and settles back.
    return TweenAnimationBuilder<double>(
      tween: Tween(end: ringed ? 1 : 0),
      duration: motion.state,
      curve: comicStateCurve,
      child: child,
      builder: (context, r, child) => TweenAnimationBuilder<double>(
        tween: Tween(end: washTo),
        duration: motion.press,
        curve: Curves.easeOut,
        child: child,
        builder: (context, w, child) {
          final outline = shape.copyWith(side: BorderSide.none);
          final popped = r > 0;
          // A part with no fill of its own pops on the card, a panel off the page, unless it stands on a filled ground
          // (a lamp, a chosen row): that fill stays behind its words, and its print takes their ink, which reads on it.
          final ground = !popped
              ? null
              : ringGap ?? (Lettered.of(context) ? null : t.colors.card);
          final ink = ground == null ? t.colors.text : _printInk(t, ground);
          final inside = popped && PopInside.of(context);
          final lift = popped && !inside
              ? Offset(-end * comicFocusLift * r, -comicFocusLift * r)
              : Offset.zero;
          final step = t.focus.width * r;
          // One tree in every state, only its paint and offset change, so the part (a field, a scrolling list) keeps
          // its state as the focus comes and goes.
          return CustomPaint(
            // A part on its print already stands on one: lifted, the print shows wider. Any other gets its own.
            painter: !popped || inside || printed
                ? null
                : _PopPainter(
                    outline,
                    ink,
                    ground,
                    Offset(end * step, step),
                    lift,
                    direction ?? TextDirection.ltr,
                  ),
            foregroundPainter: !inside
                ? null
                : _InsetPrint(
                    outline,
                    ink,
                    ringGap,
                    (t.focus.width + 2) * r,
                    direction ?? TextDirection.ltr,
                  ),
            // Drawn, not hit: the part answers the pointer where it stood.
            child: Transform.translate(
              offset: lift,
              transformHitTests: false,
              child: CustomPaint(
                foregroundPainter: w <= 0
                    ? null
                    : _WashPainter(
                        tint.withValues(alpha: tint.a * w),
                        outline,
                        direction,
                      ),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        FlagProperty(
          'printed',
          value: printed,
          ifTrue: 'printed',
          defaultValue: false,
        ),
      )
      ..add(IterableProperty<WidgetState>('states', states))
      ..add(ColorProperty('ringGap', ringGap, defaultValue: null))
      ..add(DiagnosticsProperty<OutlinedBorder>('shape', shape))
      ..add(
        FlagProperty(
          'wash',
          value: wash,
          ifFalse: 'wash: false',
          defaultValue: true,
        ),
      )
      ..add(ColorProperty('washColor', washColor, defaultValue: null))
      ..add(ColorProperty('overlay', overlay, defaultValue: null))
      ..add(
        FlagProperty(
          'ring',
          value: ring,
          ifFalse: 'ring: false',
          defaultValue: true,
        ),
      );
  }
}

const double _hoverShade = .65;

/// The pointer's and the press's tint, filling the part's outline.
class _WashPainter extends CustomPainter {
  _WashPainter(this.wash, this.drawn, this.direction);

  final Color wash;
  final OutlinedBorder drawn;
  final TextDirection? direction;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    drawn.getOuterPath(Offset.zero & size, textDirection: direction),
    fillPaint(wash),
  );

  @override
  bool shouldRepaint(_WashPainter o) =>
      o.wash != wash || o.drawn != drawn || o.direction != direction;
}

/// The print a focused part pops off where it cannot lift (a row edge to edge in its list, [PopInside]): a band
/// [step] deep inside its outline along the bottom and the end, as its shadow would show, with a band of [gap] inside
/// it to keep it apart from a fill near its ink.
class _InsetPrint extends CustomPainter {
  const _InsetPrint(
    this.outline,
    this.ink,
    this.gap,
    this.step,
    this.direction,
  );

  final OutlinedBorder outline;
  final Color ink;
  final Color? gap;
  final double step;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    if (step <= 0) return;
    final box = Offset.zero & size;
    final end = direction == TextDirection.rtl ? -1.0 : 1.0;
    final face = outline.getOuterPath(box, textDirection: direction);
    // Even-odd: the outline less itself moved up and to the start (the web build doesn't cut a difference).
    Path band(double d) => Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(face, Offset.zero)
      ..addPath(
        outline.getOuterPath(
          box.shift(Offset(-end * d, -d)),
          textDirection: direction,
        ),
        Offset.zero,
      );
    canvas
      ..save()
      ..clipPath(face);
    final gap = this.gap;
    if (gap != null) canvas.drawPath(band(step + 2), fillPaint(gap));
    canvas
      ..drawPath(band(step), fillPaint(ink))
      ..restore();
  }

  @override
  bool shouldRepaint(_InsetPrint o) =>
      o.outline != outline ||
      o.ink != ink ||
      o.gap != gap ||
      o.step != step ||
      o.direction != direction;
}

/// Emanata at the corners of the focus ring Comic drew before its focus became the pop: each tick this many ring widths
/// long and this fraction of its weight, [comicEmanataGap] clear of the ring, fanned [comicEmanataSpread] radians either
/// side of the corner's diagonal.
@Deprecated(
  'Comic no longer draws a focus ring or its emanata: a focused part pops off its print.',
)
const double comicEmanataLength = 1.5,
    comicEmanataWeight = .8,
    comicEmanataGap = 1.5,
    comicEmanataSpread = .5;

/// The distance between a raised control and its hard shadow, in logical pixels.
const double comicPressPlate = 3;

/// How far a disabled face is screened back toward its paper: half way, opaque.
const double comicDisabledScreen = .5;

/// A raised face with a fixed ink shadow. When [down] is true, the face moves
/// toward the shadow. [shape] defines both outlines.
///
/// ```dart
/// ComicPlated(down: states.pressed, shape: theme.shapes.small, child: face)
/// ```
class ComicPlated extends StatelessWidget {
  /// Creates a [ComicPlated].
  const ComicPlated({
    super.key,
    required this.down,
    required this.shape,
    required this.child,
  });

  /// Pressed: the face stands on its print.
  final bool down;

  /// The face's outline, which the print repeats.
  final OutlinedBorder shape;

  /// The face.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final direction = Directionality.of(context);
    final step = Offset(
      direction == TextDirection.rtl ? -comicPressPlate : comicPressPlate,
      comicPressPlate,
    );
    return CustomPaint(
      painter: _PrintPainter(
        shape.copyWith(side: BorderSide.none),
        t.colors.nightLine,
        step,
        direction,
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: down ? 1 : 0),
        duration: ComicMotion.of(context).press,
        curve: Curves.easeOutBack,
        child: child,
        builder: (context, d, face) =>
            Transform.translate(offset: step * d, child: face),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        FlagProperty(
          'down',
          value: down,
          ifTrue: 'down',
          ifFalse: 'down: false',
        ),
      )
      ..add(DiagnosticsProperty<OutlinedBorder>('shape', shape));
  }
}

/// The print a focused part pops off: its outline [step] down and to the end in [ink], and the face lifted by [lift]
/// laid on a plain [ground], so a part with no fill of its own (a link, a quiet button, a row) pops as a panel with its
/// words on a plain fill. A part with a fill covers the ground with its own; with no [ground] the fill under the part
/// (a lamp, a chosen row) stays behind it.
class _PopPainter extends CustomPainter {
  const _PopPainter(
    this.outline,
    this.ink,
    this.ground,
    this.step,
    this.lift,
    this.direction,
  );
  final ShapeBorder outline;
  final Color ink;
  final Color? ground;
  final Offset step, lift;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    final print = outline.getOuterPath(
      box.shift(step),
      textDirection: direction,
    );
    // Even-odd round the lifted face: the clip is everything but the face (the web build doesn't cut a difference).
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(box.inflate(step.distance + lift.distance + 8))
      ..addPath(
        outline.getOuterPath(box.shift(lift), textDirection: direction),
        Offset.zero,
      );
    canvas
      ..save()
      ..clipPath(outside)
      ..drawPath(print, fillPaint(ink))
      ..restore();
    final ground = this.ground;
    if (ground != null) {
      canvas.drawPath(
        outline.getOuterPath(box.shift(lift), textDirection: direction),
        fillPaint(ground),
      );
    }
  }

  @override
  bool? hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_PopPainter old) =>
      old.outline != outline ||
      old.ink != ink ||
      old.ground != ground ||
      old.step != step ||
      old.lift != lift ||
      old.direction != direction;
}

class _PrintPainter extends CustomPainter {
  const _PrintPainter(this.outline, this.ink, this.step, this.direction);
  final ShapeBorder outline;
  final Color ink;
  final Offset step;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    outline.getOuterPath(
      (Offset.zero & size).shift(step),
      textDirection: direction,
    ),
    fillPaint(ink),
  );

  @override
  bool? hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_PrintPainter old) =>
      old.outline != outline ||
      old.ink != ink ||
      old.step != step ||
      old.direction != direction;
}

/// Legacy dot dimensions for artwork matching the 0.2.0 print screen.
const double comicDisabledDotPitch = 7, comicDisabledDotRadius = 1.25;

/// Minimum word contrast on a disabled control's fill.
const double comicDisabledWordsContrast = 4.5;

/// Softens an unavailable control's ink while keeping its words distinct on a
/// flat, lightly inked ground.
///
/// ```dart
/// ComicScreened(on: !enabled, child: field)
/// ```
class ComicScreened extends StatelessWidget {
  /// Creates a [ComicScreened].
  const ComicScreened({
    super.key,
    required this.on,
    this.amount = comicDisabledScreen,
    this.muteFill = true,
    required this.child,
  });

  /// Screened back.
  final bool on;

  /// How far toward the paper, from 0 (the face as it is) to 1 (paper).
  final double amount;

  /// Gives disabled controls a muted fill and separate readable ink. An avatar
  /// outside a group instead softens its portrait as a whole.
  final bool muteFill;

  /// The face.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: on ? amount : 0),
      duration: ComicMotion.of(context).state,
      curve: comicStateCurve,
      child: child,
      builder: (context, a, face) {
        final screen = _Screen(
          amount: a,
          target: amount,
          ground: t.colors.card,
          ink: t.colors.text,
          muteFill: muteFill,
          child: face,
        );
        return _ScreenScope(
          ground: muteFill && a > 0 ? t.colors.card : null,
          child: screen,
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('on', value: on, ifTrue: 'on', ifFalse: 'on: false'))
      ..add(DoubleProperty('amount', amount, defaultValue: comicDisabledScreen))
      ..add(
        FlagProperty(
          'muteFill',
          value: muteFill,
          ifFalse: 'muteFill: false',
          defaultValue: true,
        ),
      );
  }
}

// Tells the face's decorations under a screen that prints ink fills separately which paper they stand on; null: none does.
class _ScreenScope extends InheritedWidget {
  const _ScreenScope({required this.ground, required super.child});
  final Color? ground;

  static Color? groundOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ScreenScope>()?.ground;

  @override
  bool updateShouldNotify(_ScreenScope old) => old.ground != ground;
}

/// A focus print's ink on [ground]: the plate's, as every print in the comic, unless it would not show there (a
/// caption's yellow at night); then the first of the comic's inks that reaches 3:1 on it, or the one that shows most.
Color _printInk(ComicThemeData t, Color ground) {
  final g = ground.computeLuminance();
  double on(Color ink) => _contrastOf(ink.computeLuminance(), g);
  final inks = [
    t.colors.nightLine,
    t.colors.onCaption,
    t.colors.text,
    t.focus.color,
  ];
  for (final ink in inks) {
    if (on(ink) >= 3) return ink;
  }
  return inks.reduce((a, b) => on(a) >= on(b) ? a : b);
}

/// The contrast between two colours, as WCAG reckons it.
double _contrastOf(double a, double b) =>
    (math.max(a, b) + .05) / (math.min(a, b) + .05);

// A decoration's ink fill: an opaque colour of its own, away from the paper, and the decoration without it.
class _InkFill {
  const _InkFill(this.color, this.decoration, this.hollow);
  final Color color;
  final Decoration decoration;
  final Decoration hollow;

  // A fill this close to the paper is paper (a field's, a card's): it stays in the face, screened back with it.
  static const double _fromPaper = 1.2;

  static _InkFill? of(Decoration d, Color ground) {
    final (Color? color, Decoration? hollow) = switch (d) {
      ShapeDecoration(
        color: final c?,
        gradient: null,
        image: null,
        :final shape,
        :final shadows,
      ) =>
        (c, ShapeDecoration(shape: shape, shadows: shadows)),
      BoxDecoration(
        color: final c?,
        gradient: null,
        image: null,
        backgroundBlendMode: null,
        :final border,
        :final borderRadius,
        :final boxShadow,
        :final shape,
      ) =>
        (
          c,
          BoxDecoration(
            border: border,
            borderRadius: borderRadius,
            boxShadow: boxShadow,
            shape: shape,
          ),
        ),
      _ => (null, null),
    };
    if (color == null || hollow == null || color.a < 1) return null;
    if (_contrastOf(color.computeLuminance(), ground.computeLuminance()) <
        _fromPaper) {
      return null;
    }
    return _InkFill(color, d, hollow);
  }
}

// Hands its ink fill, in its own outline, to the screen above it as it paints.
class _FillMark extends SingleChildRenderObjectWidget {
  const _FillMark({required this.fill, super.child});
  final _InkFill? fill;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFillMark(fill, Directionality.maybeOf(context));

  @override
  void updateRenderObject(BuildContext context, _RenderFillMark renderObject) =>
      renderObject
        ..fill = fill
        ..direction = Directionality.maybeOf(context);
}

class _RenderFillMark extends RenderProxyBox {
  _RenderFillMark(this._fill, this._direction);
  _InkFill? _fill;
  TextDirection? _direction;

  set fill(_InkFill? value) {
    if (identical(value, _fill)) return;
    _fill = value;
    markNeedsPaint();
  }

  set direction(TextDirection? value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final fill = _fill;
    if (fill != null) {
      for (var above = parent; above != null; above = above.parent) {
        if (above is! _RenderScreen) continue;
        final outline = fill.decoration.getClipPath(
          Offset.zero & size,
          _direction ?? TextDirection.ltr,
        );
        above._fills.add((
          fill.color,
          outline.transform(getTransformTo(above).storage),
        ));
        break;
      }
    }
    super.paint(context, offset);
  }
}

// A disabled face keeps its muted fills separate from its lettering.
class _Screen extends SingleChildRenderObjectWidget {
  const _Screen({
    required this.amount,
    required this.target,
    required this.ground,
    required this.ink,
    required this.muteFill,
    super.child,
  });
  final double amount, target;
  final Color ground, ink;
  final bool muteFill;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderScreen(amount, target, ground, ink, muteFill);

  @override
  void updateRenderObject(BuildContext context, _RenderScreen renderObject) =>
      renderObject
        ..amount = amount
        ..target = target
        ..ground = ground
        ..ink = ink
        ..muteFill = muteFill;
}

class _RenderScreen extends RenderProxyBox {
  _RenderScreen(
    this._amount,
    this._target,
    this._ground,
    this._ink,
    this._muteFill,
  );
  double _amount, _target;
  Color _ground, _ink;
  bool _muteFill;

  // The ink fills the face's decorations handed up as it painted, in this box's coordinates.
  final List<(Color, Path)> _fills = [];

  // The muted fills' layer, kept from frame to frame as the screen's is and held here: a context that never takes it
  // into its tree (a recording one, as a test paints with) leaves nothing undisposed.
  final LayerHandle<ContainerLayer> _under = LayerHandle<ContainerLayer>();

  @override
  void dispose() {
    _under.layer = null;
    super.dispose();
  }

  set amount(double value) {
    if (value == _amount) return;
    final was = _amount > 0;
    _amount = value;
    if (was != (value > 0)) markNeedsCompositingBitsUpdate();
    markNeedsPaint();
  }

  set target(double value) {
    if (value == _target) return;
    _target = value;
    markNeedsPaint();
  }

  set ground(Color value) {
    if (value == _ground) return;
    _ground = value;
    markNeedsPaint();
  }

  set ink(Color value) {
    if (value == _ink) return;
    _ink = value;
    markNeedsPaint();
  }

  set muteFill(bool value) {
    if (value == _muteFill) return;
    _muteFill = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => child != null && _amount > 0;

  // The same solid fill is used here and in paint, so every label meets its
  // contrast ratio against the ground the reader actually sees.
  Color _muted(Color fill) => Color.lerp(fill, _ground, .85)!;

  Color _wordsOn() {
    final grounds = [
      _ground.computeLuminance(),
      for (final (fill, _) in _fills) _muted(fill).computeLuminance(),
    ];
    for (var a = _target; a > 0; a -= .01) {
      final words = Color.lerp(_ink, _ground, a)!;
      final l = words.computeLuminance();
      if (grounds.every(
        (g) => _contrastOf(l, g) >= comicDisabledWordsContrast,
      )) {
        return words;
      }
    }
    return _ink;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    _fills.clear();
    if (child == null) return;
    if (_amount <= 0) {
      layer = null;
      _under.layer = null;
      context.paintChild(child, offset);
      return;
    }
    // The muted fills go under the face: a layer laid before it, filled once the face has handed them up.
    final ContainerLayer? under;
    if (_muteFill) {
      under = _under.layer ??= ContainerLayer();
      under.removeAllChildren();
      context.addLayer(under);
    } else {
      _under.layer = null;
      under = null;
    }
    // The colour-filter layer kept from frame to frame, pushed as `pushColorFilter` pushes it (a recording context,
    // as a test paints with, takes a pushed layer too).
    final screen = layer is ColorFilterLayer
        ? layer! as ColorFilterLayer
        : ColorFilterLayer();
    layer = screen;
    context.pushLayer(
      screen,
      (context, offset) => context.paintChild(child, offset),
      offset,
    );
    if (under == null || _fills.isEmpty) {
      final a = _muteFill ? _amount * .24 : _amount;
      final k = 1 - a, g = _ground;
      screen.colorFilter = ColorFilter.matrix([
        k, 0, 0, 0, a * g.r * 255, //
        0, k, 0, 0, a * g.g * 255,
        0, 0, k, 0, a * g.b * 255,
        0, 0, 0, 1, 0,
      ]);
      return;
    }
    // How far along the change of state: the fill goes from ink to its flat tint, the face from its own
    // colours to the one screened ink.
    final s = _target <= 0 ? 1.0 : (_amount / _target).clamp(0.0, 1.0);
    final w = _wordsOn(), k = 1 - s;
    screen.colorFilter = ColorFilter.matrix([
      k, 0, 0, 0, s * w.r * 255, //
      0, k, 0, 0, s * w.g * 255,
      0, 0, k, 0, s * w.b * 255,
      0, 0, 0, 1, 0,
    ]);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    var bounds = Rect.zero;
    for (final (color, outline) in _fills) {
      final drawn = outline.shift(offset);
      final box = drawn.getBounds();
      bounds = bounds.isEmpty ? box : bounds.expandToInclude(box);
      canvas.drawPath(drawn, fillPaint(Color.lerp(color, _muted(color), s)!));
    }
    under.append(PictureLayer(bounds)..picture = recorder.endRecording());
  }
}
