// Gloss's parts drawn at a finger's size take ui_core's touch floor, 40 by
// 40, on every input (they were 44): a slider's row, a range slider's beads,
// a tag's slot and the bead that removes it, a table's header and a
// calendar's days. An app's RawTapTargetScope round its pages raises the
// floor there. Under a finger a split view's bead shows at rest (under the
// floor of 40 it had hidden, read as a pointer's). A tag input's tags and a
// breadcrumb's places lay out in RawChipGroup.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

const _floor48 = RawTapTargets(touch: Size.square(48));

Future<void> _show(
  WidgetTester tester,
  Widget part, {
  RawTapTargets? targets,
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // Gloss's theme declares the look's floors; an app raises them under it,
  // round its pages.
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => GlossHost(
        theme: GlossThemeData.light(),
        darkTheme: GlossThemeData.dark(),
        brightness: Brightness.light,
        child: app!,
      ),
      home: Builder(
        builder: (context) {
          final body = Align(
            alignment: Alignment.topCenter,
            child: Padding(padding: const EdgeInsets.all(24), child: part),
          );
          return targets == null
              ? body
              : RawTapTargetScope(targets: targets, child: body);
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(glossLoadFonts);
  final floor = RawTapTargets.fallback.touch;

  for (final (name, targets, side) in [
    ('the touch floor', null, floor.height),
    ("an app's floor of 48", _floor48, 48.0),
  ]) {
    testWidgets(
      "a slider stands $name, on every input",
      (tester) async {
        await _show(
          tester,
          SizedBox(
            width: 300,
            child: GlossSlider(value: 0.4, onChanged: (_) {}),
          ),
          targets: targets,
        );
        final row = find
            .descendant(
              of: find.byType(GlossSlider),
              matching: find.byType(GestureDetector),
            )
            .first;
        expect(tester.getSize(row).height, side);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.macOS,
      }),
    );

    testWidgets("a range slider's beads take $name", (tester) async {
      await _show(
        tester,
        SizedBox(
          width: 300,
          child: GlossRangeSlider(
            values: const GlossRangeValues(15, 45),
            max: 90,
            onChanged: (_) {},
          ),
        ),
        targets: targets,
      );
      final beads = find.byType(RawValueHandle);
      expect(beads, findsNWidgets(2));
      for (final bead in beads.evaluate()) {
        expect(bead.size, Size(side, side));
      }
    });

    testWidgets("a table's header stands $name", (tester) async {
      final table = GlossTableController<String>(
        rows: const ['Soup', 'Salad'],
        columns: const [GlossDataColumn(id: 'dish', label: 'Dish')],
      );
      addTearDown(table.dispose);
      await _show(
        tester,
        SizedBox(
          width: 340,
          height: 240,
          child: GlossDataTable<String>(
            controller: table,
            cell: (row, column) => row,
          ),
        ),
        targets: targets,
      );
      final header = find
          .ancestor(
            of: find.text('Dish'),
            matching: find.byType(ConstrainedBox),
          )
          .first;
      expect(tester.getSize(header).height, side);
    });

    testWidgets("a calendar's days stand $name", (tester) async {
      await _show(
        tester,
        GlossCalendar(
          firstDate: DateTime(2026),
          lastDate: DateTime(2027),
          selectedDate: DateTime(2026, 11, 16),
          onDateChanged: (_) {},
        ),
        targets: targets,
      );
      final day = find
          .ancestor(of: find.text('17'), matching: find.byType(Stack))
          .first;
      expect(tester.getSize(day).height, side);
    });

    testWidgets("a tag stands in a slot of $name, its bead's target too", (
      tester,
    ) async {
      await _show(
        tester,
        SizedBox(
          width: 340,
          child: GlossTagInput<String>(
            values: const ['Rice'],
            onChanged: (_) {},
            onCreate: (text) => text,
          ),
        ),
        targets: targets,
      );
      final tag = find
          .ancestor(of: find.text('Rice'), matching: find.byType(Stack))
          .first;
      expect(tester.getSize(tag).height, side);
      final bead = find.descendant(
        of: tag,
        matching: find.byType(PositionedDirectional),
      );
      expect(tester.getSize(bead.first), Size(side, side));
    });
  }

  testWidgets("under a finger a split view's bead shows at rest", (
    tester,
  ) async {
    await _show(
      tester,
      const SizedBox(
        width: 340,
        height: 300,
        child: GlossSplitView(first: Text('List'), second: Text('Detail')),
      ),
    );
    final bead = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(GlossSplitView),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(bead.opacity, 1);
  });

  testWidgets("under a pointer a split view's bead waits for the pointer", (
    tester,
  ) async {
    await _show(
      tester,
      const SizedBox(
        width: 340,
        height: 300,
        child: GlossSplitView(first: Text('List'), second: Text('Detail')),
      ),
    );
    final bead = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(GlossSplitView),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(bead.opacity, 0);
  }, variant: const TargetPlatformVariant({TargetPlatform.macOS}));

  testWidgets("a tag input's tags lay out in a chip group", (tester) async {
    await _show(
      tester,
      SizedBox(
        width: 340,
        child: GlossTagInput<String>(
          labelText: 'Pantry',
          values: const ['Rice', 'Lentils', 'Oats'],
          onChanged: (_) {},
          onCreate: (text) => text,
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(GlossTagInput<String>),
        matching: find.byType(RawChipGroup),
      ),
      findsOneWidget,
    );
  });

  testWidgets("a breadcrumb's places lay out in a chip group", (tester) async {
    await _show(
      tester,
      width: 1024,
      GlossBreadcrumb(
        crumbs: [
          GlossCrumb('Recipes', onPressed: () {}),
          GlossCrumb('Risotto', onPressed: () {}),
          const GlossCrumb('Lemon risotto'),
        ],
      ),
    );
    expect(
      find.descendant(
        of: find.byType(GlossBreadcrumb),
        matching: find.byType(RawChipGroup),
      ),
      findsOneWidget,
    );
  });
}
