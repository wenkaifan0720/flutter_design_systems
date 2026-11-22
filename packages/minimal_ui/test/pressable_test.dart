import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/centred_host.dart';

void main() {
  testWidgets('a pressable with nothing to do is not a control', (
    tester,
  ) async {
    await tester.pumpWidget(
      centredHost(const MinimalPressable(child: Text('Plain'))),
    );
    expect(find.byType(FocusableActionDetector), findsNothing);
    expect(find.byType(GestureDetector), findsNothing);
  });

  testWidgets('a pressable takes focus through the node it is given', (
    tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    var taps = 0;
    await tester.pumpWidget(
      centredHost(
        MinimalPressable(
          focusNode: node,
          onPressed: () => taps += 1,
          child: const Text('Agree'),
        ),
      ),
    );
    node.requestFocus();
    await tester.pump();
    expect(node.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(taps, 1);
  });
}
