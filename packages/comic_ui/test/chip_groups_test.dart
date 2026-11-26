// A run of Comic's chips stands its faces their gap apart face to face, run under run too, their targets reaching into
// the room between (ui_core's RawChipGroup): a group of choices on a wide screen 8 apart, and under a floor its tiles
// outgrow, two neighbours' targets meet and the tiles stand only as far apart as the targets need (in a Wrap each
// target's slack stood between the tiles on top of the gap). A multi-select's chosen tags, no targets of their own, stand
// 8 apart under any floor.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart' show loadComicFonts;

Future<void> _pump(
  WidgetTester tester,
  Widget part, {
  required double floor,
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFFFF3E92),
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, animation, secondary) => builder(context),
      ),
      builder: (context, navigator) => RawTapTargetScope(
        targets: RawTapTargets(
          touch: Size.square(floor),
          pointer: Size.square(floor),
        ),
        child: ComicTheme(data: ComicThemeData.offset(), child: navigator!),
      ),
      home: Align(
        alignment: Alignment.topLeft,
        child: Padding(padding: const EdgeInsets.all(16), child: part),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The faces round [words], by the nearest decorated box round each, grouped into runs by their tops.
Map<double, List<Rect>> _runs(WidgetTester tester, List<String> words) {
  final runs = <double, List<Rect>>{};
  for (final w in words) {
    final face = tester.getRect(
      find
          .ancestor(of: find.text(w), matching: find.byType(DecoratedBox))
          .first,
    );
    (runs[face.top.roundToDouble()] ??= []).add(face);
  }
  for (final run in runs.values) {
    run.sort((a, b) => a.left.compareTo(b.left));
  }
  return runs;
}

void _expectGaps(
  Map<double, List<Rect>> runs, {
  required double gap,
  required double floor,
  required String what,
}) {
  expect(runs.length, greaterThan(1), reason: '$what: the run wraps');
  for (final run in runs.values) {
    for (var i = 1; i < run.length; i++) {
      final need = math.max(gap, floor - (run[i].width + run[i - 1].width) / 2);
      expect(
        run[i].left - run[i - 1].right,
        moreOrLessEquals(math.max(gap, need), epsilon: .5),
        reason: '$what at $floor: face to face',
      );
    }
  }
  final tops = runs.keys.toList()..sort();
  for (var i = 1; i < tops.length; i++) {
    final above = runs[tops[i - 1]]!.first, below = runs[tops[i]]!.first;
    final need = floor - (above.height + below.height) / 2;
    expect(
      below.top - above.bottom,
      moreOrLessEquals(math.max(gap, need), epsilon: .5),
      reason: '$what at $floor: run under run',
    );
  }
}

const _rooms = ['Kitchen', 'Study', 'Bedroom', 'Garden', 'Hall', 'Loft'];

void main() {
  setUpAll(loadComicFonts);

  testWidgets(
    "a multi-select's chosen tags stand 8 apart, run under run too, under any floor",
    (tester) async {
      for (final floor in const [40.0, 64.0]) {
        await _pump(
          tester,
          SizedBox(
            width: 260,
            child: ComicMultiSelect(
              labelText: 'Rooms',
              values: _rooms,
              options: _rooms,
              onChanged: (_) {},
            ),
          ),
          floor: floor,
        );
        // A chosen tag is no target of its own (Backspace and the list take it away): no floor reaches between.
        _expectGaps(
          _runs(tester, _rooms),
          gap: ComicSpace.close,
          floor: 0,
          what: 'tags under $floor',
        );
      }
    },
  );

  testWidgets(
    'a wide group of choices stands its tiles 8 apart, and they meet under a raised floor',
    (tester) async {
      const sizes = [
        'Pocket',
        'Digest',
        'Comic book',
        'Tabloid',
        'Treasury',
        'Graphic novel',
        'Broadsheet',
      ];
      for (final floor in const [40.0, 96.0]) {
        await _pump(
          tester,
          SizedBox(
            width: 640,
            child: ComicChoices(
              options: [for (final s in sizes) ComicChoice(s)],
              value: 'Digest',
              onChanged: (_) {},
            ),
          ),
          floor: floor,
          width: 1024,
        );
        _expectGaps(
          _runs(tester, sizes),
          gap: ComicSpace.close,
          floor: floor,
          what: 'choices',
        );
      }
    },
  );
}
