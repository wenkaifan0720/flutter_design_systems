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
}
