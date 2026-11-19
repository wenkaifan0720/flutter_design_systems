// A time picker's words in the reader's language: the hour and minute
// columns are named, and a 12-hour clock marks its hours, from ui_core's
// DesignLocalizations, so German hears "Stunde" and Arabic reads "7:30 م",
// where Minimal once said "Hour", "Minute", "AM" and "PM" in English in every
// locale. MinimalLocalizations.delegate gives every locale those shared words
// with Minimal's own in English, as no delegate does.
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

MinimalDatePicker _picker(MinimalDatePickerPresentation presentation) =>
    MinimalDatePicker(
      label: 'Starts',
      value: DateTime(2026, 11, 20, 19, 30),
      mode: MinimalDatePickerMode.time,
      presentation: presentation,
      use24HourFormat: false,
      onChanged: (_) {},
    );

void main() {
  setUpAll(minimalLoadFonts);

  for (final (locale, hour, minute, pm) in const [
    (Locale('en'), 'Hour', 'Minute', 'PM'),
    (Locale('de'), 'Stunde', 'Minute', 'PM'),
    (Locale('ar'), 'ساعة', 'دقيقة', 'م'),
  ]) {
    final at = locale.languageCode;

    testWidgets('$at: the time columns are named $hour and $minute, and '
        'the hours marked $pm', (tester) async {
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
      expect(find.text('7 $pm'), findsOneWidget);
      if (at != 'en') {
        expect(find.bySemanticsLabel(RegExp('^Hour')), findsNothing);
      }
      // German marks its hours AM and PM too; Arabic its own.
      if (pm != 'PM') {
        expect(find.textContaining(RegExp(r'\b(AM|PM)\b')), findsNothing);
      }
      semantics.dispose();
    });

    testWidgets('$at: the compact row prints 7:30 $pm', (tester) async {
      await tester.pumpWidget(
        _app(locale, _picker(MinimalDatePickerPresentation.compact)),
      );
      await tester.pumpAndSettle();
      expect(find.text('7:30 $pm'), findsOneWidget);
    });
  }

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

  test('time12 marks the hours in the words given', () {
    final morning = DateTime(2026, 1, 1, 9, 41);
    final evening = DateTime(2026, 1, 1, 19, 5);
    expect(MinimalFormat.time12(morning), '9:41 AM');
    expect(MinimalFormat.time12(evening), '7:05 PM');
    final arabic = MinimalLocalizationsEn(
      DesignLocalizations.forLocale(const Locale('ar')),
    );
    expect(MinimalFormat.time12(morning, words: arabic), '9:41 ص');
    expect(MinimalFormat.time12(evening, words: arabic), '7:05 م');
    expect(arabic.hour, 'ساعة');
    expect(arabic.minute, 'دقيقة');
  });
}
