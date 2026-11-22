// The inventory's rail and drawer stand as tall as their rows.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import 'support/scaled_page.dart';

void main() {
  testWidgets("the inventory's rail and drawer stand as tall as their rows", (
    tester,
  ) async {
    setViewSize(tester, const Size(1000, 900));
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, navigator) => MinimalHost(
          light: dayTheme,
          dark: nightTheme,
          brightness: Brightness.light,
          child: navigator!,
        ),
        home: const MinimalScaffold(
          scroll: false,
          body: MinimalInventoryGallery(),
        ),
      ),
    );
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    while (find.byType(MinimalNavigationDrawer).evaluate().isEmpty &&
        position.pixels < position.maxScrollExtent) {
      position.jumpTo(
        math.min(position.pixels + 600, position.maxScrollExtent),
      );
      await tester.pump();
    }
    expect(tester.takeException(), isNull);
    // Two rows each, and their padding: well under 160.
    expect(
      tester.getSize(find.byType(MinimalNavigationDrawer)).height,
      lessThan(120),
    );
    expect(
      tester.getSize(find.byType(MinimalNavigationRail)).height,
      lessThan(160),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}
