import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const _fieldKey = ValueKey('field');
const _listKey = ValueKey('list');
const _colours = ['Red', 'Green', 'Blue', 'Black'];

// A host that holds the list, as an app does.
class _Host extends StatefulWidget {
  const _Host({this.initial = const [], this.maxTags});

  final List<String> initial;
  final int? maxTags;

  @override
  State<_Host> createState() => _HostState();
}

late _HostState _host;

class _HostState extends State<_Host> {
  late List<String> values = widget.initial;
  final Map<String, bool> focused = {};

  @override
  Widget build(BuildContext context) {
    _host = this;
    return DesignTagInput<String>(
      values: values,
      maxTags: widget.maxTags,
      options: _colours,
      onCreate: (text) => text.toLowerCase(),
      onChanged: (next) => setState(() => values = next),
      fieldBuilder: (context, field) => plainField(
        key: _fieldKey,
        controller: field.controller,
        focusNode: field.focusNode,
        onSubmitted: field.submit,
        width: 120,
      ),
      optionBuilder: (context, option, states) =>
          SizedBox(height: 32, child: Text('option $option')),
      surfaceBuilder: (context, list) =>
          KeyedSubtree(key: _listKey, child: list),
      // The bare reference painter: the label and a remove pressable.
      tagBuilder: (context, value, tag) {
        focused[value] = tag.focused;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('tag $value'),
            DesignPressable(
              onPressed: tag.onDeleted,
              semanticLabel: 'Remove $value',
              // The glyph is not part of the name.
              excludeSemantics: true,
              minimumSize: const Size(44, 44),
              builder: (context, states, _) => const Text('x'),
            ),
          ],
        );
      },
    );
  }
}

Widget _page(Widget child) =>
    harness(Align(alignment: Alignment.topLeft, child: child));

void main() {
  behaviourContract(
    'DesignTagInput',
    build: (c) => const Align(
      alignment: Alignment.topLeft,
      child: _Host(initial: ['Red', 'Blue']),
    ),
    node: () => find.byKey(_fieldKey),
    semantics: isSemantics(isTextField: true, isFocusable: true),
    noDisabledState:
        'the field is the look\'s (RawAutocomplete\'s model); DesignTagInput '
        'takes no enabled of its own (API review)',
    keyboard: (p) async {
      expect(
        p.tester.getSemantics(find.bySemanticsLabel('Remove Red')),
        isSemantics(isButton: true, hasTapAction: true),
        reason: 'each tag can be removed by name',
      );
      await p.tabInto();
      await p.key(LogicalKeyboardKey.backspace);
      expect(_host.focused['Blue'], isTrue, reason: 'Backspace steps back');
      await p.key(LogicalKeyboardKey.backspace);
      expect(_host.values, ['Red'], reason: 'and again removes the tag');
    },
    rtl: (p) async {
      await p.tabInto();
      await p.key(LogicalKeyboardKey.backspace);
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(
        _host.focused['Red'],
        isTrue,
        reason: 'right to left, Right is back',
      );
    },
  );

  testWidgets('a suggestion becomes a tag and leaves the suggestions', (
    tester,
  ) async {
    await tester.pumpWidget(_page(const _Host()));
    await tester.tap(find.byKey(_fieldKey));
    await tester.enterText(find.byKey(_fieldKey), 'bl');
    await tester.pumpAndSettle();
    expect(find.text('option Blue'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(_host.values, ['Blue']);
    expect(find.text('tag Blue'), findsOneWidget);
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.controller.text, isEmpty);

    await tester.enterText(find.byKey(_fieldKey), 'bl');
    await tester.pumpAndSettle();
    expect(find.text('option Blue'), findsNothing);
    expect(find.text('option Black'), findsOneWidget);
  });

  testWidgets('the suggestions open from the whole field, tags and all: on '
      'its leading edge, as wide as it', (tester) async {
    await tester.pumpWidget(_page(const _Host(initial: ['Red', 'Green'])));
    await tester.tap(find.byKey(_fieldKey));
    await tester.enterText(find.byKey(_fieldKey), 'bl');
    await tester.pumpAndSettle();
    final whole = tester.getRect(find.byType(DesignTagInput<String>));
    final entry = tester.getRect(find.byKey(_fieldKey));
    expect(entry.left, greaterThan(whole.left), reason: 'the tags lead');
    final list = tester.getRect(find.byKey(_listKey));
    expect(list.left, whole.left);
    expect(list.top, whole.bottom);
    expect(list.width, whole.width);
  });

  testWidgets('free text: Enter makes a tag; a paste with commas makes '
      'several', (tester) async {
    await tester.pumpWidget(_page(const _Host()));
    await tester.tap(find.byKey(_fieldKey));
    await tester.enterText(find.byKey(_fieldKey), 'teal');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(_host.values, ['teal']);

    await tester.enterText(find.byKey(_fieldKey), 'navy, olive,red, li');
    await tester.pumpAndSettle();
    expect(_host.values, ['teal', 'navy', 'olive', 'Red']);
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.controller.text, 'li', reason: 'the unfinished part stays');
  });

  testWidgets('Backspace on the empty field steps onto the last tag; '
      'Backspace there removes it and focus goes to the one before', (
    tester,
  ) async {
    await tester.pumpWidget(
      _page(const _Host(initial: ['one', 'two', 'three'])),
    );
    await tester.tap(find.byKey(_fieldKey));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(_host.focused['three'], isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(_host.focused['two'], isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    expect(_host.values, ['one', 'three']);
    expect(_host.focused['one'], isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.focusNode.hasPrimaryFocus, isTrue, reason: 'back to typing');
  });

  testWidgets('right to left: Right is back', (tester) async {
    await tester.pumpWidget(
      harness(
        const Align(
          alignment: Alignment.topRight,
          child: _Host(initial: ['a', 'b']),
        ),
        textDirection: TextDirection.rtl,
      ),
    );
    await tester.tap(find.byKey(_fieldKey));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(_host.focused['b'], isTrue);
  });

  testWidgets('maxTags refuses more; the remove control and the screen '
      'reader action remove', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_page(const _Host(initial: ['x'], maxTags: 2)));
    await tester.tap(find.byKey(_fieldKey));
    await tester.enterText(find.byKey(_fieldKey), 'y, z, ');
    await tester.pumpAndSettle();
    expect(_host.values, ['x', 'y']);

    await tester.tap(find.bySemanticsLabel('Remove x'));
    await tester.pumpAndSettle();
    expect(_host.values, ['y']);

    final node = tester.getSemantics(find.text('tag y'));
    final owner = semanticsOwner();
    final remove = node.getSemanticsData().customSemanticsActionIds!.single;
    owner.performAction(node.id, SemanticsAction.customAction, remove);
    await tester.pumpAndSettle();
    expect(_host.values, isEmpty);
    semantics.dispose();
  });
}
