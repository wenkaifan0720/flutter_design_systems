// A disabled search on the sunken fill.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/themed_page.dart';

/// Every fill painted under [of]: its containers' and decorated boxes'.
List<Color> _fills(WidgetTester tester, Finder of) {
  Color? fillOf(Decoration? d) => switch (d) {
    BoxDecoration(:final color) => color,
    ShapeDecoration(:final color) => color,
    _ => null,
  };
  return [
    for (final c in tester.widgetList<Container>(
      find.descendant(of: of, matching: find.byType(Container)),
    ))
      fillOf(c.decoration),
    for (final b in tester.widgetList<DecoratedBox>(
      find.descendant(of: of, matching: find.byType(DecoratedBox)),
    ))
      fillOf(b.decoration),
  ].whereType<Color>().toList();
}

void main() {
  testWidgets('a disabled search rests on the sunken fill, as a disabled '
      'text field does', (tester) async {
    await tester.pumpWidget(
      themedPage(
        const Column(
          children: [
            MinimalSearchField(hintText: 'Search archived', enabled: false),
            MinimalSearchEntry(label: 'Search archive'),
          ],
        ),
      ),
    );
    expect(
      _fills(tester, find.byType(MinimalSearchField)),
      contains(dayTheme.sunken),
    );
    expect(
      _fills(tester, find.byType(MinimalSearchEntry)),
      contains(dayTheme.sunken),
    );
  });
}
