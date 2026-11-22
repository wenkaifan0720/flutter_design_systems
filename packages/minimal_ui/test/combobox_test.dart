import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/centred_host.dart';

void main() {
  group('MinimalCombobox', () {
    testWidgets('words no option fits say so in the panel, in a row\'s '
        'place; Enter takes nothing and Escape hides it', (tester) async {
      final t = MinimalThemeData.preset('standard', Brightness.light);
      final taken = <String>[];
      await tester.pumpWidget(
        centredHost(
          SizedBox(
            width: 280,
            child: MinimalCombobox<String>(
              label: 'Assignee',
              options: const ['Ana Souza', 'Ben Okafor'],
              onSelected: taken.add,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'zz');
      await tester.pumpAndSettle();
      final said = find.text('No results');
      expect(said, findsOneWidget);
      expect(tester.widget<Text>(said).style?.color, t.mutedForeground);
      // As tall as an option's row, in the panel under the field.
      final row = find.ancestor(of: said, matching: find.byType(Container));
      expect(tester.getSize(row.first).height, 32);
      // The panel hugs it (the row, its 4 px inset and rim, 4 px off the
      // field), not the room the overlay offers.
      final surface = find.ancestor(
        of: said,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Padding &&
              w.padding ==
                  const EdgeInsets.symmetric(vertical: MinimalSpacing.s4),
        ),
      );
      expect(tester.getSize(surface.first).height, lessThan(64));
      expect(
        tester.getTopLeft(said).dy,
        greaterThan(tester.getBottomLeft(find.byType(EditableText)).dy),
      );

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(taken, isEmpty);
      expect(find.text('zz'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'zzz');
      await tester.pumpAndSettle();
      expect(said, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(said, findsNothing);

      await tester.enterText(find.byType(EditableText), 'Ben');
      await tester.pumpAndSettle();
      expect(said, findsNothing);
      expect(find.text('Ben Okafor'), findsOneWidget);
    });
  });
}
