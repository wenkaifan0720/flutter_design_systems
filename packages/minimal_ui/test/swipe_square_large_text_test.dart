// A swipe square keeps 12 px each side of its word.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/scaled_page.dart';

void main() {
  testWidgets('a swipe square keeps 12 px each side of its word at larger '
      'text', (tester) async {
    await tester.pumpWidget(
      scaledPage(
        const MinimalSwipeActions(
          initiallyOpen: true,
          trailing: [
            MinimalSwipeAction('Archive', onPressed: doNothing),
            MinimalSwipeAction(
              'Delete',
              destructive: true,
              onPressed: doNothing,
            ),
          ],
          child: MinimalListTile(title: 'Morning run', meta: '12d'),
        ),
        scale: 1.3,
      ),
    );
    await tester.pumpAndSettle();
    // The square [label] stands in: its ruled box.
    Rect square(String label) => tester.getRect(
      find
          .ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is DecoratedBox &&
                  w.decoration is BoxDecoration &&
                  (w.decoration as BoxDecoration).border is BorderDirectional,
            ),
          )
          .first,
    );
    for (final label in ['Archive', 'Delete']) {
      final word = tester.getRect(find.text(label));
      final box = square(label);
      expect(
        math.min(word.left - box.left, box.right - word.right),
        greaterThanOrEqualTo(12 - 1.5),
        reason: label,
      );
    }
  });
}
