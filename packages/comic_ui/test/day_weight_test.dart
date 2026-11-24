// A chosen day's number has one weight in a date picker and in a calendar: heavy, as a range's chosen ends are; the
// other days the body's.
import 'package:comic_ui/comic_host.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget home,
  Brightness brightness,
) async {
  await tester.runAsync(comicLoadFonts);
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      localizationsDelegates: const [RawWidgetsLocalizations.delegate],
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, animation, secondary) => builder(context),
      ),
      builder: (context, navigator) => ComicHost(
        light: ComicThemeData.offset(),
        dark: ComicThemeData.offset(Brightness.dark),
        brightness: brightness,
        child: navigator!,
      ),
      home: Align(alignment: Alignment.topCenter, child: home),
    ),
  );
  await tester.pumpAndSettle();
}

FontWeight? _weight(WidgetTester tester, String day) =>
    tester.widget<Text>(find.text(day)).style?.fontWeight;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      '${brightness.name}: the chosen day is as heavy in a date picker '
      'as in a calendar, and the rest as light',
      (tester) async {
        final days = RawCalendarController(
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          selectedDate: DateTime(2026, 11, 20),
          currentDate: DateTime(2026, 11, 9),
        );
        addTearDown(days.dispose);
        await _pump(
          tester,
          ComicCalendar(controller: days, onChanged: (_) {}),
          brightness,
        );
        final calendar = (_weight(tester, '20'), _weight(tester, '12'));
        await _pump(
          tester,
          ComicDatePicker(
            value: DateTime(2026, 11, 20),
            currentDate: DateTime(2026, 11, 9),
            onChanged: (_) {},
          ),
          brightness,
        );
        final picker = (_weight(tester, '20'), _weight(tester, '12'));
        expect(calendar.$1, FontWeight.w800);
        expect(picker, calendar);
        expect(picker.$2, isNot(FontWeight.w800));
      },
    );
  }
}
