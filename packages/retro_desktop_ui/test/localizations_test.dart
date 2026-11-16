import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
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

// The words every look shares are ui_core's: an app translates them by extending DefaultDesignLocalizations.
class _Shared extends DefaultDesignLocalizations {
  const _Shared();
  @override
  String get closeButtonLabel => 'Schließen';
}

class _SharedDelegate extends LocalizationsDelegate<DesignLocalizations> {
  const _SharedDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<DesignLocalizations> load(Locale locale) =>
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
        late DesignLocalizations shared;
        late BuildContext inside;
        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFF000000),
            locale: locale,
            supportedLocales: DesignLocalizations.supportedLocales,
            localizationsDelegates: const [DesignLocalizations.delegate],
            builder: (context, _) => Directionality(
              textDirection: direction,
              child: Overlay(
                initialEntries: [
                  _ownedEntry(
                    builder: (context) => RetroDesktopTheme(
                      data: RetroDesktopThemeData.classic(),
                      child: Builder(
                        builder: (context) {
                          shared = DesignLocalizations.of(context);
                          inside = context;
                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                const RetroDesktopTextField(
                                  label: 'Name',
                                  initial: 'Ada Lovelace',
                                ),
                                const RetroDesktopSearchField(hint: 'Search'),
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
          DesignLocalizations.forLocale(locale).closeButtonLabel,
        );
        expect(shared.closeButtonLabel, isNot('Close'));
      },
    );
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
                  label: 'Name',
                  initial: 'Ada Lovelace',
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
