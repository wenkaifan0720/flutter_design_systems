/// Studio's material: anodised metal and glass in three depths under one light
/// from the top, the indicator lamp, the readout window, the machined groove
/// and the engraved legend. Every Studio part is drawn with [StudioSurface];
/// a part that changes with its states draws [AnimatedStudioSurface], which
/// moves from one [StudioFace] to the next on a spring.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/brush.dart';
import 'theme.dart';

/// Where a surface stands under the light: set into the metal, flush with
/// it, or standing proud of it.
enum StudioDepth {
  /// Set into the metal: a field's glass, a display, a slot, a recess. Shadow
  /// falls inside from its top edge; its lower lip catches the light.
  sunk,

  /// Flush: a panel module, a bar. Its top edge catches the light.
  level,

  /// Standing proud: a key, a cap, a knob. Its top edge catches the light and
  /// it casts a shadow below; a press sinks it.
  raised,
}

/// How a surface looks at one moment: what [StudioSurface] paints and what
/// [AnimatedStudioSurface] moves between.
@immutable
class StudioFace with Diagnosticable {
  /// A face of [fill] falling to [fillLow], at [depth].
  const StudioFace({
    required this.fill,
    required this.fillLow,
    required this.depth,
    this.foreground,
    this.radius = StudioRadii.key,
    this.travel = 0,
    this.glow = const Color(0x00000000),
    this.rim = const Color(0x00000000),
    this.focus = const Color(0x00000000),
    this.brushed = false,
    this.presence = 1,
  }) : assert(travel >= 0 && travel <= 1),
       assert(presence >= 0 && presence <= 1);

  /// The face's colour at its top, where the light falls.
  final Color fill;

  /// Its colour at its foot.
  final Color fillLow;

  /// Where it stands.
  final StudioDepth depth;

  /// The words and glyphs on it; null leaves them as they are.
  final Color? foreground;

  /// Its corners. A face set in another is concentric with it: its radius is
  /// the outer one less the inset.
  final double radius;

  /// How far a raised face has sunk under a press: 0 at rest, 1 home.
  final double travel;

  /// The light a lit face gives off round it; transparent for none.
  final Color glow;

  /// A sunk face's inner rim, lit: a focused field's glass.
  final Color rim;

  /// The keyboard backlight along the inside of the face. A transparent
  /// color leaves the light off.
  final Color focus;

  /// Whether the metal shows its brush ([StudioThemeData.textureStrength]).
  final bool brushed;

  /// How much of the face is there: 1 whole, 0 gone but for its focus light.
  /// A recess that only shows under a press (a key with no cap) fades in by
  /// it.
  final double presence;

  /// A copy with the given fields replaced.
  StudioFace copyWith({
    Color? fill,
    Color? fillLow,
    StudioDepth? depth,
    Color? foreground,
    double? radius,
    double? travel,
    Color? glow,
    Color? rim,
    Color? focus,
    bool? brushed,
    double? presence,
  }) => StudioFace(
    fill: fill ?? this.fill,
    fillLow: fillLow ?? this.fillLow,
    depth: depth ?? this.depth,
    foreground: foreground ?? this.foreground,
    radius: radius ?? this.radius,
    travel: travel ?? this.travel,
    glow: glow ?? this.glow,
    rim: rim ?? this.rim,
    focus: focus ?? this.focus,
    brushed: brushed ?? this.brushed,
    presence: presence ?? this.presence,
  );

  /// Between [a] and [b] at [t].
  static StudioFace lerp(StudioFace a, StudioFace b, double t) {
    if (identical(a, b)) return a;
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    return StudioFace(
      fill: c(a.fill, b.fill),
      fillLow: c(a.fillLow, b.fillLow),
      depth: t < 0.5 ? a.depth : b.depth,
      foreground: a.foreground == null || b.foreground == null
          ? (t < 0.5 ? a.foreground : b.foreground)
          : c(a.foreground!, b.foreground!),
      radius: a.radius + (b.radius - a.radius) * t,
      travel: (a.travel + (b.travel - a.travel) * t).clamp(0.0, 1.0),
      glow: c(a.glow, b.glow),
      rim: c(a.rim, b.rim),
      focus: c(a.focus, b.focus),
      brushed: t < 0.5 ? a.brushed : b.brushed,
      presence: (a.presence + (b.presence - a.presence) * t).clamp(0.0, 1.0),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StudioFace &&
      other.fill == fill &&
      other.fillLow == fillLow &&
      other.depth == depth &&
      other.foreground == foreground &&
      other.radius == radius &&
      other.travel == travel &&
      other.glow == glow &&
      other.rim == rim &&
      other.focus == focus &&
      other.brushed == brushed &&
      other.presence == presence;

  @override
  int get hashCode => Object.hash(
    fill,
    fillLow,
    depth,
    foreground,
    radius,
    travel,
    glow,
    rim,
    focus,
    brushed,
    presence,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('fill', fill))
      ..add(ColorProperty('fillLow', fillLow))
      ..add(EnumProperty<StudioDepth>('depth', depth))
      ..add(DoubleProperty('radius', radius))
      ..add(DoubleProperty('travel', travel))
      ..add(ColorProperty('glow', glow))
      ..add(ColorProperty('focus', focus));
  }
}

/// The light and shadow a surface is painted with, from the theme: how dark a
/// shadow falls and how bright an edge catches the light in this room.
@immutable
class StudioLight {
  /// The light of [colors]'s room, the brush at [brush] (0 to 1).
  const StudioLight({
    required this.colors,
    required this.brush,
    required this.highContrast,
  });

  /// The room's light at [context]: the theme's, with the brush gone and the
  /// edges drawn in high contrast.
  factory StudioLight.of(BuildContext context) {
    final theme = StudioTheme.of(context);
    final high = MediaQuery.maybeHighContrastOf(context) ?? false;
    // By night the grain catches less light: on dark metal the same brush
    // would read as coarse static over a wide panel.
    final room = theme.colors.brightness == Brightness.dark ? 0.6 : 0.8;
    return StudioLight(
      colors: theme.colors,
      brush: high ? 0 : theme.textureStrength * room,
      highContrast: high,
    );
  }

  /// The theme's colours.
  final StudioColors colors;

  /// How strongly the metal's brush shows.
  final double brush;

  /// Whether every face also takes an outline, for high contrast.
  final bool highContrast;

  bool get _night => colors.brightness == Brightness.dark;

  /// How dark a cast shadow is.
  double get castStrength => _night ? 0.62 : 0.26;

  /// How dark the shadow inside a recess is.
  double get innerStrength => _night ? 0.85 : 0.52;

  // Dark glass by night: how much of the edge light it reflects high up,
  // and how much the wall inside its lower lip catches.
  double get _sheen => _night ? 0.8 : 0;
  double get _lowerWall => _night ? 1.6 : 0;

  @override
  bool operator ==(Object other) =>
      other is StudioLight &&
      other.colors == colors &&
      other.brush == brush &&
      other.highContrast == highContrast;

  @override
  int get hashCode => Object.hash(colors, brush, highContrast);
}

/// Paints [face] round [child]: the cast shadow or the recess, the face lit
/// from the top (sunk by its [StudioFace.travel]), its glow, its lit rim and
/// its focus light round its edge.
///
/// The surface's size is its face's: shadows, glows and the focus light fall
/// outside it, so a raised face lines up with a sunk one beside it. Leave 6 px
/// of room round a raised or lit face where a clip could cut it.
///
/// It is the primitive every Studio part is drawn with, public so an app's own
/// part can wear the look.
///
/// ```dart
/// StudioSurface(face: StudioFace(fill: colors.key, fillLow: colors.keyLow, depth: StudioDepth.raised), child: const Text('Key'))
/// ```
class StudioSurface extends StatelessWidget {
  /// [child] on [face].
  const StudioSurface({super.key, required this.face, this.child})
    : _inBank = false;

  const StudioSurface._(this._inBank, {required this.face, this.child});

  final bool _inBank;

  /// How it looks.
  final StudioFace face;

  /// What stands on the face.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final light = StudioLight.of(context);
    final ratio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    final sink = face.depth == StudioDepth.raised
        ? face.travel * StudioMetrics.pressTravel
        : 0.0;
    Widget? content = child;
    if (content != null && face.foreground != null) {
      content = IconTheme.merge(
        data: IconThemeData(color: face.foreground),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: face.foreground),
          child: content,
        ),
      );
    }
    return CustomPaint(
      painter: StudioFacePainter._(
        _inBank,
        face: face,
        light: light,
        ratio: ratio,
      ),
      child: content == null
          ? null
          : Transform.translate(offset: Offset(0, sink), child: content),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<StudioFace>('face', face));
  }
}

/// Paints a [StudioFace] in [light] over a box: what [StudioSurface] draws,
/// public for a part that paints its own face round other paint.
class StudioFacePainter extends CustomPainter {
  /// [face] in [light], its brush at [ratio] device pixels a logical one.
  StudioFacePainter({required this.face, required this.light, this.ratio = 1})
    : _inBank = false;

  StudioFacePainter._(
    this._inBank, {
    required this.face,
    required this.light,
    required this.ratio,
  });

  final bool _inBank;

  /// The face.
  final StudioFace face;

  /// The room's light.
  final StudioLight light;

  /// Device pixels per logical pixel, for the brush.
  final double ratio;

  @override
  void paint(Canvas canvas, Size size) =>
      _paintFace(canvas, Offset.zero & size, face, light, ratio, _inBank);

  @override
  bool shouldRepaint(StudioFacePainter old) =>
      old.face != face ||
      old.light != light ||
      old.ratio != ratio ||
      old._inBank != _inBank;
}

/// Paints [face] in [light] over [rect] on [canvas]: what every Studio
/// surface is.
void paintStudioFace(
  Canvas canvas,
  Rect rect,
  StudioFace face,
  StudioLight light, {
  double ratio = 1,
}) => _paintFace(canvas, rect, face, light, ratio, false);

void _paintFace(
  Canvas canvas,
  Rect rect,
  StudioFace face,
  StudioLight light,
  double ratio,
  bool inBank,
) {
  final r = Radius.circular(face.radius);
  final sink = face.depth == StudioDepth.raised
      ? face.travel * StudioMetrics.pressTravel
      : 0.0;
  final rest = RRect.fromRectAndRadius(rect, r);
  // A key mounted in a bank travels into its socket. Its outline stays on
  // the socket's keylines while its legend, edge light and shadow move.
  final body = inBank ? rest : rest.shift(Offset(0, sink));
  final layered = face.presence < 1;
  if (face.presence > 0) {
    if (layered) {
      canvas.saveLayer(
        rect.inflate(8),
        Paint()..color = Color.fromRGBO(0, 0, 0, face.presence),
      );
    }
    _paintBody(canvas, rect, body, rest, face, light, ratio, sink);
    if (layered) canvas.restore();
  } else {
    // A capless key's lit rim, with no cap round it.
    _paintRim(canvas, body, face.rim);
  }
  if (face.focus.a > 0) {
    paintStudioFocusLight(canvas, body, face.focus, light, inside: inBank);
  }
}

/// Lights the edge within [outline]. A key [inside] a bank uses the inner lip
/// of its socket. The light stays on the face and follows [focus]'s opacity.
void paintStudioFocusLight(
  Canvas canvas,
  RRect outline,
  Color focus,
  StudioLight light, {
  bool inside = false,
}) {
  if (focus.a == 0) return;
  const width = StudioMetrics.focusWidth;
  final inset = inside ? width : width / 2;
  canvas.drawRRect(
    outline.deflate(inset),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = Color.lerp(
        light.colors.indicator,
        focus,
        0.2,
      )!.withValues(alpha: focus.a * 0.7),
  );
}

// The height from which a recess is a window (a field's glass, a bank of
// keys, a pane), not a slot: by night its lips show.
const double _windowFrom = 28;

// How far down dark glass reflects the room by night.
const double _reflectionReach = 24;

void _paintBody(
  Canvas canvas,
  Rect rect,
  RRect body,
  RRect rest,
  StudioFace face,
  StudioLight light,
  double ratio,
  double sink,
) {
  final shadow = light.colors.shadow;
  final edge = light.colors.edgeLight;

  if (face.glow.a > 0) {
    canvas.drawRRect(
      body.inflate(1),
      Paint()
        ..color = face.glow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }

  switch (face.depth) {
    case StudioDepth.raised:
      final lift = 1 - face.travel;
      // The contact line, always: the key stands on the metal.
      canvas.drawRRect(
        rest.shift(const Offset(0, 1)),
        Paint()..color = shadow.withValues(alpha: light.castStrength * 1.1),
      );
      if (lift > 0) {
        canvas.drawRRect(
          rest.shift(Offset(0, 1 + 1.5 * lift)),
          Paint()
            ..color = shadow.withValues(alpha: light.castStrength * 0.8 * lift)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.5 + 2.5 * lift),
        );
      }
      final top = Color.lerp(face.fill, face.fillLow, 0.55 * face.travel)!;
      final low = Color.lerp(face.fillLow, shadow, 0.06 * face.travel)!;
      _fill(canvas, body, top, low);
      if (face.brushed) _brush(canvas, body, light, ratio);
      // The top edge catches the light; pressed home it is in shadow. A
      // brushed graphite cap (the lit key) catches more of it, so by night
      // its edge still parts it from the dark bar it stands on.
      final catchLight = face.brushed ? 2.5 : 1.0;
      _edgeLine(
        canvas,
        body,
        edge.withValues(alpha: (edge.a * lift * catchLight).clamp(0.0, 1.0)),
        top: true,
      );
      _edgeLine(
        canvas,
        body,
        shadow.withValues(alpha: light.castStrength * 0.5),
        top: false,
      );
      if (face.travel > 0) {
        _innerShadow(
          canvas,
          body,
          shadow.withValues(alpha: light.innerStrength * 0.45 * face.travel),
          drop: 1.5,
          blur: 2,
        );
      }
    case StudioDepth.level:
      // A clear face casts nothing: its shadow would show through it.
      if (face.fill.a > 0) {
        canvas.drawRRect(
          rest.shift(const Offset(0, 1)),
          Paint()..color = shadow.withValues(alpha: light.castStrength * 0.9),
        );
        canvas.drawRRect(
          rest.shift(const Offset(0, 2)),
          Paint()
            ..color = shadow.withValues(alpha: light.castStrength * 0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
      _fill(canvas, body, face.fill, face.fillLow);
      if (face.brushed) _brush(canvas, body, light, ratio);
      _edgeLine(canvas, body, edge, top: true);
    case StudioDepth.sunk:
      // The lower lip catches the light below the recess.
      canvas.drawRRect(
        rest.shift(const Offset(0, 1)),
        Paint()..color = edge.withValues(alpha: edge.a * 0.9),
      );
      // A recess is shaded under its top lip and catches the light low
      // down: its fill runs from its low tone at the top to its own below,
      // the other way to a raised face.
      _fill(canvas, body, face.fillLow, face.fill);
      if (face.brushed) _brush(canvas, body, light, ratio);
      // A pane (glass a page reads on) sits deeper than a slot: its lip
      // casts a longer shadow.
      final pane = body.height > StudioMetrics.paneDepthFrom;
      // A window (a field's glass, a bank of keys, a pane), not a slot.
      final window = body.height >= _windowFrom;
      // Dark glass by night: a shadow can't darken it, so the light shows
      // the recess. The glass reflects the room in a strip under the shadow
      // its top lip casts, clear of the first row a pane holds, and the wall
      // inside its lower lip faces the light.
      if (window && light._sheen > 0) {
        final reach = math.min(body.height * 0.6, _reflectionReach);
        canvas.drawRRect(
          body,
          Paint()
            ..shader = ui.Gradient.linear(
              body.outerRect.topCenter,
              body.outerRect.topCenter + Offset(0, reach),
              [
                edge.withValues(alpha: edge.a * light._sheen),
                edge.withValues(alpha: 0),
              ],
            ),
        );
      }
      _innerShadow(
        canvas,
        body,
        shadow.withValues(alpha: light.innerStrength * (pane ? 0.85 : 0.7)),
        drop: pane ? 3 : 2,
        blur: pane ? 6 : 3,
      );
      // The recess's wall: dark under the top lip, gone by the bottom one
      // (which catches the light), never an outline all round.
      canvas.drawRRect(
        body.deflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..shader = ui.Gradient.linear(
            body.outerRect.topCenter,
            body.outerRect.bottomCenter,
            [
              shadow.withValues(alpha: light.innerStrength * 0.7),
              shadow.withValues(alpha: light.innerStrength * 0.12),
            ],
          ),
      );
      if (window && light._lowerWall > 0) {
        _edgeLine(
          canvas,
          body,
          edge.withValues(alpha: math.min(1, edge.a * light._lowerWall)),
          top: false,
        );
      }
  }

  if (light.highContrast) {
    canvas.drawRRect(
      body.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = light.colors.legend,
    );
  }
  _paintRim(canvas, body, face.rim);
}

void _paintRim(Canvas canvas, RRect body, Color rim) {
  if (rim.a <= 0) return;
  canvas.drawRRect(
    body.deflate(1.5),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = rim,
  );
}

void _fill(Canvas canvas, RRect body, Color top, Color low) {
  canvas.drawRRect(
    body,
    Paint()
      ..shader = ui.Gradient.linear(
        body.outerRect.topCenter,
        body.outerRect.bottomCenter,
        [top, low],
      ),
  );
}

void _brush(Canvas canvas, RRect body, StudioLight light, double ratio) {
  if (light.brush <= 0) return;
  final shader = studioBrushShader(ratio);
  if (shader == null) return;
  canvas.drawRRect(
    body,
    Paint()
      ..shader = shader
      ..color = Color.fromRGBO(0, 0, 0, light.brush),
  );
}

// A one pixel line inside the top (or the bottom) edge, following the
// corners: the face and the face moved a pixel, filled even-odd and clipped
// to the face, which leaves the crescent between them. No path boolean is
// computed per paint.
void _edgeLine(Canvas canvas, RRect body, Color color, {required bool top}) {
  if (color.a == 0) return;
  canvas.save();
  canvas.clipRRect(body);
  final path = Path()
    ..fillType = PathFillType.evenOdd
    ..addRRect(body)
    ..addRRect(body.shift(Offset(0, top ? 1 : -1)));
  canvas.drawPath(path, Paint()..color = color);
  canvas.restore();
}

// A shadow falling inside [body] from its top edge.
void _innerShadow(
  Canvas canvas,
  RRect body,
  Color color, {
  required double drop,
  required double blur,
}) {
  canvas.save();
  canvas.clipRRect(body);
  final path = Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(body.outerRect.inflate(blur * 4 + drop))
    ..addRRect(body.shift(Offset(0, drop)));
  canvas.drawPath(
    path,
    Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
  );
  canvas.restore();
}

/// [StudioSurface] that moves to each new [face] on a critically damped
/// spring ([StudioMotion.pressStiffness]), from wherever it is: a press, a
/// release, a focus, a lamp lighting. A new face mid-way turns from where the
/// surface stands, with no jump back. Under Reduce Motion the change is a
/// short fade, as `DesignMotionPolicy` says.
///
/// ```dart
/// AnimatedStudioSurface(face: pressed ? resting.copyWith(travel: 1) : resting, child: const Text('Play'))
/// ```
class AnimatedStudioSurface extends StatefulWidget {
  /// [child] on a face that moves to [face].
  const AnimatedStudioSurface({
    super.key,
    required this.face,
    this.stiffness = StudioMotion.pressStiffness,
    this.child,
  }) : _inBank = false;

  /// A key mounted in a recessed bank. Its outline stays concentric with
  /// the surrounding well as the light, shadow and legend respond to a press.
  const AnimatedStudioSurface.inBank({
    super.key,
    required this.face,
    this.stiffness = StudioMotion.pressStiffness,
    this.child,
  }) : _inBank = true;

  final bool _inBank;

  /// The face to arrive at.
  final StudioFace face;

  /// The spring's stiffness; the damping ratio is always 1.
  final double stiffness;

  /// What stands on the face.
  final Widget? child;

  @override
  State<AnimatedStudioSurface> createState() => _AnimatedStudioSurfaceState();
}

class _AnimatedStudioSurfaceState extends State<AnimatedStudioSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this)
    ..value = 1;
  late StudioFace _from = widget.face;
  late StudioFace _to = widget.face;

  StudioFace get _now => StudioFace.lerp(_from, _to, _controller.value);

  @override
  void didUpdateWidget(AnimatedStudioSurface old) {
    super.didUpdateWidget(old);
    if (widget.face == _to) return;
    _from = _now;
    _to = widget.face;
    _controller.value = 0;
    _controller.springTo(
      1,
      DesignMotionPolicy.of(context).effects(
        dampingRatio: StudioMotion.dampingRatio,
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
    builder: (context, child) =>
        StudioSurface._(widget._inBank, face: _now, child: child),
    child: widget.child,
  );
}

/// A key latched in, in [StudioColors]' light.
extension StudioBacklight on StudioFace {
  /// This key's cap, backlit when [latched] by day: the cap keeps its tone
  /// (barely warmed), the light leaking round its edge (a lit rim) and
  /// beyond it, with its legend and lamp lit, so a latched key reads lit
  /// rather than filled or switched off beside its bright neighbours. Its
  /// legend keeps 4.5:1. By night the cap stays dark and its legend glows.
  ///
  /// The lit rim is where a key's focus light falls, so a [focused] latched
  /// key's edge light glows at full strength in [StudioColors.focusRing]
  /// instead: the same rim, brighter, with nothing added round it.
  StudioFace backlitIf(StudioColors c, bool latched, {bool focused = false}) {
    if (!latched || c.brightness == Brightness.dark) return this;
    return copyWith(
      fill: Color.lerp(c.key, c.indicator, 0.05),
      fillLow: Color.lerp(c.key, c.indicator, 0.14),
      rim: focused ? c.focusRing : c.indicator.withValues(alpha: 0.75),
      glow: c.indicator.withValues(alpha: 0.4),
    );
  }
}

/// The faces of Studio's three materials in [StudioColors]: what the parts start
/// from.
extension StudioFaces on StudioColors {
  /// A key's cap at rest.
  StudioFace get keyFace => StudioFace(
    fill: key,
    fillLow: keyLow,
    depth: StudioDepth.raised,
    foreground: onKey,
  );

  /// The main key's cap: brushed graphite, its legend lit (the key itself
  /// gives off no light: amber fills nothing that is not lit).
  StudioFace get litKeyFace => StudioFace(
    fill: litKey,
    fillLow: litKeyLow,
    depth: StudioDepth.raised,
    foreground: onLitKey,
    brushed: true,
  );

  /// A panel module's metal.
  StudioFace get panelFace => StudioFace(
    fill: panel,
    fillLow: panelLow,
    depth: StudioDepth.level,
    radius: StudioRadii.panel,
    foreground: legend,
    brushed: true,
  );

  /// A glass display pane.
  StudioFace get displayFace => StudioFace(
    fill: display,
    fillLow: displayLow,
    depth: StudioDepth.sunk,
    radius: StudioRadii.display,
    foreground: onDisplay,
  );

  /// A readout window's glass: dark by night, lit from behind by day.
  StudioFace get readoutFace => StudioFace(
    fill: readout,
    fillLow: readoutLow,
    depth: StudioDepth.sunk,
    radius: StudioRadii.small,
    foreground: readoutLit,
  );

  /// A recess that holds keys (a bank, a rail, a slot).
  StudioFace get recessFace => StudioFace(
    fill: Color.lerp(
      slot,
      panelLow,
      brightness == Brightness.dark ? 0.15 : 0.55,
    )!,
    fillLow: Color.lerp(
      slot,
      panel,
      brightness == Brightness.dark ? 0.25 : 0.65,
    )!,
    depth: StudioDepth.sunk,
    radius: StudioRadii.bank,
  );
}

/// A part's two style layers ([DesignStyleOf]) put on a [StudioFace]: the
/// style's `fill` (both tones), its `foreground`, and its `edge` for a lit
/// rim. The light, the depths and the corners are the look's.
extension StudioStyleFace on DesignStyleOf {
  /// [face] in these layers' colours.
  StudioFace on(StudioFace face) {
    final fill = this.fill;
    final foreground = this.foreground;
    final edge = side?.color ?? this.edge;
    if (fill == null && foreground == null && edge == null) return face;
    return face.copyWith(
      fill: fill,
      fillLow: fill == null
          ? null
          : Color.lerp(fill, const Color(0xFF000000), 0.12),
      foreground: foreground,
      rim: edge,
    );
  }

  /// [base] with these layers' `textStyle` over it.
  TextStyle text(TextStyle base) => base.merge(textStyle);
}

/// An indicator lamp: a dimple of unlit glass when off (by night its bezel
/// catches the light, so it still reads as a lamp); lit, a small amber light
/// that glows. It warms up and goes dark on a spring.
///
/// ```dart
/// StudioLamp(on: recording, color: colors.danger)
/// ```
class StudioLamp extends StatefulWidget {
  /// A lamp, lit when [on].
  const StudioLamp({
    super.key,
    required this.on,
    this.color,
    this.size = StudioMetrics.lampSize,
  });

  /// Whether it is lit.
  final bool on;

  /// Its light; the theme's indicator when null.
  final Color? color;

  /// Its diameter.
  final double size;

  @override
  State<StudioLamp> createState() => _StudioLampState();
}

class _StudioLampState extends State<StudioLamp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lit = AnimationController(
    vsync: this,
    value: widget.on ? 1 : 0,
  );

  @override
  void didUpdateWidget(StudioLamp old) {
    super.didUpdateWidget(old);
    if (old.on != widget.on) {
      _lit.springTo(
        widget.on ? 1 : 0,
        DesignMotionPolicy.of(context).effects(
          dampingRatio: StudioMotion.dampingRatio,
          stiffness: StudioMotion.lampStiffness,
        ),
      );
    }
  }

  @override
  void dispose() {
    _lit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = StudioTheme.of(context).colors;
    final light = widget.color ?? colors.indicator;
    return SizedBox.square(
      dimension: widget.size,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _LampPainter(
            lit: _lit,
            light: light,
            off: colors.lampOff,
            edge: colors.edgeLight,
            bezel: colors.lampEdge,
            night: colors.brightness == Brightness.dark,
          ),
        ),
      ),
    );
  }
}

class _LampPainter extends CustomPainter {
  _LampPainter({
    required this.lit,
    required this.light,
    required this.off,
    required this.edge,
    required this.bezel,
    required this.night,
  }) : super(repaint: lit);

  final Animation<double> lit;
  final Color light;
  final Color off;
  final Color edge;
  final Color bezel;
  final bool night;

  @override
  void paint(Canvas canvas, Size size) {
    final t = lit.value.clamp(0.0, 1.0);
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    // The bezel: the dimple's lower lip catches the light.
    canvas.drawCircle(c.translate(0, 0.75), r, Paint()..color = edge);
    // Off: unlit glass in its dimple, shaded from above. By night a dark
    // dimple; by day pale smoked glass, so an unlit lamp never reads as a
    // dark dot beside a lit one.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          c.translate(0, -r * 0.25),
          r,
          night
              ? [
                  Color.lerp(off, const Color(0xFFFFFFFF), 0.08)!,
                  Color.lerp(off, const Color(0xFF000000), 0.55)!,
                ]
              : [
                  Color.lerp(off, const Color(0xFFFFFFFF), 0.6)!,
                  Color.lerp(off, const Color(0xFFFFFFFF), 0.12)!,
                ],
        ),
    );
    // By night the dimple's bezel catches the light round the dark glass,
    // at 3:1 on the metal, so an unlit lamp still reads as a lamp. It fades
    // as the glass lights, which covers it.
    if (night && t < 1) {
      final w = r * 0.25 < 1 ? 1.0 : r * 0.25;
      canvas.drawCircle(
        c,
        r - w / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..color = bezel.withValues(alpha: bezel.a * (1 - t)),
      );
    }
    if (t == 0) return;
    // Lit: the glow round it, then the light itself, hot at its heart.
    canvas.drawCircle(
      c,
      r * 1.6,
      Paint()
        ..color = light.withValues(alpha: (night ? 0.45 : 0.32) * t)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.9),
    );
    final hot = Color.lerp(light, const Color(0xFFFFFFFF), 0.75)!;
    final deep = Color.lerp(light, const Color(0xFF000000), 0.25)!;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          c.translate(-r * 0.12, -r * 0.2),
          r,
          [
            hot.withValues(alpha: t),
            light.withValues(alpha: t),
            deep.withValues(alpha: t),
          ],
          [0, 0.45, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(_LampPainter old) =>
      old.light != light ||
      old.off != off ||
      old.edge != edge ||
      old.bezel != bezel ||
      old.night != night;
}

/// A readout window: by night dark glass, its figures glowing in the
/// indicator light; by day pale glass lit from behind, its figures the
/// indicator deepened to read there. Tabular figures, so they never jitter
/// as they change.
///
/// ```dart
/// StudioReadout('1:24:05')
/// ```
class StudioReadout extends StatelessWidget {
  /// A window showing [text].
  const StudioReadout(
    this.text, {
    super.key,
    this.unit,
    this.color,
    this.style,
    this.minWidth = 0,
    this.semanticsLabel,
  });

  /// The figures.
  final String text;

  /// A small unit after them (`%`, `dB`).
  final String? unit;

  /// Their light; the theme's [StudioColors.readoutLit] when null.
  final Color? color;

  /// Over the theme's readout style.
  final TextStyle? style;

  /// The least width of the window, so a changing figure keeps its frame.
  final double minWidth;

  /// What a screen reader says in place of the figures.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final light = color ?? theme.colors.readoutLit;
    final base = theme.textTheme.readout
        .merge(style)
        .copyWith(color: light, shadows: theme.colors.readoutGlow(light));
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: semanticsLabel != null,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: StudioSurface(
          face: theme.colors.readoutFace,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StudioSpacing.small + 2,
              vertical: StudioSpacing.tight,
            ),
            child: Text.rich(
              TextSpan(
                text: text,
                children: [
                  if (unit != null)
                    TextSpan(
                      // A thin space parts the figure from its unit.
                      text: '\u2009$unit',
                      style: base.copyWith(
                        fontSize: (base.fontSize ?? 20) * 0.6,
                      ),
                    ),
                ],
              ),
              style: base,
              // Figures in a window run left to right in every language,
              // as a display's do: a sign before its number, a unit after.
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.end,
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// A machined groove across a panel: a dark cut with its lower lip catching
/// the light. Rows on a panel are parted by one.
///
/// ```dart
/// const StudioGroove()
/// ```
class StudioGroove extends StatelessWidget {
  /// A groove across its width, [indent] in from its start.
  const StudioGroove({super.key, this.indent = 0, this.endIndent = 0});

  /// How far in from the start it begins.
  final double indent;

  /// How far in from the end it stops.
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    final colors = StudioTheme.of(context).colors;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent, end: endIndent),
      child: SizedBox(
        height: 2,
        child: Column(
          children: [
            Expanded(child: ColoredBox(color: colors.groove)),
            Expanded(child: ColoredBox(color: colors.edgeLight)),
          ],
        ),
      ),
    );
  }
}

/// An engraved legend on the metal: small capitals with tracking where the
/// script has capitals (Latin, Greek, Cyrillic), and its own natural form
/// where it has none (Arabic, Hebrew, CJK, Thai), never forced spacing.
///
/// ```dart
/// const StudioLegend('Audio quality')
/// ```
class StudioLegend extends StatelessWidget {
  /// [text] as a legend.
  const StudioLegend(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.maxLines = 1,
  });

  /// The words, written in sentence case; the legend sets their capitals.
  final String text;

  /// Over the theme's legend style.
  final TextStyle? style;

  /// Their ink; the theme's muted legend when null.
  final Color? color;

  /// The most lines it takes, cut with an ellipsis past them; null wraps it
  /// onto as many as its words need.
  final int? maxLines;

  /// Whether [text]'s script has capitals.
  static bool hasCapitals(String text) =>
      text.toUpperCase() != text.toLowerCase();

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final capitals = hasCapitals(text);
    final base = theme.textTheme.legend.merge(style);
    final shown = capitals
        ? base.copyWith(color: color ?? base.color)
        : base.copyWith(
            color: color ?? base.color,
            letterSpacing: 0,
            fontSize: (base.fontSize ?? 12) + 1,
          );
    return Text(
      capitals ? text.toUpperCase() : text,
      style: shown,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      semanticsLabel: text,
    );
  }
}
