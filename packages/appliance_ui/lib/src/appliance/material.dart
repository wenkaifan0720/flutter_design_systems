/// Appliance's material: moulded plastic lit from the top, at three depths
/// ([ApplianceDepth]), joined at parting lines; the grained housing every
/// bar and panel surround is moulded in; the lamp; the focus backlight. Every
/// part paints with these, so a key, a field and a faceplate are one
/// material in one light.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/corners.dart';
import 'theme.dart';

const Color _clear = Color(0x00000000);

/// How one moulded part looks at one moment: its plastic (a gradient from
/// [top] to [bottom]), how far it stands out of or sinks into the panel
/// ([lift], 1 raised, 0 level, -1 sunken), whether it is seated at a parting
/// line ([seam]), how far a press has carried it in ([travel]), its corners
/// and its focus backlight. Every value lerps, so a press, a latch or a focus
/// moves continuously from one face to the next.
@immutable
class ApplianceFace with Diagnosticable {
  /// A face.
  const ApplianceFace({
    required this.top,
    required this.bottom,
    this.lift = 0,
    this.seam = 0,
    this.travel = 0,
    this.radius = BorderRadius.zero,
    this.corners,
    this.borderRadius,
    this.circle = false,
    this.foreground = _clear,
    this.focus = _clear,
    this.focusReach = 0,
    this.edge = _clear,
  });

  /// A raised key's face in [colors]: the key plastic, standing out.
  factory ApplianceFace.key(
    ApplianceColors colors, {
    double radius = 10,
    bool circle = false,
  }) => ApplianceFace(
    top: colors.keyTop,
    bottom: colors.keyBottom,
    lift: 1,
    radius: BorderRadius.circular(radius),
    circle: circle,
    foreground: colors.print,
  );

  /// The same key held or latched down: in shade, sunk into the panel.
  factory ApplianceFace.keyDown(
    ApplianceColors colors, {
    double radius = 10,
    bool circle = false,
  }) => ApplianceFace(
    top: colors.keyDownTop,
    bottom: colors.keyDownBottom,
    lift: -0.7,
    travel: 1,
    radius: BorderRadius.circular(radius),
    circle: circle,
    foreground: colors.print,
  );

  /// A sunken well in [colors]: a field, a display window.
  factory ApplianceFace.well(
    ApplianceColors colors, {
    double radius = 10,
    Color? fill,
  }) => ApplianceFace(
    top: fill ?? colors.well,
    bottom: fill ?? colors.well,
    lift: -1,
    radius: BorderRadius.circular(radius),
    foreground: colors.print,
  );

  /// A faceplate seated in the housing at a parting line, flush.
  factory ApplianceFace.plate(ApplianceColors colors, {double radius = 14}) =>
      ApplianceFace(
        top: colors.face,
        bottom: colors.face,
        seam: 1,
        radius: BorderRadius.circular(radius),
        foreground: colors.print,
      );

  /// The plastic at the top.
  final Color top;

  /// The plastic at the bottom.
  final Color bottom;

  /// 1 raised (a highlight on the top edge, a shade under), 0 level, -1
  /// sunken (a shade along the top inside edge, a lit lip under).
  final double lift;

  /// 1 when the face is seated at a parting line (a faceplate), 0 when not.
  final double seam;

  /// How far a press has carried the face (and its legend) into the panel,
  /// 0 to 1 of [ApplianceMetrics.pressTravel].
  final double travel;

  /// The corners Appliance draws the face with: the theme's step for the
  /// part ([ApplianceThemeData.radiusKey] and the rest).
  final BorderRadius radius;

  /// The step each corner takes when a part's style names its own
  /// (`RawStyle.corners`), held to [ApplianceThemeData.shapeLimits] and
  /// drawn at the theme's [ApplianceThemeData.shapeScheme] where the face is
  /// drawn ([resolveCorners]); a corner left null keeps [radius]'s. Null:
  /// every corner [radius]'s.
  final RawCorners? corners;

  /// Each corner's own radius, outside Appliance's bands: what a part's
  /// style's `shape` gives (as Material's `ButtonStyle.shape` takes any
  /// border), or what [corners] resolve to. It wins over [corners] and
  /// [radius]; a radius past half the face's shorter side stands at that
  /// half, so a corner of `double.infinity` is a full round end. A [circle]
  /// stays round.
  final BorderRadiusGeometry? borderRadius;

  /// Whether the face is round (a radio key, a knob): [radius] is ignored.
  final bool circle;

  /// The legend's colour on this face.
  final Color foreground;

  /// The light a focused part's rim is lit with from inside; clear when
  /// unfocused. The bezel carries the color of its emitter.
  final Color focus;

  /// How far beyond the face its focus light stands: zero for a part with a
  /// rim of its own to light. A part with no face (a printed legend, a link)
  /// lights a plate this far beyond its words instead, so the light crosses
  /// no letter.
  final double focusReach;

  /// A fine edge drawn over the face's rim (an error, high contrast); clear
  /// by default.
  final Color edge;

  /// The same part out of use: level with its panel and matte, seated at a
  /// faint parting line, its legend [ApplianceColors.printDisabled]: nothing
  /// left to press. Its plastic is the darker of a key's middle tone and the
  /// faceplate's, so it never stands brighter than a key in use (a brighter
  /// flat face read as an outlined key, lit).
  ApplianceFace asDisabled(ApplianceColors colors) {
    final mid = Color.lerp(colors.keyTop, colors.keyBottom, .5)!;
    final matte = mid.computeLuminance() < colors.face.computeLuminance()
        ? mid
        : colors.face;
    return copyWith(
      top: matte,
      bottom: matte,
      lift: 0,
      seam: .6,
      travel: 0,
      foreground: colors.printDisabled,
    );
  }

  /// A copy with the given values replaced.
  ApplianceFace copyWith({
    Color? top,
    Color? bottom,
    double? lift,
    double? seam,
    double? travel,
    BorderRadius? radius,
    RawCorners? corners,
    BorderRadiusGeometry? borderRadius,
    bool? circle,
    Color? foreground,
    Color? focus,
    double? focusReach,
    Color? edge,
  }) => ApplianceFace(
    top: top ?? this.top,
    bottom: bottom ?? this.bottom,
    lift: lift ?? this.lift,
    seam: seam ?? this.seam,
    travel: travel ?? this.travel,
    radius: radius ?? this.radius,
    corners: corners ?? this.corners,
    borderRadius: borderRadius ?? this.borderRadius,
    circle: circle ?? this.circle,
    foreground: foreground ?? this.foreground,
    focus: focus ?? this.focus,
    focusReach: focusReach ?? this.focusReach,
    edge: edge ?? this.edge,
  );

  // Its corners as radii, for a lerp that moves them one by one.
  BorderRadiusGeometry get _radii => borderRadius ?? radius;

  // A full round end (`double.infinity`) as a radius past any part's half,
  // so a corner eases to and from it instead of failing the lerp.
  static BorderRadiusGeometry _finite(BorderRadiusGeometry r) {
    Radius f(Radius c) =>
        Radius.elliptical(math.min(c.x, _roundEnd), math.min(c.y, _roundEnd));
    return switch (r) {
      BorderRadius() => BorderRadius.only(
        topLeft: f(r.topLeft),
        topRight: f(r.topRight),
        bottomLeft: f(r.bottomLeft),
        bottomRight: f(r.bottomRight),
      ),
      BorderRadiusDirectional() => BorderRadiusDirectional.only(
        topStart: f(r.topStart),
        topEnd: f(r.topEnd),
        bottomStart: f(r.bottomStart),
        bottomEnd: f(r.bottomEnd),
      ),
      _ => r,
    };
  }

  static const double _roundEnd = 1000;

  /// This face with its [corners] drawn at [theme]'s, laid in [direction]:
  /// each step held to [ApplianceThemeData.shapeLimits] (in debug a step
  /// moved is said once) and set at [ApplianceThemeData.shapeScheme]'s
  /// radius, as [borderRadius]. A face with no [corners], or one whose
  /// [borderRadius] is given, is itself. [ApplianceSurface] calls it, so a
  /// part only names the steps.
  ApplianceFace resolveCorners(
    ApplianceThemeData theme, [
    TextDirection direction = TextDirection.ltr,
  ]) {
    final asked = corners;
    if (asked == null) return this;
    if (borderRadius != null) return _withCorners(borderRadius);
    final held = ApplianceThemeData.shapeLimits.clampCorners(
      asked,
      base: const RawCorners(),
      look: 'Appliance',
    );
    final scale = theme.shapeScheme.corners;
    final ltr = direction == TextDirection.ltr;
    Radius at(RawCorner? step, Radius own) => switch (step) {
      null => own,
      RawCorner.none => Radius.zero,
      RawCorner.extraSmall => Radius.circular(scale.extraSmall),
      RawCorner.small => Radius.circular(scale.small),
      RawCorner.medium => Radius.circular(scale.medium),
      RawCorner.large => Radius.circular(scale.large),
      RawCorner.extraLarge => Radius.circular(scale.extraLarge),
      RawCorner.full => const Radius.circular(double.infinity),
    };
    return _withCorners(
      BorderRadiusDirectional.only(
        topStart: at(held.topStart, ltr ? radius.topLeft : radius.topRight),
        topEnd: at(held.topEnd, ltr ? radius.topRight : radius.topLeft),
        bottomStart: at(
          held.bottomStart,
          ltr ? radius.bottomLeft : radius.bottomRight,
        ),
        bottomEnd: at(
          held.bottomEnd,
          ltr ? radius.bottomRight : radius.bottomLeft,
        ),
      ),
    );
  }

  ApplianceFace _withCorners(BorderRadiusGeometry? radii) => ApplianceFace(
    top: top,
    bottom: bottom,
    lift: lift,
    seam: seam,
    travel: travel,
    radius: radius,
    borderRadius: radii,
    circle: circle,
    foreground: foreground,
    focus: focus,
    focusReach: focusReach,
    edge: edge,
  );

  /// Between [a] and [b] by [t].
  static ApplianceFace lerp(ApplianceFace a, ApplianceFace b, double t) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
    double at(double x, double y) => x + (y - x) * t;
    return ApplianceFace(
      top: Color.lerp(a.top, b.top, t)!,
      bottom: Color.lerp(a.bottom, b.bottom, t)!,
      lift: at(a.lift, b.lift),
      seam: at(a.seam, b.seam),
      travel: at(a.travel, b.travel),
      radius: BorderRadius.lerp(a.radius, b.radius, t)!,
      corners: t < 0.5 ? a.corners : b.corners,
      borderRadius: a.borderRadius == null && b.borderRadius == null
          ? null
          : BorderRadiusGeometry.lerp(_finite(a._radii), _finite(b._radii), t),
      circle: t < 0.5 ? a.circle : b.circle,
      foreground: Color.lerp(a.foreground, b.foreground, t)!,
      focus: Color.lerp(a.focus, b.focus, t)!,
      focusReach: at(a.focusReach, b.focusReach),
      edge: Color.lerp(a.edge, b.edge, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ApplianceFace &&
      other.top == top &&
      other.bottom == bottom &&
      other.lift == lift &&
      other.seam == seam &&
      other.travel == travel &&
      other.radius == radius &&
      other.corners == corners &&
      other.borderRadius == borderRadius &&
      other.circle == circle &&
      other.foreground == foreground &&
      other.focus == focus &&
      other.focusReach == focusReach &&
      other.edge == edge;

  @override
  int get hashCode => Object.hash(
    top,
    bottom,
    lift,
    seam,
    travel,
    radius,
    corners,
    borderRadius,
    circle,
    foreground,
    focus,
    focusReach,
    edge,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('top', top))
      ..add(ColorProperty('bottom', bottom))
      ..add(DoubleProperty('lift', lift))
      ..add(DoubleProperty('seam', seam, defaultValue: 0))
      ..add(DoubleProperty('travel', travel, defaultValue: 0))
      ..add(ColorProperty('focus', focus, defaultValue: _clear))
      ..add(DoubleProperty('focusReach', focusReach, defaultValue: 0))
      ..add(
        DiagnosticsProperty<RawCorners>('corners', corners, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<BorderRadiusGeometry>(
          'borderRadius',
          borderRadius,
          defaultValue: null,
        ),
      );
  }
}

/// [child] on a moulded [face]: the plastic, its depth's light and shade,
/// its parting line, its focus backlight. The legend moves with a press.
///
/// ```dart
/// ApplianceSurface(face: ApplianceFace.key(colors), child: const Text('Start'))
/// ```
class ApplianceSurface extends StatelessWidget {
  /// [child] on [face].
  const ApplianceSurface({super.key, required this.face, this.child});

  /// How the part looks now.
  final ApplianceFace face;

  /// What stands on the face.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final face = this.face.resolveCorners(theme, direction);
    final contrast = MediaQuery.maybeHighContrastOf(context) ?? false;
    return CustomPaint(
      painter: _FacePainter(face, theme.colors, contrast, direction),
      child: child == null
          ? null
          : Transform.translate(
              offset: Offset(0, face.travel * ApplianceMetrics.pressTravel),
              child: IconTheme.merge(
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
    properties.add(DiagnosticsProperty<ApplianceFace>('face', face));
  }
}

class _FacePainter extends CustomPainter {
  _FacePainter(this.face, this.colors, this.contrast, this.direction);

  final ApplianceFace face;
  final ApplianceColors colors;
  final bool contrast;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    paintApplianceFace(
      canvas,
      Offset.zero & size,
      face,
      colors,
      contrast,
      direction,
    );
  }

  @override
  bool shouldRepaint(_FacePainter old) =>
      old.face != face ||
      old.colors != colors ||
      old.contrast != contrast ||
      old.direction != direction;
}

/// Paints [face] filling [rect] on [canvas] in [colors]: what
/// [ApplianceSurface] draws, for a part that paints its own (a switch's cap,
/// a selector's block). Under high [contrast] the edges darken. A face's own
/// corners ([ApplianceFace.borderRadius]) are laid in [textDirection]: a
/// start corner is the left one in left-to-right text.
void paintApplianceFace(
  Canvas canvas,
  Rect rect,
  ApplianceFace face,
  ApplianceColors colors, [
  bool contrast = false,
  TextDirection textDirection = TextDirection.ltr,
]) {
  final own = face.borderRadius;
  final r = face.circle
      ? RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide / 2))
      : own != null
      ? applianceCornerRect(rect, own, textDirection)
      : face.radius.toRRect(rect);
  final night = colors.brightness == Brightness.dark;
  final shade = colors.shade;
  final raised = math.max(face.lift, 0.0);
  final sunk = math.max(-face.lift, 0.0);

  // A faceplate's parting line: a shaded groove round it and a lit lip
  // under the groove.
  if (face.seam > 0) {
    final groove = r.inflate(1.5);
    canvas.drawDRRect(
      groove.shift(const Offset(0, 1)),
      groove,
      Paint()..color = _scaled(colors.seamLight, face.seam),
    );
    canvas.drawDRRect(
      groove,
      r,
      Paint()
        ..color = _scaled(
          contrast ? colors.printMuted : colors.seamShade,
          face.seam,
        ),
    );
  }

  // A raised part's shade on the panel under it.
  if (raised > 0) {
    canvas
      ..drawRRect(
        r.shift(const Offset(0, 1.5)),
        Paint()
          ..color = shade.withValues(alpha: (night ? 0.3 : 0.12) * raised)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      )
      ..drawRRect(
        r.shift(const Offset(0, 1)),
        Paint()
          ..color = shade.withValues(alpha: (night ? 0.35 : 0.16) * raised)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5),
      );
  }

  // A sunken part's lit lip, just under its bottom edge.
  if (sunk > 0) {
    canvas.drawDRRect(
      r.shift(const Offset(0, 1)).inflate(0.5),
      r.inflate(0.5),
      Paint()..color = _scaled(colors.seamLight, sunk),
    );
  }

  // The plastic.
  canvas.drawRRect(
    r,
    Paint()
      ..shader = face.top == face.bottom
          ? null
          : ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
              face.top,
              face.bottom,
            ])
      ..color = face.top,
  );

  canvas
    ..save()
    ..clipRRect(r);
  if (raised > 0) {
    // The light on the top edge, the shade on the bottom one.
    canvas
      ..drawDRRect(
        r,
        r.shift(const Offset(0, 1)),
        Paint()..color = _scaled(colors.highlight, raised),
      )
      ..drawDRRect(
        r,
        r.shift(const Offset(0, -1)),
        Paint()..color = shade.withValues(alpha: (night ? 0.2 : 0.08) * raised),
      );
  }
  if (sunk > 0) {
    // The panel's edge shades the top of the well: a blurred ring round the
    // well's shape dropped a little, clipped to the well.
    canvas.drawDRRect(
      r.inflate(8),
      r.shift(const Offset(0, 1.2)),
      Paint()
        ..color = shade.withValues(alpha: (night ? 0.6 : 0.22) * sunk)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
    );
  }
  if (face.seam > 0) {
    // A faceplate's moulded top edge catches the light.
    canvas.drawDRRect(
      r,
      r.shift(const Offset(0, 1)),
      Paint()
        ..color = _scaled(colors.highlight, face.seam * (night ? 0.5 : 0.75)),
    );
  }
  canvas.restore();

  // The rim: a fine edge round a raised or sunken part, so plastic on
  // plastic still has an outline.
  final rimAlpha = raised * (night ? 0.5 : 0.26) + sunk * (night ? 0.4 : 0.24);
  if (rimAlpha > 0) {
    canvas.drawRRect(
      raised >= sunk ? r.inflate(0.5) : r.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = contrast
            ? colors.printMuted
            : shade.withValues(alpha: math.min(rimAlpha, 1)),
    );
  }
  if (face.edge.a > 0) {
    canvas.drawRRect(
      r.deflate(0.75),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = face.edge,
    );
  }

  // The fitted bezel catches one warm line of light along its inside edge.
  if (face.focus.a > 0) {
    final light = applianceFocusLight(
      face.focus,
      face.top,
      bottom: face.bottom,
      ink: face.foreground,
    );
    const w = ApplianceMetrics.focusWidth;
    final plate = face.focusReach > 0 ? r.inflate(face.focusReach) : r;
    canvas.drawRRect(
      plate.deflate(w / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = light,
    );
  }
}

/// The emitted light over a face running from [fill] to [bottom].
/// When the face or its legend [ink] is already bright, the emitter catches
/// a little more white light. The opacity of [focus] controls its intensity.
Color applianceFocusLight(
  Color focus,
  Color fill, {
  Color? bottom,
  Color? ink,
}) {
  final face = Color.lerp(fill, bottom ?? fill, 0.5)!;
  final bright = ink != null && ink.computeLuminance() > 0.8;
  final warmth = face.computeLuminance() > 0.45 || bright ? 0.4 : 0.22;
  return Color.lerp(
    focus,
    const Color(0xFFFFE8BD),
    warmth,
  )!.withValues(alpha: focus.a);
}

Color _scaled(Color c, double by) =>
    c.withValues(alpha: c.a * by.clamp(0.0, 1.0));

/// [ApplianceSurface] that moves to each new [face] on a spring, from
/// wherever it stands: a key going down firmly ([ApplianceMotion.press]),
/// coming back up with a little give ([ApplianceMotion.release]); a focus or
/// a change of plastic on the lamp's spring. Under Reduce Motion every
/// spring is critically damped.
///
/// ```dart
/// AnimatedApplianceSurface(face: pressed ? ApplianceFace.keyDown(colors) : ApplianceFace.key(colors), child: const Text('Start'))
/// ```
class AnimatedApplianceSurface extends StatefulWidget {
  /// [child] on a face that moves to [face].
  const AnimatedApplianceSurface({
    super.key,
    required this.face,
    this.child,
    this.control = true,
  });

  /// The face to arrive at.
  final ApplianceFace face;

  /// Whether it is a control's face (a key, a well) or a surface whose
  /// contents are read on their own (a faceplate, a row). A control's face
  /// is marked as one item ([RawKeylineFace]) for the layout checks in
  /// `package:ui_core_test`; the mark lays out and paints nothing.
  final bool control;

  /// What stands on the face.
  final Widget? child;

  @override
  State<AnimatedApplianceSurface> createState() =>
      _AnimatedApplianceSurfaceState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ApplianceFace>('face', face));
  }
}

class _AnimatedApplianceSurfaceState extends State<AnimatedApplianceSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  late ApplianceFace _from = widget.face;
  late ApplianceFace _to = widget.face;

  // Both ends drawn at the theme's corners, so a part's own corners ease
  // with the rest of the face and follow a change of shapeScheme.
  ApplianceFace _now(ApplianceThemeData theme, TextDirection direction) =>
      ApplianceFace.lerp(
        _from.resolveCorners(theme, direction),
        _to.resolveCorners(theme, direction),
        _t.value,
      );

  @override
  void didUpdateWidget(AnimatedApplianceSurface old) {
    super.didUpdateWidget(old);
    if (widget.face == _to) return;
    final going = widget.face;
    final down = going.lift < _to.lift || going.travel > _to.travel;
    final up = going.lift > _to.lift || going.travel < _to.travel;
    _from = _now(
      ApplianceTheme.of(context),
      Directionality.maybeOf(context) ?? TextDirection.ltr,
    );
    _to = going;
    final policy = RawMotionPolicy.of(context);
    final token = down
        ? ApplianceMotion.press
        : up
        ? ApplianceMotion.release
        : ApplianceMotion.lamp;
    _t
      ..value = 0
      ..springTo(
        1,
        down || up
            ? policy.spatial(
                dampingRatio: token.dampingRatio,
                stiffness: token.stiffness,
              )
            : policy.effects(
                dampingRatio: token.dampingRatio,
                stiffness: token.stiffness,
              ),
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
    builder: (context, child) {
      final surface = ApplianceSurface(
        face: _now(
          ApplianceTheme.of(context),
          Directionality.maybeOf(context) ?? TextDirection.ltr,
        ),
        child: child,
      );
      return widget.control ? RawKeylineFace(child: surface) : surface;
    },
    child: widget.child,
  );
}

/// The grained plastic every bar, panel surround and page is moulded in: a
/// gradient from [ApplianceColors.housingTop] to
/// [ApplianceColors.housingBottom] under a fine grain, painted once and
/// tiled. Content never sits on it directly: it sits on a faceplate. The
/// grain goes under the platform's high contrast and with
/// [ApplianceThemeData.texture] off.
///
/// [seam] draws a parting line on that edge (a top bar's bottom, a bottom
/// bar's top, a side panel's end).
///
/// ```dart
/// ApplianceHousing(seam: AxisDirection.down, child: bar)
/// ```
class ApplianceHousing extends StatefulWidget {
  /// [child] on the housing.
  const ApplianceHousing({super.key, this.seam, this.child});

  /// The edge a parting line runs along, if any.
  final AxisDirection? seam;

  /// What stands on it.
  final Widget? child;

  @override
  State<ApplianceHousing> createState() => _ApplianceHousingState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      EnumProperty<AxisDirection>('seam', seam, defaultValue: null),
    );
  }
}

class _ApplianceHousingState extends State<ApplianceHousing> {
  // One grain tile for every housing on screen, drawn when the first comes
  // and let go when the last goes.
  ui.Image? _grain;

  ui.Image get _tile => _grain ??= _GrainTile.acquire();

  @override
  void dispose() {
    if (_grain != null) _GrainTile.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final contrast = MediaQuery.maybeHighContrastOf(context) ?? false;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _HousingPainter(
          colors: theme.colors,
          grain: theme.texture && !contrast ? _tile : null,
          seam: widget.seam,
          rtl: Directionality.maybeOf(context) == TextDirection.rtl,
          contrast: contrast,
        ),
        child: widget.child,
      ),
    );
  }
}

class _HousingPainter extends CustomPainter {
  _HousingPainter({
    required this.colors,
    required this.grain,
    required this.seam,
    required this.rtl,
    required this.contrast,
  });

  final ApplianceColors colors;
  final ui.Image? grain;
  final AxisDirection? seam;
  final bool rtl;
  final bool contrast;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
          colors.housingTop,
          colors.housingBottom,
        ]),
    );
    final tile = grain;
    if (tile != null) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ImageShader(
            tile,
            TileMode.repeated,
            TileMode.repeated,
            Matrix4.diagonal3Values(0.5, 0.5, 1).storage,
          )
          ..color = Color.fromRGBO(
            0,
            0,
            0,
            colors.brightness == Brightness.dark ? 0.5 : 0.35,
          ),
      );
    }
    final edge = seam;
    if (edge == null) return;
    final dark = Paint()
      ..color = contrast ? colors.printMuted : colors.seamShade;
    final lit = Paint()..color = colors.seamLight;
    switch (edge) {
      case AxisDirection.down:
        canvas
          ..drawRect(Rect.fromLTWH(0, size.height - 2, size.width, 1), dark)
          ..drawRect(Rect.fromLTWH(0, size.height - 1, size.width, 1), lit);
      case AxisDirection.up:
        canvas
          ..drawRect(Rect.fromLTWH(0, 0, size.width, 1), dark)
          ..drawRect(Rect.fromLTWH(0, 1, size.width, 1), lit);
      case AxisDirection.right || AxisDirection.left:
        // The panel's end side, by reading direction.
        final atRight = (edge == AxisDirection.right) != rtl;
        final x = atRight ? size.width - 2 : 0.0;
        canvas
          ..drawRect(Rect.fromLTWH(x, 0, 1, size.height), atRight ? dark : lit)
          ..drawRect(
            Rect.fromLTWH(x + 1, 0, 1, size.height),
            atRight ? lit : dark,
          );
    }
  }

  @override
  bool shouldRepaint(_HousingPainter old) =>
      old.colors != colors ||
      old.grain != grain ||
      old.seam != seam ||
      old.rtl != rtl ||
      old.contrast != contrast;
}

// The moulded grain: a 128 px tile of fine speckle, light and dark, drawn
// once at twice its size and tiled, so it stays crisp on a dense screen and
// costs nothing on scroll. Counted: drawn for the first housing, disposed
// with the last.
abstract final class _GrainTile {
  static ui.Image? _image;
  static int _users = 0;

  static ui.Image acquire() {
    _users++;
    return _image ??= _draw();
  }

  static void release() {
    if (--_users > 0) return;
    _image?.dispose();
    _image = null;
  }
}

ui.Image _draw() {
  const size = 256;
  final random = math.Random(7);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  List<double> speckle(int count) => [
    for (var i = 0; i < count; i++) ...[
      random.nextInt(size) + 0.5,
      random.nextInt(size) + 0.5,
    ],
  ];
  canvas
    ..drawRawPoints(
      ui.PointMode.points,
      Float32List.fromList(speckle(9000)),
      Paint()
        ..strokeWidth = 1
        ..color = const Color(0x1A000000),
    )
    ..drawRawPoints(
      ui.PointMode.points,
      Float32List.fromList(speckle(7000)),
      Paint()
        ..strokeWidth = 1
        ..color = const Color(0x24FFFFFF),
    );
  final picture = recorder.endRecording();
  final image = picture.toImageSync(size, size);
  picture.dispose();
  return image;
}

/// A small indicator lamp: lit in the signal colour (it glows, more so by
/// night) or out (a dark lens). It warms up and cools down on
/// [ApplianceMotion.lamp]'s spring. A lamp says nothing to a screen reader:
/// the part it belongs to says what it means.
///
/// ```dart
/// ApplianceLamp(lit: unread)
/// ```
class ApplianceLamp extends StatefulWidget {
  /// A lamp, [lit] or out.
  const ApplianceLamp({
    super.key,
    required this.lit,
    this.size = ApplianceMetrics.lampSize,
    this.color,
  });

  /// Whether it is on.
  final bool lit;

  /// Its diameter.
  final double size;

  /// Its light, the theme's signal when null.
  final Color? color;

  @override
  State<ApplianceLamp> createState() => _ApplianceLampState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('lit', value: lit, ifTrue: 'lit', ifFalse: 'out'))
      ..add(DoubleProperty('size', size));
  }
}

class _ApplianceLampState extends State<ApplianceLamp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    value: widget.lit ? 1 : 0,
  );

  @override
  void didUpdateWidget(ApplianceLamp old) {
    super.didUpdateWidget(old);
    if (old.lit == widget.lit) return;
    _t.springTo(
      widget.lit ? 1 : 0,
      RawMotionPolicy.of(context).effects(
        dampingRatio: ApplianceMotion.lamp.dampingRatio,
        stiffness: ApplianceMotion.lamp.stiffness,
      ),
    );
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ApplianceTheme.of(context).colors;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, _) => CustomPaint(
            painter: _LampPainter(
              _t.value.clamp(0.0, 1.0),
              widget.color ?? colors.signal,
              colors,
            ),
          ),
        ),
      ),
    );
  }
}

class _LampPainter extends CustomPainter {
  _LampPainter(this.lit, this.light, this.colors);

  final double lit;
  final Color light;
  final ApplianceColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final night = colors.brightness == Brightness.dark;
    if (lit > 0) {
      canvas.drawCircle(
        c,
        r * 1.4,
        Paint()
          ..color = light.withValues(alpha: (night ? 0.55 : 0.4) * lit)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.9),
      );
    }
    final hot = HSLColor.fromColor(light);
    final lens = [
      Color.lerp(
        colors.lampOff,
        hot.withLightness(math.min(0.95, hot.lightness + 0.42)).toColor(),
        lit,
      )!,
      Color.lerp(colors.lampOff, light, lit)!,
      Color.lerp(
        Color.lerp(colors.lampOff, colors.shade, 0.25)!,
        hot.withLightness(math.max(0.2, hot.lightness - 0.12)).toColor(),
        lit,
      )!,
    ];
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          c.translate(-r * 0.1, -r * 0.25),
          r * 1.1,
          lens,
          const [0, 0.55, 1],
        ),
    );
    // An unlit lens sits in a little well: shaded along its top.
    canvas.drawCircle(
      c,
      r - 0.25,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = colors.shade.withValues(alpha: (night ? 0.5 : 0.25)),
    );
  }

  @override
  bool shouldRepaint(_LampPainter old) =>
      old.lit != lit || old.light != light || old.colors != colors;
}

/// A part's style layers put on an [ApplianceFace]: the style's `fill` (the
/// plastic, top and bottom), its `foreground` (the legend), its `edge` or
/// its `side`'s colour (a fine edge over the rim). The depth, the light and
/// the corners stay the look's.
extension ApplianceStyleFace on RawStyleOf {
  /// [face] in these layers' colours.
  ///
  /// A `corners` names each corner's step (drawn at the theme's scale where
  /// the face is drawn, [ApplianceFace.resolveCorners]); a `shape` gives
  /// the corners as they are and wins.
  ///
  /// A part that keeps its own form whatever its style asks (a switch's slot,
  /// a slider's thumb, an avatar's disc, a key inside a composite whose
  /// outer corners take the style's) passes [corners] false.
  ApplianceFace on(ApplianceFace face, {bool corners = true}) {
    final fill = this.fill;
    final foreground = this.foreground;
    final edge = side?.color ?? this.edge;
    final own = corners ? this.corners : null;
    final radii = corners ? applianceRadiiOf(shape) : null;
    if (fill == null &&
        foreground == null &&
        edge == null &&
        own == null &&
        radii == null) {
      return face;
    }
    return face.copyWith(
      top: fill,
      bottom: fill,
      foreground: foreground,
      edge: edge,
      corners: own,
      borderRadius: radii,
    );
  }

  /// [base] with these layers' `textStyle` over it.
  TextStyle text(TextStyle base) => base.merge(textStyle);
}
