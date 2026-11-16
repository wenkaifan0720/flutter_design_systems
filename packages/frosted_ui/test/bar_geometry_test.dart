// The phone tab bar floats on the page's gutter, and its chosen plate is set in evenly (the user, 11-14, on Harbor's
// Activity at 390 by night: the bar started ~12 in while the page's margin is 16; the plate stood 4-5 from the bar's
// top and bottom but 8-9 from its sides; its corners were not concentric with the bar's). Read from the laid-out
// boxes: the slab starts and ends on the gutter; the plate stands one inset from the slab on all four sides at either
// end of the bar; its corner is the slab's less that inset. By day and by night, two tabs and five (the act in the
// middle), left to right and right to left.
import 'package:material_ui/material_ui.dart';
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
}) async {
  t.view.physicalSize = Size(width, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
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
            child: FrostedNavigationBar(
              items: items,
              selectedIndex: selected,
              onDestinationSelected: (_) {},
            ),
          ),
        ],
      ),
    ),
  );
  await t.pumpAndSettle();
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
