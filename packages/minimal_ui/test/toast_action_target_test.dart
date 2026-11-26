import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import 'support/centred_host.dart';

void main() {
  testWidgets('a toast\'s action keeps its whole tap target', (tester) async {
    var undone = 0;
    await tester.pumpWidget(
      centredHost(
        Builder(
          builder: (context) => MinimalButton(
            'Archive',
            onPressed: () => showMinimalSnackBar(
              context,
              'Habit archived',
              actionLabel: 'Undo',
              onAction: () => undone += 1,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    // 21 px below the action's face's middle: inside its target (the
    // toast's full height, never under the tap floor), past
    // the face (its label stands on its capitals, so not on the label's).
    final action = tester.getRect(
      find
          .ancestor(
            of: find.text('Undo'),
            matching: find.byType(MinimalPressable),
          )
          .first,
    );
    await tester.tapAt(action.center + const Offset(0, 21));
    await tester.pump();
    expect(undone, 1);
    await tester.pump(MinimalChromeMetrics.toastWithAction);
  });
}
