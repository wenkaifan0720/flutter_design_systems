/// A calendar's days are painted in the app's digits, as Material's day picker
/// writes them: in Arabic the 20th shows ٢٠, its year and its name already in
/// Arabic-Indic digits. A date picker's headline reads in the app's words
/// too (٢٠ نوفمبر ٢٠٢٦). English keeps 20 and "20 Nov 2026".
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

Future<void> _pump(WidgetTester tester, Locale locale, Widget home) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xff000000),
      locale: locale,
      supportedLocales: [locale],
      localizationsDelegates: const [RawWidgetsLocalizations.delegate],
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      builder: (context, child) => Directionality(
        textDirection: locale.languageCode == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: ExpressiveHost(
          theme: _theme,
          brightness: Brightness.light,
          child: child!,
        ),
      ),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

Widget _calendar() => Center(
  child: SizedBox(
    width: 358,
    child: ExpressiveCalendar(
      firstDate: DateTime(2026),
      lastDate: DateTime(2027),
      value: DateTime(2026, 11, 20),
      currentDate: DateTime(2026, 11, 18),
      onChanged: (_) {},
    ),
  ),
);

Widget _rangeOpener() => Center(
  child: Builder(
    builder: (context) => ExpressiveTextButton(
      'Stay',
      onPressed: () => showExpressiveDateRangePicker(
        context: context,
        initialStart: DateTime(2026, 11, 20),
        initialEnd: DateTime(2026, 11, 23),
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
        currentDate: DateTime(2026, 11, 18),
      ),
    ),
  ),
);

Widget _opener() => Center(
  child: Builder(
    builder: (context) => ExpressiveTextButton(
      'Due',
      onPressed: () => showExpressiveDatePicker(
        context: context,
        initialDate: DateTime(2026, 11, 20),
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
        currentDate: DateTime(2026, 11, 18),
      ),
    ),
  ),
);

void main() {
  setUpAll(expressiveLoadFonts);

  group('ExpressiveCalendar', () {
    testWidgets('in Arabic the days show Arabic-Indic digits', (tester) async {
      await _pump(tester, const Locale('ar'), _calendar());
      expect(find.text('١٨'), findsOneWidget);
      expect(find.text('٢٠'), findsOneWidget, reason: 'the chosen day too');
      expect(find.text('18'), findsNothing);
      expect(find.text('20'), findsNothing);
    });

    testWidgets('in English the days show Western digits', (tester) async {
      await _pump(tester, const Locale('en'), _calendar());
      expect(find.text('18'), findsOneWidget);
      expect(find.text('١٨'), findsNothing);
    });
  });

  group('showExpressiveDatePicker', () {
    testWidgets('in Arabic the days show Arabic-Indic digits', (tester) async {
      await _pump(tester, const Locale('ar'), _opener());
      await tester.tap(find.text('Due'));
      await tester.pumpAndSettle();
      expect(find.text('١٨'), findsOneWidget);
      expect(find.text('٢٠'), findsOneWidget, reason: 'the chosen day too');
      expect(find.text('18'), findsNothing);
      expect(find.text('20'), findsNothing);
    });

    testWidgets('in English the days show Western digits', (tester) async {
      await _pump(tester, const Locale('en'), _opener());
      await tester.tap(find.text('Due'));
      await tester.pumpAndSettle();
      expect(find.text('18'), findsOneWidget);
      expect(find.text('١٨'), findsNothing);
    });

    testWidgets('in Arabic the headline reads in Arabic', (tester) async {
      await _pump(tester, const Locale('ar'), _opener());
      await tester.tap(find.text('Due'));
      await tester.pumpAndSettle();
      expect(find.text('٢٠ نوفمبر ٢٠٢٦'), findsOneWidget);
      expect(find.text('20 Nov 2026'), findsNothing);
    });

    testWidgets('in English the headline is "20 Nov 2026"', (tester) async {
      await _pump(tester, const Locale('en'), _opener());
      await tester.tap(find.text('Due'));
      await tester.pumpAndSettle();
      expect(find.text('20 Nov 2026'), findsOneWidget);
    });
  });

  group('showExpressiveDateRangePicker', () {
    testWidgets('in Arabic the headline reads in Arabic', (tester) async {
      await _pump(tester, const Locale('ar'), _rangeOpener());
      await tester.tap(find.text('Stay'));
      await tester.pumpAndSettle();
      expect(find.text('٢٠ نوفمبر ٢٠٢٦'), findsOneWidget);
      expect(find.text('٢٣ نوفمبر ٢٠٢٦'), findsOneWidget);
      expect(find.text('20 Nov 2026'), findsNothing);
    });

    testWidgets('in English the headline is "20 Nov 2026"', (tester) async {
      await _pump(tester, const Locale('en'), _rangeOpener());
      await tester.tap(find.text('Stay'));
      await tester.pumpAndSettle();
      expect(find.text('20 Nov 2026'), findsOneWidget);
      expect(find.text('23 Nov 2026'), findsOneWidget);
    });
  });
}
