// A calendar's chosen day and a span's ends meet the rules round them with
// no seam of the page between, on a phone's fractional pixel ratio, by day
// and by night: under a finger the days stood 44 inside 48 targets, at 2.625
// a white pixel showed beside the chosen day's ink, and where a column fell
// on a fraction of a pixel a grey line ran down each side of the chosen day.
import 'dart:ui' as ui;

import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _table = ValueKey('table');

// The pixels near the edges of the [days]' cells that stand alone between
// the solid [tone] (a chosen day's fill and its rules) and are not that tone,
// along rows and columns.
Future<List<String>> _seams(
  WidgetTester tester,
  double ratio,
  double tone,
  List<String> days,
) async {
  final origin = tester.getTopLeft(find.byKey(_table));
  // Each day's cell inside its rules, in the image's pixels.
  final cells = [
    for (final day in days)
      () {
        final r = tester
            .getRect(
              find
                  .ancestor(
                    of: find.text(day),
                    matching: find.byType(CustomPaint),
                  )
                  .first,
            )
            .shift(-origin);
        return Rect.fromLTRB(
          r.left * ratio,
          r.top * ratio,
          r.right * ratio,
          r.bottom * ratio,
        );
      }(),
  ];
  // From a few pixels inside a cell to a few past the rules round it.
  final reach = BrutalThemeData.light().borderWidth * ratio + 3;
  bool near(int x, int y) {
    final p = Offset(x + .5, y + .5);
    return cells.any(
      (r) => r.inflate(reach).contains(p) && !r.deflate(3).contains(p),
    );
  }

  final boundary =
      tester.renderObject(find.byKey(_table)) as RenderRepaintBoundary;
  final image = (await tester.runAsync(
    () => boundary.toImage(pixelRatio: ratio),
  ))!;
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final (w, h) = (image.width, image.height);
  image.dispose();
  double light(int x, int y) {
    final i = (y * w + x) * 4;
    if (bytes.getUint8(i + 3) < 128) return 1;
    return (bytes.getUint8(i) + bytes.getUint8(i + 1) + bytes.getUint8(i + 2)) /
        765;
  }

  bool solid(int x, int y) => (light(x, y) - tone).abs() < .06;
  bool off(int x, int y) => (light(x, y) - tone).abs() > .12;
  final seams = <String>[];
  for (var y = 0; y < h; y++) {
    for (var x = 2; x < w - 2; x++) {
      if (near(x, y) &&
          off(x, y) &&
          solid(x - 2, y) &&
          solid(x - 1, y) &&
          solid(x + 1, y) &&
          solid(x + 2, y)) {
        seams.add('($x, $y)');
      }
    }
  }
  for (var x = 0; x < w; x++) {
    for (var y = 2; y < h - 2; y++) {
      if (near(x, y) &&
          off(x, y) &&
          solid(x, y - 2) &&
          solid(x, y - 1) &&
          solid(x, y + 1) &&
          solid(x, y + 2)) {
        seams.add('($x, $y)');
      }
    }
  }
  return seams;
}

void main() {
  // Today away from the chosen days, so its heavy figures stay out of reach.
  final today = DateTime(2026, 11, 2);
  final calendars = <String, (List<String>, Widget Function())>{
    'a chosen day': (
      ['18'],
      () => BrutalCalendar(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        currentDate: today,
        selectedDate: DateTime(2026, 11, 18),
        onDateChanged: (_) {},
      ),
    ),
    "a span's ends": (
      ['10', '19'],
      () => BrutalCalendar.range(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        currentDate: today,
        selectedRange: BrutalDateRange(
          start: DateTime(2026, 11, 10),
          end: DateTime(2026, 11, 19),
        ),
        onRangeChanged: (_) {},
      ),
    ),
  };
  final themes = {
    'day': BrutalThemeData.light(),
    'night': BrutalThemeData.dark(),
  };
  for (final MapEntry(key: name, value: (days, calendar))
      in calendars.entries) {
    for (final MapEntry(key: time, value: theme) in themes.entries) {
      for (final (width, ratio) in [
        (333.7, 2.625),
        (357.3, 2.625),
        (358.0, 2.0),
      ]) {
        for (final direction in TextDirection.values) {
          testWidgets('$name by $time at $width x $ratio, ${direction.name}: '
              'no seam', (tester) async {
            tester.view.physicalSize = Size(400 * ratio, 900 * ratio);
            tester.view.devicePixelRatio = ratio;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              WidgetsApp(
                color: const Color(0xFF000000),
                builder: (context, _) => Directionality(
                  textDirection: direction,
                  child: BrutalTheme(
                    data: theme,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10.3, 10.6, 0, 0),
                        child: RepaintBoundary(
                          key: _table,
                          child: ColoredBox(
                            color: theme.colors.paper,
                            child: SizedBox(width: width, child: calendar()),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            // The chosen day's tone, its rules': the theme's ink.
            final ink = theme.colors.ink;
            final tone = (ink.r + ink.g + ink.b) / 3;
            expect(await _seams(tester, ratio, tone, days), isEmpty);
          }, variant: TargetPlatformVariant.only(TargetPlatform.android));
        }
      }
    }
  }
}
