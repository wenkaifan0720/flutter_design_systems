// ClayScaffold's brand keeps its own size: a mark stands at the start of a
// sidebar's head and in the middle of a rail's, as wide as it is. The
// sidebar had stretched it across its width, so a square mark became a long
// bar with a small glyph in it.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  const mark = Key('mark');
  for (final width in [800.0, 1440.0]) {
    for (final withAction in [false, true]) {
      for (final direction in TextDirection.values) {
        testWidgets(
          'the brand keeps its size at ${width.round()}, '
          '${withAction ? 'with' : 'without'} an action (${direction.name})',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = Size(width, 900);
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              MaterialApp(
                builder: (context, app) => ClayTheme(
                  data: ClayThemeData.clay(Brightness.light),
                  child: app!,
                ),
                home: Directionality(
                  textDirection: direction,
                  child: ClayScaffold(
                    destinations: const [
                      ClayDestination(icon: IconData(0xe000), label: 'Books'),
                      ClayDestination(
                        icon: IconData(0xe001),
                        label: 'Settings',
                      ),
                    ],
                    onDestinationSelected: (_) {},
                    brand: const SizedBox.square(key: mark, dimension: 40),
                    action: withAction
                        ? ClayButton.filled('New', onPressed: () {})
                        : null,
                    body: const ClayScreen(body: SizedBox()),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.getSize(find.byKey(mark)), const Size(40, 40));
            if (width >= ClayMetrics.sidebarBreakpoint) {
              final at = tester.getRect(find.byKey(mark));
              final place = tester.getRect(find.text('Books'));
              final rtl = direction == TextDirection.rtl;
              // At the head's start, toward the places' words.
              expect(
                rtl ? at.right > place.right - 40 : at.left < place.left + 40,
                isTrue,
                reason: 'the mark ($at) is not at the start, by $place',
              );
            }
          },
        );
      }
    }
  }
}
