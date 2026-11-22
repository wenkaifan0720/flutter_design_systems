// A neutral dot in the quiet ink.
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/themed_page.dart';

void main() {
  test('a neutral dot is the quiet ink, as its words are', () {
    for (final t in [dayTheme, nightTheme]) {
      expect(t.tone(MinimalTone.neutral).indicator, t.mutedForeground);
    }
  });
}
