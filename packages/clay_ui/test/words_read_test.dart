// Words Clay draws to be read reach Material's 4.5:1 on their grounds, by
// day and by night: a step's figure before it is reached, a tag's word, the
// colon between a time's figures. The days of the next and last month in a
// calendar stand in a quiet tone of their own, about 3:1 on the calendar's
// clay and the ground (never faint), well below the month's own days; the
// month's days, the chosen day, today and a span read above them.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:ui_core_test/ui_core_test.dart';

final _stage = GlobalKey();

Future<void> _show(
  WidgetTester tester,
  Widget part,
  Brightness brightness,
) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ClayTheme(data: ClayThemeData.clay(brightness), child: app!),
      home: Builder(
        builder: (context) => ColoredBox(
          color: ClayTheme.of(context).colors.ground,
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(key: _stage, width: 342, child: part),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// What the contrast check finds under Material's bars in the stage: the
/// faults and the findings, each naming its words.
Future<List<String>> _under(WidgetTester tester) async {
  final report = await const DesignContrastCheck(look: 'clay')
      .check(_stage.currentContext!, runAsync: tester.runAsync);
  return [...report.problems, ...report.advisories];
}

Color _ink(WidgetTester tester, String figure) => tester
    .renderObject<RenderParagraph>(find.text(figure).first)
    .text
    .style!
    .color!;

void main() {
  setUpAll(clayLoadFonts);

  for (final brightness in Brightness.values) {
    final night = brightness == Brightness.dark;
    final c = night ? const ClayColors.dark() : const ClayColors.light();

    // February 2027 opens on a Monday: the 31st of January stands before it,
    // the 1st to 6th of March after it.
    testWidgets('${brightness.name}: the days outside the month stand quiet, '
        'never faint', (tester) async {
      await _show(
        tester,
        ClayCalendar(
          firstDate: DateTime(2026),
          lastDate: DateTime(2028),
          selectedDate: DateTime(2027, 2, 10),
          currentDate: DateTime(2027, 2, 17),
          onDateChanged: (_) {},
        ),
        brightness,
      );
      expect(find.text('31'), findsOneWidget);
      final outside = _ink(tester, '31');
      final month = _ink(tester, '15');
      for (final face in [c.clay, c.ground]) {
        // Clear of the 2.6 a faint figure falls under, with margin.
        expect(clayContrast(outside, face), greaterThanOrEqualTo(2.95));
        // About Apple's other-month grey (3.3), under any reading words.
        expect(clayContrast(outside, face), lessThan(4));
        // Clearly quieter than the month's own days: well under half.
        expect(
          clayContrast(month, face) / clayContrast(outside, face),
          greaterThanOrEqualTo(2.5),
        );
      }
      // A finding by design, as Cupertino's secondary words are; no fault.
      final report = await const DesignContrastCheck(look: 'clay')
          .check(_stage.currentContext!, runAsync: tester.runAsync);
      expect(report.problems, isEmpty);
      expect(report.advisories.where((s) => s.contains('"31"')), isNotEmpty);
    });

    testWidgets('${brightness.name}: the month, the chosen day, today and a '
        'span read above the days outside it', (tester) async {
      await _show(
        tester,
        ClayCalendar.range(
          firstDate: DateTime(2026),
          lastDate: DateTime(2028),
          selectedRange: ClayDateRange(
            start: DateTime(2027, 2, 9),
            end: DateTime(2027, 2, 12),
          ),
          currentDate: DateTime(2027, 2, 17),
          onRangeChanged: (_) {},
        ),
        brightness,
      );
      // The month's own days in plain ink, the days outside it quieter.
      expect(
        clayContrast(_ink(tester, '15'), c.clay),
        greaterThan(clayContrast(_ink(tester, '31'), c.clay)),
      );
      // The span, its ends and today stand on their own balls, rims and
      // grooves: their words read on them at 4.5 too.
      final under = await _under(tester);
      for (final figure in ['15', '9', '10', '11', '12', '17']) {
        expect(
          under.where((s) => s.contains('"$figure"')),
          isEmpty,
          reason: '$under',
        );
      }
    });

    testWidgets("${brightness.name}: a step's figure before it is reached "
        'reads at 4.5', (tester) async {
      await _show(
        tester,
        const ClayStepProgress(
          steps: ['Habit', 'Schedule', 'Reminder'],
          currentStep: 0,
        ),
        brightness,
      );
      final under = await _under(tester);
      expect(
        under.where((s) => s.contains('"2"') || s.contains('"3"')),
        isEmpty,
        reason: '$under',
      );
    });

    testWidgets("${brightness.name}: every tag's word reads at 4.5", (
      tester,
    ) async {
      await _show(
        tester,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tone in ClayTagTone.values)
              ClayTag('Draft ${tone.name}', tone: tone),
          ],
        ),
        brightness,
      );
      final under = await _under(tester);
      expect(
        under.where((s) => s.contains('Draft')),
        isEmpty,
        reason: '$under',
      );
    });

    testWidgets("${brightness.name}: a time's colon reads at 4.5", (
      tester,
    ) async {
      await _show(
        tester,
        ClayTimePicker(
          value: const ClayTime(hour: 7, minute: 30),
          onChanged: (_) {},
        ),
        brightness,
      );
      expect(find.text(':'), findsWidgets);
      final under = await _under(tester);
      expect(under.where((s) => s.contains('":"')), isEmpty, reason: '$under');
    });
  }
}
