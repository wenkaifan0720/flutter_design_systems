// A toast on a phone stands above the scaffold's tab bar, as a Scaffold
// keeps a snackbar above its navigation bar; under a route that covers the
// bar, the bar keeps nothing clear and the toast stands at the foot.
import 'dart:async';

import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<GlobalKey> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final page = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, navigator) => CivicTheme(
        data: CivicThemeData.light(),
        child: CivicToaster(child: navigator!),
      ),
      home: CivicScaffold(
        navigationBar: CivicNavigationBar(
          destinations: const [
            CivicNavigationDestination(icon: LucideIcons.house, label: 'Home'),
            CivicNavigationDestination(
              icon: LucideIcons.settings,
              label: 'Settings',
            ),
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
        body: SizedBox.expand(key: page),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return page;
}

void main() {
  testWidgets('a toast stands above the tab bar on a phone', (tester) async {
    final page = await _pump(tester);
    CivicToast.show(page.currentContext!, 'Your settings have been saved');
    await tester.pumpAndSettle();
    final bar = tester.getRect(find.byType(CivicNavigationBar));
    final toast = tester.getRect(find.text('Your settings have been saved'));
    expect(toast.bottom, lessThanOrEqualTo(bar.top));
    // Let the toast's time run out.
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
  });

  testWidgets('under a route that covers the bar, a toast stands at the foot', (
    tester,
  ) async {
    final page = await _pump(tester);
    final bar = tester.getRect(find.byType(CivicNavigationBar));
    final cover = GlobalKey();
    unawaited(
      Navigator.of(page.currentContext!).push(
        PageRouteBuilder<void>(
          pageBuilder: (context, _, _) => SizedBox.expand(key: cover),
        ),
      ),
    );
    await tester.pumpAndSettle();
    CivicToast.show(cover.currentContext!, 'Your settings have been saved');
    await tester.pumpAndSettle();
    final toast = tester.getRect(find.text('Your settings have been saved'));
    // The covered bar keeps nothing clear: the toast is lower than its top.
    expect(toast.bottom, greaterThan(bar.top));
    // Let the toast's time run out.
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
  });
}
