/// A dialog's text action stands as tall as the filled confirm beside it at
/// every text size: both take the small button's top and bottom, so the row
/// keeps one height at 1.3x and 2x text as at 1x.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

/// The face an action's [label] stands on.
Rect _face(WidgetTester tester, String label) => tester.getRect(
  find
      .ancestor(of: find.text(label), matching: find.byType(ExpressiveSurface))
      .first,
);

void main() {
  for (final scale in const [1.0, 1.3, 2.0]) {
    testWidgets('a text action is as tall as the filled confirm at ${scale}x '
        'text', (tester) async {
      tester.view
        ..physicalSize = const Size(1440, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: ExpressiveHost(
              theme: ExpressiveThemeData.preset('baseline', Brightness.light),
              brightness: Brightness.light,
              child: app!,
            ),
          ),
          home: const Center(
            child: ExpressiveDialog(
              title: 'Empty the bin?',
              text: 'Items in the bin are deleted for good.',
              actions: [
                ExpressiveDialogAction('Cancel'),
                ExpressiveDialogAction('Empty', filled: true),
              ],
            ),
          ),
        ),
      );
      final cancel = _face(tester, 'Cancel');
      final empty = _face(tester, 'Empty');
      expect(cancel.top, closeTo(empty.top, 0.5), reason: 'one row');
      expect(cancel.height, closeTo(empty.height, 0.5));
    });
  }
}
