// An attachment named in the sans.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/themed_page.dart';

void main() {
  testWidgets("an attachment chip names its file in the sans, as an "
      "upload list does", (tester) async {
    await tester.pumpWidget(
      themedPage(
        MinimalComposer(
          onSend: (_) {},
          attachment: 'run-2026-08-28.gpx',
          onRemoveAttachment: () {},
        ),
      ),
    );
    final style = tester.widget<Text>(find.text('run-2026-08-28.gpx')).style!;
    expect(style.fontFamily, dayTheme.bodySmall.fontFamily);
    expect(style.fontFamily, isNot(dayTheme.mono.fontFamily));
  });
}
