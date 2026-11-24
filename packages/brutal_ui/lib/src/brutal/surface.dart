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

  /// The colour of the block along the lower edge while focused.
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
/// slid [BrutalFace.travel] of the way into it, and a square rule of
/// [BrutalThemeData.borderWidth] unless the face supplies its own width.
/// Keyboard focus colours the lower edge of the shadow on a raised face
/// and the lower inside edge on a flat face.
///
/// The surface occupies the size of its face. Leave room for its hard
/// shadow where an ancestor clips its children.
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
      if (face.focus.a > 0) {
        _paintFocusBar(canvas, shadowRect, face.focus);
      }
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
    if (face.focus.a > 0 && (!hasShadow || face.travel == 1)) {
      _paintFocusBar(canvas, faceRect.deflate(width), face.focus);
    }
  }

  @override
  bool shouldRepaint(_SurfacePainter old) =>
      old.face != face || old.width != width || old.shift != shift;
}

/// [BrutalSurface] that moves to each new [face] on a critically damped
/// spring ([BrutalMotion.pressStiffness]), from wherever it is: a press, a
/// release, a focus, a change of fill. A new face mid-way turns from where
/// the surface stands, with no jump back. Under Reduce Motion the change is
/// a short fade, as `RawMotionPolicy` says.
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
      RawMotionPolicy.of(context).effects(
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

/// Marks keyboard focus along the inside lower edge of a shared cell.
class BrutalInsetFocusPainter extends CustomPainter {
  /// Creates a solid focus bar in [color].
  BrutalInsetFocusPainter(this.color);

  /// The colour of the bar.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    _paintFocusBar(
      canvas,
      (Offset.zero & size).deflate(BrutalMetrics.focusGap),
      color,
    );
  }

  @override
  bool shouldRepaint(BrutalInsetFocusPainter old) => old.color != color;
}

/// A part's two style layers ([RawStyleOf]) put on a [BrutalFace]: the
/// style's `fill`, its `foreground`, and its `edge` (or its `side`'s colour)
/// for the rule. Nothing else of a style reaches a face: the rule's weight,
/// the hard shadow and the square corners are the look's.
extension BrutalStyleFace on RawStyleOf {
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
