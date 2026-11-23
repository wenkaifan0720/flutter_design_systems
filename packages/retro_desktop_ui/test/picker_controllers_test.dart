// The colour picker and the calendar take a value and a callback, as Flutter's pickers do, or a controller handed in:
// without one each keeps a controller of its own, made from its value and disposed with it; a handed-in controller is
// the caller's and is never disposed; a swap between the two, either way, keeps the choice. Leak tracking (the
// package's flutter_test_config.dart) fails a test whose picker leaves its own controller undisposed.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

Future<void> _pump(WidgetTester tester, Widget picker) async {
  tester.view.physicalSize = const Size(1024, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    retroDesktopApp(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 360, child: picker),
      ),
      width: 1024,
    ),
  );
  await tester.pump();
}

// The day's button in the shown month, read as a screen reader reads it.
Finder _day(int day, String month) =>
    find.bySemanticsLabel(RegExp('\\b$day $month|$month $day\\b'));

void main() {
  group('RetroDesktopColorPicker', () {
    testWidgets(
      'without a controller it starts at its value and reports a pick',
      (tester) async {
        final picked = <Color>[];
        await _pump(
          tester,
          RetroDesktopColorPicker(
            value: const Color(0xFF3366FF),
            onChanged: picked.add,
          ),
        );
        expect(find.text('#3366FF'), findsOneWidget);
        // Near the shade field's top start (the picker's top): little
        // saturation, full brightness.
        await tester.tapAt(
          tester.getTopLeft(find.byType(RetroDesktopColorPicker)) +
              const Offset(8, 8),
        );
        await tester.pump();
        expect(picked, isNotEmpty);
        expect(picked.last, isNot(const Color(0xFF3366FF)));
        expect(find.text('#3366FF'), findsNothing);
      },
    );

    testWidgets('a new value moves it there without reporting it', (
      tester,
    ) async {
      final picked = <Color>[];
      await _pump(
        tester,
        RetroDesktopColorPicker(
          value: const Color(0xFF3366FF),
          onChanged: picked.add,
        ),
      );
      await _pump(
        tester,
        RetroDesktopColorPicker(
          value: const Color(0xFFCC3300),
          onChanged: picked.add,
        ),
      );
      expect(find.text('#CC3300'), findsOneWidget);
      expect(picked, isEmpty);
    });

    testWidgets('a handed-in controller is never disposed; its own is', (
      tester,
    ) async {
      final handed = RawColorController(const Color(0xFF3366FF));
      addTearDown(handed.dispose);
      final picked = <Color>[];
      await _pump(
        tester,
        RetroDesktopColorPicker(controller: handed, onChanged: picked.add),
      );
      handed.color = const Color(0xFF00AA00);
      await tester.pump();
      expect(find.text('#00AA00'), findsOneWidget);
      expect(picked, [const Color(0xFF00AA00)]);
      // Handed in, then let go: its own starts where the handed-in one was.
      await _pump(tester, RetroDesktopColorPicker(onChanged: picked.add));
      expect(find.text('#00AA00'), findsOneWidget);
      // Its own, then a handed-in one again: its own is disposed.
      await _pump(tester, RetroDesktopColorPicker(controller: handed));
      await tester.pumpWidget(const SizedBox());
      // Still the caller's: it takes listeners and changes.
      handed.color = const Color(0xFF000000);
      expect(handed.color, const Color(0xFF000000));
    });
  });

  group('RetroDesktopCalendar', () {
    testWidgets(
      'without a controller it shows its value chosen and reports a day',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final chosen = <DateTime>[];
        await _pump(
          tester,
          RetroDesktopCalendar(
            firstDate: DateTime(2026),
            lastDate: DateTime(2027),
            value: DateTime(2026, 11, 6),
            onChanged: chosen.add,
          ),
        );
        expect(find.text('November 2026'), findsOneWidget);
        expect(
          tester.getSemantics(_day(6, 'November')),
          isSemantics(isSelected: true),
        );
        await tester.tap(find.text('12'));
        await tester.pump();
        expect(chosen, [DateTime(2026, 11, 12)]);
        expect(
          tester.getSemantics(_day(12, 'November')),
          isSemantics(isSelected: true),
        );
        semantics.dispose();
      },
    );

    testWidgets('a new value is chosen and shown without reporting it', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final chosen = <DateTime>[];
      Widget calendar(DateTime value) => RetroDesktopCalendar(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
        value: value,
        onChanged: chosen.add,
      );
      await _pump(tester, calendar(DateTime(2026, 11, 6)));
      await _pump(tester, calendar(DateTime(2026, 3, 3)));
      expect(find.text('March 2026'), findsOneWidget);
      expect(
        tester.getSemantics(_day(3, 'March')),
        isSemantics(isSelected: true),
      );
      expect(chosen, isEmpty);
      semantics.dispose();
    });

    testWidgets('a handed-in controller is never disposed; its own is', (
      tester,
    ) async {
      final handed = RawCalendarController(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
        selectedDate: DateTime(2026, 5, 20),
      );
      addTearDown(handed.dispose);
      await _pump(tester, RetroDesktopCalendar(controller: handed));
      expect(find.text('May 2026'), findsOneWidget);
      // Handed in, then let go: its own keeps the month and the day.
      await _pump(
        tester,
        RetroDesktopCalendar(
          firstDate: DateTime(2026),
          lastDate: DateTime(2027),
        ),
      );
      expect(find.text('May 2026'), findsOneWidget);
      // New limits: a new one of its own, the old one disposed.
      await _pump(
        tester,
        RetroDesktopCalendar(
          firstDate: DateTime(2026),
          lastDate: DateTime(2028),
        ),
      );
      expect(find.text('May 2026'), findsOneWidget);
      // Its own, then a handed-in one again: its own is disposed.
      await _pump(tester, RetroDesktopCalendar(controller: handed));
      await tester.pumpWidget(const SizedBox());
      // Still the caller's: it takes listeners and changes.
      handed.select(DateTime(2026, 5, 21));
      expect(handed.selectedDate, DateTime(2026, 5, 21));
    });
  });
}
