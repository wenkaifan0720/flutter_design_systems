/// Gloss's material: glazed faces moulded raised, level or sunken under one
/// light from the top, the grained chrome bar, letterpressed words and the
/// engraved line. Every Gloss part is drawn with [GlossSurface]; a part that
/// changes with its states draws [AnimatedGlossSurface], which moves from
/// one [GlossFace] to the next on a spring.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'theme.dart';

const Color _clear = Color(0x00000000);

/// How a glazed face looks at one moment: what [GlossSurface] paints and
/// what [AnimatedGlossSurface] moves between.
///
/// Its [lift] says how it is moulded: 1 raised (a key, a bead: a drop shadow
/// below, a specular [lens] on its upper part), 0 level (a panel), -1 sunken
/// (a well, a slot: the rim's shade along its top, a light [lip] along its
/// foot). [travel] is how far a raised face is pressed home.
@immutable
class GlossFace with Diagnosticable {
  /// A face glazed [top] to [bottom] through [middle].
  const GlossFace({
    required this.top,
    required this.middle,
    required this.bottom,
    required this.foreground,
    this.edge = _clear,
    this.glow = _clear,
    this.shade = const Color(0xFF14283C),
    this.lip = _clear,
    this.lens = 0,
    this.lift = 0,
    this.travel = 0,
    this.focus = _clear,
    this.radius,
    this.corners,
  }) : assert(lift >= -1 && lift <= 1),
       assert(travel >= 0 && travel <= 1),
       assert(lens >= 0 && lens <= 1);

  /// The jade gel key in [colors]: raised, glossy, lit from inside.
  factory GlossFace.gel(GlossColors colors, {double? radius}) => GlossFace(
    top: colors.jadeTop,
    middle: colors.jade,
    bottom: colors.jadeBottom,
    foreground: colors.onJade,
    edge: colors.jadeEdge,
    glow: colors.jadeGlow,
    shade: colors.shadow,
    lens: 0.62,
    lift: 1,
    radius: radius,
  );

  /// The ruby gel of a destructive confirm in [colors].
  factory GlossFace.ruby(GlossColors colors, {double? radius}) => GlossFace(
    top: colors.dangerTop,
    middle: colors.dangerFill,
    bottom: colors.dangerBottom,
    foreground: colors.onDanger,
    edge: colors.dangerEdge,
    glow: const Color(0x66FFB4B8),
    shade: colors.shadow,
    lens: 0.55,
    lift: 1,
    radius: radius,
  );

  /// A pearl key or bead in [colors]: raised, white-glazed.
  factory GlossFace.pearl(GlossColors colors, {double? radius}) => GlossFace(
    top: colors.pearlTop,
    middle: Color.lerp(colors.pearlTop, colors.pearlBottom, 0.45)!,
    bottom: colors.pearlBottom,
    foreground: colors.ink,
    edge: colors.pearlEdge,
    // By night no band of light across its crown (on a dark bead it reads
    // as a bevel): its lustre is the soft cool light in its foot and the
    // fall of its glaze from crown to foot.
    glow: colors.brightness == Brightness.light
        ? const Color(0xB3FFFFFF)
        : const Color(0x26DCE8F5),
    shade: colors.shadow,
    lens: colors.brightness == Brightness.light ? 0.9 : 0,
    lift: 1,
    radius: radius,
  );

  /// A pearl part that is off in [colors]: lower, its words clouded, no
  /// band of light; by night sunk halfway to the page, so it never reads as
  /// a grey twin of a lit pearl.
  factory GlossFace.pearlOff(GlossColors colors, {double? radius}) {
    final day = colors.brightness == Brightness.light;
    final pearl = GlossFace.pearl(colors, radius: radius);
    Color dim(Color v) => day ? v : Color.lerp(v, colors.page, 0.5)!;
    return pearl.copyWith(
      top: dim(pearl.top),
      middle: dim(pearl.middle),
      bottom: dim(pearl.bottom),
      foreground: colors.inkDisabled,
      lens: day ? 0.25 : 0,
      lift: 0.3,
    );
  }

  /// A well pressed into the porcelain in [colors]: a field, a group's
  /// floor, a slot, a socket.
  factory GlossFace.well(GlossColors colors, {double? radius}) => GlossFace(
    // A floor below the page: in the rim's shadow at the top, catching a
    // little of the light toward its foot.
    top: Color.lerp(colors.well, colors.shadow, 0.035)!,
    middle: colors.well,
    bottom: Color.lerp(colors.well, colors.page, 0.4)!,
    foreground: colors.ink,
    shade: colors.wellShade,
    lip: colors.lip,
    lift: -1,
    radius: radius,
  );

  /// A level porcelain tile in [colors]: a card, a panel. A glazed rim and a
  /// soft shadow under it, a light line along its top.
  factory GlossFace.porcelain(GlossColors colors, {double? radius}) {
    final light = colors.brightness == Brightness.light;
    final face = light ? const Color(0xFFF8F9FA) : const Color(0xFF2A2F35);
    return GlossFace(
      top: light ? const Color(0xFFFFFFFF) : const Color(0xFF30363C),
      middle: face,
      bottom: face,
      foreground: colors.ink,
      edge: light ? const Color(0x24283C50) : const Color(0x99000000),
      shade: colors.shadow,
      lip: light ? const Color(0xFFFFFFFF) : const Color(0x1AFFFFFF),
      lift: 0.35,
      radius: radius,
    );
  }

  /// The glaze at the top edge.
  final Color top;

  /// The glaze at the middle, where words sit.
  final Color middle;

  /// The glaze at the foot.
  final Color bottom;

  /// The words and glyphs on the face.
  final Color foreground;

  /// The rim round the glaze. Clear for a part with none.
  final Color edge;

  /// The light glowing up from the foot inside the glaze.
  final Color glow;

  /// The colour of the shadow it casts (raised) or its rim casts on it
  /// (sunken).
  final Color shade;

  /// The light caught along a sunken face's lower rim, or along a level
  /// face's top.
  final Color lip;

  /// The specular lens's strength on a raised face, 0 to 1.
  final double lens;

  /// How it is moulded: 1 raised, 0 level, -1 sunken.
  final double lift;

  /// How far a raised face is pressed home, 0 to 1.
  final double travel;

  /// The reflected light on this glaze. Its alpha sets the strength.
  /// Use [glossGlazeOf] for the current interaction states.
  final Color focus;

  /// The corner radius; null for a capsule or a circle (half the short side).
  final double? radius;

  /// Each corner's own radius, over [radius]: a key moulded as one half of
  /// a pair (a split key), round on its outer side only.
  final BorderRadius? corners;

  /// A copy with the given fields replaced.
  GlossFace copyWith({
    Color? top,
    Color? middle,
    Color? bottom,
    Color? foreground,
    Color? edge,
    Color? glow,
    Color? shade,
    Color? lip,
    double? lens,
    double? lift,
    double? travel,
    Color? focus,
    double? radius,
    BorderRadius? corners,
  }) => GlossFace(
    top: top ?? this.top,
    middle: middle ?? this.middle,
    bottom: bottom ?? this.bottom,
    foreground: foreground ?? this.foreground,
    edge: edge ?? this.edge,
    glow: glow ?? this.glow,
    shade: shade ?? this.shade,
    lip: lip ?? this.lip,
    lens: lens ?? this.lens,
    lift: lift ?? this.lift,
    travel: travel ?? this.travel,
    focus: focus ?? this.focus,
    radius: radius ?? this.radius,
    corners: corners ?? this.corners,
  );

  /// This face glazed all over in [fill] (a part's `style.fill`), keeping
  /// its light: the top a little lighter, the foot a little darker.
  GlossFace glazed(Color fill) {
    final hsl = HSLColor.fromColor(fill);
    Color by(double d) =>
        hsl.withLightness((hsl.lightness + d).clamp(0.0, 1.0)).toColor();
    return copyWith(top: by(0.07), middle: fill, bottom: by(-0.06));
  }

  /// Between [a] and [b] at [t].
  static GlossFace lerp(GlossFace a, GlossFace b, double t) {
    if (identical(a, b)) return a;
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    double d(double x, double y) => x + (y - x) * t;
    return GlossFace(
      top: c(a.top, b.top),
      middle: c(a.middle, b.middle),
      bottom: c(a.bottom, b.bottom),
      foreground: c(a.foreground, b.foreground),
      edge: c(a.edge, b.edge),
      glow: c(a.glow, b.glow),
      shade: c(a.shade, b.shade),
      lip: c(a.lip, b.lip),
      lens: d(a.lens, b.lens).clamp(0.0, 1.0),
      lift: d(a.lift, b.lift).clamp(-1.0, 1.0),
      travel: d(a.travel, b.travel).clamp(0.0, 1.0),
      focus: c(a.focus, b.focus),
      radius: a.radius == null || b.radius == null
          ? (t < 0.5 ? a.radius : b.radius)
          : d(a.radius!, b.radius!),
      corners: BorderRadius.lerp(a.corners, b.corners, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GlossFace &&
      other.top == top &&
      other.middle == middle &&
      other.bottom == bottom &&
      other.foreground == foreground &&
      other.edge == edge &&
      other.glow == glow &&
      other.shade == shade &&
      other.lip == lip &&
      other.lens == lens &&
      other.lift == lift &&
      other.travel == travel &&
      other.focus == focus &&
      other.radius == radius &&
      other.corners == corners;

  @override
  int get hashCode => Object.hash(
    top,
    middle,
    bottom,
    foreground,
    edge,
    glow,
    shade,
    lip,
    lens,
    lift,
    travel,
    focus,
    radius,
    corners,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('top', top))
      ..add(ColorProperty('middle', middle))
      ..add(ColorProperty('bottom', bottom))
      ..add(ColorProperty('foreground', foreground))
      ..add(ColorProperty('edge', edge))
      ..add(ColorProperty('glow', glow))
      ..add(DoubleProperty('lens', lens))
      ..add(DoubleProperty('lift', lift))
      ..add(DoubleProperty('travel', travel))
      ..add(ColorProperty('focus', focus))
      ..add(DoubleProperty('radius', radius, defaultValue: null))
      ..add(
        DiagnosticsProperty<BorderRadius>(
          'corners',
          corners,
          defaultValue: null,
        ),
      );
  }
}

/// Paints [face] round [child]: its drop shadow (raised) or the rim's shade
/// along its top (sunken), the rim, the glaze, the glow and the specular
/// lens. A focused face catches a sharper reflection inside its glaze.
///
/// Leave 4 px below a raised face for its cast shadow.
///
/// ```dart
/// GlossSurface(face: GlossFace.pearl(colors), child: const Padding(padding: EdgeInsets.all(12), child: Text('Pearl')))
/// ```
class GlossSurface extends StatelessWidget {
  /// [child] on [face].
  const GlossSurface({super.key, required this.face, this.child});

  /// How it looks.
  final GlossFace face;

  /// What stands on the face.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final travel = face.lift > 0 ? face.travel * GlossMetrics.keyTravel : 0.0;
    final highContrast = MediaQuery.maybeHighContrastOf(context) ?? false;
    return CustomPaint(
      painter: _FacePainter(
        face,
        GlossTheme.of(context).colors.brightness,
        highContrast: highContrast,
      ),
      child: Transform.translate(
        offset: Offset(0, travel),
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
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<GlossFace>('face', face));
  }
}

/// The outline of a face laid in [rect]: its rounded rectangle of [radius],
/// or a capsule when [radius] is null.
RRect glossOutline(Rect rect, double? radius) => RRect.fromRectAndRadius(
  rect,
  Radius.circular(
    math.min(radius ?? rect.shortestSide / 2, rect.shortestSide / 2),
  ),
);

class _FacePainter extends CustomPainter {
  _FacePainter(this.face, this.brightness, {required this.highContrast});

  final Brightness brightness;

  final GlossFace face;
  final bool highContrast;

  @override
  void paint(Canvas canvas, Size size) {
    paintGlossFace(
      canvas,
      Offset.zero & size,
      face,
      brightness: brightness,
      highContrast: highContrast,
    );
  }

  @override
  bool shouldRepaint(_FacePainter old) =>
      old.face != face ||
      old.brightness != brightness ||
      old.highContrast != highContrast;
}

/// Paints [face] in [rect] on [canvas]: what [GlossSurface] draws, for a
/// painter of one's own (a slider's groove, a switch's slot).
void paintGlossFace(
  Canvas canvas,
  Rect rect,
  GlossFace face, {
  Brightness brightness = Brightness.light,
  bool highContrast = false,
}) {
  final raise = math.max(0.0, face.lift);
  final sink = math.max(0.0, -face.lift);
  final dy = raise > 0 ? face.travel * GlossMetrics.keyTravel : 0.0;
  final shifted = rect.shift(Offset(0, dy));
  final outer =
      face.corners?.toRRect(shifted) ?? glossOutline(shifted, face.radius);

  // The shadow a raised face casts below it: a contact shadow and a soft
  // ambient one, both shrinking as it is pressed home.
  final cast = raise * (1 - 0.7 * face.travel);
  if (cast > 0.01 && face.shade.a > 0) {
    canvas
      ..drawRRect(
        outer.shift(Offset(0, 1 * cast)),
        Paint()
          ..color = face.shade.withValues(alpha: 0.24 * cast)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8),
      )
      ..drawRRect(
        outer.shift(Offset(0, 2.5 * cast)),
        Paint()
          ..color = face.shade.withValues(alpha: 0.16 * cast)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
  }

  // The light caught along a sunken face's lower rim.
  if (sink > 0 && face.lip.a > 0) {
    canvas.drawRRect(
      outer.shift(const Offset(0, 1)),
      Paint()..color = face.lip.withValues(alpha: face.lip.a * sink),
    );
  }

  // The rim.
  final rimmed = face.edge.a > 0 || (highContrast && sink > 0);
  final inner = rimmed ? outer.deflate(1) : outer;
  if (rimmed) {
    final rim = Paint()
      ..color = highContrast
          ? face.foreground.withValues(alpha: 0.75)
          : face.edge;
    // Under a clear glaze (a lens) the rim is a ring, one even-odd path
    // (never a combined difference, which the web fills whole): a filled
    // rim would show through the glass as a slab over what it covers.
    if (face.top.a < 1 || face.middle.a < 1 || face.bottom.a < 1) {
      canvas.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRRect(outer)
          ..addRRect(inner),
        rim,
      );
    } else {
      canvas.drawRRect(outer, rim);
    }
  }

  final light = face.focus.a;
  final day = brightness == Brightness.light;
  // White porcelain and neutral plastic keep their body colour in daylight.
  // Only a coloured pigment deepens as its reflection comes into focus.
  final deepen = light == 0
      ? 0.0
      : day
      ? (_hasPigment(face.middle) ? 0.075 : 0.0)
      : (sink > 0 ? 0.095 : 0.135);
  Color glaze(Color pigment) => deepen == 0
      ? pigment
      : Color.lerp(
          pigment,
          const Color(0xFF000000).withValues(alpha: pigment.a),
          light * deepen,
        )!;

  // The glaze.
  canvas.drawRRect(
    inner,
    Paint()
      ..shader = ui.Gradient.linear(
        inner.outerRect.topCenter,
        inner.outerRect.bottomCenter,
        [glaze(face.top), glaze(face.middle), glaze(face.bottom)],
        const [0, 0.55, 1],
      ),
  );

  // The light glowing up from inside the glaze's foot.
  if (face.glow.a > 0 && !highContrast) {
    canvas.drawRRect(
      inner,
      Paint()
        ..shader = ui.Gradient.linear(
          inner.outerRect.topCenter,
          inner.outerRect.bottomCenter,
          [
            face.glow.withValues(alpha: 0),
            face.glow.withValues(alpha: 0),
            face.glow,
          ],
          const [0, 0.58, 1],
        ),
    );
  }

  // A sunken face: the rim's shade along its top, and a fine shade all
  // round its edge. A pressed raised face takes a little of it too.
  final shaded = math.max(sink, raise * face.travel * 0.45);
  if (shaded > 0.01 && face.shade.a > 0) {
    canvas
      ..save()
      ..clipRRect(inner);
    final shade = face.shade.withValues(alpha: face.shade.a * shaded);
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(inner.outerRect.inflate(12))
        ..addRRect(inner.shift(Offset(0, 2.2 * shaded))),
      Paint()
        ..color = shade
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
    );
    if (sink > 0) {
      canvas.drawRRect(
        inner.deflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = face.shade.withValues(alpha: face.shade.a * 0.55 * sink),
      );
    }
    canvas.restore();
  }

  // A sunken face is glazed: the top light mirrored in the glaze just under
  // the rim's shade, a crisp band ending well above a row's words, and the
  // light caught where the glaze curves up into the lower rim.
  if (sink > 0.01 && face.lip.a > 0 && !highContrast) {
    final box = inner.outerRect;
    final sheen = (0.03 + 0.4 * face.lip.a) * sink;
    // The band follows the rim: clipped to the face 2 px in, its ends are
    // the corners' own curves, not a pill of its own floating in the well.
    final band = Rect.fromLTWH(
      box.left,
      box.top + 2,
      box.width,
      math.min(11, box.height * 0.22),
    );
    canvas
      ..save()
      ..clipRRect(inner)
      ..save()
      ..clipRRect(inner.deflate(2))
      ..drawRect(
        band,
        Paint()
          ..shader = ui.Gradient.linear(
            band.topCenter,
            band.bottomCenter,
            [
              Color.fromRGBO(255, 255, 255, sheen),
              Color.fromRGBO(255, 255, 255, sheen * 0.35),
              const Color(0x00FFFFFF),
            ],
            const [0, 0.45, 1],
          ),
      )
      ..restore()
      ..drawRRect(
        inner.deflate(0.75),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..shader = ui.Gradient.linear(
            box.topCenter,
            box.bottomCenter,
            [
              const Color(0x00FFFFFF),
              const Color(0x00FFFFFF),
              Color.fromRGBO(255, 255, 255, sheen * 1.3),
            ],
            [0, (1 - 10 / math.max(box.height, 20)).clamp(0.0, 1.0), 1],
          ),
      )
      ..restore();
  }

  // A level face's light along its top.
  if (raise > 0 && raise <= 0.7 && face.lip.a > 0) {
    canvas
      ..save()
      ..clipRRect(inner)
      ..drawRRect(
        inner.shift(const Offset(0, 1)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..shader = ui.Gradient.linear(
            inner.outerRect.topCenter,
            inner.outerRect.topCenter + const Offset(0, 6),
            [face.lip, face.lip.withValues(alpha: 0)],
          ),
      )
      ..restore();
  }

  // The specular lens on a raised face's upper part: it ends above a
  // centred label's capitals, and dims as the face is pressed.
  final lens =
      math.min(1.0, face.lens * (1 + 0.35 * light)) *
      (1 - 0.55 * face.travel) *
      (highContrast ? 0 : 1);
  // A face too small for its rim (a part laid out at nothing, a dot) has no
  // room for a lens.
  if (lens > 0.01 && inner.outerRect.width > 4 && inner.outerRect.height > 4) {
    final box = inner.outerRect;
    final r = inner.tlRadiusX;
    final inset = math.min(3.0, box.width * 0.08);
    final height =
        box.height *
        GlossMetrics.lensFraction *
        (1 - 0.34 * light) *
        (1 - 0.18 * face.travel);
    final lensRect = Rect.fromLTWH(
      box.left + inset,
      box.top + 1 + face.travel,
      box.width - inset * 2,
      height,
    );
    final top = Radius.circular(math.max(0, math.min(r - inset * 0.6, height)));
    final foot = Radius.elliptical(
      math.min(lensRect.width / 2, math.max(r, lensRect.width * 0.18)),
      height * 0.5,
    );
    // The lens lies on the face: held to its outline, so a round face's
    // lens never shows past its shoulders.
    canvas
      ..save()
      ..clipRRect(inner);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        lensRect,
        topLeft: top,
        topRight: top,
        bottomLeft: foot,
        bottomRight: foot,
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          lensRect.topCenter,
          lensRect.bottomCenter,
          [
            Color.fromRGBO(255, 255, 255, 0.95 * lens),
            Color.fromRGBO(255, 255, 255, 0.28 * lens),
            const Color(0x00FFFFFF),
          ],
          const [0, 0.6, 1],
        ),
    );
    canvas.restore();
  }

  if (light > 0) {
    // Clear slots have no pigment of their own to deepen.
    if (!day && face.middle.a < 1) {
      _shadeGlaze(canvas, inner, face.focus, (1 - face.middle.a) * light);
    }
    _paintReflection(
      canvas,
      inner,
      light,
      pale: day && deepen == 0,
      inset: sink > 0.5,
      pressure: face.travel,
    );
  }
}

bool _hasPigment(Color color) {
  final chroma =
      math.max(color.r, math.max(color.g, color.b)) -
      math.min(color.r, math.min(color.g, color.b));
  return chroma > 0.18 && color.computeLuminance() < 0.72;
}

// A reflection of a broad light above and to the left. On a convex face
// the light meets the crown. In a recess it meets the lower inside bevel.
void _paintReflection(
  Canvas canvas,
  RRect shape,
  double light, {
  bool inset = false,
  bool pale = false,
  double pressure = 0,
}) {
  final box = shape.outerRect;
  if (light <= 0 || box.shortestSide < 3) return;
  final thickness = math.min(box.height * 0.12, inset ? 2.5 : 3.5);
  final inner = shape.deflate(math.min(1.4, box.shortestSide * 0.07));
  final rim = inner.outerRect;
  final top = inset
      ? rim.bottom - thickness - 0.4 - pressure
      : rim.top + 0.45 + 1.8 * pressure;
  final band = Rect.fromLTWH(rim.left, top, rim.width, thickness);
  // Glancing light tapers away across the part instead of tracing its edge.
  final highlight = Path()
    ..moveTo(band.left, band.center.dy)
    ..quadraticBezierTo(
      band.left + rim.width * 0.28,
      band.top - 0.4,
      band.left + rim.width * 0.83,
      band.top + thickness * 0.46,
    )
    ..quadraticBezierTo(
      band.left + rim.width * 0.38,
      band.bottom + 0.8,
      band.left,
      band.bottom,
    )
    ..close();
  canvas
    ..save()
    ..clipRRect(inner);
  if (pale) {
    // On white, the cool edge of the reflection makes the white streak legible.
    canvas.drawPath(
      highlight.shift(Offset(0, inset ? -0.9 : 0.9)),
      Paint()
        ..shader = ui.Gradient.linear(
          band.centerLeft,
          band.centerRight,
          [
            Color.fromRGBO(90, 113, 128, 0.29 * light),
            Color.fromRGBO(90, 113, 128, 0.35 * light),
            const Color(0x005A7180),
          ],
          const [0, 0.25, 0.88],
        ),
    );
  }
  canvas
    ..drawPath(
      highlight,
      Paint()
        ..shader = ui.Gradient.linear(
          band.centerLeft,
          band.centerRight,
          [
            Color.fromRGBO(255, 255, 255, 0.5 * light),
            Color.fromRGBO(255, 255, 255, 0.86 * light),
            const Color(0x00FFFFFF),
          ],
          const [0, 0.25, 0.88],
        ),
    )
    ..restore();
}

void _shadeGlaze(Canvas canvas, RRect shape, Color color, double strength) {
  final pigment = Color.lerp(
    const Color(0xFF14212E),
    color.withValues(alpha: 1),
    0.12,
  )!;
  canvas.drawRRect(
    shape,
    Paint()..color = pigment.withValues(alpha: strength * 0.12),
  );
}

/// Paints the reflection on a flat glazed part inside [shape].
/// [color] tints the glaze and its alpha determines the strength.
/// [inside] sets the reflection slightly farther into a fitted part.
void paintGlossHalo(
  Canvas canvas,
  RRect shape,
  Color color, {
  bool inside = false,
  Brightness brightness = Brightness.light,
}) {
  if (color.a <= 0 || shape.outerRect.isEmpty) return;
  final face = inside ? shape.deflate(0.5) : shape;
  final day = brightness == Brightness.light;
  if (!day) _shadeGlaze(canvas, face, color, color.a);
  _paintReflection(canvas, face, color.a, pale: day);
}

/// The reflected light on a flat part whose own surface lies behind [child].
/// The reflection fades with interaction and cuts immediately under Reduce Motion.
///
/// ```dart
/// GlossGlazeHighlight(focused: focused, child: const SizedBox(width: 96, height: 32))
/// ```
class GlossGlazeHighlight extends StatelessWidget {
  /// Reflects light within the outline of [child].
  const GlossGlazeHighlight({
    super.key,
    required this.focused,
    required this.child,
    this.hovered = false,
    this.pressed = false,
    this.radius,
    this.inset = 0,
    this.inside = false,
    this.tint = false,
    this.color,
  });

  /// Whether the part has keyboard focus.
  final bool focused;

  /// Whether the pointer is over the part.
  final bool hovered;

  /// Whether the part is held down.
  final bool pressed;

  /// The content on the glaze.
  final Widget child;

  /// The corners of the glaze. A null radius gives a capsule.
  final double? radius;

  /// An inset from the edges of the box. Negative values use the full box.
  final double inset;

  /// Whether the reflection sits slightly deeper inside a fitted part.
  final bool inside;

  /// Whether to give a surface behind plain text a little more pigment.
  final bool tint;

  /// The tint of the underlying glaze. Defaults to [GlossColors.focus].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final amount = _glazeStrength(focused, hovered, pressed);
    final colors = GlossTheme.of(context).colors;
    final pigment = color ?? colors.focus;
    final target = Offset(amount, pressed ? 1 : 0);
    Widget paint(Offset value, Widget? content) => CustomPaint(
      painter: _GlazePainter(
        value,
        pigment,
        colors.brightness,
        radius,
        inset,
        inside,
        tint,
      ),
      child: content,
    );
    if (DesignMotionPolicy.of(context).reduceMotion) {
      return paint(target, child);
    }
    return TweenAnimationBuilder<Offset>(
      tween: Tween(end: target),
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: child,
      builder: (context, value, content) => paint(value, content),
    );
  }
}

/// A [GlossGlazeHighlight] for a part drawn with earlier versions of Gloss.
typedef GlossFocusHalo = GlossGlazeHighlight;

class _GlazePainter extends CustomPainter {
  _GlazePainter(
    this.value,
    this.color,
    this.brightness,
    this.radius,
    this.inset,
    this.inside,
    this.tint,
  );
  final Offset value;
  final Color color;
  final Brightness brightness;
  final double? radius;
  final double inset;
  final bool inside;
  final bool tint;

  @override
  void paint(Canvas canvas, Size size) {
    final light = value.dx * color.a;
    if (light <= 0) return;
    final box = (Offset.zero & size).deflate(
      math.max(0, inset) + (inside ? 0.5 : 0),
    );
    if (box.isEmpty) return;
    final face = glossOutline(box, radius);
    final day = brightness == Brightness.light;
    if (!day) _shadeGlaze(canvas, face, color, light * (tint ? 1.18 : 1));
    _paintReflection(canvas, face, light, pale: day, pressure: value.dy);
  }

  @override
  bool shouldRepaint(_GlazePainter old) =>
      old.value != value ||
      old.brightness != brightness ||
      old.color != color ||
      old.radius != radius ||
      old.inset != inset ||
      old.inside != inside ||
      old.tint != tint;
}

/// [GlossSurface] that moves to each new [face] on a spring from wherever
/// it is: a press, a release, a focus, a latch. A press sinks on Gloss's
/// press spring and returns with a little give; a change of glaze runs
/// without overshoot. Reduce Motion shows the new face immediately.
///
/// ```dart
/// AnimatedGlossSurface(face: pressed ? resting.copyWith(travel: 1) : resting, child: const Text('Save'))
/// ```
class AnimatedGlossSurface extends StatefulWidget {
  /// [child] on a face that moves to [face].
  const AnimatedGlossSurface({super.key, required this.face, this.child});

  /// The face to arrive at.
  final GlossFace face;

  /// What stands on the face.
  final Widget? child;

  @override
  State<AnimatedGlossSurface> createState() => _AnimatedGlossSurfaceState();
}

class _AnimatedGlossSurfaceState extends State<AnimatedGlossSurface>
    with SingleTickerProviderStateMixin {
  // Unbounded: the press spring's give overshoots its end a little.
  late final AnimationController _controller = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  late GlossFace _from = widget.face;
  late GlossFace _to = widget.face;

  GlossFace get _now {
    final t = _controller.value;
    if (t >= 1 && t <= 1) return _to;
    // Glazes do not overshoot; the press's travel and lift may, a little.
    final colours = GlossFace.lerp(_from, _to, t.clamp(0.0, 1.0));
    double d(double a, double b) => a + (b - a) * t;
    return colours.copyWith(
      travel: d(_from.travel, _to.travel).clamp(0.0, 1.0),
      lift: d(_from.lift, _to.lift).clamp(-1.0, 1.0),
    );
  }

  @override
  void didUpdateWidget(AnimatedGlossSurface old) {
    super.didUpdateWidget(old);
    if (widget.face == _to) return;
    final pressChanged = widget.face.travel != _to.travel;
    _from = _now;
    _to = widget.face;
    final policy = DesignMotionPolicy.of(context);
    if (policy.reduceMotion) {
      _controller.value = 1;
      return;
    }
    _controller.value = 0;
    _controller.springTo(
      1,
      pressChanged
          ? policy.spatial(
              dampingRatio: GlossMotion.pressDamping,
              stiffness: GlossMotion.pressStiffness,
            )
          : policy.effects(
              dampingRatio: 1,
              stiffness: GlossMotion.colorStiffness,
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
    builder: (context, child) => GlossSurface(
      face: DesignMotionPolicy.of(context).reduceMotion ? _to : _now,
      child: child,
    ),
    child: widget.child,
  );
}

/// The words of [style] letterpressed into a chrome surface in [colors]: a
/// one-pixel light line below them by day, a dark line above them by night.
///
/// ```dart
/// Text('Simmer', style: glossLetterpress(theme.textTheme.title, colors))
/// ```
TextStyle glossLetterpress(TextStyle style, GlossColors colors) =>
    style.copyWith(
      shadows: [
        Shadow(
          color: colors.letterpress,
          offset: Offset(0, colors.letterpressBelow ? 1 : -1),
        ),
      ],
    );

/// A chrome surface: Gloss's bar glaze, its fine grain (painted once and
/// reused; off under high contrast), its light along the top and its edge
/// along the foot where it meets the page. The top bar, the bottom bar, the
/// rail and the sidebar stand on it.
///
/// ```dart
/// GlossBar(child: SizedBox(height: 56, child: Center(child: Text('Simmer'))))
/// ```
class GlossBar extends StatelessWidget {
  /// [child] on the bar glaze, its edge on [edge]'s side.
  const GlossBar({super.key, this.edge = AxisDirection.down, this.child});

  /// The side the bar meets the page on: down for a top bar, up for a
  /// bottom bar, the end side for a sidebar.
  final AxisDirection edge;

  /// What stands on the bar.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = GlossTheme.of(context).colors;
    final highContrast = MediaQuery.maybeHighContrastOf(context) ?? false;
    return CustomPaint(
      painter: _BarPainter(
        colors,
        edge: edge,
        direction: Directionality.maybeOf(context) ?? TextDirection.ltr,
        grain: !highContrast,
        pixelRatio:
            MediaQuery.maybeDevicePixelRatioOf(context) ??
            View.maybeOf(context)?.devicePixelRatio ??
            1,
      ),
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<AxisDirection>('edge', edge));
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(
    this.colors, {
    required this.edge,
    required this.direction,
    required this.grain,
    required this.pixelRatio,
  });

  final GlossColors colors;
  final AxisDirection edge;
  final TextDirection direction;
  final bool grain;
  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final vertical = edge == AxisDirection.down || edge == AxisDirection.up;
    // A sidebar is lit from the top too: its glaze runs down its length,
    // softer.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          vertical ? rect.bottomCenter : rect.topCenter + const Offset(0, 220),
          vertical
              ? [colors.barTop, colors.barMiddle, colors.barBottom]
              : [colors.barMiddle, colors.barMiddle, colors.barBottom],
          const [0, 0.55, 1],
          vertical ? TileMode.clamp : TileMode.clamp,
        ),
    );
    if (grain) {
      final day = colors.brightness == Brightness.light;
      final light = day ? const Color(0x1FFFFFFF) : const Color(0x08FFFFFF);
      final dark = day ? const Color(0x081E3246) : const Color(0x12000000);
      // A translated or scaled bar can place a speck between device pixels.
      // Its canvas must determine coverage there, just as it does for the rim.
      final origin = MatrixUtils.getAsTranslation(
        Matrix4.fromFloat64List(canvas.getTransform()),
      );
      bool aligned(double value) => value == value.roundToDouble();
      final onGrid =
          origin != null &&
          aligned(rect.width * pixelRatio) &&
          aligned(rect.height * pixelRatio) &&
          aligned(origin.dx * pixelRatio) &&
          aligned(origin.dy * pixelRatio);
      final shaders = onGrid ? _grainShadersFor(pixelRatio, light, dark) : null;
      if (shaders != null) {
        final ink = Paint();
        for (final shader in shaders) {
          canvas.drawRect(rect, ink..shader = shader);
        }
      } else {
        canvas
          ..save()
          ..clipRect(rect);
        for (var y = 0.0; y < size.height; y += _grainSize) {
          for (var x = 0.0; x < size.width; x += _grainSize) {
            canvas
              ..save()
              ..translate(x, y);
            _paintGrainTile(canvas, _grain, light, dark);
            canvas.restore();
          }
        }
        canvas.restore();
      }
    }
    final light = colors.brightness == Brightness.light;
    // The light along the top.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 1),
      Paint()
        ..color = light ? const Color(0xF2FFFFFF) : const Color(0x29FFFFFF),
    );
    final line = Paint()..color = colors.barEdge;
    switch (edge) {
      case AxisDirection.down:
        canvas.drawRect(Rect.fromLTWH(0, size.height - 1, size.width, 1), line);
      case AxisDirection.up:
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 1), line);
      case AxisDirection.right || AxisDirection.left:
        final atEnd =
            (edge == AxisDirection.right) == (direction == TextDirection.ltr);
        final x = atEnd ? size.width - 1 : 0.0;
        canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), line);
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.colors != colors ||
      old.edge != edge ||
      old.direction != direction ||
      old.grain != grain ||
      old.pixelRatio != pixelRatio;
}

const double _grainSize = 96;

typedef _GrainTile = ({Float32List light, Float32List dark});

final _grainShaders = <(double, Color, Color), List<ui.ImageShader>?>{};

List<ui.ImageShader>? _grainShadersFor(double ratio, Color light, Color dark) {
  final size = _grainSize * ratio;
  // At fractional densities adjacent specks can blend into the same pixel.
  if (ratio != ratio.roundToDouble() || size < 1 || size > 768) return null;
  final key = (ratio, light, dark);
  if (_grainShaders.containsKey(key)) return _grainShaders[key];
  if (_grainShaders.length == 8) {
    final oldest = _grainShaders.remove(_grainShaders.keys.first);
    for (final shader in oldest ?? const <ui.ImageShader>[]) {
      shader.dispose();
    }
  }
  final shaders = <ui.ImageShader>[];
  try {
    final matrix = Float64List(16)
      ..[0] = 1 / ratio
      ..[5] = 1 / ratio
      ..[10] = 1
      ..[15] = 1;
    for (final dots in _grainLayers) {
      final recorder = ui.PictureRecorder();
      _paintGrainTile(Canvas(recorder)..scale(ratio), dots, light, dark);
      final picture = recorder.endRecording();
      try {
        final image = picture.toImageSync(size.toInt(), size.toInt());
        try {
          shaders.add(
            ui.ImageShader(
              image,
              TileMode.repeated,
              TileMode.repeated,
              matrix,
              filterQuality: FilterQuality.none,
            ),
          );
        } finally {
          image.dispose();
        }
      } finally {
        picture.dispose();
      }
    }
    return _grainShaders[key] = shaders;
  } on UnsupportedError {
    // Some renderers cannot synchronously rasterize a picture.
  }
  for (final shader in shaders) {
    shader.dispose();
  }
  return _grainShaders[key] = null;
}

void _paintGrainTile(Canvas canvas, _GrainTile dots, Color light, Color dark) {
  final paint = Paint()..strokeWidth = 1;
  canvas
    ..drawRawPoints(ui.PointMode.points, dots.light, paint..color = light)
    ..drawRawPoints(ui.PointMode.points, dots.dark, paint..color = dark);
}

// A speck that lands on another must blend with the painted bar in a
// separate pass. Compositing both into a transparent tile first rounds
// their colors differently over the glaze.
final List<_GrainTile> _grainLayers = () {
  final occupied = <int, int>{};
  final layers = <({List<double> light, List<double> dark})>[];
  void place(Float32List points, {required bool light}) {
    for (var i = 0; i < points.length; i += 2) {
      final x = points[i];
      final y = points[i + 1];
      final cell = y.floor() * _grainSize.toInt() + x.floor();
      final layer = occupied[cell] ?? 0;
      occupied[cell] = layer + 1;
      if (layer == layers.length) layers.add((light: [], dark: []));
      (light ? layers[layer].light : layers[layer].dark).addAll([x, y]);
    }
  }

  place(_grain.light, light: true);
  place(_grain.dark, light: false);
  return [
    for (final layer in layers)
      (
        light: Float32List.fromList(layer.light),
        dark: Float32List.fromList(layer.dark),
      ),
  ];
}();

// The same light and dark specks cover each 96-pixel bar tile.
final ({Float32List light, Float32List dark}) _grain = () {
  final random = math.Random(1115);
  final light = <double>[];
  final dark = <double>[];
  for (var i = 0; i < 900; i++) {
    final x = random.nextInt(_grainSize.toInt()) + 0.5;
    final y = random.nextInt(_grainSize.toInt()) + 0.5;
    (random.nextBool() ? light : dark).addAll([x, y]);
  }
  return (light: Float32List.fromList(light), dark: Float32List.fromList(dark));
}();

/// The engraved line between a well's rows: a dark hairline with the light
/// caught under it, [indent] in from the start side.
///
/// ```dart
/// const GlossEngravedLine(indent: 16)
/// ```
class GlossEngravedLine extends StatelessWidget {
  /// The line, [indent] in from the start.
  const GlossEngravedLine({super.key, this.indent = 0, this.endIndent = 0});

  /// How far in from the start side it begins.
  final double indent;

  /// How far in from the end side it stops.
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    final colors = GlossTheme.of(context).colors;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent, end: endIndent),
      child: SizedBox(
        height: 1,
        width: double.infinity,
        child: ColoredBox(color: colors.hairline),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('indent', indent, defaultValue: 0))
      ..add(DoubleProperty('endIndent', endIndent, defaultValue: 0));
  }
}

double _glazeStrength(bool focused, bool hovered, bool pressed) => pressed
    ? 0.22
    : focused
    ? 1
    : hovered
    ? 0.38
    : 0;

/// The tint and strength of the reflection for [states].
Color glossGlazeOf(GlossColors colors, Set<WidgetState> states) =>
    colors.focus.withValues(
      alpha: states.contains(WidgetState.disabled)
          ? 0
          : _glazeStrength(
                  states.contains(WidgetState.focused),
                  states.contains(WidgetState.hovered),
                  states.contains(WidgetState.pressed),
                ) *
                colors.focus.a,
    );

/// The reflected light for a part which reports just its keyboard focus.
Color glossFocusOf(GlossColors colors, {required bool focused}) =>
    focused ? colors.focus : colors.focus.withValues(alpha: 0);
