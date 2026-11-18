// Decimal numbers for the value behaviours: a step in scaled integers (0.1
// on from 0.2 is 0.3, not 0.30000000000000004), and a number written and
// read in a locale's symbols and digits (CLDR's, as DesignLocaleData holds
// them).
import 'package:flutter/foundation.dart';

import 'localizations_data.dart';

/// A locale's number symbols and digits.
@immutable
class DecimalSymbols {
  /// Symbols as given.
  const DecimalSymbols({
    required this.zeroDigit,
    required this.decimalSeparator,
    required this.groupSeparator,
    required this.minusSign,
    required this.percentSign,
    required this.decimalPattern,
    required this.percentPattern,
  });

  /// [data]'s symbols, in its digits.
  DecimalSymbols.of(DesignLocaleData data)
    : this(
        zeroDigit: data.zeroDigit ?? '0',
        decimalSeparator: data.decimalSeparator,
        groupSeparator: data.groupSeparator,
        minusSign: data.minusSign,
        percentSign: data.percentSign,
        decimalPattern: data.decimalPattern,
        percentPattern: data.percentPattern,
      );

  /// The locale's zero; its other nine digits follow it.
  final String zeroDigit;

  /// Between the whole part and the fraction.
  final String decimalSeparator;

  /// Between groups of the whole part's digits.
  final String groupSeparator;

  /// Before a negative number, with any direction mark it carries.
  final String minusSign;

  /// The percent sign.
  final String percentSign;

  /// The decimal pattern, for its grouping.
  final String decimalPattern;

  /// The percent pattern: where the number and the sign go.
  final String percentPattern;

  /// The size of the group nearest the decimal separator (3), from
  /// [pattern]'s whole part.
  static int primaryGroup(String pattern) {
    final whole = pattern.split('.').first.replaceAll(RegExp(r'[^#0,]'), '');
    final at = whole.lastIndexOf(',');
    return at < 0 ? 0 : whole.length - at - 1;
  }

  /// The size of the groups before it: India's 2, else the primary.
  static int secondaryGroup(String pattern) {
    final whole = pattern.split('.').first.replaceAll(RegExp(r'[^#0,]'), '');
    final last = whole.lastIndexOf(',');
    if (last < 0) return 0;
    final before = whole.lastIndexOf(',', last - 1);
    return before < 0 ? primaryGroup(pattern) : last - before - 1;
  }

  /// [ascii]'s digits in the locale's.
  String digits(String ascii) {
    if (zeroDigit == '0') return ascii;
    final base = zeroDigit.codeUnitAt(0);
    return String.fromCharCodes(
      ascii.codeUnits.map((c) => c >= 0x30 && c <= 0x39 ? base + c - 0x30 : c),
    );
  }
}

// Direction marks a CLDR symbol carries: left-to-right, right-to-left and
// the Arabic letter mark.
final RegExp _marks = RegExp('[\u200E\u200F\u061C]');

/// [value] written in [symbols]: grouped as the decimal pattern groups,
/// with [fractionDigits] decimals, or as many as it has up to three (CLDR's
/// `#,##0.###`) when null.
String formatDecimal(
  num value,
  DecimalSymbols symbols, {
  int? fractionDigits,
  String? pattern,
}) {
  if (!value.isFinite) return value.toString();
  final digits = fractionDigits ?? 3;
  var text = roundTo(value.abs().toDouble(), digits).toStringAsFixed(digits);
  if (fractionDigits == null && text.contains('.')) {
    text = text.replaceFirst(RegExp(r'\.?0+$'), '');
  }
  final dot = text.indexOf('.');
  final whole = dot < 0 ? text : text.substring(0, dot);
  final fraction = dot < 0 ? '' : text.substring(dot + 1);
  final groups = pattern ?? symbols.decimalPattern;
  final grouped = _group(
    whole,
    DecimalSymbols.primaryGroup(groups),
    DecimalSymbols.secondaryGroup(groups),
    symbols.groupSeparator,
  );
  final negative = value < 0 && RegExp('[1-9]').hasMatch(text);
  return '${negative ? symbols.minusSign : ''}'
      '${symbols.digits(grouped)}'
      '${fraction.isEmpty ? '' : symbols.decimalSeparator + symbols.digits(fraction)}';
}

String _group(String whole, int primary, int secondary, String separator) {
  if (primary <= 0 || whole.length <= primary) return whole;
  final parts = <String>[whole.substring(whole.length - primary)];
  var end = whole.length - primary;
  while (end > 0) {
    final start = end - secondary < 0 ? 0 : end - secondary;
    parts.insert(0, whole.substring(start, end));
    end = start;
  }
  return parts.join(separator);
}

/// [fraction] (0.4) as a percentage (40%) in [symbols]' percent pattern.
String formatPercent(
  double fraction,
  DecimalSymbols symbols, {
  int fractionDigits = 0,
}) {
  final pattern = symbols.percentPattern;
  final number = formatDecimal(
    (fraction * 100).abs(),
    symbols,
    fractionDigits: fractionDigits,
    pattern: pattern,
  );
  final shown = pattern
      .replaceFirst(RegExp(r'[#0,.]+'), '\u0000')
      .replaceAll('%', symbols.percentSign)
      .replaceFirst('\u0000', number);
  final negative =
      fraction < 0 && number.runes.any((r) => _digitValue(r, symbols) > 0);
  return negative ? '${symbols.minusSign}$shown' : shown;
}

// The value of the digit [rune], in the locale's digits or ASCII; -1 if it
// is not a digit.
int _digitValue(int rune, DecimalSymbols symbols) {
  if (rune >= 0x30 && rune <= 0x39) return rune - 0x30;
  final d = rune - symbols.zeroDigit.codeUnitAt(0);
  return d >= 0 && d <= 9 ? d : -1;
}

// The space-like grouping separators a reader may type for one another.
const String _spaces = '   ';

/// [text] read as a number written in [symbols] (its digits or ASCII's),
/// or null when it does not read: empty, a stray character, a grouping
/// separator out of place (a German "1.5" is not 1.5, nor 15).
double? parseDecimal(String text, DecimalSymbols symbols) {
  var s = text.replaceAll(_marks, '').trim();
  if (s.isEmpty) return null;
  final minus = symbols.minusSign.replaceAll(_marks, '');
  var negative = false;
  for (final sign in {minus, '-', '−'}) {
    if (sign.isNotEmpty && s.startsWith(sign)) {
      negative = true;
      s = s.substring(sign.length).trimLeft();
      break;
    }
  }
  final decimal = symbols.decimalSeparator;
  final group = symbols.groupSeparator;
  // A reader whose separator is Arabic's (U+066B) may type a full stop for
  // it.
  final decimals = {decimal, if (decimal != '.' && group != '.') '.'};
  var at = -1;
  var mark = '';
  for (final d in decimals) {
    final i = s.indexOf(d);
    if (i >= 0 && (at < 0 || i < at)) {
      at = i;
      mark = d;
    }
  }
  final whole = at < 0 ? s : s.substring(0, at);
  final fraction = at < 0 ? '' : s.substring(at + mark.length);
  final isGroup = _spaces.contains(group)
      ? (String c) => _spaces.contains(c)
      : (String c) => c == group;
  // The whole part: digits, in groups the pattern allows when grouped.
  final runs = <String>[''];
  for (final c in whole.split('')) {
    if (isGroup(c)) {
      runs.add('');
      continue;
    }
    final v = _digitValue(c.runes.single, symbols);
    if (v < 0) return null;
    runs[runs.length - 1] += '$v';
  }
  if (runs.length > 1) {
    final primary = DecimalSymbols.primaryGroup(symbols.decimalPattern);
    final secondary = DecimalSymbols.secondaryGroup(symbols.decimalPattern);
    if (primary <= 0 || runs.last.length != primary) return null;
    for (var i = 1; i < runs.length - 1; i++) {
      if (runs[i].length != secondary) return null;
    }
    if (runs.first.isEmpty || runs.first.length > secondary) return null;
  }
  final out = StringBuffer(runs.join());
  if (at >= 0) {
    out.write('.');
    for (final c in fraction.split('')) {
      final v = c.isEmpty ? -1 : _digitValue(c.runes.single, symbols);
      if (v < 0) return null;
      out.write(v);
    }
  }
  final ascii = out.toString();
  if (!RegExp(r'\d').hasMatch(ascii)) return null;
  final value = double.tryParse(ascii.startsWith('.') ? '0$ascii' : ascii);
  if (value == null) return null;
  return negative ? -value : value;
}

/// How many decimals [value] is written with (0.25 has 2), up to 10.
int decimalsOf(double value) {
  if (!value.isFinite) return 0;
  for (var d = 0; d < 10; d++) {
    final scaled = value * _pow10(d);
    // Within a few units in the last place of the scaled double.
    final tolerance = scaled.abs() * 1e-15 > 1e-7 ? scaled.abs() * 1e-15 : 1e-7;
    if ((scaled - scaled.roundToDouble()).abs() < tolerance) return d;
  }
  return 10;
}

double _pow10(int n) {
  var p = 1.0;
  for (var i = 0; i < n; i++) {
    p *= 10;
  }
  return p;
}

/// [value] rounded to [digits] decimals, half away from zero, as it is
/// written (2.345 to 2.35, though its double is a hair under).
double roundTo(double value, int digits) {
  // Past 10¹⁵ a double has no decimals left to round.
  if (!value.isFinite || value.abs() >= 1e15) return value;
  final written = value.abs().toString();
  if (written.contains('e')) {
    final p = _pow10(digits);
    return (value * p).round() / p;
  }
  final dot = written.indexOf('.');
  final whole = dot < 0 ? written : written.substring(0, dot);
  final fraction = dot < 0 ? '' : written.substring(dot + 1);
  if (fraction.length <= digits) return value;
  var scaled = BigInt.parse(whole + fraction.substring(0, digits));
  if (fraction.codeUnitAt(digits) >= 0x35) scaled += BigInt.one;
  final text = scaled.toString().padLeft(digits + 1, '0');
  final cut = text.length - digits;
  final rounded = double.parse(
    digits == 0 ? text : '${text.substring(0, cut)}.${text.substring(cut)}',
  );
  return value < 0 ? -rounded : rounded;
}

/// The value [count] steps of [step] from [value] ([count] negative: back):
/// the next multiple of [step] counted from [min] (or 0) that way, then on,
/// clamped to [min] and [max]. Exact in decimals: it counts in integers
/// scaled by the decimals [value], [step] and [min] have.
double stepDecimal(
  double value, {
  required double step,
  required int count,
  double? min,
  double? max,
}) {
  assert(step > 0);
  final base = min ?? 0;
  final places = [
    decimalsOf(value),
    decimalsOf(step),
    decimalsOf(base),
  ].reduce((a, b) => a > b ? a : b);
  // Fewer decimals where the scaled integers would pass a double's 2⁵³.
  final largest = [
    value.abs(),
    step,
    base.abs(),
  ].reduce((a, b) => a > b ? a : b);
  var digits = places;
  while (digits > 0 && largest * _pow10(digits) > 9e15) {
    digits--;
  }
  final scale = _pow10(digits);
  final v = (value * scale).round();
  final b = (base * scale).round();
  final s = (step * scale).round();
  final offset = v - b;
  // Floor division, for an offset below the base too.
  var q = offset ~/ s;
  if (offset % s != 0 && offset < 0) q -= 1;
  final onStep = offset - q * s == 0;
  final n = count > 0 || onStep ? q + count : q + count + 1;
  var next = (b + n * s) / scale;
  if (min != null && next < min) next = min;
  if (max != null && next > max) next = max;
  return next;
}
