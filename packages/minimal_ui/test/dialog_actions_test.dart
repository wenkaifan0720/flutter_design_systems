// A dialog's and a sheet's actions stand in one row while they fit, else in
// one column of one width with the confirming action on top, raised and in
// place, at 320 and 390 wide, at 1x and 2x text (DesignDialogActionsCheck).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_review/ui_core_review.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

Widget _app(void Function(BuildContext context) open) => MaterialApp(
  builder: (context, app) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: app!,
  ),
  home: Scaffold(
    body: Builder(
      builder: (context) =>
          Center(child: MinimalButton('Open', onPressed: () => open(context))),
    ),
  ),
);

void _view(WidgetTester tester, double width, double scale) {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  const sets = [
    ['Keep', 'Delete'],
    ['Cancel', 'Discard', 'Save changes'],
  ];
  for (final actions in sets) {
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        final at = '${width.round()} wide, ${scale}x text';
        testWidgets('a dialog: ${actions.join(', ')} at $at', (tester) async {
          _view(tester, width, scale);
          await tester.pumpWidget(
            _app(
              (context) => showMinimalDialog<void>(
                context,
                builder: (context) => MinimalDialog(
                  title: 'Leave without saving?',
                  message: 'Your changes to this habit go.',
                  actions: [
                    for (final (i, a) in actions.indexed)
                      RawDialogAction(
                        label: a,
                        onPressed: () {},
                        isDefaultAction: i == actions.length - 1,
                        isDestructiveAction: a == 'Delete' || a == 'Discard',
                      ),
                  ],
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          DesignDialogActionsCheck(
            look: 'Minimal',
            actions: actions,
          ).check(tester.element(find.byType(MinimalDialog))).verify();
        });

        testWidgets('a dialog in place: ${actions.join(', ')} at $at', (
          tester,
        ) async {
          _view(tester, width, scale);
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, app) => MinimalHost(
                light: MinimalThemeData.preset('standard', Brightness.light),
                dark: MinimalThemeData.preset('standard', Brightness.dark),
                brightness: Brightness.light,
                child: app!,
              ),
              home: Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: MinimalDialog(
                      title: 'Leave without saving?',
                      message: 'Your changes to this habit go.',
                      actions: [
                        for (final (i, a) in actions.indexed)
                          RawDialogAction(
                            label: a,
                            onPressed: () {},
                            isDefaultAction: i == actions.length - 1,
                            isDestructiveAction:
                                a == 'Delete' || a == 'Discard',
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          DesignDialogActionsCheck(
            look: 'Minimal',
            actions: actions,
          ).check(tester.element(find.byType(MinimalDialog))).verify();
        });
      }
    }
  }

  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      final at = '${width.round()} wide, ${scale}x text';
      testWidgets('a sheet: Cancel, Save changes at $at', (tester) async {
        _view(tester, width, scale);
        await tester.pumpWidget(
          _app(
            (context) => showMinimalBottomSheet<void>(
              context,
              title: 'Rename habit',
              leading: const MinimalSheetAction.cancel('Cancel'),
              trailing: MinimalSheetAction(
                'Save changes',
                isDefaultAction: true,
                onPressed: () {},
              ),
              builder: (_) => const Text('Morning walk'),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        const DesignDialogActionsCheck(
          look: 'Minimal',
          actions: ['Cancel', 'Save changes'],
        ).check(tester.element(find.text('Morning walk'))).verify();
      });
    }
  }
}
