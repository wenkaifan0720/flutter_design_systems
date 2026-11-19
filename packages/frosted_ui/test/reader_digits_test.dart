// A month's days are painted in the reader's digits, as they are read: in Arabic the 18th shows ١٨, its name already
// saying "١٨ نوفمبر" (the user's review, 11-18: Stint's due-date calendar showed 18 under a name of ١٨). In English
// the same days show 18.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

Future<void> _pump(WidgetTester tester, Locale locale) async {
  tester.view.physicalSize = const Size(390, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: locale,
      supportedLocales: DesignLocalizations.supportedLocales,
      localizationsDelegates: const [DesignLocalizations.delegate],
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
            child: FrostedCalendar(
              firstDate: DateTime(2026),
              lastDate: DateTime(2027),
              value: DateTime(2026, 11, 20),
              currentDate: DateTime(2026, 11, 18),
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('in Arabic the days show Arabic digits', (tester) async {
    await _pump(tester, const Locale('ar'));
    expect(find.text('١٨'), findsOneWidget);
    expect(find.text('٢٠'), findsOneWidget, reason: 'the chosen day too');
    expect(find.text('18'), findsNothing);
  });

  testWidgets('in English the days show Western digits', (tester) async {
    await _pump(tester, const Locale('en'));
    expect(find.text('18'), findsOneWidget);
    expect(find.text('١٨'), findsNothing);
  });
}
