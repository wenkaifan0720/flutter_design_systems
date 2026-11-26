// The floor is ui_core's, 40 by 40 (WCAG 2.2's target size minimum) for a
// finger and 24 for a pointer; Civic's own 48 for a finger is gone, and a
// theme may raise the floors, never lower them. The chosen answers of a
// multi-select stand 8 apart face to face, run under run too, their targets
// reaching into the room between (ui_core's RawChipGroup): in a Wrap each
// target's slack stood between the runs as well.
import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<void> _pump(
  WidgetTester tester,
  Widget part, {
  RawTapTargets targets = RawTapTargets.fallback,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, navigator) => CivicTheme(
        data: CivicThemeData.light().copyWith(tapTargets: targets),
        child: navigator!,
      ),
      home: Align(
        alignment: Alignment.topLeft,
        child: Padding(padding: const EdgeInsets.all(16), child: part),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _rooms = ['Kitchen', 'Study', 'Bedroom', 'Garden', 'Hall', 'Loft'];

void main() {
  test("Civic's floors are ui_core's", () {
    expect(CivicThemeData.light().tapTargets, RawTapTargets.fallback);
    expect(CivicThemeData.dark().tapTargets, RawTapTargets.fallback);
    expect(RawTapTargets.fallback.touch, const Size.square(40));
    expect(CivicThemeData.floorsHold(RawTapTargets.fallback), isTrue);
    expect(
      CivicThemeData.floorsHold(const RawTapTargets(touch: Size.square(39))),
      isFalse,
    );
  });

  testWidgets('under a finger the targets stand on 40', (tester) async {
    late BuildContext page;
    await _pump(
      tester,
      Builder(
        builder: (context) {
          page = context;
          return const SizedBox();
        },
      ),
    );
    expect(RawTapTargets.of(page).floorOn().height, 40);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets("a multi-select's chosen answers stand 8 apart face to face, "
      'run under run too, under a finger; under a raised floor their '
      'targets meet', (tester) async {
    // At 40 an answer's face fills its target; at 64 each target reaches
    // 12 past its 40 face either side, so faces stand 24 apart (targets
    // meeting), where a Wrap would stand the targets 8 apart again (32).
    for (final (floor, runGap) in const [(40.0, 8.0), (64.0, 24.0)]) {
      await _pump(
        tester,
        SizedBox(
          width: 260,
          child: CivicMultiSelect<String>(
            labelText: 'Rooms',
            values: _rooms,
            options: _rooms,
            onChanged: (_) {},
          ),
        ),
        targets: RawTapTargets(touch: Size.square(floor)),
      );
      // Each answer's face: the nearest painted box round its words.
      final faces = [
        for (final r in _rooms)
          tester.getRect(
            find
                .ancestor(of: find.text(r), matching: find.byType(CustomPaint))
                .first,
          ),
      ];
      final runs = <double, List<Rect>>{};
      for (final f in faces) {
        (runs[f.top.roundToDouble()] ??= []).add(f);
      }
      expect(runs.length, greaterThan(1), reason: 'the answers wrap');
      for (final run in runs.values) {
        run.sort((a, b) => a.left.compareTo(b.left));
        for (var i = 1; i < run.length; i++) {
          expect(run[i].left - run[i - 1].right, moreOrLessEquals(8));
        }
      }
      final tops = runs.keys.toList()..sort();
      for (var i = 1; i < tops.length; i++) {
        expect(
          tops[i] - runs[tops[i - 1]]!.first.bottom,
          moreOrLessEquals(runGap),
          reason: 'floor $floor: run under run',
        );
      }
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets("a toggle group's segments stand on the floor in force, "
      'a raised one too', (tester) async {
    // A segment's face (48 tall, 50 wide at the least) stands over the
    // finger's 40 already; a raised floor pads round it.
    for (final floor in const [40.0, 64.0]) {
      await _pump(
        tester,
        CivicToggleGroup<String>(
          segments: const [
            CivicSegment(value: 's', label: 'S'),
            CivicSegment(value: 'i', label: 'I'),
          ],
          selected: const {'s'},
          onSelectionChanged: (_) {},
        ),
        targets: RawTapTargets(touch: Size.square(floor)),
      );
      for (final label in const ['S', 'I']) {
        final target = tester.getSize(
          find
              .ancestor(of: find.text(label), matching: find.byType(Semantics))
              .first,
        );
        expect(target.width, greaterThanOrEqualTo(floor), reason: label);
        expect(target.height, greaterThanOrEqualTo(floor), reason: label);
      }
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
