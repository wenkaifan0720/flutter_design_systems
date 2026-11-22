import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/column_host.dart';

void main() {
  group('MinimalTag', () {
    testWidgets('is 20 tall in its tone ink', (tester) async {
      await tester.pumpWidget(
        columnHost(
          const Align(
            child: MinimalTag('Overdue', tone: MinimalTone.destructive),
          ),
        ),
      );
      expect(tester.getSize(find.byType(MinimalTag)).height, MinimalTag.height);
      final text = tester.widget<Text>(find.text('Overdue'));
      expect(
        text.style!.color,
        lightTheme.tone(MinimalTone.destructive).foreground,
      );
    });
  });
}
