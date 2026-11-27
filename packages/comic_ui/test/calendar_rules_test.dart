// A calendar's days meet on one rule: each resting day draws its top and its start, and its end or its foot where no
// day of the month follows there. Each drew its whole outline, two rules deep where two days met; then each cut its
// end and foot a pixel deep, and its own top and start with them, so every crossing broke; then each ran a pixel on
// under the next day's rule, and the faint rules stood a darker dot deep at every crossing.
import 'dart:ui' as ui;

import 'package:comic_ui/comic_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

const _root = Key('root');

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required Widget home,
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
}) async {
  await tester.runAsync(comicLoadFonts);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => RepaintBoundary(
        key: _root,
        child: Directionality(
          textDirection: direction,
          child: ComicHost(
            light: ComicThemeData.offset(),
            dark: ComicThemeData.offset(Brightness.dark),
            brightness: brightness,
            child: child!,
          ),
        ),
      ),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final b in Brightness.values) {
    for (final direction in TextDirection.values) {
      testWidgets("a calendar's rules are one weight, inside and out "
          '(${b.name}, ${direction.name})', (tester) async {
        final days = RawCalendarController(
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          initialMonth: DateTime(2026, 11),
        );
        addTearDown(days.dispose);
        await _pump(
          tester,
          size: const Size(390, 844),
          brightness: b,
          direction: direction,
          home: Builder(
            builder: (context) => ColoredBox(
              color: ComicTheme.of(context).colors.background,
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 336,
                  child: ComicCalendar(controller: days, onChanged: (_) {}),
                ),
              ),
            ),
          ),
        );
        // The week of the 2nd to the 8th, just under its top rule: across it, every rule it meets.
        Rect day(String n) => tester.getRect(
          find
              .ancestor(of: find.text(n), matching: find.byType(DecoratedBox))
              .first,
        );
        final a = day('2'), z = day('8');
        final left = a.left < z.left ? a.left : z.left;
        final right = a.right > z.right ? a.right : z.right;
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(_root),
        );
        final image = (await tester.runAsync(() => boundary.toImage()))!;
        final bytes = (await tester.runAsync(
          () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
        ))!;
        int at(int x, int y) => bytes.getUint32((y * image.width + x) * 4);
        final y = (a.top + 6).round();
        final ground = at(a.center.dx.round(), y);
        final runs = <int>[];
        final tones = <int>{};
        var run = 0;
        for (var x = (left - 3).round(); x <= (right + 3).round(); x++) {
          if (at(x, y) != ground) {
            tones.add(at(x, y));
            run++;
          } else if (run > 0) {
            runs.add(run);
            run = 0;
          }
        }
        if (run > 0) runs.add(run);
        // Where the rules round the 3rd, the 4th and the 10th cross: the 3rd's top runs to its end and its start to its
        // foot, each meeting the next day's rule.
        final third = day('3');
        final rtl = direction == TextDirection.rtl;
        final startX = (rtl ? third.right - 1 : third.left).round();
        final endX = (rtl ? third.left : third.right - 1).round();
        final crossing = {
          'start at its foot': at(startX, (third.bottom - 1).round()),
          'top at its end': at(endX, third.top.round()),
        };
        final paper = at(third.center.dx.round(), (third.top + 6).round());
        // Under the 3rd's end, where the rules round the 3rd, the 4th, the 10th and the 11th cross.
        final under = at(
          (rtl ? third.left - 1 : third.right).round(),
          third.bottom.round(),
        );
        image.dispose();
        expect(
          runs,
          hasLength(8),
          reason: 'eight rules across seven days: $runs',
        );
        expect(runs.toSet(), hasLength(1), reason: 'one weight: $runs');
        expect(tones, hasLength(1), reason: 'one tone: $tones');
        expect(under, tones.first, reason: 'the crossing is one rule deep');
        for (final MapEntry(key: where, value: pixel) in crossing.entries) {
          expect(pixel, isNot(paper), reason: "the 3rd's $where");
        }
      });
    }
  }
}
