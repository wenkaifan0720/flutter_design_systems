// RawPickerWords: a date or time picker's title, Material's words in the
// app's language, which an app's own words override.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

// An app's own words: Default's English but for the date picker's title.
class _Words extends DefaultRawWidgetsLocalizations {
  const _Words();

  @override
  String get datePickerHelpText => 'Choose a day';
}

// Words that implement RawWidgetsLocalizations without extending the English.
class _Bare implements RawWidgetsLocalizations {
  const _Bare();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('English: Material\'s words', () {
    const RawWidgetsLocalizations en = DefaultRawWidgetsLocalizations();
    expect(en.datePickerHelpText, 'Select date');
    expect(en.timePickerDialHelpText, 'Select time');
  });

  test('each language says Flutter\'s Material translation', () {
    String date(String language, [String? country]) =>
        RawWidgetsLocalizations.forLocale(Locale(language, country))
            .datePickerHelpText;
    String time(String language, [String? country]) =>
        RawWidgetsLocalizations.forLocale(Locale(language, country))
            .timePickerDialHelpText;
    expect(date('de'), 'Datum auswählen');
    expect(time('de'), 'Uhrzeit auswählen');
    expect(date('ar'), 'اختيار التاريخ');
    expect(time('ar'), 'اختيار الوقت');
    expect(date('ja'), '日付の選択');
    expect(time('ja'), '時間の選択');
    expect(date('zh', 'TW'), '選取日期');
    expect(time('zh', 'TW'), '選取時間');
    // None of the other 28 falls back to English.
    for (final locale in RawWidgetsLocalizations.supportedLocales) {
      if (locale.languageCode == 'en') continue;
      final words = RawWidgetsLocalizations.forLocale(locale);
      expect(words.datePickerHelpText, isNot('Select date'), reason: '$locale');
      expect(
        words.timePickerDialHelpText,
        isNot('Select time'),
        reason: '$locale',
      );
    }
  });

  test('an app\'s subclass words a title its own way, read through '
      'RawWidgetsLocalizations; one it leaves stays English', () {
    const RawWidgetsLocalizations words = _Words();
    expect(words.datePickerHelpText, 'Choose a day');
    expect(words.timePickerDialHelpText, 'Select time');
  });

  test('words that do not extend the English say English', () {
    const RawWidgetsLocalizations words = _Bare();
    expect(words.datePickerHelpText, 'Select date');
    expect(words.timePickerDialHelpText, 'Select time');
  });

  testWidgets('under an app in German, the delegate\'s words', (tester) async {
    late RawWidgetsLocalizations words;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('de'),
        delegates: const [
          RawWidgetsLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Builder(
          builder: (context) {
            words = RawWidgetsLocalizations.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(words.datePickerHelpText, 'Datum auswählen');
    expect(words.timePickerDialHelpText, 'Uhrzeit auswählen');
  });
}
