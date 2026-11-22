// A failed list is the empty list's sibling: the same well and dome, the dome carrying the warning mark, never a bare
// dome that reads as a missing icon.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

Finder _domeGlyph(Finder state, IconData glyph) => find.descendant(
  of: state,
  matching: find.byWidgetPredicate((w) => w is Icon && w.icon == glyph),
);

void main() {
  testWidgets('a failed state stands in the well with a glyph on its dome', (
    tester,
  ) async {
    await tester.pumpWidget(
      neumorphicApp(
        Column(
          children: [
            const NeumorphicEmptyState(
              title: 'No tasks here',
              icon: NeumorphicGlyphs.inbox,
            ),
            NeumorphicErrorState(
              title: 'Couldn’t load the workspace',
              message: 'Try again to load the team’s latest work.',
              onRetry: () {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final state in [
      find.byType(NeumorphicEmptyState),
      find.byType(NeumorphicErrorState),
    ]) {
      expect(
        find.descendant(of: state, matching: find.byType(NeumorphicWell)),
        findsOneWidget,
      );
    }
    expect(
      _domeGlyph(
        find.byType(NeumorphicErrorState),
        NeumorphicGlyphs.triangleAlert,
      ),
      findsOneWidget,
    );
  });
}
