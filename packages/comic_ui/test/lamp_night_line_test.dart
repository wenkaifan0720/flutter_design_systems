// A lamp (a chosen day, a wheel's chosen row) keeps its ink contour on its yellow, and at night the night line round
// it, so its edge reads on the night page as well: the ink alone was lost against the page by night.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:comic_ui/comic_host.dart';
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

double _luminance(Color c) {
  double channel(double v) =>
      v <= .03928 ? v / 12.92 : math.pow((v + .055) / 1.055, 2.4).toDouble();
  return .2126 * channel(c.r) + .7152 * channel(c.g) + .0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final x = _luminance(a), y = _luminance(b);
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

void main() {
  for (final b in Brightness.values) {
    for (final (name, part) in <(String, Widget)>[
      (
        'date picker',
        ComicDatePicker(
          value: DateTime(2026, 11, 20),
          currentDate: DateTime(2026, 11, 22),
          onChanged: (_) {},
        ),
      ),
      (
        'range picker',
        ComicDateRangePicker(
          firstDate: DateTime(2026),
          lastDate: DateTime(2027),
          value: RawDateRange(DateTime(2026, 11, 9), DateTime(2026, 11, 13)),
          currentDate: DateTime(2026, 11, 22),
          onChanged: (_) {},
        ),
      ),
      (
        'wheel picker',
        ComicWheelPicker<int>(
          label: 'Hour',
          values: const [6, 7, 8, 9, 10, 11, 12],
          value: 9,
          labelOf: (hour) => '$hour',
          onChanged: (_) {},
        ),
      ),
    ]) {
      testWidgets(
        "a $name's lamp edge reads on the ground round it (${b.name})",
        (tester) async {
          await _pump(
            tester,
            size: const Size(390, 844),
            brightness: b,
            home: Builder(
              builder: (context) => ColoredBox(
                color: ComicTheme.of(context).colors.background,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Align(alignment: Alignment.topCenter, child: part),
                ),
              ),
            ),
          );
          final t = ComicTheme.of(tester.element(find.byWidget(part)));
          final lamps = [
            for (final e in find.byType(DecoratedBox).evaluate())
              if ((e.widget as DecoratedBox).decoration
                  case ShapeDecoration(:final color)
                  when color == t.colors.caption)
                (e.renderObject! as RenderBox),
          ];
          expect(lamps, isNotEmpty);
          // The page three device pixels a logical one, so a hairline is whole pixels.
          const ratio = 3.0;
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(_root),
          );
          final image = (await tester.runAsync(
            () => boundary.toImage(pixelRatio: ratio),
          ))!;
          final bytes = (await tester.runAsync(
            () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
          ))!;
          Color at(int x, int y) {
            final i = (y * image.width + x) * 4;
            return Color.fromARGB(
              255,
              bytes.getUint8(i),
              bytes.getUint8(i + 1),
              bytes.getUint8(i + 2),
            );
          }

          for (final lamp in lamps) {
            final rect = lamp.localToGlobal(Offset.zero) & lamp.size;
            final y = (rect.center.dy * ratio).round();
            final from = ((rect.left - 3) * ratio).round();
            final ground = at(from, y);
            // The first pixels that are not the ground, from the outside in: the lamp's outer edge.
            var x = from;
            while (at(x, y) == ground && x < rect.center.dx * ratio) {
              x++;
            }
            final edge = at(x + 1, y);
            expect(
              _contrast(edge, ground),
              greaterThanOrEqualTo(3),
              reason: 'edge $edge on ground $ground at x ${x / ratio}',
            );
          }
          image.dispose();
        },
      );
    }
  }
}
