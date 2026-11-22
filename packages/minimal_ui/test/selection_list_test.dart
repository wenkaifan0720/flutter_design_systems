import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/scrolling_host.dart';
import 'support/select_options.dart';

void main() {
  group('MinimalSelectionList', () {
    testWidgets('it checks the value and skips a disabled option', (
      tester,
    ) async {
      final chosen = <String>[];
      await tester.pumpWidget(
        scrollingHost(
          MinimalSelectionList(
            value: 'daily',
            options: selectOptions,
            onChanged: chosen.add,
          ),
        ),
      );
      await tester.tap(find.text('Custom…'));
      await tester.tap(find.text('Every evening'));
      expect(chosen, ['evening']);
    });
  });
}
