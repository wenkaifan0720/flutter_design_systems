// A failed state's dome takes a glyph that says what failed.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void main() {
  testWidgets('a failed state takes a glyph that says what failed', (
    tester,
  ) async {
    await tester.pumpWidget(
      neumorphicApp(
        const NeumorphicErrorState(
          title: 'Offline',
          icon: NeumorphicGlyphs.circleAlert,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(NeumorphicErrorState),
        matching: find.byWidgetPredicate(
          (w) => w is Icon && w.icon == NeumorphicGlyphs.circleAlert,
        ),
      ),
      findsOneWidget,
    );
  });
}
