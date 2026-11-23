// A dialog's actions stand in one row while they fit, else in one column of
// one width with the confirming action on top, at 320 and 390 wide, at 1x
// and 2x text (DesignDialogActionsCheck).
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:ui_core_test/ui_core_test.dart';

void main() {
  const sets = [
    ['Keep', 'Delete'],
    ['Cancel', 'Discard', 'Save changes'],
  ];
  for (final actions in sets) {
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('${actions.join(', ')} at ${width.round()} wide, '
            '${scale}x text', (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, app) => ClayTheme(
                data: ClayThemeData.clay(Brightness.light),
                child: app!,
              ),
              home: Builder(
                builder: (context) => Center(
                  child: ClayButton(
                    'Open',
                    onPressed: () => showClayDialog<void>(
                      context: context,
                      builder: (context) => ClayDialog(
                        title: 'Leave without saving?',
                        content: const Text('Your changes to this habit go.'),
                        actions: [
                          for (final (i, a) in actions.indexed)
                            ClayDialogAction(
                              label: a,
                              onPressed: () {},
                              isDefaultAction: i == actions.length - 1,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          DesignDialogActionsCheck(
            look: 'Clay',
            actions: actions,
          ).check(tester.element(find.byType(ClayDialog))).verify();
        });
      }
    }
  }
}
