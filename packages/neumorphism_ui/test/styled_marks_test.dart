import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/chart.dart' show NeumorphicChart;

import 'styled_controls_test.dart' show mount;
import 'support.dart';

void main() {
  setUpAll(loadNeumorphicFonts);
  final parts = <(String, Widget Function())>[
    (
      'view tabs',
      () => NeumorphicTabBar(tabs: const ['Home', 'Week'], onChanged: (_) {}),
    ),
    (
      'navigation bar',
      () => NeumorphicNavigationBar(
        items: const [
          NeumorphicNavItem(label: 'Home', icon: NeumorphicGlyphs.house),
          NeumorphicNavItem(label: 'Week', icon: NeumorphicGlyphs.calendar),
        ],
        onDestinationSelected: (_) {},
      ),
    ),
    (
      'navigation drawer',
      () => NeumorphicNavigationDrawer(
        items: const [
          NeumorphicNavItem(label: 'Home', icon: NeumorphicGlyphs.house),
          NeumorphicNavItem(label: 'Week', icon: NeumorphicGlyphs.calendar),
        ],
        onDestinationSelected: (_) {},
      ),
    ),
    ('avatar', () => const NeumorphicAvatar('NWA')),
    (
      'face pile',
      () => const NeumorphicAvatarGroup([
        NeumorphicFace('NW'),
        NeumorphicFace('AK'),
      ], total: 3),
    ),
    ('monogram', () => const NeumorphicMonogram('NWA')),
    ('icon well', () => const NeumorphicIconWell(NeumorphicGlyphs.plus)),
    ('badge', () => const NeumorphicBadge(123)),
    ('tag', () => const NeumorphicTag('Content')),
    ('notice', () => const NeumorphicBanner('Content', title: 'Title')),
    (
      'grouped list',
      () => const NeumorphicListSection(
        label: 'Group',
        children: [Text('Content')],
      ),
    ),
    (
      'table',
      () => const NeumorphicTable(
        columns: [NeumorphicTableColumn('Key')],
        rows: [
          NeumorphicTableRow(['Content'], selected: true),
        ],
      ),
    ),
    ('nudge', () => const NeumorphicNudge(title: 'Content', note: 'Note')),
    ('empty', () => const NeumorphicEmptyState(title: 'Content', body: 'Note')),
    ('note', () => const NeumorphicNote(title: 'Content', subtitle: 'Note')),
    (
      'choice with default padding',
      () => NeumorphicChoiceBox(onPressed: () {}, child: const Text('Choice')),
    ),
    (
      'stats',
      () => const NeumorphicStats([
        NeumorphicStat('Hours', '8', 'h'),
        NeumorphicStat('Tasks', '4'),
      ]),
    ),
    (
      'chart',
      () => const NeumorphicChart(
        label: 'Hours',
        series: [
          NeumorphicChartSeries('Work', [2, 4, 3]),
        ],
        labels: ['Mon', 'Tue', 'Wed'],
      ),
    ),
    (
      'picture card',
      () => const NeumorphicPictureCard(
        title: 'Room',
        subtitle: 'Quiet',
        glyph: NeumorphicGlyphs.house,
      ),
    ),
    (
      'day tray',
      () => const NeumorphicDayTray(
        from: 8,
        to: 10,
        events: [
          NeumorphicTrayEvent(
            start: '08:00',
            end: '09:00',
            title: 'Reading',
            subtitle: 'At home',
          ),
        ],
        free: [NeumorphicTrayFree('09:00', '10:00', 'Free')],
      ),
    ),
    (
      'month',
      () => const NeumorphicMonth(
        year: 2026,
        month: 11,
        today: 6,
        marked: {6, 7},
      ),
    ),
    (
      'month actions',
      () => NeumorphicMonth(
        year: 2026,
        month: 11,
        today: 6,
        marked: const {6, 7},
        onDay: (_) {},
      ),
    ),
    (
      'push bank',
      () => NeumorphicPushGroup(
        items: [
          NeumorphicPush(
            icon: NeumorphicGlyphs.sun,
            label: 'Day',
            note: 'Until six',
            onPressed: () {},
          ),
          NeumorphicPush(
            icon: NeumorphicGlyphs.moon,
            label: 'Night',
            selected: true,
            onPressed: () {},
          ),
        ],
      ),
    ),
    (
      'date picker',
      () =>
          NeumorphicDatePicker(value: DateTime(2026, 11, 6), onChanged: (_) {}),
    ),
    (
      'time picker',
      () => NeumorphicTimePicker(
        value: const NeumorphicTime(12, 30),
        minuteStep: 30,
        onChanged: (_) {},
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
                              (w) => w is Text || w is Icon,
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
                // A bank of cells (tabs, segments, latches) holds its words inside its own raised outline.
                for (final e
                    in find
                        .byWidgetPredicate(
                          (w) =>
                              w is CustomPaint &&
                              w.painter.runtimeType.toString() == '_BankFace',
                        )
                        .evaluate()) {
                  contained(e, NeumorphicTheme.of(e).shapes.capsule);
                }
                if (name == 'badge') {
                  final plate = find
                      .descendant(
                        of: find.byType(NeumorphicBadge),
                        matching: find.byWidgetPredicate(
                          (w) =>
                              w is DecoratedBox &&
                              w.decoration is ShapeDecoration,
                        ),
                      )
                      .first
                      .evaluate()
                      .single;
                  contained(
                    plate,
                    ((plate.widget as DecoratedBox).decoration
                                as ShapeDecoration)
                            .shape
                        as OutlinedBorder,
                  );
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
