import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart' show RawChartValueFormat;
import 'package:ui_core/ui_core.dart' show RawWidgetsLocalizations;

/// How the line, area and pie charts write a value: in the reader's digits
/// and separators, in thousands from a thousand up (1.2k, 12k), else whole
/// or to one decimal.
const RawChartValueFormat minimalChartValues = RawChartValueFormat.custom(
  _figure,
);

String _figure(double value, String figure, RawWidgetsLocalizations words) {
  final size = value.abs();
  if (size >= 10000) {
    return '${words.formatDecimal(value / 1000, fractionDigits: 0)}k';
  }
  if (size >= 1000) {
    return '${words.formatDecimal(value / 1000, fractionDigits: 1)}k';
  }
  return words.formatDecimal(
    value,
    fractionDigits: value == value.roundToDouble() ? 0 : 1,
  );
}

/// [value] as [minimalChartValues] writes it for [context]'s reader.
String minimalChartFigure(BuildContext context, double value) =>
    minimalChartValues.format(value, RawWidgetsLocalizations.of(context));

/// [value] whole or to one decimal, in the reader's digits and separators
/// (a bar chart's figure).
String minimalPlainFigure(BuildContext context, double value) =>
    const RawChartValueFormat().format(
      value,
      RawWidgetsLocalizations.of(context),
      fractionDigits: value == value.roundToDouble() ? 0 : 1,
    );
