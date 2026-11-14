/// The contribution grid: weeks by seven days, three intensities, today
/// outlined.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../localizations.dart';
import '../theme.dart';

/// A habit's or a contributor's record as a grid of small squares — one
/// column per week, seven days down (Monday first), oldest week at the
/// start: at the left, or at the right in a right-to-left language, so
/// time runs the way the page's charts run. Each day is a level: 0 nothing
/// (the hairline colour, by night the stronger hairline's), 1 some (the
/// success colour at half strength), 2 full (success); days past the end of
/// [levels] are the future and stay blank. [today] is outlined in the ink.
///
/// Squares are 11 px on 3 px gaps, and shrink to fit when the weeks would
/// run past the width, however many there are: the grid never paints past
/// its box. Past about a year at phone width the squares fall under 4 px
/// and stop reading as days, so show a year at most. Today's mark is one
/// ink rim just inside its square's edge, the day's own level still showing
/// in the middle, so it reads the same on a kept day and an empty one and
/// the square stays its neighbours' size, inside the grid. [legend] adds
/// the `Less ▢▢▢ More` key under it.
///
/// ```dart
/// MinimalHeatmap(levels: last84, today: 81)
/// ```
class MinimalHeatmap extends StatelessWidget {
  /// A grid of day squares, each shaded by its value.
  const MinimalHeatmap({
    super.key,
    required this.levels,
    this.weeks,
    this.today,
    this.legend = false,
    this.semanticLabel,
  });

  /// One level (0, 1 or 2) per day, oldest first, column by column.
  final List<int> levels;

  /// How many week columns to draw; null takes as many as [levels] fills.
  final int? weeks;

  /// The index into [levels] of today.
  final int? today;

  /// Show the three-step key under the grid.
  final bool legend;

  /// What a screen reader announces; null composes `71 of 81 days kept`
  /// over the days recorded (the future is not counted). Pass one built
  /// from the same figures when a header above prints the record.
  final String? semanticLabel;

  /// A square's side at full size, and the gap between two.
  static const double cell = 11;

  /// The gap between two squares at full size.
  static const double gap = 3;

  /// Today's ink rim at full size, inside its square's edge; it thins with
  /// the squares, so the day's level always shows in the middle.
  static const double ringStroke = 1.5;

  /// The fill of [level] in [t]. An empty day is the hairline's grey; by
  /// night the stronger hairline's, since a small square of the hairline
  /// all but sinks into the dark ground. The middle step is the success
  /// tone at 45% by day and 60% by night, so it stands about as far from
  /// the empty grey as from the full tone in both (at 45% by night it sat
  /// next to the raised empty grey).
  static Color levelColor(MinimalThemeData t, int level) => switch (level) {
    <= 0 => t.isLightAppearance ? t.border : t.borderStrong,
    1 => t.success.withValues(alpha: t.isLightAppearance ? 0.45 : 0.6),
    _ => t.success,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final columns = weeks ?? (levels.length / 7).ceil();
    final kept = levels.where((l) => l > 0).length;
    final grid = LayoutBuilder(
      builder: (context, box) {
        // Squares and gaps shrink together: a column is cell + gap at full
        // size, scaled to share out the width (the last column's gap is
        // the slack that keeps the grid inside it).
        final fit = box.hasBoundedWidth
            ? box.maxWidth / math.max(columns, 1) * cell / (cell + gap)
            : cell;
        final side = math.max(0.0, math.min(cell, fit));
        final space = side < cell ? gap * side / cell : gap;
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: CustomPaint(
            size: Size(
              math.max(0.0, columns * (side + space) - space),
              7 * (side + space) - space,
            ),
            painter: _HeatmapPainter(
              levels: levels,
              columns: columns,
              today: today,
              side: side,
              space: space,
              colors: [for (var l = 0; l <= 2; l++) levelColor(t, l)],
              ring: t.foreground,
              rtl: Directionality.of(context) == TextDirection.rtl,
            ),
          ),
        );
      },
    );
    return Semantics(
      label: semanticLabel ?? '$kept of ${levels.length} days kept',
      image: true,
      excludeSemantics: true,
      child: !legend
          ? grid
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                grid,
                const MinimalGap(MinimalSpacing.s8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      MinimalLocalizations.of(context).less,
                      style: t.caption,
                    ),
                    const MinimalGap(6),
                    for (var l = 0; l <= 2; l++) ...[
                      if (l > 0) const MinimalGap(gap),
                      Container(
                        width: cell,
                        height: cell,
                        decoration: BoxDecoration(
                          color: levelColor(t, l),
                          borderRadius: BorderRadius.circular(
                            t.smallRadius / 2,
                          ),
                        ),
                      ),
                    ],
                    const MinimalGap(6),
                    Text(
                      MinimalLocalizations.of(context).more,
                      style: t.caption,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.levels,
    required this.columns,
    required this.today,
    required this.side,
    required this.space,
    required this.colors,
    required this.ring,
    required this.rtl,
  });

  final List<int> levels;
  final int columns;
  final int? today;
  final double side;
  final double space;
  final List<Color> colors;
  final Color ring;

  /// Whether the oldest week stands at the right.
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final corner = Radius.circular(side * 2 / 11);
    for (var i = 0; i < columns * 7 && i < levels.length; i++) {
      final along = (i ~/ 7) * (side + space);
      final rect = Rect.fromLTWH(
        rtl ? size.width - along - side : along,
        (i % 7) * (side + space),
        side,
        side,
      );
      final level = levels[i].clamp(0, 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, corner),
        Paint()..color = colors[level],
      );
      if (i == today && side > 0) {
        // The current day is said in ink, as Minimal says every current
        // thing: one rim just inside the square's edge, so the square stays
        // its neighbours' size, the day's level still shows in the middle
        // and the mark is the same on any level. It thins with the squares
        // (1.5 px at 11 px).
        final stroke = math.min(
          MinimalHeatmap.ringStroke,
          side * MinimalHeatmap.ringStroke / MinimalHeatmap.cell,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.deflate(stroke / 2),
            Radius.circular(math.max(0, corner.x - stroke / 2)),
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..color = ring,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HeatmapPainter old) =>
      old.levels != levels ||
      old.columns != columns ||
      old.today != today ||
      old.side != side ||
      old.space != space ||
      old.ring != ring ||
      old.rtl != rtl ||
      old.colors[0] != colors[0] ||
      old.colors[1] != colors[1] ||
      old.colors[2] != colors[2];
}
