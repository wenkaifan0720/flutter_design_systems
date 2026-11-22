// A multi-select with one tag in it is as tall as empty.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/themed_page.dart';

void main() {
  for (final (name, theme) in [
    ('standard', dayTheme),
    ('compact', dayTheme.copyWith(density: MinimalDensity.compact)),
  ]) {
    testWidgets('a multi-select with a tag is as tall as empty ($name)', (
      tester,
    ) async {
      Widget field(List<String> values) => MinimalMultiSelect<String>(
        values: values,
        options: const ['Bug', 'Design', 'Docs'],
        onChanged: (_) {},
      );
      await tester.pumpWidget(themedPage(field(const []), theme: theme));
      final empty = tester.getSize(find.byType(MinimalMultiSelect<String>));
      await tester.pumpWidget(themedPage(field(const ['Bug']), theme: theme));
      expect(
        tester.getSize(find.byType(MinimalMultiSelect<String>)).height,
        empty.height,
      );
    });
  }
}
