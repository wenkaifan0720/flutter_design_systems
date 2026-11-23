// A select's list opened from the keys hangs past its field's focus ring, so the ring closes round the field (a list
// on the ring's foot left it a three-sided bracket).
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

void main() {
  for (final width in const [1440.0, 390.0]) {
    testWidgets('at $width the list clears the field\'s focus ring', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        retroDesktopApp(
          Padding(
            padding: const EdgeInsets.all(40),
            child: Align(
              alignment: Alignment.topLeft,
              child: RetroDesktopSelect<String>(
                labelText: 'Assignee',
                value: 'maya',
                focusNode: node,
                options: const [
                  RetroDesktopOption('maya', 'Maya Reed'),
                  RetroDesktopOption('sam', 'Sam Okafor'),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
          width: width,
        ),
      );
      node.requestFocus();
      await tester.pump();
      final field = tester.getRect(
        find.descendant(
          of: find.byType(RetroDesktopSelect<String>),
          matching: find.byType(RetroDesktopPressable),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      final list = tester.getRect(find.byType(RetroDesktopMenu<String>));
      final ring = RetroDesktopTheme.of(
        tester.element(find.byType(RetroDesktopSelect<String>)),
      ).focus;
      expect(
        list.top,
        greaterThanOrEqualTo(field.bottom + ring.gap + ring.width - .01),
        reason: 'the ring stands ${ring.gap} out and ${ring.width} wide',
      );
    });
  }
}
