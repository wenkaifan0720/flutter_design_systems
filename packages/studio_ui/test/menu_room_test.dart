// A menu bar low on a phone (a toolbar at the screen's foot) opens its menus
// on the side with the room: above the bar when the room under it is short
// of what the menu wants, rather than a sliver scrolling under it.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

void main() {
  for (final above in [700.0, 740.0, 780.0]) {
    testWidgets(
      'a menu bar ${above.round()} down a phone opens its menu above it',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final bar = StudioMenuBar(
          menus: [
            StudioMenuBarMenu('Clip', [
              for (var i = 0; i < 12; i++)
                StudioMenuItem(label: 'Choice $i', onPressed: () {}),
            ]),
          ],
        );
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, app) => StudioHost(child: app!),
            home: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: above),
                  bar,
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final trigger = tester.getRect(find.byWidget(bar));
        await tester.tap(find.text('Clip'));
        await tester.pumpAndSettle();
        // The menu's first and last rows, both on screen above the bar.
        final first = tester.getRect(find.text('Choice 0'));
        final last = tester.getRect(find.text('Choice 11'));
        expect(first.top, greaterThanOrEqualTo(0));
        expect(
          last.bottom,
          lessThanOrEqualTo(trigger.top),
          reason: 'the menu stayed under its bar: $first..$last, bar $trigger',
        );
      },
    );
  }
}
