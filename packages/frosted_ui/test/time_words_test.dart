// The time wheel names its columns, and says its halves of the day, in the reader's language: ui_core's shared words
// (RawWidgetsLocalizations, 30 languages) while Frosted's own are left at English, an app's own Frosted words when it
// gives them. It said Hour and Minute in English in every locale. FrostedLocalizations.delegate serves every locale,
// so an app in German installs it and is not warned that its locale lacks a delegate.
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

class _Own extends FrostedLocalizationsEn {
  const _Own();

  @override
  String get hour => 'Heure';

  @override
  String get minute => 'Minuta';
}

// Frosted's delegate as it was: English alone.
class _EnglishOnly extends LocalizationsDelegate<FrostedLocalizations> {
  const _EnglishOnly();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<FrostedLocalizations> load(Locale locale) =>
      SynchronousFuture<FrostedLocalizations>(const FrostedLocalizationsEn());

  @override
  bool shouldReload(_EnglishOnly old) => false;
}

class _OwnDelegate extends LocalizationsDelegate<FrostedLocalizations> {
  const _OwnDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<FrostedLocalizations> load(Locale locale) =>
      SynchronousFuture<FrostedLocalizations>(const _Own());

  @override
  bool shouldReload(_OwnDelegate old) => false;
}

Future<void> _pump(
  WidgetTester tester,
  Locale locale, {
  bool own = false,
  bool englishOnly = false,
}) async {
  tester.view.physicalSize = const Size(390, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: locale,
      supportedLocales: RawWidgetsLocalizations.supportedLocales,
      localizationsDelegates: [
        RawWidgetsLocalizations.delegate,
        if (own)
          const _OwnDelegate()
        else if (englishOnly)
          const _EnglishOnly()
        else
          FrostedLocalizations.delegate,
      ],
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      builder: (context, child) => Directionality(
        textDirection: locale.languageCode == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: FrostedHost(brightness: Brightness.light, child: child!),
      ),
      home: Material(
        type: MaterialType.transparency,
        child: Center(
          child: SizedBox(
            width: 358,
            child: FrostedTimePicker(
              value: const FrostedTime(hour: 9, minute: 5),
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Whether a node in the tree is named [name] (alone or ahead of its value).
bool _named(WidgetTester tester, String name) => find.semantics
    .byPredicate((n) => n.label == name || n.label.startsWith('$name\n'))
    .evaluate()
    .isNotEmpty;

void main() {
  for (final language in ['de', 'ar']) {
    testWidgets('in $language the wheel names its columns and halves in '
        "the reader's words", (tester) async {
      final semantics = tester.ensureSemantics();
      final locale = Locale(language);
      await _pump(tester, locale);
      final words = RawWidgetsLocalizations.forLocale(locale);
      expect(words.timePickerHourLabel, isNot('Hour'));
      for (final name in [
        words.timePickerHourLabel,
        words.timePickerMinuteLabel,
        words.timeFieldDayPeriodLabel,
      ]) {
        expect(_named(tester, name), isTrue, reason: name);
      }
      expect(_named(tester, 'Hour'), isFalse);
      expect(_named(tester, 'AM / PM'), isFalse);
      expect(find.text(words.anteMeridiemAbbreviation), findsWidgets);
      expect(find.text(words.postMeridiemAbbreviation), findsWidgets);
      semantics.dispose();
    });
  }

  testWidgets('a German app with the delegate is not warned and hears '
      'Stunde', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, const Locale('de'));
    expect(tester.takeException(), isNull);
    expect(_named(tester, 'Stunde'), isTrue);
    expect(_named(tester, 'Hour'), isFalse);
    semantics.dispose();
  });

  testWidgets('a delegate for English alone is warned of in a German app', (
    tester,
  ) async {
    await _pump(tester, const Locale('de'), englishOnly: true);
    expect(
      '${tester.takeException()}',
      contains('is not supported by all of its localization delegates'),
    );
  });

  testWidgets("an app's own Frosted words name the columns", (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, const Locale('de'), own: true);
    expect(_named(tester, 'Heure'), isTrue);
    expect(_named(tester, 'Minuta'), isTrue);
    expect(_named(tester, 'Stunde'), isFalse);
    semantics.dispose();
  });

  testWidgets('in English the columns are Hour and Minute', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, const Locale('en'));
    expect(_named(tester, 'Hour'), isTrue);
    expect(_named(tester, 'Minute'), isTrue);
    expect(find.text('AM'), findsWidgets);
    semantics.dispose();
  });
}
