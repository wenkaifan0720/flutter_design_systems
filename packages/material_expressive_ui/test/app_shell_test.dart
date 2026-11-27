// ExpressiveAppShell, the one adaptive shell: on ui_core's RawAdaptiveShell
// at every width, the phone's bar included. Its places are the shell's
// tabs (one tab stop, a tab bar to a screen reader); a pushed page keeps the
// rail and the phone's bar steps away; choosing the place again goes back to
// its first page; the action stands above the bar at the end on a phone and
// heads the rail from 600dp.
import 'package:material_ui/material_ui.dart'
    show MaterialApp, MaterialPageRoute;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

const _places = [
  ExpressiveNavItem(ExpressiveSymbols.book, 'Books', key: ValueKey('books')),
  ExpressiveNavItem(
    ExpressiveSymbols.search,
    'Search',
    key: ValueKey('search'),
  ),
  ExpressiveNavItem(
    ExpressiveSymbols.settings,
    'Settings',
    key: ValueKey('settings'),
  ),
];

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) => ExpressiveAppShell.branches(
    destinations: _places,
    selectedIndex: _index,
    onDestinationSelected: (i) => setState(() => _index = i),
    action: ExpressiveFloatingActionButton(
      key: const ValueKey('fab'),
      icon: ExpressiveSymbols.add,
      semanticLabel: 'Add a book',
      onPressed: () {},
    ),
    branches: [
      (context) => Center(
        child: ExpressiveFilledButton(
          'Open Dune',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const Center(child: Text('Dune')),
            ),
          ),
        ),
      ),
      (context) => const Center(child: Text('Find a book')),
      (context) => const Center(child: Text('Appearance')),
    ],
  );
}

Future<void> _show(
  WidgetTester tester,
  double width, {
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        RawWidgetsLocalizations.delegate,
        ExpressiveLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: direction,
        child: ExpressiveHost(child: child ?? const SizedBox.shrink()),
      ),
      home: const _Shell(),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _key(String key) => find.byKey(ValueKey(key));

void main() {
  testWidgets('on a phone the bar holds the shell\'s tabs', (tester) async {
    final semantics = tester.ensureSemantics();
    await _show(tester, 390);
    expect(find.byType(RawAdaptiveShell), findsOneWidget);
    expect(find.byType(ExpressiveNavigationBar), findsOneWidget);
    expect(find.bySemanticsLabel('Books\nTab 1 of 3'), findsOneWidget);
    expect(find.bySemanticsLabel('Settings\nTab 3 of 3'), findsOneWidget);
    // The bar's places are the shell's presses: a RawButton round each face.
    expect(
      find.ancestor(of: find.text('Search'), matching: find.byType(RawButton)),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Books\nTab 1 of 3')),
      matchesSemantics(
        label: 'Books\nTab 1 of 3',
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
    await tester.tap(_key('settings'));
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the places are one tab stop, the arrows along them', (
    tester,
  ) async {
    await _show(tester, 390);
    FocusNode node(String place) => tester
        .widget<RawButton>(
          find.ancestor(of: find.text(place), matching: find.byType(RawButton)),
        )
        .focusNode!;
    final stops = <String>{};
    for (var i = 0; i < 6; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      for (final place in ['Books', 'Search', 'Settings']) {
        if (node(place).hasFocus) stops.add(place);
      }
    }
    // Only the selected place takes the Tab key.
    expect(stops, {'Books'});
    node('Books').requestFocus();
    await tester.pump();
    // The face shows the shell's keyboard focus (its ring and layer).
    final face = tester.widget<ExpressivePressable>(
      find.descendant(
        of: find.ancestor(
          of: find.text('Books'),
          matching: find.byType(RawButton),
        ),
        matching: find.byType(ExpressivePressable),
      ),
    );
    expect(face.statesController!.value, contains(WidgetState.focused));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(node('Search').hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Find a book'), findsOneWidget);
  });

  testWidgets('a pushed page: the bar steps away on a phone', (tester) async {
    await _show(tester, 390);
    await tester.tap(find.text('Open Dune'));
    await tester.pumpAndSettle();
    expect(find.text('Dune'), findsOneWidget);
    expect(_key('books').hitTestable(), findsNothing);
    // The action stands on the place's first page: the pushed page covers it.
    expect(_key('fab').hitTestable(), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_key('books').hitTestable(), findsOneWidget);
    expect(_key('fab').hitTestable(), findsOneWidget);
  });

  for (final width in [800.0, 1440.0]) {
    testWidgets('at $width a pushed page keeps the rail; Books again pops it', (
      tester,
    ) async {
      await _show(tester, width);
      expect(find.byType(ExpressiveNavigationRail), findsOneWidget);
      expect(
        tester
            .widget<ExpressiveNavigationRail>(
              find.byType(ExpressiveNavigationRail),
            )
            .expanded,
        width >= ExpressiveAppShell.expandedFrom,
      );
      await tester.tap(find.text('Open Dune'));
      await tester.pumpAndSettle();
      expect(find.text('Dune'), findsOneWidget);
      expect(_key('books').hitTestable(), findsOneWidget);
      await tester.tap(_key('books'));
      await tester.pumpAndSettle();
      expect(find.text('Dune'), findsNothing);
      expect(find.text('Open Dune'), findsOneWidget);
    });
  }

  testWidgets(
    'on a phone a tap on the place again goes back to its first page',
    (tester) async {
      await _show(tester, 390);
      await tester.tap(_key('search'));
      await tester.pumpAndSettle();
      await tester.tap(_key('books'));
      await tester.pumpAndSettle();
      expect(find.text('Open Dune'), findsOneWidget);
    },
  );

  for (final direction in TextDirection.values) {
    testWidgets('${direction.name}: the action 16dp above the bar at the end', (
      tester,
    ) async {
      await _show(tester, 390, direction: direction);
      final fab = tester.getRect(_key('fab'));
      final bar = tester.getRect(find.byType(ExpressiveNavigationBar));
      expect(fab.bottom, moreOrLessEquals(bar.top - 16));
      if (direction == TextDirection.ltr) {
        expect(fab.right, moreOrLessEquals(390 - 16));
      } else {
        expect(fab.left, moreOrLessEquals(16));
      }
    });
  }

  testWidgets('from 600dp the action heads the rail', (tester) async {
    await _show(tester, 800);
    final fab = tester.getRect(_key('fab'));
    final rail = tester.getRect(find.byType(ExpressiveNavigationRail));
    expect(fab.right, lessThanOrEqualTo(rail.right));
    expect(fab.bottom, lessThan(tester.getRect(_key('books')).top));
  });

  testWidgets('the modes: bar under 600, rail, expanded from 1200', (
    tester,
  ) async {
    expect(ExpressiveAppShell.modeFor(599), RawNavigationMode.bar);
    expect(ExpressiveAppShell.modeFor(600), RawNavigationMode.rail);
    expect(ExpressiveAppShell.modeFor(1199), RawNavigationMode.rail);
    expect(ExpressiveAppShell.modeFor(1200), RawNavigationMode.sidebar);
  });

  testWidgets('on a phone a snackbar keeps clear of the bar and the action', (
    tester,
  ) async {
    await _show(tester, 390);
    showExpressiveSnackBar(tester.element(find.text('Open Dune')), 'Saved');
    await tester.pumpAndSettle();
    final snack = tester.getRect(find.byType(ExpressiveSnackBar));
    final bar = tester.getRect(find.byType(ExpressiveNavigationBar));
    final fab = tester.getRect(_key('fab'));
    expect(snack.bottom, lessThanOrEqualTo(bar.top));
    expect(snack.bottom, lessThanOrEqualTo(fab.top));
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
  });
}
