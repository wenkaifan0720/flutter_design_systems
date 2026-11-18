import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const _fieldKey = Key('number');
DesignNumberFieldDetails? _details;
final Map<bool, DesignNumberFieldButtonDetails> _buttons = {};

// The bare reference painter: an input, and two 44-point buttons.
Widget _field(BuildContext context, DesignNumberFieldDetails d) {
  _details = d;
  return SizedBox(
    width: 120,
    height: 44,
    child: EditableText(
      key: _fieldKey,
      controller: d.controller,
      focusNode: d.focusNode,
      keyboardType: d.keyboardType,
      inputFormatters: d.inputFormatters,
      readOnly: d.states.contains(WidgetState.disabled),
      onEditingComplete: d.onEditingComplete,
      style: const TextStyle(fontSize: 16),
      cursorColor: const Color(0xFF000000),
      backgroundCursorColor: const Color(0xFF808080),
    ),
  );
}

Widget _button(BuildContext context, DesignNumberFieldButtonDetails d) {
  _buttons[d.isIncrement] = d;
  return SizedBox(
    width: 44,
    height: 44,
    child: Center(child: Text(d.isIncrement ? '+' : '−')),
  );
}

late _HostState _host;

class _Host extends StatefulWidget {
  const _Host({
    this.value,
    this.enabled = true,
    this.min,
    this.max,
    this.step = 1,
    this.fractionDigits,
    this.locale,
    this.say,
  });

  final double? value;
  final bool enabled;
  final double? min;
  final double? max;
  final double step;
  final int? fractionDigits;
  final Locale? locale;
  final String Function(double)? say;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late double? value = widget.value;
  final List<double?> sent = [];

  void set(double? next) => setState(() => value = next);

  @override
  Widget build(BuildContext context) {
    _host = this;
    final field = Align(
      alignment: Alignment.topLeft,
      child: DesignNumberField(
        value: value,
        semanticLabel: 'Quantity',
        min: widget.min,
        max: widget.max,
        step: widget.step,
        fractionDigits: widget.fractionDigits,
        semanticFormatterCallback: widget.say,
        onChanged: widget.enabled
            ? (next) => setState(() {
                sent.add(next);
                value = next;
              })
            : null,
        fieldBuilder: _field,
        buttonBuilder: _button,
      ),
    );
    final locale = widget.locale;
    if (locale == null) return field;
    final direction = Directionality.of(context);
    return Localizations(
      locale: locale,
      delegates: const [
        DesignLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: Directionality(textDirection: direction, child: field),
    );
  }
}

String _text(WidgetTester tester) =>
    tester.widget<EditableText>(find.byKey(_fieldKey)).controller.text;

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

// Types [text] as a phone keyboard would, through the input's formatters.
Future<void> _typeText(WidgetTester tester, String text) async {
  await tester.showKeyboard(find.byKey(_fieldKey));
  tester.testTextInput.updateEditingValue(
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    ),
  );
  await tester.pump();
}

// Enter: the input's editing-complete action.
Future<void> _enter(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

void main() {
  setUp(() {
    _details = null;
    _buttons.clear();
  });

  behaviourContract(
    'DesignNumberField',
    build: (c) => _Host(value: 2, min: 0, max: 10, enabled: c.enabled),
    node: () => find.byKey(_fieldKey),
    root: () => find.byType(DesignNumberField),
    semantics: isSemantics(
      label: 'Quantity',
      value: '2',
      increasedValue: '3',
      decreasedValue: '1',
      isTextField: true,
      isFocusable: true,
      hasEnabledState: true,
      isEnabled: true,
      hasIncreaseAction: true,
      hasDecreaseAction: true,
    ),
    disabled: isSemantics(
      label: 'Quantity',
      value: '2',
      isTextField: true,
      isReadOnly: true,
      hasEnabledState: true,
      isEnabled: false,
      hasIncreaseAction: false,
      hasDecreaseAction: false,
    ),
    // The buttons' faces are drawn; the field itself is adjustable.
    hidden: const ['−', '+'],
    keyboard: (p) async {
      await p.tabInto();
      expect(_details!.states, contains(WidgetState.focused));
      await p.key(LogicalKeyboardKey.arrowUp);
      expect(_host.value, 3);
      expect(_text(p.tester), '3');
      await p.key(LogicalKeyboardKey.arrowDown);
      await p.key(LogicalKeyboardKey.arrowDown);
      expect(_host.value, 1);
      await p.key(LogicalKeyboardKey.pageUp);
      expect(_host.value, 10, reason: 'ten steps, held at the greatest');
      expect(_buttons[true]!.states, contains(WidgetState.disabled));
      await p.key(LogicalKeyboardKey.pageDown);
      expect(_host.value, 0);
      expect(_buttons[false]!.states, contains(WidgetState.disabled));
      await p.key(LogicalKeyboardKey.end);
      expect(_host.value, 0, reason: 'Home and End are the caret\'s');
      // Enter takes what is typed and keeps the focus.
      p.tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '7',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await p.tester.pump();
      await _enter(p.tester);
      expect(_host.value, 7);
      expect(p.focused, isTrue, reason: 'Enter keeps the focus');
    },
    rtl: (p) async {
      // Decrement, field, increment in reading order: mirrored.
      expect(
        p.tester.getCenter(find.text('−')).dx,
        greaterThan(p.tester.getCenter(find.text('+')).dx),
      );
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowUp);
      expect(_host.value, 3, reason: 'Up is up');
    },
  );

  group('typing', () {
    testWidgets('a number is taken on Enter or as the focus leaves, not on '
        'each key', (tester) async {
      await tester.pumpWidget(harness(const _Host(value: 2)));
      await _typeText(tester, '42');
      expect(_host.sent, isEmpty);
      await _enter(tester);
      expect(_host.sent, [42]);
      await _typeText(tester, '7');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(_host.sent, [42, 7]);
      await _typeText(tester, '');
      await _enter(tester);
      expect(_host.sent.last, isNull, reason: 'cleared');
    });

    testWidgets('clamped to the bounds, rounded to the step\'s decimals', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(const _Host(value: 1, min: 0, max: 5, step: 0.5)),
      );
      await _typeText(tester, '1.3');
      await _enter(tester);
      expect(_host.value, 1.3, reason: 'not moved onto the step');
      expect(_text(tester), '1.3');
      await _typeText(tester, '1.25');
      await _enter(tester);
      expect(_host.value, 1.3, reason: 'one decimal, as 0.5 has');
      await _typeText(tester, '99');
      await _enter(tester);
      expect(_host.value, 5);
      await _typeText(tester, '2');
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_host.value, 2.5, reason: 'a step takes typed text first');
    });

    testWidgets('fractionDigits keeps more decimals than the step has', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(const _Host(value: 1, step: 0.1, fractionDigits: 3)),
      );
      await _typeText(tester, '1.23456');
      await _enter(tester);
      expect(_host.value, 1.235);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_host.value, 1.3, reason: 'the next multiple of 0.1');
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_host.value, 1.4);
    });

    testWidgets('a step counts from the least value', (tester) async {
      await tester.pumpWidget(harness(const _Host(value: 4, min: 3, step: 5)));
      await tester.showKeyboard(find.byKey(_fieldKey));
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_host.value, 8);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_host.value, 13);
    });

    testWidgets('the default step of 1: no decimal key, no decimals typed; a '
        'least of 0: no minus', (tester) async {
      await tester.pumpWidget(harness(const _Host(value: 4, min: 0)));
      final type = _details!.keyboardType;
      expect(type.decimal, isFalse);
      expect(type.signed, isFalse);
      await _typeText(tester, '4.5');
      expect(_text(tester), '4', reason: 'the decimal point is refused');
      await _typeText(tester, '-4');
      expect(_text(tester), '4', reason: 'the minus is refused');
      await _typeText(tester, '4x');
      expect(_text(tester), '4', reason: 'a letter is refused');
      await _typeText(tester, '1,23');
      expect(_text(tester), '1,23', reason: 'grouping as it is typed');
      expect(
        _details!.states,
        contains(WidgetState.error),
        reason: 'does not read yet',
      );
      await _typeText(tester, '1,234');
      expect(_details!.states, isNot(contains(WidgetState.error)));
      await _enter(tester);
      expect(_host.value, 1234);
      expect(_text(tester), '1,234');
    });

    testWidgets('no least value: a minus, on its way to a number', (
      tester,
    ) async {
      await tester.pumpWidget(harness(const _Host(value: 0.25, step: 0.01)));
      expect(_details!.keyboardType.decimal, isTrue);
      expect(_details!.keyboardType.signed, isTrue);
      await _typeText(tester, '-');
      expect(_text(tester), '-');
      await _typeText(tester, '-3.');
      expect(_text(tester), '-3.');
      await _typeText(tester, '-3.14159');
      await _enter(tester);
      expect(_host.value, -3.14);
    });

    testWidgets('text that does not read puts the last value back', (
      tester,
    ) async {
      await tester.pumpWidget(harness(const _Host(value: 8)));
      await _typeText(tester, '-');
      expect(_details!.states, contains(WidgetState.error));
      await _enter(tester);
      expect(_host.sent, isEmpty);
      expect(_text(tester), '8');
      expect(_details!.states, isNot(contains(WidgetState.error)));
    });

    testWidgets('an empty field starts at its least value', (tester) async {
      await tester.pumpWidget(harness(const _Host(min: 5, max: 9)));
      await tester.showKeyboard(find.byKey(_fieldKey));
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_host.value, 5);
    });

    testWidgets('an empty field with no least value starts at 0, or the '
        'greatest below it', (tester) async {
      await tester.pumpWidget(harness(const _Host(max: -2)));
      await tester.showKeyboard(find.byKey(_fieldKey));
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_host.value, -2);
    });
  });

  group('the reader\'s numbers', () {
    testWidgets('German: 1.234,5 shown, typed and read', (tester) async {
      await tester.pumpWidget(
        harness(const _Host(value: 1234.5, step: 0.5, locale: Locale('de'))),
      );
      expect(_text(tester), '1.234,5');
      await _typeText(tester, '2.000,5');
      await _enter(tester);
      expect(_host.value, 2000.5);
    });

    testWidgets('German whole numbers: the dot groups, the comma is refused', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(const _Host(value: 1, locale: Locale('de'))),
      );
      await _typeText(tester, '1.000');
      expect(_text(tester), '1.000');
      await _typeText(tester, '1,5');
      expect(_text(tester), '1.000');
    });

    testWidgets('Arabic: its digits shown; its digits or ASCII typed', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const _Host(value: 12, locale: Locale('ar')),
          textDirection: TextDirection.rtl,
        ),
      );
      expect(_text(tester), '١٢');
      await _typeText(tester, '٣٤');
      await _enter(tester);
      expect(_host.value, 34);
      await _typeText(tester, '56');
      await _enter(tester);
      expect(_host.value, 56);
      expect(_text(tester), '٥٦');
    });
  });

  group('the buttons', () {
    testWidgets('a press steps once; a hold repeats until the limit', (
      tester,
    ) async {
      await tester.pumpWidget(harness(const _Host(value: 1, max: 6)));
      await tester.tap(find.text('+'));
      await tester.pump();
      expect(_host.value, 2);
      final hold = await tester.startGesture(tester.getCenter(find.text('+')));
      await tester.pump();
      expect(_host.value, 3);
      expect(_buttons[true]!.states, contains(WidgetState.pressed));
      await tester.pump(const Duration(milliseconds: 399));
      expect(_host.value, 3, reason: 'not before the delay');
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 80));
      expect(_host.value, 4);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump(const Duration(milliseconds: 80));
      expect(_host.value, 6);
      expect(_buttons[true]!.states, contains(WidgetState.disabled));
      await tester.pump(const Duration(milliseconds: 400));
      expect(_host.value, 6);
      await hold.up();
      await tester.pump();
      await tester.tap(find.text('−'));
      await tester.pump();
      expect(_host.value, 5);
    });

    testWidgets('a hold let go stops; a pointer over one hovers it', (
      tester,
    ) async {
      await tester.pumpWidget(harness(const _Host(value: 1)));
      final hold = await tester.startGesture(tester.getCenter(find.text('−')));
      await tester.pump();
      await hold.up();
      await tester.pump(const Duration(seconds: 1));
      expect(_host.sent, [0]);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text('+')));
      await tester.pump();
      expect(_buttons[true]!.states, contains(WidgetState.hovered));
      expect(_details!.states, contains(WidgetState.hovered));
      await mouse.moveTo(const Offset(700, 500));
      await tester.pump();
      expect(_buttons[true]!.states, isNot(contains(WidgetState.hovered)));
      await mouse.removePointer();
    });

    testWidgets('they are no tab stops', (tester) async {
      await tester.pumpWidget(harness(const _Host(value: 1)));
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_details!.focusNode.hasFocus, isTrue);
      await _key(tester, LogicalKeyboardKey.tab);
      expect(
        _details!.focusNode.hasFocus,
        isTrue,
        reason: 'the field is the only stop: Tab comes back to it',
      );
    });

    testWidgets('a layoutBuilder places them', (tester) async {
      await tester.pumpWidget(
        harness(
          DesignNumberField(
            value: 1,
            onChanged: (_) {},
            fieldBuilder: _field,
            buttonBuilder: _button,
            layoutBuilder: (context, field, decrement, increment) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                field,
                Column(children: [increment, decrement]),
              ],
            ),
          ),
        ),
      );
      expect(
        tester.getCenter(find.text('+')).dy,
        lessThan(tester.getCenter(find.text('−')).dy),
      );
    });
  });

  group('showing the value', () {
    testWidgets('a parent\'s new value shows, unless the field is being '
        'typed in', (tester) async {
      await tester.pumpWidget(harness(const _Host(value: 1)));
      _host.set(5);
      await tester.pump();
      expect(_text(tester), '5');
      await _typeText(tester, '6');
      _host.set(9);
      await tester.pump();
      expect(_text(tester), '6', reason: 'what is typed stays');
      await _enter(tester);
      expect(_host.value, 6);
    });

    testWidgets('a screen reader hears the next values its way', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        harness(_Host(value: 2, say: (v) => '${v.round()} guests')),
      );
      final node = semanticsOf(tester, find.byKey(_fieldKey));
      expect(node.getSemanticsData().increasedValue, '3 guests');
      semanticsOwner().performAction(node.id, SemanticsAction.increase);
      await tester.pump();
      expect(_host.value, 3);
      semanticsOwner().performAction(node.id, SemanticsAction.decrease);
      await tester.pump();
      expect(_host.value, 2);
      handle.dispose();
    });

    testWidgets('beside an input that says itself whether it is enabled (as '
        "Material's TextField does), the value given round it is the "
        "field's node's, as its docs say", (tester) async {
      final handle = tester.ensureSemantics();
      var value = 2.0;
      await tester.pumpWidget(
        harness(
          StatefulBuilder(
            builder: (context, setState) => Align(
              alignment: Alignment.topLeft,
              child: DesignNumberField(
                value: value,
                semanticLabel: 'Quantity',
                onChanged: (next) => setState(() => value = next ?? value),
                fieldBuilder: (context, field) => ListenableBuilder(
                  listenable: field.controller,
                  builder: (context, child) =>
                      Semantics(value: field.controller.text, child: child),
                  // Material's TextField says on its own node that it is
                  // enabled, as ui_core's node does: the two stay apart.
                  child: Semantics(
                    enabled: true,
                    child: _field(context, field),
                  ),
                ),
                buttonBuilder: _button,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final node = semanticsOf(tester, find.byType(DesignNumberField));
      expect(
        semanticsOf(tester, find.byKey(_fieldKey)).id,
        isNot(node.id),
        reason: 'the input stands in a node of its own',
      );
      var data = node.getSemanticsData();
      expect(data.label, 'Quantity');
      expect(data.value, '2');
      expect(data.increasedValue, '3');
      expect(data.decreasedValue, '1');
      semanticsOwner().performAction(node.id, SemanticsAction.increase);
      await tester.pump();
      expect(tester.takeException(), isNull);
      data = node.getSemanticsData();
      expect(value, 3);
      expect(data.value, '3');
      expect(data.increasedValue, '4');
      handle.dispose();
    });
  });

  group('the rest of a field\'s life', () {
    testWidgets('turned off while focused: the focus goes', (tester) async {
      await tester.pumpWidget(harness(const _Host(value: 1)));
      await tester.showKeyboard(find.byKey(_fieldKey));
      expect(_details!.focusNode.hasFocus, isTrue);
      await tester.pumpWidget(harness(const _Host(value: 1, enabled: false)));
      await tester.pump();
      expect(_details!.focusNode.hasFocus, isFalse);
      expect(_details!.states, contains(WidgetState.disabled));
      expect(_buttons[true]!.states, contains(WidgetState.disabled));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.tap(find.text('+'));
      expect(_host.sent, isEmpty);
    });

    testWidgets('a caller\'s controller is used and outlives the field', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        harness(
          DesignNumberField(
            value: 3,
            onChanged: (_) {},
            controller: controller,
            fieldBuilder: _field,
            buttonBuilder: _button,
          ),
        ),
      );
      expect(controller.text, '3');
      await tester.pumpWidget(harness(const SizedBox()));
      expect(() => controller.addListener(() {}), returnsNormally);
    });

    test('diagnostics name what it was given', () {
      const field = DesignNumberField(
        value: 1,
        onChanged: null,
        fieldBuilder: _field,
        buttonBuilder: _button,
        min: 0,
        step: 0.5,
        autofocus: true,
      );
      expect(
        field.toDiagnosticsNode().getProperties().map((p) => p.name),
        containsAll(['value', 'onChanged', 'min', 'step', 'autofocus']),
      );
    });
  });
}
