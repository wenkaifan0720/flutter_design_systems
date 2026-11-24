// How focus arrived: from the keys, from a pointer (on the web with
// semantics on, the browser focuses the pressed control's node before Flutter
// hears the press), or given back as a surface closes. Rings and tips show for
// the keys; a combobox's list opens for the user's own move, never for focus
// given back.
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

final Map<String, Set<WidgetState>> _states = {};

bool _painted(String label) =>
    _states[label]?.contains(WidgetState.focused) ?? false;

Widget _face(String label, Set<WidgetState> states) {
  _states[label] = states;
  return SizedBox(
    key: ValueKey(label),
    width: 120,
    height: 44,
    child: Center(child: Text(label)),
  );
}

// A button with a tip, as the looks build one.
Widget _tipped(String label, {VoidCallback? onPressed}) => MergeSemantics(
  child: RawTooltip(
    semanticsTooltip: 'Tip of $label',
    tooltipBuilder: (context, animation) => Text('Tip of $label'),
    child: RawTooltipFocusFix(
      child: RawButton(
        semanticLabel: label,
        onPressed: onPressed ?? () {},
        builder: (context, states, _) => _face(label, states),
      ),
    ),
  ),
);

Widget _button(
  String label, {
  VoidCallback? onPressed,
  bool autofocus = false,
}) => RawButton(
  semanticLabel: label,
  excludeSemantics: true,
  autofocus: autofocus,
  onPressed: onPressed ?? () {},
  builder: (context, states, _) => _face(label, states),
);

// Flutter's own dialog route (not ui_core's), its OK button focused.
Route<void> _flutterDialog() => RawDialogRoute<void>(
  pageBuilder: (context, _, _) => Center(
    child: _button(
      'OK',
      autofocus: true,
      onPressed: () => Navigator.of(context).pop(),
    ),
  ),
);

void _semanticsAction(WidgetTester tester, String label, SemanticsAction type) {
  final node = tester.getSemantics(find.byKey(ValueKey(label)));
  tester.binding.platformDispatcher.onSemanticsActionEvent!(
    SemanticsActionEvent(
      type: type,
      viewId: tester.view.viewId,
      nodeId: node.id,
    ),
  );
}

final _desktop = TargetPlatformVariant.only(TargetPlatform.macOS);

void main() {
  setUp(_states.clear);

  testWidgets(
    'on the web, a click focuses the node before the press: no tip and no '
    'ring while the mouse is held',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        harness(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [_button('Before'), _tipped('Save')],
          ),
        ),
      );
      // The keys moved last.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_painted('Before'), isTrue);
      // The browser's order: the node takes the focus, then the press comes.
      _semanticsAction(tester, 'Save', SemanticsAction.focus);
      await tester.pump();
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<RawTooltipFocusFix>(),
        isNotNull,
        reason: 'the node took the focus',
      );
      expect(
        find.text('Tip of Save'),
        findsNothing,
        reason: 'a pointer brought the focus: no tip',
      );
      expect(_painted('Save'), isFalse, reason: 'nor a ring');
      final mouse = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('Save'))),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Tip of Save'), findsNothing, reason: 'held');
      expect(_painted('Save'), isFalse);
      await mouse.up();
      await mouse.removePointer();
      await tester.pumpAndSettle();
      // A key shows them again.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_painted('Save'), isTrue);
      expect(find.text('Tip of Save'), findsOneWidget);
      semantics.dispose();
    },
    variant: _desktop,
  );

  testWidgets(
    'focus given back as a dialog closes shows the ring the keys left, but '
    'no tip',
    (tester) async {
      await tester.pumpWidget(
        harness(
          Builder(
            builder: (context) => Center(
              child: _tipped(
                'Open',
                onPressed: () => Navigator.of(context).push(
                  RawModalDialogRoute<void>(
                    builder: (context, details) =>
                        Center(child: _button('Close', autofocus: true)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(find.text('Tip of Open'), findsOneWidget, reason: 'a Tab');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Tip of Open'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_painted('Open'), isTrue, reason: 'the keys moved last');
      expect(
        find.text('Tip of Open'),
        findsNothing,
        reason: 'focus given back is no arrival of the keys',
      );
    },
    variant: _desktop,
  );

  for (final closeBy in ['keys', 'mouse']) {
    testWidgets(
      "a combobox given focus back as Flutter's own dialog closes (by the "
      '$closeBy) opens no list',
      (tester) async {
        final focus = FocusNode();
        addTearDown(focus.dispose);
        await tester.pumpWidget(
          harness(
            Align(
              alignment: Alignment.topCenter,
              child: RawCombobox<String>(
                options: const ['Apple', 'Banana', 'Cherry'],
                focusNode: focus,
                semanticLabel: 'Fruit',
                fieldBuilder: (context, field) => plainField(
                  key: const ValueKey('field'),
                  controller: field.controller,
                  focusNode: field.focusNode,
                  onSubmitted: field.submit,
                ),
                optionBuilder: (context, option, states) =>
                    SizedBox(height: 40, child: Text(option)),
              ),
            ),
          ),
        );
        await tester.tap(find.byKey(const ValueKey('field')));
        await tester.pumpAndSettle();
        expect(find.text('Banana'), findsOneWidget, reason: 'a tap opens it');
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('Banana'), findsNothing);
        expect(focus.hasFocus, isTrue);
        // A dialog over it (a shortcut's, say), closed.
        tester
            .state<NavigatorState>(find.byType(Navigator))
            .push(_flutterDialog());
        await tester.pumpAndSettle();
        expect(focus.hasFocus, isFalse);
        if (closeBy == 'keys') {
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        } else {
          await tester.tap(
            find.byKey(const ValueKey('OK')),
            kind: PointerDeviceKind.mouse,
          );
        }
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('OK')), findsNothing);
        expect(focus.hasFocus, isTrue, reason: 'Flutter gives the focus back');
        expect(
          find.text('Banana'),
          findsNothing,
          reason: 'focus given back is not the user opening the list',
        );
        // The user's own move still opens it.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(find.text('Banana'), findsOneWidget);
      },
      variant: _desktop,
    );
  }

  testWidgets('a Tab into a combobox still opens its list', (tester) async {
    await tester.pumpWidget(
      harness(
        Column(
          children: [
            _button('Before'),
            RawCombobox<String>(
              options: const ['Apple', 'Banana'],
              semanticLabel: 'Fruit',
              fieldBuilder: (context, field) => plainField(
                controller: field.controller,
                focusNode: field.focusNode,
                onSubmitted: field.submit,
              ),
              optionBuilder: (context, option, states) =>
                  SizedBox(height: 40, child: Text(option)),
            ),
          ],
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text('Banana'), findsOneWidget);
  }, variant: _desktop);
}
