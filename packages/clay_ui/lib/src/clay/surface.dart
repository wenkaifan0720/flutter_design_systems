/// Clay's material: a volume of matte clay ([ClayFace]) painted by
/// [ClaySurface], puffed by a soft light inside its top-leading edge and a
/// soft shade inside its bottom-trailing edge, floating over the ground on a
/// shadow in its own hue; or a well pressed into the ground. Every part of
/// the look is drawn with it.
library;

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/sprites.dart';
import 'theme.dart';

/// One piece of clay: its [color], its corner [radius], how far it stands
/// from the ground ([elevation]) and the moment's state ([press], [lift],
/// [focus]). Its light, its shade and its shadow come from its colour.
///
/// [elevation] is 1 for a raised part (a key, a group of rows, a card), 2
/// for one floating over the page (a dialog, a menu), 0 for one resting
/// flat on the ground (a part turned off), and -1 for a well pressed into
/// the ground (a field, a groove).
///
/// ```dart
/// ClayFace.raised(ClayTheme.of(context).colors, radius: ClayRadius.large)
/// ```
@immutable
class ClayFace with Diagnosticable {
  /// A face given value by value.
  const ClayFace({
    required this.color,
    required this.shade,
    required this.light,
    this.radius = ClayRadius.control,
    this.elevation = 1,
    this.press = 0,
    this.lift = 0,
    this.focus = 0,
    this.focusColor = const Color(0x00000000),
    this.focusInset = 1,
    this.lightOpacity = 0.8,
    this.shadeOpacity = 0.3,
    this.shadowOpacity = 0.32,
  });

  /// A raised volume of [color] (neutral clay when null).
  factory ClayFace.raised(
    ClayColors colors, {
    Color? color,
    double radius = ClayRadius.control,
  }) {
    final fill = color ?? colors.clay;
    final night = colors.brightness == Brightness.dark;
    return ClayFace(
      color: fill,
      shade: colors.shadeOf(fill),
      light: colors.light,
      radius: radius,
      focusColor: _rimFor(colors, fill),
      focusInset: _rimInset(colors, fill),
      lightOpacity: night ? 0.16 : 0.85,
      shadeOpacity: night ? 0.55 : (fill == colors.clay ? 0.20 : 0.32),
      shadowOpacity: night ? 0.62 : (fill == colors.clay ? 0.26 : 0.34),
    );
  }

  /// A volume floating over the page: a dialog, a sheet, a menu.
  factory ClayFace.floating(
    ClayColors colors, {
    Color? color,
    double radius = ClayRadius.extraLarge,
  }) => ClayFace.raised(
    colors,
    color: color,
    radius: radius,
  ).copyWith(elevation: 2);

  /// A well pressed into the ground: a field, a groove, a track.
  factory ClayFace.well(
    ClayColors colors, {
    Color? color,
    double radius = ClayRadius.control,
  }) {
    final night = colors.brightness == Brightness.dark;
    final fill = color ?? colors.well;
    return ClayFace(
      color: fill,
      shade: color == null ? colors.groundShade : colors.shadeOf(fill),
      light: colors.light,
      radius: radius,
      elevation: -1,
      focusColor: colors.focus,
      lightOpacity: night ? 0.06 : 0.75,
      shadeOpacity: night ? 0.75 : 0.22,
      shadowOpacity: 0,
    );
  }

  /// Clay resting flat on the ground: a raised part turned off.
  factory ClayFace.flat(
    ClayColors colors, {
    Color? color,
    double radius = ClayRadius.control,
  }) => ClayFace.raised(
    colors,
    color: color,
    radius: radius,
  ).copyWith(elevation: 0.25);

  /// The clay's colour.
  final Color color;

  /// Its shade: the inner shade and the drop shadow, in its own hue.
  final Color shade;

  /// The light it catches.
  final Color light;

  /// Its corner radius; half its shorter side or more makes a stadium or a
  /// circle.
  final double radius;

  /// How far it stands from the ground: -1 a well, 0 flat, 1 raised, 2
  /// floating; any value between.
  final double elevation;

  /// How far a press has squashed it into the ground, 0 to 1.
  final double press;

  /// How far it has risen toward the pointer, 0 to 1.
  final double lift;

  /// How far keyboard focus has come on, 0 to 1: the part rises a little and
  /// its rim takes [focusColor].
  final double focus;

  /// The rim a focused part takes.
  final Color focusColor;

  /// How far inside its edge the rim runs, in logical pixels: 1, or 3 where
  /// the rim is the fill's own ink, so a band of the fill stands round it
  /// and it reads on any ground.
  final double focusInset;

  /// How strong its inner light is, 0 to 1.
  final double lightOpacity;

  /// How strong its inner shade is, 0 to 1.
  final double shadeOpacity;

  /// How strong its drop shadow is, 0 to 1.
  final double shadowOpacity;

  /// How far, in logical pixels, a press or a lift moves the face.
  double get travel => elevation > 0 ? 1.5 * press - 1.0 * (lift + focus) : 0;

  /// A copy with the given values changed.
  ClayFace copyWith({
    Color? color,
    Color? shade,
    Color? light,
    double? radius,
    double? elevation,
    double? press,
    double? lift,
    double? focus,
    Color? focusColor,
    double? focusInset,
    double? lightOpacity,
    double? shadeOpacity,
    double? shadowOpacity,
  }) => ClayFace(
    color: color ?? this.color,
    shade: shade ?? this.shade,
    light: light ?? this.light,
    radius: radius ?? this.radius,
    elevation: elevation ?? this.elevation,
    press: press ?? this.press,
    lift: lift ?? this.lift,
    focus: focus ?? this.focus,
    focusColor: focusColor ?? this.focusColor,
    focusInset: focusInset ?? this.focusInset,
    lightOpacity: lightOpacity ?? this.lightOpacity,
    shadeOpacity: shadeOpacity ?? this.shadeOpacity,
    shadowOpacity: shadowOpacity ?? this.shadowOpacity,
  );

  /// This face moulded in [color] instead, its shade following ([colors]
  /// derive it).
  ClayFace tinted(ClayColors colors, Color color) => copyWith(
    color: color,
    shade: colors.shadeOf(color),
    focusColor: _rimFor(colors, color),
    focusInset: _rimInset(colors, color),
  );

  /// Between [a] and [b].
  static ClayFace lerp(ClayFace a, ClayFace b, double t) {
    if (identical(a, b)) return a;
    double l(double x, double y) => lerpDouble(x, y, t)!;
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    return ClayFace(
      color: c(a.color, b.color),
      shade: c(a.shade, b.shade),
      light: c(a.light, b.light),
      radius: l(a.radius, b.radius),
      elevation: l(a.elevation, b.elevation),
      press: l(a.press, b.press),
      lift: l(a.lift, b.lift),
      focus: l(a.focus, b.focus),
      focusColor: c(a.focusColor, b.focusColor),
      focusInset: l(a.focusInset, b.focusInset),
      lightOpacity: l(a.lightOpacity, b.lightOpacity),
      shadeOpacity: l(a.shadeOpacity, b.shadeOpacity),
      shadowOpacity: l(a.shadowOpacity, b.shadowOpacity),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ClayFace &&
      other.color == color &&
      other.shade == shade &&
      other.light == light &&
      other.radius == radius &&
      other.elevation == elevation &&
      other.press == press &&
      other.lift == lift &&
      other.focus == focus &&
      other.focusColor == focusColor &&
      other.focusInset == focusInset &&
      other.lightOpacity == lightOpacity &&
      other.shadeOpacity == shadeOpacity &&
      other.shadowOpacity == shadowOpacity;

  @override
  int get hashCode => Object.hash(
    color,
    shade,
    light,
    radius,
    elevation,
    press,
    lift,
    focus,
    focusColor,
    focusInset,
    lightOpacity,
    shadeOpacity,
    shadowOpacity,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('color', color))
      ..add(ColorProperty('shade', shade))
      ..add(DoubleProperty('radius', radius))
      ..add(DoubleProperty('elevation', elevation))
      ..add(DoubleProperty('press', press, defaultValue: 0.0))
      ..add(DoubleProperty('lift', lift, defaultValue: 0.0))
      ..add(DoubleProperty('focus', focus, defaultValue: 0.0));
  }
}

/// The corner radius a part takes from a style's `shape` slot: a rounded
/// superellipse's, a rounded rectangle's or a continuous rectangle's top
/// corner, a pill for a stadium or a circle, else [fallback]. Clay's own
/// outline is always a rounded superellipse; a shape gives it its radius.
///
/// ```dart
/// clayRadiusOf(const StadiumBorder(), ClayRadius.control)
/// ```
double clayRadiusOf(OutlinedBorder? shape, double fallback) {
  BorderRadiusGeometry? corners;
  switch (shape) {
    case null:
      return fallback;
    case StadiumBorder() || CircleBorder():
      return double.infinity;
    case RoundedSuperellipseBorder(:final borderRadius):
      corners = borderRadius;
    case RoundedRectangleBorder(:final borderRadius):
      corners = borderRadius;
    case ContinuousRectangleBorder(:final borderRadius):
      // A continuous rectangle's radius bends over about twice the run.
      return borderRadius.resolve(TextDirection.ltr).topLeft.x / 2;
    default:
      return fallback;
  }
  return corners.resolve(TextDirection.ltr).topLeft.x;
}

/// The clay a chosen part is moulded in when it is not the screen's one
/// action (a chip turned on, a toggle held on): by day the clay warmed toward
/// the accent; by night the clay lifted toward the light, barely warm (a
/// night accent mixed in turns maroon, which reads as an error), 2:1 from the
/// clay beside it. The ink stands at least 6:1 on it, by day and by night.
///
/// ```dart
/// clayChosenFill(ClayTheme.of(context).colors)
/// ```
Color clayChosenFill(ClayColors colors) => colors.brightness == Brightness.dark
    ? Color.lerp(
        Color.lerp(colors.clay, colors.ink, 0.22)!,
        colors.accent,
        0.05,
      )!
    : Color.lerp(colors.clay, colors.accent, 0.24)!;

/// The rim a focused part of [fill] takes: the look's focus colour, or the
/// ink where the focus colour would not stand 3:1 from the fill.
Color _rimFor(ClayColors colors, Color fill) =>
    clayContrast(colors.focus, fill) >= 3 ? colors.focus : colors.onColor(fill);

/// How far inside the edge of a part of [fill] its rim runs: 3 px where the
/// rim is the fill's ink (beside a dark night ground a dark rim at the edge
/// would read as the edge itself), else 1.
double _rimInset(ClayColors colors, Color fill) =>
    clayContrast(colors.focus, fill) >= 3 ? 1 : 3;

/// A volume of clay drawn as [face], holding [child] on its face. Its shadow
/// and light are painted from cached masks, so a scroll or a press never
/// blurs anything anew. The child moves with the face when it is pressed.
///
/// ```dart
/// ClaySurface(face: ClayFace.raised(ClayTheme.of(context).colors), child: const SizedBox(width: 120, height: 48))
/// ```
class ClaySurface extends StatelessWidget {
  /// [child] on a volume of [face].
  const ClaySurface({
    super.key,
    required this.face,
    this.child,
    this.clipBehavior = Clip.none,
  });

  /// The clay.
  final ClayFace face;

  /// What sits on it.
  final Widget? child;

  /// Whether [child] is cut to the clay's outline (a picture on a card).
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    Widget? content = child;
    if (content != null && clipBehavior != Clip.none) {
      content = ClipPath(
        clipper: _ShapeClip(face.radius),
        clipBehavior: clipBehavior,
        child: content,
      );
    }
    final travel = face.travel;
    if (content != null && travel != 0) {
      content = Transform.translate(offset: Offset(0, travel), child: content);
    }
    return _ClayPaint(
      painter: _ClayPainter(
        face: face,
        mirrored: Directionality.maybeOf(context) == TextDirection.rtl,
        pixelRatio: MediaQuery.maybeDevicePixelRatioOf(context) ?? 2,
      ),
      child: content,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ClayFace>('face', face));
  }
}

/// A [CustomPaint] whose render object holds the masks while it is in the
/// tree: when the last volume of clay leaves, the masks are let go.
class _ClayPaint extends CustomPaint {
  const _ClayPaint({required super.painter, super.child});

  @override
  RenderCustomPaint createRenderObject(BuildContext context) =>
      _RenderClayPaint(painter: painter);
}

class _RenderClayPaint extends RenderCustomPaint {
  _RenderClayPaint({super.painter});

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    claySpritesHold();
  }

  @override
  void detach() {
    claySpritesRelease();
    super.detach();
  }
}

class _ShapeClip extends CustomClipper<Path> {
  const _ShapeClip(this.radius);

  final double radius;

  @override
  Path getClip(Size size) {
    final path = Path();
    clayAddShape(path, Offset.zero & size, radius);
    return path;
  }

  @override
  bool shouldReclip(_ShapeClip old) => old.radius != radius;
}

/// The size scale of a part's shading: a small part casts a smaller, tighter
/// shadow than a big one.
double _scaleFor(Size size) =>
    ((math.min(size.width, size.height) / 48).clamp(0.5, 1.5) * 4)
        .roundToDouble() /
    4;

class _ClayPainter extends CustomPainter {
  _ClayPainter({
    required this.face,
    required this.mirrored,
    required this.pixelRatio,
  });

  final ClayFace face;
  final bool mirrored;
  final double pixelRatio;

  // A shadow at each whole level: (how far down, how soft, how strong).
  // It falls half its softness below the face, and is never softer than a
  // sixth of the face's short side: past that a small ball's shadow
  // spreads out as a square's would behind its round corners.
  static (double, double, double) _level(int level, double k, double side) {
    final (soft, strength) = switch (level) {
      0 => (2.0 * k, 0.55),
      1 => (9.0 * k, 1.0),
      _ => (16.0 * k, 1.0),
    };
    final blur = math.min(soft, math.max(2.0, side / 6));
    return (blur / 2, blur, strength);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final f = face;
    final whole = Offset.zero & size;
    final k = _scaleFor(size);
    final rect = whole.translate(0, f.travel);
    final radius = math.min(f.radius, math.min(size.width, size.height) / 2);
    if (f.elevation > 0 && f.shadowOpacity > 0) {
      // The shadow between its two nearest levels, cross-faded: a press
      // tightens it smoothly from two cached masks.
      final e = (f.elevation + 0.2 * (f.lift + f.focus) - 1.0 * f.press).clamp(
        0.0,
        2.0,
      );
      final low = math.min(e.floor(), 1);
      final t = e - low;
      for (final (level, weight) in [(low, 1 - t), (low + 1, t)]) {
        if (weight <= 0.001) continue;
        final (down, blur, strength) = _level(
          level,
          k,
          math.min(size.width, size.height),
        );
        clayPaintSprite(
          canvas,
          kind: ClaySpriteKind.drop,
          rect: whole,
          radius: radius,
          blur: blur,
          offset: down,
          color: f.shade.withValues(
            alpha: f.shade.a * f.shadowOpacity * strength * weight,
          ),
          pixelRatio: pixelRatio,
        );
      }
    }
    clayDrawShape(canvas, rect, radius, Paint()..color = f.color);
    final inner = (math.min(size.width, size.height) * 0.09).clamp(2.0, 8.0);
    final raised = f.elevation >= 0;
    final lightAlpha =
        f.lightOpacity * (raised ? 1 - 0.6 * f.press : 1) * f.light.a;
    final shadeAlpha =
        math.min(1.0, f.shadeOpacity * (raised ? 1 + 0.6 * f.press : 1)) *
        f.shade.a;
    canvas.save();
    clayClipShape(canvas, rect, radius);
    clayPaintSprite(
      canvas,
      kind: raised ? ClaySpriteKind.insetStart : ClaySpriteKind.insetEnd,
      rect: rect,
      radius: radius,
      blur: inner * 1.1,
      offset: inner,
      color: f.light.withValues(alpha: lightAlpha),
      pixelRatio: pixelRatio,
      mirrored: mirrored,
    );
    clayPaintSprite(
      canvas,
      kind: raised ? ClaySpriteKind.insetEnd : ClaySpriteKind.insetStart,
      rect: rect,
      radius: radius,
      blur: inner * (raised ? 1.25 : 0.9),
      offset: inner * (raised ? 1.1 : 0.8),
      color: f.shade.withValues(alpha: shadeAlpha),
      pixelRatio: pixelRatio,
      mirrored: mirrored,
    );
    if (raised && f.press > 0.001) {
      // Pressed, the clay dents: a shade comes up inside its top-leading
      // edge, where the light was.
      clayPaintSprite(
        canvas,
        kind: ClaySpriteKind.insetStart,
        rect: rect,
        radius: radius,
        blur: inner * 1.1,
        offset: inner * 0.8,
        color: f.shade.withValues(
          alpha: f.shade.a * f.shadeOpacity * 0.6 * f.press,
        ),
        pixelRatio: pixelRatio,
        mirrored: mirrored,
      );
    }
    canvas.restore();
    if (f.focus > 0.001 && f.focusColor.a > 0) {
      // The focused part's rim: a band of the focus colour 2 px wide just
      // inside its edge, concentric with it.
      clayDrawShape(
        canvas,
        rect.deflate(f.focusInset),
        math.max(0, radius - f.focusInset),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = f.focusColor.withValues(alpha: f.focusColor.a * f.focus),
      );
    }
  }

  @override
  bool shouldRepaint(_ClayPainter old) =>
      old.face != face ||
      old.mirrored != mirrored ||
      old.pixelRatio != pixelRatio;
}

/// A [ClaySurface] that moves to each new [face] on Clay's press spring: a
/// press squashes it in, a release lets it back, focus brings its rim up,
/// a new colour flows in. Under Reduce Motion it changes in a short fade.
///
/// ```dart
/// AnimatedClaySurface(face: ClayFace.raised(ClayTheme.of(context).colors), child: const SizedBox(width: 48, height: 48))
/// ```
class AnimatedClaySurface extends StatefulWidget {
  /// [child] on a volume moving to [face].
  const AnimatedClaySurface({
    super.key,
    required this.face,
    this.child,
    this.clipBehavior = Clip.none,
    this.stiffness = ClayMotion.pressStiffness,
  });

  /// The clay to arrive at.
  final ClayFace face;

  /// What sits on it.
  final Widget? child;

  /// Whether [child] is cut to the clay's outline.
  final Clip clipBehavior;

  /// The spring's stiffness (critically damped: it arrives and stops).
  final double stiffness;

  @override
  State<AnimatedClaySurface> createState() => _AnimatedClaySurfaceState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ClayFace>('face', face));
  }
}

class _AnimatedClaySurfaceState extends State<AnimatedClaySurface>
    with SingleTickerProviderStateMixin {
  late ClayFace _from = widget.face;
  late final AnimationController _t = AnimationController(
    vsync: this,
    value: 1,
  );

  ClayFace get _now =>
      _t.value >= 1 ? widget.face : ClayFace.lerp(_from, widget.face, _t.value);

  @override
  void didUpdateWidget(AnimatedClaySurface old) {
    super.didUpdateWidget(old);
    if (old.face == widget.face) return;
    _from = ClayFace.lerp(_from, old.face, _t.value);
    _t.value = 0;
    final policy = RawMotionPolicy.of(context);
    _t.springTo(
      1,
      policy.reduceMotion
          ? policy.effects(dampingRatio: 1, stiffness: widget.stiffness)
          : policy.spatial(dampingRatio: 1, stiffness: widget.stiffness),
    );
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    child: widget.child,
    builder: (context, child) => ClaySurface(
      face: _now,
      clipBehavior: widget.clipBehavior,
      child: child,
    ),
  );
}

/// A well pressed into the ground holding [child]: what a field, a search, a
/// groove and a track are made of.
///
/// ```dart
/// const ClayWell(child: SizedBox(height: 48))
/// ```
class ClayWell extends StatelessWidget {
  /// [child] in a well with corners of [radius].
  const ClayWell({super.key, this.radius = ClayRadius.control, this.child});

  /// The well's corner radius.
  final double radius;

  /// What sits in it.
  final Widget? child;

  @override
  Widget build(BuildContext context) => ClaySurface(
    face: ClayFace.well(ClayTheme.of(context).colors, radius: radius),
    child: child,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('radius', radius));
  }
}
