/// A chart's figure in the reader's digits.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// [value] in the reader's digits and decimal mark (Arabic-Indic in Arabic),
/// whole or to one place: the figure a chart writes where the app gives none.
/// Plumbing of the charts.
String fluent2Figure(BuildContext context, double value) {
  final words = RawWidgetsLocalizations.of(context);
  return value == value.roundToDouble()
      ? words.formatDecimal(value.round())
      : words.formatDecimal(value, fractionDigits: 1);
}
