// The phone tab bar floats on the page's gutter, and its chosen plate is set in evenly (the user, 11-14, on Harbor's
// Activity at 390 by night: the bar started ~12 in while the page's margin is 16; the plate stood 4-5 from the bar's
// top and bottom but 8-9 from its sides; its corners were not concentric with the bar's). Read from the laid-out
// boxes: the slab starts and ends on the gutter; the plate stands one inset from the slab on all four sides at either
// end of the bar; its corner is the slab's less that inset. By day and by night, two tabs and five (the act in the
// middle), left to right and right to left.
//
// Then the same read on the painted pixels at 3x (the user, 11-17, on the pub page's picture of Harbor's Activity by
// night: the plate did not sit concentric in the bar). The layout above was right all along, and so was the paint: the
// dark gap from the slab's edge to the plate's rim the same on every side and round the corners. What the user saw
// was the frame round the bar: the day's card on the same gutter ran its rim 1 outside the slab's sides and rounded
// off 9 under it, while the bar drew no fade (harbor_test reads that it no longer does); this file read only the
// bar, so it had nothing to catch. Here the slab's paint starts where the bar leaves the bare fade it stands on, and
// the plate's at its rim, where the bar with it chosen stands furthest from the bar with the other end chosen; the
// gap is the same at the side, the top and the bottom, and along the corner's diagonal it is the gap a concentric
// corner leaves. At 390 and 1440, by day and by night, two tabs and five, either end, left to right and right to left.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/internal/chosen_plate.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _two = [
  FrostedNavItem(LucideIcons.receipt, 'Activity'),
  FrostedNavItem(LucideIcons.settings, 'Settings'),
];

const _five = [
  FrostedNavItem(LucideIcons.house, 'Home'),
  FrostedNavItem(LucideIcons.chartPie, 'Spending'),
  FrostedNavItem.action(
    LucideIcons.arrowLeftRight,
    'Move',
    actionLabel: 'Move money',
  ),
  FrostedNavItem(LucideIcons.target, 'Goals'),
  FrostedNavItem(LucideIcons.creditCard, 'Cards'),
];

Future<void> _pump(
  WidgetTester t, {
  required List<FrostedNavItem> items,
  required int selected,
  required Brightness brightness,
  TextDirection direction = TextDirection.ltr,
  double width = 390,
  double ratio = 1,
  bool bare = false,
}) async {
  t.view.physicalSize = Size(width, 844) * ratio;
  t.view.devicePixelRatio = ratio;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    RepaintBoundary(
      key: _screen,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, page) => Directionality(
          textDirection: direction,
          child: FrostedHost(brightness: brightness, child: page!),
        ),
        home: Stack(
          fit: StackFit.expand,
          children: [
            const FrostedBackdropView(),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: bare
                  ? Builder(
                      builder: (context) => SizedBox(
                        height: FrostedChromeMetrics.tabBarFade,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: FrostedNavigationBar.fade(
                              context.frostedTheme,
                            ),
                          ),
                        ),
                      ),
                    )
                  : FrostedNavigationBar(
                      items: items,
                      selectedIndex: selected,
                      onDestinationSelected: (_) {},
                    ),
            ),
          ],
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

const _screen = ValueKey('screen');

/// The screen's pixels at the view's ratio, four bytes each.
Future<(Uint8List, int)> _pixels(WidgetTester t) async {
  final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(_screen));
  final image = await t.runAsync(
    () => boundary.toImage(pixelRatio: t.view.devicePixelRatio),
  );
  final bytes = await t.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  return (bytes!.buffer.asUint8List(), image!.width);
}

/// How far in along [path] (device pixels from 6 outside the slab's laid-out
/// edge) the slab's paint starts and the plate's: the slab where [other] (the
/// bar with the plate at its other end) leaves [ground] (the same screen with
/// the fade the bar stands on but no slab), the plate's at its rim, where
/// [chosen] (the plate at this end) stands furthest from [other]: the rim is
/// the plate's brightest line by day and by night (15 levels off the glass by
/// day, 155 by night), where its faint outer ring reads 3 to 10 by day, more
/// at the top under its sheen than at the sides.
(int, int) _paintedEdges(
  Uint8List chosen,
  Uint8List other,
  Uint8List ground,
  int width,
  List<(int, int)> path,
) {
  int apart(Uint8List a, Uint8List b, int i) {
    var most = 0;
    for (var k = 0; k < 3; k++) {
      most = math.max(most, (a[i + k] - b[i + k]).abs());
    }
    return most;
  }

  int? slab;
  var plate = -1;
  var most = 7;
  for (final (k, (x, y)) in path.indexed) {
    final i = (y * width + x) * 4;
    slab ??= apart(other, ground, i) >= 5 ? k : null;
    final off = apart(chosen, other, i);
    if (off > most) {
      most = off;
      plate = k;
    }
  }
  return (slab ?? -1, plate);
}

Rect _rectOf(WidgetTester t, Finder f) {
  final box = t.renderObject<RenderBox>(f);
  return MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  );
}

/// The slab: the bar material's face under the bar.
Finder get _slab => find.descendant(
  of: find.byType(FrostedNavigationBar),
  matching: find.byWidgetPredicate(
    (w) => w is FrostedFace && w.material == FrostedMaterial.bar,
  ),
);

/// The chosen tab's plate.
Finder get _plate => find.descendant(
  of: find.byType(FrostedNavigationBar),
  matching: find.byType(FrostedChosenPlate),
);

void main() {
  for (final brightness in Brightness.values) {
    for (final direction in TextDirection.values) {
      final tag = '${brightness.name}, ${direction.name}';

      for (final width in [390.0, 1440.0]) {
        testWidgets(
          'the plate is set in evenly and concentric as painted, $width wide ($tag)',
          (t) async {
            const ratio = 3.0;
            await _pump(
              t,
              items: _two,
              selected: 0,
              brightness: brightness,
              direction: direction,
              width: width,
              ratio: ratio,
              bare: true,
            );
            final (ground, _) = await _pixels(t);
            for (final items in [_two, _five]) {
              final ends = [0, items.length - 1];
              final shots = <int, Uint8List>{};
              var w = 0;
              for (final end in ends) {
                await _pump(
                  t,
                  items: items,
                  selected: end,
                  brightness: brightness,
                  direction: direction,
                  width: width,
                  ratio: ratio,
                );
                final (px, pw) = await _pixels(t);
                shots[end] = px;
                w = pw;
              }
              final slab = _rectOf(t, _slab);
              for (final end in ends) {
                final first = end == 0;
                final atLeft = first == (direction == TextDirection.ltr);
                final dir = atLeft ? 1 : -1;
                final sx =
                    ((atLeft ? slab.left : slab.right) * ratio).round() -
                    (atLeft ? 0 : 1);
                final top = (slab.top * ratio).round();
                final bottom = (slab.bottom * ratio).round() - 1;
                final middle = (slab.center.dy * ratio).round();
                // A column on the straight of the plate's top and foot, past
                // its corner, short of its glyph and word.
                final column = sx + dir * (30 * ratio).round();
                (int, int) read(List<(int, int)> path) => _paintedEdges(
                  shots[end]!,
                  shots[ends.firstWhere((e) => e != end)]!,
                  ground,
                  w,
                  path,
                );
                final side = read([
                  for (var k = -6; k < 30; k++) (sx + dir * k, middle),
                ]);
                final over = read([
                  for (var k = -6; k < 30; k++) (column, top + k),
                ]);
                final under = read([
                  for (var k = -6; k < 30; k++) (column, bottom - k),
                ]);
                final corner = read([
                  for (var k = -6; k < 40; k++) (sx + dir * k, top + k),
                ]);
                final gaps = [
                  for (final (s, p) in [side, over, under]) p - s,
                ];
                final what =
                    '${items.length} tabs, the plate at tab $end: side, top, '
                    'bottom gaps $gaps device px, corner ${corner.$2 - corner.$1} '
                    'diagonal steps';
                expect(side.$1, isNonNegative, reason: what);
                expect(
                  gaps.reduce(math.max) - gaps.reduce(math.min),
                  lessThanOrEqualTo(1),
                  reason: what,
                );
                // Along the diagonal from the slab's corner a concentric
                // plate's rim stands the side's gap away.
                expect(
                  ((corner.$2 - corner.$1) * math.sqrt2 - gaps.first).abs(),
                  lessThanOrEqualTo(1.5),
                  reason: what,
                );
              }
            }
          },
        );
      }

      testWidgets('the slab stands on the gutter ($tag)', (t) async {
        await _pump(
          t,
          items: _two,
          selected: 0,
          brightness: brightness,
          direction: direction,
        );
        final slab = _rectOf(t, _slab);
        expect(slab.left, FrostedChromeMetrics.gutter);
        expect(390 - slab.right, FrostedChromeMetrics.gutter);
      });

      for (final (items, ends) in [
        (_two, [0, 1]),
        (_five, [0, 4]),
      ]) {
        for (final selected in ends) {
          testWidgets(
            'the plate of tab $selected of ${items.length} is set in evenly, its corner concentric ($tag)',
            (t) async {
              await _pump(
                t,
                items: items,
                selected: selected,
                brightness: brightness,
                direction: direction,
              );
              final slab = _rectOf(t, _slab);
              final plate = _rectOf(t, _plate);
              // The plate's inset past the slab's edge, from the outline.
              const inset =
                  FrostedChromeMetrics.selectionInset + FrostedStrokes.regular;
              expect(plate.top - slab.top, inset);
              expect(slab.bottom - plate.bottom, inset);
              // The end the plate stands at: its start side in the reading
              // direction for the first tab, its end side for the last.
              final first = selected == 0;
              final atLeft = first == (direction == TextDirection.ltr);
              if (atLeft) {
                expect(plate.left - slab.left, inset);
              } else {
                expect(slab.right - plate.right, inset);
              }
              final plateFace = t.widget<FrostedChosenPlate>(_plate);
              final slabFace = t.widget<FrostedFace>(_slab);
              expect(
                plateFace.radius.topLeft.x,
                slabFace.radius.topLeft.x - inset,
              );
            },
          );
        }
      }
    }
  }
}
