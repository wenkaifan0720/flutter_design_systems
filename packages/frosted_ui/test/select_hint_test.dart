// An open select's list covers the line under its well (coordinator, 11-12: at 1440 the Room select's helper peeked
// past the open list's rounded top-left corner, 2-3 dark pixels of its first letter just outside the curve). With the
// list open, the region round the list's top-left corner reads the same, pixel for pixel, as the same select without
// a helper, by day and by night; the line comes back once the list goes.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

const _stage = ValueKey('stage');
const _width = 1440;
const _height = 480;
const _helper = 'Where the meeting is held';

typedef _Read = Color Function(int x, int y);

double _apart(Color a, Color b) =>
    [(a.r - b.r).abs(), (a.g - b.g).abs(), (a.b - b.b).abs()].reduce(math.max);

Future<_Read> _shot(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_stage),
  );
  final px = (await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      return (await image.toByteData())!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }))!;
  return (int x, int y) {
    final i = (y * _width + x) * 4;
    return Color.fromARGB(px[i + 3], px[i], px[i + 1], px[i + 2]);
  };
}

Widget _app(FrostedThemeData t, {required bool helper}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => FrostedHost(
    light: t,
    dark: t,
    brightness: t.isDark ? Brightness.dark : Brightness.light,
    child: RepaintBoundary(key: _stage, child: page!),
  ),
  home: ColoredBox(
    color: t.colorScheme.background,
    child: Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: SizedBox(
          width: 400,
          child: FrostedSelect<String>(
            label: 'Room',
            helper: helper ? _helper : null,
            onChanged: (_) {},
            options: const [
              FrostedSelectOption('k', 'Kitchen'),
              FrostedSelectOption('s', 'Study'),
              FrostedSelectOption('g', 'Garden', note: 'Outdoors'),
            ],
          ),
        ),
      ),
    ),
  ),
);

/// Opens the select's list and reads the stage, with the list's box.
Future<(_Read, Rect)> _open(
  WidgetTester tester,
  FrostedThemeData t, {
  required bool helper,
}) async {
  // A fresh app each time: no list left open from the read before.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(_app(t, helper: helper));
  await tester.pumpAndSettle();
  // The well, by the words it shows (the prompt).
  await tester.tap(find.text('Select'));
  await tester.pumpAndSettle();
  final list = tester.getRect(find.byType(FrostedMenu<String>));
  return (await _shot(tester), list);
}

void main() {
  setUpAll(frostedLoadFonts);

  for (final brightness in Brightness.values) {
    final day = brightness == Brightness.light ? 'day' : 'night';
    final t = FrostedThemeData.preset(
      FrostedThemeData.presets.first,
      brightness,
    );

    testWidgets('by $day no letter of the helper shows round the open '
        "list's corner", (tester) async {
      tester.view.physicalSize = Size(_width.toDouble(), _height.toDouble());
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final (bare, bareList) = await _open(tester, t, helper: false);
      final (withHelper, list) = await _open(tester, t, helper: true);
      expect(list, bareList, reason: 'the list drops from the well alike');

      // The corner's square, a little past the list's edges.
      final corner = Rect.fromLTWH(
        list.left - 4,
        list.top - 4,
        FrostedChromeMetrics.menuRadius + 12,
        FrostedChromeMetrics.menuRadius + 12,
      );
      final line = tester.getRect(find.text(_helper));
      expect(
        corner.overlaps(line),
        isTrue,
        reason: 'the helper $line stands in the corner $corner',
      );

      final off = <String>[];
      for (var y = corner.top.floor(); y < corner.bottom.ceil(); y++) {
        for (var x = corner.left.floor(); x < corner.right.ceil(); x++) {
          final d = _apart(withHelper(x, y), bare(x, y));
          if (d > 2 / 255) off.add('($x, $y) ${(d * 255).round()}');
        }
      }
      expect(off, isEmpty, reason: 'pixels the helper changes: $off');

      // Shut, the helper is back.
      await tester.tapAt(const Offset(_width - 40, _height - 40));
      await tester.pumpAndSettle();
      expect(find.byType(FrostedMenu<String>), findsNothing);
      final shown = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.text(_helper),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(shown.opacity, 1);
    }, tags: const ['goldens']);
  }
}
