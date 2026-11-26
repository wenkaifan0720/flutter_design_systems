// The shipped words in another language: a picker's titles are ui_core's (RawPickerWords) and numbers are written in
// the reader's digits and separators through ui_core's formatDecimal and formatPercent, Arabic's in Arabic-Indic
// digits. English reads as it did.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

Future<NeumorphicLocalizations> _words(
  WidgetTester tester,
  Locale locale,
) async {
  late NeumorphicLocalizations words;
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: locale,
      supportedLocales: [locale],
      localizationsDelegates: const [
        NeumorphicLocalizations.delegate,
        RawWidgetsLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      builder: (context, _) => Builder(
        builder: (context) {
          words = NeumorphicLocalizations.of(context);
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return words;
}

void main() {
  for (final lang in const ['ar', 'de', 'ja']) {
    testWidgets("$lang: a picker's titles are ui_core's words", (tester) async {
      final words = await _words(tester, Locale(lang));
      final shared = RawWidgetsLocalizations.forLocale(Locale(lang));
      expect(words.chooseDate, shared.datePickerHelpText);
      expect(words.chooseTime, shared.timePickerDialHelpText);
      expect(words.chooseDate, isNot('Choose a date'));
      expect(words.chooseTime, isNot('Choose a time'));
    });
  }

  testWidgets("ar: numbers are in the reader's digits", (tester) async {
    final words = await _words(tester, const Locale('ar'));
    final shared = RawWidgetsLocalizations.forLocale(const Locale('ar'));
    expect(words.formatNumber(1240.54), shared.formatDecimal(1240.5));
    expect(words.formatNumber(3), shared.formatDecimal(3));
    expect(
      words.formatNumber(2.5, maximumFractionDigits: 0),
      shared.formatDecimal(3, fractionDigits: 0),
    );
    expect(words.formatPercent(.4), shared.formatPercent(.4));
    expect(words.formatNumber(1240.54), isNot(contains(RegExp('[0-9]'))));
    expect(words.pageOf(3, 12), isNot(contains(RegExp('[0-9]'))));
  });

  testWidgets("de: numbers take the reader's separators", (tester) async {
    final words = await _words(tester, const Locale('de'));
    expect(words.formatNumber(1240.54), '1.240,5');
  });

  testWidgets('en: the words and numbers read as they did', (tester) async {
    final words = await _words(tester, const Locale('en'));
    expect(words.chooseDate, 'Choose a date');
    expect(words.chooseTime, 'Choose a time');
    expect(words.formatNumber(1240.54), '1,240.5');
    expect(words.formatNumber(3.0), '3');
    expect(words.formatPercent(.4), '40%');
  });
}
