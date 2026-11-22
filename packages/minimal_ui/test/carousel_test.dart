import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/directional_page.dart';

void main() {
  for (final fraction in [0.8, 1.0]) {
    testWidgets('a carousel at $fraction cuts its neighbours '
        '${fraction < 1 ? 'square, faded' : 'not at all'}', (tester) async {
      await tester.pumpWidget(
        directionalPage(
          MinimalCarouselView(
            height: 120,
            viewportFraction: fraction,
            children: const [
              SizedBox.expand(),
              SizedBox.expand(),
              SizedBox.expand(),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final fade = find.descendant(
        of: find.byType(MinimalCarouselView),
        matching: find.byType(ShaderMask),
      );
      expect(fade, fraction < 1 ? findsOneWidget : findsNothing);
    });
  }
}
