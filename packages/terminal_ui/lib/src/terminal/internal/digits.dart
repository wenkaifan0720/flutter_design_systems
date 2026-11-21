/// Figures in the reader's digits: what Terminal's dates, times and
/// counters write, in the same script as the words around them.
library;

import 'package:ui_core/ui_core.dart';

/// [value] in [l]'s digits, ungrouped and padded with zeros to [width]
/// ("2026", "07"; Arabic's "٢٠٢٦", "٠٧").
String termDigits(RawWidgetsLocalizations l, int value, {int width = 1}) {
  final zero = l.formatDecimal(0).runes.first;
  final ascii = value.abs().toString().padLeft(width, '0');
  final digits = zero == 0x30
      ? ascii
      : String.fromCharCodes(ascii.codeUnits.map((c) => c - 0x30 + zero));
  return value < 0 ? '-$digits' : digits;
}

/// [text] with [l]'s digits written as ASCII ones, so a figure typed in
/// either reads the same.
String termAsciiDigits(RawWidgetsLocalizations l, String text) {
  final zero = l.formatDecimal(0).runes.first;
  if (zero == 0x30) return text;
  return String.fromCharCodes(
    text.runes.map((r) => r >= zero && r <= zero + 9 ? r - zero + 0x30 : r),
  );
}

/// The characters a figure in [l] is typed with: ASCII digits and the
/// reader's, for an input's filter.
String termDigitClass(RawWidgetsLocalizations l) {
  final zero = l.formatDecimal(0).runes.first;
  return zero == 0x30
      ? '0-9'
      : '0-9${String.fromCharCode(zero)}-${String.fromCharCode(zero + 9)}';
}
