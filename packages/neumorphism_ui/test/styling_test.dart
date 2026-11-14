import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/theme.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

Iterable<Offset> points(Rect box) => [
  box.topLeft,
  box.topCenter,
  box.topRight,
  box.centerRight,
  box.bottomRight,
  box.bottomCenter,
  box.bottomLeft,
  box.centerLeft,
];

void main() {
  const borders = <NeumorphicBorder>[
    NeumorphicRoundedBorder(radius: 8),
    NeumorphicRoundedBorder(radius: 20),
    NeumorphicStadiumBorder(),
    NeumorphicCircleBorder(),
  ];
  for (var i = 0; i < borders.length; i++) {
    for (var j = 0; j < borders.length; j++) {
      test('rounded family $i to $j keeps exact ends and safe midpoint', () {
        final a = borders[i], b = borders[j];
        expect(OutlinedBorder.lerp(a, b, 0), a);
        expect(OutlinedBorder.lerp(a, b, 1), b);
        final mid = OutlinedBorder.lerp(a, b, .5)! as NeumorphicBorder;
        for (final width in [24.0, 48.0, 80.0, 120.0]) {
          final fitted = mid.fit(Size.square(width));
          final box = Offset.zero & Size.square(width);
          final inside = fitted.dimensions
              .resolve(TextDirection.ltr)
              .deflateRect(box)
              .deflate(1);
          if (inside.isEmpty) continue;
          for (final point in points(inside)) {
            expect(
              fitted.getOuterPath(box).contains(point),
              isTrue,
              reason: '$width $point',
            );
          }
        }
      });
    }
  }
  for (final border in borders) {
    test('${border.runtimeType} has a value API and scales geometry', () {
      const side = BorderSide(color: Colors.black, width: 2);
      expect(border.copyWith(side: border.side), border);
      expect(border.copyWith(side: border.side).hashCode, border.hashCode);
      expect(border.copyWith(side: side).side, side);
      expect(border.scale(0).dimensions, EdgeInsets.zero);
      expect(
        border.scale(2).dimensions.horizontal,
        closeTo(border.dimensions.horizontal * 2, 1e-8),
      );
      expect(
        border.getOuterPath(const Rect.fromLTWH(0, 0, 80, 80)).getBounds(),
        const Rect.fromLTWH(0, 0, 80, 80),
      );
    });
  }

  for (final (name, ground, pigment) in [
    ('plum', const Color(0xFFE8E3ED), const Color(0xFF7542A3)),
    ('pale', const Color(0xFFEEEEEE), const Color(0xFFFDFAED)),
    ('dark input', const Color(0xFF080510), const Color(0xFFB4DF76)),
    ('one grey', const Color(0xFF777777), const Color(0xFF777777)),
    ('transparent', const Color(0x007700FF), const Color(0x33777777)),
    ('saturated', const Color(0xFF00FF00), const Color(0xFFFF00FF)),
  ]) {
    for (final brightness in Brightness.values) {
      final theme = NeumorphicThemeData.from(
        ground: ground,
        pigment: pigment,
        brightness: brightness,
      );
      final c = theme.colors;
      final grounds = [
        c.ground,
        c.faceStart,
        c.faceEnd,
        c.wellStart,
        c.wellEnd,
      ];
      final washed = [for (final g in grounds) Color.alphaBlend(c.wash, g)];
      test(
        '$name ${brightness.name}: words and resting edges on every surface',
        () {
          expect(theme.dark, brightness == Brightness.dark);
          expect(theme.id, 'custom');
          for (final g in [...grounds, ...washed]) {
            for (final word in [
              c.ink,
              c.inkSecondary,
              c.inkTertiary,
              c.pigmentInk,
              c.pigmentInkLit,
            ]) {
              expect(contrast(word, g), greaterThanOrEqualTo(4.5));
            }
            expect(contrast(c.edge, g), greaterThanOrEqualTo(4));
            for (final mark in [c.quiet, c.barStart, c.barEnd]) {
              expect(contrast(mark, g), greaterThanOrEqualTo(3));
            }
          }
          for (final g in grounds) {
            expect(contrast(c.pigment, g), greaterThanOrEqualTo(3));
          }
          expect(contrast(c.onPigment, c.pigment), greaterThanOrEqualTo(4.5));
          expect(contrast(c.onPigment, c.pigmentDk), greaterThanOrEqualTo(4.5));
        },
      );
    }
  }

  test(
    'style resolution falls through null states and merge keeps own slots',
    () {
      const base = NeumorphicStyle(
        fill: WidgetStatePropertyAll(Colors.black),
        foreground: WidgetStatePropertyAll(Colors.white),
      );
      final local = NeumorphicStyle(
        fill: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed) ? Colors.red : null,
        ),
      );
      expect(NeumorphicStyleOf([local, base], const {}).fill, Colors.black);
      expect(
        NeumorphicStyleOf([local, base], const {WidgetState.pressed}).fill,
        Colors.red,
      );
      expect(local.merge(base).foreground, base.foreground);
      expect(NeumorphicStyle.lerp(base, local, 0), same(base));
      expect(NeumorphicStyle.lerp(base, local, 1), same(local));
      final mid = NeumorphicStyle.lerp(base, local, .5)!;
      expect(
        mid.fill!.resolve({WidgetState.pressed}),
        Color.lerp(Colors.black, Colors.red, .5),
      );
      expect(base.copyWith(), base);
      expect(base.copyWith().hashCode, base.hashCode);
      expect(base.toDiagnosticsNode().toStringDeep(), contains('foreground'));
    },
  );

  test('theme copy, responsive width and lerp retain every customization', () {
    const style = NeumorphicStyle(fill: WidgetStatePropertyAll(Colors.black));
    final a = NeumorphicThemeData.porcelain().copyWith(
      density: NeumorphicDensity.compact,
      highContrast: true,
      typeface: const NeumorphicTypeface.app(display: 'Display', text: 'Text'),
      elevation: const NeumorphicElevation(depth: .5, strength: .75),
      buttonTheme: style,
      textFieldTheme: style,
      cardTheme: style,
      avatarTheme: style,
    );
    expect(a.copyWith(), a);
    expect(a.copyWith().hashCode, a.hashCode);
    final wide = a.atWidth(1200);
    expect(wide.shapes, a.shapes);
    expect(wide.typeface, a.typeface);
    expect(wide.buttonTheme, a.buttonTheme);
    expect(wide.avatarTheme, a.avatarTheme);
    expect(wide.textTheme.page.fontFamily, 'Display');
    expect(wide.textTheme.body.fontFamily, 'Text');
    expect(wide.highContrast, isTrue);
    expect(wide.density, NeumorphicDensity.compact);
    expect(wide.textTheme.body.fontSize, 16);
    final b = NeumorphicThemeData.pompeii();
    expect(NeumorphicThemeData.lerp(a, b, 0), a);
    expect(NeumorphicThemeData.lerp(a, b, 1), b);
    final mid = NeumorphicThemeData.lerp(a, b, .5);
    expect(mid.elevation.depth, .75);
    expect(mid.density.horizontal, -1);
    expect(a.toDiagnosticsNode().toStringDeep(), contains('textFieldTheme'));
  });

  testWidgets('state shape changes ease and reduce motion lands immediately', (
    tester,
  ) async {
    var shape = borders.first;
    var reduce = false;
    late StateSetter update;
    OutlinedBorder? painted;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return MediaQuery(
              data: MediaQueryData(disableAnimations: reduce),
              child: NeumorphicTheme(
                data: NeumorphicThemeData.porcelain(),
                child: AnimatedNeumorphicShape(
                  shape: shape,
                  builder: (context, now) {
                    painted = now;
                    return const SizedBox(width: 48, height: 48);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
    expect(painted, borders.first);
    expect(
      find.descendant(
        of: find.byType(AnimatedNeumorphicShape),
        matching: find.byType(RepaintBoundary),
      ),
      findsOneWidget,
    );
    update(() => shape = borders.last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    expect(painted, isNot(borders.first));
    expect(painted, isNot(borders.last));
    await tester.pumpAndSettle();
    expect(painted, borders.last);
    update(() {
      reduce = true;
      shape = borders[1];
    });
    await tester.pump();
    expect(painted, borders[1]);
  });
}
