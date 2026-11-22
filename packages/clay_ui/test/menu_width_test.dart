// A key's menu is as wide as its widest row, within a menu's measures, on a
// phone and on a desk: it never spreads across the window.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  setUpAll(clayLoadFonts);

  for (final width in const [390.0, 1440.0]) {
    testWidgets("a key's menu at ${width.toInt()} is as wide as its rows", (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) => ClayTheme(
            data: ClayThemeData.clay(Brightness.light),
            child: app!,
          ),
          home: Align(
            alignment: AlignmentDirectional.topStart,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ClayMenu(
                semanticLabel: 'Habit',
                items: [
                  ClayMenuItem(label: 'Edit', onPressed: () {}),
                  ClayMenuItem(label: 'Pause', onPressed: () {}),
                  ClayMenuItem(
                    label: 'Delete',
                    onPressed: () {},
                    isDestructiveAction: true,
                  ),
                ],
                builder: (context, toggle, open) => ClayIconButton(
                  onPressed: toggle,
                  icon: const Icon(LucideIcons.ellipsis),
                  tooltip: 'More',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ClayIconButton));
      await tester.pumpAndSettle();
      // The panel: the outermost clay round its rows.
      final menu = tester.getRect(
        find
            .ancestor(
              of: find.text('Pause'),
              matching: find.byType(ClaySurface),
            )
            .last,
      );
      expect(menu.width, greaterThanOrEqualTo(160));
      expect(menu.width, lessThanOrEqualTo(320));
      expect(
        menu.left,
        moreOrLessEquals(24, epsilon: 1),
        reason: 'it starts under its key',
      );
    });
  }
}
