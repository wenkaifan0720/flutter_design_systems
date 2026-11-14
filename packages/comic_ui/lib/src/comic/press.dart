// The one press every control in Comic stands on: the design kit's pressable (focus, Enter and Space, hover, one
// semantics node, the states) with Comic's face on it: a press that lands a pixel under a wash in the part's own
// outline, and a ring that only the keyboard sees, each moving on Comic's motion tokens. The pointer's approach
// changes no face: the cursor says a part presses ([SystemMouseCursors.click]), and an app that wants a hover style
// resolves [WidgetState.hovered] in a component theme or a part's style.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' show MaterialTapTargetSize, Theme;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/geometry.dart';
import 'internal/reach.dart';
import 'styled.dart';
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

/// Every control's least target, and where a touch reaches it.
abstract final class ComicTapTarget {
  /// Every control's least target.
  static const double target = 44;

  /// Every control's least target where a touch reaches it: Android's 48, as Material's padded tap target.
  static const double touchTarget = 48;

  /// Whether a touch reaches the controls at [context]: the app's `materialTapTargetSize` is padded, as it is by default
  /// on Android and iOS. There every press stands at least [touchTarget] square, its face at its own size.
  static bool padded(BuildContext context) =>
      Theme.of(context).materialTapTargetSize == MaterialTapTargetSize.padded;

  /// The least target at [context]: [touchTarget] where a touch reaches it, [target] elsewhere.
  /// None inside a row that takes the press itself (a check row's box).
  static double targetOf(BuildContext context) => RowMark.inRow(context)
      ? 0
      : padded(context)
      ? touchTarget
      : target;
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
      builder: (context, decoration, child) => DecoratedBox(
        decoration: decoration,
        position: position,
        child: child,
      ),
    );
    final sized = width != null || height != null
        ? constraints?.tighten(width: width, height: height) ??
              BoxConstraints.tightFor(width: width, height: height)
        : constraints;
    if (sized != null) box = ConstrainedBox(constraints: sized, child: box);
    return box;
  }
}

/// Makes a face a control. Use it for a tile of your own: the parts in this library already stand on it.
///
/// It stands on the design kit's `DesignPressable`: one semantics node named [label], the face's own words kept out of
/// it, or merged in when [label] is null; Enter and Space press it; the face's [builder] gets the press's
/// `Set<WidgetState>`. A finger sinks it a pixel under a wash in its outline, the keyboard rings it
/// ([ComicThemeData.focus]), each on [ComicMotion.press] and a cut under Reduce Motion. The pointer's approach changes
/// nothing on the face: the cursor turns to [SystemMouseCursors.click] over a part that presses and stays
/// [SystemMouseCursors.basic] over one that doesn't. [WidgetState.hovered] still reaches [builder], [outline] and
/// [overlay], so a style can give hover a look of its own. Null [onPressed] is disabled, and the face says so: pass
/// [busy] instead to take no press while keeping focus and face.
///
/// Its least target ([ComicTapTarget.targetOf]: 44, or 48 by 48 where a touch reaches it, as Material's padded tap target)
/// pads outward beside the face and never moves it along its line: the press is as wide as its drawn face, so the face
/// starts where its parent puts it (a column's edge), and as tall as its target, so rows and stacks of presses keep
/// their height. The target's sides are hit-tested and read by a screen reader only, reaching as far as the boxes
/// around the press let a press reach and never over a neighbour's face. A touch in the margin reaches the face's
/// centre.
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
    this.target = false,
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

  /// A corner its ring and wash follow when [outline] is null; 0 takes the theme's control step (`shapes.small`).
  final double radius;

  /// False when the face draws the ring itself.
  final bool ring;

  /// A wash over the face under the pointer and the press.
  final bool wash;

  /// The wash on a face that isn't paper: the letters' colour.
  final Color? washColor;

  /// The face lands a pixel under the finger.
  final bool sink;

  /// A face under 44: its target is 44 round it on every platform (48 where a touch reaches it, as every press), padding
  /// outward as every press's does.
  final bool target;

  /// Waiting: takes no press, keeps its focus and its face.
  final bool busy;

  /// More keys, on top of Enter and Space: arrows on a radio group, a slider.
  final KeyEventResult Function(FocusNode node, KeyEvent event)? keys;

  /// A styled part's outline, for its states: the ring and the wash follow it in place of [radius]. Null keeps [radius].
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
        // Disabled screens the face; the change of state moves, as every change of a face does.
        face = AnimatedOpacity(
          opacity: holds ? 1 : .5,
          duration: motion.state,
          curve: comicStateCurve,
          child: face,
        );
        // The marks take the face's own outline; a small face's larger target stays unmarked around it.
        final drawn = outline?.resolve(shown) ?? _defaultOutline(radius, t);
        final over = live ? overlay?.resolve(shown) : null;
        face = ComicHighlight(
          states: shown,
          shape: drawn,
          wash: wash && live,
          washColor: washColor,
          overlay: over,
          ring: ring,
          child: face,
        );
        // The drawn face: what the press is as wide as, its target round it (a part marks a face of its own inside,
        // a box's mark in its target, with a [ComicPressFace] of its own).
        face = ComicPressFace(child: face);
        if (target) {
          face = ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: ComicTapTarget.target,
              minHeight: ComicTapTarget.target,
            ),
            child: Center(widthFactor: 1, heightFactor: 1, child: face),
          );
        }
        if (sink) {
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
        return _TapTarget(
          minSize: Size.square(ComicTapTarget.targetOf(context)),
          child: face,
        );
      },
    );
    return _Reach(
      child: error
          ? MergeSemantics(
              child: Semantics(
                validationResult: SemanticsValidationResult.invalid,
                child: press,
              ),
            )
          : press,
    );
  }
}

/// A press's own outline when none is given: its [ComicPressable.radius] when set, the control step otherwise.
OutlinedBorder _defaultOutline(double radius, ComicThemeData t) => radius > 0
    ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius))
    : t.shapes.small;

/// The look's interaction marks on one part of a face: the press's wash (10% of the ink, or [overlay] as given) and the
/// keyboard's ring, each in [shape]. The pointer's approach draws nothing unless [overlay] gives a colour for
/// [WidgetState.hovered]. The wash fills the part's exact outline; the ring stands [ComicFocusRing.gap] outside it,
/// concentric (a rounded corner grows by the gap, a square one stays square, a circle stays a circle).
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
  });

  /// The press's states: pressed washes it, focused rings it; hovered only reaches [overlay].
  final Set<WidgetState> states;

  /// An opaque gap, in this colour, between the part and its ring, concentric with both. For a ring drawn on a fill
  /// (a split button's half inside the act face): the fill around a ring can come close to the ring's own colour, and
  /// the gap keeps the ring apart from it. A ring on the ground needs none: the gap shows the ground and the part's own
  /// rim stands between it and the part's fill.
  final Color? ringGap;

  /// The part's outline, from the look's shape theme.
  final OutlinedBorder shape;

  /// The part.
  final Widget child;

  /// Washes under the press.
  final bool wash;

  /// The wash on a part that isn't paper: the letters' colour. Null: the ink.
  final Color? washColor;

  /// A styled part's wash for these states, drawn as given.
  final Color? overlay;

  /// Rings under the keyboard's focus.
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final ringed = ring && states.focused;
    final over = overlay;
    final washTo = over != null
        ? 1.0
        : !wash
        ? 0.0
        : states.pressed
        ? .1
        : 0.0;
    final motion = ComicMotion.of(context);
    // The wash and the ring each move from where they are: the ring inks in round the face, and out.
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
        builder: (context, w, child) => CustomPaint(
          foregroundPainter: w <= 0 && r <= 0
              ? null
              : _PressPainter(
                  w <= 0
                      ? null
                      : over != null
                      ? over.withValues(alpha: over.a * w)
                      : (washColor ?? t.colors.text).withValues(alpha: w),
                  // Drawn, not faded: the ring's line thickens from nothing to its width.
                  r <= 0
                      ? null
                      : ComicFocusRing(
                          color: t.focus.color,
                          width: t.focus.width * r.clamp(0, 1),
                          gap: t.focus.gap,
                        ),
                  shape.copyWith(side: BorderSide.none),
                  Directionality.maybeOf(context),
                  r <= 0 ? null : ringGap,
                ),
          child: child,
        ),
      ),
    );
  }
}

class _PressPainter extends CustomPainter {
  _PressPainter(this.wash, this.ring, this.drawn, this.direction, [this.gap]);

  /// The part's outline: the wash fills it, the ring stands concentric outside it.
  final OutlinedBorder drawn;
  final TextDirection? direction;
  final Color? wash;
  final ComicFocusRing? ring;

  /// [ComicHighlight.ringGap]: the band from the outline to the ring's centre, filled before the ring is stroked over
  /// its outer half.
  final Color? gap;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    if (wash != null) {
      canvas.drawPath(
        drawn.getOuterPath(r, textDirection: direction),
        fillPaint(wash!),
      );
    }
    final ring = this.ring;
    if (ring != null) {
      final centre = comicOutsetShape(
        drawn,
        ring.gap,
      ).getOuterPath(r.inflate(ring.gap), textDirection: direction);
      final gap = this.gap;
      if (gap != null) {
        // Even-odd, not Path.combine: the web build doesn't cut a difference (Flutter 3.47).
        canvas.drawPath(
          Path()
            ..fillType = PathFillType.evenOdd
            ..addPath(centre, Offset.zero)
            ..addPath(
              drawn.getOuterPath(r, textDirection: direction),
              Offset.zero,
            ),
          fillPaint(gap),
        );
      }
      canvas.drawPath(centre, strokePaint(ring.color, ring.width));
    }
  }

  @override
  bool shouldRepaint(_PressPainter o) =>
      o.gap != gap ||
      o.wash != wash ||
      o.ring?.color != ring?.color ||
      o.ring?.width != ring?.width ||
      o.ring?.gap != ring?.gap ||
      o.drawn != drawn ||
      o.direction != direction;
}

// Material's padded tap target (its `_InputPadding`), for a press: the face is laid out under the constraints the press
// was given, as if nothing stood around it, and the target grows around it to [minSize] as far as those constraints let
// it, the face centred. A touch in the margin reaches the face's centre. [_Reach] lays the whole press out as wide as
// the face, so the target's sides pad outward.
class _TapTarget extends SingleChildRenderObjectWidget {
  const _TapTarget({required this.minSize, required super.child});

  final Size minSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTapTarget(minSize);

  @override
  void updateRenderObject(BuildContext context, _RenderTapTarget target) =>
      target.minSize = minSize;
}

class _RenderTapTarget extends RenderShiftedBox {
  _RenderTapTarget(this._minSize) : super(null);

  Size get minSize => _minSize;
  Size _minSize;
  set minSize(Size value) {
    if (_minSize == value) return;
    _minSize = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(child?.getMinIntrinsicWidth(height) ?? 0, minSize.width);

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(child?.getMinIntrinsicHeight(width) ?? 0, minSize.height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(child?.getMaxIntrinsicWidth(height) ?? 0, minSize.width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(child?.getMaxIntrinsicHeight(width) ?? 0, minSize.height);

  Size _sized(BoxConstraints constraints, Size face) => constraints.constrain(
    Size(
      math.max(face.width, minSize.width),
      math.max(face.height, minSize.height),
    ),
  );

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return Size.zero;
    return _sized(constraints, child.getDryLayout(constraints));
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final child = this.child;
    if (child == null) return null;
    final at = child.getDryBaseline(constraints, baseline);
    if (at == null) return null;
    final face = child.getDryLayout(constraints);
    return at +
        Alignment.center
            .alongOffset(_sized(constraints, face) - face as Offset)
            .dy;
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = Size.zero;
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    size = _sized(constraints, child.size);
    (child.parentData! as BoxParentData).offset = Alignment.center.alongOffset(
      size - child.size as Offset,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) return true;
    final child = this.child;
    if (child == null || !size.contains(position)) return false;
    final centre = child.size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(centre),
      position: centre,
      hitTest: (result, position) => child.hitTest(result, position: centre),
    );
  }
}

// A press laid out as wide as its drawn face (the deepest [ComicPressFace] down the press's chain of single children)
// and as tall as its least target ([_TapTarget]), whose sides stand outward beside the face: painted, hit-tested and
// read by a screen reader where they stand, taking no room along the line, so the face starts on its column's edge
// while rows and stacks of presses keep their height. A touch reaches the target only where the boxes round the press let it, and
// never over a neighbour's own box, so a row of small faces keeps each face its own. Where the press is held at its
// own size (a tight width), it keeps its own placement.
class _Reach extends SingleChildRenderObjectWidget {
  const _Reach({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderReach();
}

class _RenderReach extends RenderShiftedBox {
  _RenderReach() : super(null);

  // The deepest face and where it stands in [child], as laid out (a paint transform, the sink, never counts).
  (RenderBox, Offset)? _face() {
    RenderObject? node = child;
    var at = Offset.zero;
    (RenderBox, Offset)? found;
    while (node is RenderBox) {
      if (node is RenderComicPressFace) found = (node, at);
      if (node is! RenderObjectWithChildMixin<RenderBox>) break;
      final RenderBox? next =
          (node as RenderObjectWithChildMixin<RenderBox>).child;
      if (next == null) break;
      if (node is RenderShiftedBox) {
        at += (next.parentData! as BoxParentData).offset;
      }
      node = next;
    }
    return found;
  }

  // The deepest face and the constraints it meets under [constraints], down the press's chain; null past a box this
  // does not know.
  (RenderBox, BoxConstraints)? _faceUnder(BoxConstraints constraints) {
    RenderObject? node = child;
    var c = constraints;
    (RenderBox, BoxConstraints)? found;
    while (node is RenderBox) {
      if (node is RenderComicPressFace) found = (node, c);
      if (node is RenderConstrainedBox) {
        c = node.additionalConstraints.enforce(c);
      } else if (node is RenderPositionedBox) {
        c = c.loosen();
      } else if (node is RenderPadding) {
        c = c.deflate(node.padding.resolve(node.textDirection));
      } else if (node is RenderFittedBox) {
        c = const BoxConstraints();
      } else if (node is RenderShiftedBox &&
          node is! _RenderTapTarget &&
          node is! _RenderReach) {
        return found;
      }
      if (node is! RenderObjectWithChildMixin<RenderBox>) break;
      node = (node as RenderObjectWithChildMixin<RenderBox>).child;
    }
    return found;
  }

  RenderBox? get _drawn => _face()?.$1;

  @override
  double computeMinIntrinsicWidth(double height) =>
      (_drawn ?? child)?.getMinIntrinsicWidth(height) ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      (_drawn ?? child)?.getMaxIntrinsicWidth(height) ?? 0;

  @override
  double computeMinIntrinsicHeight(double width) =>
      child?.getMinIntrinsicHeight(width) ?? 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      child?.getMaxIntrinsicHeight(width) ?? 0;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    final face = _faceUnder(constraints);
    final whole = child.getDryLayout(constraints);
    if (face == null) return whole;
    return constraints.constrain(
      Size(face.$1.getDryLayout(face.$2).width, whole.height),
    );
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    // The press stands at the top of its own box, its height in the flow, so its baseline is the whole press's.
    return child?.getDryBaseline(constraints, baseline);
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    final data = child.parentData! as BoxParentData;
    final found = _face();
    if (found == null) {
      size = child.size;
      data.offset = Offset.zero;
      return;
    }
    final (face, at) = found;
    final drawn = (face as RenderComicPressFace).laidOut;
    size = constraints.constrain(Size(drawn.width, child.size.height));
    data.offset = Offset(
      size.width == child.size.width
          ? 0
          : (size.width - drawn.width) / 2 - at.dx,
      0,
    );
  }

  // Whether a box beside this one, in a parent of several, holds [position]: its own box comes before this target.
  bool _neighbourAt(Offset position) {
    final parent = this.parent;
    if (parent
        is! ContainerRenderObjectMixin<
          RenderBox,
          ContainerBoxParentData<RenderBox>
        >) {
      return false;
    }
    final at = position + (parentData! as BoxParentData).offset;
    for (
      RenderBox? box = parent.firstChild;
      box != null;
      box = (box.parentData! as ContainerBoxParentData<RenderBox>).nextSibling
    ) {
      if (box == this) continue;
      if (((box.parentData! as BoxParentData).offset & box.size).contains(at)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    final offset = (child.parentData! as BoxParentData).offset;
    if (!size.contains(position) &&
        (!(offset & child.size).contains(position) || _neighbourAt(position))) {
      return false;
    }
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}
