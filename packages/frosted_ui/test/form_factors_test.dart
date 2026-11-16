// A tablet is not a stretched phone (the form-factors check, coordinator
// msg_5e8ccd896566): from FrostedBreakpoints.medium (600) a sheet stands as
// the centred card it is on the desktop, and the tab bar hugs its tabs in the
// middle of the foot; on a phone both span the window, as before.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';

const _tabs = [
  FrostedNavItem(FrostedGlyphs.check, 'Activity'),
  FrostedNavItem(FrostedGlyphs.close, 'Settings'),
];

Widget _app() => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) => FrostedHost(child: child!),
  home: Builder(
    builder: (context) => Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: GestureDetector(
            onTap: () => unawaited(
              FrostedSheet.show<void>(
                context,
                title: 'Filters',
                builder: (_) => [const Text('Sheet body')],
              ),
            ),
            child: const Text('Open'),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: FrostedNavigationBar(
            items: _tabs,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
          ),
        ),
      ],
    ),
  ),
);

Rect _slab(WidgetTester tester) => tester.getRect(
  find
      .descendant(
        of: find.byType(FrostedNavigationBar),
        matching: find.byType(FrostedFace),
      )
      .first,
);

Future<Rect> _sheet(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  expect(find.text('Sheet body'), findsOneWidget);
  return tester.getRect(find.byType(FrostedSheetCard));
}

void main() {
  for (final (size, phone) in [
    (const Size(390, 844), true),
    (const Size(768, 1024), false),
    (const Size(1023, 768), false),
  ]) {
    testWidgets('at ${size.width.toInt()} wide a sheet '
        '${phone ? 'spans the foot' : 'stands as the centred card'}, and '
        'the tab bar ${phone ? 'spans the window' : 'hugs its tabs'}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app());

      final slab = _slab(tester);
      if (phone) {
        expect(slab.width, size.width - 2 * FrostedChromeMetrics.tabBarSide);
      } else {
        expect(slab.width, 2 * FrostedChromeMetrics.tabBarTabMedium);
        expect(slab.center.dx, size.width / 2);
      }

      final card = await _sheet(tester);
      if (phone) {
        expect(card.width, size.width);
        expect(card.bottom, size.height);
      } else {
        expect(
          card.width,
          lessThanOrEqualTo(FrostedChromeMetrics.sheetWideWidth),
        );
        expect(card.center.dx, size.width / 2);
        expect(card.bottom, lessThan(size.height), reason: 'not at the foot');
      }
    });
  }
}
