import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../components/glass.dart';
import '../theme.dart';
import 'styled.dart';
import '../materials.dart';

export '../components/glass.dart' show FrostedOnGlass;
export '../materials.dart' show FrostedMaterial;

/// The edge a pane of glass wears, as the look draws it: by day the lit
/// hairline, white light along every side, never a dark line (a pane
/// stands apart by its blur, its fill and its shadow); by night [night],
/// the rim the night glass keeps.
Color frostedLitEdge(FrostedThemeData t, Color night) =>
    t.isDark ? night : FrostedChromeMetrics.litEdge;

/// The ink the keyboard's focus is drawn in: the theme's ring ink
/// ([FrostedColorScheme.ringOuter], the accent at 70%) by night, where it is
/// light, and by day where it has a hue; where by day it is the words' ink
/// (opal's, near black) the theme's cool blue ([FrostedColorScheme.cold]) at
/// the same strength. Glass shows focus as light, never as a dark line (the
/// user, 11-17: "a black focus border on a glass field: is this something a
/// glass would have?").
Color frostedFocusInk(FrostedThemeData t) {
  final ring = t.colorScheme.ringOuter;
  // Its hue's strength: the spread of its channels (opal's ink 0.03, every
  // coloured accent of the presets over 0.5).
  final chroma =
      [ring.r, ring.g, ring.b].reduce(math.max) -
      [ring.r, ring.g, ring.b].reduce(math.min);
  if (t.isDark || chroma >= .15) return ring;
  return t.colorScheme.cold.withValues(alpha: ring.a);
}

/// The keyboard focus's light ([FrostedFocusLight]): the focus ink's hue
/// made luminous and clear. By day a saturated tone of it, as light as it can
/// be and still stand 3:1 off the darkest of the theme's dawn (its ground and
/// its washes; on opal's a vivid blue, never slate: opal's near-black ink
/// falls back to the cool blue); by night a pale tone of it.
Color frostedFocusLight(FrostedThemeData t) {
  final ink = HSLColor.fromColor(frostedFocusInk(t).withValues(alpha: 1));
  final hue = ink.withSaturation(
    t.isDark ? math.min(ink.saturation, .9) : math.max(ink.saturation, .8),
  );
  final want = t.isDark ? .55 : (_darkestDawn(t) + .05) / 3.6 - .05;
  // Luminance rises with lightness: the lightest tone at most [want] by day,
  // the darkest at least [want] by night.
  var lo = 0.0, hi = 1.0;
  for (var i = 0; i < 24; i++) {
    final mid = (lo + hi) / 2;
    if (hue.withLightness(mid).toColor().computeLuminance() < want) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return hue.withLightness(t.isDark ? hi : lo).toColor();
}

// The luminance of the darkest place on the theme's dawn: its ground, or a
// wash of its light over it at its strongest.
double _darkestDawn(FrostedThemeData t) {
  final ground = t.colorScheme.background.withValues(alpha: 1);
  final l = t.lights;
  var least = ground.computeLuminance();
  for (final wash in [l.lilac, l.rose, l.peach]) {
    final at = wash.withValues(alpha: (wash.a * l.strength).clamp(0, 1));
    least = math.min(least, Color.alphaBlend(at, ground).computeLuminance());
  }
  return least;
}

/// The ink of a destructive act's word over its [tint] (the danger hue's
/// subtle share, over the page's ground): the theme's danger hue, moved
/// toward the words' ink until it holds 4.5:1 on the tint, day and night.
Color frostedDangerInk(FrostedThemeData t, Color tint) {
  final ground = Color.alphaBlend(
    tint,
    t.colorScheme.background.withValues(alpha: 1),
  );
  final hue = t.colorScheme.danger.withValues(alpha: 1);
  final words = t.colorScheme.textPrimary.withValues(alpha: 1);
  for (var k = 0.0; k <= 1; k += .05) {
    final ink = Color.lerp(hue, words, k)!;
    if (FrostedThemeData.contrast(ink, ground) >= 4.6) return ink;
  }
  return words;
}

/// The frost's brightening under a focused glass face: white by day, the
/// pale ink faintly by night.
Color frostedFocusWash(FrostedThemeData t) => t.isDark
    ? t.colorScheme.textPrimary.withValues(alpha: .10)
    : const Color(0x59FFFFFF);

/// The glass lit by the keyboard's focus, over a face [outline] filling the
/// paint's box: a bright core of [light] hugging the face's edge, a soft glow
/// of it fading out beyond (or, [inside], inward from the edge, kept within
/// the face), and a [rim] of light along the edge itself.
class FrostedFocusLight extends CustomPainter {
  /// Lights [outline]'s edge.
  const FrostedFocusLight(
    this.outline, {
    required this.light,
    required this.rim,
    this.inside = false,
  });

  /// The face's outline.
  final ShapeBorder outline;

  /// The glow's light.
  final Color light;

  /// The rim's light.
  final Color rim;

  /// Whether the glow runs inward, within the face.
  final bool inside;

  /// How far the bright core reaches from the edge.
  static const double core = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final face = Offset.zero & size;
    if (face.isEmpty) return;
    final edge = outline.getOuterPath(face);
    canvas.save();
    canvas.clipPath(
      inside
          ? edge
          : Path.combine(
              PathOperation.difference,
              Path()..addRect(face.inflate(48)),
              edge,
            ),
    );
    Paint band(double width, double blur, double alpha) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = light.withValues(alpha: light.a * alpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    // The glow, fading out to about 10 from the edge.
    canvas.drawPath(edge, band(16, 5, .45));
    // Its bright core along the edge; within a face, a little deeper, as
    // its rim takes less of it.
    canvas.drawPath(edge, band((inside ? core + 1 : core) * 2, 1.4, 1));
    canvas.restore();
    // The rim of the glass catching the light.
    final rimWidth = inside ? 1.0 : 1.5;
    canvas.drawPath(
      outline.getOuterPath(face.deflate(rimWidth / 2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rimWidth
        ..color = rim,
    );
  }

  @override
  bool shouldRepaint(FrostedFocusLight old) =>
      old.outline != outline ||
      old.light != light ||
      old.rim != rim ||
      old.inside != inside;
}

/// A field holding focus by day: the light its rim gives off, a soft
/// white glow round the well. White, not the focus ink: a tinted glow read
/// as a grey shadow on the dawn backdrop.
const List<BoxShadow> frostedFocusGlow = [
  BoxShadow(color: Color(0xF2FFFFFF), blurRadius: 12, spreadRadius: 1),
];

/// The frost a frosted face stands on, as CSS's `backdrop-filter: blur(24px)
/// saturate(130%)` draws a tile's: what is behind blurred, then saturated.
ui.ImageFilter frostedFrost({
  double blur = FrostedChromeMetrics.frostBlur,
  double saturation = FrostedChromeMetrics.frostSaturation,
}) => ui.ImageFilter.compose(
  outer: ui.ColorFilter.matrix(frostedSaturate(saturation)),
  inner: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
);

/// The colour matrix of CSS's `saturate(s)`.
List<double> frostedSaturate(double s) => <double>[
  0.213 + 0.787 * s,
  0.715 - 0.715 * s,
  0.072 - 0.072 * s,
  0,
  0,
  0.213 - 0.213 * s,
  0.715 + 0.285 * s,
  0.072 - 0.072 * s,
  0,
  0,
  0.213 - 0.213 * s,
  0.715 - 0.715 * s,
  0.072 + 0.928 * s,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

/// A face as the source's stylesheet draws one, in CSS's order: its outer
/// shadows (outside the face only, as CSS clips a box's shadow to outside
/// its border box, so a translucent face is never darkened by its own
/// shadow), its fill (a colour and gradients, the first painted first), the
/// light along its top inside edge ([sheen], `inset 0 1px 0`), a ring inside
/// its edge ([ring], `inset 0 0 0 1px`), its edge (1 wide on the [edges]
/// it has), then its child.
///
/// Its [material] decides what is under the fill. Paint is the fill alone.
/// Glass first blurs what is behind it inside its shape (sharing one read of
/// the backdrop with its neighbours under a `BackdropGroup` when it is a
/// sheer, pane or well; bars and slabs stand over other glass and read it
/// themselves), then lays the theme's tint; [color] and [gradients] are laid
/// over that, the recipe's sheen, rim and shadows stand where the face sets
/// none. Glass on glass is raised a step, not blurred twice; without
/// transparency it is the recipe's opaque fill.
///
/// When a state changes what it paints (a press, a hover, focus, a choice,
/// an error, day to night), the face eases from what it shows to the new
/// paint over [FrostedMotion.fast]: tint, fill, washes, edge, sheen, rim and
/// shadows together, the glass thickening and brightening, never springing.
/// A change that comes mid-way turns from where the face is; under Reduce
/// Motion it is a cut. Plumbing of the components; pages never place one.
class FrostedFace extends StatelessWidget {
  /// Creates a [FrostedFace].
  const FrostedFace({
    required this.material,
    required this.radius,
    this.shape,
    this.color,
    this.gradients = const <Gradient>[],
    this.wash,
    this.edge,
    this.edges = const EdgeInsets.all(FrostedChromeMetrics.outline),
    this.sheen,
    this.ring,
    this.shadows = const <BoxShadow>[],
    this.padding = EdgeInsets.zero,
    this.clipChild = false,
    this.child,
    super.key,
  });

  /// What the face is made of.
  final FrostedMaterial material;

  /// The face's corners.
  final BorderRadius radius;

  /// The face's outline when an app's style or the look's corners cut it to
  /// one: a rounded rectangle is drawn at its own corners in place of
  /// [radius]; any other border (a superellipse, a bevel, a stadium) is cut
  /// to its path. Null draws [radius].
  final OutlinedBorder? shape;

  /// A wash laid over the fill in a state (a style's overlay).
  final Color? wash;

  /// A flat fill under the [gradients].
  final Color? color;

  /// Gradient fills, the first painted first (CSS lists its layers the other
  /// way round, the top one first).
  final List<Gradient> gradients;

  /// The edge's colour; null draws none.
  final Color? edge;

  /// How wide the edge is on each side: 1 all round, or none on a side the
  /// face has none (a phone sheet's foot).
  final EdgeInsets edges;

  /// The light along the face's top inside edge.
  final Color? sheen;

  /// The ring just inside the face's edge.
  final Color? ring;

  /// The face's outer shadows, as Flutter draws CSS's, in CSS's order: the
  /// first stands on top.
  final List<BoxShadow> shadows;

  /// The room inside the face round its child, inside its edge (the edge
  /// takes its own room, as CSS's border does).
  final EdgeInsets padding;

  /// Whether the child is clipped to the face's shape.
  final bool clipChild;

  /// What stands on the face.
  final Widget? child;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<FrostedMaterial>('material', material))
      ..add(ColorProperty('color', color, defaultValue: null))
      ..add(ColorProperty('edge', edge, defaultValue: null))
      ..add(ColorProperty('ring', ring, defaultValue: null))
      ..add(IterableProperty<BoxShadow>('shadows', shadows));
  }

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.maybeOf(context);
    final cut = shape;
    final corners = cut is RoundedRectangleBorder
        ? cut.borderRadius.resolve(direction)
        : radius;
    final path = cut is RoundedRectangleBorder ? null : cut;
    Widget clip(Widget child) => path == null
        ? ClipRRect(borderRadius: corners, child: child)
        : ClipPath(
            clipper: ShapeBorderClipper(shape: path, textDirection: direction),
            child: child,
          );
    // As CSS's border box: the edge takes room of its own inside the face.
    final room = edge == null ? padding : padding + edges;
    Widget? inside = child == null
        ? null
        : Padding(padding: room, child: child);
    final recipe = material.isGlass
        ? context.frostedTheme.materials.of(material)
        : null;
    final onGlass = recipe != null && FrostedOnGlass.of(context);
    final opaque = recipe != null && frostedOpaqueAt(context);
    if (inside != null && recipe != null) {
      inside = FrostedOnGlass(child: inside);
    }
    if (inside != null && clipChild) inside = clip(inside);
    // Glass's own layers under the face's: the tint (raised on glass, opaque
    // without transparency), then the face's fill over it.
    final base = recipe == null
        ? null
        : opaque
        ? recipe.opaque
        : onGlass
        ? recipe.raised
        : recipe.tint;
    final motion = FrostedMotion.of(context);
    Widget face = _FacePaint(
      style: _FaceStyle(
        base: base,
        color: color,
        gradients: gradients,
        wash: wash,
        edge: edge,
        sheen: sheen ?? recipe?.sheen,
        shade: recipe?.shade,
        ring: ring ?? recipe?.rim,
        shadows: shadows.isEmpty && recipe != null && !onGlass
            ? recipe.shadows
            : shadows,
      ),
      radius: corners,
      path: path,
      edged: edge != null,
      edges: edges,
      textDirection: direction,
      duration: motion.fast,
      curve: motion.curve,
      child: inside ?? SizedBox(width: room.horizontal, height: room.vertical),
    );
    // Always a stack, the face its last child: a face turning from glass to
    // paint (a chip chosen) keeps its paint's state and eases.
    final shares =
        material == FrostedMaterial.sheer ||
        material == FrostedMaterial.pane ||
        material == FrostedMaterial.well;
    face = Stack(
      fit: StackFit.passthrough,
      children: [
        if (recipe != null && !opaque && !onGlass) ...[
          Positioned.fill(
            child: clip(
              shares
                  ? BackdropFilter.grouped(
                      filter: recipe.filter,
                      child: const SizedBox.expand(),
                    )
                  : BackdropFilter(
                      filter: recipe.filter,
                      child: const SizedBox.expand(),
                    ),
            ),
          ),
          // Light glass's floor, added over the filtered backdrop.
          if (recipe.floor > 0)
            Positioned.fill(
              child: clip(CustomPaint(painter: _Lift(recipe.floor))),
            ),
        ],
        face,
      ],
    );
    // The face is its box, whatever its pixels show: glass may be the
    // colour of what is behind it, and its shadows fall outside it. The
    // alignment checks take it as one face (ui_core's DesignKeylineFace).
    // Always marked: a mark that came and went with a state would rebuild
    // the face's subtree (a field would lose its focus).
    return DesignKeylineFace(child: face);
  }
}

/// Light glass's floor: a grey of [floor] added (`BlendMode.plus`) over the
/// filtered backdrop, so black behind the glass comes out [floor] and every
/// hue keeps its colour (`FrostedMaterialRecipe.filter`).
class _Lift extends CustomPainter {
  const _Lift(this.floor);

  final double floor;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..blendMode = BlendMode.plus
      ..color = Color.from(alpha: 1, red: floor, green: floor, blue: floor),
  );

  @override
  bool shouldRepaint(_Lift oldDelegate) => oldDelegate.floor != floor;
}

/// What a face paints for its state: the part that eases when the state
/// changes. Its shape and the room its edge takes stay the new state's.
@immutable
class _FaceStyle {
  const _FaceStyle({
    required this.base,
    required this.color,
    required this.gradients,
    required this.wash,
    required this.edge,
    required this.sheen,
    required this.shade,
    required this.ring,
    required this.shadows,
  });

  final Color? base;
  final Color? color;
  final List<Gradient> gradients;
  final Color? wash;
  final Color? edge;
  final Color? sheen;
  final Color? shade;
  final Color? ring;
  final List<BoxShadow> shadows;

  /// [a] at 0 to [b] at 1: a layer one side lacks fades in or out.
  static _FaceStyle lerp(_FaceStyle a, _FaceStyle b, double t) => _FaceStyle(
    base: Color.lerp(a.base, b.base, t),
    color: Color.lerp(a.color, b.color, t),
    gradients: [
      for (var i = 0; i < math.max(a.gradients.length, b.gradients.length); i++)
        // One side has it at each index, so the lerp is never null.
        Gradient.lerp(
          i < a.gradients.length ? a.gradients[i] : null,
          i < b.gradients.length ? b.gradients[i] : null,
          t,
        )!,
    ],
    wash: Color.lerp(a.wash, b.wash, t),
    edge: Color.lerp(a.edge, b.edge, t),
    sheen: Color.lerp(a.sheen, b.sheen, t),
    shade: Color.lerp(a.shade, b.shade, t),
    ring: Color.lerp(a.ring, b.ring, t),
    shadows: BoxShadow.lerpList(a.shadows, b.shadows, t) ?? const [],
  );

  @override
  bool operator ==(Object other) =>
      other is _FaceStyle &&
      other.base == base &&
      other.color == color &&
      _FacePainter._same(other.gradients, gradients) &&
      other.wash == wash &&
      other.edge == edge &&
      other.sheen == sheen &&
      other.shade == shade &&
      other.ring == ring &&
      _FacePainter._same(other.shadows, shadows);

  @override
  int get hashCode => Object.hash(
    base,
    color,
    Object.hashAll(gradients),
    wash,
    edge,
    sheen,
    shade,
    ring,
    Object.hashAll(shadows),
  );
}

class _FaceStyleTween extends Tween<_FaceStyle> {
  _FaceStyleTween({super.begin});

  @override
  _FaceStyle lerp(double t) => _FaceStyle.lerp(begin!, end!, t);
}

/// A face's paint, easing to a new [style] (Frosted's one motion for a
/// change of state): an implicit animation over the whole style, so a
/// change mid-way turns from the paint shown.
class _FacePaint extends ImplicitlyAnimatedWidget {
  const _FacePaint({
    required this.style,
    required this.radius,
    required this.path,
    required this.edged,
    required this.edges,
    required this.textDirection,
    required this.child,
    required super.duration,
    super.curve,
  });

  final _FaceStyle style;
  final BorderRadius radius;
  final OutlinedBorder? path;
  final bool edged;
  final EdgeInsets edges;
  final TextDirection? textDirection;
  final Widget child;

  @override
  AnimatedWidgetBaseState<_FacePaint> createState() => _FacePaintState();
}

class _FacePaintState extends AnimatedWidgetBaseState<_FacePaint> {
  _FaceStyleTween? _style;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _style = visitor(
      _style,
      widget.style,
      (value) => _FaceStyleTween(begin: value as _FaceStyle),
    ) as _FaceStyleTween?;
  }

  @override
  Widget build(BuildContext context) {
    final s = _style!.evaluate(animation);
    return CustomPaint(
      painter: _FacePainter(
        radius: widget.radius,
        path: widget.path,
        base: s.base,
        color: s.color,
        gradients: s.gradients,
        wash: s.wash,
        edge: s.edge,
        edged: widget.edged,
        edges: widget.edges,
        sheen: s.sheen,
        shade: s.shade,
        ring: s.ring,
        shadows: s.shadows,
        textDirection: widget.textDirection,
      ),
      child: widget.child,
    );
  }
}

class _FacePainter extends CustomPainter {
  const _FacePainter({
    required this.radius,
    required this.path,
    required this.base,
    required this.color,
    required this.gradients,
    required this.wash,
    required this.edge,
    required this.edged,
    required this.edges,
    required this.sheen,
    required this.shade,
    required this.ring,
    required this.shadows,
    required this.textDirection,
  });

  final BorderRadius radius;
  final OutlinedBorder? path;
  final Color? base;
  final Color? color;
  final List<Gradient> gradients;
  final Color? wash;
  final Color? edge;

  /// Whether the edge takes its room (the new state's, while the edge's
  /// colour eases).
  final bool edged;
  final EdgeInsets edges;
  final Color? sheen;
  final Color? shade;
  final Color? ring;
  final List<BoxShadow> shadows;
  final TextDirection? textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final cut = path;
    if (cut != null) return _paintPath(canvas, Offset.zero & size, cut);
    final rect = Offset.zero & size;
    final outer = radius.toRRect(rect);
    if (shadows.isNotEmpty) {
      var reach = 1.0;
      for (final s in shadows) {
        reach = math.max(
          reach,
          s.offset.distance + s.spreadRadius.abs() + 3 * s.blurSigma + 1,
        );
      }
      canvas.save();
      canvas.clipPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(rect.inflate(reach))
          ..addRRect(outer),
      );
      // CSS stacks a box's shadows with the first on top.
      for (final s in shadows.reversed) {
        canvas.drawRRect(
          outer.shift(s.offset).inflate(s.spreadRadius),
          s.toPaint(),
        );
      }
      canvas.restore();
    }
    final under = base;
    if (under != null) canvas.drawRRect(outer, Paint()..color = under);
    final fill = color;
    if (fill != null) canvas.drawRRect(outer, Paint()..color = fill);
    for (final g in gradients) {
      canvas.drawRRect(
        outer,
        Paint()..shader = g.createShader(rect, textDirection: textDirection),
      );
    }
    final over = wash;
    if (over != null) canvas.drawRRect(outer, Paint()..color = over);
    final inner = edged ? _inside(outer, edges) : outer;
    final dusk = shade;
    if (dusk != null) {
      canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRRect(inner),
          Path()..addRRect(inner.shift(const Offset(0, 2))),
        ),
        Paint()..color = dusk,
      );
    }
    final light = sheen;
    if (light != null) {
      canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRRect(inner),
          Path()..addRRect(inner.shift(const Offset(0, 1))),
        ),
        Paint()..color = light,
      );
    }
    final inRing = ring;
    if (inRing != null) {
      canvas.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRRect(inner)
          ..addRRect(inner.deflate(FrostedChromeMetrics.outline)),
        Paint()..color = inRing,
      );
    }
    final line = edge;
    if (line != null) {
      canvas.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRRect(outer)
          ..addRRect(inner),
        Paint()..color = line,
      );
    }
  }

  /// The same layers cut to [cut]'s path: the shadows round it, the fill,
  /// the wash, the sheen, the ring and the edge (as wide as the top edge).
  void _paintPath(Canvas canvas, Rect rect, OutlinedBorder cut) {
    final dir = textDirection;
    Path pathIn(Rect r, [double width = 0]) => width <= 0
        ? cut.getOuterPath(r, textDirection: dir)
        : cut
              .copyWith(side: BorderSide(width: width))
              .getInnerPath(r, textDirection: dir);
    final outer = pathIn(rect);
    if (shadows.isNotEmpty) {
      var reach = 1.0;
      for (final s in shadows) {
        reach = math.max(
          reach,
          s.offset.distance + s.spreadRadius.abs() + 3 * s.blurSigma + 1,
        );
      }
      canvas.save();
      canvas.clipPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(rect.inflate(reach))
          ..addPath(outer, Offset.zero),
      );
      for (final s in shadows.reversed) {
        // A spread grows the cut's corners with its sides, as an RRect's
        // inflate does, so a hard spread line runs concentric to the face.
        final grown = FrostedStyleLayers.around(cut, s.spreadRadius)!;
        canvas.drawPath(
          grown.getOuterPath(
            rect.inflate(s.spreadRadius).shift(s.offset),
            textDirection: dir,
          ),
          s.toPaint(),
        );
      }
      canvas.restore();
    }
    final under = base;
    if (under != null) canvas.drawPath(outer, Paint()..color = under);
    final fill = color;
    if (fill != null) canvas.drawPath(outer, Paint()..color = fill);
    for (final g in gradients) {
      canvas.drawPath(
        outer,
        Paint()..shader = g.createShader(rect, textDirection: dir),
      );
    }
    final over = wash;
    if (over != null) canvas.drawPath(outer, Paint()..color = over);
    final width = edged ? edges.top : 0.0;
    final inner = pathIn(rect, width);
    final dusk = shade;
    if (dusk != null) {
      canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          inner,
          inner.shift(const Offset(0, 2)),
        ),
        Paint()..color = dusk,
      );
    }
    final light = sheen;
    if (light != null) {
      canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          inner,
          inner.shift(const Offset(0, 1)),
        ),
        Paint()..color = light,
      );
    }
    final inRing = ring;
    if (inRing != null) {
      canvas.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addPath(inner, Offset.zero)
          ..addPath(
            pathIn(rect, width + FrostedChromeMetrics.outline),
            Offset.zero,
          ),
        Paint()..color = inRing,
      );
    }
    final line = edge;
    if (line != null && width > 0) {
      canvas.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addPath(outer, Offset.zero)
          ..addPath(inner, Offset.zero),
        Paint()..color = line,
      );
    }
  }

  /// The face's padding box: inside its edge, each corner's curve less the
  /// edge's width, as CSS draws a border's inner edge.
  static RRect _inside(RRect o, EdgeInsets w) => RRect.fromLTRBAndCorners(
    o.left + w.left,
    o.top + w.top,
    o.right - w.right,
    o.bottom - w.bottom,
    topLeft: Radius.elliptical(
      math.max(0, o.tlRadiusX - w.left),
      math.max(0, o.tlRadiusY - w.top),
    ),
    topRight: Radius.elliptical(
      math.max(0, o.trRadiusX - w.right),
      math.max(0, o.trRadiusY - w.top),
    ),
    bottomRight: Radius.elliptical(
      math.max(0, o.brRadiusX - w.right),
      math.max(0, o.brRadiusY - w.bottom),
    ),
    bottomLeft: Radius.elliptical(
      math.max(0, o.blRadiusX - w.left),
      math.max(0, o.blRadiusY - w.bottom),
    ),
  );

  @override
  bool shouldRepaint(_FacePainter old) =>
      old.radius != radius ||
      old.path != path ||
      old.base != base ||
      old.color != color ||
      old.wash != wash ||
      !_same(old.gradients, gradients) ||
      old.edge != edge ||
      old.edged != edged ||
      old.edges != edges ||
      old.sheen != sheen ||
      old.shade != shade ||
      old.ring != ring ||
      !_same(old.shadows, shadows) ||
      old.textDirection != textDirection;

  static bool _same<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
