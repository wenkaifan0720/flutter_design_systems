// A dialog's keys stand in one row at its end when they fit, and one to a
// line, at the end, when they don't: never two on a line and the third alone
// under them. Phones from 320 to 390, at their text size and larger, and a
// desk.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

void main() {
  setUpAll(loadFaces);

  for (final (width, scale) in const [
    (320.0, 1.0),
    (360.0, 1.0),
    (390.0, 1.0),
    (390.0, 1.5),
    (390.0, 2.0),
    (1440.0, 1.0),
  ]) {
    testWidgets('at $width, text at ${scale}x: the keys stand in one row or '
        'one to a line', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: MediaQuery.withClampedTextScaling(
            minScaleFactor: scale,
            maxScaleFactor: scale,
            child: TermTheme(
              data: TermThemeData.light(),
              child: Center(
                child: TermDialog(
                  title: 'unsaved changes',
                  content: const Text('the form has edits that are not saved.'),
                  actions: [
                    TermButton(label: 'cancel', onPressed: () {}),
                    TermButton(label: 'discard', onPressed: () {}),
                    TermButton.filled(label: 'save changes', onPressed: () {}),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final keys = [
        for (final e in find.byType(TermButton).evaluate())
          tester.getRect(find.byElementPredicate((x) => identical(x, e))),
      ];
      expect(keys, hasLength(3));
      final tops = {for (final k in keys) k.top.round()};
      final where = keys.map((k) => '$k').join(', ');
      if (tops.length == 1) {
        // One row, the strongest last, at the end.
        expect(keys[0].right, lessThanOrEqualTo(keys[1].left), reason: where);
        expect(keys[1].right, lessThanOrEqualTo(keys[2].left), reason: where);
      } else {
        // One to a line, in their order, each at the end.
        expect(tops, hasLength(3), reason: 'two on a line: $where');
        expect(keys[0].bottom, lessThanOrEqualTo(keys[1].top), reason: where);
        expect(keys[1].bottom, lessThanOrEqualTo(keys[2].top), reason: where);
        expect(
          {for (final k in keys) k.right.round()},
          hasLength(1),
          reason: 'each at the end: $where',
        );
      }
      if (width > 600 && scale == 1) {
        expect(tops, hasLength(1), reason: 'a desk has room: $where');
      }
    });
  }
}
