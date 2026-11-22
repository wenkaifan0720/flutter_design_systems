// A row that opens something ends in a chevron pointing toward its end: to
// the right left to right, to the left right to left (as Material's
// Icons.chevron_right follows the reading direction).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

/// Whether the row's chevron is drawn pointing left on the screen.
bool _pointsLeft(WidgetTester tester) {
  final chevron = find.descendant(
    of: find.byType(KeycapListTile),
    matching: find.byWidgetPredicate(
      (w) =>
          w is Icon &&
          (w.icon?.codePoint == LucideIcons.chevronRight.codePoint ||
              w.icon?.codePoint == LucideIcons.chevronLeft.codePoint),
    ),
  );
  final icon = tester.widget<Icon>(chevron);
  var left = icon.icon!.codePoint == LucideIcons.chevronLeft.codePoint;
  final flipped = find.descendant(
    of: chevron,
    matching: find.byWidgetPredicate(
      (w) => w is Transform && w.transform.storage[0] < 0,
    ),
  );
  if (tester.any(flipped)) left = !left;
  return left;
}

void main() {
  setUpAll(keycapLoadFonts);

  for (final direction in TextDirection.values) {
    testWidgets("a row's chevron points to its end, ${direction.name}", (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) =>
              KeycapHost(brightness: Brightness.light, child: app!),
          home: Directionality(
            textDirection: direction,
            child: Column(
              children: [KeycapListTile(title: 'Inbox', onTap: () {})],
            ),
          ),
        ),
      );
      expect(_pointsLeft(tester), direction == TextDirection.rtl);
    });
  }
}
