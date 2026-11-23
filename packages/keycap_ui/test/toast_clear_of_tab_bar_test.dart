// A toast on a phone stands above the tab bar, on a phone with a home
// indicator too, and keeps to the foot of the screen where there is none or
// a pushed page covers it.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _shell({required bool tabs}) {
  final body = Builder(
    builder: (context) => Center(
      child: KeycapButton(
        onPressed: () =>
            showKeycapToast(context, 'Note moved to Work', actionLabel: 'Undo'),
        child: const Text('Move'),
      ),
    ),
  );
  return MaterialApp(
    builder: (context, app) => KeycapHost(
      brightness: Brightness.light,
      child: KeycapToaster(child: app!),
    ),
    home: tabs
        ? KeycapScaffold(
            destinations: const [
              KeycapDestination(icon: IconData(0xe000), label: 'Notes'),
              KeycapDestination(icon: IconData(0xe001), label: 'Folders'),
              KeycapDestination(icon: IconData(0xe002), label: 'Settings'),
            ],
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            body: body,
          )
        : body,
  );
}

/// A page pushed over the shell, its own key showing the same toast.
Widget _page() => ColoredBox(
  color: const Color(0xFFCDD1DA),
  child: Builder(
    builder: (context) => Center(
      child: KeycapButton(
        onPressed: () =>
            showKeycapToast(context, 'Note moved to Work', actionLabel: 'Undo'),
        child: const Text('Move'),
      ),
    ),
  ),
);

Rect _toast(WidgetTester tester) => tester.getRect(
  find
      .ancestor(
        of: find.text('Note moved to Work'),
        matching: find.byType(KeycapPanel),
      )
      .first,
);

void main() {
  for (final inset in [0.0, 34.0]) {
    testWidgets('a toast stands above the tab bar (${inset.round()} px home '
        'indicator)', (tester) async {
      _phone(tester);
      tester.view.padding = FakeViewPadding(bottom: inset);
      await tester.pumpWidget(_shell(tabs: true));
      await tester.tap(find.text('Move'));
      await tester.pumpAndSettle();
      final bar = tester.getRect(find.byType(KeycapNavigationBar));
      expect(
        _toast(tester).bottom,
        lessThanOrEqualTo(bar.top + 0.5),
        reason: 'the toast covers the tab bar (${bar.top})',
      );
      // Clear the toast's timer.
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
    });
  }

  testWidgets('under a page pushed over the tab bar a toast keeps to the '
      'foot, and stands above the bar again once the page pops', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_shell(tabs: true));
    final bar = tester.getRect(find.byType(KeycapNavigationBar));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push(
        PageRouteBuilder<void>(pageBuilder: (context, _, _) => _page()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();
    expect(
      _toast(tester).bottom,
      greaterThan(bar.top + 0.5),
      reason: 'the covered tab bar still holds the toast up',
    );
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    navigator.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();
    expect(_toast(tester).bottom, lessThanOrEqualTo(bar.top + 0.5));
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });

  testWidgets('with no tab bar a toast keeps to the foot', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_shell(tabs: false));
    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();
    expect(_toast(tester).bottom, greaterThan(844 - 120));
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });
}
