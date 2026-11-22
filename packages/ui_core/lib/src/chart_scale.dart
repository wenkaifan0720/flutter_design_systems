/// Chart scales: values (a number, a time's milliseconds, a category's
/// index) to positions on screen and back, and the ticks between, labelled
/// in the reader's numbers and dates, and [DesignChartValueFormat], a
/// value's words with its unit. No widgets: [DesignChart] makes them for its
/// plot, and a look may make its own.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'date_field.dart' show RawTimeOfDay;
import 'internal/decimal.dart' as decimal;
import 'localizations.dart';

/// A tick on a scale: a [value], its [position], its [label].
@immutable
class DesignScaleTick {
  /// A tick.
  const DesignScaleTick({
    required this.value,
    required this.position,
    required this.label,
    this.fractionDigits,
  });

  /// The value it marks: a number, a time's milliseconds since the epoch,
  /// or a category's index.
  final double value;

  /// Where it stands, in the scale's positions.
  final double position;

  /// Its label, in the reader's numbers and dates.
  final String label;

  /// The decimals its scale writes every tick's value with (a step of 0.2
  /// writes 1), so a format writes them alike
  /// ([DesignChartValueFormat.labelTicks]); null for a category's or a
  /// time's tick.
  final int? fractionDigits;

  /// The width of the widest of [ticks]' labels set in [style] at
  /// [textScaler], for the room a look keeps for them beside a plot
  /// ([DesignChart.yLabelGutter]); 0 when there are none.
  ///
  /// ```dart
  /// DesignScaleTick.widestLabel(details.yTicks, style: const TextStyle(fontSize: 12), textScaler: MediaQuery.textScalerOf(context))
  /// ```
  static double widestLabel(
    Iterable<DesignScaleTick> ticks, {
    required TextStyle style,
    TextScaler textScaler = TextScaler.noScaling,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    var widest = 0.0;
    final painter = TextPainter(
      textDirection: textDirection,
      textScaler: textScaler,
    );
    for (final tick in ticks) {
      painter
        ..text = TextSpan(text: tick.label, style: style)
        ..layout();
      widest = math.max(widest, painter.width);
    }
    painter.dispose();
    return widest;
  }

  @override
  bool operator ==(Object other) =>
      other is DesignScaleTick &&
      other.value == value &&
      other.position == position &&
      other.label == label &&
      other.fractionDigits == fractionDigits;

  @override
  int get hashCode => Object.hash(value, position, label, fractionDigits);

  @override
  String toString() => 'DesignScaleTick($label at $position)';
}

/// Values to positions and back.
///
/// ```dart
/// const DesignLinearScale(min: 0, max: 100, start: 0, end: 300).map(50)
/// ```
abstract class DesignScale {
  /// A scale over the positions [start] to [end].
  const DesignScale({required this.start, required this.end});

  /// The position of the least value (left, or right when the scale runs
  /// right to left; the bottom of a y scale).
  final double start;

  /// The position of the greatest value.
  final double end;

  /// The position of [value].
  double map(double value);

  /// The value at [position].
  double invert(double position);

  /// About [count] ticks across the scale, labelled for [localizations].
  List<DesignScaleTick> ticks(
    RawWidgetsLocalizations localizations, {
    int count = 5,
  });
}

/// A number line: [min] at [start], [max] at [end].
///
/// ```dart
/// DesignLinearScale.nice(min: 3, max: 97, start: 300, end: 0)
/// ```
class DesignLinearScale extends DesignScale {
  /// A scale from [min] to [max] exactly.
  const DesignLinearScale({
    required this.min,
    required this.max,
    required super.start,
    required super.end,
    this.divisions,
  }) : assert(divisions == null || divisions > 0);

  /// A scale widened to whole ticks: [min] and [max] out to the nearest
  /// multiples of a 1, 2 or 5 × 10ⁿ step that gives about [tickCount]
  /// ticks, and to 0 when [includeZero]. A single value widens by one
  /// each way; zeros alone with [includeZero] (an empty week) run from 0 up
  /// in whole steps, as a week with data counts (0 1 2 3 4 for about five
  /// ticks, or one step per division), never below zero. With [divisions],
  /// the scale covers the data in exactly that many equal intervals,
  /// rounding the span up to 1, 2, 2.5 or 5 × 10ⁿ.
  factory DesignLinearScale.nice({
    required double min,
    required double max,
    required double start,
    required double end,
    int tickCount = 5,
    bool includeZero = false,
    int? divisions,
  }) {
    assert(divisions == null || divisions > 0);
    var lo = math.min(min, max);
    var hi = math.max(min, max);
    if (includeZero) {
      lo = math.min(lo, 0);
      hi = math.max(hi, 0);
    }
    if (lo == hi && includeZero && lo == 0) {
      // Nothing to scale but zero: count up from it in ones.
      var ones = divisions ?? math.max(1, tickCount - 1);
      while (divisions == null &&
          _tickStep(0, ones.toDouble(), tickCount) < 1) {
        ones++;
      }
      return DesignLinearScale(
        min: 0,
        max: ones.toDouble(),
        start: start,
        end: end,
        divisions: divisions,
      );
    }
    if (lo == hi) {
      lo -= 1;
      hi += 1;
    }
    if (divisions != null) {
      final range = hi - lo;
      final unit = math
          .pow(10, (math.log(range) / math.ln10).floor())
          .toDouble();
      final span = const [1.0, 2.0, 2.5, 5.0, 10.0]
          .map((factor) => factor * unit)
          .firstWhere((width) => width >= range, orElse: () => 10 * unit);
      final step = span / divisions;
      // Keep zero on an end for a one-sided domain that includes it. For
      // other domains align the lower bound to a step if both ends fit.
      final aligned = (lo / step).floorToDouble() * step;
      final lower = hi == 0
          ? -span
          : aligned + span >= hi
          ? aligned
          : lo;
      return DesignLinearScale(
        min: lower,
        max: math.max(hi, lower + span),
        start: start,
        end: end,
        divisions: divisions,
      );
    }
    // Until the step holds: widening can change it, and the ticks are read
    // at the step of the widened bounds (d3's nice).
    double? last;
    for (var i = 0; i < 10; i++) {
      final step = _tickStep(lo, hi, tickCount);
      if (step == last) break;
      final digits = decimal.decimalsOf(step);
      lo = decimal.roundTo((lo / step).floorToDouble() * step, digits);
      hi = decimal.roundTo((hi / step).ceilToDouble() * step, digits);
      last = step;
    }
    return DesignLinearScale(min: lo, max: hi, start: start, end: end);
  }

  /// The least value.
  final double min;

  /// The greatest value.
  final double max;

  /// The exact number of equal intervals, or null to choose whole-number
  /// steps for the tick count requested by [ticks].
  final int? divisions;

  @override
  double map(double value) {
    if (max == min) return (start + end) / 2;
    return start + (value - min) / (max - min) * (end - start);
  }

  @override
  double invert(double position) {
    if (end == start) return min;
    return min + (position - start) / (end - start) * (max - min);
  }

  @override
  List<DesignScaleTick> ticks(
    RawWidgetsLocalizations localizations, {
    int count = 5,
  }) {
    if (max <= min) {
      return [
        DesignScaleTick(
          value: min,
          position: map(min),
          label: localizations.formatDecimal(min),
          fractionDigits: decimal.decimalsOf(min),
        ),
      ];
    }
    if (divisions case final n?) {
      final step = (max - min) / n;
      final digits = math.min(
        math.max(decimal.decimalsOf(min), decimal.decimalsOf(step)),
        math.max(0, -(math.log(step) / math.ln10).floor()) + 2,
      );
      return [
        for (var i = 0; i <= n; i++)
          if ((i == n ? max : min + i * step) case final value)
            DesignScaleTick(
              value: value,
              position: map(value),
              label: localizations.formatDecimal(value, fractionDigits: digits),
              fractionDigits: digits,
            ),
      ];
    }
    final step = _tickStep(min, max, count);
    final digits = decimal.decimalsOf(step);
    final first = (min / step - 1e-9).ceil();
    final last = (max / step + 1e-9).floor();
    return [
      for (var i = first; i <= last; i++)
        if (decimal.roundTo(i * step, digits) case final value)
          DesignScaleTick(
            value: value,
            position: map(value),
            label: localizations.formatDecimal(value, fractionDigits: digits),
            fractionDigits: digits,
          ),
    ];
  }

  @override
  String toString() => 'DesignLinearScale($min–$max → $start–$end)';
}

// A 1, 2 or 5 × 10ⁿ step giving about [count] ticks from [lo] to [hi]
// (d3's tickStep).
double _tickStep(double lo, double hi, int count) {
  final raw = (hi - lo) / math.max(1, count);
  final power = (math.log(raw) / math.ln10).floor();
  final unit = math.pow(10, power).toDouble();
  final error = raw / unit;
  final factor = error >= 7.071
      ? 10
      : error >= 3.162
      ? 5
      : error >= 1.414
      ? 2
      : 1;
  return decimal.roundTo(factor * unit, math.max(0, -power));
}

/// A calendar step a time scale ticks on.
enum _Unit { second, minute, hour, day, week, month, year }

// The steps a time scale tries, shortest first.
const List<(_Unit, int)> _timeSteps = [
  (_Unit.second, 1),
  (_Unit.second, 5),
  (_Unit.second, 15),
  (_Unit.second, 30),
  (_Unit.minute, 1),
  (_Unit.minute, 5),
  (_Unit.minute, 15),
  (_Unit.minute, 30),
  (_Unit.hour, 1),
  (_Unit.hour, 3),
  (_Unit.hour, 6),
  (_Unit.hour, 12),
  (_Unit.day, 1),
  (_Unit.day, 2),
  (_Unit.week, 1),
  (_Unit.month, 1),
  (_Unit.month, 3),
  (_Unit.month, 6),
  (_Unit.year, 1),
];

int _approxMs(_Unit unit, int n) =>
    n *
    switch (unit) {
      _Unit.second => 1000,
      _Unit.minute => 60000,
      _Unit.hour => 3600000,
      _Unit.day => 86400000,
      _Unit.week => 604800000,
      _Unit.month => 2629746000,
      _Unit.year => 31556952000,
    };

/// Time, in local dates: [min] at [start], [max] at [end]. Its values are
/// milliseconds since the epoch ([DateTime.millisecondsSinceEpoch]); its
/// ticks fall on calendar steps (seconds to years) and read as the
/// reader's times and dates.
///
/// ```dart
/// DesignTimeScale(min: DateTime(2026), max: DateTime(2026, 12), start: 0, end: 300)
/// ```
class DesignTimeScale extends DesignScale {
  /// A scale from [min] to [max] exactly.
  DesignTimeScale({
    required this.min,
    required this.max,
    required super.start,
    required super.end,
  }) : _linear = DesignLinearScale(
         min: min.millisecondsSinceEpoch.toDouble(),
         max: max.millisecondsSinceEpoch.toDouble(),
         start: start,
         end: end,
       );

  /// A scale widened to the calendar steps around [min] and [max] that
  /// give about [tickCount] ticks (a month's first day, a year's).
  factory DesignTimeScale.nice({
    required DateTime min,
    required DateTime max,
    required double start,
    required double end,
    int tickCount = 5,
  }) {
    var lo = min.isAfter(max) ? max : min;
    var hi = min.isAfter(max) ? min : max;
    if (lo == hi) {
      lo = lo.subtract(const Duration(days: 1));
      hi = hi.add(const Duration(days: 1));
    }
    // Until the step holds, as for numbers.
    (_Unit, int)? last;
    for (var i = 0; i < 10; i++) {
      final step = _stepFor(lo, hi, tickCount);
      if (step == last) break;
      final (unit, n) = step;
      final ceil = _floor(hi, unit, n);
      hi = ceil.isBefore(hi) ? _add(ceil, unit, n) : ceil;
      lo = _floor(lo, unit, n);
      last = step;
    }
    return DesignTimeScale(min: lo, max: hi, start: start, end: end);
  }

  /// The earliest time.
  final DateTime min;

  /// The latest time.
  final DateTime max;

  final DesignLinearScale _linear;

  /// The position of [time].
  double mapDate(DateTime time) => map(time.millisecondsSinceEpoch.toDouble());

  @override
  double map(double value) => _linear.map(value);

  @override
  double invert(double position) => _linear.invert(position);

  @override
  List<DesignScaleTick> ticks(
    RawWidgetsLocalizations localizations, {
    int count = 5,
  }) {
    final (unit, n) = _stepFor(min, max, count);
    final ticks = <DesignScaleTick>[];
    var at = _floor(min, unit, n);
    if (at.isBefore(min)) at = _add(at, unit, n);
    while (!at.isAfter(max) && ticks.length < 1000) {
      final value = at.millisecondsSinceEpoch.toDouble();
      ticks.add(
        DesignScaleTick(
          value: value,
          position: map(value),
          label: _label(localizations, at, unit),
        ),
      );
      at = _add(at, unit, n);
    }
    return ticks;
  }

  /// [time] labelled as a tick on a scale this long would be: a time of
  /// day within a day or two, a month and day within months, a month
  /// within years (January as its year), a year beyond.
  String label(RawWidgetsLocalizations localizations, DateTime time) =>
      _label(localizations, time, _stepFor(min, max, 5).$1);

  static String _label(RawWidgetsLocalizations l, DateTime at, _Unit unit) =>
      switch (unit) {
        _Unit.second => l.formatTimeOfDay(
          RawTimeOfDay.fromDateTime(at),
          showSeconds: true,
        ),
        _Unit.minute ||
        _Unit.hour => l.formatTimeOfDay(RawTimeOfDay.fromDateTime(at)),
        _Unit.day || _Unit.week => l.formatShortMonthDay(at),
        _Unit.month =>
          at.month == 1 ? l.formatYear(at) : l.formatShortMonth(at),
        _Unit.year => l.formatYear(at),
      };

  static (_Unit, int) _stepFor(DateTime lo, DateTime hi, int count) {
    final target =
        (hi.millisecondsSinceEpoch - lo.millisecondsSinceEpoch) /
        math.max(1, count);
    for (final (unit, n) in _timeSteps) {
      if (_approxMs(unit, n) >= target) return (unit, n);
    }
    // Years: a 1, 2 or 5 × 10ⁿ count of them.
    final years = _tickStep(0, target / _approxMs(_Unit.year, 1), 1);
    return (_Unit.year, math.max(1, years.round()));
  }

  // The step boundary at or before [time].
  static DateTime _floor(DateTime t, _Unit unit, int n) => switch (unit) {
    _Unit.second => DateTime(
      t.year,
      t.month,
      t.day,
      t.hour,
      t.minute,
      t.second - t.second % n,
    ),
    _Unit.minute => DateTime(
      t.year,
      t.month,
      t.day,
      t.hour,
      t.minute - t.minute % n,
    ),
    _Unit.hour => DateTime(t.year, t.month, t.day, t.hour - t.hour % n),
    _Unit.day => DateTime(t.year, t.month, t.day - (t.day - 1) % n),
    // Weeks from Monday, ISO's.
    _Unit.week => DateTime(t.year, t.month, t.day - (t.weekday - 1)),
    _Unit.month => DateTime(t.year, t.month - (t.month - 1) % n),
    _Unit.year => DateTime(t.year - t.year % n),
  };

  static DateTime _add(DateTime t, _Unit unit, int n) => switch (unit) {
    _Unit.second => DateTime(
      t.year,
      t.month,
      t.day,
      t.hour,
      t.minute,
      t.second + n,
    ),
    _Unit.minute => DateTime(t.year, t.month, t.day, t.hour, t.minute + n),
    _Unit.hour => DateTime(t.year, t.month, t.day, t.hour + n),
    _Unit.day => DateTime(t.year, t.month, t.day + n),
    _Unit.week => DateTime(t.year, t.month, t.day + 7 * n),
    _Unit.month => DateTime(t.year, t.month + n),
    _Unit.year => DateTime(t.year + n),
  };

  @override
  String toString() => 'DesignTimeScale($min–$max → $start–$end)';
}

/// Categories side by side (bars): [count] bands from [start] to [end],
/// [paddingInner] of each step between bands and [paddingOuter] at the
/// ends. A value is a band's index; [map] gives its centre.
///
/// ```dart
/// const DesignBandScale(count: 4, start: 0, end: 400, labels: ['Q1', 'Q2', 'Q3', 'Q4']).map(2)
/// ```
class DesignBandScale extends DesignScale {
  /// A band scale.
  const DesignBandScale({
    required this.count,
    required super.start,
    required super.end,
    this.paddingInner = 0.1,
    this.paddingOuter = 0.05,
    this.labels,
  }) : assert(count >= 0),
       assert(paddingInner >= 0 && paddingInner < 1),
       assert(paddingOuter >= 0);

  /// How many bands.
  final int count;

  /// The share of a step between two bands, 0 to 1.
  final double paddingInner;

  /// The share of a step before the first band and after the last.
  final double paddingOuter;

  /// The bands' names, for their ticks; null: their numbers from 1.
  final List<String>? labels;

  /// The distance from one band's start to the next's, signed as [end] −
  /// [start] is.
  double get step =>
      (end - start) / math.max(1, count - paddingInner + paddingOuter * 2);

  /// A band's width.
  double get bandwidth => (step * (1 - paddingInner)).abs();

  // The first band's start edge.
  double get _first => start + step * paddingOuter;

  @override
  double map(double value) => _first + step * value + step.sign * bandwidth / 2;

  @override
  double invert(double position) {
    if (step == 0) return 0;
    return (position - _first - step.sign * bandwidth / 2) / step;
  }

  /// The band under [position] (its padding between bands shared by its
  /// neighbours); null before the first or after the last.
  int? indexAt(double position) {
    if (count == 0 || step == 0) return null;
    final index = invert(position).round();
    if (index < 0 || index >= count) return null;
    return (map(index.toDouble()) - position).abs() <= step.abs() / 2
        ? index
        : null;
  }

  @override
  List<DesignScaleTick> ticks(
    RawWidgetsLocalizations localizations, {
    int count = 5,
  }) => [
    for (var i = 0; i < this.count; i++)
      DesignScaleTick(
        value: i.toDouble(),
        position: map(i.toDouble()),
        label: labels != null && i < labels!.length
            ? labels![i]
            : localizations.formatDecimal(i + 1),
      ),
  ];

  @override
  String toString() => 'DesignBandScale($count bands, $start–$end)';
}

/// The words for a value of [value] given as [figure]: the value in the
/// reader's digits at the scale's decimals; [localizations] writes others.
typedef DesignChartValueBuilder = String Function(
  double value,
  String figure,
  RawWidgetsLocalizations localizations,
);

/// How a chart writes a value, on its axis, in what a screen reader hears
/// and in its table: in the reader's digits and separators (Arabic-Indic in
/// Arabic), at its scale's decimals (or [fractionDigits]), with a unit
/// ([prefix], [suffix]), or as [DesignChartValueFormat.custom] builds it.
///
/// A look's own painter writes its ticks with [labelTicks] and a value with
/// [format]; [DesignChart.valueFormat] and [DesignPieChart.valueFormat] take
/// one. The unit is the app's words, in the reader's language: a format
/// writes digits for the locale, not units.
///
/// ```dart
/// const DesignChartValueFormat(suffix: ' h').format(4, RawWidgetsLocalizations.of(context))
/// ```
@immutable
class DesignChartValueFormat {
  /// A value with [prefix] before it and [suffix] after (r'$', ' h', '%').
  const DesignChartValueFormat({
    this.prefix = '',
    this.suffix = '',
    this.fractionDigits,
  }) : _builder = null,
       assert(fractionDigits == null || fractionDigits >= 0);

  /// A value as [builder] writes it, from the figure in the reader's digits
  /// (a compact 1.2k past a thousand, say).
  const DesignChartValueFormat.custom(
    DesignChartValueBuilder builder, {
    this.fractionDigits,
  }) : _builder = builder,
       prefix = '',
       suffix = '',
       assert(fractionDigits == null || fractionDigits >= 0);

  /// What comes before the figure.
  final String prefix;

  /// What comes after the figure: a unit, with the space the language puts
  /// before it (' h').
  final String suffix;

  /// The decimals of every value; null: a tick's scale's, else as many as
  /// the value has, up to three.
  final int? fractionDigits;

  final DesignChartValueBuilder? _builder;

  /// [value]'s words for [localizations], with [fractionDigits] decimals
  /// when this format sets none (a scale's tick's).
  String format(
    double value,
    RawWidgetsLocalizations localizations, {
    int? fractionDigits,
  }) {
    final figure = localizations.formatDecimal(
      value,
      fractionDigits: this.fractionDigits ?? fractionDigits,
    );
    final builder = _builder;
    if (builder != null) return builder(value, figure, localizations);
    return '$prefix$figure$suffix';
  }

  /// [ticks] labelled by this format, each at its scale's decimals.
  List<DesignScaleTick> labelTicks(
    List<DesignScaleTick> ticks,
    RawWidgetsLocalizations localizations,
  ) => [
    for (final tick in ticks)
      DesignScaleTick(
        value: tick.value,
        position: tick.position,
        label: format(
          tick.value,
          localizations,
          fractionDigits: tick.fractionDigits,
        ),
        fractionDigits: tick.fractionDigits,
      ),
  ];

  @override
  bool operator ==(Object other) =>
      other is DesignChartValueFormat &&
      other.prefix == prefix &&
      other.suffix == suffix &&
      other.fractionDigits == fractionDigits &&
      other._builder == _builder;

  @override
  int get hashCode => Object.hash(prefix, suffix, fractionDigits, _builder);

  @override
  String toString() => _builder != null
      ? 'DesignChartValueFormat.custom()'
      : 'DesignChartValueFormat(${prefix.isEmpty ? '' : 'prefix: "$prefix", '}'
            '${suffix.isEmpty ? '' : 'suffix: "$suffix", '}'
            'fractionDigits: $fractionDigits)';
}
