// A toast on a phone stands above the scaffold's tab bar, as a Scaffold
// keeps a snackbar above its navigation bar; under a route that covers the
// bar, the bar keeps nothing clear and the toast stands at the foot.
import 'dart:async';

import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<GlobalKey> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final page = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, navigator) => BrutalTheme(
        data: BrutalThemeData.light(),
        child: BrutalToaster(child: navigator!),
      ),
      home: BrutalScaffold(
        destinations: const [
          BrutalDestination(icon: LucideIcons.house, label: 'Home'),
          BrutalDestination(icon: LucideIcons.ticket, label: 'Tickets'),
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

// The phone's bar: the tallest full-width box round the first place's icon
// that stands on the screen's foot (the scaffold builds it, not a
// BrutalNavigationBar).
Rect _bar() {
  Rect? bar;
  for (final e
      in find
          .ancestor(
            of: find.byIcon(LucideIcons.house),
            matching: find.byWidgetPredicate((_) => true),
          )
          .evaluate()) {
    final box = e.renderObject;
    if (box is! RenderBox || !box.hasSize) continue;
    final r = MatrixUtils.transformRect(
      box.getTransformTo(null),
      Offset.zero & box.size,
    );
    if (r.width < 389 || r.bottom < 843 || r.height > 200) continue;
    if (bar == null || r.height > bar.height) bar = r;
  }
  return bar!;
}

void main() {
  testWidgets('a toast stands above the tab bar on a phone', (tester) async {
    final page = await _pump(tester);
    showBrutalToast(page.currentContext!, 'Ticket cancelled', duration: null);
    await tester.pumpAndSettle();
    final bar = _bar();
    final toast = tester.getRect(find.text('Ticket cancelled'));
    expect(toast.bottom, lessThanOrEqualTo(bar.top));
  });

  testWidgets('under a route that covers the bar, a toast stands at the foot', (
    tester,
  ) async {
    final page = await _pump(tester);
    final bar = _bar();
    final cover = GlobalKey();
    unawaited(
      Navigator.of(page.currentContext!).push(
        PageRouteBuilder<void>(
          pageBuilder: (context, _, _) => SizedBox.expand(key: cover),
        ),
      ),
    );
    await tester.pumpAndSettle();
    showBrutalToast(cover.currentContext!, 'Ticket cancelled', duration: null);
    await tester.pumpAndSettle();
    final toast = tester.getRect(find.text('Ticket cancelled'));
    // The covered bar keeps nothing clear: the toast is lower than its top.
    expect(toast.bottom, greaterThan(bar.top));
  });
}
