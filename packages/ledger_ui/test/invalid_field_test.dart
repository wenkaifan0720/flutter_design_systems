// A field told it is invalid with no words to say why (ui_core's
// RawInputDecorator.invalid) is ruled in the danger red, as one with an
// error is.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_parts.dart';

void main() {
  for (final invalid in [false, true]) {
    testWidgets('a field ${invalid ? 'marked invalid' : 'that is valid'} '
        'is ruled ${invalid ? 'in the danger red' : 'in the ink'}', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, page) =>
              LedgerHost(brightness: Brightness.light, child: page!),
          home: Material(
            type: MaterialType.transparency,
            child: Center(
              child: SizedBox(
                width: 320,
                child: RawInputDecorator(
                  labelText: 'Amount',
                  invalid: invalid,
                  builder: (context, parts) =>
                      LedgerFieldFrame(parts: parts, line: parts.control),
                  child: const SizedBox(height: 40),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final t = LedgerTheme.of(tester.element(find.byType(LedgerFieldFrame)));
      final ink = tester.widget<LedgerFace>(find.byType(LedgerFace)).style.ink;
      expect(ink, invalid ? t.danger : isNot(t.danger));
    });
  }
}
