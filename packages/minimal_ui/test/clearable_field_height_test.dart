// A compact clearable field keeps its height.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/themed_page.dart';

void main() {
  testWidgets('a compact clearable field keeps its height with the clear '
      'glyph in it', (tester) async {
    final compact = dayTheme.copyWith(density: MinimalDensity.compact);
    final name = TextEditingController(text: 'Morning run');
    addTearDown(name.dispose);
    await tester.pumpWidget(
      themedPage(
        MinimalTextField(controller: name, clearable: true),
        theme: compact,
      ),
    );
    final cleared = tester.getSize(find.byType(MinimalTextField)).height;
    name.clear();
    await tester.pump();
    expect(tester.getSize(find.byType(MinimalTextField)).height, cleared);
  });
}
