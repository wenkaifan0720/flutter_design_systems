import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/scrolling_host.dart';

void main() {
  group('MinimalDatePicker', () {
    final today = DateTime(2026, 8, 28);

    testWidgets('a date pill opens the calendar; a day picks and closes', (
      tester,
    ) async {
      final chosen = <DateTime>[];
      await tester.pumpWidget(
        scrollingHost(
          MinimalDatePicker(
            labelText: 'Starts',
            value: DateTime(2026, 8, 21),
            mode: MinimalDatePickerMode.date,
            currentDate: today,
            onChanged: chosen.add,
          ),
        ),
      );
      expect(find.text('21 Aug 2026'), findsOneWidget);
      await tester.tap(find.text('21 Aug 2026'));
      await tester.pumpAndSettle();
      expect(find.text('August 2026'), findsOneWidget);
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      expect(chosen, [DateTime(2026, 8, 15)]);
      expect(find.text('August 2026'), findsNothing);
    });

    testWidgets('the calendar names days, marks today and the choice', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        scrollingHost(
          MinimalDatePicker(
            labelText: 'Started',
            value: DateTime(2026, 8, 21),
            mode: MinimalDatePickerMode.date,
            presentation: MinimalDatePickerPresentation.inline,
            currentDate: today,
            firstDate: DateTime(2026, 8, 3),
            onChanged: (_) {},
          ),
        ),
      );
      final chosen = tester.getSemantics(
        find.bySemanticsLabel('Friday, 21 August 2026'),
      );
      expect(
        chosen.getSemanticsData().flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(
        find.bySemanticsLabel('Friday, 28 August 2026, Today'),
        findsOneWidget,
      );
      final early = tester.getSemantics(
        find.bySemanticsLabel('Sunday, 2 August 2026'),
      );
      expect(
        early.getSemanticsData().flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pump();
      expect(find.text('September 2026'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Previous month'));
      await tester.tap(find.bySemanticsLabel('Previous month'));
      await tester.pump();
      expect(find.text('July 2026'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the time columns set the hour and the minute', (tester) async {
      final chosen = <DateTime>[];
      await tester.pumpWidget(
        scrollingHost(
          MinimalDatePicker(
            labelText: 'Reminder',
            value: DateTime(2026, 8, 28, 21, 30),
            mode: MinimalDatePickerMode.time,
            presentation: MinimalDatePickerPresentation.wheel,
            onChanged: chosen.add,
          ),
        ),
      );
      await tester.tap(find.text('35'));
      await tester.tap(find.text('22'));
      expect(chosen, [
        DateTime(2026, 8, 28, 21, 35),
        DateTime(2026, 8, 28, 22, 30),
      ]);
    });

    testWidgets('the time columns loop as a clock face does: on the hour, '
        '55 and 50 stand over 00', (tester) async {
      await tester.pumpWidget(
        scrollingHost(
          MinimalTimePicker(
            labelText: 'Reminder',
            value: DateTime(2026, 8, 28, 7),
            wheel: true,
            onChanged: (_) {},
          ),
        ),
      );
      final hour = tester.getCenter(find.text('07')).dy;
      final minute = tester.getCenter(find.text('00')).dy;
      expect(minute, moreOrLessEquals(hour, epsilon: 0.5));
      // Two rows over the pick in both columns: 05 and 06, 50 and 55.
      expect(tester.getCenter(find.text('55')).dy, minute - 32);
      expect(tester.getCenter(find.text('50')).dy, minute - 64);
      expect(tester.getCenter(find.text('06')).dy, hour - 32);
    });

    testWidgets('a confirming sheet commits only on Done', (tester) async {
      final chosen = <DateTime>[];
      await tester.pumpWidget(
        scrollingHost(
          MinimalDatePicker(
            labelText: 'Ends',
            value: DateTime(2026, 12, 31, 23),
            mode: MinimalDatePickerMode.date,
            confirmSelection: true,
            onChanged: chosen.add,
          ),
        ),
      );
      await tester.tap(find.text('31 Dec 2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('24'));
      await tester.pump();
      expect(chosen, isEmpty);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(chosen, [DateTime(2026, 12, 24, 23)]);
    });

    testWidgets('with no onChanged its pills are disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        scrollingHost(
          MinimalDatePicker(
            labelText: 'Created',
            value: DateTime(2026, 6, 2, 7, 12),
          ),
        ),
      );
      final pill = tester.getSemantics(
        find.bySemanticsLabel(RegExp('^Created, date')),
      );
      expect(
        pill.getSemanticsData().flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      await tester.tap(find.text('2 Jun 2026'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('June 2026'), findsNothing);
      expect(find.text('07:12'), findsOneWidget);
      handle.dispose();
    });
  });

  group('MinimalDatePicker range, format and keys', () {
    testWidgets('days past the maximum are out; times clamp into range', (
      tester,
    ) async {
      final chosen = <DateTime>[];
      await tester.pumpWidget(
        scrollingHost(
          Column(
            children: [
              MinimalDatePicker(
                labelText: 'Started',
                value: DateTime(2026, 8, 18),
                mode: MinimalDatePickerMode.date,
                presentation: MinimalDatePickerPresentation.inline,
                lastDate: DateTime(2026, 8, 20),
                onChanged: chosen.add,
              ),
              MinimalDatePicker(
                labelText: 'Reminder',
                value: DateTime(2026, 8, 28, 10),
                mode: MinimalDatePickerMode.time,
                presentation: MinimalDatePickerPresentation.wheel,
                firstDate: DateTime(2026, 8, 28, 9),
                onChanged: chosen.add,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('25'), warnIfMissed: false);
      expect(chosen, isEmpty);
      await tester.tap(find.text('08'));
      expect(chosen, [DateTime(2026, 8, 28, 9)]);
    });

    testWidgets('the 12-hour clock prints in the pill and the columns', (
      tester,
    ) async {
      await tester.pumpWidget(
        scrollingHost(
          Column(
            children: [
              MinimalDatePicker(
                labelText: 'Reminder',
                value: DateTime(2026, 8, 28, 21, 30),
                mode: MinimalDatePickerMode.time,
                use24HourFormat: false,
                onChanged: (_) {},
              ),
              MinimalDatePicker(
                labelText: 'Reminder',
                value: DateTime(2026, 8, 28, 21, 30),
                mode: MinimalDatePickerMode.time,
                presentation: MinimalDatePickerPresentation.wheel,
                use24HourFormat: false,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );
      expect(find.text('9:30 PM'), findsOneWidget);
      expect(find.text('9 PM'), findsOneWidget);
    });

    testWidgets('the chosen time prints in the ink, centred under its head', (
      tester,
    ) async {
      await tester.pumpWidget(
        scrollingHost(
          MinimalDatePicker(
            labelText: 'Reminder',
            value: DateTime(2026, 8, 28, 21, 30),
            mode: MinimalDatePickerMode.time,
            presentation: MinimalDatePickerPresentation.wheel,
            onChanged: (_) {},
          ),
        ),
      );
      final t = MinimalThemeData.preset('standard', Brightness.light);
      expect(tester.widget<Text>(find.text('21')).style!.color, t.foreground);
      expect(
        tester.getCenter(find.text('HOUR')).dx,
        moreOrLessEquals(tester.getCenter(find.text('21')).dx, epsilon: 1),
      );
    });

    testWidgets('the arrow keys walk the days across months; Enter picks', (
      tester,
    ) async {
      final chosen = <DateTime>[];
      await tester.pumpWidget(
        scrollingHost(
          MinimalDatePicker(
            labelText: 'Started',
            value: DateTime(2026, 8, 21),
            mode: MinimalDatePickerMode.date,
            presentation: MinimalDatePickerPresentation.inline,
            onChanged: chosen.add,
          ),
        ),
      );
      final grid = find.byWidgetPredicate(
        (w) => w is Focus && w.focusNode?.debugLabel == 'Calendar days',
      );
      tester.widget<Focus>(grid).focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(chosen, [DateTime(2026, 8, 22)]);
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      }
      await tester.pump();
      expect(find.text('July 2026'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(chosen.last, DateTime(2026, 7, 25));
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      expect(find.text('August 2026'), findsOneWidget);
    });
  });
}
