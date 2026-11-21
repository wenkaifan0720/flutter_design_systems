// A count the look speaks itself takes its language's plural form: a date range's nights ("1 night", "2 nights"),
// through NeumorphicLocalizations.nights, so a translation gives every form its language has (Polish: one, few, many).
import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:intl/date_symbol_data_local.dart' show initializeDateFormatting;
import 'package:intl/intl.dart' show Intl;

/// An app's Polish, as a translation would write it: only the words this test reads differ from English.
class _Polish extends NeumorphicLocalizationsEn {
  const _Polish() : super(localeName: 'pl');
  @override
  String nights(int count) => Intl.plural(
    count,
    one: '${formatNumber(count)} noc',
    few: '${formatNumber(count)} noce',
    many: '${formatNumber(count)} nocy',
    other: '${formatNumber(count)} nocy',
    locale: localeName,
  );
}

class _PolishDelegate extends LocalizationsDelegate<NeumorphicLocalizations> {
  const _PolishDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<NeumorphicLocalizations> load(Locale locale) =>
      SynchronousFuture(const _Polish());
  @override
  bool shouldReload(_PolishDelegate old) => false;
}

/// The span the range picker writes above its days for a stay of [nights] from 2 March 2026.
Future<String> _span(
  WidgetTester tester,
  int nights, {
  LocalizationsDelegate<NeumorphicLocalizations>? words,
}) async {
  final start = DateTime(2026, 3, 2);
  final stay = RawCalendarController(
    firstDate: DateTime(2026, 3),
    lastDate: DateTime(2026, 4, 30),
    mode: RawCalendarMode.range,
    selectedRange: RawDateRange(start, start.add(Duration(days: nights))),
  );
  addTearDown(stay.dispose);
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      localizationsDelegates: [?words],
      builder: (context, child) =>
          NeumorphicTheme(data: NeumorphicThemeData.porcelain(), child: child!),
      home: SingleChildScrollView(
        child: NeumorphicDateRangePicker(controller: stay),
      ),
    ),
  );
  final span = find.descendant(
    of: find.byType(NeumorphicDateRangePicker),
    matching: find.textContaining(' – '),
  );
  return tester.widget<Text>(span.first).data!;
}

void main() {
  setUpAll(() => initializeDateFormatting('pl'));

  test('English: 1 night, 2 nights', () {
    const en = NeumorphicLocalizationsEn();
    expect(en.nights(1), '1 night');
    expect(en.nights(2), '2 nights');
    expect(en.nights(0), '0 nights');
  });

  test('Polish, through Intl.plural in its locale: one, few, many', () {
    const pl = _Polish();
    expect(pl.nights(1), '1 noc');
    expect(pl.nights(2), '2 noce');
    expect(pl.nights(5), '5 nocy');
    expect(pl.nights(22), '22 noce');
  });

  testWidgets('the range picker speaks its nights through the localizations', (
    tester,
  ) async {
    expect(await _span(tester, 1), endsWith(', 1 night'));
    expect(await _span(tester, 2), endsWith(', 2 nights'));
    expect(
      await _span(tester, 1, words: const _PolishDelegate()),
      endsWith(', 1 noc'),
    );
    expect(
      await _span(tester, 2, words: const _PolishDelegate()),
      endsWith(', 2 noce'),
    );
    expect(
      await _span(tester, 5, words: const _PolishDelegate()),
      endsWith(', 5 nocy'),
    );
  });
}
