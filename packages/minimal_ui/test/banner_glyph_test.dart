// A banner's glyph centres on its title's line at any text size.
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/directional_page.dart';

void main() {
  for (final scale in [1.0, 1.3]) {
    testWidgets('a banner\'s glyph centres on its title at ${scale}x', (
      tester,
    ) async {
      await tester.pumpWidget(
        directionalPage(
          const MinimalBanner(
            title: 'Domain verified',
            tone: MinimalTone.success,
          ),
          scale: scale,
        ),
      );
      await tester.pumpAndSettle();
      final glyph = find.descendant(
        of: find.byType(MinimalBanner),
        matching: find.byType(MinimalIcon),
      );
      expect(glyph, findsOneWidget);
      expect(
        tester.getCenter(glyph).dy,
        moreOrLessEquals(
          tester.getCenter(find.text('Domain verified')).dy,
          epsilon: 0.01,
        ),
      );
    });
  }
}
