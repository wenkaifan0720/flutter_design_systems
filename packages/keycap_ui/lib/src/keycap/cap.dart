/// Keycap's materials, as public primitives a page can build with: the
/// sculpted cap ([KeycapCap], [AnimatedKeycapCap], drawn from a
/// [KeycapFace]), the well cut into the case ([KeycapWell]) and the panel of
/// keycap plastic laid over the keyboard ([KeycapPanel]).
library;

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'theme.dart';

/// How much of a cap's walls shows round its top face: the sides, the back
/// (a sliver, it leans away) and the front (the most: the eye looks down at
/// it). [KeycapMetrics.walls] gives them for a key's height.
typedef KeycapWalls = ({double side, double back, double front});

/// A cap at one moment: its plastic, its legend, how far it has travelled
/// down onto its switch, and the light round its foot. Parts compute one per
/// state; [AnimatedKeycapCap] springs between them.
@immutable
class KeycapFace with Diagnosticable {
  /// A cap's every quality given.
  const KeycapFace({
    required this.top,
    required this.wall,
    required this.front,
    required this.legend,
    required this.edge,
    required this.shadow,
    this.backlight = const Color(0x00000000),
    this.focus = const Color(0x00000000),
    this.radius = KeycapMetrics.keyRadius,
    this.travel = 0,
    this.sculpt = 1,
  });

  /// A key moulded in [colors], at rest: its plastic, its legend, its edge,
  /// its shadow on the case.
  ///
  /// ```dart
  /// final face = KeycapFace.of(theme.colors.alpha, theme.colors);
  /// ```
  factory KeycapFace.of(KeycapCapColors cap, KeycapColors colors) => KeycapFace(
    top: cap.top,
    wall: cap.wall,
    front: cap.front,
    legend: cap.legend,
    edge: colors.edge,
    shadow: colors.shadow.withValues(
      alpha: colors.brightness == Brightness.light ? 0.22 : 0.55,
    ),
  );

  /// The dished top face.
  final Color top;

  /// The side and back walls.
  final Color wall;

  /// The front wall.
  final Color front;

  /// The legend: the words and glyphs printed on the top face.
  final Color legend;

  /// The fine edge round the cap's foot.
  final Color edge;

  /// The shadow the cap casts on the case (clear: none).
  final Color shadow;

  /// The light under a backlit cap, showing round its foot.
  final Color backlight;

  /// The focus band round the cap's foot (clear when not focused).
  final Color focus;

  /// The corner of the cap's foot.
  final double radius;

  /// How far down the cap has gone: 0 at rest, 1 bottomed out, 0.55 latched.
  final double travel;

  /// How much of the cap's moulding shows: 1 sculpted, its dish shaded and
  /// its rim drawn; 0 a level, matte plate, as a key out of use stands.
  final double sculpt;

  /// A copy with the given qualities replaced.
  KeycapFace copyWith({
    Color? top,
    Color? wall,
    Color? front,
    Color? legend,
    Color? edge,
    Color? shadow,
    Color? backlight,
    Color? focus,
    double? radius,
    double? travel,
    double? sculpt,
  }) => KeycapFace(
    top: top ?? this.top,
    wall: wall ?? this.wall,
    front: front ?? this.front,
    legend: legend ?? this.legend,
    edge: edge ?? this.edge,
    shadow: shadow ?? this.shadow,
    backlight: backlight ?? this.backlight,
    focus: focus ?? this.focus,
    radius: radius ?? this.radius,
    travel: travel ?? this.travel,
    sculpt: sculpt ?? this.sculpt,
  );

  /// This cap off: a level, matte plate of its top's plastic faded toward
  /// [ground], with no moulding, no shadow and no travel, its legend [ink].
  /// It keeps its shape and its size, and is never brighter than a cap in
  /// use.
  KeycapFace disabled(Color ground, Color ink) {
    final plate = Color.lerp(top, ground, 0.55)!;
    return copyWith(
      top: plate,
      wall: plate,
      front: plate,
      legend: ink,
      shadow: shadow.withValues(alpha: 0),
      backlight: backlight.withValues(alpha: 0),
      travel: 0,
      sculpt: 0,
    );
  }

  /// Between [a] and [b] by [t].
  static KeycapFace lerp(KeycapFace a, KeycapFace b, double t) {
    if (identical(a, b)) return a;
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    return KeycapFace(
      top: c(a.top, b.top),
      wall: c(a.wall, b.wall),
      front: c(a.front, b.front),
      legend: c(a.legend, b.legend),
      edge: c(a.edge, b.edge),
      shadow: c(a.shadow, b.shadow),
      backlight: c(a.backlight, b.backlight),
      focus: c(a.focus, b.focus),
      radius: lerpDouble(a.radius, b.radius, t)!,
      travel: lerpDouble(a.travel, b.travel, t)!,
      sculpt: lerpDouble(a.sculpt, b.sculpt, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is KeycapFace &&
      other.top == top &&
      other.wall == wall &&
      other.front == front &&
      other.legend == legend &&
      other.edge == edge &&
      other.shadow == shadow &&
      other.backlight == backlight &&
      other.focus == focus &&
      other.radius == radius &&
      other.travel == travel &&
      other.sculpt == sculpt;

  @override
  int get hashCode => Object.hash(
    top,
    wall,
    front,
    legend,
    edge,
    shadow,
    backlight,
    focus,
    radius,
    travel,
    sculpt,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('top', top))
      ..add(ColorProperty('legend', legend))
      ..add(DoubleProperty('travel', travel))
      ..add(DoubleProperty('sculpt', sculpt, defaultValue: 1));
  }
}

/// Lays a part's `style:` over a face it computed: [RawStyle.fill]
/// recolours the cap's plastic (its walls shaded from it),
/// [RawStyle.foreground] its legend, [RawStyle.edge] its edge and a
/// `RoundedRectangleBorder` [RawStyle.shape] its corner.
extension KeycapStyleFace on RawStyleOf {
  /// [face] with this style's slots laid over it.
  KeycapFace on(KeycapFace face) {
    final fill = this.fill;
    final shape = this.shape;
    var out = face;
    if (fill != null) {
      out = out.copyWith(
        top: fill,
        wall: Color.lerp(fill, const Color(0xFF000000), 0.12),
        front: Color.lerp(fill, const Color(0xFF000000), 0.28),
      );
    }
    final fg = foreground;
    if (fg != null) out = out.copyWith(legend: fg);
    final e = edge;
    if (e != null) out = out.copyWith(edge: e);
    if (shape is RoundedRectangleBorder) {
      final r = shape.borderRadius.resolve(TextDirection.ltr).topLeft.x;
      out = out.copyWith(radius: r);
    } else if (shape is StadiumBorder) {
      out = out.copyWith(radius: 999);
    }
    return out;
  }
}

/// A sculpted keycap drawn as [face] says, its legend ([child]) on the
/// dished top face. The cap fills its box; its walls take [walls] of it on
/// every side, the front the most; as it travels down the cap sinks into the
/// case, its top face and the legend with it: the front wall shortens and
/// the side walls narrow.
///
/// ```dart
/// KeycapCap(face: KeycapFace.of(colors.alpha, colors), walls: KeycapMetrics.walls(48), child: const Text('Save'))
/// ```
class KeycapCap extends StatelessWidget {
  /// A cap at [face], [child] on its top face.
  const KeycapCap({
    super.key,
    required this.face,
    required this.walls,
    this.child,
  });

  /// The cap's look at this moment.
  final KeycapFace face;

  /// How much of each wall shows at rest.
  final KeycapWalls walls;

  /// The legend.
  final Widget? child;

  /// How far a bottomed-out cap's top face sinks, for [walls]: half its
  /// front wall.
  static double depth(KeycapWalls walls) => walls.front * 0.5;

  @override
  Widget build(BuildContext context) {
    final dy = face.travel * depth(walls);
    return CustomPaint(
      painter: _CapPainter(face, walls, Directionality.of(context)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          walls.side,
          walls.back,
          walls.side,
          walls.front,
        ),
        child: Transform.translate(
          offset: Offset(0, dy),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: face.legend),
            child: IconTheme.merge(
              data: IconThemeData(color: face.legend),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<KeycapFace>('face', face));
  }
}

/// [KeycapCap] springing to each new [face]: down onto its switch crisply
/// ([KeycapMotion.press]), back up without a bounce ([KeycapMotion.release]),
/// into a latch and out of it calmly ([KeycapMotion.latch]); every colour
/// on the same spring. Reduce Motion damps them all.
///
/// ```dart
/// AnimatedKeycapCap(face: pressed ? down : up, walls: walls, child: label)
/// ```
class AnimatedKeycapCap extends StatefulWidget {
  /// A cap moving to [face].
  const AnimatedKeycapCap({
    super.key,
    required this.face,
    required this.walls,
    this.child,
  });

  /// Where the cap is going.
  final KeycapFace face;

  /// How much of each wall shows at rest.
  final KeycapWalls walls;

  /// The legend.
  final Widget? child;

  @override
  State<AnimatedKeycapCap> createState() => _AnimatedKeycapCapState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<KeycapFace>('face', face));
  }
}

class _AnimatedKeycapCapState extends State<AnimatedKeycapCap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this)
    ..value = 1;
  late KeycapFace _from = widget.face;
  late KeycapFace _to = widget.face;

  KeycapFace get _now =>
      _t.value >= 1 ? _to : KeycapFace.lerp(_from, _to, _t.value);

  @override
  void didUpdateWidget(AnimatedKeycapCap old) {
    super.didUpdateWidget(old);
    if (widget.face == _to) return;
    final now = _now;
    final down = widget.face.travel > now.travel + 0.01;
    final up = widget.face.travel < now.travel - 0.01;
    final s = down && widget.face.travel >= 0.9
        ? KeycapMotion.press
        : up && now.travel >= 0.9 && widget.face.travel < 0.1
        ? KeycapMotion.release
        : down || up
        ? KeycapMotion.latch
        : KeycapMotion.colour;
    _from = now;
    _to = widget.face;
    final policy = RawMotionPolicy.of(context);
    _t
      ..value = 0
      ..springTo(
        1,
        policy.spatial(dampingRatio: s.dampingRatio, stiffness: s.stiffness),
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
    builder: (context, child) =>
        KeycapCap(face: _now, walls: widget.walls, child: child),
  );
}

class _CapPainter extends CustomPainter {
  _CapPainter(this.face, this.walls, this.direction);

  final KeycapFace face;
  final KeycapWalls walls;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final f = face;
    final travel = f.travel.clamp(0.0, 1.0);
    final dy = f.travel * KeycapCap.depth(walls);
    final lift = 1 - travel;
    final r = math.min(f.radius, math.min(size.width, size.height) / 2);
    // The cap sinks into the case as it travels: its foot's top comes down
    // with its top face, so the front wall shortens by as much, and the side
    // walls narrow as the skirt goes below the plate.
    final side = walls.side * (1 - 0.3 * travel);
    final foot = RRect.fromRectAndRadius(
      Rect.fromLTRB(0, dy, size.width, size.height),
      Radius.circular(r),
    );
    final faceRect = Rect.fromLTRB(
      side,
      walls.back + dy,
      size.width - side,
      size.height - walls.front + dy,
    );

    // The backlight, under a lit cap by night.
    if (f.backlight.a > 0) {
      canvas.drawRRect(
        foot.inflate(1),
        Paint()
          ..color = f.backlight
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }
    // Its shadow on the case: wider at rest, tight on the switch.
    if (f.shadow.a > 0) {
      canvas.drawRRect(
        foot.shift(Offset(0, 0.8 + 1.4 * lift)),
        Paint()
          ..color = f.shadow.withValues(alpha: f.shadow.a * (0.5 + lift * 0.5))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1 + lift * 1.8),
      );
    }

    // The skirt: the side walls, the back catching the light and the deep
    // front, meeting at the corners along the diagonals as moulded walls do.
    canvas.save();
    canvas.clipRRect(foot);
    canvas.drawRect(foot.outerRect, Paint()..color = f.wall);
    canvas.drawPath(
      Path()
        ..moveTo(0, dy)
        ..lineTo(size.width, dy)
        ..lineTo(faceRect.right, faceRect.top)
        ..lineTo(faceRect.left, faceRect.top)
        ..close(),
      Paint()..color = Color.lerp(f.top, f.wall, 0.35)!,
    );
    canvas.drawPath(
      Path()
        ..moveTo(faceRect.left, faceRect.bottom)
        ..lineTo(faceRect.right, faceRect.bottom)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              // Darkened in the front's own opacity: a clear cap (a place
              // not chosen) leaves no shadow of a skirt on the case.
              colors: [
                Color.lerp(f.front, f.top, 0.18)!,
                Color.lerp(
                  f.front,
                  const Color(0xFF000000),
                  0.06 * f.sculpt,
                )!.withValues(alpha: f.front.a),
              ],
            ).createShader(
              Rect.fromLTRB(0, faceRect.bottom, size.width, size.height),
            ),
    );
    canvas.restore();

    // The dished top face, smaller than the skirt: shaded under the back
    // rim, lighter toward the front where the dish turns up to the light,
    // and shaded softly all round its edge where it curves down. Every shade
    // keeps the plastic's own opacity, so a clear cap (a place in the
    // navigation that is not current) stays clear.
    final faceR = math.max(3.0, r - side * 0.6);
    final top = RRect.fromRectAndRadius(faceRect, Radius.circular(faceR));
    final dark = f.top.computeLuminance() < 0.2;
    canvas.drawRRect(
      top,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(
              f.top,
              const Color(0xFF000000),
              (dark ? 0.13 : 0.075) * f.sculpt,
            )!.withValues(alpha: f.top.a),
            f.top,
            // A small lift, the same on every plastic: a larger one turns a
            // coloured face glossy and convex.
            Color.lerp(
              f.top,
              const Color(0xFFFFFFFF),
              (dark ? 0.06 : 0.10) * f.sculpt,
            )!.withValues(alpha: f.top.a),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(faceRect),
    );
    if (f.top.a > 0 && f.sculpt > 0) {
      canvas.save();
      canvas.clipRRect(top);
      canvas.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(faceRect.inflate(12))
          ..addRRect(top),
        Paint()
          ..color = const Color(0xFF000000)
              .withValues(alpha: (dark ? 0.16 : 0.10) * f.top.a * f.sculpt)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
      );
      canvas.restore();
    }
    // The rim where the face turns down into the walls.
    canvas.drawRRect(
      top.deflate(0.25),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = Color.lerp(
          f.wall,
          const Color(0xFF000000),
          0.12,
        )!.withValues(alpha: 0.43 * f.top.a * f.sculpt),
    );

    // The edge round the foot, a full pixel, so the cap's outline reads on
    // the case and in a well alike.
    if (f.edge.a > 0) {
      canvas.drawRRect(
        foot.deflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = f.edge,
      );
    }

    // Focus: a band of backlight round the cap's foot.
    if (f.focus.a > 0) {
      const w = KeycapMetrics.focusWidth;
      final ring = foot.inflate(KeycapMetrics.focusGap + w / 2);
      canvas.drawRRect(
        ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..color = f.focus,
      );
    }
  }

  @override
  bool shouldRepaint(_CapPainter old) =>
      old.face != face || old.walls != walls || old.direction != direction;
}

/// An opening cut into the case: where a group of rows, a card or a field's
/// words sit. A small well's floor (a field's, a search's, a track's) is a
/// shade darker than the case, by day and by night, so it never reads as a
/// card; a [page] (a large well read or written in) is floored with
/// [KeycapColors.page], the lightest surface. The plate's thickness shows as a hard
/// band along its top inside edge (no soft shadow: a hole in the plate, not
/// a tray) and its bottom edge catches the light. [floor] recolours it (a pressed
/// row), [rim] draws a band inside its edge (a focused field), both
/// springing as they change.
///
/// ```dart
/// KeycapWell(child: Column(children: rows))
/// ```
class KeycapWell extends StatelessWidget {
  /// A well round [child].
  const KeycapWell({
    super.key,
    this.child,
    this.radius,
    this.floor,
    this.rim,
    this.rimWidth = KeycapMetrics.focusWidth,
    this.padding = EdgeInsets.zero,
    this.style,
    this.clip = true,
    this.page = false,
  });

  /// What sits in the well.
  final Widget? child;

  /// Whether it is a page: a large well that is read or written in (a
  /// group of rows, a card, a table, a note's words), floored with
  /// [KeycapColors.page]. The rows in it press and latch in the page's
  /// colours ([isPage]).
  final bool page;

  /// Whether [context] sits in a page ([KeycapWell.page]), for a row to
  /// take the page's pressed and chosen floors.
  static bool isPage(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PageScope>()?.page ?? false;

  /// The well's corners; [KeycapMetrics.wellRadius] when null.
  final BorderRadiusGeometry? radius;

  /// The floor's colour; the theme's well when null.
  final Color? floor;

  /// A band inside the well's edge (a focused field's), or none.
  final Color? rim;

  /// The band's width.
  final double rimWidth;

  /// The room between the well's edge and [child].
  final EdgeInsetsGeometry padding;

  /// Overrides for the well: [RawStyle.fill] its floor,
  /// [RawStyle.edge] its edge, a `RoundedRectangleBorder`
  /// [RawStyle.shape] its corners.
  final KeycapStyle? style;

  /// Whether [child] is clipped to the well's corners.
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.wellStyle], const {});
    final shape = layered.shape;
    final corners =
        (shape is RoundedRectangleBorder ? shape.borderRadius : null) ??
        radius ??
        BorderRadius.circular(KeycapMetrics.wellRadius);
    final resolved = corners.resolve(Directionality.of(context));
    final paint = _WellLook(
      floor: floor ?? layered.fill ?? (page ? c.page : c.well),
      shade: c.wellShade,
      lip: c.wellLip,
      edge: layered.edge ?? c.edge,
      rim: rim ?? c.focus.withValues(alpha: 0),
    );
    Widget inner = _PageScope(
      page: page,
      child: Padding(padding: padding, child: child),
    );
    if (clip) {
      inner = ClipRRect(borderRadius: resolved, child: inner);
    }
    return _AnimatedWell(
      look: paint,
      radius: resolved,
      rimWidth: rimWidth,
      child: inner,
    );
  }
}

class _PageScope extends InheritedWidget {
  const _PageScope({required this.page, required super.child});

  final bool page;

  @override
  bool updateShouldNotify(_PageScope old) => old.page != page;
}

class _AnimatedWell extends StatefulWidget {
  const _AnimatedWell({
    required this.look,
    required this.radius,
    required this.rimWidth,
    required this.child,
  });

  final _WellLook look;
  final BorderRadius radius;
  final double rimWidth;
  final Widget child;

  @override
  State<_AnimatedWell> createState() => _AnimatedWellState();
}

class _AnimatedWellState extends State<_AnimatedWell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this)
    ..value = 1;
  late _WellLook _from = widget.look;
  late _WellLook _to = widget.look;

  _WellLook get _now =>
      _t.value >= 1 ? _to : _WellLook.lerp(_from, _to, _t.value);

  @override
  void didUpdateWidget(_AnimatedWell old) {
    super.didUpdateWidget(old);
    if (widget.look == _to) return;
    _from = _now;
    _to = widget.look;
    const s = KeycapMotion.colour;
    _t
      ..value = 0
      ..springTo(
        1,
        RawMotionPolicy.of(context)
            .effects(dampingRatio: s.dampingRatio, stiffness: s.stiffness),
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
    builder: (context, child) {
      final look = _now;
      return CustomPaint(
        painter: _WellPainter(
          look,
          widget.radius,
          widget.rimWidth,
          under: true,
        ),
        foregroundPainter: _WellPainter(
          look,
          widget.radius,
          widget.rimWidth,
          under: false,
        ),
        child: child,
      );
    },
  );
}

@immutable
class _WellLook {
  const _WellLook({
    required this.floor,
    required this.shade,
    required this.lip,
    required this.edge,
    required this.rim,
  });

  final Color floor;
  final Color shade;
  final Color lip;
  final Color edge;
  final Color rim;

  static _WellLook lerp(_WellLook a, _WellLook b, double t) => _WellLook(
    floor: Color.lerp(a.floor, b.floor, t)!,
    shade: Color.lerp(a.shade, b.shade, t)!,
    lip: Color.lerp(a.lip, b.lip, t)!,
    edge: Color.lerp(a.edge, b.edge, t)!,
    rim: Color.lerp(a.rim, b.rim, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is _WellLook &&
      other.floor == floor &&
      other.shade == shade &&
      other.lip == lip &&
      other.edge == edge &&
      other.rim == rim;

  @override
  int get hashCode => Object.hash(floor, shade, lip, edge, rim);
}

class _WellPainter extends CustomPainter {
  _WellPainter(this.look, this.radius, this.rimWidth, {required this.under});

  final _WellLook look;
  final BorderRadius radius;
  final double rimWidth;
  final bool under;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final well = radius.toRRect(rect);
    if (under) {
      canvas.drawRRect(well, Paint()..color = look.floor);
      return;
    }
    canvas.save();
    canvas.clipRRect(well);
    // The plate's thickness, seen along the top inside edge of the cut: a
    // hard band, no soft shadow, so the opening reads as a hole cut in the
    // plate and never as a tray or a card.
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRRect(well)
        ..addRRect(well.shift(const Offset(0, KeycapMetrics.plateDepth))),
      Paint()..color = look.shade,
    );
    // The light caught along the bottom inside edge.
    final lip = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(12))
      ..addRRect(well.shift(const Offset(0, -1)));
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, size.height / 2, size.width, size.height));
    canvas.drawPath(lip, Paint()..color = look.lip);
    canvas.restore();
    canvas.restore();
    // The cut's edge, a hard pixel: darker along the top, lit along the
    // bottom.
    canvas.drawRRect(
      well.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(look.shade, look.edge),
            look.edge,
            Color.alphaBlend(look.lip, look.edge),
          ],
          stops: const [0, 0.35, 1],
        ).createShader(rect),
    );
    if (look.rim.a > 0) {
      canvas.drawRRect(
        well.deflate(rimWidth / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rimWidth
          ..color = look.rim,
      );
    }
  }

  @override
  bool shouldRepaint(_WellPainter old) =>
      old.look != look ||
      old.radius != radius ||
      old.rimWidth != rimWidth ||
      old.under != under;
}

/// A panel of keycap plastic laid over the keyboard: a dialog's, a sheet's,
/// a menu's. Flat, a fine edge, a soft shadow on the keys below.
///
/// ```dart
/// KeycapPanel(child: Padding(padding: const EdgeInsets.all(24), child: body))
/// ```
class KeycapPanel extends StatelessWidget {
  /// A panel under [child].
  const KeycapPanel({
    super.key,
    required this.child,
    this.radius,
    this.color,
    this.elevated = true,
  });

  /// What the panel holds.
  final Widget child;

  /// Its corners; [KeycapMetrics.panelRadius] on every corner when null.
  final BorderRadiusGeometry? radius;

  /// Its plastic; the theme's panel when null.
  final Color? color;

  /// Whether it casts its shadow (a sheet at the foot of the screen still
  /// does; a panel inside another does not).
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final c = KeycapTheme.of(context).colors;
    final corners = radius ?? BorderRadius.circular(KeycapMetrics.panelRadius);
    final light = c.brightness == Brightness.light;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? c.panel,
        borderRadius: corners,
        border: Border.all(color: c.edge, width: 0.5),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: c.shadow.withValues(alpha: light ? 0.14 : 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: c.shadow.withValues(alpha: light ? 0.10 : 0.4),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: corners.resolve(Directionality.of(context)),
        child: child,
      ),
    );
  }
}

/// The kinds of key in Keycap's colourway; each is moulded in its own
/// plastic, and a key's kind never changes with its state.
enum KeycapKind {
  /// A light key: a neutral control.
  alpha,

  /// A darker key: a secondary control.
  modifier,

  /// The one coloured key: a screen's main action.
  accent,

  /// A key that destroys something, in a dialog that confirms it.
  danger,
}

/// How far down a latched key sits: below its neighbours, above a pressed
/// one.
const double keycapLatchTravel = 0.55;

/// The face of a [kind] key in [theme] at [states]: pressed, it travels down
/// onto its switch; [latched], it sits part way down and is moulded in the
/// modifier plastic (an alpha's latch reads as a modifier's); off, it fades
/// toward the case and casts no shadow (a coloured key goes neutral first:
/// its colour says what it does, and a key that does nothing says nothing,
/// while its legend still reads); focused, its foot is ringed in the
/// focus backlight. [backlit] lets the accent's backlight show by night.
///
/// ```dart
/// final face = keycapKeyFace(theme, KeycapKind.accent, states);
/// ```
KeycapFace keycapKeyFace(
  KeycapThemeData theme,
  KeycapKind kind,
  Set<WidgetState> states, {
  bool latched = false,
  bool backlit = true,
  double? radius,
}) {
  final c = theme.colors;
  final off = states.contains(WidgetState.disabled);
  final cap = switch (kind) {
    KeycapKind.accent || KeycapKind.danger when off => c.alpha,
    KeycapKind.alpha => latched ? c.modifier : c.alpha,
    KeycapKind.modifier => c.modifier,
    KeycapKind.accent => c.accent,
    KeycapKind.danger => c.danger,
  };
  var face = KeycapFace.of(cap, c).copyWith(
    radius: radius ?? KeycapMetrics.keyRadius,
    focus: states.contains(WidgetState.focused)
        ? c.focus
        : c.focus.withValues(alpha: 0),
    backlight: backlit && theme.backlight && kind == KeycapKind.accent
        ? c.backlight
        : c.backlight.withValues(alpha: 0),
  );
  if (off) return face.disabled(c.ground, c.inkDisabled);
  final pressed = states.contains(WidgetState.pressed);
  if (pressed) {
    face = face.copyWith(travel: 1, top: Color.lerp(face.top, c.shadow, 0.035));
  }
  if (latched) {
    face = face.copyWith(
      travel: pressed ? 1 : keycapLatchTravel,
      legend: kind == KeycapKind.alpha || kind == KeycapKind.modifier
          ? c.latchedLegend
          : null,
    );
  }
  return face;
}
