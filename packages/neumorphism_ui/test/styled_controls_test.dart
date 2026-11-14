import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

typedef _Build = Widget Function(NeumorphicStyle? style, VoidCallback? press);
const _capture = ValueKey('capture');

Future<void> mount(
  WidgetTester tester,
  Widget child,
  NeumorphicThemeData theme, {
  double width = 240,
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(600, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(600, 800),
          textScaler: TextScaler.linear(scale),
        ),
        child: NeumorphicTheme(
          data: theme,
          child: Center(
            child: RepaintBoundary(
              key: _capture,
              child: SizedBox(
                width: width,
                child: NeumorphicFlatScope(child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

RenderCustomPaint face(WidgetTester tester) => tester
    .renderObjectList<RenderCustomPaint>(find.byType(CustomPaint))
    .firstWhere(
      // A bank of cells (tabs) has no face per cell: its first cell lies on the bank's face.
      (r) => [
        '_ActPainter',
        '_CastPainter',
        '_BankFace',
      ].contains(r.painter.runtimeType.toString()),
    );

Future<int> pixel(WidgetTester tester) async {
  final paint = face(tester),
      capture = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(_capture),
      );
  final point = capture.globalToLocal(
    paint.localToGlobal(Offset(9, paint.size.height / 2)),
  );
  return (await tester.runAsync(() async {
    final image = await capture.toImage();
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final i = (point.dy.floor() * image.width + point.dx.floor()) * 4;
    final color = Color.fromARGB(
      bytes.getUint8(i + 3),
      bytes.getUint8(i),
      bytes.getUint8(i + 1),
      bytes.getUint8(i + 2),
    );
    image.dispose();
    return color.toARGB32();
  }))!;
}

void main() {
  setUpAll(loadNeumorphicFonts);
  final parts = <(String, _Build, bool)>[
    (
      'act',
      (s, p) => NeumorphicButton.filled('Control', style: s, onPressed: p),
      false,
    ),
    (
      'line',
      (s, p) => NeumorphicButton('Control', style: s, onPressed: p),
      false,
    ),
    (
      'quiet',
      (s, p) => NeumorphicButton.text('Control', style: s, onPressed: p),
      false,
    ),
    (
      'danger',
      (s, p) => NeumorphicButton(
        'Control',
        isDestructiveAction: true,
        style: s,
        onPressed: p,
      ),
      false,
    ),
    (
      'button',
      (s, p) => NeumorphicButton('Control', style: s, onPressed: p),
      false,
    ),
    (
      'icon',
      (s, p) => NeumorphicIconButton(
        NeumorphicGlyphs.plus,
        label: 'Control',
        style: s,
        onPressed: p,
      ),
      true,
    ),
    (
      'round act',
      (s, p) => NeumorphicRoundButton.filled(
        NeumorphicGlyphs.plus,
        label: 'Control',
        style: s,
        onPressed: p,
      ),
      true,
    ),
    (
      'round',
      (s, p) => NeumorphicRoundButton(
        NeumorphicGlyphs.plus,
        label: 'Control',
        style: s,
        onPressed: p,
      ),
      true,
    ),
    ('send', (s, p) => NeumorphicSendButton(style: s, onPressed: p), true),
  ];
  for (final (name, build, square) in parts) {
    if (name != 'quiet') {
      testWidgets('$name paints pressed and hovered style slots', (
        tester,
      ) async {
        var presses = 0;
        final style = NeumorphicStyle(
          fill: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? Colors.blue
                : states.contains(WidgetState.hovered)
                ? Colors.green
                : Colors.red,
          ),
          overlay: const WidgetStatePropertyAll(Colors.transparent),
        );
        await mount(
          tester,
          build(style, () => presses++),
          NeumorphicThemeData.porcelain(),
        );
        expect(await pixel(tester), Colors.red.toARGB32());
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: const Offset(1, 1));
        await mouse.moveTo(tester.getCenter(find.byType(NeumorphicTap).first));
        await tester.pumpAndSettle();
        expect(await pixel(tester), Colors.green.toARGB32());
        await mouse.down(tester.getCenter(find.byType(NeumorphicTap).first));
        await tester.pumpAndSettle();
        expect(await pixel(tester), Colors.blue.toARGB32());
        await mouse.up();
        await tester.pumpAndSettle();
        expect(presses, 1);
        await mouse.removePointer();
      }, tags: ['goldens']);
    }
    for (final set in const ['look']) {
      for (final (densityName, density) in [
        ('standard', NeumorphicDensity.standard),
        ('comfortable', NeumorphicDensity.comfortable),
        ('compact', NeumorphicDensity.compact),
      ]) {
        for (final width in [120.0, 240.0, 390.0]) {
          for (final scale in [1.0, 1.3]) {
            testWidgets(
              '$name $set $densityName contains content at $width $scale',
              (tester) async {
                await mount(
                  tester,
                  build(null, () {}),
                  NeumorphicThemeData.porcelain().copyWith(density: density),
                  width: width,
                  scale: scale,
                );
                final content = square
                    ? find.byIcon(
                        name == 'send'
                            ? NeumorphicGlyphs.sendHorizontal
                            : NeumorphicGlyphs.plus,
                      )
                    : find.text('Control');
                final render = name == 'quiet'
                    ? tester.renderObject<RenderBox>(
                        find.byType(NeumorphicTap).first,
                      )
                    : face(tester);
                final size = render.size;
                final border = square
                    ? NeumorphicCircleBorder(diameter: size.shortestSide)
                    : const NeumorphicRoundedBorder();
                final path = border.getOuterPath(Offset.zero & size);
                final child = tester.renderObject<RenderBox>(content);
                final bounds = MatrixUtils.transformRect(
                  child.getTransformTo(render),
                  child.paintBounds,
                ).deflate(1);
                for (final point in [
                  bounds.topLeft,
                  bounds.topCenter,
                  bounds.topRight,
                  bounds.centerRight,
                  bounds.bottomRight,
                  bounds.bottomCenter,
                  bounds.bottomLeft,
                  bounds.centerLeft,
                ]) {
                  expect(
                    path.contains(point),
                    isTrue,
                    reason: '$point outside $size',
                  );
                }
                final tap = tester.getSize(find.byType(NeumorphicTap).first);
                expect(tap.width, greaterThanOrEqualTo(48));
                expect(tap.height, greaterThanOrEqualTo(48));
              },
            );
          }
        }
      }
    }
  }
}
