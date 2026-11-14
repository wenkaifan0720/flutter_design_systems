import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'styled_controls_test.dart' show mount;
import 'support.dart';

void main() {
  setUpAll(loadNeumorphicFonts);
  final parts = <(String, Widget Function())>[
    (
      'dial',
      () => const NeumorphicDial(
        value: 21,
        min: 10,
        max: 30,
        figure: '21°',
        label: 'Room',
        sub: 'Now',
      ),
    ),
    (
      'compact dial',
      () => const NeumorphicDial(
        value: 21,
        figure: '21°',
        label: 'Room',
        compact: true,
      ),
    ),
    (
      'span',
      () => const NeumorphicSpanDial(
        start: '09:00',
        end: '10:00',
        elapsed: 20,
        total: 60,
        figure: '40',
        unit: 'min',
        tag: 'Left',
      ),
    ),
    (
      'compact span',
      () => const NeumorphicSpanDial(
        start: '09:00',
        end: '10:00',
        elapsed: 20,
        total: 60,
        figure: '40',
        compact: true,
      ),
    ),
    ('mini dial', () => const NeumorphicMiniDial(value: 21, figure: '21°')),
    (
      'gauge',
      () => const NeumorphicGauge(value: 21, figure: '21°', name: 'Room'),
    ),
  ];
  for (final (name, build) in parts) {
    for (final set in const ['look']) {
      for (final density in [
        NeumorphicDensity.standard,
        NeumorphicDensity.comfortable,
        NeumorphicDensity.compact,
      ]) {
        for (final width in [120.0, 240.0, 390.0]) {
          for (final scale in [1.0, 1.3]) {
            testWidgets(
              '$name $set $density $width $scale contains its inset readout',
              (tester) async {
                await mount(
                  tester,
                  SingleChildScrollView(child: build()),
                  NeumorphicThemeData.porcelain().copyWith(density: density),
                  width: width,
                  scale: scale,
                );
                final paints = find
                    .byWidgetPredicate(
                      (w) =>
                          w is CustomPaint &&
                          [
                            '_DialPainter',
                            '_MiniPainter',
                          ].contains(w.painter.runtimeType.toString()),
                    )
                    .evaluate();
                expect(paints, isNotEmpty);
                for (final paint in paints) {
                  Element? stack;
                  paint.visitAncestorElements((element) {
                    if (element.widget is Stack) {
                      stack = element;
                      return false;
                    }
                    return true;
                  });
                  expect(stack, isNotNull);
                  final face = stack!.findRenderObject()! as RenderBox;
                  final path = const NeumorphicCircleBorder().getOuterPath(
                    Offset.zero & face.size,
                  );
                  // Captions moved outside the circle are deliberately outside
                  // this Stack. Every readout still inside it must fit the face.
                  for (final node
                      in find
                          .descendant(
                            of: find.byWidget(stack!.widget),
                            matching: find.byWidgetPredicate(
                              (w) => w is Text || w is Icon,
                            ),
                          )
                          .evaluate()) {
                    final child = node.findRenderObject()! as RenderBox;
                    final bounds = MatrixUtils.transformRect(
                      child.getTransformTo(face),
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
                            '${node.widget}: $bounds at $point outside ${face.size}',
                      );
                    }
                  }
                }
              },
            );
          }
        }
      }
    }
  }
}
