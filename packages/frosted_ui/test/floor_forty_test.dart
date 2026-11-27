// The finger floor is ui_core's, 40 by 40 (WCAG 2.2's target size minimum), under a finger and a pointer alike;
// Frosted's own 48 (a finger) and 44 (a pointer) are gone. Chips in a group stand their spacing apart face to face, their
// targets reaching into the room between (ui_core's RawChipGroup): in a Wrap each target's slack stood between the faces
// too, so two runs of choices stood 8 and the slack apart and read as two groups.
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';

import 'touch_floor.dart';

Future<BuildContext> _pump(WidgetTester t, Widget part) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  late BuildContext page;
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          FrostedHost(brightness: Brightness.light, child: child!),
      home: Builder(
        builder: (context) {
          page = context;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Align(alignment: Alignment.topLeft, child: part),
          );
        },
      ),
    ),
  );
  await t.pumpAndSettle();
  return page;
}

Rect _rectOf(Element e) {
  final box = e.renderObject! as RenderBox;
  return MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  );
}

const _rooms = [
  FrostedSelectOption('k', 'Kitchen'),
  FrostedSelectOption('s', 'Study'),
  FrostedSelectOption('b', 'Bedroom'),
  FrostedSelectOption('g', 'Garden'),
  FrostedSelectOption('h', 'Hall'),
  FrostedSelectOption('l', 'Loft'),
];

void main() {
  for (final platform in [
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.macOS,
    TargetPlatform.windows,
  ]) {
    testWidgets('the floor is 40 on ${platform.name}', (t) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        final page = await _pump(t, const SizedBox());
        expect(FrostedBreakpoints.hitTargetOf(page), 40);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  testWidgets('choices stand 8 apart face to face, along a run and run '
      'under run, each in a target of the floor', (t) async {
    await _pump(
      t,
      SizedBox(
        width: 220,
        child: FrostedChoices<String>(
          options: _rooms,
          value: 'k',
          onChanged: (_) {},
        ),
      ),
    );
    // Each chip's face: the outermost face under it.
    final faces = [
      for (final chip in find.byType(FrostedChip).evaluate())
        _rectOf(
          find
              .descendant(
                of: find.byWidget(chip.widget),
                matching: find.byType(FrostedFace),
              )
              .evaluate()
              .first,
        ),
    ];
    expect(faces.length, _rooms.length);
    final runs = <double, List<Rect>>{};
    for (final f in faces) {
      (runs[f.top] ??= []).add(f);
    }
    expect(runs.length, greaterThan(1), reason: 'the chips wrap');
    final tops = runs.keys.toList()..sort();
    for (final run in runs.values) {
      run.sort((a, b) => a.left.compareTo(b.left));
      for (var i = 1; i < run.length; i++) {
        expect(run[i].left - run[i - 1].right, moreOrLessEquals(8));
      }
    }
    for (var i = 1; i < tops.length; i++) {
      expect(tops[i] - runs[tops[i - 1]]!.first.bottom, moreOrLessEquals(8));
    }
    await expectLater(t, meetsGuideline(touchFloorGuideline));
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.macOS]) {
    testWidgets('a breadcrumb wrapped onto three lines steps evenly, the page '
        "standing as tall as the links' targets (${platform.name})", (t) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        await _pump(
          t,
          SizedBox(
            width: 200,
            child: FrostedBreadcrumb(
              items: [
                FrostedBreadcrumbItem('Home', onPressed: () {}),
                FrostedBreadcrumbItem('Cards', onPressed: () {}),
                FrostedBreadcrumbItem('Statements', onPressed: () {}),
                const FrostedBreadcrumbItem('Everyday'),
              ],
            ),
          ),
        );
        final tops = {
          for (final word in ['Home', 'Cards', 'Statements', 'Everyday'])
            t.getRect(find.text(word)).top.roundToDouble(),
        }.toList()..sort();
        expect(tops, hasLength(3), reason: 'the trail wraps onto three lines');
        expect(
          tops[2] - tops[1],
          moreOrLessEquals(tops[1] - tops[0], epsilon: 1),
        );
        await expectLater(t, meetsGuideline(touchFloorGuideline));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}
