// A dialog's keys stand in one row while they fit, else in one column of one
// width with the confirming key on top, at 320 and 390 wide, at 1x and 2x
// text (DesignDialogActionsCheck); a sheet's footer keys the same.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:ui_core_test/ui_core_test.dart';

Widget _keys(List<String> actions) => KeycapDialog(
  title: 'Leave without saving?',
  content: const Text('Your changes to this note go.'),
  actions: [
    for (final (i, a) in actions.indexed)
      if (i == actions.length - 1)
        KeycapButton.accent(onPressed: () {}, child: Text(a))
      else
        KeycapButton(onPressed: () {}, child: Text(a)),
  ],
);

void main() {
  const sets = [
    ['Keep', 'Delete'],
    ['Cancel', 'Discard', 'Save changes'],
  ];
  for (final sheet in [false, true]) {
    for (final actions in sets) {
      for (final width in [320.0, 390.0]) {
        for (final scale in [1.0, 2.0]) {
          testWidgets('a ${sheet ? 'sheet' : 'dialog'}: ${actions.join(', ')} '
              'at ${width.round()} wide, ${scale}x text', (tester) async {
            tester.view.physicalSize = Size(width, 844);
            tester.view.devicePixelRatio = 1;
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.view.reset);
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            await tester.pumpWidget(
              MaterialApp(
                builder: (context, app) =>
                    KeycapHost(brightness: Brightness.light, child: app!),
                home: Builder(
                  builder: (context) => Center(
                    child: KeycapButton(
                      onPressed: () => sheet
                          ? showKeycapBottomSheet<void>(
                              context: context,
                              title: 'Leave without saving?',
                              builder: (context) =>
                                  const Text('Your changes to this note go.'),
                              footer: [
                                for (final (i, a) in actions.indexed)
                                  if (i == actions.length - 1)
                                    KeycapButton.accent(
                                      onPressed: () {},
                                      child: Text(a),
                                    )
                                  else
                                    KeycapButton(
                                      onPressed: () {},
                                      child: Text(a),
                                    ),
                              ],
                            )
                          : showKeycapDialog<void>(
                              context: context,
                              builder: (context) => _keys(actions),
                            ),
                      child: const Text('Open'),
                    ),
                  ),
                ),
              ),
            );
            await tester.tap(find.text('Open'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            DesignDialogActionsCheck(look: 'Keycap', actions: actions)
                .check(
                  tester.element(
                    find.byType(sheet ? KeycapSheet : KeycapDialog),
                  ),
                )
                .verify();
          });
        }
      }
    }
  }
}
