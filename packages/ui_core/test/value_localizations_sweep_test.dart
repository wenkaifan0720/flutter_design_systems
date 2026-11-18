// The value behaviours' numbers, dates and times in the reader's symbols,
// digits and patterns (CLDR's), and their counted words in each language's
// plural forms.
@Tags(['sweep'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

void main() {
  test('every locale writes a number and reads it back', () {
    for (final locale in DesignLocalizations.supportedLocales) {
      final l = DesignLocalizations.forLocale(locale);
      for (final v in [0.0, 7.0, -3.25, 1234.5, 1234567.125, -0.5]) {
        for (final digits in [null, 0, 2, 3]) {
          final text = l.formatDecimal(v, fractionDigits: digits);
          final back = l.parseDecimal(text);
          final rounded = digits == null
              ? v
              : (v * _pow(digits)).round() / _pow(digits);
          expect(back, closeTo(rounded, 1e-9), reason: '$locale $v → $text');
        }
      }
    }
  });

  test('every locale formats its date and time patterns, in its digits', () {
    final at = DateTime(2026, 11, 16, 15, 7, 9);
    final time = DesignTimeOfDay.fromDateTime(at);
    for (final locale in DesignLocalizations.supportedLocales) {
      final l = DesignLocalizations.forLocale(locale);
      // The locale's digits for 2026, 07, 09: its own zero on.
      final zero = l.formatDecimal(0).runes.single;
      String digits(String ascii) =>
          String.fromCharCodes(ascii.runes.map((r) => zero + r - 0x30));
      expect(l.formatYear(at), contains(digits('2026')), reason: '$locale');
      expect(l.formatShortMonth(at), isNotEmpty, reason: '$locale');
      expect(l.formatShortMonthDay(at), contains(digits('16')));
      expect(l.formatTimeOfDay(time), contains(digits('07')));
      final full = l.formatTimeOfDay(
        time,
        alwaysUse24HourFormat: true,
        showSeconds: true,
      );
      expect(full, contains(digits('15')), reason: '$locale $full');
      expect(full, contains(digits('9')), reason: '$locale $full');
      for (final pattern in [
        l.dateFieldPattern,
        l.timeFieldPattern(),
        l.timeFieldPattern(alwaysUse24HourFormat: true, showSeconds: true),
      ]) {
        // Only the letters a field types: no weekday, era or zone.
        final letters = pattern.replaceAll(RegExp("'[^']*'"), '');
        expect(
          RegExp('[A-Za-z]').allMatches(letters).map((m) => m[0]).toSet(),
          everyElement(
            isIn(['y', 'M', 'd', 'h', 'H', 'K', 'k', 'm', 's', 'a']),
          ),
          reason: '$locale $pattern',
        );
      }
    }
  });
}

double _pow(int n) {
  var p = 1.0;
  for (var i = 0; i < n; i++) {
    p *= 10;
  }
  return p;
}
