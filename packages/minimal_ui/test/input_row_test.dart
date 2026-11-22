import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/scrolling_host.dart';

void main() {
  group('MinimalInputRow layout', () {
    testWidgets('narrow rows stack; wide rows start the error under the '
        'field', (tester) async {
      await tester.pumpWidget(
        scrollingHost(
          const Column(
            children: [
              SizedBox(
                width: 240,
                child: MinimalInputRow(label: 'Name', hint: 'Stretch'),
              ),
              MinimalInputRow(
                label: 'Goal',
                hint: '10',
                error: 'Between 1 and 240 minutes.',
              ),
            ],
          ),
        ),
      );
      final name = tester.getRect(find.text('Name'));
      final stretch = tester.getRect(find.text('Stretch'));
      expect(stretch.top, greaterThan(name.bottom));
      final goalField = tester.getRect(find.text('10'));
      final error = tester.getRect(find.text('Between 1 and 240 minutes.'));
      expect(error.left, moreOrLessEquals(goalField.left, epsilon: 0.5));
    });
  });
}
