// A calendar writes its days in the app's digits, as Material's does: in Arabic the 20th reads ٢٠.
import 'package:comic_ui/comic_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget home) async {
  await tester.runAsync(comicLoadFonts);
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [RawWidgetsLocalizations.delegate],
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, animation, secondary) => builder(context),
      ),
      builder: (context, navigator) => ComicHost(
        light: ComicThemeData.offset(),
        dark: ComicThemeData.offset(Brightness.dark),
        brightness: Brightness.light,
        child: navigator!,
      ),
      home: Align(alignment: Alignment.topCenter, child: home),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a ComicCalendar writes its days in Arabic-Indic digits', (
    tester,
  ) async {
    final days = RawCalendarController(
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      initialMonth: DateTime(2026, 11),
    );
    addTearDown(days.dispose);
    await _pump(tester, ComicCalendar(controller: days, onChanged: (_) {}));
    expect(find.text('٢٠'), findsOneWidget);
    expect(find.text('20'), findsNothing);
  });

  testWidgets('a ComicDatePicker writes its days in Arabic-Indic digits', (
    tester,
  ) async {
    await _pump(
      tester,
      ComicDatePicker(
        value: DateTime(2026, 11, 9),
        currentDate: DateTime(2026, 11, 9),
        onChanged: (_) {},
      ),
    );
    expect(find.text('٢٠'), findsOneWidget);
    expect(find.text('20'), findsNothing);
  });
}
