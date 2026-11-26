// Gloss installs as the README shows, in the builder of any app widget:
// MaterialApp, CupertinoApp and WidgetsApp, by day and by night. A page, a
// dialog and a toast work under each; so does the README's smallest app.
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

class _TodayPage extends StatelessWidget {
  const _TodayPage();

  @override
  Widget build(BuildContext context) => GlossScreen(
    topBar: const GlossTopBar(title: 'Today'),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlossButton.filled(
            'Delete',
            onPressed: () => showGlossDialog<void>(
              context: context,
              builder: (context) => GlossDialog(
                title: 'Delete this plan?',
                content: const Text('Its dinners go back to your recipes.'),
                actions: [
                  GlossDialogAction(
                    label: 'Keep',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
          GlossButton(
            'Save',
            onPressed: () => showGlossToast(context, 'Saved'),
          ),
        ],
      ),
    ),
  );
}

void main() {
  setUpAll(glossLoadFonts);

  final hosts = <String, Widget Function(Brightness)>{
    'MaterialApp': (b) => MaterialApp(
      builder: (context, child) => GlossHost(brightness: b, child: child!),
      home: const _TodayPage(),
    ),
    'CupertinoApp': (b) => CupertinoApp(
      builder: (context, child) => GlossHost(brightness: b, child: child!),
      home: const _TodayPage(),
    ),
    'WidgetsApp': (b) => WidgetsApp(
      color: const Color(0xFF0E7652),
      builder: (context, child) => GlossHost(brightness: b, child: child!),
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      home: const _TodayPage(),
    ),
  };

  for (final MapEntry(key: host, value: app) in hosts.entries) {
    for (final b in Brightness.values) {
      testWidgets('${b.name}: a page, a dialog and a toast under $host', (
        tester,
      ) async {
        await tester.pumpWidget(app(b));
        await tester.pumpAndSettle();
        expect(find.text('Today'), findsOneWidget);
        expect(
          GlossTheme.of(tester.element(find.text('Delete'))).colors.brightness,
          b,
        );

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        expect(find.text('Delete this plan?'), findsOneWidget);
        await tester.tap(find.text('Keep'));
        await tester.pumpAndSettle();
        expect(find.text('Delete this plan?'), findsNothing);

        await tester.tap(find.text('Save'));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Saved'), findsOneWidget);
        await tester.pumpAndSettle(const Duration(seconds: 10));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets("the README's smallest app shows its key", (tester) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF0E7652),
        builder: (context, _) => GlossHost(
          child: Center(child: GlossButton.filled('Start', onPressed: () {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
