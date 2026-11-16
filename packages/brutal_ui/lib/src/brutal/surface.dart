/// Brutal's material: a square face in one rule, a hard shadow under what you
/// can press, the press that slides the face into it, and the focus rule.
/// Every Brutal part is drawn with [BrutalSurface]; a part that changes with
/// its states draws [AnimatedBrutalSurface], which moves from one [BrutalFace]
/// to the next on a spring.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'theme.dart';

/// How a surface looks at one moment: what [BrutalSurface] paints and what
/// [AnimatedBrutalSurface] moves between.
@immutable
class BrutalFace with Diagnosticable {
  /// A face of [fill] in a rule of [border].
  const BrutalFace({
    required this.fill,
    required this.border,
    required this.foreground,
    this.shadow = const Color(0x00000000),
    this.travel = 0,
    this.focus = const Color(0x00000000),
    this.borderWidth,
  }) : assert(travel >= 0 && travel <= 1),
       assert(
         borderWidth == null ||
             borderWidth == 0 ||
             (borderWidth >= BrutalMetrics.minBorderWidth &&
                 borderWidth <= BrutalMetrics.maxBorderWidth),
         'Brutal draws one heavy rule or none: a face\'s borderWidth is '
         'null (the theme\'s), 0, or ${BrutalMetrics.minBorderWidth} to '
         '${BrutalMetrics.maxBorderWidth} px, not $borderWidth.',
       );

  /// The face's fill.
  final Color fill;

  /// The rule round the face. Transparent for a part with no rule.
  final Color border;

  /// The words and icons on the face.
  final Color foreground;

  /// The hard shadow's colour; transparent for a flat surface.
  final Color shadow;

  /// How far the face has slid into its shadow: 0 at rest, 1 pressed home
  /// (the shadow gone under it).
  final double travel;

  /// The focus rule's colour; transparent when not focused.
  final Color focus;

  /// The rule's width: null for the theme's
  /// ([BrutalThemeData.borderWidth]), 0 for a cell that shares its
  /// neighbours' rules.
  final double? borderWidth;

  /// A copy with the given fields replaced.
  BrutalFace copyWith({
    Color? fill,
    Color? border,
    Color? foreground,
    Color? shadow,
    double? travel,
    Color? focus,
    double? borderWidth,
  }) => BrutalFace(
    fill: fill ?? this.fill,
    border: border ?? this.border,
    foreground: foreground ?? this.foreground,
    shadow: shadow ?? this.shadow,
    travel: travel ?? this.travel,
    focus: focus ?? this.focus,
    borderWidth: borderWidth ?? this.borderWidth,
  );

  /// Between [a] and [b] at [t].
  static BrutalFace lerp(BrutalFace a, BrutalFace b, double t) {
    if (identical(a, b)) return a;
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    return BrutalFace(
      fill: c(a.fill, b.fill),
      border: c(a.border, b.border),
      foreground: c(a.foreground, b.foreground),
      shadow: c(a.shadow, b.shadow),
      travel: (a.travel + (b.travel - a.travel) * t).clamp(0.0, 1.0),
      focus: c(a.focus, b.focus),
      borderWidth: a.borderWidth == null || b.borderWidth == null
          ? (t < 0.5 ? a.borderWidth : b.borderWidth)
          : a.borderWidth! + (b.borderWidth! - a.borderWidth!) * t,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BrutalFace &&
      other.fill == fill &&
      other.border == border &&
      other.foreground == foreground &&
      other.shadow == shadow &&
      other.travel == travel &&
      other.focus == focus &&
      other.borderWidth == borderWidth;

  @override
  int get hashCode =>
      Object.hash(fill, border, foreground, shadow, travel, focus, borderWidth);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('fill', fill))
      ..add(ColorProperty('border', border))
      ..add(ColorProperty('foreground', foreground))
      ..add(ColorProperty('shadow', shadow))
      ..add(DoubleProperty('travel', travel))
      ..add(ColorProperty('focus', focus))
      ..add(DoubleProperty('borderWidth', borderWidth, defaultValue: null));
  }
}

/// Paints [face] round [child]: the hard shadow
/// ([BrutalThemeData.shadowOffset] down and toward the end side), the face
/// slid [BrutalFace.travel] of the way into it, the square rule
/// ([BrutalThemeData.borderWidth] unless the face says), and the focus rule
/// outside them both.
///
/// The surface's size is its face's: the shadow and the focus rule are drawn
/// outside it, so a raised face lines up with a flat one beside it. Leave
/// the shadow's reach of room after it (and the focus rule's 4 all round)
/// where a clip could cut it.
///
/// It is the primitive every Brutal part is drawn with, public so an app's
/// own part can wear the look.
///
/// ```dart
/// BrutalSurface(face: BrutalFace(fill: colors.surface, border: colors.ink, foreground: colors.ink, shadow: colors.ink), child: const Padding(padding: EdgeInsets.all(16), child: Text('Raw')))
/// ```
class BrutalSurface extends StatelessWidget {
  /// [child] on [face].
  const BrutalSurface({super.key, required this.face, this.child});

  /// How it looks.
  final BrutalFace face;

  /// What stands on the face, inside its rule.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final theme = BrutalTheme.of(context);
    final shift = theme.shadowIn(direction);
    final width = face.borderWidth ?? theme.borderWidth;
    return CustomPaint(
      painter: _SurfacePainter(face, width, shift),
      child: Transform.translate(
        offset: shift * face.travel,
        child: Padding(
          padding: EdgeInsets.all(width),
          child: child == null
              ? null
              : IconTheme.merge(
                  data: IconThemeData(color: face.foreground),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: face.foreground),
                    child: child!,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<BrutalFace>('face', face));
  }
}

class _SurfacePainter extends CustomPainter {
  _SurfacePainter(this.face, this.width, this.shift);

  final BrutalFace face;
  final double width;
  final Offset shift;

  @override
  void paint(Canvas canvas, Size size) {
    final rest = Offset.zero & size;
    final shadowRect = rest.shift(shift);
    final faceRect = rest.shift(shift * face.travel);
    final hasShadow = face.shadow.a > 0;
    if (hasShadow && face.travel < 1) {
      canvas.drawRect(shadowRect, Paint()..color = face.shadow);
    }
    if (face.fill.a > 0) canvas.drawRect(faceRect, Paint()..color = face.fill);
    if (face.border.a > 0 && width > 0) {
      canvas.drawRect(
        faceRect.deflate(width / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..color = face.border,
      );
    }
    if (face.focus.a > 0) {
      // The ring is the outline [by] round the face and its shadow, less the
      // one nearer in: two nested outlines filled even-odd. (Flutter 3.47's
      // web renderer does not cut a Path.combine difference, and fills the
      // whole outline.)
      List<Offset> around(double by) {
        final a = faceRect.inflate(by);
        return hasShadow
            ? _steppedUnion(a, shadowRect.center - faceRect.center)
            : [a.topLeft, a.topRight, a.bottomRight, a.bottomLeft];
      }

      canvas.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addPolygon(
            around(BrutalMetrics.focusGap + BrutalMetrics.focusWidth),
            true,
          )
          ..addPolygon(around(BrutalMetrics.focusGap), true),
        Paint()..color = face.focus,
      );
    }
  }

  // The outline of [a] together with [a] moved by [s] (less than its size
  // either way): a rectangle with a square step at the two corners the move
  // opens.
  static List<Offset> _steppedUnion(Rect a, Offset s) {
    // Drawn for a move down and to the right, then mirrored back.
    final sx = s.dx < 0 ? -1.0 : 1.0;
    final sy = s.dy < 0 ? -1.0 : 1.0;
    Offset m(double x, double y) => Offset(x * sx, y * sy);
    final r = Rect.fromPoints(m(a.left, a.top), m(a.right, a.bottom));
    final dx = s.dx.abs();
    final dy = s.dy.abs();
    return [
      m(r.left, r.top),
      m(r.right, r.top),
      m(r.right, r.top + dy),
      m(r.right + dx, r.top + dy),
      m(r.right + dx, r.bottom + dy),
      m(r.left + dx, r.bottom + dy),
      m(r.left + dx, r.bottom),
      m(r.left, r.bottom),
    ];
  }

  @override
  bool shouldRepaint(_SurfacePainter old) =>
      old.face != face || old.width != width || old.shift != shift;
}

/// [BrutalSurface] that moves to each new [face] on a critically damped
/// spring ([BrutalMotion.pressStiffness]), from wherever it is: a press, a
/// release, a focus, a change of fill. A new face mid-way turns from where
/// the surface stands, with no jump back. Under Reduce Motion the change is
/// a short fade, as `DesignMotionPolicy` says.
///
/// ```dart
/// AnimatedBrutalSurface(face: pressed ? resting.copyWith(travel: 1) : resting, child: const Text('Buy'))
/// ```
class AnimatedBrutalSurface extends StatefulWidget {
  /// [child] on a face that moves to [face].
  const AnimatedBrutalSurface({
    super.key,
    required this.face,
    this.stiffness = BrutalMotion.pressStiffness,
    this.child,
  });

  /// The face to arrive at.
  final BrutalFace face;

  /// The spring's stiffness; the damping ratio is always 1.
  final double stiffness;

  /// What stands on the face.
  final Widget? child;

  @override
  State<AnimatedBrutalSurface> createState() => _AnimatedBrutalSurfaceState();
}

class _AnimatedBrutalSurfaceState extends State<AnimatedBrutalSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this)
    ..value = 1;
  late BrutalFace _from = widget.face;
  late BrutalFace _to = widget.face;

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) => BrutalSurface(face: _now, child: child),
    child: widget.child,
  );
}

/// The keyboard focus inside a cell that shares its rules (a list row, a
/// segment, a navigation cell): a 2 px square line 3 px inside the cell, so
/// it never sits on a neighbour.
class BrutalInsetFocusPainter extends CustomPainter {
  /// A focus line in [color].
  BrutalInsetFocusPainter(this.color);

  /// The line's colour: ink on paper, paper on ink.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      (Offset.zero & size).deflate(
        BrutalMetrics.focusGap + 1 + BrutalMetrics.focusWidth / 2,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = BrutalMetrics.focusWidth
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(BrutalInsetFocusPainter old) => old.color != color;
}

/// A part's two style layers ([DesignStyleOf]) put on a [BrutalFace]: the
/// style's `fill`, its `foreground`, and its `edge` (or its `side`'s colour)
/// for the rule. Nothing else of a style reaches a face: the rule's weight,
/// the hard shadow and the square corners are the look's.
extension BrutalStyleFace on DesignStyleOf {
  /// [face] in these layers' colours.
  BrutalFace on(BrutalFace face) {
    final fill = this.fill;
    final foreground = this.foreground;
    final edge = side?.color ?? this.edge;
    if (fill == null && foreground == null && edge == null) return face;
    return face.copyWith(fill: fill, foreground: foreground, border: edge);
  }

  /// [base] with these layers' `textStyle` over it.
  TextStyle text(TextStyle base) => base.merge(textStyle);
}
