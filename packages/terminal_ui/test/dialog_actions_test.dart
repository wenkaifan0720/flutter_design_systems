// A dialog's keys stand in one row at its end when they fit, else in one
// column of one width, the confirming key on top and the dismissive one at
// the foot: never two on a line and the third alone under them, never a
// stack of ragged widths. Phones from 320 to 390, at their text size and
// larger, and a desk; ui_core_test's DesignDialogActionsCheck reads each.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

import 'faces.dart';

const _keys = ['cancel', 'discard', 'save changes'];

void main() {
  setUpAll(loadFaces);

  for (final (width, scale) in const [
    (320.0, 1.0),
    (320.0, 2.0),
    (360.0, 1.0),
    (390.0, 1.0),
    (390.0, 1.5),
    (390.0, 2.0),
    (1440.0, 1.0),
  ]) {
    testWidgets('at $width, text at ${scale}x: the keys stand in one row or '
        'one column of one width, the confirming key on top', (tester) async {
      final semantics = tester.ensureSemantics();
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
                    TermButton(label: _keys[0], onPressed: () {}),
                    TermButton(label: _keys[1], onPressed: () {}),
                    TermButton.filled(label: _keys[2], onPressed: () {}),
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
        // One column, the strongest on top, each as wide as the others.
        expect(tops, hasLength(3), reason: 'two on a line: $where');
        expect(keys[2].bottom, lessThanOrEqualTo(keys[1].top), reason: where);
        expect(keys[1].bottom, lessThanOrEqualTo(keys[0].top), reason: where);
        expect(
          {for (final k in keys) k.width.round()},
          hasLength(1),
          reason: 'one width: $where',
        );
      }
      if (width > 600 && scale == 1) {
        expect(tops, hasLength(1), reason: 'a desk has room: $where');
      }
      final report = const DesignDialogActionsCheck(
        look: 'terminal',
        actions: _keys,
      ).check(tester.element(find.byType(TermDialog)));
      expect(report.problems, isEmpty);
      semantics.dispose();
    });
  }
}
