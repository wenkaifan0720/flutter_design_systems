import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'styled_controls_test.dart' show mount, pixel;
import 'support.dart';

typedef _Build = Widget Function(NeumorphicStyle?);

void main() {
  setUpAll(loadNeumorphicFonts);
  final parts = <(String, _Build, bool)>[
    (
      'text',
      (s) => NeumorphicTextField(initialValue: 'Content', style: s),
      false,
    ),
    (
      'area',
      (s) => NeumorphicTextArea(initialValue: 'Content', lines: 3, style: s),
      true,
    ),
    ('search', (s) => NeumorphicSearchField(hint: 'Content', style: s), false),
    (
      'select',
      (s) =>
          NeumorphicSelectField(value: 'Content', style: s, onPressed: () {}),
      false,
    ),
    ('input', (s) => NeumorphicInput(initialValue: 'Content', style: s), false),
    ('code', (s) => NeumorphicInputOtp(length: 4, style: s), false),
  ];
  for (final (name, build, _) in parts) {
    testWidgets('$name uses field theme and local fill', (tester) async {
      final theme = NeumorphicThemeData.porcelain().copyWith(
        textFieldTheme: const NeumorphicStyle(
          fill: WidgetStatePropertyAll(Colors.red),
        ),
      );
      await mount(tester, build(null), theme);
      expect(await pixel(tester), Colors.red.toARGB32());
      await mount(
        tester,
        build(const NeumorphicStyle(fill: WidgetStatePropertyAll(Colors.blue))),
        theme,
      );
      expect(await pixel(tester), Colors.blue.toARGB32());
    });
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
                  build(null),
                  NeumorphicThemeData.porcelain().copyWith(density: density),
                  width: width,
                  scale: scale,
                );
                if (name == 'code') {
                  await tester.enterText(find.byType(EditableText), '1234');
                  await tester.pumpAndSettle();
                }
                final faces = tester
                    .renderObjectList<RenderCustomPaint>(
                      find.byType(CustomPaint),
                    )
                    .where(
                      (r) => r.painter.runtimeType.toString() == '_CastPainter',
                    )
                    .toList();
                final contents = name == 'code'
                    ? [for (var i = 1; i <= 4; i++) find.text('$i')]
                    : [
                        name == 'select' || name == 'search'
                            ? find.text('Content')
                            : find.byType(EditableText),
                      ];
                const shape = NeumorphicRoundedBorder();
                for (var i = 0; i < contents.length; i++) {
                  final paint = faces[i];
                  final path = shape.getOuterPath(Offset.zero & paint.size);
                  final child = tester.renderObject<RenderBox>(contents[i]);
                  final bounds = MatrixUtils.transformRect(
                    child.getTransformTo(paint),
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
                      reason: '$point outside ${paint.size}',
                    );
                  }
                }
                expect(tester.takeException(), isNull);
              },
            );
          }
        }
      }
    }
  }
  testWidgets('editing focus and error states resolve independently', (
    tester,
  ) async {
    final style = NeumorphicStyle(
      fill: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.error)
            ? Colors.red
            : states.contains(WidgetState.focused)
            ? Colors.blue
            : Colors.green,
      ),
    );
    await mount(
      tester,
      NeumorphicTextField(style: style),
      NeumorphicThemeData.porcelain(),
    );
    expect(await pixel(tester), Colors.green.toARGB32());
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(await pixel(tester), Colors.blue.toARGB32());
    await mount(
      tester,
      NeumorphicTextField(style: style, error: 'Required'),
      NeumorphicThemeData.porcelain(),
    );
    expect(await pixel(tester), Colors.red.toARGB32());
  });
  testWidgets('select uses the same focused state as its pressable', (
    tester,
  ) async {
    final style = NeumorphicStyle(
      fill: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.pressed) ? Colors.blue : Colors.green,
      ),
      overlay: const WidgetStatePropertyAll(Colors.transparent),
    );
    await mount(
      tester,
      NeumorphicSelectField(value: 'Content', style: style, onPressed: () {}),
      NeumorphicThemeData.porcelain(),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(NeumorphicTap).first),
    );
    await tester.pumpAndSettle();
    expect(await pixel(tester), Colors.blue.toARGB32());
    await gesture.up();
  });
}
