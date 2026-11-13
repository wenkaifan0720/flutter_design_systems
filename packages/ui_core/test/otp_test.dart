import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/semantics.dart'
    show SemanticsAction, SemanticsValidationResult;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

final List<DesignOtpSlot> _slots = [];

// The bare reference painter: a 44 by 44 box per slot, its character, a bar
// under the active one.
Widget _slot(BuildContext context, DesignOtpSlot slot) {
  if (slot.index == 0) _slots.clear();
  _slots.add(slot);
  return Container(
    key: ValueKey('slot-${slot.index}'),
    width: 44,
    height: 44,
    margin: const EdgeInsets.all(2),
    color: slot.active && slot.focused
        ? const Color(0xFF0000FF)
        : const Color(0xFFDDDDDD),
    alignment: Alignment.center,
    child: Text(slot.obscured && slot.filled ? '*' : slot.character),
  );
}

String _shown() => _slots.map((s) => s.character).join();

int _active() => _slots.indexWhere((s) => s.active);

void main() {
  behaviourContract(
    'DesignOtpField',
    build: (c) => Center(
      child: DesignOtpField(
        length: 4,
        enabled: c.enabled,
        isError: c.error,
        semanticLabel: 'Code',
        slotBuilder: _slot,
      ),
    ),
    node: () => find.bySemanticsLabel('Code'),
    // One text field: a tap focuses it (and brings the keyboard back), its
    // length rides the node, and it says when it is wrong.
    semantics: isSemantics(
      label: 'Code',
      isTextField: true,
      isFocusable: true,
      hasTapAction: true,
      hasEnabledState: true,
      isEnabled: true,
      maxValueLength: 4,
      currentValueLength: 0,
      validationResult: SemanticsValidationResult.none,
    ),
    disabled: isSemantics(
      isTextField: true,
      hasEnabledState: true,
      isEnabled: false,
      hasTapAction: false,
    ),
    error: isSemantics(validationResult: SemanticsValidationResult.invalid),
    keyboard: (p) async {
      await p.tabInto();
      await p.tester.enterText(find.byType(EditableText), '12');
      await p.tester.pump();
      expect(p.data.currentValueLength, 2);
      await p.key(LogicalKeyboardKey.backspace);
      expect(p.data.currentValueLength, 1, reason: 'Backspace steps back');
    },
    rtl: (p) async {
      final first = p.tester.getCenter(find.byKey(const ValueKey('slot-0')));
      final second = p.tester.getCenter(find.byKey(const ValueKey('slot-1')));
      expect(
        first.dx,
        lessThan(second.dx),
        reason: 'a code reads left to right',
      );
    },
  );

  testWidgets('typing fills the boxes in order and drops what is not a '
      'digit; it completes once per completion', (tester) async {
    final done = <String>[];
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      harness(
        Center(
          child: DesignOtpField(
            focusNode: focus,
            slotBuilder: _slot,
            onCompleted: done.add,
          ),
        ),
      ),
    );
    // The real input lies over the boxes and takes the tap.
    await tester.tap(find.byKey(const ValueKey('slot-3')), warnIfMissed: false);
    await tester.pump();
    expect(focus.hasPrimaryFocus, isTrue, reason: 'any box focuses the code');
    expect(_active(), 0, reason: 'the caret goes to the first empty box');

    await tester.enterText(find.byType(EditableText), '1a2');
    await tester.pump();
    expect(_shown(), '12');
    expect(_active(), 2);

    await tester.enterText(find.byType(EditableText), '123456');
    await tester.pump();
    expect(done, ['123456']);
    expect(_active(), 5, reason: 'a whole code keeps the caret on the last');

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(_shown(), '12345');
    expect(_active(), 5);
    await tester.enterText(find.byType(EditableText), '123459');
    await tester.pump();
    expect(done, ['123456', '123459']);
  });

  testWidgets('a paste fills every box, cut to length, separators dropped', (
    tester,
  ) async {
    final controller = DesignOtpController(length: 6);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      harness(
        Center(
          child: DesignOtpField(controller: controller, slotBuilder: _slot),
        ),
      ),
    );
    await tester.tap(find.byType(DesignOtpField));
    await tester.enterText(find.byType(EditableText), '12-34 5678');
    await tester.pump();
    expect(_shown(), '123456');

    controller.clear();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == 'Clipboard.getData'
          ? <String, Object?>{'text': ' 987 654 '}
          : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await controller.paste();
    await tester.pump();
    expect(_shown(), '987654');
    expect(controller.isComplete, isTrue);
  });

  testWidgets('a screen reader hears one field by the name given, its '
      'length as the node\'s, invalid when wrong; the boxes stay out of its '
      'way', (tester) async {
    final semantics = tester.ensureSemantics();
    Widget field({bool error = false}) => harness(
      Center(
        child: DesignOtpField(
          length: 4,
          isError: error,
          semanticLabel: 'Code de vérification',
          slotBuilder: _slot,
        ),
      ),
    );
    await tester.pumpWidget(field());
    // The name as given, in the app's language: no English added to it.
    expect(
      tester.getSemantics(find.byType(EditableText)),
      isSemantics(isTextField: true, label: 'Code de vérification'),
    );
    var data = tester
        .getSemantics(find.byType(EditableText))
        .getSemanticsData();
    expect(data.maxValueLength, 4);
    expect(data.currentValueLength, 0);
    expect(data.validationResult, SemanticsValidationResult.none);

    await tester.enterText(find.byType(EditableText), '12');
    await tester.pumpWidget(field(error: true));
    data = tester.getSemantics(find.byType(EditableText)).getSemanticsData();
    expect(data.currentValueLength, 2);
    expect(data.validationResult, SemanticsValidationResult.invalid);
    semantics.dispose();
  });

  testWidgets('a screen reader\'s tap focuses the code; disabled, the node '
      'has no tap', (tester) async {
    final semantics = tester.ensureSemantics();
    Widget field({bool enabled = true}) => harness(
      Center(
        child: DesignOtpField(
          length: 4,
          enabled: enabled,
          semanticLabel: 'Code',
          slotBuilder: _slot,
        ),
      ),
    );
    await tester.pumpWidget(field());
    final focus = tester.widget<EditableText>(find.byType(EditableText));
    expect(focus.focusNode.hasFocus, isFalse);
    final node = tester.getSemantics(find.byType(EditableText));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    semanticsOwner().performAction(node.id, SemanticsAction.tap);
    await tester.pump();
    expect(focus.focusNode.hasFocus, isTrue, reason: 'the tap focuses it');

    await tester.pumpWidget(field(enabled: false));
    expect(
      tester
          .getSemantics(find.byType(EditableText))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isFalse,
    );
    semantics.dispose();
  });

  testWidgets('a long press or a secondary click offers Paste in the look\'s '
      'menu; Paste fills the code and closes it', (tester) async {
    var clipboard = <String, Object?>{'text': '12 34'};
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => switch (call.method) {
        'Clipboard.hasStrings' => <String, Object?>{
          'value': (clipboard['text'] as String?)?.isNotEmpty ?? false,
        },
        'Clipboard.getData' => clipboard,
        _ => null,
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final controller = DesignOtpController(length: 4);
    addTearDown(controller.dispose);
    TextSelectionToolbarAnchors? anchors;
    List<ContextMenuButtonItem>? items;
    Widget menu(
      BuildContext context,
      TextSelectionToolbarAnchors a,
      List<ContextMenuButtonItem> i,
    ) {
      anchors = a;
      items = i;
      return Positioned(
        left: a.primaryAnchor.dx,
        top: a.primaryAnchor.dy,
        child: GestureDetector(
          onTap: i.single.onPressed,
          child: const Text('Paste', key: ValueKey('paste')),
        ),
      );
    }

    await tester.pumpWidget(
      harness(
        Center(
          child: DesignOtpField(
            controller: controller,
            slotBuilder: _slot,
            contextMenuBuilder: menu,
          ),
        ),
      ),
    );
    final centre = tester.getCenter(find.byType(DesignOtpField));
    await tester.longPressAt(centre);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('paste')), findsOneWidget);
    expect(items!.single.type, ContextMenuButtonType.paste);
    expect(anchors!.primaryAnchor, centre);

    await tester.tap(find.byKey(const ValueKey('paste')));
    await tester.pumpAndSettle();
    expect(_shown(), '1234');
    expect(find.byKey(const ValueKey('paste')), findsNothing);

    // A right click opens it too; with nothing to paste, nothing opens.
    controller.clear();
    await tester.tapAt(centre, buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('paste')), findsOneWidget);
    // A tap on the field (clear of the menu, drawn at the press) closes it.
    await tester.tapAt(
      tester.getTopLeft(find.byType(DesignOtpField)) + const Offset(4, 4),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('paste')), findsNothing);
    expect(_shown(), '', reason: 'closing pastes nothing');
    clipboard = <String, Object?>{'text': null};
    await tester.longPressAt(centre);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('paste')), findsNothing);
  });

  testWidgets('right to left: the code still reads left to right', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        Center(child: DesignOtpField(length: 4, slotBuilder: _slot)),
        textDirection: TextDirection.rtl,
      ),
    );
    final first = tester.getRect(find.byKey(const ValueKey('slot-0')));
    final last = tester.getRect(find.byKey(const ValueKey('slot-3')));
    expect(first.left, lessThan(last.left));
  });

  testWidgets('a PIN hides its characters; disabled takes no input', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      harness(
        Center(
          child: DesignOtpField(
            length: 4,
            obscureText: true,
            focusNode: focus,
            slotBuilder: _slot,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(DesignOtpField));
    await tester.enterText(find.byType(EditableText), '42');
    await tester.pump();
    expect(find.text('*'), findsNWidgets(2));
    expect(find.text('4'), findsNothing);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).obscureText,
      isTrue,
    );

    focus.unfocus();
    await tester.pumpWidget(
      harness(
        Center(
          child: DesignOtpField(
            length: 4,
            enabled: false,
            focusNode: focus,
            slotBuilder: _slot,
          ),
        ),
      ),
    );
    // Disabled, it ignores the pointer.
    await tester.tap(find.byType(DesignOtpField), warnIfMissed: false);
    await tester.pump();
    expect(focus.hasFocus, isFalse);
    expect(_slots.every((s) => !s.enabled && !s.active), isTrue);
  });

  testWidgets('a form\'s own input: the code lives in its controller, '
      'filtered, and stays the form\'s', (tester) async {
    final text = TextEditingController(text: '12a3');
    addTearDown(text.dispose);
    final controller = DesignOtpController(length: 4, text: text);
    expect(text.text, '123', reason: 'what it holds is filtered at once');
    final clean = TextEditingController();
    addTearDown(clean.dispose);
    var heard = 0;
    clean.addListener(() => heard++);
    DesignOtpController(length: 4, text: clean).dispose();
    expect(heard, 0, reason: 'a clean input is left alone while it is built');
    String? done;
    await tester.pumpWidget(
      harness(
        Center(
          child: DesignOtpField(
            controller: controller,
            slotBuilder: _slot,
            onCompleted: (v) => done = v,
          ),
        ),
      ),
    );
    expect(_shown(), '123');
    text.text = '1234';
    await tester.pump();
    expect(_shown(), '1234');
    expect(done, '1234');
    await tester.pumpWidget(harness(const SizedBox()));
    controller.dispose();
    expect(text.text, '1234', reason: 'the form\'s input outlives the code');
  });

  testWidgets('the action key is the caller\'s, and its press reaches them; '
      'a caller that names it gets no name of the field\'s own', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var finished = 0;
    await tester.pumpWidget(
      harness(
        Center(
          // A form field's own semantics around it, merged into one node.
          child: MergeSemantics(
            child: Semantics(
              label: 'Code',
              child: DesignOtpField(
                length: 4,
                slotBuilder: _slot,
                semanticLabel: null,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => finished++,
              ),
            ),
          ),
        ),
      ),
    );
    final input = find.byType(EditableText);
    expect(
      tester.widget<EditableText>(input).textInputAction,
      TextInputAction.next,
    );
    expect(
      tester.getSemantics(input),
      isSemantics(isTextField: true, label: 'Code'),
    );
    await tester.showKeyboard(input);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(finished, 1);
    semantics.dispose();
  });

  testWidgets('a form drives the input: its submit, its formatters (the '
      'code\'s filter has the last word), its autofill', (tester) async {
    final submitted = <String>[];
    final text = TextEditingController();
    addTearDown(text.dispose);
    final code = DesignOtpController(
      length: 4,
      allowed: RegExp('[A-Z0-9]'),
      text: text,
    );
    addTearDown(code.dispose);
    await tester.pumpWidget(
      harness(
        Center(
          child: DesignOtpField(
            controller: code,
            slotBuilder: _slot,
            textInputAction: TextInputAction.next,
            onSubmitted: submitted.add,
            autofillHints: const [AutofillHints.postalCode],
            inputFormatters: [
              TextInputFormatter.withFunction(
                (old, value) => value.copyWith(text: value.text.toUpperCase()),
              ),
            ],
          ),
        ),
      ),
    );
    final input = tester.widget<EditableText>(find.byType(EditableText));
    expect(input.autofillHints, [AutofillHints.postalCode]);

    await tester.tap(find.byType(DesignOtpField));
    await tester.enterText(find.byType(EditableText), 'ab-c9z');
    await tester.pump();
    expect(text.text, 'ABC9', reason: 'upper-cased, filtered, then cut');
    expect(_shown(), 'ABC9');

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(submitted, ['ABC9']);
  });
}
