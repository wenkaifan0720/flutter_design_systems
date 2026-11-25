// Clay installs as the README shows, in the builder of any app widget:
// MaterialApp, CupertinoApp and WidgetsApp, by day and by night. A page,
// a dialog and a toast work under each.
import 'package:clay_ui/clay_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Widget _clay(BuildContext context, Widget? child, Brightness b) => ClayTheme(
  data: ClayThemeData.clay(b),
  child: ClayToaster(child: child!),
);

class _TodayPage extends StatelessWidget {
  const _TodayPage();

  @override
  Widget build(BuildContext context) => ClayScaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClayButton.filled(
            'Add habit',
            onPressed: () => showClayDialog<void>(
              context: context,
              builder: (context) => ClayDialog(
                title: 'Add a habit?',
                content: const Text('It starts today.'),
                actions: [
                  ClayDialogAction(
                    label: 'Add',
                    isDefaultAction: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
          ClayButton('Save', onPressed: () => showClayToast(context, 'Saved')),
        ],
      ),
    ),
  );
}

void main() {
  setUpAll(clayLoadFonts);

  final hosts = <String, Widget Function(Brightness)>{
    'MaterialApp': (b) => MaterialApp(
      builder: (context, child) => _clay(context, child, b),
      home: const _TodayPage(),
    ),
    'CupertinoApp': (b) => CupertinoApp(
      builder: (context, child) => _clay(context, child, b),
      home: const _TodayPage(),
    ),
    'WidgetsApp': (b) => WidgetsApp(
      color: const Color(0xFFFF7A59),
      builder: (context, child) => _clay(context, child, b),
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
        expect(find.text('Add habit'), findsOneWidget);
        expect(
          ClayTheme.of(tester.element(find.text('Add habit')))
              .colors
              .brightness,
          b,
        );

        await tester.tap(find.text('Add habit'));
        await tester.pumpAndSettle();
        expect(find.text('Add a habit?'), findsOneWidget);
        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();
        expect(find.text('Add a habit?'), findsNothing);

        await tester.tap(find.text('Save'));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Saved'), findsOneWidget);
        await tester.pumpAndSettle(const Duration(seconds: 10));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
