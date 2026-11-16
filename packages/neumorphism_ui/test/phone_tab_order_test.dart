// On a phone the page stands over the app's tab bar, and Tab walks the page to its end before the bar: the rows the
// page has scrolled below the bar's top come before the bar's places, never one row, then the whole bar, then the next.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void main() {
  testWidgets('Tab walks the page to its end, then the tab bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const rows = ['a', 'b', 'c', 'd', 'e', 'f'];
    await tester.pumpWidget(
      neumorphicApp(
        Column(
          children: [
            Expanded(
              child: NeumorphicScaffold(
                body: Column(
                  children: [
                    for (final r in rows)
                      Padding(
                        // Tall enough that the last rows start below the bar's top.
                        padding: const EdgeInsets.only(bottom: 180),
                        child: NeumorphicButton(r, onPressed: () {}),
                      ),
                  ],
                ),
              ),
            ),
            NeumorphicNavigationBar(
              items: const [
                NeumorphicNavItem(
                  label: 'Home',
                  icon: NeumorphicGlyphs.settings,
                ),
                NeumorphicNavItem(
                  label: 'Shop',
                  icon: NeumorphicGlyphs.settings,
                ),
              ],
              onDestinationSelected: (_) {},
            ),
          ],
        ),
      ),
    );
    final walked = <String>[];
    for (var i = 0; i < rows.length + 2; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      walked.add(
        FocusManager.instance.primaryFocus!.context!
            .findAncestorWidgetOfExactType<NeumorphicTap>()!
            .label!,
      );
    }
    expect(walked, [...rows, 'Home', 'Shop']);
  });
}
