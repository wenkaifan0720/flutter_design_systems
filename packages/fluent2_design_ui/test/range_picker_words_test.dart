// A range picker's month and weekday heads are in the app's language, as
// Fluent's calendar and date picker are: an Arabic app read "November 2026"
// and "Su Mo Tu" over Arabic-Indic days. English stays as it was, and an
// app's own Fluent 2 words still win.
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _Own extends Fluent2LocalizationsEn {
  const _Own();

  @override
  List<String> get weekdaysShort => const [
    'L',
    'Ma',
    'Me',
    'J',
    'V',
    'Sa',
    'D',
  ];

  @override
  String monthYear(DateTime date) => 'novembre ${date.year}';
}

class _OwnDelegate extends LocalizationsDelegate<Fluent2Localizations> {
  const _OwnDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<Fluent2Localizations> load(Locale locale) =>
      SynchronousFuture<Fluent2Localizations>(const _Own());

  @override
  bool shouldReload(_OwnDelegate old) => false;
}

Future<RawWidgetsLocalizations> _show(
  WidgetTester tester,
  Locale locale, {
  LocalizationsDelegate<Fluent2Localizations> words =
      Fluent2Localizations.delegate,
}) async {
  late RawWidgetsLocalizations names;
  final controller = RawCalendarController(
    firstDate: DateTime(2026),
    lastDate: DateTime(2027, 12, 31),
    mode: RawCalendarMode.range,
    initialMonth: DateTime(2026, 11),
    currentDate: DateTime(2026, 11, 20),
  );
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: [RawWidgetsLocalizations.delegate, words],
      builder: (context, _) => Fluent2Host(
        child: Builder(
          builder: (context) {
            names = RawWidgetsLocalizations.of(context);
            return SizedBox(
              width: 360,
              child: Fluent2DateRangePicker(controller: controller, months: 1),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return names;
}

void main() {
  setUpAll(fluent2LoadFonts);

  testWidgets('in Arabic a range picker heads its month and weekdays in '
      'Arabic', (tester) async {
    final names = await _show(tester, const Locale('ar'));
    expect(
      find.text(names.formatMonthYear(DateTime(2026, 11))),
      findsOneWidget,
    );
    expect(find.text('November 2026'), findsNothing);
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      expect(
        find.text(names.formatShortWeekday(weekday)),
        findsOneWidget,
        reason: '$weekday',
      );
    }
    expect(find.text('Su'), findsNothing);
  });

  testWidgets('in English it heads them as before', (tester) async {
    await _show(tester, const Locale('en'));
    expect(find.text('November 2026'), findsOneWidget);
    for (final head in const ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']) {
      expect(find.text(head), findsOneWidget, reason: head);
    }
  });

  testWidgets("an app's own Fluent 2 words still head it", (tester) async {
    await _show(tester, const Locale('ar'), words: const _OwnDelegate());
    expect(find.text('novembre 2026'), findsOneWidget);
    for (final head in const ['L', 'Ma', 'Me', 'J', 'V', 'Sa', 'D']) {
      expect(find.text(head), findsOneWidget, reason: head);
    }
  });
}
