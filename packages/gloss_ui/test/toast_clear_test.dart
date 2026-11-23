// A toast on a phone stands above the scaffold's tab bar, as a Scaffold
// keeps a snackbar above its navigation bar; under a route that covers the
// bar, the bar keeps nothing clear and the toast stands at the foot.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<GlobalKey> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final page = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, navigator) => GlossTheme(
        data: GlossThemeData.light(),
        child: GlossToaster(child: navigator!),
      ),
      home: GlossScaffold(
        destinations: const [
          GlossDestination(icon: LucideIcons.chefHat, label: 'Recipes'),
          GlossDestination(icon: LucideIcons.calendarDays, label: 'Plan'),
        ],
        selectedIndex: 0,
        onDestinationSelected: (_) {},
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
    showGlossToast(page.currentContext!, 'Added to Thursday', duration: null);
    await tester.pumpAndSettle();
    final bar = tester.getRect(find.byType(GlossNavigationBar));
    final toast = tester.getRect(find.text('Added to Thursday'));
    expect(toast.bottom, lessThanOrEqualTo(bar.top));
  });

  testWidgets('under a route that covers the bar, a toast stands at the foot', (
    tester,
  ) async {
    final page = await _pump(tester);
    final bar = tester.getRect(find.byType(GlossNavigationBar));
    final cover = GlobalKey();
    unawaited(
      Navigator.of(page.currentContext!).push(
        PageRouteBuilder<void>(
          pageBuilder: (context, _, _) => SizedBox.expand(key: cover),
        ),
      ),
    );
    await tester.pumpAndSettle();
    showGlossToast(cover.currentContext!, 'Added to Thursday', duration: null);
    await tester.pumpAndSettle();
    final toast = tester.getRect(find.text('Added to Thursday'));
    // The covered bar keeps nothing clear: the toast is lower than its top.
    expect(toast.bottom, greaterThan(bar.top));
  });
}
