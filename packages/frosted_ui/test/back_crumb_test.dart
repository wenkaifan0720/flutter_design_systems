// The desktop crumb over a pushed page goes back on its first activation
// through the semantics tree, after the place was left and chosen again.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

class _Books extends StatelessWidget {
  const _Books();

  @override
  Widget build(BuildContext context) => FrostedScaffold(
    topBar: const FrostedAppBar(title: 'Books'),
    body: Center(
      child: FrostedButton(
        'Open',
        onPressed: () => Navigator.of(context).push(
          PageRouteBuilder<void>(
            pageBuilder: (context, _, _) => const FrostedScaffold(
              topBar: FrostedAppBar(title: 'Dune', backLabel: 'Books'),
              body: Center(child: Text('Dune page')),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          FrostedHost(brightness: Brightness.light, child: app!),
      home: FrostedAppShell(
        destinations: const [
          RawNavigationDestination(label: 'Books', icon: FrostedGlyphs.house),
          RawNavigationDestination(
            label: 'Settings',
            icon: FrostedGlyphs.person,
          ),
        ],
        branches: [
          (context) => const _Books(),
          (context) => const FrostedScaffold(
            topBar: FrostedAppBar(title: 'Settings'),
            body: Center(child: Text('Settings page')),
          ),
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _activate(WidgetTester tester, String label) async {
  tester.semantics.tap(find.semantics.byLabel(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the crumb goes back on its first activation', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Dune page'), findsOneWidget);
    await _activate(tester, 'Back to Books');
    expect(find.text('Dune page'), findsNothing);
    handle.dispose();
  });

  testWidgets('after the place was left and chosen again', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text('Settings page'), findsOneWidget);
    await tester.tap(find.text('Books').first);
    await tester.pumpAndSettle();
    expect(find.text('Dune page'), findsOneWidget);
    await _activate(tester, 'Back to Books');
    expect(find.text('Dune page'), findsNothing);
    handle.dispose();
  });
}
