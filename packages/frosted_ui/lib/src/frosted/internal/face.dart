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

/// The ring just inside a dialog's lit edge: by day none (the slab's own
/// ring, a dark hairline, would stand inside the light), by night the
/// slab's own light ring, lit from above with its edge
/// ([FrostedFace.litFromAbove]).
Color? frostedSlabRing(FrostedThemeData t) =>
    t.isDark ? null : const Color(0x00000000);

// The luminance of the darkest place on the theme's dawn: its ground, or a
// wash of its light over it at its strongest.

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

/// How far a part's frost has cleared, for the faces under it: 0 at rest,
/// [hover] under a pointer, 1 while the keyboard holds it. The keyboard's
/// focus, said in glass: the frost wipes partway clear (less blur, less
/// milk, more of the colour behind) and the part's own thin rim catches
/// white light ([lit]). No colour of its own, no line of its own, nothing
/// outside the part. A pointer only clears it, a little.
///
/// [FrostedFocusRing] sets it round a part. The outermost [FrostedFace]
/// under it clears and lights its rim, easing to them, and hands 0 to the
/// faces it holds, so a chip on a cleared card stays as it was.
class FrostedClearing extends InheritedWidget {
  /// Clears the faces under [child] to [level], their rims lit to [lit].
  const FrostedClearing({
    required this.level,
    required super.child,
    this.lit = 0,
    super.key,
  }) : _claim = null;

  const FrostedClearing._claimed(
    this._claim, {
    required this.level,
    required this.lit,
    required super.child,
  });

  /// How far the frost clears: 0 to 1.
  final double level;

  /// How far the part's rim catches the light: 0 to 1, 1 for the keyboard's
  /// focus and 0 under a pointer.
  final double lit;

  // Set by the face that lights its own rim, so the part draws no second.
  final _RimClaim? _claim;

  /// A pointer's clearing: lighter than the keyboard's.
  static const double hover = .45;

  /// The level the faces under [context] clear to.
  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FrostedClearing>()?.level ?? 0;

  /// How far the rim of the part under [context] is lit, for a part that
  /// draws its own rim; the part then draws it, and nothing else does.
  static double litOf(BuildContext context) {
    final clearing = context
        .dependOnInheritedWidgetOfExactType<FrostedClearing>();
    clearing?._claim?.taken = true;
    return clearing?.lit ?? 0;
  }

  @override
  bool updateShouldNotify(FrostedClearing old) =>
      old.level != level || old.lit != lit || old._claim != _claim;
}

// Whether a part under a FrostedCleared lights its own rim.
class _RimClaim {
  bool taken = false;
}

/// Marks a part that draws its own clearing (a menu's or a list's row, lit
/// by its place in the menu as well as by focus): a [FrostedFocusRing] under
/// it draws nothing, so the row never clears twice.
class FrostedClearingHeld extends InheritedWidget {
  /// Holds the clearing for [child].
  const FrostedClearingHeld({required super.child, super.key});

  /// Whether a part above [context] draws its clearing.
  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<FrostedClearingHeld>() != null;

  @override
  bool updateShouldNotify(FrostedClearingHeld old) => false;
}

/// [child] with its frost cleared to [level] (eased to it, a cut under
/// Reduce Motion): what is behind its [outline], standing [insets] inside
/// its box, clears ([FrostedClearPatch]), and unless [inside] its outermost
/// face clears too ([FrostedClearing]). While [lit], the part's own rim
/// catches white light: the face's rim when it has one, otherwise a hairline
/// just inside [outline] ([frostedRimLight]). [FrostedFocusRing] places one;
/// a row lit by its place in a menu places its own.
class FrostedCleared extends StatelessWidget {
  /// Clears [child] to [level], its rim lit to [lit].
  const FrostedCleared({
    required this.level,
    required this.outline,
    required this.child,
    this.lit = 0,
    this.insets = EdgeInsets.zero,
    this.inside = false,
    super.key,
  });

  /// How far: 0 to 1.
  final double level;

  /// How far the rim catches the light: 0 to 1, 1 for the keyboard's focus.
  final double lit;

  /// The part's shape.
  final ShapeBorder outline;

  /// How far inside [child]'s box the part stands.
  final EdgeInsetsGeometry insets;

  /// Whether only what is behind the part clears, not the faces it holds.
  final bool inside;

  /// The part.
  final Widget child;

  @override
  Widget build(BuildContext context) => _Cleared(
    level: level,
    lit: lit,
    outline: outline,
    insets: insets.resolve(Directionality.maybeOf(context)),
    inside: inside,
    child: child,
  );
}

class _Cleared extends StatefulWidget {
  const _Cleared({
    required this.level,
    required this.lit,
    required this.outline,
    required this.insets,
    required this.inside,
    required this.child,
  });

  final double level;
  final double lit;
  final ShapeBorder outline;
  final EdgeInsets insets;
  final bool inside;
  final Widget child;

  @override
  State<_Cleared> createState() => _ClearedState();
}

class _ClearedState extends State<_Cleared> {
  // Whether a face under it lights its own rim; kept while it stands.
  final _claim = _RimClaim();

  @override
  Widget build(BuildContext context) {
    final at = widget.insets;
    final motion = FrostedMotion.of(context);
    final t = context.frostedTheme;
    Widget placed(Widget child) => Positioned(
      left: at.left,
      top: at.top,
      right: at.right,
      bottom: at.bottom,
      child: IgnorePointer(child: child),
    );
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        // By day the keyboard's part rises: a soft shadow under it, outside
        // its outline.
        placed(
          TweenAnimationBuilder<double>(
            tween: Tween(end: t.isDark ? 0.0 : widget.lit),
            duration: motion.fast,
            curve: motion.curve,
            builder: (context, lift, _) => _Rise(
              outline: widget.outline,
              shadows: frostedLift(t, lift),
              textDirection: Directionality.maybeOf(context),
            ),
          ),
        ),
        // Under the face, so it never touches the face's words.
        placed(
          TweenAnimationBuilder<double>(
            tween: Tween(end: widget.level),
            duration: motion.fast,
            curve: motion.curve,
            builder: (context, cleared, _) =>
                FrostedClearPatch(level: cleared, outline: widget.outline),
          ),
        ),
        if (widget.inside)
          FrostedClearing(level: 0, child: widget.child)
        else
          FrostedClearing._claimed(
            _claim,
            level: widget.level,
            lit: widget.lit,
            child: widget.child,
          ),
        // A part with no face of its own to light (a row, a check drawn as
        // a disc): its rim, a hairline just inside its outline.
        placed(
          TweenAnimationBuilder<double>(
            tween: Tween(end: widget.lit),
            duration: motion.fast,
            curve: motion.curve,
            builder: (context, lit, _) => _RimLight(
              outline: widget.outline,
              claim: widget.inside ? null : _claim,
              color: frostedRimLight(t, null, lit),
              textDirection: Directionality.maybeOf(context),
            ),
          ),
        ),
      ],
    );
  }
}

// A hairline of [color] just inside [outline], unless a face claimed it.
// Its own render box, not a custom paint: it is light on a part, not a
// face, and paints nothing at rest.
class _RimLight extends LeafRenderObjectWidget {
  const _RimLight({
    required this.outline,
    required this.claim,
    required this.color,
    required this.textDirection,
  });

  final ShapeBorder outline;
  final _RimClaim? claim;
  final Color color;
  final TextDirection? textDirection;

  @override
  _RenderRimLight createRenderObject(BuildContext context) => _RenderRimLight(
    outline: outline,
    claim: claim,
    color: color,
    textDirection: textDirection,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderRimLight box) => box
    ..outline = outline
    ..claim = claim
    ..color = color
    ..textDirection = textDirection;
}

class _RenderRimLight extends RenderBox {
  _RenderRimLight({
    required this._outline,
    required this._claim,
    required this._color,
    required this._textDirection,
  });

  ShapeBorder _outline;
  set outline(ShapeBorder v) {
    if (v == _outline) return;
    _outline = v;
    markNeedsPaint();
  }

  _RimClaim? _claim;
  set claim(_RimClaim? v) {
    if (identical(v, _claim)) return;
    _claim = v;
    markNeedsPaint();
  }

  Color _color;
  set color(Color v) {
    if (v == _color) return;
    _color = v;
    markNeedsPaint();
  }

  TextDirection? _textDirection;
  set textDirection(TextDirection? v) {
    if (v == _textDirection) return;
    _textDirection = v;
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_color.a == 0 || (_claim?.taken ?? false)) return;
    final box = offset & size;
    context.canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addPath(
          _outline.getOuterPath(box, textDirection: _textDirection),
          Offset.zero,
        )
        ..addPath(
          _outline.getOuterPath(
            box.deflate(FrostedChromeMetrics.outline),
            textDirection: _textDirection,
          ),
          Offset.zero,
        ),
      Paint()..color = _color,
    );
  }
}

/// The shadow a part rises on by day while the keyboard holds it, at [lit]
/// (0 to 1): the theme's raised shade, deeper and further below, the way a
/// floating pane stands off the glass. None by night, where the rim's light
/// shows focus, and none at rest. It is drawn for a part 36 high: a focused
/// part casts it scaled to its size, from 0.55 to 1.25 times.
List<BoxShadow> frostedLift(FrostedThemeData t, double lit) {
  if (t.isDark || lit <= 0) return const <BoxShadow>[];
  final raised = t.shadows.raised;
  final shade = raised.isEmpty
      ? const Color(0x2E2A2464)
      : raised.first.color.withValues(alpha: 1);
  final strength = raised.isEmpty ? .18 : raised.first.color.a;
  // One broad, low shadow: its edge never reads as a line along the part.
  return [
    BoxShadow(
      color: shade.withValues(alpha: math.min(1, strength * 2) * lit),
      offset: Offset(0, 10 * lit),
      blurRadius: 26 * lit,
      spreadRadius: -6,
    ),
  ];
}

// [shadows] cast by [outline], drawn only outside it: glass never shows its
// own shadow through itself.
class _Rise extends LeafRenderObjectWidget {
  const _Rise({
    required this.outline,
    required this.shadows,
    required this.textDirection,
  });

  final ShapeBorder outline;
  final List<BoxShadow> shadows;
  final TextDirection? textDirection;

  @override
  _RenderRise createRenderObject(BuildContext context) => _RenderRise(
    outline: outline,
    shadows: shadows,
    textDirection: textDirection,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderRise box) => box
    ..outline = outline
    ..shadows = shadows
    ..textDirection = textDirection;
}

class _RenderRise extends RenderBox {
  _RenderRise({
    required this._outline,
    required this._shadows,
    required this._textDirection,
  });

  ShapeBorder _outline;
  set outline(ShapeBorder v) {
    if (v == _outline) return;
    _outline = v;
    markNeedsPaint();
  }

  List<BoxShadow> _shadows;
  set shadows(List<BoxShadow> v) {
    if (listEquals(v, _shadows)) return;
    _shadows = v;
    markNeedsPaint();
  }

  TextDirection? _textDirection;
  set textDirection(TextDirection? v) {
    if (v == _textDirection) return;
    _textDirection = v;
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_shadows.isEmpty) return;
    final box = offset & size;
    final canvas = context.canvas;
    // [frostedLift] is drawn for a part 36 high; a smaller one (a check, a
    // knob) casts it smaller, a larger one (a row, a card) a little larger.
    final k = (size.shortestSide / 36).clamp(.55, 1.25);
    final shadows = [for (final s in _shadows) s.scale(k)];
    var reach = 0.0;
    for (final s in shadows) {
      reach = math.max(
        reach,
        s.offset.distance + s.spreadRadius.abs() + s.blurRadius * 2,
      );
    }
    canvas.save();
    canvas.clipPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(box.inflate(reach))
        ..addPath(
          _outline.getOuterPath(box, textDirection: _textDirection),
          Offset.zero,
        ),
    );
    for (final s in shadows.reversed) {
      if (s.color.a == 0) continue;
      canvas.drawPath(
        _outline.getOuterPath(
          box.shift(s.offset).inflate(s.spreadRadius),
          textDirection: _textDirection,
        ),
        s.toPaint(),
      );
    }
    canvas.restore();
  }
}

/// Whether [rim] is a part's dark boundary (it holds 3:1 on light glass, as
/// an empty check's ring does): white light over it would take the outline
/// away, so a lit part keeps it and catches the light just inside it.
bool frostedRimIsBoundary(Color rim) =>
    rim.a >= .5 && rim.withValues(alpha: 1).computeLuminance() < .3;

/// The light a focused part's rim catches, at [lit] (0 to 1): its own [rim]
/// brightened toward white, or white fading in where it has none. White by
/// day; by night a white a little softer, as the night glass's rims are.
Color frostedRimLight(FrostedThemeData t, Color? rim, double lit) {
  final light = t.isDark ? const Color(0xE6FFFFFF) : const Color(0xFFFFFFFF);
  return Color.lerp(rim ?? light.withValues(alpha: 0), light, lit)!;
}

/// The frost under a part cleared to [level], over its shape [outline]: what
/// is behind loses some of its milk and shows more of its colour. By day
/// every colour is drawn toward the darkest ground any of the theme's glass
/// can show (over black, where its floor holds the words at their contrast)
/// and no further, so words on a cleared part read as they do at rest
/// whatever is behind; by night it dims toward black, which only parts
/// light words further from their ground. One colour matrix, the lift its
/// offset, clipped to the part: a lift drawn after the filter would miss
/// the part's anti-aliased edge and leave a dark seam there.
class FrostedClearPatch extends StatelessWidget {
  /// Clears what is behind [outline] to [level].
  const FrostedClearPatch({
    required this.level,
    required this.outline,
    super.key,
  });

  /// How far: 0 draws nothing.
  final double level;

  /// The part's shape.
  final ShapeBorder outline;

  /// How much of the milk a full clearing takes away, by day and by night.
  static const double day = .65, night = .45;

  /// How much more of the colour behind a full clearing shows.
  static const double colour = 1;

  /// The grey a day clearing draws toward: the brightest of the theme's
  /// glass grounds over black, the least ground its words are held on.
  static double fixedPoint(FrostedThemeData t) {
    final m = t.materials;
    var most = 0.0;
    for (final g in [m.sheer, m.pane, m.well, m.slab, m.bar]) {
      final c = g.groundOver(const Color(0xFF000000));
      most = math.max(most, math.max(c.r, math.max(c.g, c.b)));
    }
    return most;
  }

  /// The matrix of a clearing to [level], and the lift added after it.
  static (List<double>, double) of(FrostedThemeData t, double level) {
    final m = frostedSaturate(1 + colour * level);
    final k = 1 - (t.isDark ? night : day) * level;
    for (var i = 0; i < 15; i++) {
      if (i % 5 < 4) m[i] *= k;
    }
    return (m, t.isDark ? 0.0 : fixedPoint(t) * (1 - k));
  }

  @override
  Widget build(BuildContext context) {
    if (level <= 0) return const SizedBox.shrink();
    final (matrix, lift) = of(context.frostedTheme, level);
    return ClipPath(
      clipper: ShapeBorderClipper(
        shape: outline,
        textDirection: Directionality.maybeOf(context),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ui.ColorFilter.matrix([
              for (var i = 0; i < 20; i++)
                // The offset column is in 0 to 255.
                i == 4 || i == 9 || i == 14 ? lift * 255 : matrix[i],
            ]),
            child: const SizedBox.expand(),
          ),
        ],
      ),
    );
  }
}

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
    this.litFromAbove = false,
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

  /// Whether the [edge] and the [ring] catch the light from above: at their
  /// full strength along the top, fading down the sides to nothing at the
  /// foot, so a raised slab by night wears a lit rim rather than a stroke
  /// (law 2). False draws them even all round.
  final bool litFromAbove;

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
    // A part's focus clears its own face and lights its own rim, not the
    // faces it holds.
    final clearing = FrostedClearing.of(context);
    final lit = FrostedClearing.litOf(context);
    if (inside != null) inside = FrostedClearing(level: 0, child: inside);
    if (inside != null && clipChild) inside = clip(inside);
    // Glass's own layers under the face's: the tint (raised on glass, opaque
    // without transparency), then the face's fill over it.
    // Cleared, glass on glass thins its milk (a well's shade, which lowers
    // it, stays); glass over the page clears its blur below.
    final base = recipe == null
        ? null
        : opaque
        ? recipe.opaque
        : onGlass && recipe.raised.computeLuminance() > .5
        ? recipe.raised.withValues(alpha: recipe.raised.a * (1 - .5 * clearing))
        : onGlass
        ? recipe.raised
        : recipe.tint;
    final rim = ring ?? recipe?.rim;
    final t = context.frostedTheme;
    // Lit, its rim catches the light: the ring when it has one, else its
    // edge, else a white ring fades in where the ring would stand. A rim
    // that is the part's dark boundary stays, and the light comes in just
    // inside it, so the part never loses its outline.
    var (ringLit, edgeLit, glint) = (rim, edge, null as Color?);
    if (lit > 0) {
      final light = frostedRimLight(t, null, lit);
      if (rim != null) {
        if (frostedRimIsBoundary(rim)) {
          glint = light;
        } else {
          ringLit = frostedRimLight(t, rim, lit);
        }
      } else if (edge case final edge?) {
        if (frostedRimIsBoundary(edge)) {
          ringLit = light;
        } else {
          edgeLit = frostedRimLight(t, edge, lit);
        }
      } else {
        ringLit = light;
      }
    }
    final motion = FrostedMotion.of(context);
    Widget face = _FacePaint(
      style: _FaceStyle(
        base: base,
        color: color,
        gradients: gradients,
        wash: wash,
        edge: edgeLit,
        sheen: sheen ?? recipe?.sheen,
        shade: recipe?.shade,
        ring: ringLit,
        glint: glint,
        shadows: shadows.isEmpty && recipe != null && !onGlass
            ? recipe.shadows
            : shadows,
      ),
      radius: corners,
      path: path,
      edged: edge != null,
      edges: edges,
      litFromAbove: litFromAbove,
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
              TweenAnimationBuilder<double>(
                tween: Tween(end: clearing),
                duration: motion.fast,
                curve: motion.curve,
                builder: (context, cleared, _) => shares
                    ? BackdropFilter.grouped(
                        filter: recipe.clearedFilter(cleared),
                        child: const SizedBox.expand(),
                      )
                    : BackdropFilter(
                        filter: recipe.clearedFilter(cleared),
                        child: const SizedBox.expand(),
                      ),
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
    // alignment checks take it as one face (ui_core's RawKeylineFace).
    // Always marked: a mark that came and went with a state would rebuild
    // the face's subtree (a field would lose its focus).
    return RawKeylineFace(child: face);
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
    required this.glint,
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
  final Color? glint;
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
    glint: Color.lerp(a.glint, b.glint, t),
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
      other.glint == glint &&
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
    glint,
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
    required this.litFromAbove,
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
  final bool litFromAbove;
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
        glint: s.glint,
        shadows: s.shadows,
        litFromAbove: widget.litFromAbove,
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
    required this.glint,
    required this.shadows,
    required this.litFromAbove,
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

  // The light just inside the ring while a dark ring is lit.
  final Color? glint;
  final List<BoxShadow> shadows;
  final bool litFromAbove;
  final TextDirection? textDirection;

  /// The paint of the edge or the ring: [color] even all round, or, lit
  /// from above, at its full strength along the top, fading down the sides
  /// to nothing at the foot.
  Paint _rim(Color color, Rect rect) => litFromAbove
      ? (Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color,
              color.withValues(alpha: color.a * .3),
              color.withValues(alpha: 0),
            ],
            stops: const [0, .5, 1],
          ).createShader(rect))
      : (Paint()..color = color);

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
        _rim(inRing, rect),
      );
    }
    final lit = glint;
    if (lit != null) {
      canvas.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRRect(inner.deflate(FrostedChromeMetrics.outline))
          ..addRRect(inner.deflate(2 * FrostedChromeMetrics.outline)),
        Paint()..color = lit,
      );
    }
    final line = edge;
    if (line != null) {
      canvas.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRRect(outer)
          ..addRRect(inner),
        _rim(line, rect),
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
        _rim(inRing, rect),
      );
    }
    final lit = glint;
    if (lit != null) {
      canvas.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addPath(
            pathIn(rect, width + FrostedChromeMetrics.outline),
            Offset.zero,
          )
          ..addPath(
            pathIn(rect, width + 2 * FrostedChromeMetrics.outline),
            Offset.zero,
          ),
        Paint()..color = lit,
      );
    }
    final line = edge;
    if (line != null && width > 0) {
      canvas.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addPath(outer, Offset.zero)
          ..addPath(inner, Offset.zero),
        _rim(line, rect),
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
      old.glint != glint ||
      !_same(old.shadows, shadows) ||
      old.textDirection != textDirection ||
      old.litFromAbove != litFromAbove;

  static bool _same<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
