import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/column_host.dart';

void main() {
  testWidgets('MinimalMetaRow keeps one line, ellipsizing only its middle', (
    tester,
  ) async {
    await tester.pumpWidget(
      columnHost(
        const SizedBox(
          width: 220,
          child: MinimalMetaRow(
            leading: Text('1047'),
            middle: Text(
              'Studio North asked to move their standing order to Tuesdays',
            ),
            trailing: Text('09:30'),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('1047'), findsOneWidget);
    expect(find.text('09:30'), findsOneWidget);
    final middle = tester.getSize(find.textContaining('Studio North'));
    expect(middle.height, lessThan(24));
  });
}
