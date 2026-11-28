import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

void _noop() {}

class _WidgetWords extends DefaultWidgetsLocalizations {
  const _WidgetWords();
  @override
  String get copyButtonLabel => 'Framework copy';
}

class _WidgetDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const _WidgetDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture(const _WidgetWords());
  @override
  bool shouldReload(_WidgetDelegate old) => false;
}

class _Words extends RetroDesktopLocalizationsEn {
  const _Words() : super(localeName: 'de');
  @override
  String get copy => 'Look copy';
}

// The words every look shares are ui_core's: an app translates them by extending DefaultRawWidgetsLocalizations.
class _Shared extends DefaultRawWidgetsLocalizations {
  const _Shared();
  @override
  String get closeButtonLabel => 'Schließen';
}

class _SharedDelegate extends LocalizationsDelegate<RawWidgetsLocalizations> {
  const _SharedDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<RawWidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture(const _Shared());
  @override
  bool shouldReload(_SharedDelegate old) => false;
}

class _Delegate extends LocalizationsDelegate<RetroDesktopLocalizations> {
  const _Delegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<RetroDesktopLocalizations> load(Locale locale) async {
    await initializeDateFormatting('de');
    return const _Words();
  }

  @override
  bool shouldReload(_Delegate old) => false;
}

void main() {
  testWidgets('a part says the shared words an app translated', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_SharedDelegate()],
        home: RetroDesktopTheme(
          data: RetroDesktopThemeData.preset('classic', Brightness.light),
          child: const Center(
            child: RetroDesktopBackButton(close: true, onPressed: _noop),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Schließen'), findsOneWidget);
  });

  test('English fallback formats dates before any delegate loads', () {
    const words = RetroDesktopLocalizationsEn();
    expect(words.formatDate(DateTime(2026, 11, 6)), 'November 6, 2026');
    expect(words.formatMonthYear(DateTime(2026, 11)), 'November 2026');
    expect(words.months.first, 'January');
    expect(words.weekdays.first, 'Mon');
    expect(words.formatNumber(1234.5), '1,234.5');
  });

  test(
    'English delegate preserves region and locale-specific date order',
    () async {
      final words = await RetroDesktopLocalizations.delegate.load(
        const Locale('en', 'GB'),
      );
      expect(words.localeName, 'en_GB');
      expect(words.formatDate(DateTime(2026, 11, 6)), '6 November 2026');
      expect(words.weekdays.first, 'Mon');
      expect(words.weekdaysShort.first, 'Mo');
      expect(() => words.months.add('extra'), throwsUnsupportedError);
    },
  );

  test(
    'custom words share locale-aware number, percent and date formatting',
    () async {
      await initializeDateFormatting('de');
      const words = _Words();
      expect(words.formatNumber(1234.5), '1.234,5');
      expect(words.formatPercent(.25), '25\u00a0%');
      expect(words.formatInteger(6, digits: 2), '06');
      expect(words.formatDate(DateTime(2026, 11, 6)), '6. November 2026');
      expect(words.months[2], 'März');
    },
  );

  for (final explicit in [false, true]) {
    testWidgets(
      'editing words prefer ${explicit ? "look" : "framework"} delegate',
      (tester) async {
        await tester.pumpWidget(
          Localizations(
            locale: const Locale('de'),
            delegates: [
              const _WidgetDelegate(),
              if (explicit) const _Delegate(),
            ],
            child: Builder(
              builder: (context) =>
                  Text(RetroDesktopLocalizations.of(context).copy),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(explicit ? 'Look copy' : 'Framework copy'),
          findsOneWidget,
        );
      },
    );
  }

  // The Material and Cupertino under a field (its editable, its selection handles and menu) need words of their own;
  // their English delegates load in English alone, so under an app in another language that gives none, a field threw
  // "No MaterialLocalizations found". The theme now gives them (English here; the published package's own
  // translations), in any locale, Android and iOS.
  for (final (locale, direction) in const [
    (Locale('ar'), TextDirection.rtl),
    (Locale('de'), TextDirection.ltr),
  ]) {
    testWidgets(
      'fields and pickers build, edit and open their menu under an app in '
      '${locale.languageCode} that gives no Material words',
      variant: const TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.iOS,
      }),
      (tester) async {
        late RawWidgetsLocalizations shared;
        late BuildContext inside;
        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFF000000),
            locale: locale,
            supportedLocales: RawWidgetsLocalizations.supportedLocales,
            localizationsDelegates: const [RawWidgetsLocalizations.delegate],
            builder: (context, _) => Directionality(
              textDirection: direction,
              child: Overlay(
                initialEntries: [
                  _ownedEntry(
                    builder: (context) => RetroDesktopTheme(
                      data: RetroDesktopThemeData.classic(),
                      child: Builder(
                        builder: (context) {
                          shared = RawWidgetsLocalizations.of(context);
                          inside = context;
                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                const RetroDesktopTextField(
                                  labelText: 'Name',
                                  initialValue: 'Ada Lovelace',
                                ),
                                const RetroDesktopSearchField(
                                  hintText: 'Search',
                                ),
                                RetroDesktopDatePicker(
                                  value: DateTime(2026, 6, 2),
                                  onChanged: (_) {},
                                ),
                                RetroDesktopTimePicker(onChanged: (_) {}),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final field = find.byType(EditableText).first;
        await tester.tap(field);
        await tester.pumpAndSettle();
        // A double tap selects a word: the handles and the menu show.
        await tester.tap(field);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(field);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(RetroDesktopTextContextMenu), findsOneWidget);
        await tester.longPress(field);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // The Material words the look loads: English in the catalog's app, the app's language in the package (which
        // loads material_ui's own translations).
        expect(
          MaterialLocalizations.of(inside).copyButtonLabel,
          anyOf(
            'Copy',
            const {'de': 'Kopieren', 'ar': 'نسخ'}[locale.languageCode],
          ),
        );
        // The parts' own words are the app's language.
        expect(
          shared.closeButtonLabel,
          RawWidgetsLocalizations.forLocale(locale).closeButtonLabel,
        );
        expect(shared.closeButtonLabel, isNot('Close'));
      },
    );
  }

  // A time picker's wheels are named in the app's language, by its RawWidgetsLocalizations, with no Retro Desktop words
  // for it: they said "Hour", "Minute" and "AM or PM" in every language.
  for (final (locale, direction) in const [
    (Locale('ar'), TextDirection.rtl),
    (Locale('de'), TextDirection.ltr),
  ]) {
    testWidgets('a time picker names its wheels in '
        '${locale.languageCode}', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          locale: locale,
          supportedLocales: RawWidgetsLocalizations.supportedLocales,
          localizationsDelegates: const [RawWidgetsLocalizations.delegate],
          builder: (context, _) => Directionality(
            textDirection: direction,
            child: RetroDesktopTheme(
              data: RetroDesktopThemeData.classic(),
              child: Center(
                child: RetroDesktopTimePicker(
                  value: const RetroDesktopTime(9, 30),
                  use24Hour: false,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // What a screen reader says at each node: its name and its value.
      final said = <String>[];
      void visit(SemanticsNode n) {
        final data = n.getSemanticsData();
        said.add('${data.label} ${data.value}'.trim());
        n.visitChildren((c) {
          visit(c);
          return true;
        });
      }

      visit(
        tester
            .binding
            .renderViews
            .first
            .owner!
            .semanticsOwner!
            .rootSemanticsNode!,
      );
      final words = RawWidgetsLocalizations.forLocale(locale);
      for (final word in [
        words.timePickerHourLabel,
        words.timePickerMinuteLabel,
        words.timeFieldDayPeriodLabel,
        words.anteMeridiemAbbreviation,
      ]) {
        expect(
          said.where((s) => s.contains(word)),
          isNotEmpty,
          reason: '"$word" is said ($said)',
        );
      }
      for (final english in ['Hour', 'AM or PM']) {
        expect(
          said.where((s) => s.contains(english)),
          isEmpty,
          reason: '"$english" is not said ($said)',
        );
      }
      semantics.dispose();
    });
  }

  // The look's delegate takes every locale: it said English only, so a German app that installed it, as the README
  // shows, had Flutter's warning that no delegate supports de, and the delegate was skipped.
  testWidgets('a German app with the look\'s delegate has no warning and '
      'hears Stunde', (tester) async {
    final semantics = tester.ensureSemantics();
    late BuildContext inside;
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        locale: const Locale('de'),
        supportedLocales: const [Locale('de')],
        localizationsDelegates: const [RetroDesktopLocalizations.delegate],
        builder: (context, _) => Directionality(
          textDirection: TextDirection.ltr,
          child: RetroDesktopTheme(
            data: RetroDesktopThemeData.classic(),
            child: Builder(
              builder: (context) {
                inside = context;
                return Center(
                  child: RetroDesktopTimePicker(
                    value: const RetroDesktopTime(9, 30),
                    use24Hour: true,
                    onChanged: (_) {},
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.takeException(),
      isNull,
      reason: 'no unsupported-locale warning',
    );
    final words = RetroDesktopLocalizations.of(inside);
    expect(words.hour, 'Stunde');
    expect(words.localeName, 'de', reason: 'its dates and numbers are German');
    expect(find.bySemanticsLabel(RegExp('^Stunde')), findsWidgets);
    semantics.dispose();
  });

  // A picker's title in the app's language: ui_core's picker words (RawPickerWords) where the app speaks another, the
  // look's own English where it speaks English. They stayed "Choose a date" in a German app.
  for (final (locale, date, time) in [
    (
      const Locale('de'),
      RawWidgetsLocalizations.forLocale(const Locale('de')).datePickerHelpText,
      RawWidgetsLocalizations.forLocale(const Locale('de'))
          .timePickerDialHelpText,
    ),
    (const Locale('en'), 'Choose a date', 'Choose a time'),
  ]) {
    testWidgets('pickers are titled in ${locale.languageCode}', (tester) async {
      late BuildContext inside;
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          locale: locale,
          supportedLocales: [locale],
          localizationsDelegates: const [RetroDesktopLocalizations.delegate],
          builder: (context, _) => Builder(
            builder: (context) {
              inside = context;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final words = RetroDesktopLocalizations.of(inside);
      expect(words.chooseDate, date);
      expect(words.chooseTime, time);
      if (locale.languageCode != 'en') {
        expect(date, isNot(contains('date')));
      }
    });
  }

  // A text field's selection handles and menu build in the app's root overlay, above a theme that sits under the
  // app's home rather than in its builder: there the theme's `of` gives the look's default rather than throwing.
  testWidgets(
    'a field selects text with the theme under the app\'s home',
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RetroDesktopTheme(
            data: RetroDesktopThemeData.classic(),
            child: const Center(
              child: SizedBox(
                width: 320,
                child: RetroDesktopTextField(
                  labelText: 'Name',
                  initialValue: 'Ada Lovelace',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final field = find.byType(EditableText);
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.tap(field);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(field);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(RetroDesktopTextContextMenu), findsOneWidget);
      final controller = tester.widget<EditableText>(field).controller;
      expect(controller.selection.isCollapsed, isFalse);
      await tester.longPress(field);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}

/// The overlay entries a test's app built: the first is the one its Overlay took (initialEntries are read once).
final _entries = <OverlayEntry>[];

/// An overlay entry the test owns: when the test ends the one its Overlay took is removed, and every one built is
/// disposed, so the leak tracker finds none left.
OverlayEntry _ownedEntry({required WidgetBuilder builder}) {
  final entry = OverlayEntry(builder: builder);
  if (_entries.isEmpty) {
    addTearDown(() {
      _entries.first.remove();
      for (final built in _entries) {
        built.dispose();
      }
      _entries.clear();
    });
  }
  _entries.add(entry);
  return entry;
}
