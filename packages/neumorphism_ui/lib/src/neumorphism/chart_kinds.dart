// The chart rows every look names alike: a line, a bar and an area chart, each NeumorphicChart with its kind fixed, so a
// developer reaches for the class by what it draws.
import 'package:flutter/widgets.dart';

import 'chart.dart';
import 'component_themes.dart';

/// Values over time as one line a series, in the chart's pressed well: round-step gridlines labelled beside the plot, a
/// label under each point, a key, and a raised readout on hover or touch. [loading] shows the well's skeleton; no
/// values show the empty state.
///
/// ```dart
/// NeumorphicLineChart(label: 'Hours slept', series: const [NeumorphicChartSeries('Sleep', [7, 6.5, 8])], labels: const ['Mon', 'Tue', 'Wed'])
/// ```
class NeumorphicLineChart extends StatelessWidget {
  /// Creates a [NeumorphicLineChart].
  const NeumorphicLineChart({
    super.key,
    this.style,
    required this.label,
    required this.series,
    this.labels = const [],
    this.band,
    this.summary,
    this.height = 180,
    this.format,
    this.loading = false,
  }) : assert(height >= 60);

  /// Frame styling before the shared card component theme.
  final NeumorphicStyle? style;

  /// The accessible name of the chart.
  final String label;

  /// The series drawn together on a shared scale.
  final List<NeumorphicChartSeries> series;

  /// Category labels corresponding to sample positions.
  final List<String> labels;

  /// An optional shaded reference interval.
  final NeumorphicChartBand? band;

  /// An optional spoken summary of the chart.
  final String? summary;

  /// Height of the plotted area; labels grow outside it.
  final double height;

  /// Formats numeric values for labels and semantics.
  final String Function(double value)? format;

  /// Whether the series are still on their way: the well holds a skeleton of the plot.
  final bool loading;

  @override
  Widget build(BuildContext context) => NeumorphicChart(
    style: style,
    label: label,
    series: series,
    labels: labels,
    band: band,
    summary: summary,
    height: height,
    format: format,
    loading: loading,
  );
}

/// Values side by side as columns, one ink a series, in the chart's pressed well, with its gridlines, labels, key and
/// readout.
///
/// ```dart
/// NeumorphicBarChart(label: 'Visits', series: const [NeumorphicChartSeries('Visits', [12, 18, 9])], labels: const ['Mon', 'Tue', 'Wed'])
/// ```
class NeumorphicBarChart extends StatelessWidget {
  /// Creates a [NeumorphicBarChart].
  const NeumorphicBarChart({
    super.key,
    this.style,
    required this.label,
    required this.series,
    this.labels = const [],
    this.band,
    this.summary,
    this.height = 180,
    this.format,
    this.loading = false,
  }) : assert(height >= 60);

  /// Frame styling before the shared card component theme.
  final NeumorphicStyle? style;

  /// The accessible name of the chart.
  final String label;

  /// The series drawn together on a shared scale.
  final List<NeumorphicChartSeries> series;

  /// Category labels corresponding to sample positions.
  final List<String> labels;

  /// An optional shaded reference interval.
  final NeumorphicChartBand? band;

  /// An optional spoken summary of the chart.
  final String? summary;

  /// Height of the plotted area; labels grow outside it.
  final double height;

  /// Formats numeric values for labels and semantics.
  final String Function(double value)? format;

  /// Whether the series are still on their way: the well holds a skeleton of the plot.
  final bool loading;

  @override
  Widget build(BuildContext context) => NeumorphicChart(
    style: style,
    label: label,
    series: series,
    kind: NeumorphicChartKind.bar,
    labels: labels,
    band: band,
    summary: summary,
    height: height,
    format: format,
    loading: loading,
  );
}

/// A line over a faint fill down to zero, for an amount whose size matters more than its turns, in the chart's pressed
/// well with its gridlines, labels, key and readout.
///
/// ```dart
/// NeumorphicAreaChart(label: 'Energy used', series: const [NeumorphicChartSeries('kWh', [3.2, 4.1, 2.8])], labels: const ['Mon', 'Tue', 'Wed'])
/// ```
class NeumorphicAreaChart extends StatelessWidget {
  /// Creates a [NeumorphicAreaChart].
  const NeumorphicAreaChart({
    super.key,
    this.style,
    required this.label,
    required this.series,
    this.labels = const [],
    this.band,
    this.summary,
    this.height = 180,
    this.format,
    this.loading = false,
  }) : assert(height >= 60);

  /// Frame styling before the shared card component theme.
  final NeumorphicStyle? style;

  /// The accessible name of the chart.
  final String label;

  /// The series drawn together on a shared scale.
  final List<NeumorphicChartSeries> series;

  /// Category labels corresponding to sample positions.
  final List<String> labels;

  /// An optional shaded reference interval.
  final NeumorphicChartBand? band;

  /// An optional spoken summary of the chart.
  final String? summary;

  /// Height of the plotted area; labels grow outside it.
  final double height;

  /// Formats numeric values for labels and semantics.
  final String Function(double value)? format;

  /// Whether the series are still on their way: the well holds a skeleton of the plot.
  final bool loading;

  @override
  Widget build(BuildContext context) => NeumorphicChart(
    style: style,
    label: label,
    series: series,
    kind: NeumorphicChartKind.area,
    labels: labels,
    band: band,
    summary: summary,
    height: height,
    format: format,
    loading: loading,
  );
}
