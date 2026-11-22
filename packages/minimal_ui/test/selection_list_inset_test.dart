// A selection list's own inset.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/themed_page.dart';

void main() {
  testWidgets('a selection list insets its rows by its padding', (
    tester,
  ) async {
    Widget list(EdgeInsetsGeometry padding) => MinimalSelectionList<String>(
      value: 'a',
      options: const [
        MinimalSelectOption('a', 'Alpha'),
        MinimalSelectOption('b', 'Beta'),
      ],
      padding: padding,
      onChanged: (_) {},
    );
    await tester.pumpWidget(themedPage(list(EdgeInsets.zero)));
    final flush = tester.getTopLeft(find.text('Beta')).dx;
    await tester.pumpWidget(
      themedPage(list(const EdgeInsets.symmetric(horizontal: 16))),
    );
    expect(tester.getTopLeft(find.text('Beta')).dx - flush, 16);
  });
}
