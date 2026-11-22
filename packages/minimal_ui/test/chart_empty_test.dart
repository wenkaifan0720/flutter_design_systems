import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/directional_page.dart';

void main() {
  testWidgets('an empty chart says why in the caption ink', (tester) async {
    await tester.pumpWidget(
      directionalPage(
        const Column(
          children: [
            MinimalLineChart(series: [], emptyLabel: 'No signups'),
            MinimalPieChart(slices: [], emptyLabel: 'No hours'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final t = tester.element(find.text('No signups')).minimalTheme;
    for (final why in ['No signups', 'No hours']) {
      expect(
        tester.widget<Text>(find.text(why)).style?.color,
        t.mutedForeground,
      );
    }
  });
}
