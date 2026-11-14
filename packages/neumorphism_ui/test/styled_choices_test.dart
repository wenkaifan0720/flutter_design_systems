import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/internal/reach.dart';

import 'styled_controls_test.dart' show mount, pixel;
import 'support.dart';

typedef _Part = Widget Function(NeumorphicStyle?);
typedef _SetTheme = NeumorphicThemeData Function(
  NeumorphicThemeData,
  NeumorphicStyle,
);

/// A bank of cells' raised face (segments, latches): the part that keeps its painted height.
final _bankFace = find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter.runtimeType.toString() == '_BankFace',
);

/// Whether something under test is filled with [color]: a surface whose style resolves to it, or a bank cell's face.
bool _fills(WidgetTester tester, Color color) =>
    tester
        .widgetList<NeumorphicSurface>(find.byType(NeumorphicSurface))
        .any(
          (s) =>
              NeumorphicStyleOf([s.style, s.themeStyle], s.states).fill ==
              color,
        ) ||
    tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .any(
          (d) =>
              d.decoration is ShapeDecoration &&
              (d.decoration as ShapeDecoration).color == color,
        );

void main() {
  setUpAll(loadNeumorphicFonts);
  final parts = <(String, _Part, _SetTheme)>[
    (
      'chip',
      (s) => NeumorphicChip('Choice', style: s, onPressed: () {}),
      (t, s) => t.copyWith(chipTheme: s),
    ),
    (
      'chosen chip',
      (s) =>
          NeumorphicChip('Choice', style: s, selected: true, onPressed: () {}),
      (t, s) => t.copyWith(chipTheme: s),
    ),
    (
      'delete chip',
      (s) => NeumorphicChip(
        'Choice',
        style: s,
        onPressed: () {},
        onDeleted: () {},
      ),
      (t, s) => t.copyWith(chipTheme: s),
    ),
    (
      'choice box',
      (s) => NeumorphicChoiceBox(
        style: s,
        selected: true,
        onPressed: () {},
        padding: const EdgeInsets.all(12),
        child: const Text('Choice'),
      ),
      (t, s) => t.copyWith(optionTheme: s),
    ),
    (
      'choices',
      (s) => NeumorphicChoices(
        style: s,
        value: 'One',
        options: const [
          NeumorphicChoice('One'),
          NeumorphicChoice('Two', note: 'Note'),
        ],
        onChanged: (_) {},
      ),
      (t, s) => t.copyWith(optionTheme: s),
    ),
    (
      'select',
      (s) => NeumorphicSelect<int>(
        style: s,
        value: 1,
        options: const [NeumorphicMenuItem(1, 'Choice')],
        onChanged: (_) {},
      ),
      (t, s) => t.copyWith(textFieldTheme: s),
    ),
    (
      'checkbox',
      (s) => NeumorphicCheckbox(
        style: s,
        value: true,
        label: 'Choice',
        onChanged: (_) {},
      ),
      (t, s) => t.copyWith(checkboxTheme: s),
    ),
    (
      'check row',
      (s) => NeumorphicCheckRow(
        style: s,
        value: true,
        label: 'Choice',
        note: 'Note',
        onChanged: (_) {},
      ),
      (t, s) => t.copyWith(checkboxTheme: s),
    ),
    (
      'radio',
      (s) => NeumorphicRadioGroup<int>(
        style: s,
        label: 'Choice',
        value: 1,
        options: const [NeumorphicRadio(1, 'One'), NeumorphicRadio(2, 'Two')],
        onChanged: (_) {},
      ),
      (t, s) => t.copyWith(radioTheme: s),
    ),
    (
      'segments',
      (s) => NeumorphicSegmentedButton<int>(
        style: s,
        label: 'Choice',
        value: 1,
        segments: const [
          NeumorphicButtonSegment(1, 'One'),
          NeumorphicButtonSegment(2, 'Two'),
        ],
        onChanged: (_) {},
      ),
      (t, s) => t.copyWith(segmentedButtonTheme: s),
    ),
    (
      'latches',
      (s) => NeumorphicLatchGroup(
        style: s,
        value: 'One',
        options: const [NeumorphicLatch('One'), NeumorphicLatch('Two')],
        onChanged: (_) {},
      ),
      (t, s) => t.copyWith(segmentedButtonTheme: s),
    ),
    (
      'stepper',
      (s) => NeumorphicNumberField(
        style: s,
        value: '2',
        onDecrease: () {},
        onIncrease: () {},
      ),
      (t, s) => t.copyWith(stepperTheme: s),
    ),
  ];
  for (final (name, build, setTheme) in parts) {
    if (name == 'latches' || name == 'segments') {
      testWidgets(
        '$name keeps its painted height in a taller stretching row',
        (tester) async {
          final theme = NeumorphicThemeData.porcelain();
          await mount(tester, build(null), theme);
          final normal = tester.getSize(_bankFace.first).height;
          await mount(
            tester,
            SizedBox(
              height: 220,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [Expanded(child: build(null))],
              ),
            ),
            theme,
          );
          expect(tester.getSize(_bankFace.first).height, normal);
        },
        variant: TargetPlatformVariant({
          TargetPlatform.android,
          TargetPlatform.macOS,
        }),
      );
    }

    testWidgets('$name resolves widget fill before component theme', (
      tester,
    ) async {
      const red = NeumorphicStyle(fill: WidgetStatePropertyAll(Colors.red));
      const blue = NeumorphicStyle(fill: WidgetStatePropertyAll(Colors.blue));
      final theme = setTheme(NeumorphicThemeData.porcelain(), red);
      await mount(tester, build(null), theme);
      // A cap carries the style: a surface's own, or a bank cell's face fill.
      expect(_fills(tester, Colors.red), isTrue);
      await mount(tester, build(blue), theme);
      expect(_fills(tester, Colors.blue), isTrue);
      if (![
        'latches',
        'segments',
        'radio',
        'checkbox',
        'check row',
      ].contains(name)) {
        expect(await pixel(tester), Colors.blue.toARGB32());
      }
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
              '$name $set $densityName holds content at $width $scale',
              (tester) async {
                await mount(
                  tester,
                  build(null),
                  NeumorphicThemeData.porcelain().copyWith(density: density),
                  width: width,
                  scale: scale,
                );
                var checked = 0;
                void contained(Element element, ShapeBorder border) {
                  final render = element.findRenderObject()! as RenderBox;
                  final surface = element.widget;
                  final path = border.getOuterPath(Offset.zero & render.size);
                  for (final content
                      in find
                          .descendant(
                            of: find.byWidget(surface),
                            matching: find.byWidgetPredicate(
                              (w) =>
                                  w is Text ||
                                  w is Icon ||
                                  w is AnimatedContainer,
                            ),
                          )
                          .evaluate()) {
                    final child = content.findRenderObject()! as RenderBox;
                    if (child.size.isEmpty) continue;
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
                        reason:
                            '$name ${content.widget} $point outside ${render.size} $border',
                      );
                    }
                    checked++;
                  }
                }

                for (final element
                    in find.byType(NeumorphicSurface).evaluate()) {
                  final surface = element.widget as NeumorphicSurface;
                  final render = element.findRenderObject()! as RenderBox;
                  contained(
                    element,
                    surface.shape ??
                        (surface.round
                            ? NeumorphicCircleBorder(
                                diameter: render.size.shortestSide,
                              )
                            : NeumorphicRoundedBorder(
                                radius:
                                    surface.radius ??
                                    (surface.cast == NeumorphicSurfaceLevel.well
                                        ? NeumorphicRadii.well
                                        : NeumorphicRadii.control),
                              )),
                  );
                }
                // A bank of cells (segments, latches) holds its words inside its own raised outline.
                for (final element
                    in find
                        .byWidgetPredicate(
                          (w) =>
                              w is CustomPaint &&
                              w.painter.runtimeType.toString() == '_BankFace',
                        )
                        .evaluate()) {
                  contained(
                    element,
                    NeumorphicTheme.of(element).shapes.capsule,
                  );
                }
                expect(checked, greaterThan(0));
                for (final tap in find.byType(NeumorphicTap).evaluate()) {
                  final size = (tap.findRenderObject()! as RenderBox).size;
                  // A face drawn a chip's height takes the target in the reach round it, which passes a press in its
                  // margin to the face (a removable chip's own press beside its cross).
                  final reach = find.ancestor(
                    of: find.byElementPredicate((e) => e == tap),
                    matching: find.byType(NeumorphicReach),
                  );
                  expect(size.width, greaterThanOrEqualTo(48));
                  expect(
                    reach.evaluate().isEmpty
                        ? size.height
                        : tester.getSize(reach.first).height,
                    greaterThanOrEqualTo(48),
                  );
                }
              },
            );
          }
        }
      }
    }
  }
}
