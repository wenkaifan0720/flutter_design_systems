/// A time picker's words (its hour and minute fields, its AM/PM pair and
/// their names) in the app's language, and a delegate that takes every
/// locale. The picker said "Hour", "Minute", "AM" and "PM" in every
/// language, though ui_core's DesignLocalizations has them in 30, and
/// [ExpressiveLocalizations.delegate] said English only, so a German app
/// that installed it had Flutter's warning that no delegate supports its
/// locale, and the delegate was skipped.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

class _Own extends ExpressiveLocalizations {
  const _Own() : super(hour: 'Std.', am: 'vorm.');
}

class _OwnDelegate extends LocalizationsDelegate<ExpressiveLocalizations> {
  const _OwnDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<ExpressiveLocalizations> load(Locale locale) =>
      SynchronousFuture(const _Own());

  @override
  bool shouldReload(_OwnDelegate old) => false;
}

/// The words a time picker reads in a [locale] app with [delegates].
Future<ExpressiveLocalizations> _words(
  WidgetTester tester,
  Locale locale,
  List<LocalizationsDelegate<Object?>> delegates, {
  Widget Function(BuildContext context)? body,
}) async {
  late ExpressiveLocalizations words;
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xff000000),
      locale: locale,
      supportedLocales: [locale],
      localizationsDelegates: delegates,
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      builder: (context, child) => ExpressiveHost(
        light: _theme,
        brightness: Brightness.light,
        child: child!,
      ),
      home: Builder(
        builder: (context) {
          words = ExpressiveLocalizations.of(context);
          return body?.call(context) ?? const SizedBox();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Flutter reports a locale no delegate of a type supports as an error.
  expect(tester.takeException(), isNull);
  return words;
}

void _says(ExpressiveLocalizations words, DesignLocalizations shared) {
  expect(words.hour, shared.timePickerHourLabel);
  expect(words.minute, shared.timePickerMinuteLabel);
  expect(words.period, shared.timeFieldDayPeriodLabel);
  expect(words.am, shared.anteMeridiemAbbreviation);
  expect(words.pm, shared.postMeridiemAbbreviation);
}

void main() {
  setUpAll(expressiveLoadFonts);

  test('the delegate takes every locale', () {
    for (final code in ['en', 'de', 'ar', 'ja', 'xx']) {
      expect(ExpressiveLocalizations.delegate.isSupported(Locale(code)), true);
    }
  });

  testWidgets('a German app with the delegate has no warning and its time '
      'picker says ui_core\'s German words', (tester) async {
    final german = DesignLocalizations.forLocale(const Locale('de'));
    expect(german.timePickerHourLabel, isNot('Hour'));
    final time = ExpressiveTimePickerController(hour: 9, minute: 30);
    addTearDown(time.dispose);
    final words = await _words(tester, const Locale('de'), const [
      ExpressiveLocalizations.delegate,
    ], body: (_) => Center(child: ExpressiveTimePicker(controller: time)));
    _says(words, german);
    expect(find.text(german.anteMeridiemAbbreviation), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(german.timeFieldDayPeriodLabel)),
      findsWidgets,
    );
  });

  testWidgets('an Arabic app\'s own DesignLocalizations name the fields', (
    tester,
  ) async {
    _says(
      await _words(tester, const Locale('ar'), const [
        DesignLocalizations.delegate,
      ]),
      DesignLocalizations.forLocale(const Locale('ar')),
    );
  });

  testWidgets('an English app keeps the look\'s English', (tester) async {
    final words = await _words(tester, const Locale('en'), const [
      ExpressiveLocalizations.delegate,
      DesignLocalizations.delegate,
    ]);
    const english = ExpressiveLocalizations.english;
    expect(
      [words.hour, words.minute, words.period, words.am, words.pm],
      [english.hour, english.minute, english.period, english.am, english.pm],
    );
  });

  testWidgets('an app\'s own words win', (tester) async {
    final words = await _words(tester, const Locale('de'), const [
      _OwnDelegate(),
      DesignLocalizations.delegate,
    ]);
    expect((words.hour, words.am, words.minute), ('Std.', 'vorm.', 'Minute'));
  });
}
