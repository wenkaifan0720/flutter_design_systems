import 'dart:async';

import 'package:flutter/gestures.dart';
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
  const _Host({
    this.initial = const [],
    this.maxTags,
    this.disabled,
    this.follows = false,
  });

  final List<String> initial;
  final int? maxTags;
  final Set<String>? disabled;
  final bool follows;

  @override
  State<_Host> createState() => _HostState();
}

late _HostState _host;

// Each suggestion's states, as last painted.
final Map<String, Set<WidgetState>> _seen = {};

// The suggestions the open list shows.
List<String> _listed() => [
  for (final c in _colours)
    if (find.text('option $c').evaluate().isNotEmpty) c,
];

// The one suggestion lit among those shown.
String? _litOne() {
  final lit = _listed()
      .where((c) => _seen[c]?.contains(WidgetState.focused) ?? false)
      .toList();
  return lit.length == 1 ? lit.single : null;
}

class _HostState extends State<_Host> {
  late List<String> values = widget.initial;
  final Map<String, bool> focused = {};

  @override
  Widget build(BuildContext context) {
    _host = this;
    return RawTagInput<String>(
      values: values,
      maxTags: widget.maxTags,
      options: _colours,
      isOptionEnabled: widget.disabled == null
          ? null
          : (c) => !widget.disabled!.contains(c),
      highlightFollowsPointer: widget.follows,
      onCreate: (text) => text.toLowerCase(),
      onChanged: (next) => setState(() => values = next),
      fieldBuilder: (context, field) => plainField(
        key: _fieldKey,
        controller: field.controller,
        focusNode: field.focusNode,
        onSubmitted: field.submit,
        width: 120,
      ),
      optionBuilder: (context, option, states) {
        _seen[option] = states;
        return SizedBox(height: 32, child: Text('option $option'));
      },
      surfaceBuilder: (context, list) =>
          KeyedSubtree(key: _listKey, child: list),
      // The bare reference painter: the label and a remove pressable.
      tagBuilder: (context, value, tag) {
        focused[value] = tag.focused;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('tag $value'),
            RawButton(
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

// [page] pushed over a home page, as a page an app opens.
Future<void> _pushed(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(harness(const Text('Home')));
  final navigator = tester.state<NavigatorState>(find.byType(Navigator));
  unawaited(
    navigator.push(PageRouteBuilder<void>(pageBuilder: (_, _, _) => page)),
  );
  await tester.pumpAndSettle();
}

// The system's back: Android's button or gesture.
Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

// Whether the field has the focus.
bool _fieldFocused(WidgetTester tester) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byKey(_fieldKey),
        matching: find.byType(EditableText),
        matchRoot: true,
      ),
    )
    .focusNode
    .hasFocus;

void main() {
  testWidgets('suggestions open above the whole field near the bottom', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.only(bottom: 48),
            child: SizedBox(width: 280, child: _Host(initial: ['Red'])),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(_fieldKey));
    await tester.enterText(find.byKey(_fieldKey), 'blu');
    await tester.pumpAndSettle();
    final field = tester.getRect(find.byType(RawAutocomplete<Object>));
    expect(
      tester.getRect(find.byKey(_listKey)).bottom,
      closeTo(field.top, 0.1),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_host.values, ['Red', 'Blue']);
  });

  behaviourContract(
    'RawTagInput',
    build: (c) => const Align(
      alignment: Alignment.topLeft,
      child: _Host(initial: ['Red', 'Blue']),
    ),
    node: () => find.byKey(_fieldKey),
    semantics: isSemantics(isTextField: true, isFocusable: true),
    noDisabledState:
        'the field is the look\'s (RawAutocomplete\'s model); RawTagInput '
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

  setUp(_seen.clear);

  testWidgets('the suggestions\' keys go round the ends, and on a closed '
      'list only open it', (tester) async {
    await tester.pumpWidget(_page(const _Host()));
    await tester.tap(find.byKey(_fieldKey));
    await tester.pumpAndSettle();
    expect(_listed(), _colours);
    expect(_litOne(), 'Red');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(_litOne(), 'Black', reason: 'Up at the first goes round');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_litOne(), 'Red', reason: 'Down at the last goes round');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_litOne(), 'Green');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_listed(), isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(_listed(), _colours);
    expect(_litOne(), 'Red', reason: 'Down only opens it, at the first');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(_host.values, ['Red']);
  });

  testWidgets('highlightFollowsPointer: the pointer moves the suggestions\' '
      'highlight; the keys go on from there; leaving keeps it', (tester) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(700, 500));
    addTearDown(mouse.removePointer);
    await tester.pumpWidget(
      _page(const _Host(disabled: {'Black'}, follows: true)),
    );
    await tester.tap(find.byKey(_fieldKey));
    await tester.pumpAndSettle();
    expect(_litOne(), 'Red');
    await mouse.moveTo(const Offset(700, 500));
    await mouse.moveTo(tester.getCenter(find.text('option Green')));
    await tester.pump();
    expect(_litOne(), 'Green');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_litOne(), 'Blue');
    await mouse.moveTo(tester.getCenter(find.text('option Black')));
    await tester.pump();
    expect(_litOne(), 'Blue', reason: 'a disabled one never takes it');
    await mouse.moveTo(const Offset(700, 500));
    await tester.pump();
    expect(_litOne(), 'Blue', reason: 'leaving the list keeps it');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(_host.values, ['Blue']);
  });

  testWidgets('a disabled suggestion is never added by a comma, Enter or a '
      'paste', (tester) async {
    await tester.pumpWidget(_page(const _Host(disabled: {'Red'})));
    await tester.tap(find.byKey(_fieldKey));
    await tester.enterText(find.byKey(_fieldKey), 'red,');
    await tester.pumpAndSettle();
    expect(_host.values, isEmpty, reason: 'a comma');
    await tester.enterText(find.byKey(_fieldKey), 'Red');
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(_host.values, isEmpty, reason: 'Enter');
    await tester.enterText(find.byKey(_fieldKey), 'red, green, ');
    await tester.pumpAndSettle();
    expect(_host.values, ['Green'], reason: 'a paste takes the rest');
  });

  testWidgets('a disabled suggestion is passed over and never taken', (
    tester,
  ) async {
    await tester.pumpWidget(_page(const _Host(disabled: {'Red', 'Blue'})));
    await tester.tap(find.byKey(_fieldKey));
    await tester.pumpAndSettle();
    expect(_listed(), _colours);
    expect(_litOne(), 'Green', reason: 'the first that can be taken');
    expect(_seen['Red'], contains(WidgetState.disabled));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_litOne(), 'Black', reason: 'past Blue');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_litOne(), 'Green', reason: 'round the end, past Red');
    await tester.tap(find.text('option Red'));
    await tester.pumpAndSettle();
    expect(_host.values, isEmpty, reason: 'a tap takes no disabled one');
    await tester.enterText(find.byKey(_fieldKey), 'bl');
    await tester.pumpAndSettle();
    expect(_listed(), ['Blue', 'Black']);
    expect(_litOne(), 'Black');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(_host.values, ['Black']);
  });

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
    final whole = tester.getRect(find.byType(RawTagInput<String>));
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

  testWidgets('the field\'s node is its frame, not the words or tags beside '
      'it', (tester) async {
    final semantics = tester.ensureSemantics();
    const frame = ValueKey('frame');
    await tester.pumpWidget(
      _page(
        RawTagInput<String>(
          values: const ['Red'],
          options: _colours,
          onChanged: (_) {},
          fieldBuilder: (context, field) => SizedBox(
            width: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Colours'),
                SizedBox(
                  key: frame,
                  height: 48,
                  child: plainField(
                    controller: field.controller,
                    focusNode: field.focusNode,
                  ),
                ),
                const Text('Pick a few'),
              ],
            ),
          ),
          optionBuilder: (context, option, states) => Text(option),
          tagBuilder: (context, value, tag) => Text('tag $value'),
        ),
      ),
    );
    final node = textFieldNode();
    expect(node.rect.size, tester.getSize(find.byKey(frame)));
    expect(node.label, isEmpty);
    expect(find.bySemanticsLabel('Colours'), findsOneWidget);
    semantics.dispose();
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

  testWidgets(
    "Android's back closes the open list, focus staying in the field and the "
    'page staying; the next back pops the page',
    (tester) async {
      await _pushed(
        tester,
        const Align(alignment: Alignment.topLeft, child: _Host()),
      );
      await tester.tap(find.byKey(_fieldKey));
      await tester.pumpAndSettle();
      expect(_listed(), _colours);
      await _back(tester);
      expect(_listed(), isEmpty, reason: 'the back closed the list');
      expect(find.byKey(_fieldKey), findsOneWidget, reason: 'the page stays');
      expect(_fieldFocused(tester), isTrue);
      await _back(tester);
      expect(find.byKey(_fieldKey), findsNothing);
      expect(find.text('Home'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'focus given back to the field by a closing popover opens no list',
    (tester) async {
      final popover = MenuController();
      await _pushed(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Host(),
              RawPopover(
                controller: popover,
                anchorBuilder: (context, anchor) => RawButton(
                  onPressed: anchor.toggle,
                  builder: (context, states, _) => const Text('Filter'),
                ),
                overlayBuilder: (context, info) => RawButton(
                  onPressed: info.close,
                  builder: (context, states, _) =>
                      const Text('Clear', key: ValueKey('item')),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.byKey(_fieldKey));
      await tester.pumpAndSettle();
      expect(_listed(), _colours);
      popover.open();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('item')), findsOneWidget);
      await _back(tester);
      expect(find.byKey(const ValueKey('item')), findsNothing);
      expect(_fieldFocused(tester), isTrue, reason: 'given back to the field');
      expect(_listed(), isEmpty, reason: 'the user did not give it');
      await _back(tester);
      expect(find.text('Home'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
