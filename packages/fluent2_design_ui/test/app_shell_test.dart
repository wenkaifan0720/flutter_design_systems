// Fluent2AppShell: the phone's tab bar has the current place selected, the
// pane's rail from 640 and the pane from 1024; each place keeps its own stack
// (a pushed page keeps the pane, back pops it, choosing the place again
// returns to its first page); a toast stands above the bar; the act floats
// over a phone's first page, heads the rail and stands under the pane's head.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

const _places = [
  Fluent2NavItem(Fluent2Icons.book, 'Books'),
  Fluent2NavItem(Fluent2Icons.add, 'Add'),
  Fluent2NavItem(Fluent2Icons.settings, 'Settings'),
];

class _Shell extends StatefulWidget {
  const _Shell({this.action});

  final Fluent2ShellAction? action;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _place = 0;

  @override
  Widget build(BuildContext context) => Fluent2AppShell.branches(
    destinations: _places,
    selectedIndex: _place,
    onDestinationSelected: (index) => setState(() => _place = index),
    action: widget.action,
    header: const Text('Shelf'),
    branches: [
      (context) => Fluent2Scaffold(
        topBar: const Fluent2AppBar(title: 'Books'),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Fluent2Button(
              'Open',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const Fluent2Scaffold(
                    topBar: Fluent2AppBar(title: 'Stoner', backLabel: 'Books'),
                    body: Text('Detail body'),
                  ),
                ),
              ),
            ),
            Builder(
              builder: (context) => Fluent2Button(
                'Toast',
                onPressed: () => showFluent2Toast(context, 'Saved'),
              ),
            ),
          ],
        ),
      ),
      (context) => const Fluent2Scaffold(body: Text('Add body')),
      (context) => const Fluent2Scaffold(body: Text('Settings body')),
    ],
  );
}

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  TextDirection? direction,
  Fluent2ShellAction? action,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => Fluent2Host(
        light: Fluent2ThemeData.preset('lapis', Brightness.light),
        dark: Fluent2ThemeData.preset('lapis', Brightness.dark),
        brightness: Brightness.light,
        child: direction == null
            ? app!
            : Directionality(textDirection: direction, child: app!),
      ),
      home: _Shell(action: action),
    ),
  );
  await tester.pumpAndSettle();
}

/// A place by what a screen reader hears.
Finder _tab(String label, int at) =>
    find.bySemanticsLabel(RegExp('^$label\n?.*Tab $at of 3'));

SemanticsNode _place(WidgetTester tester, String label, int at) =>
    tester.getSemantics(_tab(label, at));

Fluent2ShellAction _act(List<String> log) => Fluent2ShellAction(
  icon: Fluent2Icons.add,
  label: 'New book',
  accent: true,
  onPressed: (context) => log.add('act'),
);

void main() {
  testWidgets(
    "the phone's tab bar: its places are tabs, the current selected",
    (tester) async {
      await _pump(tester, const Size(390, 844));
      // Along the bottom, a third of the width each.
      final tab = tester.getRect(_tab('Books', 1));
      expect(tab.bottom, 844);
      expect(tab.width, closeTo(390 / 3, 1));
      expect(tab.height, greaterThanOrEqualTo(56));
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
    },
  );

  testWidgets("the pane's rail from 640, the pane from 1024", (tester) async {
    await _pump(tester, const Size(800, 900));
    // Down the start edge: the rail's 48, the glyphs alone, each centred.
    expect(
      tester.getTopLeft(find.byType(Fluent2Scaffold)).dx,
      Fluent2ChromeMetrics.paneRail,
    );
    expect(find.text('Settings'), findsNothing);
    expect(
      tester.getCenter(_tab('Settings', 3)).dx,
      closeTo(Fluent2ChromeMetrics.paneRail / 2, 1),
    );
    await _pump(tester, const Size(1440, 900));
    // The pane: its items' words beside their glyphs, the page past it.
    expect(
      tester.getTopLeft(find.text('Settings')).dx,
      lessThan(Fluent2AppShell.defaultSidebarWidth / 2),
    );
    expect(find.text('Shelf'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(Fluent2Scaffold)).dx,
      Fluent2AppShell.defaultSidebarWidth,
    );
    await _pump(tester, const Size(1440, 900), direction: TextDirection.rtl);
    expect(
      tester.getTopRight(find.byType(Fluent2Scaffold)).dx,
      1440 - Fluent2AppShell.defaultSidebarWidth,
    );
  });

  testWidgets('a pushed page keeps the pane; back pops it', (tester) async {
    await _pump(tester, const Size(1440, 900));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Detail body'), findsOneWidget);
    expect(find.text('Settings', skipOffstage: false), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Detail body')).dx,
      greaterThan(Fluent2AppShell.defaultSidebarWidth),
    );
    const DesignNavigationCheck(look: 'Fluent 2')
        .check(
          tester.element(find.byType(_Shell)),
          destinations: ['Books', 'Add', 'Settings'],
        )
        .verify();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Detail body'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('the rail stays reachable over a pushed page', (tester) async {
    await _pump(tester, const Size(800, 900));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    const DesignNavigationCheck(look: 'Fluent 2')
        .check(
          tester.element(find.byType(_Shell)),
          destinations: ['Books', 'Add', 'Settings'],
        )
        .verify();
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

  testWidgets('a toast stands above the tab bar', (tester) async {
    await _pump(tester, const Size(390, 844));
    await tester.tap(find.text('Toast'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final toast = tester.getRect(find.text('Saved'));
    final bar = tester.getRect(_tab('Books', 1));
    expect(toast.bottom, lessThanOrEqualTo(bar.top));
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });

  testWidgets("the act: a phone's floating button, the rail's head, the "
      "pane's button", (tester) async {
    final log = <String>[];
    await _pump(tester, const Size(390, 844), action: _act(log));
    final fab = find.bySemanticsLabel('New book');
    expect(fab, findsOneWidget);
    expect(
      tester.getRect(fab).bottom,
      lessThanOrEqualTo(tester.getRect(_tab('Books', 1)).top),
    );
    expect(tester.getRect(fab).right, lessThanOrEqualTo(390 - 16 + 0.5));
    await tester.tap(fab);
    expect(log, ['act']);
    // A pushed page leaves it behind.
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('New book'), findsNothing);

    await _pump(tester, const Size(800, 900), action: _act(log));
    final head = tester.getRect(find.bySemanticsLabel('New book'));
    expect(head.right, lessThanOrEqualTo(Fluent2ChromeMetrics.paneRail));
    expect(head.top, lessThan(tester.getRect(_tab('Books', 1)).top));

    await _pump(tester, const Size(1440, 900), action: _act(log));
    expect(find.text('New book'), findsOneWidget);
    expect(
      tester.getRect(find.text('New book')).right,
      lessThan(Fluent2AppShell.defaultSidebarWidth),
    );
    await tester.tap(find.text('New book'));
    expect(log, ['act', 'act']);
  });
}
