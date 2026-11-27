// MinimalAppShell: the phone's bar is a tab bar with the current place
// selected, a rail from 600 and a sidebar from 960, each place keeps its own
// stack (a pushed page keeps the sidebar, back pops it, choosing the place
// again returns to its first page), and a toast stands above the bar.
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
  testWidgets("the phone's bar: its places are tabs, the current selected", (
    tester,
  ) async {
    await _pump(tester, const Size(390, 844));
    // Along the bottom, a third of the width each.
    final tab = tester.getRect(_tab('Books', 1));
    expect(tab.bottom, 844);
    expect(tab.width, closeTo(390 / 3, 1));
    final books = _place(tester, 'Books', 1);
    expect(books.getSemanticsData().role, SemanticsRole.tab);
    expect(books, isSemantics(isSelected: true, hasSelectedState: true));
    expect(
      _place(tester, 'Settings', 3),
      isSemantics(isSelected: false, hasSelectedState: true),
    );
    await tester.tap(_tab('Settings', 3));
    await tester.pumpAndSettle();
    expect(find.text('Settings body'), findsOneWidget);
    expect(_place(tester, 'Settings', 3), isSemantics(isSelected: true));
  });

  testWidgets('a rail from 600, a sidebar of its own width from 960', (
    tester,
  ) async {
    await _pump(tester, const Size(800, 900));
    // Down the start edge: a rail's width, its labels under their glyphs.
    expect(
      tester.getTopLeft(find.byType(MinimalScaffold)).dx,
      MinimalNavigationRail.width,
    );
    // Centred in the rail inside its end hairline.
    expect(
      tester.getCenter(find.text('Settings')).dx,
      closeTo(MinimalNavigationRail.width / 2, 1),
    );
    await _pump(tester, const Size(1440, 900));
    // A sidebar: its rows' labels beside their glyphs, the page past it.
    expect(
      tester.getTopLeft(find.text('Settings')).dx,
      lessThan(MinimalAppShell.defaultSidebarWidth / 2),
    );
    expect(
      tester.getTopLeft(find.byType(MinimalScaffold)).dx,
      MinimalAppShell.defaultSidebarWidth,
    );
    await _pump(tester, const Size(1440, 900), direction: TextDirection.rtl);
    expect(
      tester.getTopRight(find.byType(MinimalScaffold)).dx,
      1440 - MinimalAppShell.defaultSidebarWidth,
    );
  });

  testWidgets('a pushed page keeps the sidebar; back pops it', (tester) async {
    await _pump(tester, const Size(1440, 900));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Detail body'), findsOneWidget);
    expect(find.text('Settings', skipOffstage: false), findsOneWidget);
    expect(tester.getTopLeft(find.text('Detail body')).dx, greaterThan(248));
    // The page's own way back is there, and the platform's back pops it.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Detail body'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('choosing the current place again returns to its first page', (
    tester,
  ) async {
    await _pump(tester, const Size(1440, 900));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Books').first);
    await tester.pumpAndSettle();
    expect(find.text('Detail body'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('each place keeps its own stack', (tester) async {
    await _pump(tester, const Size(1440, 900));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings body'), findsOneWidget);
    await tester.tap(find.text('Books').first);
    await tester.pumpAndSettle();
    expect(find.text('Detail body'), findsOneWidget);
  });

  testWidgets('a toast stands above the bar', (tester) async {
    await _pump(tester, const Size(390, 844));
    await tester.tap(find.text('Toast'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final toast = tester.getRect(find.text('Saved'));
    final bar = tester.getRect(_tab('Books', 1));
    expect(toast.bottom, lessThanOrEqualTo(bar.top));
  });
}
