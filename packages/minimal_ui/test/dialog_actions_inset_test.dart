// A dialog's actions end on its question's inset.
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/scaled_page.dart';

void main() {
  testWidgets("a dialog's actions end on its question's inset", (tester) async {
    await tester.pumpWidget(
      scaledPage(
        const MinimalDialog(
          title: 'Archive habit?',
          message: 'It leaves Today; its history stays.',
          confirmLabel: 'Archive',
          cancelLabel: 'Keep',
        ),
        width: MinimalDialog.maxWidth,
      ),
    );
    final card = tester.getRect(find.byType(MinimalDialog));
    final title = tester.getRect(find.text('Archive habit?'));
    final act = tester.getRect(
      find
          .ancestor(
            of: find.text('Archive'),
            matching: find.byType(MinimalButton),
          )
          .first,
    );
    expect(card.right - act.right, closeTo(title.left - card.left, 0.01));
  });
}
