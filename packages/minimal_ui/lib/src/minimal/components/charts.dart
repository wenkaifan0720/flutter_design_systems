/// Bar charts in the quiet ink with one bar in the full ink, and sparklines.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../internal/controls.dart';
import '../localizations.dart';
import '../theme.dart';
import 'pressable.dart';

/// A bar chart for a short series — a week of check-ins, a day of orders:
/// thin square-shouldered bars on a hairline baseline, mono axis labels
/// under them, and exactly one bar in the full ink, the highest unless
/// [highlight] names another. Every other bar stays in the quiet ink; a
/// zero draws no bar at all.
///
/// With [onBarPressed] each bar is a control (the wash, the focus ring, a 44 px
/// hit column): a page keeps the tapped index and passes it back as
/// [highlight] to read one bar out.
///
/// ```dart
/// MinimalBarChart([4, 9, 6, 12], labels: ['M', 'T', 'W', 'T'])
/// ```
class MinimalBarChart extends StatelessWidget {
  /// A bar for each of [values].
  const MinimalBarChart(
    this.values, {
    super.key,
    this.labels,
    this.height = 120,
    this.highlight,
    this.onBarPressed,
    this.semanticLabel,
  });

  /// The bars' values, in order.
  final List<double> values;

  /// One short axis label per bar (`M`, `09`, `W34`), printed in mono.
  final List<String>? labels;

  /// The plot's height, above the label strip.
  final double height;

  /// The bar drawn in the full ink; null takes the highest.
  final int? highlight;

  /// Makes every bar a control that reports its index.
  final ValueChanged<int>? onBarPressed;

  /// What a screen reader announces for the chart as a whole; each bar
  /// reads its own label and value after it.
  final String? semanticLabel;

  /// The widest a bar paints, however wide its slot: the chart stays an
  /// instrument, never a wall of blocks.
  static const double maxBarWidth = 12;

  static String _figure(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final labelStyle = t.countFigure.c(t.mutedForeground);
    final max = values.isEmpty ? 0.0 : values.reduce(math.max);
    final scale = max <= 0 ? 1.0 : max;
    final lit = highlight ?? (max > 0 ? values.indexOf(max) : -1);
    final names = labels;

    Widget bar(int i) {
      final v = values[i];
      final on = i == lit;
      final fraction = (v / scale).clamp(0.0, 1.0);
      final column = SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, box) => Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: math.min(maxBarWidth, box.maxWidth * 0.6),
              // A zero draws nothing over the baseline: no bar, no stub.
              height: v > 0 ? math.max(fraction * height, 2) : 0,
              decoration: BoxDecoration(
                // The bar read out is said in the ink; a chart is no act
                // to take, so it never wears the accent.
                color: on ? t.foreground : t.textTertiary,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(t.smallRadius / 2),
                ),
              ),
            ),
          ),
        ),
      );
      final name = names != null && i < names.length ? names[i] : null;
      final announced =
          '${name ?? MinimalLocalizations.of(context).bar(i + 1)}: ${_figure(v)}';
      final cell = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(border: Border(bottom: t.rule)),
            child: column,
          ),
          if (names != null) ...[
            const MinimalGap(MinimalSpacing.s4),
            Text(
              name ?? '',
              style: on ? labelStyle.c(t.foreground).medium : labelStyle,
              maxLines: 1,
              overflow: TextOverflow.clip,
              softWrap: false,
            ),
          ],
        ],
      );
      final tap = onBarPressed;
      if (tap == null) {
        return Semantics(
          container: true,
          label: announced,
          child: ExcludeSemantics(child: cell),
        );
      }
      return MinimalPressable(
        onPressed: () => tap(i),
        shape: t.shapes.mark,
        semanticLabel: announced,
        selected: on,
        child: ExcludeSemantics(child: cell),
      );
    }

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++) Expanded(child: bar(i)),
        ],
      ),
    );
  }
}

/// A trend line with no axes — the shape of a series inside a stat, a KPI
/// cell or a row, never a chart in its own right: a 1.6 px line with round
/// joins over a faint area, ending on a dot where the series stands now.
/// The line spans the series' own range; a flat series (every value
/// equal) runs through the middle of the box, steady rather than zero.
/// Time runs from the start edge, as in Minimal's bar and line charts: right
/// to left, the series begins at the right and stands now on the left.
///
/// ```dart
/// MinimalSparkline(weekly, height: 26, color: t.success)
/// ```
class MinimalSparkline extends StatelessWidget {
  /// A line through [data].
  const MinimalSparkline(
    this.data, {
    super.key,
    this.height = 40,
    this.color,
    this.area = true,
    this.endDot = true,
    this.semanticLabel,
  });

  /// The values, in order.
  final List<double> data;

  /// Its height.
  final double height;

  /// Null takes the accent.
  final Color? color;

  /// Fill the faint area under the line.
  final bool area;

  /// Mark the last point, where the series stands now.
  final bool endDot;

  /// What a screen reader announces ('Revenue, rising'); null keeps the
  /// line out of the semantics tree as the decoration it usually is.
  final String? semanticLabel;

  /// The line's stroke.
  static const double stroke = 1.6;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final paint = SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(
          data,
          color ?? t.primary,
          area: area,
          endDot: endDot,
          rtl: Directionality.of(context) == TextDirection.rtl,
        ),
      ),
    );
    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: paint);
    return Semantics(label: label, image: true, child: paint);
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(
    this.data,
    this.color, {
    required this.area,
    required this.endDot,
    required this.rtl,
  });

  final List<double> data;
  final Color color;
  final bool area;
  final bool endDot;

  /// Whether time runs from the right.
  final bool rtl;

  static const double _dot = 2.2;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final lo = data.reduce(math.min);
    final hi = data.reduce(math.max);
    final flat = hi == lo;
    final range = flat ? 1.0 : hi - lo;
    // The dot's radius is kept clear on every edge so it never clips.
    const pad = _dot + MinimalSparkline.stroke / 2;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;

    Offset at(int i) {
      final along = i / (data.length - 1) * w;
      return Offset(
        rtl ? size.width - pad - along : pad + along,
        flat ? size.height / 2 : pad + h - (data[i] - lo) / range * h,
      );
    }

    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < data.length; i++) {
      line.lineTo(at(i).dx, at(i).dy);
    }
    if (area) {
      final fill = Path.from(line)
        ..lineTo(at(data.length - 1).dx, size.height)
        ..lineTo(at(0).dx, size.height)
        ..close();
      canvas.drawPath(fill, Paint()..color = color.withValues(alpha: 0.12));
    }
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = MinimalSparkline.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..color = color,
    );
    if (endDot) {
      canvas.drawCircle(at(data.length - 1), _dot, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.data != data ||
      old.color != color ||
      old.area != area ||
      old.endDot != endDot ||
      old.rtl != rtl;
}
