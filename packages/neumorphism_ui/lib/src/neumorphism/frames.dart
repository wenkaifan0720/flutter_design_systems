// The material: one small painter, used by name, gives every raised and pressed surface. Flutter has no inset box shadow,
// so a pressed face is an inverted copy of its own shape, blurred and clipped to it.
//
// What a surface stands on decides what it draws, so raised and pressed can't stack up: `NeumorphicSurface.resolve` is the
// whole table. A slab inside a slab is a small part, with no second big shadow. A part on a part is a plain step. A well
// inside a well is a floor, one engraved edge with no second inset. Pages use `NeumorphicSlab` and `NeumorphicWell`, which take
// no radius and no colour.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/geometry.dart';
import 'theme.dart';
import 'component_themes.dart';
import 'knobs.dart';
import 'styled.dart';

/// The levels of the material, named for what they are.
enum NeumorphicSurfaceLevel {
  /// Buttons, knobs, chips, tiles: raised a little.
  part,

  /// A card: raised out of the wall.
  slab,

  /// A hero object: raised furthest. Only on the wall.
  casting,

  /// A switch's slot, a slider's track, a latched control: pressed a little.
  groove,

  /// A chart's or a list's bed, a bank of buttons, a tray: pressed in.
  well,
}

/// What a surface really draws, once it knows what it stands on.
enum NeumorphicDraw {
  /// A shallow raised face.
  part,

  /// A raised card face.
  slab,

  /// A deeply raised object face.
  casting,

  /// Raised nothing: a face with a catch-light. A part on a part.
  step,

  /// A shallow pressed face.
  groove,

  /// A deeply pressed surface.
  well,

  /// Pressed nothing: a well's floor with one engraved edge. A well in a well.
  floor,
}

/// Paints no cast shadow, catch-light or inset under it, leaving only faces and marks: what a washed-out screen leaves,
/// and what a part out of use is. For checks: a state must still read here.
///
/// ```dart
/// NeumorphicFlatScope(child: NeumorphicButton('Save', onPressed: () {}))
/// ```
class NeumorphicFlatScope extends InheritedWidget {
  /// Creates a [NeumorphicFlatScope].
  const NeumorphicFlatScope({
    super.key,
    this.flat = true,
    this.relief = 1,
    required super.child,
  }) : assert(relief >= 0 && relief <= 1);

  /// Whether the parts under it are flat. False gives them their relief back, so a part can keep its scope in the tree
  /// while it turns flat and back without being rebuilt from scratch.
  final bool flat;

  /// How much of their relief the parts under it keep while they are on their way to flat or back, 1 to 0: a part
  /// going out of use sinks to flush instead of losing its light and shadow at once.
  final double relief;

  /// Whether shadows and catch-lights are disabled by the nearest enclosing scope.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NeumorphicFlatScope>()?.flat ??
      false;

  /// The share of their relief parts keep under the nearest enclosing scope: 1 outside any.
  static double reliefOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<NeumorphicFlatScope>()
          ?.relief ??
      1;
  @override
  bool updateShouldNotify(NeumorphicFlatScope old) =>
      old.flat != flat || old.relief != relief;
}

Paint _blurred(Color color, double blur) => Paint()
  ..color = color
  ..isAntiAlias = true
  ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 2);

Paint _facePaint(Color ground, Shader? face) {
  final paint = Paint()..isAntiAlias = true;
  if (face == null) {
    // The material has one face colour. A gradient with two identical stops
    // adds a shader and its GPU program work without changing that colour.
    paint.color = ground;
  } else {
    paint.shader = face;
  }
  return paint;
}

/// A cast shadow's reach: an offset and a CSS blur.
typedef NeumorphicThrow = (Offset, double);

/// Raises [shape]: a dark shadow, a light shadow, the face, a catch-light and a crease.
void neumorphicPaintRaised(
  Canvas canvas,
  Path shape,
  NeumorphicColors c, {
  required NeumorphicThrow light,
  required NeumorphicThrow dark,
  Color? lightColor,
  Color? darkColor,
  Shader? face,
  double faceDeg = 145,
  bool flat = false,
  bool rim = false,
  NeumorphicElevation elevation = const NeumorphicElevation(),
}) {
  final box = shape.getBounds();
  if (!flat && elevation.depth > 0) {
    Color strength(Color color) =>
        color.withValues(alpha: color.a * elevation.strength);
    // By night the light side stays close to the face, a rim and not a halo: it never reaches further than the dark
    // side's own offset.
    final lit = c.dark && lightColor == null
        ? (light.$1 * .4, light.$2 * .45)
        : light;
    canvas.drawPath(
      shape.shift(dark.$1 * elevation.depth),
      _blurred(strength(darkColor ?? c.shadow), dark.$2 * elevation.depth),
    );
    canvas.drawPath(
      shape.shift(lit.$1 * elevation.depth),
      _blurred(strength(lightColor ?? c.highlight), lit.$2 * elevation.depth),
    );
  }
  canvas.drawPath(shape, _facePaint(c.ground, face));
  if (!flat && rim) _paintEdges(canvas, shape, box, c);
}

void _paintEdges(
  Canvas canvas,
  Path shape,
  Rect box,
  NeumorphicColors c, [
  double opacity = 1,
]) {
  canvas.save();
  canvas.clipPath(shape);
  canvas.drawPath(
    _outside(shape, box, const Offset(1, 1), 4),
    neumorphicFillPaint(c.rim.withValues(alpha: c.rim.a * opacity)),
  );
  canvas.drawPath(
    _outside(shape, box, const Offset(-1, -1), 4),
    neumorphicFillPaint(c.crease.withValues(alpha: c.crease.a * opacity)),
  );
  canvas.restore();
}

Path _outside(Path shape, Rect box, Offset by, double pad) => Path()
  ..fillType = PathFillType.evenOdd
  ..addRect(box.inflate(pad))
  ..addPath(shape, by);

/// Presses [shape] in: the pressed face, a light inset, a dark inset.
void neumorphicPaintPressed(
  Canvas canvas,
  Path shape,
  NeumorphicColors c, {
  required NeumorphicThrow light,
  required NeumorphicThrow dark,
  Color? lightColor,
  Color? darkColor,
  Color? tone,
  Shader? face,
  double faceDeg = 145,
  bool flat = false,
  NeumorphicElevation elevation = const NeumorphicElevation(),
  Rect? contentBounds,
}) {
  final box = shape.getBounds();
  canvas.drawPath(shape, _facePaint(c.ground, face));
  if (flat || elevation.depth == 0) return;
  Color strength(Color color) =>
      color.withValues(alpha: color.a * elevation.strength);
  // A coloured face keeps its colour: its light and shade inside are its own lighter and darker tones, never the
  // ground's white wash over it.
  if (tone != null) {
    final (hi, lo) = neumorphicTones(tone, c);
    lightColor = hi;
    darkColor = lo.withValues(alpha: math.max(lo.a, darkColor?.a ?? 0));
  }
  canvas.save();
  canvas.clipPath(shape);
  if (contentBounds != null && !contentBounds.isEmpty) {
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        shape,
        Path()..addRect(contentBounds),
      ),
    );
  }
  final pad =
      (light.$2 + dark.$2 + light.$1.distance + dark.$1.distance) *
          elevation.depth +
      2;
  canvas.drawPath(
    _outside(shape, box, light.$1 * elevation.depth, pad),
    _blurred(strength(lightColor ?? c.highlight), light.$2 * elevation.depth),
  );
  canvas.drawPath(
    _outside(shape, box, dark.$1 * elevation.depth, pad),
    _blurred(strength(darkColor ?? c.shadowInset), dark.$2 * elevation.depth),
  );
  canvas.restore();
}

/// A coloured face's own lighter and darker tones, for the light and shade inside it: the pigment's own when the face
/// is the pigment, else the colour moved toward white and black.
(Color, Color) neumorphicTones(Color face, NeumorphicColors c) {
  final opaque = face.withValues(alpha: 1);
  if (opaque == c.pigment.withValues(alpha: 1)) {
    return (
      c.pigmentHi.withValues(alpha: .55),
      c.pigmentDk.withValues(alpha: .75),
    );
  }
  final hsl = HSLColor.fromColor(opaque);
  return (
    hsl
        .withLightness((hsl.lightness + .12).clamp(0.0, 1.0))
        .toColor()
        .withValues(alpha: .55),
    hsl
        .withLightness((hsl.lightness - .2).clamp(0.0, 1.0))
        .toColor()
        .withValues(alpha: .75),
  );
}

/// Whether [fill] is a colour of its own (a pigment face), not the ground or a tint of it.
bool neumorphicIsColourFace(Color? fill, NeumorphicColors c) {
  if (fill == null || fill.a < .5) return false;
  final g = c.ground;
  final d = (fill.r - g.r).abs() + (fill.g - g.g).abs() + (fill.b - g.b).abs();
  return d > .3 && HSLColor.fromColor(fill).saturation > .2;
}

/// One level on [shape], by name. The numbers are the concept's: e1, e2, e3, p1 and p2.
void neumorphicPaintCast(
  Canvas canvas,
  Path shape,
  NeumorphicDraw draw,
  NeumorphicColors c, {
  bool flat = false,
  Shader? face,
  Color? tone,
  NeumorphicElevation elevation = const NeumorphicElevation(),
  Rect? contentBounds,
}) {
  switch (draw) {
    case NeumorphicDraw.part:
      neumorphicPaintRaised(
        canvas,
        shape,
        c,
        light: (const Offset(-4, -4), 10),
        dark: (const Offset(5, 5), 12),
        face: face,
        flat: flat,
        elevation: elevation,
      );
    case NeumorphicDraw.slab:
      neumorphicPaintRaised(
        canvas,
        shape,
        c,
        // The brighter dark-mode highlight belongs near the face. A wide
        // throw can wash over a caption sitting above a card on the wall.
        light: c.dark
            ? (const Offset(-5, -5), 12)
            : (const Offset(-10, -10), 24),
        dark: (const Offset(12, 12), 28),
        face: face,
        flat: flat,
        elevation: elevation,
      );
    case NeumorphicDraw.casting:
      neumorphicPaintRaised(
        canvas,
        shape,
        c,
        light: (const Offset(-16, -16), 36),
        dark: (const Offset(20, 20), 44),
        darkColor: c.shadowDeep,
        face: face,
        flat: flat,
        elevation: elevation,
      );
    case NeumorphicDraw.step:
      neumorphicPaintRaised(
        canvas,
        shape,
        c,
        light: (const Offset(-1, -1), 3),
        dark: (const Offset(1, 1), 3),
        face: face,
        flat: flat,
        elevation: elevation,
      );
    case NeumorphicDraw.groove:
      neumorphicPaintPressed(
        canvas,
        shape,
        c,
        tone: tone,
        contentBounds: contentBounds,
        light: (const Offset(-3, -3), 7),
        dark: (const Offset(3, 3), 7),
        face: face,
        flat: flat,
        elevation: elevation,
      );
    case NeumorphicDraw.well:
      neumorphicPaintPressed(
        canvas,
        shape,
        c,
        tone: tone,
        contentBounds: contentBounds,
        light: (const Offset(-6, -6), 14),
        dark: (const Offset(6, 6), 14),
        face: face,
        flat: flat,
        elevation: elevation,
      );
    case NeumorphicDraw.floor:
      neumorphicPaintPressed(
        canvas,
        shape,
        c,
        tone: tone,
        light: (const Offset(-1, -1), 3),
        dark: (const Offset(1, 1), 3),
        face: face,
        flat: flat,
        elevation: elevation,
        contentBounds: contentBounds,
      );
  }
}

/// Keyboard focus on a moulded part, said in the material: the part stands further off the wall (a longer, softer,
/// darker shadow) and its lit side warms with the pigment, the look's sign of what is live. Painted round [shape] and
/// never over it, so the face and its words stay as they are. Never a line, and never a press: pressed in means on.
/// [amount] eases it in and out; [reach] scales it to a small part (a cell in its bank, a slider's thumb).
void neumorphicPaintFocusLift(
  Canvas canvas,
  Path shape,
  NeumorphicColors c, {
  double amount = 1,
  double reach = 1,
  NeumorphicElevation elevation = const NeumorphicElevation(),
}) {
  if (amount <= 0) return;
  // Focus shows on a look with its relief turned low too: the lift keeps a floor of its own.
  final d = math.max(elevation.depth, .75) * reach;
  final box = shape.getBounds();
  canvas.save();
  canvas.clipPath(_outside(shape, box, Offset.zero, 64 * d + 8));
  final shade = c.shadowDeep;
  canvas.drawPath(
    shape.shift(Offset(12, 12) * d),
    _blurred(
      shade.withValues(alpha: math.min(1, shade.a * 2) * amount),
      26 * d,
    ),
  );
  // Lifted off the wall, the part's foot shades the wall close under it. That near shade, not a line, carries the
  // focus at 3:1 on a light ground, where the warmed light side can't.
  canvas.drawPath(
    shape.shift(Offset(3, 3) * d),
    _blurred(
      shade.withValues(alpha: math.min(1, shade.a * 2.2) * amount),
      5 * d,
    ),
  );
  final warm = Color.lerp(
    c.dark ? c.ink : const Color(0xFFFFFFFF),
    c.pigment,
    c.dark ? .7 : .42,
  )!;
  canvas.drawPath(
    shape.shift(Offset(-8, -8) * d),
    _blurred(warm.withValues(alpha: (c.dark ? .9 : 1) * amount), 22 * d),
  );
  canvas.restore();
}

/// Eases a face's focus, depth and wash together.
class _FaceTween extends Tween<(double, double, double)> {
  _FaceTween({super.end});

  @override
  (double, double, double) lerp(double t) {
    final a = begin ?? end!, b = end!;
    return (
      a.$1 + (b.$1 - a.$1) * t,
      a.$2 + (b.$2 - a.$2) * t,
      a.$3 + (b.$3 - a.$3) * t,
    );
  }
}

/// How far a pressed inset reads into its face: the groove's offset and half its blur.
const double _insetReach = 6;

class _CastPainter extends CustomPainter {
  _CastPainter(
    this.draw,
    this.radius,
    this.round,
    this.c,
    this.flat,
    this.live,
    this.outlined,
    this.depression,
    this.pressedDraw, {
    this.boundary = false,
    this.border,
    this.fill,
    this.side,
    this.safePadding = EdgeInsets.zero,
    this.elevation = const NeumorphicElevation(),
    this.focus = 0,
  });
  final NeumorphicDraw draw;
  final double radius;
  final bool round, flat, outlined, boundary;

  /// How much of the pigment's wash lies on the face: 0 off, 1 on.
  final double live;
  final NeumorphicColors c;
  final double depression;
  final NeumorphicDraw pressedDraw;
  final OutlinedBorder? border;
  final Color? fill;
  final BorderSide? side;
  final EdgeInsets safePadding;
  final NeumorphicElevation elevation;

  /// How far a focused groove or well has deepened, 0 to 1.
  final double focus;
  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    final shape =
        border?.getOuterPath(box) ??
        (Path()..addRRect(
          RRect.fromRectAndRadius(
            box,
            Radius.circular(round ? size.shortestSide / 2 : radius),
          ),
        ));
    // A colour face (the pigment on a checked box, a filled key) keeps its colour when it sinks.
    final tone = neumorphicIsColourFace(fill, c) ? fill : null;
    final face = fill == null ? null : cssLinear(box, 145, [fill!, fill!]);
    final cut = (round ? size.shortestSide / 2 : radius) * (1 - math.sqrt(.5));
    // A pressed shadow keeps out of the content rectangle, but always keeps a
    // band at every edge, at least the corner's cut and the inset's own reach:
    // that band is the edge. A one-line field's content spans
    // its whole height, so without the band its inset showed at the ends alone.
    final band = math.max(cut, _insetReach);
    final protected = EdgeInsets.fromLTRB(
      math.max(safePadding.left, band),
      math.max(safePadding.top, band),
      math.max(safePadding.right, band),
      math.max(safePadding.bottom, band),
    );
    final safe = protected.deflateRect(box);
    if (depression == 0 && boundary && draw == NeumorphicDraw.groove) {
      // A control found by its edge, with no line to find it by: a tighter, darker inset, so the well's rim reads
      // as an edge at a glance, day and night.
      // Focus deepens it: a longer, softer, darker inset, and the caret does the rest.
      final f = focus;
      neumorphicPaintPressed(
        canvas,
        shape,
        c,
        light: (Offset(-3 - 2 * f, -3 - 2 * f), 5 + 5 * f),
        dark: (Offset(3 + 3 * f, 3 + 3 * f), 5 + 7 * f),
        darkColor: c.shadowInset.withValues(
          alpha: math.min(
            1,
            c.shadowInset.a *
                ((c.dark ? 1.15 : 1.35) + (c.dark ? .5 : .75) * f),
          ),
        ),
        face: face,
        tone: tone,
        flat: flat,
        elevation: elevation,
        contentBounds: safe,
      );
    } else if (depression == 0 &&
        focus > 0 &&
        (draw == NeumorphicDraw.groove || draw == NeumorphicDraw.well)) {
      // A focused groove or well goes deeper, by [focus].
      final (o, b) = draw == NeumorphicDraw.groove ? (3.0, 7.0) : (6.0, 14.0);
      final f = focus;
      neumorphicPaintPressed(
        canvas,
        shape,
        c,
        light: (Offset(-o - 2 * f, -o - 2 * f), b + 5 * f),
        dark: (Offset(o + 3 * f, o + 3 * f), b + 7 * f),
        darkColor: c.shadowInset.withValues(
          alpha: math.min(1, c.shadowInset.a * (1 + .7 * f)),
        ),
        face: face,
        tone: tone,
        flat: flat,
        elevation: elevation,
        contentBounds: safe,
      );
    } else if (depression == 0) {
      neumorphicPaintCast(
        canvas,
        shape,
        draw,
        c,
        flat: flat,
        face: face,
        tone: tone,
        elevation: elevation,
        contentBounds: safe,
      );
    } else if (depression == 1) {
      neumorphicPaintCast(
        canvas,
        shape,
        pressedDraw,
        c,
        flat: flat,
        face: face,
        tone: tone,
        elevation: elevation,
        contentBounds: safe,
      );
    } else {
      // One depth from raised through flat to pressed: the raised pair shrinks to nothing by the middle, where the
      // face lies flush with the wall, and the pressed pair grows from nothing after it. A release runs back the same
      // way from wherever it is.
      final up = math.max(0.0, 1 - 2 * depression);
      final down = math.max(0.0, 2 * depression - 1);
      neumorphicPaintRaised(
        canvas,
        shape,
        c,
        light: (const Offset(-4, -4), 10),
        dark: (const Offset(5, 5), 12),
        face: face,
        elevation: elevation.copyWith(
          depth: elevation.depth * up,
          strength: elevation.strength * up,
        ),
        flat: flat || draw == NeumorphicDraw.step || up == 0,
        rim: false,
      );
      neumorphicPaintPressed(
        canvas,
        shape,
        c,
        light: (const Offset(-3, -3), 7),
        dark: (const Offset(3, 3), 7),
        face: face,
        tone: tone,
        elevation: elevation.copyWith(
          depth: elevation.depth * down,
          strength: elevation.strength * down,
        ),
        flat: flat || pressedDraw == NeumorphicDraw.floor || down == 0,
        contentBounds: safe,
      );
    }
    if (live > 0) {
      // Selected or on: one even tint of the pigment over the whole pressed face, never a band.
      canvas.drawPath(
        shape,
        Paint()
          ..isAntiAlias = true
          ..color = c.wash.withValues(alpha: c.wash.a * live),
      );
    }
    if (outlined || side != null) {
      final edge = side ?? BorderSide(color: c.edge, width: 1.5);
      if (border != null) {
        border!.copyWith(side: edge).paint(canvas, box);
      } else if (edge.style != BorderStyle.none) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            box.deflate(edge.width / 2),
            Radius.circular(
              ((round ? size.shortestSide / 2 : radius) - edge.width / 2).clamp(
                0,
                double.infinity,
              ),
            ),
          ),
          neumorphicStrokePaint(edge.color, edge.width),
        );
      }
    } else if (flat && boundary) {
      // A control found by its edge, lying flat out of use, has no relief left to be found by: its outline is printed
      // in the quiet ink, as a flat switch's track and a flat dial's collar are, so a disabled radio or box is still
      // there beside its words.
      canvas.drawPath(shape, neumorphicStrokePaint(c.quiet, 1));
    }
  }

  @override
  bool shouldRepaint(_CastPainter o) =>
      o.draw != draw ||
      o.radius != radius ||
      o.round != round ||
      o.c != c ||
      o.flat != flat ||
      o.live != live ||
      o.outlined != outlined ||
      o.boundary != boundary ||
      o.depression != depression ||
      o.focus != focus ||
      o.pressedDraw != pressedDraw ||
      o.border != border ||
      o.fill != fill ||
      o.side != side ||
      o.safePadding != safePadding ||
      o.elevation != elevation;
}

/// What [child]'s surfaces stand on, with no surface of its own drawn. A carousel's frame seats its slides as on a
/// face: a card in it casts as a part does, so its whole cast stays inside the frame, where a slab's cast (50 px) was
/// cut by the frame into a tray under the slide.
class NeumorphicSeat extends StatelessWidget {
  /// Seats [child]'s surfaces on [on].
  const NeumorphicSeat({super.key, required this.on, required this.child});

  /// What the surfaces inside stand on.
  final NeumorphicDraw on;

  /// The content seated.
  final Widget child;

  @override
  Widget build(BuildContext context) => _SurfaceScope(on: on, child: child);
}

class _SurfaceScope extends InheritedWidget {
  const _SurfaceScope({
    required this.on,
    this.border,
    this.padding = EdgeInsets.zero,
    this.rim = 0,
    required super.child,
  });
  final NeumorphicDraw on;
  final OutlinedBorder? border;
  final EdgeInsets padding;
  final double rim;
  @override
  bool updateShouldNotify(_SurfaceScope old) =>
      old.on != on ||
      old.border != border ||
      old.padding != padding ||
      old.rim != rim;
}

/// The outline of the surface holding [context], how far inside it its content starts, and how wide its rim is: what
/// a part needs to line its own outline up with its holder's, as a grouped list's rows do. Null outside a surface.
/// Hidden from the barrel.
({OutlinedBorder border, EdgeInsets padding, double rim})? neumorphicHolder(
  BuildContext context,
) {
  final scope = context.dependOnInheritedWidgetOfExactType<_SurfaceScope>();
  final border = scope?.border;
  return border == null
      ? null
      : (border: border, padding: scope!.padding, rim: scope.rim);
}

/// A surface of the material. Hidden from the barrel: pages use `NeumorphicSlab` and `NeumorphicWell`, and a part uses this.
/// [round] is for an object: a dial's body, a knob, a push button. Anything holding words stays on [NeumorphicRadii].
///
/// ```dart
/// NeumorphicSurface(cast: NeumorphicSurfaceLevel.part, padding: EdgeInsets.all(16), child: Text('Raised content'))
/// ```
class NeumorphicSurface extends StatelessWidget {
  /// Creates a [NeumorphicSurface].
  const NeumorphicSurface({
    super.key,
    required this.cast,
    this.radius,
    this.round = false,
    this.padding = EdgeInsets.zero,
    this.live = false,
    this.outlined = false,
    this.boundary = false,
    this.depression = 0,
    this.style,
    this.themeStyle,
    this.shape,
    this.states = const {},
    this.child,
  });

  /// The intended relief level, resolved against the surrounding surface.
  final NeumorphicSurfaceLevel cast;

  /// The fallback corner radius when no shape overrides it.
  final double? radius;

  /// Whether the fallback surface is circular.
  final bool round;

  /// Space between the face and its content, before any shape inset.
  final EdgeInsetsGeometry padding;

  /// A wash of the pigment: this surface is on.
  final bool live;

  /// Adds a printed boundary when the theme's high-contrast setting is enabled.
  final bool outlined;

  /// A control a person finds by its edge (a checkbox, a radio, a field): with no line drawn round it, its groove sits
  /// deeper, a tighter and darker inset, so the relief alone shows where it is.
  final bool boundary;

  /// A moulded part's progress into a groove, from zero to one.
  final double depression;

  /// The widget override, read before [themeStyle].
  final NeumorphicStyle? style;

  /// The owning component's theme.
  final NeumorphicStyle? themeStyle;

  /// The role's shape knob, after style overrides; null keeps the drawn shape.
  final OutlinedBorder? shape;

  /// Additional states such as selection or an editing error.
  final Set<WidgetState> states;

  /// The content placed inside this component.
  final Widget? child;

  /// What [cast] draws standing on [on]; null is the wall. The whole of the nesting rule.
  static NeumorphicDraw resolve(
    NeumorphicSurfaceLevel cast,
    NeumorphicDraw? on,
  ) {
    switch (cast) {
      case NeumorphicSurfaceLevel.groove:
        return on == NeumorphicDraw.groove || on == NeumorphicDraw.floor
            ? NeumorphicDraw.floor
            : NeumorphicDraw.groove;
      case NeumorphicSurfaceLevel.well:
        return switch (on) {
          NeumorphicDraw.well ||
          NeumorphicDraw.groove ||
          NeumorphicDraw.floor => NeumorphicDraw.floor,
          NeumorphicDraw.part || NeumorphicDraw.step => NeumorphicDraw.groove,
          _ => NeumorphicDraw.well,
        };
      case NeumorphicSurfaceLevel.part:
        return on == NeumorphicDraw.part || on == NeumorphicDraw.step
            ? NeumorphicDraw.step
            : NeumorphicDraw.part;
      case NeumorphicSurfaceLevel.slab:
        return switch (on) {
          null => NeumorphicDraw.slab,
          NeumorphicDraw.part || NeumorphicDraw.step => NeumorphicDraw.step,
          _ => NeumorphicDraw.part,
        };
      case NeumorphicSurfaceLevel.casting:
        return switch (on) {
          null => NeumorphicDraw.casting,
          NeumorphicDraw.part || NeumorphicDraw.step => NeumorphicDraw.step,
          _ => NeumorphicDraw.part,
        };
    }
  }

  static double _defaultRadius(NeumorphicSurfaceLevel cast) => switch (cast) {
    NeumorphicSurfaceLevel.slab ||
    NeumorphicSurfaceLevel.casting => NeumorphicRadii.slab,
    NeumorphicSurfaceLevel.well => NeumorphicRadii.well,
    NeumorphicSurfaceLevel.part ||
    NeumorphicSurfaceLevel.groove => NeumorphicRadii.control,
  };

  /// What this context's next surface stands on: null on the wall.
  static NeumorphicDraw? on(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SurfaceScope>()?.on;

  @override
  Widget build(BuildContext context) {
    final theme = NeumorphicTheme.of(context);
    final c = theme.colors;
    final draw = resolve(cast, on(context));
    final look = NeumorphicStyleOf(
      [style, themeStyle],
      {...NeumorphicStatesScope.of(context), ...states},
    );
    final ownPadding =
        look.padding(Directionality.of(context)) ??
        padding.resolve(Directionality.of(context));
    final customShape = look.shape ?? shape;
    final familyShape = round
        ? theme.shapes.circle()
        : theme.shapes.corner(radius ?? _defaultRadius(cast));
    final edge =
        look.side ??
        (outlined && theme.highContrast || look.edge != null
            ? BorderSide(color: look.edge ?? c.edge, width: neumorphicEdgeWidth)
            : null);
    return AnimatedNeumorphicShape(
      shape: customShape ?? familyShape,
      builder: (context, border) {
        final safePadding =
            ownPadding +
            (customShape?.dimensions.resolve(Directionality.of(context)) ??
                EdgeInsets.zero);
        Widget content = Padding(padding: safePadding, child: child);
        final words = look.textStyle;
        final foreground = look.foreground;
        if (words != null || foreground != null) {
          content = DefaultTextStyle.merge(
            style: (words ?? const TextStyle()).copyWith(color: foreground),
            child: content,
          );
        }
        if (foreground != null || look.iconSize != null) {
          content = IconTheme.merge(
            data: IconThemeData(color: foreground, size: look.iconSize),
            child: content,
          );
        }
        final minimum = look.minimumSize;
        if (minimum != null) {
          content = ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: minimum.width,
              minHeight: minimum.height,
            ),
            child: content,
          );
        }
        // A groove or a well with focus (a field being typed in, a code's cell, the wheel) deepens; the caret, or the
        // lens, does the rest. Eased, and always in the tree.
        final focused =
            (draw == NeumorphicDraw.groove || draw == NeumorphicDraw.well) &&
            (states.contains(WidgetState.focused) ||
                NeumorphicStatesScope.of(context)
                    .contains(WidgetState.focused));
        final motion = NeumorphicMotion.of(context);
        // A part going out of use sinks to flush rather than losing its light and shadow at once.
        final relief = NeumorphicFlatScope.reliefOf(context);
        final elevation = relief >= 1
            ? theme.elevation
            : theme.elevation.copyWith(
                depth: theme.elevation.depth * relief,
                strength: theme.elevation.strength * relief,
              );
        // A part chosen or let go (raised to pressed in, and back) moves through one depth, flush at the middle, and
        // its wash comes and goes with it; nothing switches at once.
        final sinks =
            cast == NeumorphicSurfaceLevel.part ||
            cast == NeumorphicSurfaceLevel.groove;
        final pressedDraw = resolve(NeumorphicSurfaceLevel.groove, on(context));
        final raisedDraw = resolve(NeumorphicSurfaceLevel.part, on(context));
        final face = TweenAnimationBuilder<(double, double, double)>(
          tween: _FaceTween(
            end: (
              focused ? 1 : 0,
              cast == NeumorphicSurfaceLevel.groove ? 1 : 0,
              live ? 1 : 0,
            ),
          ),
          duration: motion.state,
          curve: motion.standard,
          builder: (context, value, child) {
            final (focus, sink, wash) = value;
            final moving = sinks && sink > 0 && sink < 1;
            return CustomPaint(
              painter: _CastPainter(
                moving ? raisedDraw : draw,
                radius ?? _defaultRadius(cast),
                round,
                c,
                NeumorphicFlatScope.of(context),
                wash.clamp(0.0, 1.0),
                outlined && theme.highContrast,
                moving ? math.max(depression, sink) : depression,
                pressedDraw,
                boundary: boundary,
                border: border,
                fill: look.fill,
                side: edge,
                safePadding: safePadding,
                elevation: elevation,
                focus: focus.clamp(0.0, 1.0),
              ),
              child: child,
            );
          },
          child: _SurfaceScope(
            on: draw,
            border: border,
            padding: safePadding,
            rim: edge == null || edge.style == BorderStyle.none
                ? 0
                : edge.width,
            child: content,
          ),
        );
        // A face of the ground's colour shows only by its shadows, which no reading of pixels can place: a control's,
        // a slot's, a field's or a well's face is marked as one item for ui_core's keyline and label checks. A card
        // and the hero cast hold things judged by their own keylines, so they stay unmarked.
        return switch (cast) {
          NeumorphicSurfaceLevel.slab || NeumorphicSurfaceLevel.casting => face,
          _ => DesignKeylineFace(child: face),
        };
      },
    );
  }
}

/// A slab raised out of the wall, holding whatever you give it. For a card with a head use `NeumorphicCard`. It takes no radius
/// and no colour: its shape is the look's. A slab inside a slab comes out a small part, never a second big shadow.
///
/// ```dart
/// NeumorphicSlab(child: NeumorphicKvRow('A label', 'A value', isFirst: true))
/// ```
class NeumorphicSlab extends StatelessWidget {
  /// Creates a [NeumorphicSlab].
  const NeumorphicSlab({
    super.key,
    required this.child,
    this.padding,
    this.style,
  });

  /// The content placed inside this component.
  final Widget child;

  /// Face, outline, padding, minimum size and inherited content styling,
  /// before the card component theme. Explicit child styles keep precedence.
  final NeumorphicStyle? style;

  /// Defaults to the concept's card inset: 20 on a phone, 24 on a desktop.
  final EdgeInsetsGeometry? padding;

  /// The default inset, for a child that bleeds to the edge by hand.
  static EdgeInsets inset(NeumorphicThemeData t) =>
      EdgeInsets.all(t.desk ? 24 : 20);
  @override
  // A slab (a card, a list's section) holds its own keylines: ui_core's keyline check measures every screen built on it.
  Widget build(BuildContext context) => DesignKeylineRegion(
    child: NeumorphicSurface(
      cast: NeumorphicSurfaceLevel.slab,
      style: style,
      themeStyle: NeumorphicTheme.of(context).cardTheme,
      padding: padding ?? inset(NeumorphicTheme.of(context)),
      child: child,
    ),
  );
}

/// A well pressed in: a chart's bed, a list of times, a stat. Words and marks stand in it, on the same inks as anywhere. It
/// takes no radius and no colour. A well inside a well comes out a plain floor, never a second inset.
///
/// ```dart
/// NeumorphicWell(padding: const EdgeInsets.all(14), child: NeumorphicStepRow(time: '09:00', title: 'A step'))
/// ```
class NeumorphicWell extends StatelessWidget {
  /// Creates a [NeumorphicWell].
  const NeumorphicWell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.small = false,
    this.style,
  });

  /// The content placed inside this component.
  final Widget child;

  /// Space between the face and its content, before any shape inset.
  final EdgeInsetsGeometry padding;

  /// Face, outline, padding, minimum size and inherited content styling.
  /// Explicit child styles keep precedence.
  final NeumorphicStyle? style;

  /// A small well: a stat, a note, one line.
  final bool small;
  @override
  Widget build(BuildContext context) => NeumorphicSurface(
    cast: NeumorphicSurfaceLevel.well,
    style: style,
    themeStyle: NeumorphicTheme.of(context).cardTheme,
    radius: small ? NeumorphicRadii.control : NeumorphicRadii.well,
    padding: padding,
    child: child,
  );
}
