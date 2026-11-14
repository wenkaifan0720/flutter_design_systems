/// The n-of-m segmented summary bar and a row's inline week of squares.
library;

import 'package:flutter/widgets.dart';

import '../theme.dart';
import 'tag.dart';

/// A count out of a small whole as a row of segments — `3/5 kept` as three
/// filled of five: one 6 px segment per unit with 3 px between, filled in
/// the tone from the start, the rest in the hairline colour. Past 24 units
/// the segments would be slivers, so use [MinimalLinearProgressIndicator]
/// instead.
///
/// With [label] the bar leads with its figure (`3` in the ink, `/5 kept`
/// quiet); [showPercent] ends it with the mono percentage — the Today
/// summary line. The percentage stands in a slot as wide as `100%`, so the
/// bar's end holds still as the figure changes. Bars stacked in a column
/// give each the same [labelWidth], so their segments start on one line
/// too.
///
/// ```dart
/// MinimalSegmentBar(value: 3, total: 5, label: 'kept', showPercent: true)
/// ```
class MinimalSegmentBar extends StatelessWidget {
  /// A count out of a whole, as segments.
  const MinimalSegmentBar({
    super.key,
    required this.value,
    required this.total,
    this.tone = MinimalTone.success,
    this.label,
    this.labelWidth,
    this.showPercent = false,
    this.semanticLabel,
  }) : assert(total >= 0 && total <= 24, 'a segment bar holds 0–24 units'),
       assert(value >= 0, 'a segment bar counts up from zero');

  /// How many units are filled; clamped to [total].
  final int value;

  /// How many units the whole has. Zero draws one empty track (`0/0`).
  final int total;

  /// The filled segments' colour.
  final MinimalTone tone;

  /// The noun after the figure (`kept`, `done`); null draws the bar alone.
  final String? label;

  /// The width of the figure and its noun, grown with the text scale as
  /// the words grow: the words stand at its start, and longer ones keep
  /// their own width. Null gives them their own width.
  final double? labelWidth;

  /// End with the mono percentage.
  final bool showPercent;

  /// What a screen reader announces; null composes `3 of 5 kept`.
  final String? semanticLabel;

  /// A segment's height, and the gap between two.
  static const double thickness = 6;

  /// The gap between two segments.
  static const double gap = 3;

  /// The space between the figure, the bar and the percentage.
  static const double spacing = 10;

  /// A segment's corner: half the small radius, a square with its edges
  /// softened, shared with [MinimalWeekDots].
  static double cornerOf(MinimalThemeData t) => t.smallRadius / 2;

  /// The slot every percentage stands in: the widest one, `100%`, at the
  /// text scale.
  static double _percentSlot(BuildContext context, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: '100%', style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width.ceilToDouble();
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final filled = value.clamp(0, total);
    final percent = total == 0 ? '—' : '${(filled * 100 / total).round()}%';
    final noun = label;
    final duration = context.minimalStill ? Duration.zero : MinimalMotion.fast;
    final segments = Row(
      children: [
        for (var i = 0; i < (total == 0 ? 1 : total); i++) ...[
          if (i > 0) const MinimalGap(gap),
          Expanded(
            child: AnimatedContainer(
              duration: duration,
              height: thickness,
              decoration: BoxDecoration(
                color: i < filled ? t.tone(tone).indicator : t.border,
                borderRadius: BorderRadius.circular(cornerOf(t)),
              ),
            ),
          ),
        ],
      ],
    );
    final announced =
        semanticLabel ?? '$filled of $total${noun == null ? '' : ' $noun'}';
    if (noun == null && !showPercent) {
      return Semantics(
        label: announced,
        value: percent,
        excludeSemantics: true,
        child: segments,
      );
    }
    final Widget? figure = noun == null
        ? null
        : Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$filled',
                  style: t.bodySmall.semibold.copyWith(
                    fontFeatures: t.mono.fontFeatures,
                  ),
                ),
                TextSpan(
                  text: '/$total $noun',
                  style: t.bodySmall.c(t.mutedForeground),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
    final percentStyle = t.mono.c(t.mutedForeground);
    final percentWidth = showPercent
        ? _percentSlot(context, percentStyle)
        : 0.0;
    final count = total == 0 ? 1 : total;
    // The bar never shrinks past its gaps and a short run of track: on a
    // narrow line at large text the figure's words give way (ellipsized)
    // rather than push the row past its edge.
    final least = (count - 1) * gap + count * 2 + 24;
    return Semantics(
      label: announced,
      value: percent,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) {
          Widget? lead = figure;
          if (lead != null) {
            final room = box.maxWidth.isFinite
                ? (box.maxWidth -
                          spacing -
                          least -
                          (showPercent ? spacing + percentWidth : 0))
                      .clamp(0.0, double.infinity)
                : double.infinity;
            final width = labelWidth;
            final slot = width == null
                ? 0.0
                : MediaQuery.textScalerOf(context).scale(width);
            lead = ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: slot < room ? slot : room,
                maxWidth: room,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: 1,
                heightFactor: 1,
                child: lead,
              ),
            );
          }
          return Row(
            children: [
              if (lead != null) ...[lead, const MinimalGap(spacing)],
              Expanded(child: segments),
              if (showPercent) ...[
                const MinimalGap(spacing),
                SizedBox(
                  width: percentWidth,
                  child: Text(
                    percent,
                    style: percentStyle,
                    maxLines: 1,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// A row's inline week — seven 7 px squares, oldest first: the kept days
/// in the ink, the rest in the hairline colour, and today ringed in the ink
/// with its own day inside (kept or not, as the heatmap marks today), so the
/// row never loses its place in the week and a kept today shows. It sits
/// [MinimalSegmentBar.spacing] before a row's trailing streak count.
///
/// ```dart
/// MinimalWeekDots(completedDays: [false, true, true, true, true, false, false], currentDay: 4)
/// ```
class MinimalWeekDots extends StatelessWidget {
  /// A week as seven squares.
  const MinimalWeekDots({
    super.key,
    required this.completedDays,
    this.currentDay,
    this.color,
    this.semanticLabel,
  });

  /// Whether each day of the week was kept, oldest first.
  final List<bool> completedDays;

  /// The index of today, ringed; null when the week is past.
  final int? currentDay;

  /// The kept days' colour; null takes the ink.
  final Color? color;

  /// What a screen reader announces; null composes `4 of 7 days kept`.
  final String? semanticLabel;

  /// A square's side, and the gap between two.
  static const double square = 7;

  /// The gap between two squares.
  static const double gap = 2;

  /// Today's ring, drawn inside the square.
  static const double ring = 1.5;

  @override
  Widget build(BuildContext context) {
    // A const list's length is not a constant, so the week is checked here.
    assert(completedDays.length == 7, 'a week has seven days');
    final t = context.minimalTheme;
    final ink = color ?? t.foreground.withValues(alpha: 0.78);
    final count = completedDays.where((k) => k).length;
    final corner = MinimalSegmentBar.cornerOf(t);
    return Semantics(
      label: semanticLabel ?? '$count of 7 days kept',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const MinimalGap(gap),
            Container(
              width: square,
              height: square,
              decoration: BoxDecoration(
                color: completedDays[i] ? ink : t.border,
                borderRadius: BorderRadius.circular(corner),
                border: i == currentDay
                    ? Border.all(color: t.foreground, width: ring)
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
