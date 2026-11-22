// A page dot that is not the current page shows by night as it does by day:
// its well stands off the case at least 1.3:1 (by day 1.41:1). Before, by
// night it was 1.08:1, gone into the case.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

double _contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (x > y ? x + 0.05 : y + 0.05) / (x > y ? y + 0.05 : x + 0.05);
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('a resting page dot shows on the case, ${brightness.name}', (
      tester,
    ) async {
      late Color ground;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) =>
              KeycapHost(brightness: brightness, child: app!),
          home: Builder(
            builder: (context) {
              ground = KeycapTheme.of(context).colors.ground;
              return const Center(child: KeycapPageDots(count: 4, index: 1));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final dots = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(KeycapPageDots),
              matching: find.byType(DecoratedBox),
            ),
          )
          .toList();
      expect(dots, hasLength(4));
      final rest = (dots.first.decoration as BoxDecoration).color!;
      expect(_contrast(rest, ground), greaterThanOrEqualTo(1.3));
    });
  }
}
