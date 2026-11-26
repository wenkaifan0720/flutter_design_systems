// Expressive's touch floor is ui_core's, 40 by 40, for a finger and a
// pointer alike (it was Compose's 48): a chip, a checkbox, an icon button
// and a segmented button's segment stand at it, and an app's
// RawTapTargetScope under the theme raises it. A chip row's chips, input
// chips with them, and a multi-select's tags lay out in RawChipGroup: their
// faces stand 8dp apart along a line and from line to line, the targets
// taking the room between them.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

const _floor56 = RawTapTargets(
  touch: Size.square(56),
  pointer: Size.square(56),
);

Future<void> _show(
  WidgetTester tester,
  Widget part, {
  RawTapTargets? targets,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // Expressive's theme declares the look's floors; an app raises them under
  // it, round its pages.
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => ExpressiveHost(
        theme: ExpressiveThemeData.baseline(),
        brightness: Brightness.light,
        child: app!,
      ),
      home: Builder(
        builder: (context) {
          final body = Align(
            alignment: Alignment.topCenter,
            child: Padding(padding: const EdgeInsets.all(16), child: part),
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

/// The drawn face of the chip that shows [label].
Rect _face(WidgetTester tester, String label) => tester.getRect(
  find
      .descendant(
        of: find
            .ancestor(
              of: find.text(label),
              matching: find.byType(ExpressiveChip),
            )
            .first,
        matching: find.byType(ExpressiveSurface),
      )
      .first,
);

/// Expects the faces of the chips showing [labels] 8dp apart along each
/// line and from one line to the next, on more than one line.
void _eightApart(WidgetTester tester, List<String> labels) {
  final lines = <double, List<Rect>>{};
  for (final label in labels) {
    final face = _face(tester, label);
    lines.putIfAbsent(face.top, () => []).add(face);
  }
  final tops = lines.keys.toList()..sort();
  expect(tops.length, greaterThan(1), reason: 'the chips fill one line');
  for (final (i, top) in tops.indexed) {
    final line = lines[top]!..sort((a, b) => a.left.compareTo(b.left));
    for (var j = 1; j < line.length; j++) {
      expect(
        line[j].left - line[j - 1].right,
        closeTo(8, .01),
        reason: 'line $i',
      );
    }
    if (i > 0) {
      expect(
        top - lines[tops[i - 1]]!.first.bottom,
        closeTo(8, .01),
        reason: 'line $i',
      );
    }
  }
}

void main() {
  const words = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Vegetarian',
    'Vegan',
    'Gluten free',
    'Spicy',
    'Quick',
  ];

  testWidgets(
    "the theme's floor is ui_core's, 40 by 40, on every input",
    (tester) async {
      late BuildContext inside;
      await _show(
        tester,
        Builder(
          builder: (context) {
            inside = context;
            return const SizedBox.square(dimension: 10);
          },
        ),
      );
      expect(RawTapTargets.of(inside).floorOn(), RawTapTargets.fallback.touch);
      expect(
        ExpressiveMinimumInteractiveSize.floorAt(inside),
        const Size(40, 40),
      );
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.macOS,
    }),
  );

  for (final (name, targets, side) in [
    ('the touch floor', null, 40.0),
    ("an app's floor of 56", _floor56, 56.0),
  ]) {
    testWidgets(
      'a chip, a checkbox, an icon button and a segment stand at $name',
      (tester) async {
        await _show(
          tester,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExpressiveChip.assist('Share', onPressed: () {}),
              ExpressiveCheckbox(value: true, onChanged: (_) {}),
              ExpressiveIconButton(
                ExpressiveSymbols.edit,
                semanticLabel: 'Edit',
                onPressed: () {},
              ),
              ExpressiveSegmentedButton<int>(
                expand: false,
                segments: const [
                  ExpressiveButtonSegment(0, 'Day'),
                  ExpressiveButtonSegment(1, 'Week'),
                ],
                value: 0,
                onChanged: (_) {},
              ),
            ],
          ),
          targets: targets,
        );
        expect(tester.getSize(find.byType(ExpressiveChip)).height, side);
        expect(
          tester.getSize(find.byType(ExpressiveCheckbox)),
          Size(side, side),
        );
        expect(
          tester.getSize(find.byType(ExpressiveIconButton)),
          Size(side, side),
        );
        expect(
          tester
              .getSize(find.widgetWithText(ExpressiveToggleButton, 'Day'))
              .height,
          side,
        );
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.macOS,
      }),
    );
  }

  testWidgets("a chip row's chips stand 8dp apart, line to line too", (
    tester,
  ) async {
    await _show(
      tester,
      ExpressiveChipRow(
        children: [
          for (final w in words)
            ExpressiveChip.filter(w, selected: w == 'Lunch', onPressed: () {}),
        ],
      ),
    );
    expect(find.byType(RawChipGroup), findsOneWidget);
    _eightApart(tester, words);
  });

  testWidgets('input chips, their remove targets with them, stand 8dp apart', (
    tester,
  ) async {
    await _show(
      tester,
      ExpressiveChipRow(
        children: [
          for (final w in words) ExpressiveChip.input(w, onDeleted: () {}),
        ],
      ),
    );
    _eightApart(tester, words);
  });

  testWidgets("a multi-select's tags stand 8dp apart, line to line too", (
    tester,
  ) async {
    final tags = words.take(7).toList();
    await _show(
      tester,
      SizedBox(
        width: 358,
        child: ExpressiveMultiSelect<String>(
          labelText: 'Tags',
          options: [for (final w in words) ExpressiveSelectOption(w, w)],
          values: tags,
          onChanged: (_) {},
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(ExpressiveMultiSelect<String>),
        matching: find.byType(RawChipGroup),
      ),
      findsOneWidget,
    );
    _eightApart(tester, tags);
  });
}
