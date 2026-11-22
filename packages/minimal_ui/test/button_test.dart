import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/centred_host.dart';

void main() {
  testWidgets('a button taps, and says it is an enabled button', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      centredHost(MinimalButton('Create habit', onPressed: () => taps += 1)),
    );
    await tester.tap(find.text('Create habit'));
    expect(taps, 1);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Create habit')),
      matchesSemantics(
        label: 'Create habit',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('a button with no action is disabled, and says so', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(centredHost(const MinimalButton('Create habit')));
    final semantics = tester.getSemantics(
      find.bySemanticsLabel('Create habit'),
    );
    expect(
      semantics,
      matchesSemantics(
        label: 'Create habit',
        isButton: true,
        hasEnabledState: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('the keyboard focuses a control and Enter activates it', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      centredHost(MinimalButton('Create habit', onPressed: () => taps += 1)),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('a busy button leads with a spinner, takes no presses and does '
      'not dim', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      centredHost(
        MinimalButton('Creating…', busy: true, onPressed: () => taps += 1),
      ),
    );
    await tester.tap(find.text('Creating…'), warnIfMissed: false);
    await tester.pump();
    expect(taps, 0);
    // A spinner, painted in the label's ink, before the words.
    final mark = find.descendant(
      of: find.byType(MinimalButton),
      matching: find.byType(RotationTransition),
    );
    expect(mark, findsOneWidget);
    expect(
      tester.getRect(mark).right,
      lessThan(tester.getRect(find.text('Creating…')).left),
    );
    // Busy is not disabled: nothing fades the face.
    final faded = tester
        .widgetList<AnimatedOpacity>(
          find.descendant(
            of: find.byType(MinimalButton),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .where((o) => o.opacity < 1);
    expect(faded, isEmpty);
  });
}
