// A date or time picker's title in the app's language: Comic's own words in English ("Choose a date"), and in
// another language ui_core's (RawPickerWords: Material's "Select date" and its translations), as the words ui_core
// shares are; an app's own title still wins.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart' show loadComicFonts;

Future<BuildContext> _open(WidgetTester tester, Locale locale) async {
  late BuildContext page;
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFFFF3E92),
      locale: locale,
      supportedLocales: [locale],
      localizationsDelegates: const [
        DefaultWidgetsLocalizations.delegate,
        RawWidgetsLocalizations.delegate,
      ],
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, animation, secondary) => builder(context),
      ),
      builder: (context, navigator) =>
          ComicTheme(data: ComicThemeData.offset(), child: navigator!),
      home: Builder(
        builder: (context) {
          page = context;
          return const ComicScaffold(body: SizedBox(height: 120));
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return page;
}

void main() {
  setUpAll(loadComicFonts);

  test("in English a picker keeps Comic's own title", () {
    final words = ComicLocalizations.forLocale(const Locale('en'));
    expect(words.chooseDate, 'Choose a date');
    expect(words.chooseTime, 'Choose a time');
  });

  test("in another language a picker's title is ui_core's", () {
    for (final code in ['de', 'fr', 'ja', 'ar']) {
      final locale = Locale(code);
      final words = ComicLocalizations.forLocale(locale);
      final core = RawWidgetsLocalizations.forLocale(locale);
      expect(words.chooseDate, core.datePickerHelpText, reason: code);
      expect(words.chooseTime, core.timePickerDialHelpText, reason: code);
      expect(words.chooseDate, isNot('Choose a date'), reason: code);
    }
  });

  for (final (name, open, word)
      in <
        (
          String,
          void Function(BuildContext),
          String Function(RawWidgetsLocalizations),
        )
      >[
        (
          'date',
          (c) => showComicDatePicker(c, value: DateTime(2026, 11, 6)),
          (w) => w.datePickerHelpText,
        ),
        (
          'time',
          (c) => showComicTimePicker(c, value: const ComicTime(19, 30)),
          (w) => w.timePickerDialHelpText,
        ),
        (
          'date range',
          (c) => showComicDateRangePicker(
            c,
            firstDate: DateTime(2026),
            lastDate: DateTime(2027),
          ),
          (w) => w.datePickerHelpText,
        ),
      ]) {
    testWidgets("the $name picker's dialog says ui_core's title in German", (
      tester,
    ) async {
      final page = await _open(tester, const Locale('de'));
      open(page);
      await tester.pumpAndSettle();
      final title = word(RawWidgetsLocalizations.forLocale(const Locale('de')));
      expect(find.textContaining(title, findRichText: true), findsWidgets);
      expect(find.textContaining('Choose a', findRichText: true), findsNothing);
    });
  }

  testWidgets("an app's own title still wins", (tester) async {
    final page = await _open(tester, const Locale('de'));
    unawaited(
      showComicDatePicker(page, value: DateTime(2026, 11, 6), title: 'Anreise'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Anreise', findRichText: true), findsWidgets);
  });
}
