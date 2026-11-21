// A slider's value reads by its active track, which holds 3:1 on the ground
// by day and by night, and the knob stands at that track's end. The knob is
// bounded by light, not a traced line: its rim reads at least as light as the
// ground it stands on.
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_parts.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final mode in Brightness.values) {
    testWidgets('a slider reads by its track and lights its knob on $mode', (
      t,
    ) async {
      const ratio = 4.0;
      const key = Key('slider-plate');
      t.view.devicePixelRatio = ratio;
      t.view.physicalSize = const Size(390, 844) * ratio;
      addTearDown(t.view.reset);
      final ground = mode == Brightness.light
          ? const Color(0xffdec9eb)
          : const Color(0xff27232e);
      await t.pumpWidget(
        MaterialApp(
          home: FrostedHost(
            brightness: mode,
            child: Center(
              child: RepaintBoundary(
                key: key,
                child: ColoredBox(
                  color: ground,
                  child: SizedBox(
                    width: 320,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FrostedSlider(
                          label: 'Reach',
                          value: .6,
                          onChanged: (_) {},
                        ),
                        FrostedRangeSlider(
                          values: const RawRangeValues(.2, .8),
                          onChanged: (_) {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(key));
      final origin = t.getTopLeft(find.byKey(key));
      final image = (await t.runAsync(
        () => boundary.toImage(pixelRatio: ratio),
      ))!;
      final data = (await t.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
      ))!;
      Color pixel(Offset point) {
        final local = (point - origin) * ratio;
        final at = 4 * (local.dy.floor() * image.width + local.dx.floor());
        return Color.fromARGB(
          255,
          data.getUint8(at),
          data.getUint8(at + 1),
          data.getUint8(at + 2),
        );
      }

      for (final control in [
        find.byType(FrostedSlider),
        find.byType(FrostedRangeSlider),
      ]) {
        final faces = find.descendant(
          of: control,
          matching: find.byType(FrostedFace),
        );
        final shapes = faces
            .evaluate()
            .map((e) => t.getRect(find.byWidget(e.widget)))
            .toList();
        final tracks =
            shapes
                .where((r) => r.height == FrostedChromeMetrics.sliderTrack)
                .toList()
              ..sort((a, b) => a.width.compareTo(b.width));
        final active = tracks.first;
        expect(
          FrostedThemeData.contrast(pixel(active.center), ground),
          greaterThanOrEqualTo(3),
        );
        final knobs = shapes
            .where(
              (r) =>
                  r.width == FrostedChromeMetrics.sliderThumb &&
                  r.height == r.width,
            )
            .toList();
        expect(knobs, isNotEmpty);
        for (final knob in knobs) {
          final end = [active.left, active.right]
              .map((x) => (knob.center.dx - x).abs())
              .reduce((a, b) => a < b ? a : b);
          expect(end, lessThanOrEqualTo(knob.width / 2), reason: 'at the end');
          final rim = pixel(Offset(knob.center.dx, knob.top + .45));
          expect(
            rim.computeLuminance(),
            greaterThanOrEqualTo(ground.computeLuminance()),
            reason: 'rim $rim on $ground: light, not a dark line',
          );
        }
      }
      image.dispose();
    });
  }
}
