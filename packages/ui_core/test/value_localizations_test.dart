// The value behaviours' numbers, dates and times in the reader's symbols,
// digits and patterns (CLDR's), and their counted words in each language's
// plural forms. Every locale × every value: value_localizations_sweep_test.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

RawWidgetsLocalizations _l(String language, [String? country]) =>
    RawWidgetsLocalizations.forLocale(Locale(language, country));

const _nbsp = ' ';
const _narrow = ' ';

void main() {
  group('numbers', () {
    test('in each locale\'s separators, grouping and digits', () {
      expect(_l('en').formatDecimal(-1234567.5), '-1,234,567.5');
      expect(_l('de').formatDecimal(-1234567.5), '-1.234.567,5');
      expect(
        _l('fr').formatDecimal(1234567.5),
        '1${_narrow}234${_narrow}567,5',
      );
      // India groups by lakh and crore.
      expect(_l('hi').formatDecimal(1234567.5), '12,34,567.5');
      // Arabic: ui_core's Arabic-Indic digits with their own separators.
      expect(_l('ar').formatDecimal(1234567.5), '١٬٢٣٤٬٥٦٧٫٥');
      expect(_l('fa').formatDecimal(1234.5), '۱٬۲۳۴٫۵');
      expect(_l('bn').formatDecimal(1234567), '১২,৩৪,৫৬৭');
      expect(_l('sv').formatDecimal(-3), '−3');
    });

    test('decimals: as many as it has up to three, or as asked', () {
      final en = _l('en');
      expect(en.formatDecimal(3), '3');
      expect(en.formatDecimal(3.5), '3.5');
      expect(en.formatDecimal(0.1 + 0.2), '0.3');
      expect(en.formatDecimal(2 / 3), '0.667');
      expect(en.formatDecimal(2, fractionDigits: 2), '2.00');
      expect(en.formatDecimal(2.345, fractionDigits: 0), '2');
      expect(en.formatDecimal(-0.0001), '0', reason: 'no minus on a zero');
      expect(en.formatDecimal(double.infinity), 'Infinity');
    });

    test('read back in the reader\'s own symbols, or ASCII digits', () {
      expect(_l('en').parseDecimal('1,234.5'), 1234.5);
      expect(_l('de').parseDecimal('1.234,5'), 1234.5);
      expect(_l('de').parseDecimal('1,5'), 1.5);
      expect(_l('de').parseDecimal(' -2 '), -2);
      expect(_l('ar').parseDecimal('١٢٫٥'), 12.5);
      expect(_l('ar').parseDecimal('12.5'), 12.5, reason: 'a full stop too');
      expect(_l('ar').parseDecimal('؜-٣'), -3);
      expect(_l('fa').parseDecimal('‎−۴'), -4);
      expect(_l('fr').parseDecimal('1 234,5'), 1234.5, reason: 'any space');
      expect(_l('hi').parseDecimal('12,34,567'), 1234567);
      expect(_l('en').parseDecimal('.5'), 0.5);
    });

    test('text that does not read is null', () {
      final en = _l('en');
      for (final text in ['', ' ', '-', 'abc', '1.2.3', '1,23', '12,3456']) {
        expect(en.parseDecimal(text), isNull, reason: '"$text"');
      }
      // A German "1.5" is neither 1.5 nor 15: the dot groups thousands.
      expect(_l('de').parseDecimal('1.5'), isNull);
      expect(_l('hi').parseDecimal('1,234,567'), isNull);
    });

    test('percentages where each locale puts the sign', () {
      expect(_l('en').formatPercent(0.4), '40%');
      expect(_l('de').formatPercent(0.4), '40$_nbsp%');
      expect(_l('tr').formatPercent(0.4), '%40');
      expect(_l('tr').formatPercent(-0.125, fractionDigits: 1), '-%12,5');
      expect(_l('ar').formatPercent(0.4), '٤٠٪؜');
      expect(_l('en').formatPercent(-0.001), '0%', reason: 'no minus on 0%');
    });
  });

  group('dates and times', () {
    final at = DateTime(2026, 11, 16, 15, 5, 9);
    const time = RawTimeOfDay(hour: 15, minute: 5, second: 9);

    test('a tick\'s year, month and day', () {
      expect(_l('en').formatYear(at), '2026');
      expect(_l('ja').formatYear(at), '2026年');
      expect(_l('ar').formatYear(at), '٢٠٢٦');
      expect(_l('en').formatShortMonth(at), 'Nov');
      expect(_l('ja').formatShortMonth(at), '11月');
      expect(_l('en').formatShortMonthDay(at), 'Nov 16');
      expect(_l('de').formatShortMonthDay(at), '16. Nov.');
      expect(_l('he').formatShortMonthDay(at), '16 בנוב׳');
    });

    test('a time on the locale\'s clock, or 24 hours, with seconds', () {
      expect(_l('en').formatTimeOfDay(time), '3:05${_narrow}PM');
      expect(_l('de').formatTimeOfDay(time), '15:05');
      expect(_l('ko').formatTimeOfDay(time), '오후 3:05');
      expect(_l('zh', 'TW').formatTimeOfDay(time), '下午3:05');
      expect(_l('ar').formatTimeOfDay(time), '٣:٠٥ م');
      expect(
        _l('en').formatTimeOfDay(time, alwaysUse24HourFormat: true),
        '15:05',
      );
      expect(
        _l('en').formatTimeOfDay(time, showSeconds: true),
        '3:05:09${_narrow}PM',
      );
      expect(
        _l('en').formatTimeOfDay(const RawTimeOfDay(hour: 0, minute: 0)),
        '12:00${_narrow}AM',
      );
    });

    test('a field\'s order: CLDR\'s short date and time', () {
      expect(_l('en').dateFieldPattern, 'M/d/y');
      expect(_l('de').dateFieldPattern, 'd.M.y');
      expect(_l('ja').dateFieldPattern, 'y/M/d');
      expect(_l('ko').dateFieldPattern, 'y. M. d.');
      expect(_l('en').timeFieldPattern(), 'h:mm${_narrow}a');
      expect(_l('ko').timeFieldPattern(), 'a h:mm');
      expect(_l('en').timeFieldPattern(alwaysUse24HourFormat: true), 'HH:mm');
      expect(
        _l('en').timeFieldPattern(showSeconds: true),
        'h:mm:ss${_narrow}a',
      );
      expect(
        _l('de')
            .timeFieldPattern(alwaysUse24HourFormat: true, showSeconds: true),
        'HH:mm:ss',
      );
    });
  });

  group('words', () {
    test('a rating\'s value in the reader\'s numbers', () {
      expect(_l('en').ratingValueLabel(3.5, 5), '3.5 of 5');
      expect(_l('de').ratingValueLabel(3.5, 5), '3,5 von 5');
      expect(_l('ar').ratingValueLabel(3.5, 5), '٣٫٥ من ٥');
      expect(_l('ja').ratingValueLabel(4, 5), '5 点中 4 点');
    });

    test('English counts: one, other, and a count grouped', () {
      final en = _l('en');
      expect(en.chartSeriesCountLabel(1), '1 series');
      expect(en.chartSeriesCountLabel(2), '2 series');
      expect(en.chartPointCountLabel(1), '1 point');
      expect(en.chartPointCountLabel(1240), '1,240 points');
      expect(en.chartSliceCountLabel(4), '4 slices');
    });

    test('Arabic counts: its six forms', () {
      final ar = _l('ar');
      expect([0, 1, 2, 3, 11, 100].map(ar.chartPointCountLabel), [
        '٠ نقطة',
        'نقطة واحدة',
        'نقطتان',
        '٣ نقاط',
        '١١ نقطة',
        '١٠٠ نقطة',
      ]);
      expect(ar.chartSeriesCountLabel(2), 'سلسلتان');
    });

    test('Polish counts: one, few, many', () {
      final pl = _l('pl');
      expect([1, 2, 5, 12, 22, 1240].map(pl.chartPointCountLabel), [
        '1 punkt',
        '2 punkty',
        '5 punktów',
        '12 punktów',
        '22 punkty',
        '1${_nbsp}240 punktów',
      ]);
      expect([1, 3, 5].map(pl.chartSliceCountLabel), [
        '1 wycinek',
        '3 wycinki',
        '5 wycinków',
      ]);
    });

    test('a summary\'s parts, in the language\'s punctuation', () {
      expect(_l('en').chartRangeLabel('Jan', 'Dec'), 'Jan to Dec');
      expect(
        _l('en').chartExtremesLabel('820', '1,640'),
        'lowest 820, highest 1,640',
      );
      expect(
        _l('en').chartPointLabel('Mar 2026', 'Revenue', '1,240'),
        'Mar 2026, Revenue: 1,240',
      );
      expect(
        _l('fr').chartPointLabel('mars', 'Revenu', '1'),
        'mars, Revenu$_nbsp: 1',
      );
      expect(_l('ja').listSeparator, '、');
      expect(_l('ar').listSeparator, '، ');
    });

    test('field names: CLDR\'s, as a label stands alone', () {
      expect(_l('de').dateFieldYearLabel, 'Jahr');
      expect(_l('pl').dateFieldMonthLabel, 'Miesiąc');
      expect(_l('ja').dateFieldDayLabel, '日');
      expect(_l('sv').timeFieldDayPeriodLabel, 'fm/em');
      expect(_l('de').timePickerHourLabel, 'Stunde');
      expect(_l('de').dateFieldDayPlaceholder, 'tt');
      expect(_l('cs').dateFieldMonthPlaceholder, 'mm');
      expect(_l('cs').dateFieldYearPlaceholder, 'rrrr');
    });
  });
}
