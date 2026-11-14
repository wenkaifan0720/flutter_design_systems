// The chart rows' shared stems: a line, a bar, an area and a pie (the donut) chart, each the one plot
// (`RetroDesktopChart`) in its kind, so a developer reaches for the chart by the name every look gives it.
import 'package:flutter/widgets.dart';

import 'chart.dart';
import 'component_themes.dart';

/// Values over a run (days, months) as lines on paper, every gridline named
/// at a round value; a press or the arrows read a point.
///
/// ```dart
/// RetroDesktopLineChart(label: 'Visits', series: [RetroDesktopChartSeries('Visits', [9, 15, 22, 12])], labels: const ['Mon', 'Tue', 'Wed', 'Thu'])
/// ```
class RetroDesktopLineChart extends StatelessWidget {
  /// Creates a [RetroDesktopLineChart].
  const RetroDesktopLineChart({
    super.key,
    required this.label,
    required this.series,
    this.labels = const [],
    this.height = 180,
    this.format,
    this.summary,
    this.loading = false,
    this.style,
  });

  /// The chart's name, for a screen reader and its readout.
  final String label;

  /// The lines, each a key entry.
  final List<RetroDesktopChartSeries> series;

  /// The run's names under the plot.
  final List<String> labels;

  /// The plot's height.
  final double height;

  /// A value's words; null uses the number.
  final String Function(double)? format;

  /// What the chart says, for a screen reader.
  final String? summary;

  /// Whether the values are still coming.
  final bool loading;

  /// Overrides this part's component theme.
  final RetroDesktopStyle? style;

  @override
  Widget build(BuildContext context) => RetroDesktopChart(
    label: label,
    series: series,
    labels: labels,
    kind: RetroDesktopChartType.line,
    height: height,
    format: format,
    summary: summary,
    loading: loading,
    style: style,
  );
}

/// Values side by side as bars, the series hatched apart, every gridline
/// named at a round value.
///
/// ```dart
/// RetroDesktopBarChart(label: 'Files', series: [RetroDesktopChartSeries('Documents', [4, 8, 6, 12])], labels: const ['Mon', 'Tue', 'Wed', 'Thu'])
/// ```
class RetroDesktopBarChart extends StatelessWidget {
  /// Creates a [RetroDesktopBarChart].
  const RetroDesktopBarChart({
    super.key,
    required this.label,
    required this.series,
    this.labels = const [],
    this.height = 180,
    this.format,
    this.summary,
    this.loading = false,
    this.style,
  });

  /// The chart's name, for a screen reader and its readout.
  final String label;

  /// The bars' series, each a key entry.
  final List<RetroDesktopChartSeries> series;

  /// The groups' names under the plot.
  final List<String> labels;

  /// The plot's height.
  final double height;

  /// A value's words; null uses the number.
  final String Function(double)? format;

  /// What the chart says, for a screen reader.
  final String? summary;

  /// Whether the values are still coming.
  final bool loading;

  /// Overrides this part's component theme.
  final RetroDesktopStyle? style;

  @override
  Widget build(BuildContext context) => RetroDesktopChart(
    label: label,
    series: series,
    labels: labels,
    kind: RetroDesktopChartType.bar,
    height: height,
    format: format,
    summary: summary,
    loading: loading,
    style: style,
  );
}

/// A running amount as a line with the ground under it tinted: storage used,
/// a balance.
///
/// ```dart
/// RetroDesktopAreaChart(label: 'Disk used', series: [RetroDesktopChartSeries('Disk used', [12, 15, 21, 24, 30])], labels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May'])
/// ```
class RetroDesktopAreaChart extends StatelessWidget {
  /// Creates a [RetroDesktopAreaChart].
  const RetroDesktopAreaChart({
    super.key,
    required this.label,
    required this.series,
    this.labels = const [],
    this.height = 180,
    this.format,
    this.summary,
    this.loading = false,
    this.style,
  });

  /// The chart's name, for a screen reader and its readout.
  final String label;

  /// The areas' series, each a key entry.
  final List<RetroDesktopChartSeries> series;

  /// The run's names under the plot.
  final List<String> labels;

  /// The plot's height.
  final double height;

  /// A value's words; null uses the number.
  final String Function(double)? format;

  /// What the chart says, for a screen reader.
  final String? summary;

  /// Whether the values are still coming.
  final bool loading;

  /// Overrides this part's component theme.
  final RetroDesktopStyle? style;

  @override
  Widget build(BuildContext context) => RetroDesktopChart(
    label: label,
    series: series,
    labels: labels,
    kind: RetroDesktopChartType.area,
    height: height,
    format: format,
    summary: summary,
    loading: loading,
    style: style,
  );
}

/// Shares of a whole as a ring, each share hatched apart, the total in its
/// hole.
///
/// ```dart
/// RetroDesktopPieChart(label: 'Storage', series: [RetroDesktopChartSeries('Storage', [52, 28, 20])], labels: const ['Documents', 'Pictures', 'Other'])
/// ```
class RetroDesktopPieChart extends StatelessWidget {
  /// Creates a [RetroDesktopPieChart].
  const RetroDesktopPieChart({
    super.key,
    required this.label,
    required this.series,
    this.labels = const [],
    this.height = 180,
    this.format,
    this.summary,
    this.loading = false,
    this.style,
  });

  /// The chart's name, for a screen reader and its readout.
  final String label;

  /// The shares: one series, a value per share.
  final List<RetroDesktopChartSeries> series;

  /// The shares' names.
  final List<String> labels;

  /// The ring's height.
  final double height;

  /// A value's words; null uses the number.
  final String Function(double)? format;

  /// What the chart says, for a screen reader.
  final String? summary;

  /// Whether the values are still coming.
  final bool loading;

  /// Overrides this part's component theme.
  final RetroDesktopStyle? style;

  @override
  Widget build(BuildContext context) => RetroDesktopChart(
    label: label,
    series: series,
    labels: labels,
    kind: RetroDesktopChartType.donut,
    height: height,
    format: format,
    summary: summary,
    loading: loading,
    style: style,
  );
}
