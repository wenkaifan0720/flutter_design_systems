// English dates follow the app's region, as Material's localizations do:
// plain English (and no delegate at all) writes month first, as its
// date field's M/d/y does; British, Australian, Irish, Indian, New
// Zealand, Singapore and South African English write the day first;
// Canadian writes y-MM-dd in a field. An app that wants one format of its
// own extends DefaultRawWidgetsLocalizations and lists its delegate first.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

final DateTime _monday = DateTime(2026, 11, 9);

RawWidgetsLocalizations _l(String language, [String? country]) =>
    RawWidgetsLocalizations.forLocale(Locale(language, country));

// An app's own date format: day first, whatever the region.
class _AppWords extends DefaultRawWidgetsLocalizations {
  const _AppWords();

  @override
  String formatMediumDate(DateTime date) =>
      '${date.day} ${formatShortMonth(date)} ${date.year}';

  @override
  String get dateFieldPattern => 'dd/MM/y';
}

class _AppWordsDelegate extends LocalizationsDelegate<RawWidgetsLocalizations> {
  const _AppWordsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<RawWidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture<RawWidgetsLocalizations>(const _AppWords());

  @override
  bool shouldReload(_AppWordsDelegate old) => false;
}

Future<RawWidgetsLocalizations> _loaded(
  WidgetTester tester,
  Locale locale,
  List<LocalizationsDelegate<dynamic>> delegates,
) async {
  late RawWidgetsLocalizations words;
  await tester.pumpWidget(
    Localizations(
      locale: locale,
      delegates: [...delegates, DefaultWidgetsLocalizations.delegate],
      child: Builder(
        builder: (context) {
          words = RawWidgetsLocalizations.of(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return words;
}

void main() {
  test('English writes the month first, as its date field does', () {
    for (final en in [
      const DefaultRawWidgetsLocalizations(),
      _l('en'),
      _l('en', 'US'),
      _l('en', 'JM'),
    ]) {
      expect(en.formatMediumDate(_monday), 'Nov 9, 2026');
      expect(en.formatFullDate(_monday), 'Monday, November 9, 2026');
      expect(en.formatMonthYear(_monday), 'November 2026');
      expect(en.formatShortMonthDay(_monday), 'Nov 9');
      expect(en.dateFieldPattern, 'M/d/y');
      expect(en.firstDayOfWeek, DateTime.sunday);
    }
  });

  test("a region's English writes its own order, week and clock", () {
    final gb = _l('en', 'GB');
    expect(gb.formatMediumDate(_monday), '9 Nov 2026');
    expect(gb.formatFullDate(_monday), 'Monday, 9 November 2026');
    expect(gb.formatShortMonthDay(_monday), '9 Nov');
    expect(gb.formatMediumDate(DateTime(2026, 9, 3)), '3 Sept 2026');
    expect(gb.dateFieldPattern, 'dd/MM/y');
    expect(gb.firstDayOfWeek, DateTime.monday);
    expect(gb.timeFieldPattern(), 'HH:mm');
    expect(gb.cancelButtonLabel, 'Cancel');
    expect(gb.selectedRowCountTitle(2), '2 items selected');

    expect(_l('en', 'AU').formatMediumDate(_monday), '9 Nov 2026');
    expect(_l('en', 'AU').formatFullDate(_monday), 'Monday 9 November 2026');
    expect(_l('en', 'IE').dateFieldPattern, 'd/M/y');
    expect(_l('en', 'IN').dateFieldPattern, 'd/M/y');
    expect(_l('en', 'NZ').dateFieldPattern, 'd/MM/y');
    expect(_l('en', 'SG').dateFieldPattern, 'dd/MM/y');
    expect(_l('en', 'ZA').dateFieldPattern, 'y/MM/dd');
    expect(_l('en', 'CA').dateFieldPattern, 'y-MM-dd');
    expect(_l('en', 'CA').formatMediumDate(_monday), 'Nov 9, 2026');
  });

  testWidgets("the delegate loads the app's region", (tester) async {
    final gb = await _loaded(tester, const Locale('en', 'GB'), const [
      RawWidgetsLocalizations.delegate,
    ]);
    expect(gb.formatMediumDate(_monday), '9 Nov 2026');
    expect(gb.dateFieldPattern, 'dd/MM/y');
    final us = await _loaded(tester, const Locale('en', 'US'), const [
      RawWidgetsLocalizations.delegate,
    ]);
    expect(us.formatMediumDate(_monday), 'Nov 9, 2026');
    expect(us.dateFieldPattern, 'M/d/y');
  });

  testWidgets("an app's own format wins when its delegate comes first", (
    tester,
  ) async {
    final words = await _loaded(tester, const Locale('en', 'US'), const [
      _AppWordsDelegate(),
      RawWidgetsLocalizations.delegate,
    ]);
    expect(words.formatMediumDate(_monday), '9 Nov 2026');
    expect(words.dateFieldPattern, 'dd/MM/y');
    expect(words.formatFullDate(_monday), 'Monday, November 9, 2026');
  });
}
