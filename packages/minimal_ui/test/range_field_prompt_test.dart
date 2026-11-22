// A range field's prompt in the body face.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/themed_page.dart';

void main() {
  testWidgets("a range field's prompt is words, in the placeholder face", (
    tester,
  ) async {
    await tester.pumpWidget(
      themedPage(
        MinimalDateRangePicker(
          label: 'Stay',
          firstDate: DateTime(2026),
          lastDate: DateTime(2027),
          onChanged: (_) {},
        ),
      ),
    );
    final style = tester.widget<Text>(find.text('Choose')).style!;
    expect(style.fontFamily, dayTheme.body.fontFamily);
    expect(style.fontSize, dayTheme.body.fontSize);
  });
}
