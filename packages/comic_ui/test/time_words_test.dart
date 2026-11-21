// A time picker says its hour, minute and half of the day in the app's language: ui_core's words, which it speaks in
// 30 languages. It said "Hour" and "Minute" in English in every one. And Comic's delegate supports every locale, so a
// German app installs it without Flutter's warning; it supported English alone.
import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoLocalizations, DefaultCupertinoLocalizations;
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

void main() {
  for (final (locale, hour, minute, half, am) in const [
    (Locale('de'), 'Stunde', 'Minute', 'Tageshälfte', 'AM'),
    (Locale('ar'), 'ساعة', 'دقيقة', 'ص/م', 'ص'),
    (Locale('en'), 'Hour', 'Minute', 'AM/PM', 'AM'),
  ]) {
    testWidgets('a time picker says its parts in ${locale.languageCode}', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        comicApp(
          direction: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          Builder(
            builder: (context) => Localizations.override(
              context: context,
              locale: locale,
              delegates: const [RawWidgetsLocalizations.delegate],
              child: ComicTimePicker(
                value: const ComicTime(9, 30),
                use24hFormat: false,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final name in [hour, minute, half]) {
        expect(find.text(name), findsOneWidget, reason: '"$name" shown');
        expect(
          find.bySemanticsLabel(RegExp('^${RegExp.escape(name)}')),
          findsOneWidget,
          reason: '"$name" heard',
        );
      }
      // The morning half, chosen, in the language's own abbreviation.
      expect(find.text(am), findsWidgets);
      semantics.dispose();
    });
  }

  testWidgets('a German app installs Comic\'s words without a warning, and '
      'its time picker says Stunde', (tester) async {
    final semantics = tester.ensureSemantics();
    final base = ComicTheme.preset('offset', Brightness.light);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        supportedLocales: const [Locale('de'), Locale('en')],
        localizationsDelegates: const [
          RawWidgetsLocalizations.delegate,
          ComicLocalizations.delegate,
          _AnyLocale<MaterialLocalizations>(DefaultMaterialLocalizations()),
          _AnyLocale<CupertinoLocalizations>(DefaultCupertinoLocalizations()),
          DefaultWidgetsLocalizations.delegate,
        ],
        builder: (context, child) => ComicTheme(
          data: base.atWidth(MediaQuery.sizeOf(context).width),
          child: child!,
        ),
        home: Scaffold(
          body: ComicTimePicker(
            value: const ComicTime(9, 30),
            use24hFormat: true,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Flutter warns when a delegate leaves out the app's locale, and skips it.
    expect(tester.takeException(), isNull);
    expect(
      ComicLocalizations.of(tester.element(find.byType(ComicTimePicker))),
      isNotNull,
    );
    expect(find.bySemanticsLabel(RegExp('^Stunde')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Minute')), findsOneWidget);
    semantics.dispose();
  });

  test('Comic\'s words in another language are English but for the words '
      'ui_core shares', () {
    final german = ComicLocalizations.forLocale(const Locale('de'));
    final shared = RawWidgetsLocalizations.forLocale(const Locale('de'));
    expect(german.tryAgain, shared.retryButtonLabel);
    expect(german.dismiss, shared.modalBarrierDismissLabel);
    expect(german.months.first, shared.formatMonth(DateTime(2000)));
    expect(german.weekdaysShort.first, shared.formatShortWeekday(1));
    // Comic's own words stay in English.
    expect(german.dropFiles, const ComicLocalizationsEn().dropFiles);
    expect(
      ComicLocalizations.forLocale(const Locale('en')),
      isA<ComicLocalizationsEn>(),
    );
  });
}

/// Stands in for flutter_localizations' delegates, which say Flutter's own words in every language.
class _AnyLocale<T> extends LocalizationsDelegate<T> {
  const _AnyLocale(this.words);

  final T words;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<T> load(Locale locale) => SynchronousFuture<T>(words);

  @override
  bool shouldReload(_AnyLocale<T> old) => false;
}
