import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'styled_controls_test.dart' show mount;
import 'support.dart';

void main() {
  setUpAll(loadNeumorphicFonts);
  final parts = <(String, Widget Function())>[
    (
      'rail link',
      () => NeumorphicRailLink(
        label: 'Room',
        figure: '21',
        selected: true,
        onPressed: () {},
      ),
    ),
    (
      'photo placeholder',
      () =>
          const NeumorphicMedia(label: 'A room', glyph: NeumorphicGlyphs.house),
    ),
    (
      'success state',
      () => const NeumorphicSuccessState(title: 'Saved', message: 'Ready'),
    ),
    (
      'error state',
      () => NeumorphicErrorState(
        title: 'Try again',
        message: 'Disconnected',
        onRetry: () {},
      ),
    ),
    (
      'two-way bars',
      () => const NeumorphicTwoWayBars(
        above: [2, 4, 1],
        below: {1: 1},
        slots: 3,
        peak: '4',
        now: 1.5,
        nowLabel: 'Now',
        labels: {0: 'Start', 2: 'End'},
        keys: [NeumorphicLegendItem('Used')],
      ),
    ),
    (
      'column bars',
      () => const NeumorphicColumnBars(
        values: [2, 4, 1],
        labels: ['Mon', 'Tue', 'Wed'],
        now: 2,
        forecast: 3,
      ),
    ),
    (
      'step line',
      () => const NeumorphicStepLine(
        readings: [(0, 2), (12, 4), (24, 3)],
        steps: [(0, 2), (12, 3), (24, 3)],
        now: 12,
        xMax: 24,
        yMin: 0,
        yMax: 5,
        yTicks: [1, 3, 5],
        yLabel: 'kW',
        xLabels: [(0, '00'), (12, '12'), (24, '24')],
        keys: [NeumorphicLegendItem('Used')],
        note: 'Today',
      ),
    ),
    (
      'relief ground',
      () => const NeumorphicRelief(
        title: 'Home',
        courses: [
          NeumorphicCourse('Rooms', [
            NeumorphicBay(name: 'Desk', figure: '21'),
          ]),
        ],
        ground: [
          NeumorphicGroundNote('All quiet', icon: NeumorphicGlyphs.house),
        ],
      ),
    ),
  ];
  for (final (name, build) in parts) {
    for (final set in const ['look']) {
      for (final (densityName, density) in [
        ('standard', NeumorphicDensity.standard),
        ('comfortable', NeumorphicDensity.comfortable),
        ('compact', NeumorphicDensity.compact),
      ]) {
        for (final width in [120.0, 240.0, 390.0]) {
          for (final scale in [1.0, 1.3]) {
            testWidgets(
              '$name $set $densityName contains paint at $width $scale',
              (tester) async {
                await mount(
                  tester,
                  SingleChildScrollView(child: build()),
                  NeumorphicThemeData.porcelain().copyWith(density: density),
                  width: width,
                  scale: scale,
                );
                var checked = 0;
                void contained(Element plate, OutlinedBorder border) {
                  final render = plate.findRenderObject()! as RenderBox;
                  final path = border.getOuterPath(Offset.zero & render.size);
                  for (final node
                      in find
                          .descendant(
                            of: find.byWidget(plate.widget),
                            matching: find.byWidgetPredicate(
                              (w) =>
                                  w is Text ||
                                  w is Icon ||
                                  (w is CustomPaint &&
                                      w.painter.runtimeType.toString() ==
                                          '_ColumnPainter'),
                            ),
                          )
                          .evaluate()) {
                    final child = node.findRenderObject()! as RenderBox;
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
                            '$name ${node.widget} $bounds at $point outside ${render.size} $border',
                      );
                    }
                    checked++;
                  }
                }

                for (final e in find.byType(NeumorphicSurface).evaluate()) {
                  final surface = e.widget as NeumorphicSurface,
                      render = e.findRenderObject()! as RenderBox;
                  final border =
                      surface.shape ??
                      (surface.round
                          ? NeumorphicCircleBorder(
                              diameter: render.size.shortestSide,
                            )
                          : NeumorphicRoundedBorder(
                              radius:
                                  surface.radius ??
                                  (surface.cast == NeumorphicSurfaceLevel.slab
                                      ? NeumorphicRadii.slab
                                      : surface.cast ==
                                            NeumorphicSurfaceLevel.well
                                      ? NeumorphicRadii.well
                                      : NeumorphicRadii.control),
                            ));
                  contained(e, border);
                }
                expect(checked, greaterThan(0));
              },
            );
          }
        }
      }
    }
  }
}
