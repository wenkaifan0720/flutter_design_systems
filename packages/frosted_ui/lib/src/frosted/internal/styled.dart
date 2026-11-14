import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import 'corner.dart';

/// A part's style layers read at its states: its own `style:`, then its
/// component theme's ([FrostedComponentThemes]), the first value of each
/// slot winning; a slot neither sets returns null, and the part falls back
/// to the theme's knobs and then the look's own. Plumbing of the components.
@immutable
class FrostedStyleLayers {
  /// The layers of [own] over [theme], read at [states].
  const FrostedStyleLayers(
    this.own,
    this.theme, [
    this.states = const <WidgetState>{},
  ]);

  /// The widget's own style.
  final FrostedStyle? own;

  /// The part's component theme.
  final FrostedStyle theme;

  /// The states the slots resolve against.
  final Set<WidgetState> states;

  /// These layers read at [states].
  FrostedStyleLayers at(Set<WidgetState> states) =>
      FrostedStyleLayers(own, theme, states);

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

  /// The outline.
  OutlinedBorder? get shape => _first((s) => s.shape);

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
  OutlinedBorder? cut(OutlinedBorder knob) {
    final shape = this.shape ?? knob;
    return shape is StadiumBorder ? null : shape;
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
