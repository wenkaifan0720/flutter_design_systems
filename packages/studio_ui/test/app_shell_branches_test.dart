// StudioAppShell.branches: each place keeps a navigator of its own. A page
// pushed on one keeps the rail or the side panel, the phone's key bank steps
// away for it and comes back with back, back pops the place before it leaves
// it, choosing the place again returns to its first page, a toast stands
// clear of the key bank and the act stands over first pages only.
import 'package:material_ui/material_ui.dart'
    show MaterialApp, MaterialPageRoute;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

const _places = [
  StudioTab(LucideIcons.disc3, 'Books'),
  StudioTab(LucideIcons.plus, 'Add'),
  StudioTab(LucideIcons.settings, 'Settings'),
];

class _Shell extends StatefulWidget {
  const _Shell({this.action});

  final StudioShellAction? action;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _place = 0;

  @override
  Widget build(BuildContext context) => StudioAppShell.branches(
    tabs: _places,
    selectedIndex: _place,
    onSelected: (index) => setState(() => _place = index),
    action: widget.action,
    brand: 'Shelf',
    branches: [
      (context) => StudioScreen(
        topBar: const StudioAppBar(title: 'Books'),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StudioButton(
              'Open',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const StudioScreen(
                    topBar: StudioAppBar(title: 'Stoner'),
                    body: Text('Detail body'),
                  ),
                ),
              ),
            ),
            Builder(
              builder: (context) => StudioButton(
                'Toast',
                onPressed: () => showStudioToast(context, 'Saved'),
              ),
            ),
          ],
        ),
      ),
      (context) => const StudioScreen(body: Text('Add body')),
      (context) => const StudioScreen(body: Text('Settings body')),
    ],
  );
}

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  TextDirection direction = TextDirection.ltr,
  StudioShellAction? action,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => Directionality(
        textDirection: direction,
        child: StudioHost(brightness: Brightness.light, child: app!),
      ),
      home: _Shell(action: action),
    ),
  );
  await tester.pumpAndSettle();
}

/// A place by what a screen reader hears.
Finder _tab(String label, int at) =>
    find.bySemanticsLabel(RegExp('^$label(\n.*)?Tab $at of 3', dotAll: true));

void _placesReachable(WidgetTester tester) =>
    const DesignNavigationCheck(look: 'Studio')
        .check(
          tester.element(find.byType(_Shell)),
          destinations: ['Books', 'Add', 'Settings'],
        )
        .verify();

StudioShellAction _act(List<String> log) => StudioShellAction(
  icon: LucideIcons.plus,
  label: 'New book',
  onPressed: (context) => log.add('act'),
);

void main() {
  setUpAll(studioLoadFonts);

  for (final direction in TextDirection.values) {
    testWidgets('a pushed page keeps the side panel at 1440; back pops it '
        '(${direction.name})', (tester) async {
      await _pump(tester, const Size(1440, 900), direction: direction);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Detail body'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Shelf'), findsOneWidget);
      // The page stands past the panel, on its own side.
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

  testWidgets("the phone's key bank steps away for a pushed page and comes "
      'back with back', (tester) async {
    await _pump(tester, const Size(390, 844));
    expect(tester.getRect(_tab('Books', 1)).bottom, lessThanOrEqualTo(844));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Detail body'), findsOneWidget);
    expect(_tab('Books', 1).hitTestable(), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(_tab('Books', 1).hitTestable(), findsOneWidget);
  });

  testWidgets('choosing the current place again returns to its first page', (
    tester,
  ) async {
    await _pump(tester, const Size(1440, 900));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(_tab('Books', 1));
    await tester.pumpAndSettle();
    expect(find.text('Detail body'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('each place keeps its own stack', (tester) async {
    await _pump(tester, const Size(1440, 900));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(_tab('Settings', 3));
    await tester.pumpAndSettle();
    expect(find.text('Settings body'), findsOneWidget);
    await tester.tap(_tab('Books', 1));
    await tester.pumpAndSettle();
    expect(find.text('Detail body'), findsOneWidget);
  });

  testWidgets('a toast stands clear of the key bank', (tester) async {
    await _pump(tester, const Size(390, 844));
    await tester.tap(find.text('Toast'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    final toast = tester.getRect(find.text('Saved'));
    final bank = tester.getRect(_tab('Books', 1));
    expect(toast.bottom, lessThanOrEqualTo(bank.top));
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('the act stands over a first page, not over a pushed one', (
    tester,
  ) async {
    final log = <String>[];
    await _pump(tester, const Size(390, 844), action: _act(log));
    final act = find.bySemanticsLabel(RegExp('^New book'));
    expect(act, findsOneWidget);
    expect(
      tester.getRect(act).bottom,
      lessThanOrEqualTo(tester.getRect(_tab('Books', 1)).top),
    );
    await tester.tap(act);
    expect(log, ['act']);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('^New book')), findsNothing);
  });
}
