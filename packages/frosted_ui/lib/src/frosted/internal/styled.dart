import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';
import 'corner.dart';

/// A part's style layers read at its states: its own `style:`, then its
/// component theme's ([FrostedComponentThemes]), the first value of each
/// slot winning; a slot neither sets returns null, and the part falls back
/// to the theme's knobs and then the look's own. Plumbing of the components.
@immutable
class FrostedStyleLayers {
  /// The layers of [own] over [theme], read at [states]; [look], the theme
  /// a style's `corners` are drawn in (none drawn without it).
  const FrostedStyleLayers(
    this.own,
    this.theme, [
    this.states = const <WidgetState>{},
    this.look,
  ]);

  /// The widget's own style.
  final FrostedStyle? own;

  /// The part's component theme.
  final FrostedStyle theme;

  /// The states the slots resolve against.
  final Set<WidgetState> states;

  /// The theme a style's `corners` are drawn in: its scale and Frosted's
  /// limits.
  final FrostedThemeData? look;

  /// These layers read at [states].
  FrostedStyleLayers at(Set<WidgetState> states) =>
      FrostedStyleLayers(own, theme, states, look);

  /// Whether neither layer sets a slot.
  bool get isEmpty => (own?.isEmpty ?? true) && theme.isEmpty;

  T? _first<T>(WidgetStateProperty<T?>? Function(FrostedStyle style) slot) =>
      FrostedStyle.first([own, theme], slot, states);

  /// The face's fill.
  Color? get fill => _first((s) => s.fill);

  /// The words', glyphs' or mark's colour.
  Color? get foreground => _first((s) => s.foreground);

  /// The edge's colour.
  Color? get edge => _first((s) => s.edge);

  /// The wash over the face.
  Color? get overlay => _first((s) => s.overlay);

  /// The whole edge.
  BorderSide? get side => _first((s) => s.side);

  /// The outline the style gives (its `shape`), as given.
  OutlinedBorder? get shape => _first((s) => s.shape);

  /// The corners the style gives (its `corners`), each its own step.
  RawCorners? get corners => _first((s) => s.corners);

  /// The outline an app gives a part whose own outline is [knob] (a
  /// [FrostedCorners] outline, or a stadium), [own] its radius where the
  /// part's differs from [knob]'s: the style's [shape], as given; else the
  /// style's [corners] over the part's own (each corner it leaves out keeps
  /// the part's), held to [FrostedThemeData.shapeLimits] and drawn in
  /// [look]'s scale, start and end following the reading direction; else
  /// null.
  ///
  /// A piece of a strip of them (a segment, the plate sliding under it)
  /// takes only the corners on the strip's ends: the start ones where it
  /// [starts] the strip, the end ones where it [ends] it; the joins keep the
  /// piece's own.
  OutlinedBorder? given(
    OutlinedBorder knob, {
    double? own,
    bool starts = true,
    bool ends = true,
  }) {
    final given = shape;
    if (given != null) return given;
    final t = look;
    final override = _sides(corners, starts: starts, ends: ends);
    if (override == null || override.isEmpty || t == null) return null;
    final step = frostedStepOf(knob);
    final scale = t.shapeScheme.corners;
    final at = own ?? t.corner(step, frostedCornerOf(knob) ?? 0);
    return _at(scale, step, at).borderOf(_held(override, step));
  }

  /// The outline of a piece standing [by] inside a part this style cuts
  /// ([knob] the part's own outline; [own] the piece's own corner), as a
  /// menu's row stands in its menu: each corner the style gives on the
  /// piece's sides ([tops], [bottoms]) concentric with the part's, [by]
  /// less; the others the piece's own. Null where the style gives no
  /// corners there, or gives a shape (the piece keeps its own).
  OutlinedBorder? within(
    OutlinedBorder knob, {
    required double own,
    required double by,
    bool tops = true,
    bool bottoms = true,
  }) {
    final t = look;
    if (shape != null || t == null) return null;
    final override = _sides(corners, tops: tops, bottoms: bottoms);
    if (override == null || override.isEmpty) return null;
    final step = frostedStepOf(knob);
    final s = t.shapeScheme.corners;
    double less(double r) => math.max(0, r - by);
    final inner = s.copyWith(
      extraSmall: less(s.extraSmall),
      small: less(s.small),
      medium: less(s.medium),
      large: less(s.large),
      extraLarge: less(s.extraLarge),
    );
    return _at(inner, step, own).borderOf(_held(override, step));
  }

  // [given] held to Frosted's bands over [step] on every corner.
  static RawCorners _held(RawCorners given, RawCorner step) => FrostedThemeData
      .shapeLimits
      .clampCorners(given, base: RawCorners.all(step), look: 'Frosted');

  // [scale] with [step] at [at]: a part's own corner where it is not its
  // step's.
  static RawCornerScale _at(RawCornerScale scale, RawCorner step, double at) =>
      switch (step) {
        RawCorner.extraSmall => scale.copyWith(extraSmall: at),
        RawCorner.small => scale.copyWith(small: at),
        RawCorner.medium => scale.copyWith(medium: at),
        RawCorner.large => scale.copyWith(large: at),
        RawCorner.extraLarge => scale.copyWith(extraLarge: at),
        RawCorner.none || RawCorner.full => scale,
      };

  // The corners of [c] on the sides named, the others left to the part.
  static RawCorners? _sides(
    RawCorners? c, {
    bool starts = true,
    bool ends = true,
    bool tops = true,
    bool bottoms = true,
  }) => c == null
      ? null
      : RawCorners(
          topStart: starts && tops ? c.topStart : null,
          topEnd: ends && tops ? c.topEnd : null,
          bottomStart: starts && bottoms ? c.bottomStart : null,
          bottomEnd: ends && bottoms ? c.bottomEnd : null,
        );

  /// The room inside the face.
  EdgeInsetsGeometry? get padding => _first((s) => s.padding);

  /// The face's least size.
  Size? get minimumSize => _first((s) => s.minimumSize);

  /// The words' style.
  TextStyle? get textStyle => _first((s) => s.textStyle);

  /// The glyphs' size.
  double? get iconSize => _first((s) => s.iconSize);

  /// The outline the part is cut to: the style's, else [knob] (the look's
  /// corner the part reads, a [FrostedCorners] outline). Null for a stadium, which the
  /// part draws round by its own height as the look does.
  OutlinedBorder? cut(OutlinedBorder knob, {bool corners = true}) {
    final shape = (corners ? given(knob) : this.shape) ?? knob;
    return shape is StadiumBorder ? null : shape;
  }

  /// [knob] (a [FrostedCorners] outline) as [t]'s shapes move it
  /// ([FrostedThemeData.corner]): its corner at its step of [t]'s scale.
  static OutlinedBorder moved(FrostedThemeData t, OutlinedBorder knob) {
    final r = frostedCornerOf(knob);
    if (r == null || knob is! RoundedRectangleBorder) return knob;
    return knob.copyWith(
      borderRadius: BorderRadius.circular(t.corner(frostedStepOf(knob), r)),
    );
  }

  /// [FrostedCorners.medium]'s and [FrostedCorners.large]'s radii: what a
  /// surface's own corner is measured from.
  static const double stockMedium = 18, stockLarge = 22;

  /// The outline a surface the look rounds to [look] is cut to, and the
  /// radius it draws: the style's shape; else [step]'s kind of corner (a
  /// [FrostedCorners] outline), moved as far from [look] as the step stands
  /// from [stock], so a surface keeps the look's own corner. A rounded step is drawn as a
  /// radius (a null outline).
  (OutlinedBorder?, double) surface(
    OutlinedBorder step,
    double stock,
    double look,
  ) {
    final own = shape;
    if (own != null) return (own, radiusOf(own, 0, look));
    final cornered = given(step, own: look);
    if (cornered != null) return (cornered, look);
    final r = frostedCornerOf(step);
    if (r == null) return (step, look);
    final at = math.max(0.0, look + r - stock);
    final corners = BorderRadius.circular(at);
    return switch (step) {
      RoundedRectangleBorder() => (null, at),
      final RoundedSuperellipseBorder b => (
        b.copyWith(borderRadius: corners),
        at,
      ),
      final BeveledRectangleBorder b => (b.copyWith(borderRadius: corners), at),
      final ContinuousRectangleBorder b => (
        b.copyWith(borderRadius: corners * 2.3),
        at,
      ),
      _ => (step, at),
    };
  }

  /// The corner radius [cut] gives a face of [height], for what draws a
  /// radius (a focus ring, a clip); [look] when it gives none.
  static double radiusOf(OutlinedBorder? cut, double height, double look) =>
      switch (cut) {
        null => look,
        RoundedRectangleBorder(:final borderRadius) ||
        RoundedSuperellipseBorder(:final borderRadius) ||
        BeveledRectangleBorder(
          :final borderRadius,
        ) => borderRadius.resolve(TextDirection.ltr).topLeft.x,
        StadiumBorder() || CircleBorder() => height / 2,
        _ => look,
      };

  /// [cut] grown by [by] all round (shrunk when [by] is negative, its
  /// corners no less than square), for the part that holds a face cut to it
  /// (a strip round its segments, a knob inside its track), so the two run
  /// concentric; null stays null.
  static OutlinedBorder? around(OutlinedBorder? cut, double by) {
    BorderRadiusGeometry grow(BorderRadiusGeometry radius) {
      final r = radius.resolve(TextDirection.ltr);
      // A square corner stays square.
      double move(double r) => r == 0 ? 0 : math.max(0, r + by);
      Radius moved(Radius x) => Radius.elliptical(move(x.x), move(x.y));
      return BorderRadius.only(
        topLeft: moved(r.topLeft),
        topRight: moved(r.topRight),
        bottomLeft: moved(r.bottomLeft),
        bottomRight: moved(r.bottomRight),
      );
    }

    return switch (cut) {
      null => null,
      final RoundedRectangleBorder b => b.copyWith(
        borderRadius: grow(b.borderRadius),
      ),
      final RoundedSuperellipseBorder b => b.copyWith(
        borderRadius: grow(b.borderRadius),
      ),
      final BeveledRectangleBorder b => b.copyWith(
        borderRadius: grow(b.borderRadius),
      ),
      // An app's corners: concentric as ui_core draws them, a square corner
      // staying square.
      final RawCornerBorder b => b.outset(EdgeInsets.all(by)),
      _ => cut,
    };
  }

  /// The edge's colour and widths: the [side]'s when set (none when its
  /// style is none or its width 0), else [edge] or [look] at [width].
  (Color?, EdgeInsets) edgeOf(Color? look, double width) {
    final side = this.side;
    if (side != null) {
      return side.style == BorderStyle.none || side.width <= 0
          ? (null, EdgeInsets.zero)
          : (side.color, EdgeInsets.all(side.width));
    }
    return (edge ?? look, EdgeInsets.all(width));
  }

  /// [look] in the [foreground] colour and with the [textStyle] merged over
  /// it.
  TextStyle words(TextStyle look) {
    final ink = foreground;
    final own = textStyle;
    final coloured = ink == null ? look : look.copyWith(color: ink);
    return own == null ? coloured : coloured.merge(own);
  }

  /// [child] held to at least the [minimumSize].
  Widget least(Widget child) {
    final size = minimumSize;
    if (size == null) return child;
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: size.width, minHeight: size.height),
      child: child,
    );
  }
}
