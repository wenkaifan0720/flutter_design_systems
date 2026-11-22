/// A select's list as wide as a wide field still marks its choice at the
/// row's end: the check stands the item's padding in from the lit row's
/// end, either way round, and the words keep the field's value edge.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

final ExpressiveThemeData bloom = ExpressiveThemeData.preset(
  'bloom',
  Brightness.light,
);

/// The row's inset from the menu's sides and the item's end padding
/// (`MenuBehavior.itemInset`, `MenuBehavior.itemHorizontalPadding`).
const double _rowInset = 4;
const double _endPadding = 12;

Widget _host(TextDirection direction) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) => Directionality(
    textDirection: direction,
    child: ExpressiveHost(
      light: bloom,
      brightness: Brightness.light,
      child: app!,
    ),
  ),
  home: Align(
    alignment: AlignmentDirectional.topStart,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 400,
        child: ExpressiveSelect<String>(
          label: 'Project',
          options: const [
            ExpressiveSelectOption('studio', 'Open studio'),
            ExpressiveSelectOption('series', 'Workshop series'),
          ],
          value: 'studio',
          onChanged: (_) {},
        ),
      ),
    ),
  ),
);

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('the chosen row\'s check stands at the row\'s end in a list '
        'wider than a menu\'s widest item (${direction.name})', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(direction));
      await tester.tap(find.text('Open studio'));
      await tester.pumpAndSettle();

      final check = tester.getRect(find.byIcon(ExpressiveSymbols.check));
      final row = tester.getRect(
        find
            .ancestor(
              of: find.byIcon(ExpressiveSymbols.check),
              matching: find.byWidgetPredicate(
                (w) => w.runtimeType.toString() == '_MenuItemTile',
              ),
            )
            .first,
      );
      // The list is the field's width, past the 280dp a menu's item asks.
      expect(row.width, greaterThan(300));
      final gap = direction == TextDirection.ltr
          ? row.right - check.right
          : check.left - row.left;
      expect(
        gap,
        moreOrLessEquals(_rowInset + _endPadding, epsilon: .5),
        reason: 'check $check in row $row',
      );
    });
  }
}
