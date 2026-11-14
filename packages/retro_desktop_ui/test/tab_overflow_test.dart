// Folder tabs too wide for their room scroll sideways and show it: a pair of arrows at the row's end steps the tabs
// into view (self-review round 3: at twice the text size on a phone the third tab stood cut at the panel's edge, with
// nothing to say there was more). Tabs that fit show no arrows.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

Widget _tabs() => Padding(
  padding: const EdgeInsets.all(16),
  child: RetroDesktopTabBar(
    tabs: const ['Today', 'Soon', 'Later'],
    counts: const ['3', '4', '5'],
    onChanged: (_) {},
    child: const Text('One row'),
  ),
);

Finder _arrow(String label) => find.byWidgetPredicate(
  (w) => w is RetroDesktopIconButton && w.label == label,
);

void main() {
  setUpAll(() async {
    await loadRetroDesktopFonts();
  });

  for (final direction in TextDirection.values) {
    testWidgets('tabs too wide for a phone at twice the text size show '
        'arrows that step them, ${direction.name}', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        retroDesktopApp(_tabs(), width: 390, scale: 2, direction: direction),
      );
      await tester.pump();
      expect(_arrow('Earlier tabs'), findsOneWidget);
      expect(_arrow('Later tabs'), findsOneWidget);
      final strip = find.descendant(
        of: find.byType(RetroDesktopTabBar),
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(strip).position;
      expect(position.pixels, 0);
      expect(position.maxScrollExtent, greaterThan(0));
      expect(
        tester.widget<RetroDesktopIconButton>(_arrow('Earlier tabs')).onPressed,
        isNull,
        reason: 'at the start there is nothing earlier',
      );
      while (tester
              .widget<RetroDesktopIconButton>(_arrow('Later tabs'))
              .onPressed !=
          null) {
        await tester.tap(_arrow('Later tabs'));
        await tester.pump();
      }
      expect(position.pixels, position.maxScrollExtent);
      // The last tab stands whole in the strip's room, its arrows beside it.
      final room = tester.getRect(strip);
      final last = tester.getRect(find.text('Later'));
      expect(last.left, greaterThanOrEqualTo(room.left - .5));
      expect(last.right, lessThanOrEqualTo(room.right + .5));
      final arrows = tester.getRect(_arrow('Later tabs'));
      expect(
        direction == TextDirection.ltr
            ? arrows.left >= room.right - .5
            : arrows.right <= room.left + .5,
        isTrue,
        reason: 'the arrows stand past the strip, at its end',
      );
      await tester.tap(_arrow('Earlier tabs'));
      await tester.pump();
      expect(position.pixels, lessThan(position.maxScrollExtent));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tabs that fit show no arrows', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(retroDesktopApp(_tabs(), width: 1440));
    await tester.pump();
    expect(_arrow('Earlier tabs'), findsNothing);
    expect(_arrow('Later tabs'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
