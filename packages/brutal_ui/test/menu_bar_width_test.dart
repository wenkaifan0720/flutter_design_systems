// A menu bar spans the width it is given, its menus from the start, as a
// desk app's bar spans its window, and a rule closes each menu, the last
// one's never doubled by the bar's own end rule: it hugged its menus, and
// the last menu's rule stood against the bar's end rule.
import 'dart:ui' as ui;

import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _bar = ValueKey('bar');

Future<void> _pump(
  WidgetTester tester, {
  required Brightness brightness,
  required TextDirection direction,
  required bool loose,
}) async {
  tester.view.physicalSize = const Size(600, 300);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final bar = BrutalMenuBar(
    menus: [
      BrutalMenuBarMenu('Edit', [
        BrutalMenuItem(label: 'Undo', onPressed: () {}),
      ]),
    ],
  );
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      builder: (context, _) => Directionality(
        textDirection: direction,
        child: BrutalTheme(
          data: brightness == Brightness.light
              ? BrutalThemeData.light()
              : BrutalThemeData.dark(),
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: RepaintBoundary(
                key: _bar,
                // In a box that leaves its width to it (a docs page's
                // centred column), or in a row that gives it no width.
                child: loose
                    ? SizedBox(
                        width: 460,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: bar,
                        ),
                      )
                    : Row(mainAxisSize: MainAxisSize.min, children: [bar]),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// The ink runs along a row of the bar just under its top rule (above its
// words), start to end, as (from, to) pairs of whole pixels: the rules that
// stand across the bar.
Future<List<(int, int)>> _inkRuns(WidgetTester tester, Color ink) async {
  final boundary =
      tester.renderObject(find.byKey(_bar)) as RenderRepaintBoundary;
  final width = boundary.size.width.round();
  final bar = tester.getRect(find.byType(BrutalMenuBar));
  final y = (bar.top - tester.getTopLeft(find.byKey(_bar)).dy + 4).round();
  final bytes = (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!;
  }))!;
  bool isInk(int x) {
    final i = (y * width + x) * 4;
    return (bytes.getUint8(i) - (ink.r * 255).round()).abs() < 24 &&
        (bytes.getUint8(i + 1) - (ink.g * 255).round()).abs() < 24 &&
        (bytes.getUint8(i + 2) - (ink.b * 255).round()).abs() < 24 &&
        bytes.getUint8(i + 3) > 200;
  }

  final runs = <(int, int)>[];
  int? from;
  for (var x = 0; x <= width; x++) {
    final on = x < width && isInk(x);
    if (on && from == null) from = x;
    if (!on && from != null) {
      runs.add((from, x));
      from = null;
    }
  }
  return runs;
}

void main() {
  for (final brightness in Brightness.values) {
    for (final direction in TextDirection.values) {
      final ink =
          (brightness == Brightness.light
                  ? BrutalThemeData.light()
                  : BrutalThemeData.dark())
              .colors
              .ink;
      testWidgets('given 460 (${brightness.name}, ${direction.name}): the bar '
          'is 460 wide and the menu closes on one rule', (tester) async {
        await _pump(
          tester,
          brightness: brightness,
          direction: direction,
          loose: true,
        );
        final bar = tester.getRect(find.byType(BrutalMenuBar));
        expect(bar.width, 460);
        final runs = await _inkRuns(tester, ink);
        final w = BrutalThemeData.light().borderWidth.round();
        // The bar's start rule, the menu's closing rule, the bar's end rule,
        // each one rule wide.
        expect(runs, hasLength(3), reason: '$runs');
        expect(runs.first.$1, 0, reason: '$runs');
        expect(runs.last.$2, 460, reason: '$runs');
        for (final (from, to) in runs) {
          expect(to - from, w, reason: 'one rule, not doubled: $runs');
        }
      });

      testWidgets('given no width (${brightness.name}, ${direction.name}): it '
          'hugs its menus, closed by its own end rule alone', (tester) async {
        await _pump(
          tester,
          brightness: brightness,
          direction: direction,
          loose: false,
        );
        final runs = await _inkRuns(tester, ink);
        final w = BrutalThemeData.light().borderWidth.round();
        // The bar's start and end rules alone, each one rule wide.
        expect(runs, hasLength(2), reason: '$runs');
        for (final (from, to) in runs) {
          expect(to - from, w, reason: 'one rule, not doubled: $runs');
        }
      });
    }
  }
}
