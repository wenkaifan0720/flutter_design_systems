// The charts, in wells. Data is in ink; only what's live takes the pigment: now, today, what's still coming. No chart takes a colour: a
// chart says which point is now, and the pigment follows. Numbers never stand alone in a well: axes and a key say what they are.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart' show listEquals, mapEquals;

import '../frames.dart';
import '../internal/geometry.dart';
import '../heads.dart';
import '../layout.dart';
import '../localizations.dart';
import '../ornaments.dart';
import '../rows.dart';
import '../theme.dart';

/// How a key's swatch is drawn.
/// The visual key used by a chart legend.
enum NeumorphicLegendSwatch {
  /// A solid mark in the neutral ink.
  ink,

  /// A solid mark in the active pigment.
  live,

  /// A line sample for a continuous trace.
  line,
}

/// One line of a chart's key.
class NeumorphicLegendItem {
  /// Creates a [NeumorphicLegendItem].
  const NeumorphicLegendItem(
    this.label, {
    this.kind = NeumorphicLegendSwatch.ink,
  });

  /// The text identifying this item or control.
  final String label;

  /// The stroke or fill represented by this legend entry.
  final NeumorphicLegendSwatch kind;
}

/// A chart's key: a swatch and words per series. A note with no swatch needs [NeumorphicLegendItem.kind] ink and a blank.
///
/// ```dart
/// NeumorphicLegend(const [NeumorphicLegendItem('Used'), NeumorphicLegendItem('Made', kind: NeumorphicLegendSwatch.live)])
/// ```
class NeumorphicLegend extends StatelessWidget {
  /// Creates a [NeumorphicLegend].
  const NeumorphicLegend(this.items, {super.key, this.note});

  /// The legend entries, in display order.
  final List<NeumorphicLegendItem> items;

  /// Words with no swatch that say what the key is of ('Today'), at its head in bold. At its end, in the items' own
  /// style, it read as a series that had lost its swatch.
  final String? note;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    return Wrap(
      spacing: 18,
      runSpacing: 6,
      children: [
        if (note != null)
          Text(
            note!,
            style: t.textTheme.micro.copyWith(fontWeight: FontWeight.w700),
          ),
        for (final k in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (k.kind == NeumorphicLegendSwatch.line)
                // A piece of the plotted line, its ends round as the line's are: data, not a part's corner.
                neumorphicOwnSize(
                  width: 14,
                  height: 10,
                  child: CustomPaint(painter: _LineSwatch(c.pigment)),
                )
              else
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: k.kind == NeumorphicLegendSwatch.live
                        ? c.pigment
                        : c.inkSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 8),
              Flexible(child: Text(k.label, style: t.textTheme.micro)),
            ],
          ),
      ],
    );
  }
}

class _LineSwatch extends CustomPainter {
  const _LineSwatch(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    canvas.drawLine(
      Offset(1.5, y),
      Offset(size.width - 1.5, y),
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_LineSwatch old) => old.color != color;
}

class _Xaxis extends StatelessWidget {
  const _Xaxis({required this.labels, this.now});

  /// Where to put each word, 0 to 1 across.
  final Map<double, String> labels;
  final (double, String)? now;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final style = t.textTheme.micro.tabular;
    final nowStyle = style.copyWith(
      color: t.colors.pigmentInk,
      fontWeight: FontWeight.w800,
    );
    // As tall as its words at the reader's size: held at 16, twice the text hung its words over the key below.
    final painter = TextPainter(
      text: TextSpan(text: '0', style: nowStyle),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final line = painter.height;
    painter.dispose();
    return SizedBox(
      height: math.max(16, line),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: LayoutBuilder(
          builder: (context, box) {
            Widget at(double f, String word, TextStyle s) => Positioned(
              left: f * box.maxWidth - 40,
              width: 80,
              top: 0,
              child: Text(
                word,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: s,
              ),
            );
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (final e in labels.entries)
                  if (now == null || (e.key - now!.$1).abs() > .07)
                    at(e.key, e.value, style),
                if (now != null) at(now!.$1, now!.$2, nowStyle),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TwoWayPainter extends CustomPainter {
  _TwoWayPainter(
    this.c,
    this.flat,
    this.above,
    this.below,
    this.slots,
    this.now, {
    this.round = true,
  });
  final NeumorphicColors c;
  final bool flat;

  /// Round-ended bars; false in the square corner family.
  final bool round;
  final List<double> above;
  final Map<int, double> below;
  final int slots;
  final double? now;
  static const _axis = 112.0;
  @override
  void paint(Canvas canvas, Size s) {
    canvas.save();
    canvas.scale(s.width / 480, s.height / 156);
    final unit = 480 / slots;
    final barW = unit / 2;
    final peak = above.fold<double>(0, math.max);
    final deep = below.values.fold<double>(0, math.max);
    final k = math.min(
      peak > 0 ? 104.5 / peak : 55.0,
      deep > 0 ? 38 / deep : 55.0,
    );
    if (flat) {
      canvas.drawRect(
        Rect.fromLTWH(0, _axis + 1, 480, 1),
        neumorphicFillPaint(c.quiet),
      );
    } else {
      canvas.drawLine(
        const Offset(0, _axis + 1.5),
        const Offset(480, _axis + 1.5),
        neumorphicStrokePaint(c.crease, 1.5, round: false),
      );
      canvas.drawLine(
        const Offset(0, _axis + 3),
        const Offset(480, _axis + 3),
        neumorphicStrokePaint(c.rim, 1.5, round: false),
      );
    }
    final nowSlot = now?.floor();
    for (var h = 0; h < slots; h++) {
      final x = h * unit + unit / 4;
      if (h < above.length) {
        final v = above[h] * k;
        if (v > 0) {
          final r = Rect.fromLTWH(x, _axis - v, barW, v);
          // Round at its outer end only, square on the axis: rounded at both ends, a value under the bar's width
          // closed into a circle or a lozenge and its size no longer read.
          final end = Radius.circular(round ? math.min(barW / 2, v) : 0);
          canvas.drawRRect(
            RRect.fromRectAndCorners(r, topLeft: end, topRight: end),
            Paint()
              ..isAntiAlias = true
              ..shader = cssLinear(r, 180, [
                h == nowSlot ? c.barStart.withValues(alpha: .45) : c.barStart,
                h == nowSlot ? c.barEnd.withValues(alpha: .45) : c.barEnd,
              ]),
          );
        }
      } else {
        canvas.drawCircle(
          Offset(x + barW / 2, _axis - 4),
          2,
          neumorphicFillPaint(c.quiet),
        );
      }
      final b = below[h];
      if (b != null && b > 0) {
        final r = Rect.fromLTWH(x, _axis + 6, barW, b * k);
        final end = Radius.circular(round ? math.min(barW / 2, b * k) : 0);
        canvas.drawRRect(
          RRect.fromRectAndCorners(r, bottomLeft: end, bottomRight: end),
          Paint()
            ..isAntiAlias = true
            ..shader = cssLinear(r, 180, [c.pigment, c.pigmentHi]),
        );
      }
    }
    if (now != null) {
      final nx = now! * unit;
      canvas.drawPath(
        neumorphicDashed(
          Path()
            ..moveTo(nx, 14)
            ..lineTo(nx, _axis - 1),
          2,
          3,
        ),
        neumorphicStrokePaint(c.pigment, 1.5, round: false),
      );
      canvas.drawCircle(Offset(nx, 12), 4.5, neumorphicFillPaint(c.pigment));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TwoWayPainter o) =>
      o.c != c ||
      o.flat != flat ||
      !listEquals(o.above, above) ||
      !mapEquals(o.below, below) ||
      o.slots != slots ||
      o.now != now ||
      o.round != round;
}

/// Two directions per slot across a day, mirrored over an engraved axis: what went one way above in ink, what came back below in the pigment.
/// Slots still to come are dots. The dashed line and its bead are now. Bars mean a count in that slot.
///
/// ```dart
/// NeumorphicTwoWayBars(above: const [.6, .5, 1.1], below: const {1: .3}, slots: 24, now: 2.5, labels: const {0: '00', 6: '06', 12: '12'}, nowLabel: '02:30', keys: const [NeumorphicLegendItem('Used'), NeumorphicLegendItem('Made', kind: NeumorphicLegendSwatch.live)])
/// ```
class NeumorphicTwoWayBars extends StatelessWidget {
  /// Creates a [NeumorphicTwoWayBars].
  const NeumorphicTwoWayBars({
    super.key,
    required this.above,
    this.below = const {},
    this.slots = 24,
    this.now,
    this.labels = const {},
    this.nowLabel,
    this.peak,
    this.keys = const [],
  });

  /// Values drawn above the baseline, one per slot.
  final List<double> above;

  /// By slot.
  final Map<int, double> below;

  /// The number of positions reserved on the horizontal axis.
  final int slots;

  /// Where now stands, in slots: 20.17 is a sixth of the way through slot 20.
  final double? now;

  /// An axis word per slot.
  final Map<int, String> labels;

  /// The label attached to the current-position marker.
  final String? nowLabel;

  /// A word over the tallest bar: its value.
  final String? peak;

  /// The legend entries for the plotted series.
  final List<NeumorphicLegendItem> keys;
  @override
  Widget build(BuildContext context) {
    if (above.isEmpty && below.isEmpty) {
      return NeumorphicEmptyState(
        title: NeumorphicLocalizations.of(context).nothingToShow,
      );
    }
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final count = slots > 0 ? slots : 1;
    final top = above.isEmpty ? 0 : above.indexOf(above.reduce(math.max));
    final topValue = above.fold<double>(0, math.max);
    return NeumorphicFill(
      maxWidth: 760,
      alignment: AlignmentDirectional.topStart,
      child: NeumorphicColumn(
        children: [
          NeumorphicWell(
            padding: const EdgeInsets.fromLTRB(14, 34, 14, 14),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: LayoutBuilder(
                builder: (context, box) {
                  final w = box.maxWidth;
                  final h = w * 156 / 480;
                  final unit = w / count;
                  final kUnit = math.min(
                    topValue > 0 ? 104.5 / topValue : 55.0,
                    below.isEmpty
                        ? 55.0
                        : 38 / below.values.reduce(math.max).clamp(.001, 1e9),
                  );
                  final peakY = (112 - topValue * kUnit) * h / 156;
                  return SizedBox.fromSize(
                    size: Size(w, h),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _TwoWayPainter(
                              c,
                              NeumorphicFlatScope.of(context),
                              above,
                              below,
                              count,
                              now,
                              round: true,
                            ),
                          ),
                        ),
                        if (peak != null)
                          // Its foot 5 over the bar, so it grows upward with the text: held by its top at 18 over,
                          // at twice the text it sank into the bar.
                          Positioned(
                            left: (top + .5) * unit - 30,
                            width: 60,
                            bottom: h - peakY + 5,
                            child: Text(
                              peak!,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: t.textTheme.micro
                                  .copyWith(
                                    color: c.ink,
                                    fontWeight: FontWeight.w700,
                                  )
                                  .tabular,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _Xaxis(
              labels: {
                for (final e in labels.entries) (e.key + .5) / count: e.value,
              },
              now: now == null || nowLabel == null
                  ? null
                  : (now! / count, nowLabel!),
            ),
          ),
          if (keys.isNotEmpty) ...[
            const SizedBox(height: 12),
            NeumorphicLegend(keys),
          ],
        ],
      ),
    );
  }
}

/// A round step for about [raw] a gridline: 1, 2, 2.5 or 5 times a power of ten.
double _roundStep(double raw) {
  if (!raw.isFinite || raw <= 0) return 1;
  final power = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final f = raw / power;
  final nice = f <= 1
      ? 1.0
      : f <= 2
      ? 2.0
      : f <= 2.5
      ? 2.5
      : f <= 5
      ? 5.0
      : 10.0;
  return nice * power;
}

/// The column bars' plot: 280 by 150 units, the base at 146 and [_columnTop] at the top gridline.
const double _columnBase = 146, _columnTop = 10;

class _ColumnPainter extends CustomPainter {
  _ColumnPainter(
    this.c,
    this.values,
    this.now,
    this.forecast, {
    required this.high,
    required this.ticks,
    required this.flat,
    this.round = true,
  });
  final NeumorphicColors c;

  /// Round-topped columns; false in the square corner family.
  final bool round;
  final List<double> values;
  final int? now;
  final double? forecast;

  /// The top gridline's value: the scale runs from zero to it.
  final double high;

  /// The gridlines' values, each a round step.
  final List<double> ticks;
  final bool flat;
  @override
  void paint(Canvas canvas, Size s) {
    canvas.save();
    canvas.scale(s.width / 280, s.height / 150);
    // One engraved gridline a step, under the columns; the gutter beside the plot labels each.
    for (final v in ticks) {
      final y =
          _columnBase - (high <= 0 ? 0 : v / high) * (_columnBase - _columnTop);
      canvas.drawLine(
        Offset(0, y),
        Offset(280, y),
        neumorphicStrokePaint(flat ? c.quiet : c.crease, 1, round: false),
      );
    }
    if (values.isNotEmpty) {
      final k = high > 0 ? (_columnBase - _columnTop) / high : 0.0;
      const base = _columnBase;
      final unit = 280 / values.length;
      final w = math.min(12.0, unit * .6);
      for (var i = 0; i < values.length; i++) {
        final x = i * unit + (unit - w) / 2;
        final h = values[i] * k;
        if (i == now && forecast != null && forecast! > values[i]) {
          final fh = forecast! * k;
          final r = round ? w / 2 : 0.0;
          canvas.drawPath(
            neumorphicDashed(
              Path()
                ..moveTo(x, base - h + r)
                ..lineTo(x, base - fh + r)
                ..arcToPoint(
                  Offset(x + w, base - fh + r),
                  radius: Radius.circular(r),
                )
                ..lineTo(x + w, base - h + r),
              3,
              3,
            ),
            neumorphicStrokePaint(c.pigment, 1.5, round: false),
          );
        }
        if (h > 0) {
          // In the bars' own paint, as the two-way bars and the share bars are: in a flat ink the columns stood over
          // moulded bars on the same page, two kinds of bar one above the other (fresh-eyes round 11).
          final r = Rect.fromLTWH(x, base - h, w, h);
          canvas.drawRRect(
            RRect.fromRectAndRadius(r, Radius.circular(round ? w / 2 : 0)),
            Paint()
              ..isAntiAlias = true
              ..shader = cssLinear(
                r,
                180,
                i == now ? [c.pigment, c.pigmentHi] : [c.barStart, c.barEnd],
              ),
          );
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ColumnPainter o) =>
      o.c != c ||
      !listEquals(o.values, values) ||
      o.now != now ||
      o.forecast != forecast ||
      o.high != high ||
      !listEquals(o.ticks, ticks) ||
      o.flat != flat ||
      o.round != round;
}

/// A few periods side by side, in a well, each in ink; the one that's [now] goes to the pigment, with a dashed open cap for where it's heading.
/// Gridlines stand on round steps from zero, each labelled beside the plot, and a key under it says what the pigment
/// column is ([nowLabel]) and what its dashed cap is ([forecastLabel]). In a stretched card it stands at the well's foot.
///
/// ```dart
/// NeumorphicColumnBars(values: const [23.9, 22.1, 17.8], labels: const ['Mon', 'Tue', 'Wed'], now: 2, nowLabel: 'Today', forecast: 20.6)
/// ```
class NeumorphicColumnBars extends StatelessWidget {
  /// Creates a [NeumorphicColumnBars].
  const NeumorphicColumnBars({
    super.key,
    required this.values,
    this.labels = const [],
    this.now,
    this.forecast,
    this.nowLabel,
    this.forecastLabel,
    this.format,
  });

  /// The height of each column in data units.
  final List<double> values;

  /// Labels corresponding to the columns.
  final List<String> labels;

  /// The index of the column emphasized as current.
  final int? now;

  /// An optional forecast cap above the current column.
  final double? forecast;

  /// What the pigment column is, in the key: 'Today'. Null says the localized 'Now'.
  final String? nowLabel;

  /// What the dashed cap is, in the key. Null says the localized 'Forecast'.
  final String? forecastLabel;

  /// A gridline's label; null writes the number in the locale's digits.
  final String Function(double value)? format;
  @override
  Widget build(BuildContext context) {
    final words = NeumorphicLocalizations.of(context);
    if (values.isEmpty) {
      return NeumorphicEmptyState(title: words.nothingToShow);
    }
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    // About four round steps from zero over the tallest column or cap; the top gridline is the scale's top.
    final most = [...values, ?forecast].fold<double>(0, math.max);
    final step = _roundStep(math.max(most, 1e-9) / 4);
    final count = math.max(1, (most / step - 1e-9).ceil());
    final high = count * step;
    final ticks = [for (var i = 0; i <= count; i++) i * step];
    String fmt(double v) =>
        format?.call(v) ??
        words.formatNumber(v, maximumFractionDigits: step < 1 ? 1 : 0);
    final tickStyle = t.textTheme.micro.tabular;
    final scaler = MediaQuery.textScalerOf(context);
    var gutter = 0.0, tickHeight = 0.0;
    for (final v in ticks) {
      final painter = TextPainter(
        text: TextSpan(text: fmt(v), style: tickStyle),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      gutter = math.max(gutter, painter.width);
      tickHeight = math.max(tickHeight, painter.height);
      painter.dispose();
    }
    gutter = gutter.ceilToDouble();
    const gap = 8.0;
    final shown = now != null && now! >= 0 && now! < values.length;
    // As wide as the kit's other charts (680): at 520 its well stopped short of theirs, a ragged edge down the column.
    return NeumorphicFill(
      maxWidth: 680,
      alignment: AlignmentDirectional.topStart,
      child: NeumorphicColumn(
        children: [
          NeumorphicGrow(
            child: NeumorphicWell(
              // The top label stands centred on its gridline: half a line of room over the plot.
              padding: EdgeInsets.fromLTRB(
                8,
                math.max(12, tickHeight / 2 + 4),
                8,
                // The zero's label stands half under the base: room for it, as above the top tick.
                math.max(10, tickHeight / 2 + 4),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final width = math.max(0.0, box.maxWidth - gutter - gap);
                      final height = width * 150 / 280;
                      double y(double v) =>
                          (_columnBase -
                              (high <= 0 ? 0 : v / high) *
                                  (_columnBase - _columnTop)) *
                          height /
                          150;
                      return SizedBox(
                        height: height,
                        child: Row(
                          children: [
                            neumorphicOwnSize(
                              width: gutter,
                              height: height,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  for (final v in ticks)
                                    Positioned(
                                      right: 0,
                                      top: y(v) - tickHeight / 2,
                                      child: Text(fmt(v), style: tickStyle),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: gap),
                            neumorphicOwnSize(
                              width: width,
                              height: height,
                              child: CustomPaint(
                                painter: _ColumnPainter(
                                  c,
                                  values,
                                  now,
                                  forecast,
                                  high: high,
                                  ticks: ticks,
                                  flat: NeumorphicFlatScope.of(context),
                                  round: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (labels.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              // Under the plot: past the well's padding, the gutter and its gap.
              padding: EdgeInsets.only(left: 8 + gutter + gap, right: 8),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      Expanded(
                        child: Text(
                          labels[i],
                          textAlign: TextAlign.center,
                          style: i == now
                              ? t.textTheme.micro.copyWith(
                                  color: c.pigmentInk,
                                  fontWeight: FontWeight.w800,
                                )
                              : t.textTheme.micro,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          // The key: what the pigment column is, and its dashed cap. On the chart's edge, as every chart's key stands,
          // a line under the days: past the gutter it stood 34 in, and pressed to the days' labels.
          if (shown)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: NeumorphicLegend([
                NeumorphicLegendItem(
                  nowLabel ?? words.now,
                  kind: NeumorphicLegendSwatch.live,
                ),
                if (forecast != null && forecast! > values[now!])
                  NeumorphicLegendItem(
                    forecastLabel ?? words.forecast,
                    kind: NeumorphicLegendSwatch.line,
                  ),
              ]),
            ),
        ],
      ),
    );
  }
}

class _StepPainter extends CustomPainter {
  _StepPainter({
    required this.c,
    required this.flat,
    required this.readings,
    required this.steps,
    required this.now,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
    required this.ticks,
  });
  final NeumorphicColors c;
  final bool flat;
  final List<(double, double)> readings, steps;
  final double? now;
  final double xMin, xMax, yMin, yMax;
  final List<double> ticks;
  double _x(double v) => (v - xMin) / (xMax - xMin) * 480;
  double _y(double v) => 242 - (v - yMin) / (yMax - yMin) * 240;
  @override
  void paint(Canvas canvas, Size s) {
    canvas.save();
    canvas.scale(s.width / 480, s.height / 256);
    for (final t in ticks) {
      final y = _y(t);
      canvas.drawLine(
        Offset(0, y),
        Offset(480, y),
        neumorphicStrokePaint(flat ? c.quiet : c.crease, 1, round: false),
      );
    }
    if (readings.length > 1) {
      final pts = [for (final r in readings) Offset(_x(r.$1), _y(r.$2))];
      final line = neumorphicMonotonePath(pts);
      final area = Path.from(line)
        ..lineTo(pts.last.dx, 248)
        ..lineTo(pts.first.dx, 248)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..isAntiAlias = true
          ..shader = cssLinear(const Rect.fromLTWH(0, 0, 480, 248), 180, [
            c.area,
            c.area.withValues(alpha: 0),
          ]),
      );
      _steps(canvas);
      canvas.drawPath(line, neumorphicStrokePaint(c.ink, 2.4));
    } else {
      _steps(canvas);
    }
    if (now != null && readings.isNotEmpty) {
      final at = Offset(_x(readings.last.$1), _y(readings.last.$2));
      canvas.drawCircle(at, 5.5, neumorphicFillPaint(c.pigment));
      canvas.drawCircle(at, 5.5, neumorphicStrokePaint(c.faceStart, 2.5));
    }
    canvas.restore();
  }

  void _steps(Canvas canvas) {
    if (steps.isEmpty) return;
    final nx = now == null ? 480.0 : _x(now!);
    final past = Path(), future = Path();
    var pastOn = false, futureOn = false;
    double? pastY;
    for (var i = 0; i < steps.length - 1; i++) {
      final x0 = _x(steps[i].$1), x1 = _x(steps[i + 1].$1);
      final y = _y(steps[i].$2);
      if (x0 < nx) {
        final end = math.min(x1, nx);
        pastOn ? past.lineTo(x0, y) : past.moveTo(x0, y);
        past.lineTo(end, y);
        pastOn = true;
        pastY = y;
      }
      if (x1 > nx) {
        final begin = math.max(x0, nx);
        if (futureOn) {
          future.lineTo(begin, y);
        } else {
          // The future starts where the past stopped: a step at now rises from the past's level (dashed, to come),
          // else the set line read as two broken lines.
          future.moveTo(begin, pastY ?? y);
          future.lineTo(begin, y);
        }
        future.lineTo(x1, y);
        futureOn = true;
      }
    }
    canvas.drawPath(past, neumorphicStrokePaint(c.pigment, 2, round: false));
    canvas.drawPath(
      neumorphicDashed(future, 4, 5),
      neumorphicStrokePaint(c.pigment.withValues(alpha: .8), 2, round: false),
    );
  }

  @override
  bool shouldRepaint(_StepPainter o) =>
      o.c != c ||
      o.flat != flat ||
      !listEquals(o.readings, readings) ||
      !listEquals(o.steps, steps) ||
      o.xMin != xMin ||
      o.xMax != xMax ||
      o.yMin != yMin ||
      o.yMax != yMax ||
      !listEquals(o.ticks, ticks) ||
      o.now != now;
}

/// A reading over a day against what was set: the reading a curve in ink that never overshoots a point, the set point a stepped line in the
/// pigment, solid to now and dashed after. Use it where a target moves in steps.
///
/// ```dart
/// NeumorphicStepLine(readings: const [(0, 18.6), (12, 17.6), (20, 21)], steps: const [(0, 17), (6.5, 20.5), (24, 17)], now: 20, xMax: 24, yMin: 16, yMax: 22, yTicks: const [17, 19, 21], yLabel: '°', xLabels: const [(0, '00'), (12, '12'), (24, '24')])
/// ```
class NeumorphicStepLine extends StatelessWidget {
  /// Creates a [NeumorphicStepLine].
  const NeumorphicStepLine({
    super.key,
    required this.readings,
    this.steps = const [],
    this.now,
    this.xMin = 0,
    required this.xMax,
    required this.yMin,
    required this.yMax,
    this.yTicks = const [],
    this.yLabel = '',
    this.xLabels = const [],
    this.keys = const [],
    this.note,
  });

  /// Ordered x/y observations drawn as the continuous trace.
  final List<(double, double)> readings;

  /// Ordered x/y values drawn as a stepped target line.
  final List<(double, double)> steps;

  /// The current x position, or null to omit its marker.
  final double? now;

  /// The lower bound of the horizontal scale.
  final double xMin;

  /// The upper bound of the horizontal scale.
  final double xMax;

  /// The lower bound of the vertical scale.
  final double yMin;

  /// The upper bound of the vertical scale.
  final double yMax;

  /// The values labelled on the vertical axis.
  final List<double> yTicks;

  /// What follows each y figure: a unit, as written (`'°'`; a unit word brings its own space, `' kW'`).
  final String yLabel;

  /// Horizontal positions paired with their displayed labels.
  final List<(double, String)> xLabels;

  /// The legend entries for the plotted series.
  final List<NeumorphicLegendItem> keys;

  /// Supporting text displayed with the primary content.
  final String? note;
  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty && steps.isEmpty) {
      return NeumorphicEmptyState(
        title: NeumorphicLocalizations.of(context).nothingToShow,
      );
    }
    final t = NeumorphicTheme.of(context);
    final style = t.textTheme.micro.tabular;
    final span = xMax > xMin ? xMax - xMin : 1;
    final ySpan = yMax > yMin ? yMax - yMin : 1;
    return NeumorphicFill(
      maxWidth: 680,
      alignment: AlignmentDirectional.topStart,
      child: NeumorphicColumn(
        children: [
          NeumorphicWell(
            padding: const EdgeInsets.fromLTRB(38, 18, 14, 12),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: LayoutBuilder(
                builder: (context, box) {
                  final w = box.maxWidth;
                  final h = w * 256 / 480;
                  return SizedBox.fromSize(
                    size: Size(w, h),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _StepPainter(
                              c: t.colors,
                              flat: NeumorphicFlatScope.of(context),
                              readings: readings,
                              steps: steps,
                              now: now,
                              xMin: xMin,
                              xMax: xMin + span,
                              yMin: yMin,
                              yMax: yMin + ySpan,
                              ticks: yTicks,
                            ),
                          ),
                        ),
                        for (final v in yTicks)
                          Positioned(
                            left: -30,
                            top: (242 - (v - yMin) / ySpan * 240) * h / 256,
                            // Centred on its gridline by its own height, at any text size (a fixed 8 left
                            // twice-size labels hanging under their lines).
                            child: FractionalTranslation(
                              translation: const Offset(0, -.5),
                              child: Text(
                                '${NeumorphicLocalizations.of(context).formatNumber(v, maximumFractionDigits: 6)}$yLabel',
                                maxLines: 1,
                                style: style,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(38, 0, 14, 0),
            child: _Xaxis(
              labels: {for (final e in xLabels) (e.$1 - xMin) / span: e.$2},
            ),
          ),
          if (keys.isNotEmpty || note != null) ...[
            const SizedBox(height: 18),
            NeumorphicLegend(keys, note: note),
          ],
        ],
      ),
    );
  }
}

/// One line of a [NeumorphicShareBars].
class NeumorphicShare {
  /// Creates a [NeumorphicShare].
  const NeumorphicShare(this.label, this.figure, this.share);

  /// The text identifying this item or control.
  final String label;

  /// The formatted value to display.
  final String figure;

  /// 0 to 1, of the whole.
  final double share;
}

/// How a total splits: a word and its figure over a groove with a bar in ink. Longest first. No pigment: these are shares, not live.
///
/// ```dart
/// NeumorphicShareBars(rows: const [NeumorphicShare('A kind', '9.4', .53), NeumorphicShare('Another', '3.1', .17)])
/// ```
class NeumorphicShareBars extends StatelessWidget {
  /// Creates a [NeumorphicShareBars].
  const NeumorphicShareBars({super.key, required this.rows, this.title});

  /// The shares, in display order.
  final List<NeumorphicShare> rows;

  /// A small head over them.
  final String? title;
  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return NeumorphicEmptyState(
        title: NeumorphicLocalizations.of(context).nothingToShow,
      );
    }
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final flat = NeumorphicFlatScope.of(context);
    return NeumorphicColumn(
      gap: 12,
      children: [
        if (title != null) NeumorphicSubHead(title!),
        for (final r in rows)
          NeumorphicColumn(
            gap: 6,
            children: [
              NeumorphicSplit(
                gap: 12,
                start: Text(
                  r.label,
                  style: t.textTheme.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                end: Text(
                  r.figure,
                  textAlign: TextAlign.end,
                  style: t.textTheme.caption
                      .copyWith(fontWeight: FontWeight.w700, color: c.ink)
                      .tabular,
                ),
              ),
              neumorphicPaint(null, 10, (c, flat, r.share, t.shapes), (
                canvas,
                s,
              ) {
                final track = Offset.zero & s;
                final border = t.shapes.capsule;
                neumorphicPaintPressed(
                  canvas,
                  border.getOuterPath(track),
                  c,
                  light: (const Offset(-3, -3), 7),
                  dark: (const Offset(3, 3), 7),
                  flat: flat,
                );
                if (t.highContrast) {
                  border
                      .copyWith(side: BorderSide(color: c.quiet))
                      .paint(canvas, track);
                }
                final w = s.width * r.share.clamp(0, 1);
                if (w > 0) {
                  final dir = Directionality.of(context);
                  final fill = dir == TextDirection.rtl
                      ? Rect.fromLTRB(s.width - w, 0, s.width, s.height)
                      : Rect.fromLTRB(0, 0, w, s.height);
                  canvas.drawPath(
                    border.getOuterPath(fill),
                    Paint()
                      ..isAntiAlias = true
                      ..shader = cssLinear(fill, 90, [c.barStart, c.barEnd]),
                  );
                }
              }),
            ],
          ),
      ],
    );
  }
}
