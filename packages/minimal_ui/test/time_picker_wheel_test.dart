// A wheel stands on its slot's start.
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/text_scale_host.dart';

void main() {
  testWidgets('a wheel on the page stands on its slot\'s start edge, not '
      'centred in it', (tester) async {
    await tester.pumpWidget(
      textScaleHost(
        MinimalTimePicker(
          labelText: 'Remind me at',
          value: DateTime(2026, 8, 28, 21, 30),
          wheel: true,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final slot = tester.getRect(find.byType(MinimalTimePicker));
    final hour = tester.getRect(find.text('HOUR'));
    final minute = tester.getRect(find.text('MINUTE'));
    expect(hour.left, moreOrLessEquals(slot.left, epsilon: 0.5));
    expect(minute.right - hour.left, lessThan(slot.width));
  });
}
