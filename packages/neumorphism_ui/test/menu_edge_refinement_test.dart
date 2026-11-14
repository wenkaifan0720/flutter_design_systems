import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

Future<(ByteData, int)> _pixels(WidgetTester tester, GlobalKey key) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final image = await tester.runAsync(() => boundary.toImage());
  final bytes = await tester.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  final width = image!.width;
  image.dispose();
  return (bytes!, width);
}

Color _at(ByteData bytes, int width, int x, int y) {
  final offset = (y * width + x) * 4;
  return Color.fromARGB(
    255,
    bytes.getUint8(offset),
    bytes.getUint8(offset + 1),
    bytes.getUint8(offset + 2),
  );
}

double _contrast(Color a, Color b) =>
    (math.max(a.computeLuminance(), b.computeLuminance()) + .05) /
    (math.min(a.computeLuminance(), b.computeLuminance()) + .05);

void main() {
  setUpAll(loadNeumorphicFonts);
  for (final dark in [false, true]) {
    testWidgets(
      'dropdown has one clean lower shadow over a nearby field, dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(390, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final stage = GlobalKey();
        final underlay = ValueNotifier(true);
        addTearDown(underlay.dispose);
        final colors = NeumorphicThemeData.porcelain(
          dark ? Brightness.dark : Brightness.light,
        ).colors;
        await tester.pumpWidget(
          RepaintBoundary(
            key: stage,
            child: neumorphicApp(
              ColoredBox(
                color: colors.ground,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      left: 24,
                      right: 24,
                      top: 288,
                      child: NeumorphicSelect<String>(
                        key: const Key('country'),
                        label: 'Country',
                        value: 'United States',
                        options: const [
                          NeumorphicMenuItem('United States', 'United States'),
                          NeumorphicMenuItem('Canada', 'Canada'),
                          NeumorphicMenuItem(
                            'United Kingdom',
                            'United Kingdom',
                          ),
                        ],
                        onChanged: (_) {},
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      top: 384,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: underlay,
                        builder: (context, visible, _) => Opacity(
                          opacity: visible ? 1 : 0,
                          child: const NeumorphicTextArea(
                            label: 'Delivery notes',
                            lines: 3,
                            hint: 'Anything we should know?',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              dark: dark,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('country')));
        await tester.pumpAndSettle();
        final menu = find.byType(NeumorphicMenu<String>);
        expect(
          find.descendant(of: menu, matching: find.byType(NeumorphicSurface)),
          findsOneWidget,
        );
        final rect = tester.getRect(menu);
        final withField = await _pixels(tester, stage);
        underlay.value = false;
        await tester.pumpAndSettle();
        final withoutField = await _pixels(tester, stage);
        var largestDifference = 0;
        for (var y = rect.bottom.ceil(); y < rect.bottom.ceil() + 10; y++) {
          for (var x = rect.left.ceil() + 4; x < rect.right.floor() - 4; x++) {
            final a = (y * withField.$2 + x) * 4;
            for (var channel = 0; channel < 3; channel++) {
              largestDifference = math.max(
                largestDifference,
                (withField.$1.getUint8(a + channel) -
                        withoutField.$1.getUint8(a + channel))
                    .abs(),
              );
            }
          }
        }
        expect(
          largestDifference,
          lessThanOrEqualTo(1),
          reason: 'a second recessed edge must not show through the menu lower shadow',
        );
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.all(),
      tags: ['goldens'],
    );
  }
  for (final preset in NeumorphicThemeData.presets) {
    testWidgets('$preset unchecked light well has depth beyond a thin edge', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(160, 160);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final stage = GlobalKey();
      final theme = NeumorphicThemeData.preset(preset, Brightness.light);
      await tester.pumpWidget(
        RepaintBoundary(
          key: stage,
          child: neumorphicApp(
            ColoredBox(
              color: theme.colors.ground,
              child: Center(
                child: NeumorphicCheckbox(
                  value: false,
                  label: 'Remember these details',
                  onChanged: (_) {},
                ),
              ),
            ),
            preset: preset,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final box = tester.getRect(find.byType(NeumorphicSurface));
      final image = await _pixels(tester, stage);
      final color = _at(
        image.$1,
        image.$2,
        box.left.round() + 3,
        box.center.dy.round(),
      );
      expect(
        _contrast(color, theme.colors.ground),
        greaterThan(1.05),
        reason: 'the inset should extend into the empty well, without a printed outline',
      );
      expect(theme.highContrast, isFalse);
      expect(tester.takeException(), isNull);
    }, tags: ['goldens']);
  }
}
