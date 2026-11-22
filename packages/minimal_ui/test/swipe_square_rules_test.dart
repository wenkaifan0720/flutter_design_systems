// Swipe squares ruled toward the row.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/themed_page.dart';

void _none() {}

void main() {
  for (final dir in TextDirection.values) {
    testWidgets('swipe squares are ruled toward the row, not at its outer '
        'edge (${dir.name})', (tester) async {
      await tester.pumpWidget(
        themedPage(
          Directionality(
            textDirection: dir,
            child: const MinimalSwipeActions(
              initiallyOpen: true,
              trailing: [
                MinimalSwipeAction('Archive', onPressed: _none),
                MinimalSwipeAction(
                  'Delete',
                  destructive: true,
                  onPressed: _none,
                ),
              ],
              child: MinimalListTile(title: 'Morning run', meta: '12d'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The resolved rule on each side of [label]'s square.
      Border border(String label) {
        final box = find
            .ancestor(
              of: find.text(label),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is DecoratedBox &&
                    w.decoration is BoxDecoration &&
                    (w.decoration as BoxDecoration).border is BorderDirectional,
              ),
            )
            .first;
        final decoration =
            tester.widget<DecoratedBox>(box).decoration as BoxDecoration;
        final d = decoration.border! as BorderDirectional;
        final rtlBox =
            Directionality.of(tester.element(box)) == TextDirection.rtl;
        return Border(
          top: d.top,
          bottom: d.bottom,
          left: rtlBox ? d.end : d.start,
          right: rtlBox ? d.start : d.end,
        );
      }

      final rtl = dir == TextDirection.rtl;
      // The row stands on the start side, so its actions run toward the
      // end: the inner square's start side meets the row, and the outer
      // square's end side is the list's edge.
      BorderSide towardRow(Border b) => rtl ? b.right : b.left;
      BorderSide outward(Border b) => rtl ? b.left : b.right;
      final archive = tester.getCenter(find.text('Archive')).dx;
      final delete = tester.getCenter(find.text('Delete')).dx;
      final outer = (rtl ? archive < delete : archive > delete)
          ? 'Archive'
          : 'Delete';
      for (final label in ['Archive', 'Delete']) {
        expect(towardRow(border(label)).width, greaterThan(0), reason: label);
      }
      expect(outward(border(outer)), BorderSide.none);
    });
  }
}
