/// A dialog's actions stand as Material's dialog stands them: one row, the
/// confirm action at its end, while they all fit, and otherwise one column,
/// the confirm action on top, each at the dialog's end; never two in a row
/// with the third under them. On a phone and on a desk, either way round,
/// and on a dialog as wide as its actions (its words shorter than they are).
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

final ExpressiveThemeData bloom = ExpressiveThemeData.preset(
  'bloom',
  Brightness.light,
);

void _size(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, app) => Directionality(
        textDirection: direction,
        child: ExpressiveHost(
          theme: bloom,
          brightness: Brightness.light,
          child: app!,
        ),
      ),
      home: Center(child: child),
    );

/// The button an action's [label] stands in.
Rect action(WidgetTester tester, String label) => tester.getRect(
  find
      .ancestor(of: find.text(label), matching: find.byType(ExpressiveSurface))
      .first,
);

ExpressiveDialog _unsaved(String text) => ExpressiveDialog(
  title: 'Unsaved changes',
  text: text,
  actions: const [
    ExpressiveDialogAction('Cancel'),
    ExpressiveDialogAction('Discard'),
    ExpressiveDialogAction('Save changes'),
  ],
);

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('three actions that do not fit a phone\'s row all stack, the '
        'confirm on top (${direction.name})', (tester) async {
      _size(tester, const Size(390, 844));
      await tester.pumpWidget(
        host(
          _unsaved('Save your changes before leaving this task?'),
          direction: direction,
        ),
      );
      final save = action(tester, 'Save changes');
      final discard = action(tester, 'Discard');
      final cancel = action(tester, 'Cancel');
      expect(save.bottom, lessThanOrEqualTo(discard.top));
      expect(discard.bottom, lessThanOrEqualTo(cancel.top));
      // Each at the dialog's end.
      final ends = direction == TextDirection.ltr
          ? {save.right, discard.right, cancel.right}
          : {save.left, discard.left, cancel.left};
      expect(ends, hasLength(1), reason: '$save $discard $cancel');
    });

    testWidgets('the same three share one row on a desk, the confirm at its '
        'end, the dialog as wide as they need (${direction.name})', (
      tester,
    ) async {
      _size(tester, const Size(1440, 900));
      // Words shorter than the actions: the dialog takes its width from
      // them, gaps included.
      await tester.pumpWidget(
        host(_unsaved('Leave this task?'), direction: direction),
      );
      final save = action(tester, 'Save changes');
      final discard = action(tester, 'Discard');
      final cancel = action(tester, 'Cancel');
      expect({save.top, discard.top, cancel.top}, hasLength(1));
      if (direction == TextDirection.ltr) {
        expect(cancel.right, lessThan(discard.left));
        expect(discard.right, lessThan(save.left));
      } else {
        expect(save.right, lessThan(discard.left));
        expect(discard.right, lessThan(cancel.left));
      }
    });
  }
}
