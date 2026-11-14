import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

Widget _app(void Function(BuildContext context) onPress) => MaterialApp(
  builder: (context, child) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: child!,
  ),
  home: MinimalScaffold(
    body: Builder(
      builder: (context) =>
          MinimalButton('Go', onPressed: () => onPress(context)),
    ),
  ),
);

void main() {
  testWidgets('a toast shows, then clears itself', (tester) async {
    await tester.pumpWidget(
      _app((context) => showMinimalSnackBar(context, 'Habit archived')),
    );
    await tester.tap(find.text('Go'));
    await tester.pump();
    expect(find.text('Habit archived'), findsOneWidget);
    await tester.pump(MinimalChromeMetrics.toast);
    await tester.pumpAndSettle();
    expect(find.text('Habit archived'), findsNothing);
  });

  testWidgets('its one action runs and clears it at once', (tester) async {
    var undone = 0;
    await tester.pumpWidget(
      _app(
        (context) => showMinimalSnackBar(
          context,
          'Habit archived',
          actionLabel: 'Undo',
          onAction: () => undone += 1,
        ),
      ),
    );
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(undone, 1);
    await tester.pumpAndSettle();
    expect(find.text('Habit archived'), findsNothing);
    // The timer that would have cleared it finds it already gone.
    await tester.pump(MinimalChromeMetrics.toastWithAction);
  });

  testWidgets('it stands above the shell\'s bar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MinimalHost(
          light: MinimalThemeData.preset('standard', Brightness.light),
          dark: MinimalThemeData.preset('standard', Brightness.dark),
          child: child!,
        ),
        home: MinimalShellInsets(
          allowance: 120,
          child: MinimalScaffold(
            body: Builder(
              builder: (context) => MinimalButton(
                'Go',
                onPressed: () => showMinimalSnackBar(context, 'Saved'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    final screen = tester.getSize(find.byType(MaterialApp));
    final toast = tester.getRect(find.text('Saved'));
    expect(screen.height - toast.bottom, greaterThan(120));
    await tester.pump(MinimalChromeMetrics.toast);
  });
}
