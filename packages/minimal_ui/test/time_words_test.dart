// A time picker's words in the reader's language: the hour and minute
// columns are named, and a 12-hour clock marks its hours, from ui_core's
// DesignLocalizations, so German hears "Stunde" and Arabic reads "7:30 م",
// where Minimal once said "Hour", "Minute", "AM" and "PM" in English in every
// locale. MinimalLocalizations.delegate gives every locale those shared words
// with Minimal's own in English, as no delegate does. The figures of a time
// and a calendar's days are the reader's digits too (Arabic's ٧:٣٠ م, where
// Minimal wrote 7:30 م), as Material's time picker sets its hours, and the
// date row's date is in the reader's months and digits (٢٠ نوفمبر ٢٠٢٦, where
// it read 20 Nov 2026 in every language).
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

/// An app's own German, over ui_core's.
class _AppGerman extends DefaultDesignLocalizations {
  const _AppGerman();

  @override
  String get timePickerHourLabel => 'Std.';
}

class _AppGermanDelegate extends LocalizationsDelegate<DesignLocalizations> {
  const _AppGermanDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<DesignLocalizations> load(Locale locale) =>
      SynchronousFuture<DesignLocalizations>(const _AppGerman());

  @override
  bool shouldReload(_AppGermanDelegate old) => false;
}

Widget _app(
  Locale locale,
  Widget child, {
  List<LocalizationsDelegate<Object?>> delegates = const [
    DesignLocalizations.delegate,
  ],
}) => WidgetsApp(
  color: const Color(0xFF000000),
  locale: locale,
  supportedLocales: const [Locale('en'), Locale('de'), Locale('ar')],
  localizationsDelegates: delegates,
  builder: (context, _) => MinimalTheme(
    data: MinimalThemeData.standard(),
    child: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(width: 342, child: child),
    ),
  ),
);

MinimalDatePicker _picker(
  MinimalDatePickerPresentation presentation, {
  MinimalDatePickerMode mode = MinimalDatePickerMode.time,
  bool use24HourFormat = false,
}) => MinimalDatePicker(
  label: 'Starts',
  value: DateTime(2026, 11, 20, 19, 30),
  mode: mode,
  presentation: presentation,
  use24HourFormat: use24HourFormat,
  onChanged: (_) {},
);

void main() {
  setUpAll(minimalLoadFonts);

  for (final (locale, hour, minute, pm, seven, half, twenty) in const [
    (Locale('en'), 'Hour', 'Minute', 'PM', '7', '30', '20'),
    (Locale('de'), 'Stunde', 'Minute', 'PM', '7', '30', '20'),
    (Locale('ar'), 'ساعة', 'دقيقة', 'م', '٧', '٣٠', '٢٠'),
  ]) {
    final at = locale.languageCode;

    testWidgets('$at: the time columns are named $hour and $minute, and '
        'the hours marked $pm, in its digits', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(locale, _picker(MinimalDatePickerPresentation.wheel)),
      );
      await tester.pumpAndSettle();
      for (final name in [hour, minute]) {
        expect(
          find.bySemanticsLabel(RegExp('^${RegExp.escape(name)}')),
          findsWidgets,
          reason: name,
        );
        expect(find.text(name.toUpperCase()), findsOneWidget, reason: name);
      }
      expect(find.text('$seven $pm'), findsOneWidget);
      expect(find.text(half), findsOneWidget, reason: "the minutes' drum");
      expect(
        find.bySemanticsLabel(RegExp('^${RegExp.escape(minute)}')),
        isNot(findsNothing),
      );
      expect(
        tester
            .getSemantics(
              find.bySemanticsLabel(RegExp('^${RegExp.escape(minute)}')).first,
            )
            .value,
        half,
      );
      if (at != 'en') {
        expect(find.bySemanticsLabel(RegExp('^Hour')), findsNothing);
      }
      // German marks its hours AM and PM too; Arabic its own.
      if (pm != 'PM') {
        expect(find.textContaining(RegExp(r'\b(AM|PM)\b')), findsNothing);
      }
      semantics.dispose();
    });

    testWidgets('$at: the compact row prints $seven:$half $pm', (tester) async {
      await tester.pumpWidget(
        _app(locale, _picker(MinimalDatePickerPresentation.compact)),
      );
      await tester.pumpAndSettle();
      expect(find.text('$seven:$half $pm'), findsOneWidget);
    });

    testWidgets("$at: a 24-hour row and a calendar's days in its digits", (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          locale,
          _picker(MinimalDatePickerPresentation.compact, use24HourFormat: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('${seven == '7' ? '19' : '١٩'}:$half'), findsOneWidget);
      await tester.pumpWidget(
        _app(
          locale,
          _picker(
            MinimalDatePickerPresentation.inline,
            mode: MinimalDatePickerMode.date,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(twenty), findsOneWidget, reason: 'the 20th');
      if (twenty != '20') expect(find.text('20'), findsNothing);
    });
  }

  for (final locale in const [Locale('en'), Locale('de'), Locale('ar')]) {
    final at = locale.languageCode;
    final shared = DesignLocalizations.forLocale(locale);
    final month = shared.formatShortMonth(DateTime(2026, 11));
    final date = at == 'ar' ? '٢٠ $month ٢٠٢٦' : '20 $month 2026';
    testWidgets("$at: the compact row's date reads $date", (tester) async {
      await tester.pumpWidget(
        _app(
          locale,
          _picker(
            MinimalDatePickerPresentation.compact,
            mode: MinimalDatePickerMode.date,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(date), findsOneWidget);
      if (at == 'ar') expect(find.textContaining('Nov '), findsNothing);
    });
  }

  test("Minimal's English months are as they were", () {
    const english = MinimalLocalizationsEn();
    expect(english.monthsShort, const [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ]);
    expect(english.months.first, 'January');
    expect(english.months.last, 'December');
    expect(english.months[8], 'September');
    final at = DateTime(2026, 11, 20, 7, 5);
    expect(MinimalFormat.date(at), '20 Nov 2026');
    expect(MinimalFormat.dayMonth(at), '20 Nov');
    expect(MinimalFormat.stamp(at), '20 Nov 07:05');
    final arabic = MinimalLocalizationsEn(
      DesignLocalizations.forLocale(const Locale('ar')),
    );
    expect(MinimalFormat.date(at, words: arabic), '٢٠ نوفمبر ٢٠٢٦');
    expect(MinimalFormat.stamp(at, words: arabic), '٢٠ نوفمبر ٠٧:٠٥');
  });

  testWidgets('MinimalLocalizations.delegate gives every locale the shared '
      'words in force, Minimal\'s own in English', (tester) async {
    late MinimalLocalizations words;
    Widget probe() => Builder(
      builder: (context) {
        words = MinimalLocalizations.of(context);
        return const SizedBox();
      },
    );
    await tester.pumpWidget(
      _app(
        const Locale('de'),
        probe(),
        delegates: const [
          MinimalLocalizations.delegate,
          DesignLocalizations.delegate,
        ],
      ),
    );
    expect(words.hour, 'Stunde');
    expect(words.back, 'Zurück');
    expect(words.tryAgain, isNot('Try again'));
    expect(words.voiceMessage, 'Voice message');
    // An app's own shared words, as with no Minimal delegate.
    await tester.pumpWidget(
      _app(
        const Locale('de'),
        probe(),
        delegates: const [MinimalLocalizations.delegate, _AppGermanDelegate()],
      ),
    );
    expect(words.hour, 'Std.');
    expect(MinimalLocalizations.delegate.isSupported(const Locale('sw')), true);
  });

  test('time12 and clock write the hours in the words and digits given', () {
    final morning = DateTime(2026, 1, 1, 9, 41);
    final evening = DateTime(2026, 1, 1, 19, 5);
    expect(MinimalFormat.time12(morning), '9:41 AM');
    expect(MinimalFormat.time12(evening), '7:05 PM');
    final arabic = MinimalLocalizationsEn(
      DesignLocalizations.forLocale(const Locale('ar')),
    );
    expect(MinimalFormat.time12(morning, words: arabic), '٩:٤١ ص');
    expect(MinimalFormat.time12(evening, words: arabic), '٧:٠٥ م');
    expect(MinimalFormat.clock(evening, words: arabic), '١٩:٠٥');
    expect(MinimalFormat.clock(evening), '19:05');
    // Figure by figure: a year takes no separator.
    expect(arabic.digits(2026), '٢٠٢٦');
    expect(const MinimalLocalizationsEn().digits(2026), '2026');
    expect(arabic.digits(5, width: 2), '٠٥');
    expect(arabic.hour, 'ساعة');
    expect(arabic.minute, 'دقيقة');
  });
}
