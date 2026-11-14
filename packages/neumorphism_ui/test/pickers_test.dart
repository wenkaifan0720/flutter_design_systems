import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void main() {
  setUpAll(loadNeumorphicFonts);
  for (final width in [320.0, 350.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final direction in TextDirection.values) {
        testWidgets('time targets wrap at $width, text $scale, $direction', (
          tester,
        ) async {
          NeumorphicTime? picked;
          await tester.pumpWidget(
            neumorphicApp(
              Center(
                child: SizedBox(
                  width: width,
                  child: SingleChildScrollView(
                    child: NeumorphicTimePicker(
                      value: const NeumorphicTime(0, 0),
                      twentyFour: true,
                      minuteStep: 1,
                      onChanged: (value) => picked = value,
                    ),
                  ),
                ),
              ),
              direction: direction,
              textScale: scale,
            ),
          );
          for (final target in find.byType(DesignPressable).evaluate()) {
            final size = tester.getSize(find.byWidget(target.widget));
            expect(size.width, greaterThanOrEqualTo(48));
            expect(size.height, greaterThanOrEqualTo(48));
          }
          await tester.ensureVisible(find.text('59'));
          await tester.tap(find.text('59'));
          expect(picked, const NeumorphicTime(0, 59));
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  test(
    'time is a neutral value with localized formatting and copy semantics',
    () {
      const time = NeumorphicTime(0, 5);
      expect(time.format(), '12:05 AM');
      expect(time.format(twentyFour: true), '00:05');
      expect(time.copyWith(hour: 12).format(), '12:05 PM');
      expect(time.copyWith(), time);
      expect(time.copyWith().hashCode, time.hashCode);
      expect(() => NeumorphicTime(24, 0), throwsAssertionError);
    },
  );
  test('calendar week start follows the locale data', () async {
    final us = await NeumorphicLocalizations.delegate.load(
      const Locale('en', 'US'),
    );
    final gb = await NeumorphicLocalizations.delegate.load(
      const Locale('en', 'GB'),
    );
    expect(us.firstDayOfWeek, DateTime.sunday);
    expect(gb.firstDayOfWeek, DateTime.monday);
  });
  for (final direction in TextDirection.values) {
    testWidgets(
      'calendar handles leap days and logical arrow motion in ${direction.name}',
      (tester) async {
        DateTime? picked;
        await tester.pumpWidget(
          neumorphicApp(
            Center(
              child: SizedBox(
                width: 350,
                child: NeumorphicDatePicker(
                  value: DateTime(2028, 2, 28),
                  first: DateTime(2028, 2, 1),
                  last: DateTime(2028, 3, 31),
                  onChanged: (v) => picked = v,
                ),
              ),
            ),
            direction: direction,
          ),
        );
        final selected = tester.widget<NeumorphicTap>(
          find.byWidgetPredicate(
            (w) => w is NeumorphicTap && w.selected == true,
          ),
        );
        selected.focusNode!.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(
          direction == TextDirection.rtl
              ? LogicalKeyboardKey.arrowLeft
              : LogicalKeyboardKey.arrowRight,
        );
        await tester.pumpAndSettle();
        expect(picked, isNull, reason: 'arrows move focus without committing');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(picked, DateTime(2028, 2, 29));
        await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(picked, DateTime(2028, 3, 29));
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('date bounds disable unavailable days and month movement', (
    tester,
  ) async {
    DateTime? picked;
    await tester.pumpWidget(
      neumorphicApp(
        Center(
          child: SizedBox(
            width: 350,
            child: NeumorphicDatePicker(
              value: DateTime(2026, 11, 6),
              first: DateTime(2026, 11, 5),
              last: DateTime(2026, 11, 8),
              onChanged: (v) => picked = v,
            ),
          ),
        ),
      ),
    );
    final arrows = tester.widgetList<NeumorphicIconButton>(
      find.byType(NeumorphicIconButton),
    );
    expect(arrows.every((b) => b.onPressed == null), isTrue);
    final fifth = find.byWidgetPredicate(
      (w) =>
          w is NeumorphicTap && w.label?.contains('November 5, 2026') == true,
    );
    tester.widget<NeumorphicTap>(fifth).focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(picked, DateTime(2026, 11, 5));
    final disabled = tester
        .widgetList<NeumorphicTap>(find.byType(NeumorphicTap))
        .where((w) => w.label?.contains('November 4, 2026') == true)
        .single;
    expect(disabled.onPressed, isNull);
  });
  testWidgets(
    'time converts noon and midnight correctly and keeps minute precision',
    (tester) async {
      var time = const NeumorphicTime(9, 30);
      await tester.pumpWidget(
        neumorphicApp(
          SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) => NeumorphicTimePicker(
                value: time,
                twentyFour: false,
                minuteStep: 15,
                onChanged: (v) => setState(() => time = v),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      expect(time, const NeumorphicTime(9, 15));
      await tester.ensureVisible(find.text('PM'));
      await tester.tap(find.text('PM'));
      await tester.pumpAndSettle();
      expect(time, const NeumorphicTime(21, 15));
      await tester.ensureVisible(find.text('12'));
      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();
      expect(time, const NeumorphicTime(12, 15));
      await tester.ensureVisible(find.text('AM'));
      await tester.tap(find.text('AM'));
      await tester.pumpAndSettle();
      expect(time, const NeumorphicTime(0, 15));
      await tester.pumpWidget(
        neumorphicApp(
          SingleChildScrollView(
            child: NeumorphicTimePicker(
              value: const NeumorphicTime(23, 59),
              twentyFour: true,
              minuteStep: 15,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(
        find.text('59'),
        findsOneWidget,
        reason: 'a supplied off-step minute stays editable',
      );
      expect(find.text('23:59'), findsOneWidget);
      expect(find.text('AM'), findsNothing);
    },
  );
  testWidgets('date and time sheets return only confirmed results', (
    tester,
  ) async {
    late BuildContext host;
    await tester.pumpWidget(
      neumorphicApp(
        Builder(
          builder: (context) {
            host = context;
            return const Text('Page');
          },
        ),
      ),
    );
    final date = showNeumorphicDatePicker(host, value: DateTime(2026, 11, 6));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    expect(await date, DateTime(2026, 11, 6));
    final time = showNeumorphicTimePicker(
      host,
      value: const NeumorphicTime(9, 30),
      minuteStep: 15,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    expect(await time, const NeumorphicTime(9, 30));
    final canceled = showNeumorphicDatePicker(
      host,
      value: DateTime(2026, 11, 6),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(await canceled, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('day targets remain 48 wide in a narrow scrolling calendar', (
    tester,
  ) async {
    await tester.pumpWidget(
      neumorphicApp(
        Center(
          child: SizedBox(
            width: 280,
            child: NeumorphicDatePicker(
              value: DateTime(2026, 11, 6),
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    final days = find.byWidgetPredicate(
      (w) => w is NeumorphicTap && w.label?.contains('November') == true,
    );
    for (final e in days.evaluate()) {
      expect(
        tester.getSize(find.byWidget(e.widget)).width,
        greaterThanOrEqualTo(48),
      );
    }
    expect(tester.takeException(), isNull);
  });
  check(
    'date picker',
    () => NeumorphicDatePicker(value: DateTime(2026, 11, 6), onChanged: (_) {}),
  );
  check(
    'time picker 12 hour',
    () => NeumorphicTimePicker(
      value: const NeumorphicTime(9, 30),
      twentyFour: false,
      onChanged: (_) {},
    ),
  );
  check(
    'time picker 24 hour',
    () => NeumorphicTimePicker(
      value: const NeumorphicTime(23, 59),
      twentyFour: true,
      onChanged: (_) {},
    ),
  );
}
