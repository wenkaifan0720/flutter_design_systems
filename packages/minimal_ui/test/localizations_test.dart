// The words the parts say on their own: the words every look shares come
// from ui_core's DesignLocalizations (English with nothing registered, an
// app's language with a DefaultDesignLocalizations subclass registered),
// and Minimal's own words are English.
import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoLocalizations, DefaultCupertinoLocalizations;
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

class _German extends DefaultDesignLocalizations {
  const _German();

  @override
  String get loadingLabel => 'Lädt';
  @override
  String get searchFieldLabel => 'Suchen';
  @override
  String get currentDateLabel => 'Heute';
  @override
  String get nextMonthTooltip => 'Nächster Monat';
  @override
  String formatMonthYear(DateTime date) =>
      '${const ['Januar', 'Februar', 'März'][date.month - 1]} ${date.year}';
  @override
  int get firstDayOfWeek => DateTime.monday;
}

class _GermanDelegate extends LocalizationsDelegate<DesignLocalizations> {
  const _GermanDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'de';

  @override
  Future<DesignLocalizations> load(Locale locale) =>
      SynchronousFuture<DesignLocalizations>(const _German());

  @override
  bool shouldReload(_GermanDelegate old) => false;
}

/// Flutter's English Material words for any locale, as an app's
/// flutter_localizations would give German: a field's own menu needs them.
class _AnyMaterial extends LocalizationsDelegate<MaterialLocalizations> {
  const _AnyMaterial();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultMaterialLocalizations.load(locale);

  @override
  bool shouldReload(_AnyMaterial old) => false;
}

/// The same for Cupertino's words.
class _AnyCupertino extends LocalizationsDelegate<CupertinoLocalizations> {
  const _AnyCupertino();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      DefaultCupertinoLocalizations.load(locale);

  @override
  bool shouldReload(_AnyCupertino old) => false;
}

final MinimalThemeData _look = MinimalThemeData.preset(
  'standard',
  Brightness.light,
);

Widget _app(Widget child, {bool german = false}) => MaterialApp(
  locale: german ? const Locale('de') : null,
  supportedLocales: const [Locale('en'), Locale('de')],
  localizationsDelegates: [
    if (german)
      const _GermanDelegate()
    else
      DefaultDesignLocalizations.delegate,
    const _AnyMaterial(),
    const _AnyCupertino(),
    DefaultWidgetsLocalizations.delegate,
  ],
  builder: (context, navigator) => MinimalHost(
    light: _look,
    dark: _look,
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('with nothing registered the parts speak English', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, navigator) => MinimalHost(
          light: _look,
          dark: _look,
          brightness: Brightness.light,
          child: navigator!,
        ),
        home: const Scaffold(body: Center(child: MinimalLoadingState())),
      ),
    );
    expect(find.text('Loading'), findsOneWidget);
  });

  testWidgets('the English delegate loads English', (tester) async {
    await tester.pumpWidget(
      _app(const SizedBox(width: 300, child: MinimalSearchField())),
    );
    expect(find.text('Search'), findsOneWidget);
  });

  testWidgets('a registered language reaches every part', (tester) async {
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MinimalLoadingState(),
            const SizedBox(width: 300, child: MinimalSearchField()),
            MinimalCalendar(
              firstDate: DateTime(2026),
              lastDate: DateTime(2027),
              value: DateTime(2026, 3, 9),
              onChanged: (_) {},
            ),
          ],
        ),
        german: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Lädt'), findsOneWidget);
    expect(find.text('Suchen'), findsOneWidget);
    expect(find.text('März 2026'), findsOneWidget);
    expect(find.bySemanticsLabel('Nächster Monat'), findsWidgets);
    expect(find.text('Loading'), findsNothing);
  });

  testWidgets('a caller\'s words win over the localized ones', (tester) async {
    await tester.pumpWidget(
      _app(const MinimalLoadingState(message: 'Loading habits'), german: true),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Loading habits'), findsOneWidget);
  });

  test('the formatters print English unless given words', () {
    final day = DateTime(2026, 3, 28, 7, 12);
    expect(MinimalFormat.date(day), '28 Mar 2026');
    expect(MinimalFormat.dayMonth(day), '28 Mar');
    expect(MinimalFormat.weekday(day), 'Sat');
    expect(MinimalFormat.weekday(day, short: false), 'Saturday');
    expect(MinimalFormat.stamp(day), '28 Mar 07:12');
    expect(MinimalFormat.relative(day, now: day), 'Today');
    expect(
      MinimalFormat.relative(day, now: day.add(const Duration(days: 3))),
      '3 days ago',
    );
    expect(
      MinimalFormat.relative(day, now: day.add(const Duration(days: 10))),
      '28 Mar',
    );
    const german = MinimalLocalizationsEn(_German());
    expect(MinimalFormat.relative(day, now: day, words: german), 'Heute');
    expect(german.firstDayOfWeek, DateTime.monday);
    expect(german.monthYear(day), 'März 2026');
  });

  test('English says every word', () {
    const en = MinimalLocalizationsEn();
    expect(en.months, hasLength(12));
    expect(en.monthsShort, hasLength(12));
    expect(en.weekdays, hasLength(7));
    expect(en.weekdaysShort, ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']);
    expect(en.firstDayOfWeek, DateTime.sunday);
    expect(en.ok, 'OK');
    expect(en.monthYear(DateTime(2026, 8)), 'August 2026');
    expect(en.fullDate(DateTime(2026, 8, 28)), 'Friday, 28 August 2026');
    expect(en.clear(null), 'Clear text');
    expect(en.clear('Name'), 'Clear Name');
    expect(en.decrease('Pages'), 'Decrease Pages');
    expect(en.code(null), 'Code');
    expect(en.code('Dart'), 'Dart code');
    expect(en.filters(active: true), 'Filters, active');
    expect(en.relativeDay(2), 'In 2 days');
    expect(en.relativeDay(9), '');
  });
}
