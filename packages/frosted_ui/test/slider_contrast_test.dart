import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_parts.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final mode in Brightness.values) {
    testWidgets('slider track and thumb rim remain distinct on $mode glass', (
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
                          values: const DesignRangeValues(.2, .8),
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
        for (final knob in shapes.where(
          (r) =>
              r.width == FrostedChromeMetrics.sliderThumb &&
              r.height == r.width,
        )) {
          final sample = pixel(Offset(knob.center.dx, knob.top + .45));
          expect(
            FrostedThemeData.contrast(sample, ground),
            greaterThanOrEqualTo(3),
          );
        }
      }
      image.dispose();
    });
  }
}
