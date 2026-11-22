import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/themed_page.dart';

void main() {
  // The tag's rim, and the box's air over a tag, are the remove key's
  // where they stand over it: no pixel there takes no tap.
  testWidgets("a tag's remove key takes taps on its rim and over it", (
    tester,
  ) async {
    final changes = <List<String>>[];
    await tester.pumpWidget(
      themedPage(
        MinimalMultiSelect<String>(
          values: const ['Bug'],
          options: const ['Bug', 'Design', 'Docs'],
          onChanged: changes.add,
        ),
      ),
    );
    final key = tester.getRect(find.bySemanticsLabel(RegExp('Remove Bug')));
    final tag = tester.getRect(
      find
          .ancestor(of: find.text('Bug'), matching: find.byType(Container))
          .first,
    );
    for (final y in [tag.top + 0.5, tag.bottom - 0.5, tag.top - 3]) {
      await tester.tapAt(Offset(key.center.dx, y));
      await tester.pump();
    }
    expect(changes, hasLength(3));
  });
}
