// How a styled part reads its style and draws its shape: the layers in
// order, a shape that animates to each new one, and the ease every part's
// face rides from one state to the next.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Builds [builder] with [shape], easing to each new shape over Fluent's `durationNormal` (a cut under Reduce
/// Motion). Rounded shapes morph into each other; other shapes snap at the middle. A null shape builds at once with
/// null: the part draws its own.
///
/// ```dart
/// AnimatedFluent2Shape(
///   shape: pressed ? const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))) : const RoundedRectangleBorder(),
///   builder: (context, shape) => DecoratedBox(
///     decoration: ShapeDecoration(color: fill, shape: shape!),
///   ),
/// )
/// ```
class AnimatedFluent2Shape extends StatelessWidget {
  /// Eases to [shape] whenever it changes.
  const AnimatedFluent2Shape({
    super.key,
    required this.shape,
    required this.builder,
  });

  /// The shape to ease to.
  final OutlinedBorder? shape;

  /// What draws the shape, given the shape at this frame.
  final Widget Function(BuildContext context, OutlinedBorder? shape) builder;

  @override
  Widget build(BuildContext context) {
    final shape = this.shape;
    if (shape == null) return builder(context, null);
    return TweenAnimationBuilder<ShapeBorder?>(
      tween: _ShapeTween(end: shape),
      duration: Fluent2Motion.of(context, Fluent2Motion.normal),
      curve: Fluent2Motion.easyEase,
      builder: (context, now, _) =>
          builder(context, now is OutlinedBorder ? now : shape),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<OutlinedBorder>('shape', shape, defaultValue: null),
      )
      ..add(
        ObjectFlagProperty<
          Widget Function(BuildContext context, OutlinedBorder? shape)
        >.has('builder', builder),
      );
  }
}

/// Builds [builder] with [value], easing to each new value as Fluent's
/// controls ease their fill, stroke and inks: over [duration] (Fluent's
/// `durationFaster` unless set) on [curve] (`curveEasyEase` unless set). A
/// change that comes mid-way turns from where the value stands, with no jump
/// back; under Reduce Motion each change is a cut.
///
/// The one way a Fluent 2 part animates a change of state: it resolves its
/// whole face for its states (a [Fluent2ButtonFace], its inks) and eases that
/// face with its [lerp], never a tween per colour. A part of your own does the
/// same.
///
/// ```dart
/// Fluent2Eased<Color>(value: hovered ? hoverFill : restFill, lerp: (a, b, t) => Color.lerp(a, b, t)!, builder: (context, fill) => ColoredBox(color: fill))
/// ```
class Fluent2Eased<T> extends StatefulWidget {
  /// Eases to [value] whenever it changes.
  const Fluent2Eased({
    super.key,
    required this.value,
    required this.lerp,
    required this.builder,
    this.same,
    this.duration = Fluent2Motion.faster,
    this.curve = Fluent2Motion.easyEase,
  });

  /// Where the face is going.
  final T value;

  /// The face a share [t] of the way from [a] to [b].
  final T Function(T a, T b, double t) lerp;

  /// What draws the face, given the face at this frame.
  final Widget Function(BuildContext context, T value) builder;

  /// Whether two faces are the same, so no ease starts; null is `==`.
  final bool Function(T a, T b)? same;

  /// How long an ease takes.
  final Duration duration;

  /// How an ease runs.
  final Curve curve;

  @override
  State<Fluent2Eased<T>> createState() => _Fluent2EasedState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(
        ObjectFlagProperty<T Function(T a, T b, double t)>.has('lerp', lerp),
      )
      ..add(
        ObjectFlagProperty<Widget Function(BuildContext context, T value)>.has(
          'builder',
          builder,
        ),
      )
      ..add(ObjectFlagProperty<bool Function(T a, T b)?>.has('same', same))
      ..add(
        DiagnosticsProperty<Duration>(
          'duration',
          duration,
          defaultValue: Fluent2Motion.faster,
        ),
      )
      ..add(
        DiagnosticsProperty<Curve>(
          'curve',
          curve,
          defaultValue: Fluent2Motion.easyEase,
        ),
      );
  }
}

class _Fluent2EasedState<T> extends State<Fluent2Eased<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(
    vsync: this,
    value: 1,
  );
  late T _from = widget.value;
  late T _to = widget.value;

  T get _now => _run.value >= 1
      ? _to
      : widget.lerp(_from, _to, widget.curve.transform(_run.value));

  bool _same(T a, T b) => widget.same?.call(a, b) ?? a == b;

  @override
  void didUpdateWidget(Fluent2Eased<T> old) {
    super.didUpdateWidget(old);
    if (_same(widget.value, _to)) return;
    final duration = Fluent2Motion.of(context, widget.duration);
    _from = _now;
    _to = widget.value;
    if (duration == Duration.zero) {
      _run.value = 1;
      return;
    }
    _run
      ..duration = duration
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _run,
    builder: (context, _) => widget.builder(context, _now),
  );
}

/// A part's inks eased together: [inks] (a fill, a stroke, the words' and the
/// glyph's colours, in the part's own order) given to [builder] as they stand
/// this frame. Plumbing of the parts that resolve their inks inline.
Widget fluent2EasedInks(
  List<Color> inks,
  Widget Function(BuildContext context, List<Color> inks) builder,
) => Fluent2Eased<List<Color>>(
  value: inks,
  lerp: (a, b, t) => [
    for (var i = 0; i < b.length; i++)
      i < a.length ? Color.lerp(a[i], b[i], t)! : b[i],
  ],
  same: (a, b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  },
  builder: builder,
);

// Material's ShapeBorderTween, without Material.
class _ShapeTween extends Tween<ShapeBorder?> {
  _ShapeTween({super.end});

  @override
  ShapeBorder? lerp(double t) => ShapeBorder.lerp(begin, end, t);
}

/// A styled part's layers for its states: its own `style:`, then its component theme. Each getter is the first layer's
/// value for the states, or null, so the part goes on to its own Fluent default. It is ui_core's [DesignStyleOf].
///
/// ```dart
/// final look = Fluent2StyleOf([style, Fluent2Theme.of(context).tagTheme], states);
/// final fill = look.fill ?? surface;
/// ```
typedef Fluent2StyleOf = DesignStyleOf;

/// A styled surface: [fill] inside [side] at Fluent's [radius], or along
/// [shape] when one is styled, in [shadows], [child] inside [padding] and
/// clipped to the outline when [clip]. What a card, a menu, a popover, a
/// dialog, a sheet, a toast and a tooltip stand on.
///
/// ```dart
/// final look = Fluent2StyleOf([style, theme.cardTheme], const {});
/// Fluent2Plate(
///   fill: look.fill ?? theme.colors.neutralBackground1,
///   side: fluent2Rim(theme, look, theme.colors.neutralStroke2),
///   radius: BorderRadius.circular(Fluent2Radius.xLarge),
///   shape: look.shape,
///   child: body,
/// );
/// ```
class Fluent2Plate extends StatelessWidget {
  /// A plate of [fill] holding [child].
  const Fluent2Plate({
    super.key,
    required this.fill,
    required this.radius,
    required this.child,
    this.side = BorderSide.none,
    this.shape,
    this.shadows,
    this.padding = EdgeInsets.zero,
    this.clip = false,
  });

  /// The plate's colour.
  final Color fill;

  /// Its rim; [BorderSide.none] draws none.
  final BorderSide side;

  /// Fluent's corner, drawn when [shape] is null.
  final BorderRadiusGeometry radius;

  /// A styled outline; it wins over [radius].
  final OutlinedBorder? shape;

  /// Its elevation's shadows.
  final List<BoxShadow>? shadows;

  /// The room inside the plate.
  final EdgeInsetsGeometry padding;

  /// Whether [child] is clipped to the outline.
  final bool clip;

  /// What stands on the plate.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final drawn = shape;
    Widget inner = Padding(padding: padding, child: child);
    if (drawn == null) {
      if (clip) inner = ClipRRect(borderRadius: radius, child: inner);
      return DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: radius,
          border: side.style == BorderStyle.none
              ? null
              : Border.all(color: side.color, width: side.width),
          boxShadow: shadows,
        ),
        child: inner,
      );
    }
    if (clip) {
      inner = ClipPath(
        clipper: ShapeBorderClipper(
          shape: drawn,
          textDirection: Directionality.maybeOf(context),
        ),
        child: inner,
      );
    }
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: fill,
        shape: drawn.copyWith(side: side),
        shadows: shadows,
      ),
      child: inner,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('fill', fill))
      ..add(
        DiagnosticsProperty<BorderSide>(
          'side',
          side,
          defaultValue: BorderSide.none,
        ),
      )
      ..add(DiagnosticsProperty<BorderRadiusGeometry>('radius', radius))
      ..add(
        DiagnosticsProperty<OutlinedBorder>('shape', shape, defaultValue: null),
      )
      ..add(IterableProperty<BoxShadow>('shadows', shadows, defaultValue: null))
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'padding',
          padding,
          defaultValue: EdgeInsets.zero,
        ),
      )
      ..add(FlagProperty('clip', value: clip, ifTrue: 'clip'));
  }
}

/// The corner radius a styled [shape] stands for at [height]: a rounded
/// rectangle's (its top start corner), a stadium's or a circle's half
/// height, [fallback] for any other outline (and for none). What a part
/// that draws Fluent's own strokes along a rounded rectangle (a field's
/// accessible bottom and brand underline, a split button's halves) rounds
/// to. A [height] of [double.infinity] asks for a pill the painter clamps
/// to its own half height.
///
/// ```dart
/// final r = fluent2CornerOf(look.shape, 32, 4);
/// ```
double fluent2CornerOf(OutlinedBorder? shape, double height, double fallback) =>
    switch (shape) {
      RoundedRectangleBorder(:final borderRadius) =>
        borderRadius.resolve(TextDirection.ltr).topLeft.x,
      ContinuousRectangleBorder(:final borderRadius) =>
        borderRadius.resolve(TextDirection.ltr).topLeft.x / 2,
      StadiumBorder() || CircleBorder() => height / 2,
      _ => fallback,
    };

/// The rim a styled part draws: [side] when set, else [edge] (or [fallback])
/// at the theme's regular stroke.
///
/// ```dart
/// final look = Fluent2StyleOf([style, theme.cardTheme], const {});
/// final rim = fluent2Rim(theme, look, theme.border);
/// ```
BorderSide fluent2Rim(
  Fluent2ThemeData theme,
  Fluent2StyleOf look,
  Color fallback, [
  double own = 1,
]) => look.side ?? BorderSide(color: look.edge ?? fallback, width: own);
