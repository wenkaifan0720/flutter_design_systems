import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'styled_controls_test.dart' show mount;
import 'support.dart';

void main() {
  setUpAll(loadNeumorphicFonts);
  testWidgets(
    'rail link resolves selected and pressed slots before its theme',
    (tester) async {
      var presses = 0;
      final theme = NeumorphicThemeData.porcelain().copyWith(
        segmentedButtonTheme: const NeumorphicStyle(
          foreground: WidgetStatePropertyAll(Colors.red),
          textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 19)),
          padding: WidgetStatePropertyAll(EdgeInsets.all(12)),
          minimumSize: WidgetStatePropertyAll(Size(100, 64)),
        ),
      );
      final style = NeumorphicStyle(
        foreground: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed) ? Colors.blue : null,
        ),
        fill: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : null,
        ),
        side: const WidgetStatePropertyAll(
          BorderSide(color: Colors.black, width: 2),
        ),
        shape: const WidgetStatePropertyAll(NeumorphicRoundedBorder(radius: 8)),
      );
      await mount(
        tester,
        NeumorphicRailLink(
          label: 'Room',
          figure: '21',
          selected: true,
          style: style,
          onPressed: () => presses++,
        ),
        theme,
      );
      for (final label in ['Room', '21']) {
        expect(tester.widget<Text>(find.text(label)).style!.color, Colors.red);
        expect(tester.widget<Text>(find.text(label)).style!.fontSize, 19);
      }
      final face = find.byType(NeumorphicSurface);
      expect(tester.getSize(face).height, greaterThanOrEqualTo(64));
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Room')),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.text('Room')).style!.color, Colors.blue);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(presses, 1);
      expect(tester.getSemantics(find.bySemanticsLabel('Room')).label, 'Room');
    },
  );

  testWidgets('link slots cascade by state and keep its labelled target', (
    tester,
  ) async {
    var presses = 0;
    const leading = Icon(Icons.star, key: ValueKey('mark'));
    final theme = NeumorphicThemeData.porcelain().copyWith(
      buttonTheme: const NeumorphicStyle(
        foreground: WidgetStatePropertyAll(Colors.red),
        iconSize: WidgetStatePropertyAll(22),
      ),
      textButtonTheme: const NeumorphicStyle(
        textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 19)),
        padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
      ),
    );
    final local = NeumorphicStyle(
      foreground: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.pressed) ? Colors.blue : null,
      ),
      fill: const WidgetStatePropertyAll(Colors.white),
      side: const WidgetStatePropertyAll(
        BorderSide(color: Colors.black, width: 2),
      ),
      shape: const WidgetStatePropertyAll(NeumorphicRoundedBorder(radius: 8)),
      minimumSize: const WidgetStatePropertyAll(Size(100, 56)),
    );
    await mount(
      tester,
      NeumorphicLink(
        'Details',
        style: local,
        leading: leading,
        onPressed: () => presses++,
      ),
      theme,
    );
    expect(tester.widget<Text>(find.text('Details')).style!.color, Colors.red);
    expect(tester.widget<Text>(find.text('Details')).style!.fontSize, 19);
    expect(
      IconTheme.of(tester.element(find.byKey(const ValueKey('mark')))).size,
      22,
    );
    final face = find.descendant(
      of: find.byType(NeumorphicLink),
      matching: find.byType(DecoratedBox),
    );
    final decoration =
        tester.widget<DecoratedBox>(face).decoration as ShapeDecoration;
    expect(decoration.color, Colors.white);
    expect((decoration.shape as OutlinedBorder).side.width, 2);
    expect(tester.getSize(face).height, greaterThanOrEqualTo(56));
    final press = await tester.startGesture(
      tester.getCenter(find.text('Details')),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text('Details')).style!.color, Colors.blue);
    await press.up();
    await tester.pumpAndSettle();
    expect(presses, 1);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Details')).label,
      'Details',
    );
  });

  for (final set in const ['look']) {
    for (final density in [
      NeumorphicDensity.standard,
      NeumorphicDensity.comfortable,
      NeumorphicDensity.compact,
    ]) {
      for (final width in [120.0, 240.0, 390.0]) {
        for (final scale in [1.0, 1.3]) {
          testWidgets('link $set $density $width $scale contains its words', (
            tester,
          ) async {
            await mount(
              tester,
              NeumorphicLink(
                'More details about your home',
                leading: const Icon(Icons.info),
                style: const NeumorphicStyle(
                  fill: WidgetStatePropertyAll(Colors.white),
                  padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
                ),
                onPressed: () {},
              ),
              NeumorphicThemeData.porcelain().copyWith(density: density),
              width: width,
              scale: scale,
            );
            final face = find.descendant(
              of: find.byType(NeumorphicLink),
              matching: find.byType(DecoratedBox),
            );
            final box = tester.renderObject<RenderBox>(face);
            final border =
                (tester.widget<DecoratedBox>(face).decoration
                        as ShapeDecoration)
                    .shape;
            final path = border.getOuterPath(Offset.zero & box.size);
            for (final node
                in find
                    .descendant(
                      of: face,
                      matching: find.byWidgetPredicate(
                        (w) => w is Text || w is Icon,
                      ),
                    )
                    .evaluate()) {
              final child = node.findRenderObject()! as RenderBox;
              final bounds = MatrixUtils.transformRect(
                child.getTransformTo(box),
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
                  reason: '${node.widget}: $bounds outside ${box.size}',
                );
              }
            }
          });
        }
      }
    }
  }
}
