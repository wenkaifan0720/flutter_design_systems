import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/centred_host.dart';

void main() {
  group('MinimalInputOtp', () {
    testWidgets('a long press offers Paste in Minimal\'s menu at the press, '
        'and Paste fills the code and closes it', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => switch (call.method) {
          'Clipboard.hasStrings' => <String, Object?>{'value': true},
          'Clipboard.getData' => <String, Object?>{'text': '1234'},
          _ => null,
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final codes = <String>[];
      await tester.pumpWidget(
        centredHost(
          MinimalInputOtp(length: 4, labelText: 'Code', onCompleted: codes.add),
        ),
      );
      final press = tester.getCenter(find.byType(EditableText));
      await tester.longPressAt(press);
      await tester.pumpAndSettle();
      expect(find.text('Paste'), findsOneWidget);
      // The menu opens at the press: its one row just below and after it.
      final word = tester.getTopLeft(find.text('Paste'));
      expect(word.dx - press.dx, inInclusiveRange(0, 32));
      expect(word.dy - press.dy, inInclusiveRange(0, 32));

      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();
      expect(codes, ['1234']);
      expect(find.text('Paste'), findsNothing);
    });

    testWidgets('its submit, formatters and autofill reach the input', (
      tester,
    ) async {
      final submitted = <String>[];
      final upper = TextInputFormatter.withFunction(
        (_, value) => value.copyWith(text: value.text.toUpperCase()),
      );
      await tester.pumpWidget(
        centredHost(
          MinimalInputOtp(
            length: 4,
            onSubmitted: submitted.add,
            inputFormatters: [upper],
            autofillHints: const [AutofillHints.creditCardSecurityCode],
          ),
        ),
      );
      final input = tester.widget<EditableText>(find.byType(EditableText));
      expect(input.inputFormatters, contains(upper));
      expect(input.autofillHints, const [AutofillHints.creditCardSecurityCode]);
      input.onSubmitted!('1234');
      expect(submitted, ['1234']);
    });
  });
}
