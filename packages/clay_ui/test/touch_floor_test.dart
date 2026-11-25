// Clay's parts take the touch floor ui_core declares, 40 by 40 for a
// finger, where they held a finger's 44 of their own, and follow a floor an
// app declares round them (an Android app's 48, say). A part that draws at
// the floor (a slider's slot, a day, a tag's slot) draws there on every
// input, so a desk keeps the phone's rhythm, as Material keeps its cells.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

/// Shows [part] by day in a 390 phone, under a declared [touch] floor (or
/// ui_core's own when null) and [input].
Future<void> _show(
  WidgetTester tester,
  Widget part, {
  double? touch,
  RawInput? input,
  double width = 342,
}) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => ClayTheme(
        data: ClayThemeData.clay(Brightness.light),
        child: touch == null && input == null
            ? app!
            : RawTapTargetScope(
                targets: RawTapTargets(
                  touch: Size.square(touch ?? 40),
                  input: input,
                ),
                child: app!,
              ),
      ),
      home: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(width: width, child: part),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(clayLoadFonts);

  for (final floor in const [40.0, 48.0]) {
    final declared = floor == 40 ? null : floor;
    final named = floor == 40 ? "ui_core's 40" : 'a declared 48';

    testWidgets('a slider stands in the touch floor: $named', (tester) async {
      await _show(
        tester,
        ClaySlider(value: 0.5, onChanged: (_) {}),
        touch: declared,
      );
      expect(tester.getSize(find.byType(ClaySlider)).height, floor);
    });

    testWidgets("a rating's stars stand in the touch floor: $named", (
      tester,
    ) async {
      await _show(
        tester,
        ClayRating(value: 3, onChanged: (_) {}, size: 24),
        touch: declared,
      );
      expect(tester.getSize(find.byType(ClayRating)).height, floor);
    });

    testWidgets("a calendar's day is the touch floor tall: $named", (
      tester,
    ) async {
      await _show(
        tester,
        ClayCalendar(
          firstDate: DateTime(2026),
          lastDate: DateTime(2027),
          selectedDate: DateTime(2026, 11, 19),
          onDateChanged: (_) {},
        ),
        touch: declared,
      );
      // The day's ball, 4 less than its row.
      final ball = tester.getSize(
        find
            .ancestor(
              of: find.text('15'),
              matching: find.byType(AnimatedClaySurface),
            )
            .first,
      );
      expect(ball.height, floor - 4);
    });

    testWidgets("a tag's key that removes it is the touch floor square: "
        '$named', (tester) async {
      await _show(
        tester,
        ClayTagInput<String>(
          labelText: 'Tags',
          values: const ['Morning'],
          onChanged: (_) {},
          onCreate: (text) => text,
        ),
        touch: declared,
      );
      final key = find.byWidgetPredicate(
        (w) => w is RawButton && (w.semanticLabel ?? '').endsWith('Morning'),
      );
      expect(key, findsOneWidget);
      expect(tester.getSize(key), Size(floor, floor));
    });

    testWidgets("a time field's figure takes the touch floor wide: $named", (
      tester,
    ) async {
      await _show(
        tester,
        ClayTimeField(
          labelText: 'Remind me at',
          value: const ClayTime(hour: 7, minute: 30),
          onChanged: (_) {},
        ),
        touch: declared,
      );
      final figure = find
          .ancestor(of: find.text('30'), matching: find.byType(MouseRegion))
          .first;
      expect(tester.getSize(figure).width, floor);
    });
  }

  for (final floor in const [40.0, 48.0]) {
    testWidgets('a menu bar on a desk stands the touch floor tall: '
        '${floor.round()}', (tester) async {
      await _show(
        tester,
        ClayMenuBar(
          menus: [
            ClayMenuBarMenu(
              label: 'Habit',
              items: [ClayMenuItem(label: 'New habit', onPressed: () {})],
            ),
          ],
        ),
        touch: floor,
        input: RawInput.pointer,
      );
      expect(
        tester
            .getSize(
              find
                  .descendant(
                    of: find.byType(ClayMenuBar),
                    matching: find.byType(ClaySurface),
                  )
                  .first,
            )
            .height,
        floor,
      );
    });
  }

  testWidgets('stacked segments each take the floor declared round them', (
    tester,
  ) async {
    Future<double> height(double? touch) async {
      await _show(
        tester,
        ClaySegmentedButton<String>(
          segments: const [
            ClaySegment(value: 'morning', label: 'Morning'),
            ClaySegment(value: 'evening', label: 'Evening'),
            ClaySegment(value: 'anytime', label: 'Anytime'),
          ],
          selected: 'morning',
          onChanged: (_) {},
        ),
        touch: touch,
        width: 150,
      );
      return tester.getSize(find.byType(ClaySegmentedButton<String>)).height;
    }

    final at40 = await height(null);
    final at48 = await height(48);
    // Three rows, each 8 taller.
    expect(at48 - at40, 24);
  });

  testWidgets("a table's headings follow the floor declared round them", (
    tester,
  ) async {
    final controller = ClayTableController<String>(
      rows: const ['Water', 'Walk'],
      columns: const [ClayDataColumn(id: 'name', label: 'Habit name')],
    );
    addTearDown(controller.dispose);
    Future<double> height(double? touch) async {
      await _show(
        tester,
        ClayDataTable<String>(
          controller: controller,
          cell: (row, column) => row,
          selectable: false,
        ),
        touch: touch,
      );
      return tester
          .getSize(
            find
                .ancestor(
                  of: find.text('Habit name'),
                  matching: find.byType(AnimatedClaySurface),
                )
                .first,
          )
          .height;
    }

    final at40 = await height(null);
    final at48 = await height(48);
    expect(at40, greaterThanOrEqualTo(40));
    expect(at48, 48);
  });

  for (final input in RawInput.values) {
    testWidgets("a split view's handle at rest: shown to a finger, kept for "
        'a pointer to find (${input.name})', (tester) async {
      await _show(
        tester,
        const SizedBox(
          height: 240,
          child: ClaySplitView(first: Text('Habits'), second: Text('Water')),
        ),
        input: input,
      );
      final shown = tester.widget<AnimatedOpacity>(
        find.descendant(
          of: find.byType(ClaySplitView),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(shown.opacity, input == RawInput.touch ? 1 : 0);
    });
  }
}
