import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'internal/face.dart';
import 'theme.dart';

/// What a Frosted surface is made of. Every surface but [paint] is glass: what
/// is behind it comes through blurred and saturated, under a tint whose alpha
/// is derived from the theme's text so the words on it always read
/// ([FrostedMaterials.derive]). The glasses differ in thickness: how far the
/// blur reaches, how much tint, how deep the shadow.
enum FrostedMaterial {
  /// No glass: the face is its own colours (the primary action's ink, a
  /// track, a mark, the toast's dark slab).
  paint,

  /// The thinnest glass, a card on the ground: the backdrop shows through
  /// it, blurred.
  sheer,

  /// The everyday glass: a list's section, a secondary button, a chip.
  pane,

  /// Recessed glass, a step darker than what holds it, with a shade along
  /// its top inside edge: a field.
  well,

  /// The thick glass of what floats over a page: a sheet, a dialog, a menu,
  /// a popover, an action sheet, a picker's card, the command palette. What
  /// is below it dims and
  /// softens ([FrostedMaterials.scrim], [FrostedMaterials.soften]).
  slab,

  /// The glass of the bars the content passes under: the top bar, the
  /// navigation bar, the sidebar, a sticky header.
  bar;

  /// Whether the material is glass (everything but [paint]).
  bool get isGlass => this != paint;
}

/// How one glass is drawn: the backdrop blurred by [blur], saturated by
/// [saturation], its greys drawn between [floor] and [ceiling], the [tint]
/// over it, the [rim] just inside its edge, the [sheen] along its top, and
/// its [shadows] outside. Without transparency
/// ([FrostedThemeData.opaqueMaterials]) the [opaque] fill replaces the
/// backdrop and the tint.
@immutable
class FrostedMaterialRecipe {
  /// Creates a [FrostedMaterialRecipe].
  const FrostedMaterialRecipe({
    required this.blur,
    required this.saturation,
    required this.tint,
    required this.raised,
    required this.rim,
    required this.sheen,
    required this.opaque,
    this.floor = 0,
    this.ceiling = 1,
    this.shade,
    this.shadows = const <BoxShadow>[],
  });

  /// The blur's sigma over what is behind.
  final double blur;

  /// How much the blurred backdrop's colour is saturated (1 keeps it).
  final double saturation;

  /// Where black behind the glass comes out, 0 to 1: light glass lifts it,
  /// so its dark words read over anything, while the backdrop's hues keep
  /// their colour (only lightness is drawn into the glass's span).
  final double floor;

  /// Where white behind the glass comes out, 0 to 1: dark glass lowers it,
  /// so its light words read over anything; a hue's colour dims half as
  /// much.
  final double ceiling;

  /// Laid over the blurred backdrop: the glass's colour, thin enough that
  /// the backdrop shows through. With [floor] and [ceiling] it keeps the
  /// words on the glass at their contrast over any backdrop
  /// ([FrostedMaterials.derive]).
  final Color tint;

  /// The fill when this glass stands on another glass: it is not blurred a
  /// second time, only raised (or, for a well, lowered) a step.
  final Color raised;

  /// The one-pixel rim just inside the edge, taking no room.
  final Color rim;

  /// The light along the top inside edge.
  final Color sheen;

  /// The shade along the top inside edge of a recessed glass; null for none.
  final Color? shade;

  /// The shadows outside the glass, the first on top.
  final List<BoxShadow> shadows;

  /// The fill of the glass's opaque form.
  final Color opaque;

  /// The filter over what is behind: blurred, then one colour matrix that
  /// saturates it (CSS's `saturate()`) and scales its lightness into the
  /// glass's span, `ceiling - floor`: a grey `g` comes out
  /// `g * (ceiling - floor)`, a hue as far from that grey as it was on light
  /// glass, and dimmed half as much as its lightness on dark glass.
  /// The matrix has no offset (an offset would also paint where nothing
  /// is, which a backdrop filter must not), so light glass adds its
  /// [floor] after it, a grey added over the filtered backdrop
  /// ([BlendMode.plus]) under the tint.
  ui.ImageFilter get filter => ui.ImageFilter.compose(
    outer: ui.ColorFilter.matrix(_matrix),
    inner: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
  );

  // The luma weights CSS's saturate() keeps.
  static const List<double> _luma = [0.213, 0.715, 0.072];

  // Lightness scales by the span; colour (each channel's distance from the
  // grey of its lightness) by [_colour].
  List<double> get _matrix {
    final m = frostedSaturate(saturation);
    final light = ceiling - floor;
    final colour = _colour;
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        final i = row * 5 + col;
        m[i] = colour * m[i] + (light - colour) * _luma[col];
      }
    }
    return m;
  }

  // How much of a hue's colour comes through: all of it on light glass (its
  // floor lifts it clear of dark words), and on dark glass half the way
  // from the lightness it keeps to all of it, so a saturated red or magenta
  // dims too under light words.
  double get _colour => ceiling >= 1 ? 1 : (1 + ceiling) / 2;

  /// The colour this glass shows over a flat [behind]: through its matrix,
  /// lifted by its [floor], under its tint. What a legibility test reads
  /// the words against.
  Color groundOver(Color behind) {
    final m = _matrix;
    double seen(int row) {
      final c =
          m[row * 5] * behind.r +
          m[row * 5 + 1] * behind.g +
          m[row * 5 + 2] * behind.b;
      return (c.clamp(0.0, 1.0) + floor).clamp(0.0, 1.0);
    }

    return Color.alphaBlend(
      tint,
      Color.from(alpha: 1, red: seen(0), green: seen(1), blue: seen(2)),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FrostedMaterialRecipe &&
      other.blur == blur &&
      other.saturation == saturation &&
      other.floor == floor &&
      other.ceiling == ceiling &&
      other.tint == tint &&
      other.raised == raised &&
      other.rim == rim &&
      other.sheen == sheen &&
      other.shade == shade &&
      other.opaque == opaque &&
      _sameShadows(other.shadows, shadows);

  @override
  int get hashCode => Object.hash(
    blur,
    saturation,
    floor,
    ceiling,
    tint,
    raised,
    rim,
    sheen,
    shade,
    opaque,
    Object.hashAll(shadows),
  );

  static bool _sameShadows(List<BoxShadow> a, List<BoxShadow> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// The theme's glass, one [FrostedMaterialRecipe] per [FrostedMaterial], and
/// what a [FrostedMaterial.slab] does to the page below it.
@immutable
class FrostedMaterials {
  /// Creates a [FrostedMaterials].
  const FrostedMaterials({
    required this.sheer,
    required this.pane,
    required this.well,
    required this.slab,
    required this.bar,
    required this.scrim,
    required this.soften,
  });

  /// A card on the ground.
  final FrostedMaterialRecipe sheer;

  /// A section, a secondary control.
  final FrostedMaterialRecipe pane;

  /// A field.
  final FrostedMaterialRecipe well;

  /// What floats: sheets, dialogs, menus.
  final FrostedMaterialRecipe slab;

  /// The bars.
  final FrostedMaterialRecipe bar;

  /// The colour the page below a slab dims under.
  final Color scrim;

  /// The blur the page below a slab softens by.
  final double soften;

  /// The recipe of [material]; null for [FrostedMaterial.paint].
  FrostedMaterialRecipe? of(FrostedMaterial material) => switch (material) {
    FrostedMaterial.paint => null,
    FrostedMaterial.sheer => sheer,
    FrostedMaterial.pane => pane,
    FrostedMaterial.well => well,
    FrostedMaterial.slab => slab,
    FrostedMaterial.bar => bar,
  };

  /// Every colour the glass can show under what stands on it: each glass
  /// over black, white and the saturated hues, flat and raised a step on
  /// another, and each glass's opaque colour. A control's boundary
  /// ([FrostedThemeData.controlEdge]) keeps its contrast on all of them.
  List<Color> grounds() => [
    for (final glass in [sheer, pane, well, slab, bar]) ...[
      for (final behind in _behind) ...[
        glass.groundOver(behind),
        Color.alphaBlend(glass.raised, glass.groundOver(behind)),
      ],
      glass.opaque,
    ],
  ];

  /// The contrast every body text colour keeps on glass (WCAG's AA).
  static const double bodyContrast = 4.5;

  /// The contrast quiet words (a placeholder, a hint) and a control's
  /// boundary keep on glass.
  static const double quietContrast = 3;

  static final Expando<FrostedMaterials> _derived = Expando<FrostedMaterials>(
    'frosted materials',
  );

  /// [theme]'s glass. Each glass has a tint of the preset's glass colour,
  /// thin enough that the backdrop shows through (thicker glass, more
  /// tint), and the range what is behind it is drawn into: the least lift
  /// of black (light glass) or the least dimming of white (dark glass) that
  /// keeps [FrostedColorScheme.textPrimary], `textSecondary` and
  /// `textTertiary` at [bodyContrast] and `textQuiet` at [quietContrast]
  /// over black, white and saturated colours, and over the glass raised on
  /// another. So the guarantee is the glass's, not a backdrop's.
  static FrostedMaterials derive(FrostedThemeData theme) =>
      _derived[theme] ??= _derive(theme);

  /// What a page can put behind glass: the extremes and the saturated hues.
  static const List<Color> _behind = [
    Color(0xFF000000),
    Color(0xFFFFFFFF),
    Color(0xFFFF0000),
    Color(0xFF00FF00),
    Color(0xFF0000FF),
    Color(0xFFFFFF00),
    Color(0xFFFF00FF),
    Color(0xFF00FFFF),
  ];

  static FrostedMaterials _derive(FrostedThemeData t) {
    final dark = t.isDark;
    final body = [
      t.colorScheme.textPrimary,
      t.colorScheme.textSecondary,
      t.colorScheme.textTertiary,
    ];
    final tintColour = t.glass.fill.withValues(alpha: 1);
    final wellColour = dark
        ? Color.lerp(tintColour, const Color(0xFF000000), .35)!
        : Color.lerp(tintColour, t.colorScheme.background, .55)!;
    const white = Color(0xFFFFFFFF);
    const black = Color(0xFF000000);
    final ink = t.colorScheme.textPrimary;
    final rim = dark
        ? white.withValues(alpha: .10)
        : ink.withValues(alpha: .07);
    final sheen = dark
        ? white.withValues(alpha: .16)
        : white.withValues(alpha: .95);
    final shadowInk = dark ? black : ink;
    BoxShadow drop(double y, double blur, double alpha) => BoxShadow(
      color: shadowInk.withValues(alpha: alpha),
      offset: Offset(0, y),
      blurRadius: blur,
    );

    // One glass: its look, and the range that keeps its words. [span] caps
    // how far the lightness behind it reaches through (light glass lifts its
    // floor, dark glass lowers its ceiling): colour still comes through, the
    // shape of a dark or a bright thing behind does not.
    FrostedMaterialRecipe glass({
      required double blur,
      required double saturation,
      required Color tint,
      required Color raised,
      double span = 1,
      Color? rimColour,
      Color? sheenColour,
      Color? shade,
      List<BoxShadow> shadows = const <BoxShadow>[],
    }) {
      FrostedMaterialRecipe at(double range, Color opaque) =>
          FrostedMaterialRecipe(
            blur: blur,
            saturation: saturation,
            floor: dark ? 0 : range,
            ceiling: dark ? range : 1,
            tint: tint,
            raised: raised,
            rim: rimColour ?? rim,
            sheen: sheenColour ?? sheen,
            shade: shade,
            shadows: shadows,
            opaque: opaque,
          );
      // Light glass: the least floor that reads; dark: the greatest ceiling.
      var lo = 0.0, hi = 1.0;
      for (var i = 0; i < 24; i++) {
        final mid = (lo + hi) / 2;
        final reads = _reads(at(mid, black), body, t.colorScheme.textTertiary);
        if (dark == reads) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      final range = dark ? math.min(lo, span) : math.max(hi, 1 - span);
      final probe = at(range, black);
      return at(range, probe.groundOver(t.colorScheme.background));
    }

    Color tint(Color c, double a) => c.withValues(alpha: a);
    return FrostedMaterials(
      sheer: glass(
        blur: 18,
        saturation: dark ? 1.5 : 1.8,
        tint: tint(tintColour, dark ? .34 : .28),
        raised: dark
            ? white.withValues(alpha: .06)
            : white.withValues(alpha: .55),
        shadows: [drop(1, 2, dark ? .30 : .04), drop(8, 24, dark ? .30 : .06)],
      ),
      pane: glass(
        blur: 22,
        saturation: dark ? 1.5 : 1.8,
        tint: tint(tintColour, dark ? .40 : .36),
        raised: dark
            ? white.withValues(alpha: .08)
            : white.withValues(alpha: .7),
        shadows: [drop(1, 2, dark ? .28 : .05)],
      ),
      well: glass(
        blur: 10,
        saturation: dark ? 1.3 : 1.4,
        tint: tint(wellColour, dark ? .46 : .34),
        raised: dark
            ? black.withValues(alpha: .22)
            : ink.withValues(alpha: .04),
        rimColour: dark
            ? white.withValues(alpha: .08)
            : ink.withValues(alpha: .10),
        sheenColour: dark
            ? white.withValues(alpha: .04)
            : white.withValues(alpha: .0),
        shade: dark ? black.withValues(alpha: .35) : ink.withValues(alpha: .07),
      ),
      // The thickest glass, what floats over the page: a dark or a bright
      // control below moves a row's ground by a few percent at most
      // (glass_test.dart), while the colour behind still glows through.
      slab: glass(
        blur: 40,
        saturation: dark ? 1.4 : 1.7,
        tint: tint(tintColour, dark ? .62 : .6),
        span: .22,
        raised: dark
            ? white.withValues(alpha: .07)
            : white.withValues(alpha: .65),
        rimColour: dark
            ? white.withValues(alpha: .14)
            : ink.withValues(alpha: .08),
        shadows: [drop(2, 6, dark ? .35 : .06), drop(24, 64, dark ? .50 : .16)],
      ),
      bar: glass(
        blur: 26,
        saturation: dark ? 1.5 : 1.8,
        tint: tint(tintColour, dark ? .48 : .44),
        raised: dark
            ? white.withValues(alpha: .08)
            : white.withValues(alpha: .7),
      ),
      scrim: dark
          ? black.withValues(alpha: .42)
          : t.colorScheme.textPrimary.withValues(alpha: .18),
      soften: 6,
    );
  }

  /// Whether every body text reads at [bodyContrast], and the quiet text at
  /// [quietContrast], on [glass] over everything in [_behind], flat or
  /// raised on another glass.
  static bool _reads(
    FrostedMaterialRecipe glass,
    List<Color> body,
    Color quiet,
  ) {
    double ratio(Color c, Color g) {
      final l = c.computeLuminance();
      final lg = g.computeLuminance();
      return (math.max(l, lg) + .05) / (math.min(l, lg) + .05);
    }

    for (final behind in _behind) {
      final ground = glass.groundOver(behind);
      for (final g in [ground, Color.alphaBlend(glass.raised, ground)]) {
        // A margin of 0.1 over the floor: the blur's mixing and the
        // renderer's rounding never take the words under it.
        for (final c in body) {
          if (ratio(c, g) < bodyContrast + .1) return false;
        }
        if (ratio(quiet, g) < quietContrast + .1) return false;
      }
    }
    return true;
  }
}

/// What stands behind every page, for the glass to show: the preset's
/// [light], a [night] sky, an [image], or a [plain] colour. A theme carries
/// one ([FrostedThemeData.backdrop]); `FrostedScaffold` paints it, still,
/// behind the page as the page scrolls over it.
@immutable
class FrostedBackdrop {
  const FrostedBackdrop._(this.kind, {this.color, this.image});

  /// The preset's dawn: its three washes over the page's ground, the whole
  /// screen through.
  const FrostedBackdrop.dawn() : this._(FrostedBackdropKind.dawn);

  /// A night sky: deep blue into violet, two glows of light low over it and
  /// a scatter of stars.
  const FrostedBackdrop.night() : this._(FrostedBackdropKind.night);

  /// A photograph or painting, covering the screen.
  const FrostedBackdrop.image(ImageProvider image)
    : this._(FrostedBackdropKind.image, image: image);

  /// One colour; null takes the theme's ground.
  const FrostedBackdrop.plain([Color? color])
    : this._(FrostedBackdropKind.plain, color: color);

  /// Which backdrop it is.
  final FrostedBackdropKind kind;

  /// A plain backdrop's colour.
  final Color? color;

  /// An image backdrop's picture.
  final ImageProvider? image;

  /// Whether the backdrop is dark enough that light glass over it reads as
  /// a lit pane rather than a page (the night sky).
  bool get isDark => kind == FrostedBackdropKind.night;

  @override
  bool operator ==(Object other) =>
      other is FrostedBackdrop &&
      other.kind == kind &&
      other.color == color &&
      other.image == image;

  @override
  int get hashCode => Object.hash(kind, color, image);

  @override
  String toString() => 'FrostedBackdrop.${kind.name}';
}

/// The kinds of [FrostedBackdrop].
enum FrostedBackdropKind {
  /// The preset's dawn: three washes of its light over its ground.
  dawn,

  /// The night sky.
  night,

  /// An image.
  image,

  /// One colour.
  plain,
}
