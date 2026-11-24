// A range's band runs unbroken from its start to its end: where the
// month's columns fell on a fraction of a pixel (at 1440, at 2x), each day's
// band met the next with a lighter seam of the page between, a line down the
// band at each day's edge. As brutal's calendar_seams_test: by day and by
// night, either way round, under a finger and on a desk. Its days overlap
// only each other: past its row's or its month's last day the page stays.
import 'dart:ui' as ui;

import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _table = ValueKey('table');

void main() {
  setUpAll(fluent2LoadFonts);

  for (final brightness in Brightness.values) {
    for (final (width, ratio) in [
      (333.7, 2.0),
      (357.3, 2.625),
      (401.1, 1.0),
      (452.9, 2.0),
    ]) {
      for (final direction in TextDirection.values) {
        testWidgets(
          'a range by ${brightness.name} at $width x $ratio, '
          '${direction.name}: its band has no seam',
          (tester) async {
            tester.view.physicalSize = Size(520 * ratio, 900 * ratio);
            tester.view.devicePixelRatio = ratio;
            addTearDown(tester.view.reset);
            final controller =
                RawCalendarController(
                    firstDate: DateTime(2026),
                    lastDate: DateTime(2027, 12, 31),
                    mode: RawCalendarMode.range,
                    initialMonth: DateTime(2026, 11),
                    currentDate: DateTime(2026, 11, 20),
                  )
                  ..select(DateTime(2026, 11, 10))
                  ..select(DateTime(2026, 11, 13));
            addTearDown(controller.dispose);
            await tester.pumpWidget(
              WidgetsApp(
                color: const Color(0xFF000000),
                builder: (context, _) => Directionality(
                  textDirection: direction,
                  child: Fluent2Host(
                    brightness: brightness,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10.3, 10.6, 0, 0),
                        child: RepaintBoundary(
                          key: _table,
                          child: SizedBox(
                            width: width,
                            child: Fluent2DateRangePicker(
                              controller: controller,
                              months: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final origin = tester.getTopLeft(find.byKey(_table));
            Offset at(String day) =>
                (tester.getCenter(find.text(day)) - origin) * ratio;
            final (start, inner, end) = (at('10'), at('11'), at('13'));
            final step = (at('12').dx - inner.dx).abs();
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(_table),
            );
            final image = (await tester.runAsync(
              () => boundary.toImage(pixelRatio: ratio),
            ))!;
            final bytes = (await tester.runAsync(
              () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
            ))!;
            final w = image.width;
            image.dispose();
            List<int> pixel(int x, int y) {
              final i = (y * w + x) * 4;
              return [
                bytes.getUint8(i),
                bytes.getUint8(i + 1),
                bytes.getUint8(i + 2),
              ];
            }

            int apart(List<int> a, List<int> b) =>
                [for (var k = 0; k < 3; k++) (a[k] - b[k]).abs()]
                    .reduce((p, q) => p > q ? p : q);
            // The band's tone, beside the 11's figures; its top, up from there.
            final x =
                (inner.dx +
                        step * .35 * (direction == TextDirection.rtl ? -1 : 1))
                    .round();
            final band = pixel(x, inner.dy.round());
            var top = inner.dy.round();
            while (apart(pixel(x, top - 1), band) < 3) {
              top--;
            }
            // A line along the band above its figures, between the ends' discs.
            final y = top + (3 * ratio).round();
            final from = (start.dx < end.dx ? start.dx : end.dx) + step / 2;
            final to = (start.dx < end.dx ? end.dx : start.dx) - step / 2;
            final seams = <String>[
              for (var px = from.ceil(); px <= to.floor(); px++)
                if (apart(pixel(px, y), band) >= 3)
                  '($px, $y) ${pixel(px, y)} against $band',
            ];
            expect(seams, isEmpty);
          },
          variant: const TargetPlatformVariant({
            TargetPlatform.macOS,
            TargetPlatform.android,
          }),
        );
      }
    }
  }

  // Nor does it reach past its row's ends or its month's: 28 November ends a
  // row, 29 starts one and 30 ends the month (the band no further than its
  // days, the page beyond them untouched).
  for (final brightness in Brightness.values) {
    for (final (width, ratio) in [
      (333.7, 2.0),
      (357.3, 2.625),
      (401.1, 1.0),
      (452.9, 2.0),
      (371.9, 3.0),
    ]) {
      for (final direction in TextDirection.values) {
        testWidgets(
          'a range by ${brightness.name} at $width x $ratio, '
          '${direction.name}: its band stops at its row and month ends',
          (tester) async {
            tester.view.physicalSize = Size(520 * ratio, 900 * ratio);
            tester.view.devicePixelRatio = ratio;
            addTearDown(tester.view.reset);
            final controller =
                RawCalendarController(
                    firstDate: DateTime(2026),
                    lastDate: DateTime(2027, 12, 31),
                    mode: RawCalendarMode.range,
                    initialMonth: DateTime(2026, 11),
                    currentDate: DateTime(2026, 11, 20),
                  )
                  ..select(DateTime(2026, 11, 27))
                  ..select(DateTime(2026, 12, 3));
            addTearDown(controller.dispose);
            const page = Color(0xFF808080);
            await tester.pumpWidget(
              WidgetsApp(
                color: const Color(0xFF000000),
                builder: (context, _) => Directionality(
                  textDirection: direction,
                  child: Fluent2Host(
                    brightness: brightness,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10.3, 10.6, 0, 0),
                        child: RepaintBoundary(
                          key: _table,
                          child: ColoredBox(
                            color: page,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.3,
                              ),
                              child: SizedBox(
                                width: width,
                                child: Fluent2DateRangePicker(
                                  controller: controller,
                                  months: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final rtl = direction == TextDirection.rtl;
            final origin = tester.getTopLeft(find.byKey(_table));
            Offset at(String day) =>
                (tester.getCenter(find.text(day)) - origin) * ratio;
            final step = (at('29').dx - at('30').dx).abs();
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(_table),
            );
            final image = (await tester.runAsync(
              () => boundary.toImage(pixelRatio: ratio),
            ))!;
            final bytes = (await tester.runAsync(
              () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
            ))!;
            final w = image.width;
            image.dispose();
            List<int> pixel(int x, int y) {
              final i = (y * w + x) * 4;
              return [
                bytes.getUint8(i),
                bytes.getUint8(i + 1),
                bytes.getUint8(i + 2),
              ];
            }

            int apart(List<int> a, List<int> b) =>
                [for (var k = 0; k < 3; k++) (a[k] - b[k]).abs()]
                    .reduce((p, q) => p > q ? p : q);
            final ground = pixel(2, 2);
            // A line along the band above its figures, found from 29's band.
            List<String> beyond(String day, {required bool end}) {
              final c = at(day);
              final x = (c.dx + step * .35).round();
              final band = pixel(x, c.dy.round());
              var top = c.dy.round();
              while (apart(pixel(x, top - 1), band) < 3) {
                top--;
              }
              final y = top + (3 * ratio).round();
              // The edge the band stops at, and the first whole pixel past it.
              final right = end != rtl;
              final edge = c.dx + (right ? step / 2 : -step / 2);
              final px = right ? edge.ceil() : edge.floor() - 1;
              return [
                if (apart(pixel(px, y), ground) >= 3)
                  '$day ($px, $y) ${pixel(px, y)} against $ground',
              ];
            }

            expect([
              ...beyond('28', end: true),
              ...beyond('29', end: false),
              ...beyond('30', end: true),
            ], isEmpty);
          },
          variant: const TargetPlatformVariant({
            TargetPlatform.macOS,
            TargetPlatform.android,
          }),
        );
      }
    }
  }
}
