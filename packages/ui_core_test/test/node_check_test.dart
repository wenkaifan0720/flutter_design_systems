// DesignControlNodesCheck: each control keeps a node of its own;
// DesignNavigationCheck: the navigation stays in the tree under a page.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core_test/ui_core_test.dart';

import 'behaviour_harness.dart';

Widget _button(String label, {Key? key}) => RawButton(
  key: key,
  onPressed: () {},
  semanticLabel: label,
  builder: (context, states, _) =>
      SizedBox(height: 44, child: Center(widthFactor: 1, child: Text(label))),
);

// A list row: its words a button the row's width, a "more" button after.
Widget _row({required bool merged}) {
  final row = Row(
    children: [
      Expanded(child: _button('Stoner')),
      _button('More for Stoner'),
    ],
  );
  return harness(
    Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 360,
        child: merged ? MergeSemantics(child: row) : row,
      ),
    ),
  );
}

List<String> _nodes(WidgetTester tester) =>
    const DesignControlNodesCheck(look: 'Test')
        .check(tester.element(find.byType(WidgetsApp)))
        .problems;

void main() {
  testWidgets("a row's trailing button merged into the row's node is named", (
    tester,
  ) async {
    await tester.pumpWidget(_row(merged: true));
    expect(_nodes(tester), [
      'a button "Stoner" and a button "More for Stoner" are one node, so a '
          'tap through the semantics tree reaches one of them',
    ]);
    await tester.pumpWidget(_row(merged: false));
    expect(_nodes(tester), isEmpty);
  });

  testWidgets('a row scrolled under a floating button is not a merge', (
    tester,
  ) async {
    // Olive's row, its Water and More buttons under an Add button that
    // floats over the list's foot, as a phone at 2x text shows it.
    await tester.pumpWidget(
      harness(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 360,
            height: 60,
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(child: _button('Olive')),
                    _button('Water Olive'),
                    _button('More for Olive'),
                  ],
                ),
                Positioned(
                  left: 200,
                  right: 0,
                  top: 10,
                  child: _button('Add a plant'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(_nodes(tester), isEmpty);
  });

  testWidgets('a check row (a checkbox merged into its row) is one control', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 360,
            child: MergeSemantics(
              child: Row(
                children: [
                  Expanded(child: _button('Wi-Fi')),
                  Semantics(
                    checked: true,
                    onTap: () {},
                    child: const SizedBox(width: 44, height: 44),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(_nodes(tester), isEmpty);
  });

  group('DesignNavigationCheck', () {
    // A rail painted before a body's navigator, [kept] in a semantics
    // container of its own.
    Widget app(GlobalKey<NavigatorState> navigator, {required bool kept}) {
      final body = Navigator(
        key: navigator,
        onGenerateRoute: (settings) => PageRouteBuilder<void>(
          pageBuilder: (context, _, _) => const Center(child: Text('Inbox')),
        ),
      );
      return harness(
        Row(
          children: [
            SizedBox(
              width: 80,
              child: Column(children: [_button('Home'), _button('Mail')]),
            ),
            Expanded(
              child: kept
                  ? Semantics(
                      container: true,
                      explicitChildNodes: true,
                      child: body,
                    )
                  : body,
            ),
          ],
        ),
      );
    }

    List<String> nav(WidgetTester tester) =>
        const DesignNavigationCheck(look: 'Test')
            .check(
              tester.element(find.byType(WidgetsApp)),
              destinations: ['Home', 'Mail'],
            )
            .problems;

    Future<void> push(
      WidgetTester tester,
      GlobalKey<NavigatorState> navigator,
    ) async {
      navigator.currentState!
          .push(
            PageRouteBuilder<void>(
              pageBuilder: (context, _, _) =>
                  const Center(child: Text('Message')),
            ),
          )
          .ignore();
      await tester.pumpAndSettle();
    }

    testWidgets('a rail dropped from the tree under a pushed page is named', (
      tester,
    ) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(app(navigator, kept: false));
      await tester.pumpAndSettle();
      await push(tester, navigator);
      expect(nav(tester), [
        'the destination "Home" is not in the semantics tree with a page '
            'pushed',
        'the destination "Mail" is not in the semantics tree with a page '
            'pushed',
      ]);
    });

    testWidgets('a body in a container of its own keeps the rail', (
      tester,
    ) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(app(navigator, kept: true));
      await tester.pumpAndSettle();
      await push(tester, navigator);
      expect(nav(tester), isEmpty);
    });

    testWidgets('RawAdaptiveShell keeps its navigation', (tester) async {
      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        harness(
          RawAdaptiveShell(
            destinations: const [
              RawNavigationDestination(label: 'Home', icon: IconData(0xe318)),
              RawNavigationDestination(label: 'Mail', icon: IconData(0xe158)),
            ],
            selectedIndex: 0,
            onDestinationSelected: (index) {},
            destinationBuilder: (context, destination, details) =>
                SizedBox(height: 48, child: Text(destination.label)),
            navigationBuilder: (context, details) => SizedBox(
              width: 80,
              child: Column(children: details.destinations),
            ),
            body: Navigator(
              key: navigator,
              onGenerateRoute: (settings) => PageRouteBuilder<void>(
                pageBuilder: (context, _, _) => const Text('Inbox'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await push(tester, navigator);
      expect(nav(tester), isEmpty);
    });
  });
}
