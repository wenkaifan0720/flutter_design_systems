// A tooltip over every trigger mode, every input and both directions: what
// shows it, and where its tip lands (above, centred, 4 px clear).
@Tags(['sweep'])
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const _childKey = ValueKey('child');
const _tipKey = ValueKey('tip');

enum _Input { hover, longPress, tap, keyboard }

// Hover and the keyboard's focus show it whatever the mode; a finger shows
// it as the mode says (a long press ends in a tap, which tap mode takes).
bool _shows(TooltipTriggerMode mode, _Input input) => switch (input) {
  _Input.hover || _Input.keyboard => true,
  _Input.longPress => mode != TooltipTriggerMode.manual,
  _Input.tap => mode == TooltipTriggerMode.tap,
};

Widget _page(TooltipTriggerMode mode, TextDirection direction) => harness(
  Center(
    child: DesignTooltip(
      message: 'Save the report',
      triggerMode: mode,
      tooltipBuilder: (context, info) => const SizedBox(
        key: _tipKey,
        width: 140,
        height: 32,
        child: Text('Save the report'),
      ),
      child: const Focus(
        child: SizedBox(
          key: _childKey,
          width: 44,
          height: 44,
          child: Text('i'),
        ),
      ),
    ),
  ),
  textDirection: direction,
);

Future<void> _act(WidgetTester tester, _Input input) async {
  final child = find.byKey(_childKey);
  switch (input) {
    case _Input.hover:
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(child));
      await tester.pump(const Duration(milliseconds: 600));
    case _Input.longPress:
      await tester.longPress(child);
    case _Input.tap:
      await tester.tap(child);
    case _Input.keyboard:
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  }
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  for (final mode in TooltipTriggerMode.values) {
    for (final input in _Input.values) {
      for (final direction in TextDirection.values) {
        final shows = _shows(mode, input);
        testWidgets('${mode.name} mode, ${input.name}, ${direction.name}: '
            '${shows ? 'shows, above and centred' : 'shows nothing'}', (
          tester,
        ) async {
          await tester.pumpWidget(_page(mode, direction));
          await _act(tester, input);
          final tip = find.byKey(_tipKey);
          expect(tip.evaluate().isNotEmpty, shows);
          if (shows) {
            final anchor = tester.getRect(find.byKey(_childKey));
            final rect = tester.getRect(tip);
            expect(rect.bottom, moreOrLessEquals(anchor.top - 4));
            expect(rect.center.dx, moreOrLessEquals(anchor.center.dx));
          }
          DesignTooltip.dismissAll();
          await tester.pumpAndSettle();
          await tester.pump(DesignTooltip.warmUpDuration);
          await tester.pump(const Duration(seconds: 2));
        });
      }
    }
  }
}
