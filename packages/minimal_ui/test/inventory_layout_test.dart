// The inventory shows a dialog and a side sheet at their own widths, and every
// specimen in it lays out (a navigation rail needs a height of its own).
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import 'support/scaled_page.dart';

void main() {
  testWidgets('the inventory shows a dialog at its own width, on the '
      "column's start", (tester) async {
    setViewSize(tester, const Size(1000, 900));
    await tester.pumpWidget(_inventory());
    // Jump a screen at a time: a drag can land on a part that takes the
    // gesture itself (a slider, a split's handle) and not scroll the list.
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    while (find.byType(MinimalDialog).evaluate().isEmpty &&
        position.pixels < position.maxScrollExtent) {
      position.jumpTo(
        math.min(position.pixels + 600, position.maxScrollExtent),
      );
      await tester.pump();
    }
    expect(
      tester.getSize(find.byType(MinimalDialog)).width,
      MinimalDialog.maxWidth,
    );
    // Let any part's timers run out before the end.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });

  // The everyday tier on a phone, the sweep tier at 1000.
  for (final width in [1000.0, 390.0]) {
    testWidgets('every inventory specimen lays out, top to bottom, $width '
        'wide', (tester) async {
      setViewSize(tester, Size(width, 900));
      await tester.pumpWidget(_inventory());
      expect(tester.takeException(), isNull);
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      // The list builds lazily: walk it a screen at a time, so every row
      // is built and laid out once.
      while (position.pixels < position.maxScrollExtent) {
        position.jumpTo(
          math.min(position.pixels + 600, position.maxScrollExtent),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '${position.pixels}');
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
    }, tags: width == 390 ? null : 'sweep');
  }
}

/// The inventory gallery as a page of its own.
Widget _inventory() => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: const MinimalScaffold(scroll: false, body: MinimalInventoryGallery()),
);
