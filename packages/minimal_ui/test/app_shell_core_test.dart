// MinimalAppShell on ui_core 0.8.0 (lane U): the rail and the sidebar stay
// in the semantics tree with a page pushed, both ways; the phone's bar steps
// away while a page is pushed and comes back when it pops.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _places = [
  MinimalNavItem(LucideIcons.bookOpen, 'Books'),
  MinimalNavItem(LucideIcons.plus, 'Add'),
  MinimalNavItem(LucideIcons.settings, 'Settings'),
];

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _place = 0;

  @override
  Widget build(BuildContext context) => MinimalAppShell.branches(
    destinations: _places,
    selectedIndex: _place,
    onDestinationSelected: (index) => setState(() => _place = index),
    branches: [
      (context) => MinimalScaffold(
        topBar: const MinimalAppBar(title: 'Books'),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MinimalButton(
              'Open',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const MinimalScaffold(
                    topBar: MinimalAppBar(title: 'Stoner', parent: 'Books'),
                    body: Text('Detail body'),
                  ),
                ),
              ),
            ),
            Builder(
              builder: (context) => MinimalButton(
                'Toast',
                onPressed: () => showMinimalSnackBar(context, 'Saved'),
              ),
            ),
          ],
        ),
      ),
      (context) => const MinimalScaffold(body: Text('Add body')),
      (context) => const MinimalScaffold(body: Text('Settings body')),
    ],
  );
}

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  TextDirection? direction,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: minimalPageTransitions,
        ),
      ),
      builder: (context, app) => MinimalHost(
        light: MinimalThemeData.preset('standard', Brightness.light),
        dark: MinimalThemeData.preset('standard', Brightness.dark),
        brightness: Brightness.light,
        child: direction == null
            ? app!
            : Directionality(textDirection: direction, child: app!),
      ),
      home: const _Shell(),
    ),
  );
  await tester.pumpAndSettle();
}

/// A place by what a screen reader hears.
Finder _tab(String label, int at) =>
    find.bySemanticsLabel('$label\nTab $at of 3');

SemanticsNode _place(WidgetTester tester, String label, int at) =>
    tester.getSemantics(_tab(label, at));

void main() {
  for (final direction in TextDirection.values) {
    for (final size in const [Size(800, 900), Size(1440, 900)]) {
      testWidgets('the places stay in the tree with a page pushed '
          '(${size.width.toInt()}, ${direction.name})', (tester) async {
        await _pump(tester, size, direction: direction);
        expect(_tab('Settings', 3), findsOneWidget);
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Detail body'), findsOneWidget);
        expect(_tab('Settings', 3), findsOneWidget);
        expect(_place(tester, 'Books', 1), isSemantics(isSelected: true));
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(_tab('Settings', 3), findsOneWidget);
      });
    }
  }

  testWidgets("the phone's bar steps away while a page is pushed", (
    tester,
  ) async {
    await _pump(tester, const Size(390, 844));
    expect(_tab('Books', 1), findsOneWidget);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    // Below the window and out of the semantics tree.
    expect(tester.getTopLeft(_tab('Books', 1)).dy, greaterThanOrEqualTo(844));
    expect(find.semantics.byLabel('Books\nTab 1 of 3'), findsNothing);
    // The page takes the bar's room.
    expect(tester.getBottomLeft(find.byType(MinimalScaffold).last).dy, 844);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.semantics.byLabel('Books\nTab 1 of 3'), findsOneWidget);
    expect(tester.getBottomLeft(_tab('Books', 1)).dy, 844);
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      'a desktop toast stands beside the sidebar (${direction.name})',
      (tester) async {
        await _pump(tester, const Size(1440, 900), direction: direction);
        await tester.tap(find.text('Toast'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final toast = tester.getRect(find.text('Saved'));
        const sidebar = MinimalAppShell.defaultSidebarWidth;
        if (direction == TextDirection.ltr) {
          expect(toast.left, greaterThan(sidebar));
        } else {
          expect(toast.right, lessThan(1440 - sidebar));
        }
      },
    );
  }
}
