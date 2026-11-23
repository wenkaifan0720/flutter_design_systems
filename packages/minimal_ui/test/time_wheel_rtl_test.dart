// A 12-hour wheel reads 7 AM under a right-to-left page.
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/directional_page.dart';

void main() {
  testWidgets('a 12-hour wheel reads its period after the hour in RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      directionalPage(
        MinimalDatePicker(
          labelText: 'Wake-up',
          value: DateTime(2026, 8, 28, 7),
          mode: MinimalDatePickerMode.time,
          presentation: MinimalDatePickerPresentation.wheel,
          use24HourFormat: false,
          onChanged: (_) {},
        ),
        direction: TextDirection.rtl,
      ),
    );
    await tester.pumpAndSettle();
    final hour = find.text('7 AM');
    expect(hour, findsWidgets);
    for (final paragraph in tester.renderObjectList<RenderParagraph>(hour)) {
      expect(paragraph.textDirection, TextDirection.ltr);
    }
  });
}
