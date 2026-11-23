// A dialog's and a sheet's keys stand in one row or one column of one width,
// the main key on top when stacked (DesignDialogActionsCheck), each key's
// words shown whole: at 320 and 390 wide, at 1x and 2x text.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

Widget _app(void Function(BuildContext context) open) => MaterialApp(
  builder: (context, app) =>
      ApplianceHost(brightness: Brightness.light, child: app!),
  home: Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: ApplianceButton('Open', onPressed: () => open(context)),
      ),
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

void _wordsWhole(WidgetTester tester, List<String> actions) {
  for (final a in actions) {
    final words = tester.renderObject<RenderParagraph>(find.text(a));
    expect(
      words.didExceedMaxLines,
      isFalse,
      reason: '"$a" shows its words whole',
    );
  }
}

List<Widget> _keys(List<String> actions) => [
  for (final (i, a) in actions.indexed)
    i == actions.length - 1
        ? ApplianceButton.filled(a, onPressed: () {})
        : ApplianceButton(a, onPressed: () {}),
];

void main() {
  setUpAll(applianceLoadFonts);
  const sets = [
    ['Keep', 'Remove'],
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
              (context) => showApplianceDialog<void>(
                context: context,
                builder: (context) => ApplianceDialog(
                  title: 'Leave without saving?',
                  content: const Text('Your basket keeps its goods.'),
                  actions: _keys(actions),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          DesignDialogActionsCheck(
            look: 'Appliance',
            actions: actions,
          ).check(tester.element(find.byType(ApplianceDialog))).verify();
          _wordsWhole(tester, actions);
        });

        testWidgets('a sheet: ${actions.join(', ')} at $at', (tester) async {
          _view(tester, width, scale);
          await tester.pumpWidget(
            _app(
              (context) => showApplianceSheet<void>(
                context: context,
                builder: (context) => ApplianceSheet(
                  title: 'Delivery',
                  footer: _keys(actions),
                  child: const Text('Tuesday, between 8 and 10'),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          DesignDialogActionsCheck(
            look: 'Appliance',
            actions: actions,
          ).check(tester.element(find.byType(ApplianceSheet))).verify();
          _wordsWhole(tester, actions);
        });

        testWidgets('a side sheet: ${actions.join(', ')} at $at', (
          tester,
        ) async {
          _view(tester, width, scale);
          await tester.pumpWidget(
            _app(
              (context) => showApplianceSideSheet<void>(
                context: context,
                title: 'Filters',
                footer: _keys(actions),
                builder: (context) => const Text('In stock only'),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          DesignDialogActionsCheck(
            look: 'Appliance',
            actions: actions,
          ).check(tester.element(find.byType(ApplianceSideSheet))).verify();
          _wordsWhole(tester, actions);
        });
      }
    }
  }
}
