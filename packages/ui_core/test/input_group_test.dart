import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

late Set<WidgetState> _states;

// The bare reference painter: a frame whose border follows the states, a
// unit add-on and a clear button add-on.
Widget _group({
  required FocusNode field,
  required TextEditingController text,
  FocusNode? button,
  bool enabled = true,
  bool error = false,
  VoidCallback? onClear,
}) => DesignInputGroup(
  focusNode: field,
  enabled: enabled,
  isError: error,
  builder: (context, states, child) {
    _states = states;
    return Container(
      key: const ValueKey('frame'),
      padding: const EdgeInsets.all(4),
      color: states.contains(WidgetState.focused)
          ? const Color(0xFF0000FF)
          : const Color(0xFFCCCCCC),
      child: child,
    );
  },
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('kg', key: ValueKey('unit')),
      plainField(controller: text, focusNode: field, width: 100),
      DesignPressable(
        focusNode: button,
        onPressed: onClear ?? text.clear,
        semanticLabel: 'Clear',
        // The glyph is not part of the name.
        excludeSemantics: true,
        minimumSize: const Size(44, 44),
        builder: (context, states, _) => const Text('x'),
      ),
    ],
  ),
);

void main() {
  final groupField = FocusNode();
  final groupText = TextEditingController(text: '5');
  tearDownAll(() {
    groupField.dispose();
    groupText.dispose();
  });
  behaviourContract(
    'DesignInputGroup',
    build: (c) => Center(
      child: _group(
        field: groupField,
        text: groupText,
        enabled: c.enabled,
        error: c.error,
      ),
    ),
    node: () => find.byType(EditableText),
    root: () => find.byType(DesignInputGroup),
    semantics: isSemantics(isTextField: true, isFocusable: true),
    // A text field's node always says focusable (RenderEditable); Tab
    // passing the whole group by is the check.
    disabled: isSemantics(isTextField: true),
    hidden: ['x'],
    keyboard: (p) async {
      await p.tabInto();
      await p.tab();
      expect(
        p.tester.getSemantics(find.bySemanticsLabel('Clear')),
        isSemantics(isFocused: true),
        reason: 'an add-on is its own tab stop',
      );
      await p.key(LogicalKeyboardKey.enter);
      expect(groupText.text, isEmpty);
    },
    rtl: (p) async {
      expect(
        p.tester.getCenter(find.byKey(const ValueKey('unit'))).dx,
        greaterThan(p.tester.getCenter(p.node).dx),
        reason: 'the leading add-on is on the right',
      );
    },
  );

  final passwordField = FocusNode();
  final passwordText = TextEditingController(text: 'hunter2');
  tearDownAll(() {
    passwordField.dispose();
    passwordText.dispose();
  });
  behaviourContract(
    'DesignPasswordReveal',
    build: (c) => Center(
      child: DesignPasswordReveal(
        focusNode: passwordField,
        builder: (context, password) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            plainField(
              controller: passwordText,
              focusNode: passwordField,
              obscureText: password.obscured,
            ),
            DesignPressable(
              onPressed: password.toggle,
              semanticLabel: password.toggleLabel,
              excludeSemantics: true,
              minimumSize: const Size(48, 48),
              builder: (context, states, _) => const Text('eye'),
            ),
          ],
        ),
      ),
    ),
    node: () => find.byType(EditableText),
    semantics: isSemantics(isTextField: true, isObscured: true),
    noDisabledState:
        'the field and its toggle are the look\'s; the reveal only holds '
        'whether the password shows',
    hidden: ['eye'],
    keyboard: (p) async {
      await p.tabInto();
      await p.tab();
      expect(
        p.tester.getSemantics(find.bySemanticsLabel('Show password')),
        isSemantics(isButton: true, isFocused: true),
        reason: 'the toggle says what it will do',
      );
      await p.key(LogicalKeyboardKey.space);
      expect(p.data.flagsCollection.isObscured, isFalse, reason: 'shown');
      expect(find.bySemanticsLabel('Hide password'), findsOneWidget);
    },
  );

  testWidgets('a tap on a plain add-on puts the caret in the field; its '
      'button keeps its own press', (tester) async {
    final field = FocusNode();
    final text = TextEditingController(text: '12');
    addTearDown(field.dispose);
    addTearDown(text.dispose);
    await tester.pumpWidget(
      harness(
        Center(
          child: _group(field: field, text: text),
        ),
      ),
    );
    expect(_states, isEmpty);
    await tester.tap(find.byKey(const ValueKey('unit')));
    await tester.pump();
    expect(field.hasPrimaryFocus, isTrue);
    expect(_states, contains(WidgetState.focused));

    await tester.tap(find.text('x'));
    await tester.pump();
    expect(text.text, isEmpty);
    expect(field.hasPrimaryFocus, isTrue, reason: 'the button took no focus');
  });

  testWidgets('focus on an add-on lights the whole group; a pointer over '
      'it hovers it', (tester) async {
    final field = FocusNode();
    final button = FocusNode();
    final text = TextEditingController();
    addTearDown(field.dispose);
    addTearDown(button.dispose);
    addTearDown(text.dispose);
    await tester.pumpWidget(
      harness(
        Center(
          child: _group(field: field, text: text, button: button),
        ),
      ),
    );
    field.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(button.hasPrimaryFocus, isTrue);
    expect(_states, contains(WidgetState.focused));

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byKey(const ValueKey('unit'))));
    await tester.pump();
    expect(_states, contains(WidgetState.hovered));
    await mouse.moveTo(Offset.zero);
    await tester.pump();
    expect(_states, isNot(contains(WidgetState.hovered)));
  });

  testWidgets('disabling a focused group takes the caret out of its field', (
    tester,
  ) async {
    final field = FocusNode();
    final text = TextEditingController();
    addTearDown(field.dispose);
    addTearDown(text.dispose);
    Widget group({required bool enabled}) => harness(
      Center(
        child: _group(field: field, text: text, enabled: enabled),
      ),
    );
    await tester.pumpWidget(group(enabled: true));
    field.requestFocus();
    await tester.pump();
    expect(_states, contains(WidgetState.focused));
    await tester.pumpWidget(group(enabled: false));
    await tester.pump();
    expect(field.hasFocus, isFalse);
    expect(_states, isNot(contains(WidgetState.focused)));
    expect(_states, contains(WidgetState.disabled));
  });

  testWidgets('disabled: no focus from a tap, and the states say so; error '
      'reaches the frame', (tester) async {
    final field = FocusNode();
    final text = TextEditingController();
    addTearDown(field.dispose);
    addTearDown(text.dispose);
    await tester.pumpWidget(
      harness(
        Center(
          child: _group(field: field, text: text, enabled: false, error: true),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('unit')));
    await tester.pump();
    expect(field.hasFocus, isFalse);
    expect(_states, containsAll([WidgetState.disabled, WidgetState.error]));
  });

  testWidgets('the reveal flips the field, keeps its focus and caret, and '
      'says what it will do', (tester) async {
    final field = FocusNode();
    final text = TextEditingController(text: 'hunter2');
    addTearDown(field.dispose);
    addTearDown(text.dispose);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      harness(
        Center(
          child: DesignPasswordReveal(
            focusNode: field,
            builder: (context, password) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                plainField(
                  controller: text,
                  focusNode: field,
                  obscureText: password.obscured,
                ),
                DesignPressable(
                  onPressed: password.toggle,
                  semanticLabel: password.toggleLabel,
                  excludeSemantics: true,
                  toggled: !password.obscured,
                  minimumSize: const Size(48, 48),
                  builder: (context, states, _) => const Text('eye'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    EditableText editable() =>
        tester.widget<EditableText>(find.byType(EditableText));
    expect(editable().obscureText, isTrue);
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    text.selection = const TextSelection.collapsed(offset: 3);
    expect(find.bySemanticsLabel('Show password'), findsOneWidget);

    await tester.tap(find.text('eye'));
    await tester.pump();
    expect(editable().obscureText, isFalse);
    expect(field.hasPrimaryFocus, isTrue);
    expect(text.selection.baseOffset, 3);
    expect(find.bySemanticsLabel('Hide password'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('hideOnBlur hides a shown password when focus leaves', (
    tester,
  ) async {
    final field = FocusNode();
    final text = TextEditingController(text: 'secret');
    final controller = DesignPasswordController(obscured: false);
    addTearDown(field.dispose);
    addTearDown(text.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      harness(
        Center(
          child: DesignPasswordReveal(
            focusNode: field,
            controller: controller,
            hideOnBlur: true,
            builder: (context, password) => plainField(
              controller: text,
              focusNode: field,
              obscureText: password.obscured,
            ),
          ),
        ),
      ),
    );
    field.requestFocus();
    await tester.pump();
    expect(controller.obscured, isFalse);
    field.unfocus();
    await tester.pump();
    expect(controller.obscured, isTrue);
  });

  testWidgets('a reveal follows a new controller and a new focus node', (
    tester,
  ) async {
    final first = FocusNode();
    final second = FocusNode();
    final text = TextEditingController(text: 'secret');
    final controller = DesignPasswordController(obscured: false);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    addTearDown(text.dispose);
    addTearDown(controller.dispose);
    late DesignPasswordDetails shown;
    Widget reveal(FocusNode node, DesignPasswordController? c) => harness(
      Center(
        child: DesignPasswordReveal(
          focusNode: node,
          controller: c,
          hideOnBlur: true,
          builder: (context, password) {
            shown = password;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                plainField(
                  controller: text,
                  focusNode: node,
                  obscureText: password.obscured,
                ),
                // The other node stays in the tree, to take focus.
                Focus(
                  focusNode: identical(node, first) ? second : first,
                  child: const SizedBox(width: 10, height: 10),
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpWidget(reveal(first, null));
    expect(shown.obscured, isTrue, reason: 'its own, hidden');
    await tester.pumpWidget(reveal(first, controller));
    expect(shown.obscured, isFalse, reason: 'the given one, shown');
    controller.toggle();
    await tester.pump();
    expect(shown.obscured, isTrue);
    expect(shown.toggleLabel, 'Show password');
    controller.toggle();
    await tester.pump();
    expect(shown.toggleLabel, 'Hide password');

    await tester.pumpWidget(reveal(second, controller));
    second.requestFocus();
    await tester.pump();
    second.unfocus();
    await tester.pump();
    expect(controller.obscured, isTrue, reason: 'the new node\'s blur hides');
    controller.toggle();
    first.requestFocus();
    await tester.pump();
    first.unfocus();
    await tester.pump();
    expect(controller.obscured, isFalse, reason: 'the old node is let go');

    await tester.pumpWidget(reveal(second, null));
    expect(shown.obscured, isTrue, reason: 'back on its own');
    controller.toggle();
    await tester.pump();
    expect(shown.obscured, isTrue, reason: 'the old controller is let go');
  });
}
