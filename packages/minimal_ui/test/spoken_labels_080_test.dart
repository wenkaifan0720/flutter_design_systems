import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/padded_host.dart';

// A name only a screen reader hears is a semanticLabel: the rating's and the
// segmented button's are spoken, never drawn.
void main() {
  testWidgets("MinimalRating's semanticLabel names it and is not drawn", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      paddedHost(
        MinimalRating(
          value: 3,
          semanticLabel: 'Your rating',
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.bySemanticsLabel(RegExp('Your rating')), findsWidgets);
    expect(find.text('Your rating'), findsNothing);
    handle.dispose();
  });

  testWidgets("MinimalSegmentedButton's semanticLabel names the group and is "
      'not drawn', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      paddedHost(
        MinimalSegmentedButton<String>(
          segments: const [
            MinimalButtonSegment('week', 'Week'),
            MinimalButtonSegment('month', 'Month'),
          ],
          value: 'week',
          onChanged: (_) {},
          semanticLabel: 'View',
        ),
      ),
    );
    expect(find.bySemanticsLabel(RegExp('^View')), findsOneWidget);
    expect(find.text('View'), findsNothing);
    handle.dispose();
  });
}
