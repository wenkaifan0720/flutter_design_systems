import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/controls.dart'
    show NeumorphicTapFace;
import 'package:neumorphism_ui/src/neumorphism/internal/panel.dart'
    show NeumorphicPanel;

import 'support.dart';

void main() {
  for (final direction in TextDirection.values) {
    for (final withIcon in [false, true]) {
      testWidgets('the split menu starts at the full button edge '
          '($direction, icons: $withIcon)', (tester) async {
        tester.view.physicalSize = const Size(2880, 1800);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          neumorphicApp(
            Center(
              child: NeumorphicSplitButton(
                'Save',
                onPressed: () {},
                actions: [
                  NeumorphicSplitAction('Save a copy', onPressed: () {}),
                  if (withIcon)
                    NeumorphicSplitAction(
                      'Save a copy in another folder',
                      icon: NeumorphicGlyphs.check,
                      onPressed: () {},
                    ),
                ],
              ),
            ),
            direction: direction,
            width: 1440,
          ),
        );
        await tester.pumpAndSettle();
        final halves = find.byType(NeumorphicTapFace);
        final button = tester
            .getRect(halves.first)
            .expandToInclude(tester.getRect(halves.last));
        await tester.tap(find.byIcon(NeumorphicGlyphs.chevronDown));
        await tester.pumpAndSettle();
        final menu = tester.getRect(find.byType(NeumorphicPanel));
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        final ltr = direction == TextDirection.ltr;
        expect(
          ltr ? menu.left : menu.right,
          closeTo(ltr ? button.left : button.right, .5),
        );
        expect(menu.width, greaterThanOrEqualTo(button.width - .5));
        if (withIcon) expect(menu.width, greaterThan(button.width));
      });
    }
  }
}
