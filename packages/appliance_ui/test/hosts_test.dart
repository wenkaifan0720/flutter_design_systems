// Appliance installs as the README shows, in the builder of any app widget:
// MaterialApp, CupertinoApp and WidgetsApp, by day and by night. A page, a
// dialog and a toast work under each; so does the README's smallest app.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

class _BasketPage extends StatelessWidget {
  const _BasketPage();

  @override
  Widget build(BuildContext context) => ApplianceScreen(
    topBar: const ApplianceAppBar(title: 'Basket'),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ApplianceButton.filled(
            'Remove',
            onPressed: () => showApplianceDialog<void>(
              context: context,
              builder: (context) => ApplianceDialog(
                title: 'Remove the kettle?',
                content: const Text('It leaves the basket.'),
                actions: [
                  ApplianceButton(
                    'Keep',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
          ApplianceButton(
            'Save',
            onPressed: () => showApplianceToast(context, 'Saved'),
          ),
        ],
      ),
    ),
  );
}

void main() {
  setUpAll(applianceLoadFonts);

  final hosts = <String, Widget Function(Brightness)>{
    'MaterialApp': (b) => MaterialApp(
      builder: (context, child) => ApplianceHost(brightness: b, child: child!),
      home: const _BasketPage(),
    ),
    'CupertinoApp': (b) => CupertinoApp(
      builder: (context, child) => ApplianceHost(brightness: b, child: child!),
      home: const _BasketPage(),
    ),
    'WidgetsApp': (b) => WidgetsApp(
      color: const Color(0xFFEE6A26),
      builder: (context, child) => ApplianceHost(brightness: b, child: child!),
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      home: const _BasketPage(),
    ),
  };

  for (final MapEntry(key: host, value: app) in hosts.entries) {
    for (final b in Brightness.values) {
      testWidgets('${b.name}: a page, a dialog and a toast under $host', (
        tester,
      ) async {
        await tester.pumpWidget(app(b));
        await tester.pumpAndSettle();
        expect(find.text('Basket'), findsOneWidget);
        expect(
          ApplianceTheme.of(tester.element(find.text('Remove')))
              .colors
              .brightness,
          b,
        );

        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();
        expect(find.text('Remove the kettle?'), findsOneWidget);
        await tester.tap(find.text('Keep'));
        await tester.pumpAndSettle();
        expect(find.text('Remove the kettle?'), findsNothing);

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
        color: const Color(0xFFEE6A26),
        builder: (context, _) => ApplianceHost(
          child: Center(
            child: ApplianceButton.filled('Start', onPressed: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
