// ApplianceScaffold.branches: each place keeps a navigator of its own. A
// page pushed on one keeps the rail or the side panel, the phone's key strip
// steps away for it and comes back with back, back pops the place before it
// leaves it, choosing the place again returns to its first page, and a toast
// stands clear of the key strip.
import 'package:material_ui/material_ui.dart'
    show MaterialApp, MaterialPageRoute;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appliance_ui/appliance_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

const _places = [
  ApplianceDestination(icon: LucideIcons.listChecks, label: 'Lists'),
  ApplianceDestination(icon: LucideIcons.plus, label: 'Add'),
  ApplianceDestination(icon: LucideIcons.settings, label: 'Settings'),
];

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _place = 0;

  @override
  Widget build(BuildContext context) => ApplianceScaffold.branches(
    destinations: _places,
    selectedIndex: _place,
    onSelected: (index) => setState(() => _place = index),
    header: const Text('Larder'),
    branches: [
      (context) => ApplianceScreen(
        topBar: const ApplianceAppBar(title: 'Lists'),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ApplianceButton(
              'Open',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const ApplianceScreen(
                    topBar: ApplianceAppBar(title: 'Weekly shop'),
                    body: Text('Detail body'),
                  ),
                ),
              ),
            ),
            Builder(
              builder: (context) => ApplianceButton(
                'Toast',
                onPressed: () => showApplianceToast(context, 'Saved'),
              ),
            ),
          ],
        ),
      ),
      (context) => const ApplianceScreen(body: Text('Add body')),
      (context) => const ApplianceScreen(body: Text('Settings body')),
    ],
  );
}

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => Directionality(
        textDirection: direction,
        child: ApplianceHost(brightness: Brightness.light, child: app!),
      ),
      home: const _Shell(),
    ),
  );
  await tester.pumpAndSettle();
}

/// A place by what a screen reader hears.
Finder _tab(String label, int at) =>
    find.bySemanticsLabel(RegExp('^$label(\n.*)?Tab $at of 3', dotAll: true));

void _placesReachable(WidgetTester tester) =>
    const DesignNavigationCheck(look: 'Appliance')
        .check(
          tester.element(find.byType(_Shell)),
          destinations: ['Lists', 'Add', 'Settings'],
        )
        .verify();

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('a pushed page keeps the side panel at 1440; back pops it '
        '(${direction.name})', (tester) async {
      await _pump(tester, const Size(1440, 900), direction: direction);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Detail body'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      final panel = tester.getRect(find.text('Settings'));
      final detail = tester.getRect(find.text('Detail body'));
      if (direction == TextDirection.ltr) {
        expect(detail.left, greaterThan(panel.right));
      } else {
        expect(detail.right, lessThan(panel.left));
      }
      _placesReachable(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Detail body'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    });
  }

  testWidgets('the rail stays over a pushed page at 800', (tester) async {
    await _pump(tester, const Size(800, 900));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Detail body'), findsOneWidget);
    expect(tester.getRect(_tab('Settings', 3)).left, lessThan(120));
    _placesReachable(tester);
  });

  testWidgets("the phone's key strip steps away for a pushed page and comes "
      'back with back', (tester) async {
    await _pump(tester, const Size(390, 844));
    expect(tester.getRect(_tab('Lists', 1)).bottom, lessThanOrEqualTo(844));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Detail body'), findsOneWidget);
    expect(_tab('Lists', 1).hitTestable(), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_tab('Lists', 1).hitTestable(), findsOneWidget);
  });

  testWidgets('choosing the place again returns to its first page', (
    tester,
  ) async {
    await _pump(tester, const Size(1440, 900));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(_tab('Lists', 1));
    await tester.pumpAndSettle();
    expect(find.text('Detail body'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('each place keeps its own pages', (tester) async {
    await _pump(tester, const Size(1440, 900));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(_tab('Settings', 3));
    await tester.pumpAndSettle();
    expect(find.text('Settings body'), findsOneWidget);
    await tester.tap(_tab('Lists', 1));
    await tester.pumpAndSettle();
    // Lists was chosen again from elsewhere: its pushed page is still there.
    expect(find.text('Detail body'), findsOneWidget);
  });

  testWidgets('a toast stands clear of the key strip', (tester) async {
    await _pump(tester, const Size(390, 844));
    await tester.tap(find.text('Toast'));
    await tester.pumpAndSettle();
    final toast = tester.getRect(find.text('Saved'));
    final strip = tester.getRect(_tab('Lists', 1));
    expect(toast.bottom, lessThanOrEqualTo(strip.top));
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });
}
