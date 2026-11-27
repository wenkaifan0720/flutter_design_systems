// The floor is ui_core's, 40 by 40 (WCAG 2.2's target size minimum), under a finger and a pointer alike; Fluent 2's
// own 48 (a finger) and 44 (a pointer's rows) are gone. Tags in a group stand the group's gap apart face to face, their
// targets reaching into the room between (ui_core's RawChipGroup): in a Wrap each target's slack stood between the
// runs too, so two runs of tags stood the gap and the slack apart.
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

Future<BuildContext> _pump(WidgetTester t, Widget part) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  late BuildContext page;
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Fluent2Host(child: child!),
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

const _rooms = ['Kitchen', 'Study', 'Bedroom', 'Garden', 'Hall', 'Loft'];

/// The finger floor, ui_core's 40.
final _floor = RawTapTargets.fallback.touch.height;

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
        expect(Fluent2Layout.hitTargetOf(page), _floor);
        expect(_floor, 40);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  testWidgets("a tag group's runs stand the group's gap apart face to face "
      'under a finger, as its tags do along a run', (t) async {
    await _pump(
      t,
      SizedBox(
        width: 220,
        child: Fluent2TagGroup<String>(
          items: [for (final r in _rooms) Fluent2TagItem(r, r)],
          selected: const {'Kitchen'},
          onSelectionChanged: (_) {},
        ),
      ),
    );
    // Each tag's face: the first painted box under it.
    final faces = [
      for (final r in _rooms)
        _rectOf(
          find
              .descendant(
                of: find.byKey(ValueKey<String>(r)),
                matching: find.byType(DecoratedBox),
              )
              .evaluate()
              .first,
        ),
    ];
    final runs = <double, List<Rect>>{};
    for (final f in faces) {
      (runs[f.top.roundToDouble()] ??= []).add(f);
    }
    expect(runs.length, greaterThan(1), reason: 'the tags wrap');
    final gap = Fluent2TagSize.medium.groupGap;
    for (final run in runs.values) {
      run.sort((a, b) => a.left.compareTo(b.left));
      for (var i = 1; i < run.length; i++) {
        expect(run[i].left - run[i - 1].right, moreOrLessEquals(gap));
      }
    }
    final tops = runs.keys.toList()..sort();
    final face = faces.first.height;
    for (var i = 1; i < tops.length; i++) {
      expect(
        tops[i] - runs[tops[i - 1]]!.first.bottom,
        moreOrLessEquals(gap > _floor - face ? gap : _floor - face),
        reason:
            'run under run, the faces stand the gap apart unless the '
            'targets need more',
      );
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets("a tag picker's runs of tags stand as close as their targets "
      'let them under a finger, the targets meeting', (t) async {
    await _pump(
      t,
      SizedBox(
        width: 240,
        child: Fluent2MultiSelect<String>(
          semanticLabel: 'Rooms',
          options: [for (final r in _rooms) Fluent2Option(r, r)],
          selected: _rooms,
          onChanged: (_) {},
        ),
      ),
    );
    // Each tag's face: the nearest painted box round its words.
    final faces = [
      for (final r in _rooms)
        _rectOf(
          find
              .ancestor(of: find.text(r), matching: find.byType(DecoratedBox))
              .evaluate()
              .first,
        ),
    ];
    final runs = <double, List<Rect>>{};
    for (final f in faces) {
      (runs[f.top.roundToDouble()] ??= []).add(f);
    }
    expect(runs.length, greaterThan(1), reason: 'the tags wrap');
    final tops = runs.keys.toList()..sort();
    final face = faces.first.height;
    // A medium picker's tags stand Fluent's xs (4) apart.
    expect(face, lessThan(_floor - Fluent2Spacing.xs));
    for (var i = 1; i < tops.length; i++) {
      expect(
        tops[i] - runs[tops[i - 1]]!.first.bottom,
        moreOrLessEquals(_floor - face, epsilon: 0.5),
        reason: 'run under run, the targets meet: no gap beside their slack',
      );
    }
    for (final run in runs.values) {
      run.sort((a, b) => a.left.compareTo(b.left));
      for (var i = 1; i < run.length; i++) {
        expect(
          run[i].left - run[i - 1].right,
          moreOrLessEquals(Fluent2Spacing.xs, epsilon: 0.5),
        );
      }
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
