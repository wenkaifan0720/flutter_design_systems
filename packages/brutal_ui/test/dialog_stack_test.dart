// A dialog whose actions stack (at large text, or where one's words don't
// fit its cell) stands the main action on top, the others under it in
// reverse, as Material's dialog's actions overflow: the confirming act is
// the first the eye and the thumb find.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final direction in TextDirection.values) {
    for (final scale in const [1.0, 2.0]) {
      testWidgets(
        'stacked actions stand the main one on top (${direction.name}, ${scale}x)',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: const Size(390, 844),
                  textScaler: TextScaler.linear(scale),
                ),
                child: Directionality(
                  textDirection: direction,
                  child: BrutalTheme(
                    data: BrutalThemeData.light(),
                    child: Center(
                      child: SizedBox(
                        width: 358,
                        child: BrutalDialog(
                          title: 'Unsaved changes',
                          content: const Text('Keep the edits to this task?'),
                          actions: [
                            BrutalDialogAction(
                              label: 'Cancel',
                              onPressed: () {},
                            ),
                            BrutalDialogAction(
                              label: 'Discard changes',
                              onPressed: () {},
                            ),
                            BrutalDialogAction(
                              label: 'Save the changes',
                              isDefaultAction: true,
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          Rect cell(String words) => tester.getRect(
            find.ancestor(
              of: find.text(words),
              matching: find.byType(BrutalDialogAction),
            ),
          );
          final cancel = cell('Cancel');
          final discard = cell('Discard changes');
          final save = cell('Save the changes');
          // Stacked: one width, one above another.
          expect(save.width, cancel.width);
          expect(save.bottom, lessThanOrEqualTo(discard.top));
          expect(discard.bottom, lessThanOrEqualTo(cancel.top));
        },
      );
    }
  }
}
