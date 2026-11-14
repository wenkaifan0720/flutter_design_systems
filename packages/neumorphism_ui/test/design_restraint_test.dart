import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void _tap() {}

void main() {
  setUpAll(loadNeumorphicFonts);
  for (final width in [390.0, 1440.0]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'dialog actions fit one aligned row at $width ${brightness.name}',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MaterialApp(
              home: NeumorphicTheme(
                data: NeumorphicThemeData.porcelain(brightness),
                child: NeumorphicDialog(
                  title: 'Save your changes?',
                  message: 'Your preferences will be used on all your devices.',
                  actions: [
                    NeumorphicButton.text(
                      'Cancel',
                      key: const Key('cancel'),
                      onPressed: () {},
                    ),
                    NeumorphicButton.filled(
                      'Save changes',
                      key: const Key('save'),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            (tester.getCenter(find.text('Cancel')).dy -
                    tester.getCenter(find.text('Save changes')).dy)
                .abs(),
            lessThanOrEqualTo(.5),
          );
          expect(
            (tester.getSize(find.byKey(const Key('cancel'))).height -
                    tester.getSize(find.byKey(const Key('save'))).height)
                .abs(),
            lessThanOrEqualTo(.5),
          );
          expect(
            tester
                .widget<Text>(find.text('Save your changes?'))
                .style!
                .fontSize,
            24,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final preset in NeumorphicThemeData.presets) {
    for (final brightness in Brightness.values) {
      testWidgets('$preset ${brightness.name}: strong outlines are opt-in', (
        tester,
      ) async {
        final base = NeumorphicThemeData.preset(preset, brightness);
        final stage = GlobalKey();
        final ratios = <double>[];
        for (final strong in [false, true]) {
          await tester.pumpWidget(
            MaterialApp(
              home: NeumorphicTheme(
                data: base.copyWith(highContrast: strong),
                child: Center(
                  child: RepaintBoundary(
                    key: stage,
                    child: ColoredBox(
                      color: base.colors.ground,
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: NeumorphicFlatScope(
                          child: SizedBox(
                            width: 200,
                            // An enabled box: a disabled one fades, and 3:1 doesn't bind a control out of use.
                            child: NeumorphicChoiceBox(
                              onPressed: _tap,
                              child: SizedBox(height: 48),
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
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(stage),
          );
          final face = tester.renderObject<RenderBox>(
            find.byType(NeumorphicSurface),
          );
          final offset = face.localToGlobal(
            Offset(0, face.size.height / 2),
            ancestor: boundary,
          );
          final image = await tester.runAsync(() => boundary.toImage());
          final data = await tester.runAsync(
            () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
          );
          double contrast(Color a, Color b) =>
              (math.max(a.computeLuminance(), b.computeLuminance()) + .05) /
              (math.min(a.computeLuminance(), b.computeLuminance()) + .05);
          var strongest = 1.0;
          for (var dx = 0; dx < 3; dx++) {
            final index =
                (offset.dy.round() * image!.width + offset.dx.round() + dx) * 4;
            final pixel = Color.fromARGB(
              255,
              data!.getUint8(index),
              data.getUint8(index + 1),
              data.getUint8(index + 2),
            );
            strongest = math.max(
              strongest,
              contrast(pixel, base.colors.ground),
            );
          }
          image!.dispose();
          ratios.add(strongest);
        }
        expect(
          ratios.first,
          lessThan(1.5),
          reason: 'the normal face has no dark contour',
        );
        expect(
          ratios.last,
          greaterThanOrEqualTo(3),
          reason: 'explicit high contrast retains its boundary',
        );
      }, tags: ['goldens']);
    }
  }

  for (final kind in ['linear', 'circular']) {
    for (final preset in NeumorphicThemeData.presets) {
      for (final brightness in Brightness.values) {
        testWidgets(
          '$kind progress in $preset ${brightness.name}: track outline is opt-in',
          (tester) async {
            final base = NeumorphicThemeData.preset(preset, brightness);
            final stage = GlobalKey();
            final ratios = <double>[];
            for (final strong in [false, true, false]) {
              await tester.pumpWidget(
                MaterialApp(
                  home: NeumorphicTheme(
                    data: base.copyWith(highContrast: strong),
                    child: Center(
                      child: RepaintBoundary(
                        key: stage,
                        child: ColoredBox(
                          color: base.colors.ground,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            // Isolate the track from its soft shadow pair.
                            child: NeumorphicFlatScope(
                              child: kind == 'linear'
                                  ? const SizedBox(
                                      width: 200,
                                      child: NeumorphicLinearProgressIndicator(
                                        value: 0,
                                        label: 'Upload',
                                        quiet: true,
                                      ),
                                    )
                                  : const NeumorphicCircularProgressIndicator(
                                      value: 0,
                                      color: Colors.transparent,
                                      size: 64,
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
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(stage),
              );
              final image = await tester.runAsync(() => boundary.toImage());
              final data = await tester.runAsync(
                () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
              );
              final ground = base.colors.ground.computeLuminance();
              var strongest = 1.0;
              for (var i = 0; i < data!.lengthInBytes; i += 4) {
                final luminance = Color.fromARGB(
                  255,
                  data.getUint8(i),
                  data.getUint8(i + 1),
                  data.getUint8(i + 2),
                ).computeLuminance();
                strongest = math.max(
                  strongest,
                  (math.max(luminance, ground) + .05) /
                      (math.min(luminance, ground) + .05),
                );
              }
              image!.dispose();
              ratios.add(strongest);
              expect(tester.takeException(), isNull);
            }
            expect(ratios.first, lessThan(1.1));
            expect(ratios[1], greaterThanOrEqualTo(3));
            expect(
              ratios.last,
              closeTo(ratios.first, .01),
              reason: 'turning high contrast off repaints the plain track',
            );
          },
          tags: ['goldens'],
        );
      }
    }
  }

  for (final density in [
    NeumorphicDensity.compact,
    NeumorphicDensity.standard,
    NeumorphicDensity.comfortable,
  ]) {
    {
      testWidgets('action labels share a centre and height at $density', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: NeumorphicTheme(
              data: NeumorphicThemeData.porcelain().copyWith(density: density),
              child: Center(
                child: SizedBox(
                  width: 600,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: NeumorphicButton.text(
                          'Cancel',
                          key: const Key('quiet'),
                          wide: true,
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: NeumorphicButton(
                          'Preview',
                          key: const Key('line'),
                          wide: true,
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: NeumorphicButton.filled(
                          'Save',
                          key: const Key('filled'),
                          wide: true,
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final centres = [
          for (final label in ['Cancel', 'Preview', 'Save'])
            tester.getCenter(find.text(label)).dy,
        ];
        final heights = [
          for (final key in ['quiet', 'line', 'filled'])
            tester.getSize(find.byKey(Key(key))).height,
        ];
        expect(
          centres.reduce(math.max) - centres.reduce(math.min),
          lessThanOrEqualTo(.5),
        );
        expect(
          heights.reduce(math.max) - heights.reduce(math.min),
          lessThanOrEqualTo(.5),
        );
        expect(heights.every((value) => value >= 48), isTrue);
      });
    }
  }
}
