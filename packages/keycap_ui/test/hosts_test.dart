// Keycap installs as the README shows, in the builder of any app widget:
// MaterialApp, CupertinoApp and WidgetsApp, by day and by night. A page, a
// dialog and a toast work under each; so does the README's smallest app.
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

class _NotesPage extends StatelessWidget {
  const _NotesPage();

  @override
  Widget build(BuildContext context) => KeycapScreen(
    topBar: const KeycapAppBar(title: 'Notes'),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KeycapButton.accent(
            onPressed: () => showKeycapDialog<void>(
              context: context,
              builder: (context) => KeycapDialog(
                title: 'Delete note?',
                content: const Text('It goes for good.'),
                actions: [
                  KeycapButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Keep'),
                  ),
                ],
              ),
            ),
            child: const Text('Delete'),
          ),
          KeycapButton(
            onPressed: () => showKeycapToast(context, 'Saved'),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

void main() {
  setUpAll(keycapLoadFonts);

  final hosts = <String, Widget Function(Brightness)>{
    'MaterialApp': (b) => MaterialApp(
      builder: (context, child) => KeycapHost(brightness: b, child: child!),
      home: const _NotesPage(),
    ),
    'CupertinoApp': (b) => CupertinoApp(
      builder: (context, child) => KeycapHost(brightness: b, child: child!),
      home: const _NotesPage(),
    ),
    'WidgetsApp': (b) => WidgetsApp(
      color: const Color(0xFF2F59CF),
      builder: (context, child) => KeycapHost(brightness: b, child: child!),
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      home: const _NotesPage(),
    ),
  };

  for (final MapEntry(key: host, value: app) in hosts.entries) {
    for (final b in Brightness.values) {
      testWidgets('${b.name}: a page, a dialog and a toast under $host', (
        tester,
      ) async {
        await tester.pumpWidget(app(b));
        await tester.pumpAndSettle();
        expect(find.text('Notes'), findsOneWidget);
        expect(
          KeycapTheme.of(tester.element(find.text('Delete'))).colors.brightness,
          b,
        );

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        expect(find.text('Delete note?'), findsOneWidget);
        await tester.tap(find.text('Keep'));
        await tester.pumpAndSettle();
        expect(find.text('Delete note?'), findsNothing);

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
        color: const Color(0xFF2F59CF),
        builder: (context, _) => KeycapHost(
          child: Center(
            child: KeycapButton.accent(
              onPressed: () {},
              child: const Text('New note'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('New note'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
