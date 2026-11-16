import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const _fruit = ['Apple', 'Apricot', 'Banana', 'Blueberry', 'Cherry'];
const _fieldKey = ValueKey('field');

// The bare reference painter: a plain field, each option's text marked with
// its states.
final Map<String, Set<WidgetState>> _seen = {};

Widget _option(BuildContext context, String option, Set<WidgetState> states) {
  _seen[option] = states;
  return SizedBox(
    key: ValueKey('option-$option'),
    height: 40,
    child: Text(option),
  );
}

Widget _combobox({
  ValueChanged<String>? onSelected,
  String? value,
  bool requireSelection = false,
  FocusNode? focusNode,
  Iterable<String> options = _fruit,
  double optionsMaxHeight = 300,
  WidgetBuilder? emptyBuilder,
  DesignOptionSearch<String>? search,
  bool Function(String option)? isOptionEnabled,
  bool highlightFollowsPointer = false,
}) => DesignCombobox<String>(
  options: options,
  search: search,
  isOptionEnabled: isOptionEnabled,
  highlightFollowsPointer: highlightFollowsPointer,
  emptyBuilder: emptyBuilder,
  value: value,
  focusNode: focusNode,
  requireSelection: requireSelection,
  onSelected: onSelected,
  optionsMaxHeight: optionsMaxHeight,
  semanticLabel: 'Fruit',
  fieldBuilder: (context, field) => plainField(
    key: _fieldKey,
    controller: field.controller,
    focusNode: field.focusNode,
    onSubmitted: field.submit,
  ),
  optionBuilder: _option,
);

Widget _page(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    harness(
      Align(
        alignment: Alignment.topCenter,
        child: Padding(padding: const EdgeInsets.only(top: 40), child: child),
      ),
      textDirection: direction,
    );

bool _lit(String option) =>
    _seen[option]?.contains(WidgetState.focused) ?? false;

// The options the open list shows, in order.
List<String> _listed() => [
  for (final o in _fruit)
    if (find.byKey(ValueKey('option-$o')).evaluate().isNotEmpty) o,
];

// The one option lit among those shown.
String? _litOne() {
  final lit = _listed().where(_lit).toList();
  return lit.length == 1 ? lit.single : null;
}

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
  String? chosen;
  behaviourContract(
    'DesignCombobox',
    build: (c) => Align(
      alignment: Alignment.topCenter,
      child: _combobox(onSelected: (v) => chosen = v),
    ),
    node: () => find.byKey(_fieldKey),
    semantics: isSemantics(isTextField: true, isFocusable: true),
    noDisabledState:
        'the field is the look\'s (RawAutocomplete\'s model): a look '
        'disables its own field',
    keyboard: (p) async {
      await p.tabInto();
      await p.tester.enterText(find.byKey(_fieldKey), 'ap');
      await p.tester.pumpAndSettle();
      expect(
        p.tester.getSemantics(find.bySemanticsLabel('Fruit')),
        isSemantics(label: 'Fruit'),
        reason: 'the list carries its name',
      );
      await p.key(LogicalKeyboardKey.arrowDown);
      // Enter on a one-line input is its action key.
      await p.tester.testTextInput.receiveAction(TextInputAction.done);
      await p.tester.pumpAndSettle();
      expect(chosen, 'Apricot', reason: 'Down moves, Enter takes');
      await p.tester.enterText(find.byKey(_fieldKey), 'b');
      await p.tester.pumpAndSettle();
      await p.key(LogicalKeyboardKey.escape);
      expect(find.text('Banana'), findsNothing, reason: 'Escape hides it');
      expect(p.focused, isTrue, reason: 'focus stays in the field');
    },
    rtl: (p) async {
      await p.tester.tap(p.node);
      await p.tester.enterText(p.node, 'b');
      await p.tester.pumpAndSettle();
      expect(
        p.tester.getTopRight(find.text('Banana')).dx,
        moreOrLessEquals(p.tester.getTopRight(p.node).dx, epsilon: 1),
        reason: 'the list sits under the field from its start',
      );
    },
  );

  setUp(_seen.clear);

  testWidgets('typing filters; arrows move the highlight; Enter takes it', (
    tester,
  ) async {
    String? taken;
    await tester.pumpWidget(_page(_combobox(onSelected: (o) => taken = o)));
    await tester.tap(find.byKey(_fieldKey));
    await tester.pump();
    await tester.enterText(find.byKey(_fieldKey), 'ap');
    await tester.pumpAndSettle();
    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Apricot'), findsOneWidget);
    expect(find.text('Banana'), findsNothing);
    expect(_lit('Apple'), isTrue, reason: 'the first match starts lit');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_lit('Apricot'), isTrue);
    expect(_lit('Apple'), isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_litOne(), 'Apple', reason: 'Down at the last goes round');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(_litOne(), 'Apricot', reason: 'Up at the first goes round');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(_litOne(), 'Apple');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_litOne(), 'Apricot');

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(taken, 'Apricot');
    expect(find.text('Apple'), findsNothing, reason: 'the list closed');
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.controller.text, 'Apricot');
  });

  testWidgets('opened by a press, Down or a toggle, the list shows every '
      'option, the chosen one lit; Down on a closed list only opens it; the '
      'list filters once the words are edited; Home and End stay with the '
      'text', (tester) async {
    var value = 'Banana';
    const toggle = ValueKey('toggle');
    await tester.pumpWidget(
      _page(
        StatefulBuilder(
          builder: (context, setState) => DesignCombobox<String>(
            options: _fruit,
            value: value,
            onSelected: (o) => setState(() => value = o),
            fieldBuilder: (context, field) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                plainField(
                  key: _fieldKey,
                  controller: field.controller,
                  focusNode: field.focusNode,
                  onSubmitted: field.submit,
                ),
                // A look's chevron: focus opens the list, as a press does.
                GestureDetector(
                  key: toggle,
                  behavior: HitTestBehavior.opaque,
                  onTap: () => field.focusNode.hasFocus
                      ? field.focusNode.unfocus()
                      : field.focusNode.requestFocus(),
                  child: const SizedBox(width: 24, height: 24),
                ),
              ],
            ),
            optionBuilder: _option,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(_fieldKey));
    await tester.pumpAndSettle();
    expect(_listed(), _fruit, reason: 'a press lists every option');
    expect(_litOne(), 'Banana', reason: 'the chosen one lit');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_litOne(), 'Blueberry');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(value, 'Blueberry');
    expect(_listed(), isEmpty, reason: 'taking one closes the list');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(_listed(), _fruit, reason: 'Down reopens it on every option');
    expect(_litOne(), 'Blueberry', reason: 'and only opens it');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(_litOne(), 'Banana');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_listed(), isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(_litOne(), 'Blueberry', reason: 'Up only opens it too');

    await tester.tap(find.byKey(toggle));
    await tester.pumpAndSettle();
    expect(_listed(), isEmpty, reason: 'the toggle closes it');
    await tester.tap(find.byKey(toggle));
    await tester.pumpAndSettle();
    expect(_listed(), _fruit, reason: 'and opens it on every option');
    expect(_litOne(), 'Blueberry');

    TextSelection selection() => tester
        .widget<EditableText>(find.byType(EditableText))
        .controller
        .selection;
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect((selection().baseOffset, selection().extentOffset), (0, 0));
    expect(_litOne(), 'Blueberry', reason: 'Home is the text\'s');
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect((selection().baseOffset, selection().extentOffset), (9, 9));
    expect(_litOne(), 'Blueberry', reason: 'End is the text\'s');

    await tester.enterText(find.byKey(_fieldKey), 'ch');
    await tester.pumpAndSettle();
    expect(_listed(), ['Cherry'], reason: 'edited words filter');
    expect(_litOne(), 'Cherry');
  });

  testWidgets('in an empty field, Down opens every option at the first', (
    tester,
  ) async {
    await tester.pumpWidget(_page(_combobox()));
    await tester.tap(find.byKey(_fieldKey));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_listed(), isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(_listed(), _fruit);
    expect(_litOne(), 'Apple');
  });

  testWidgets('highlightFollowsPointer: the pointer moves the highlight, the '
      'keys go on from there, leaving the list keeps it, a disabled option '
      'never takes it; off, the pointer and the keys are two places', (
    tester,
  ) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    addTearDown(mouse.removePointer);
    Future<void> over(String option) async {
      await mouse.moveTo(tester.getCenter(find.text(option)));
      await tester.pump();
    }

    List<String> hovered() => _listed()
        .where((o) => _seen[o]!.contains(WidgetState.hovered))
        .toList();

    await tester.pumpWidget(
      _page(
        _combobox(
          isOptionEnabled: (o) => o != 'Cherry',
          highlightFollowsPointer: true,
        ),
      ),
    );
    await tester.tap(find.byKey(_fieldKey));
    await tester.pumpAndSettle();
    expect(_litOne(), 'Apple');
    await mouse.moveTo(const Offset(1, 1));
    await over('Banana');
    expect(_litOne(), 'Banana', reason: 'the pointer moves the highlight');
    expect(hovered(), isEmpty, reason: 'one place: no option hovered apart');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_litOne(), 'Blueberry', reason: 'the keys go on from there');
    expect(hovered(), isEmpty);
    await over('Cherry');
    expect(_litOne(), 'Blueberry', reason: 'a disabled option never takes it');
    await mouse.moveTo(const Offset(1, 1));
    await tester.pump();
    expect(_litOne(), 'Blueberry', reason: 'leaving the list keeps it');
    await over('Apricot');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.controller.text, 'Apricot');

    // Off, as by default: the pointer's option is hovered, the keys' lit.
    await mouse.moveTo(const Offset(1, 1));
    await tester.pumpWidget(_page(const SizedBox()));
    _seen.clear();
    await tester.pumpWidget(_page(_combobox()));
    await tester.tap(find.byKey(_fieldKey));
    await tester.pumpAndSettle();
    await mouse.moveTo(const Offset(1, 1));
    await over('Banana');
    expect(_litOne(), 'Apple');
    expect(hovered(), ['Banana']);
  });

  testWidgets('a long list opens on its value in view, and every move keeps '
      'the highlighted row in view, rows of differing heights too', (
    tester,
  ) async {
    const countries = [
      'Austria', 'Belgium', 'Bulgaria', 'Croatia', 'Cyprus', 'Czechia', //
      'Denmark', 'Estonia', 'Finland', 'France', 'Germany', 'Greece', //
      'Hungary', 'Ireland', 'Italy', 'United Kingdom', 'United States', //
    ];
    // 30, 45 and 60 high in turn: the list is about five and a half rows.
    double height(String c) => 30.0 + (countries.indexOf(c) % 3) * 15;
    await tester.pumpWidget(
      _page(
        DesignCombobox<String>(
          options: countries,
          value: 'United Kingdom',
          optionsMaxHeight: 245,
          fieldBuilder: (context, field) => plainField(
            key: _fieldKey,
            controller: field.controller,
            focusNode: field.focusNode,
            onSubmitted: field.submit,
          ),
          optionBuilder: (context, option, states) {
            _seen[option] = states;
            return SizedBox(
              key: ValueKey('option-$option'),
              height: height(option),
              child: Text(option),
            );
          },
        ),
      ),
    );
    String? lit() {
      final on = [
        for (final c in countries)
          if (find.byKey(ValueKey('option-$c')).evaluate().isNotEmpty &&
              (_seen[c]?.contains(WidgetState.focused) ?? false))
            c,
      ];
      return on.length == 1 ? on.single : null;
    }

    void inView(String c, String why) {
      final row = find.byKey(ValueKey('option-$c'));
      expect(row, findsOneWidget, reason: '$why: $c is built');
      final list = tester.getRect(find.byType(ListView));
      final rect = tester.getRect(row);
      expect(
        rect.top >= list.top - 0.5 && rect.bottom <= list.bottom + 0.5,
        isTrue,
        reason: '$why: $c ($rect) lies wholly in the list ($list)',
      );
    }

    Future<void> key(LogicalKeyboardKey key, {bool control = false}) async {
      if (control) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      }
      await tester.sendKeyEvent(key);
      if (control) {
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      }
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byKey(_fieldKey));
    await tester.pumpAndSettle();
    expect(lit(), 'United Kingdom');
    inView('United Kingdom', 'opened');
    await key(LogicalKeyboardKey.arrowDown);
    expect(lit(), 'United States');
    inView('United States', 'Down');
    await key(LogicalKeyboardKey.arrowDown);
    expect(lit(), 'Austria');
    inView('Austria', 'Down round the end');
    await key(LogicalKeyboardKey.arrowUp);
    expect(lit(), 'United States');
    inView('United States', 'Up round the start');
    await key(LogicalKeyboardKey.pageUp);
    expect(lit(), 'Hungary');
    inView('Hungary', 'Page Up');
    await key(LogicalKeyboardKey.arrowUp, control: true);
    expect(lit(), 'Austria');
    inView('Austria', 'Ctrl+Up');
    await key(LogicalKeyboardKey.pageDown);
    expect(lit(), 'Cyprus');
    inView('Cyprus', 'Page Down');
    await key(LogicalKeyboardKey.arrowDown, control: true);
    expect(lit(), 'United States');
    inView('United States', 'Ctrl+Down');
    await key(LogicalKeyboardKey.escape);
    await key(LogicalKeyboardKey.arrowDown);
    expect(lit(), 'United Kingdom', reason: 'reopened on its value');
    inView('United Kingdom', 'reopened');
  });

  testWidgets('a disabled option is passed over, never opened on, and never '
      'taken', (tester) async {
    final taken = <String>[];
    await tester.pumpWidget(
      _page(
        _combobox(
          value: 'Cherry',
          onSelected: taken.add,
          isOptionEnabled: (o) => o != 'Banana' && o != 'Cherry',
        ),
      ),
    );
    await tester.tap(find.byKey(_fieldKey));
    await tester.pumpAndSettle();
    expect(_listed(), _fruit);
    expect(
      _litOne(),
      'Apple',
      reason:
          'the value is disabled: the first '
          'option that can be taken starts lit',
    );
    expect(_seen['Banana'], contains(WidgetState.disabled));
    expect(_seen['Apple'], isNot(contains(WidgetState.disabled)));

    Future<void> key(LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pump();
    }

    await key(LogicalKeyboardKey.arrowDown);
    expect(_litOne(), 'Apricot');
    await key(LogicalKeyboardKey.arrowDown);
    expect(_litOne(), 'Blueberry', reason: 'past Banana');
    await key(LogicalKeyboardKey.arrowDown);
    expect(_litOne(), 'Apple', reason: 'past Cherry, round the end');
    await key(LogicalKeyboardKey.arrowUp);
    expect(_litOne(), 'Blueberry', reason: 'round the start, past Cherry');
    await key(LogicalKeyboardKey.pageUp);
    expect(_litOne(), 'Apple');
    await key(LogicalKeyboardKey.pageDown);
    expect(
      _litOne(),
      'Blueberry',
      reason:
          'four on is Cherry: the nearest '
          'that can be taken',
    );

    await tester.tap(find.text('Banana'));
    await tester.pumpAndSettle();
    expect(taken, isEmpty, reason: 'a tap takes no disabled option');
    expect(_listed(), _fruit);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(taken, ['Blueberry']);
  });

  testWidgets('words nothing matches are told so; Enter takes nothing', (
    tester,
  ) async {
    final taken = <String>[];
    await tester.pumpWidget(
      _page(
        _combobox(
          onSelected: taken.add,
          emptyBuilder: (_) => const Text('No fruit'),
        ),
      ),
    );
    await tester.tap(find.byKey(_fieldKey));
    await tester.pump();
    expect(find.text('No fruit'), findsNothing);
    await tester.enterText(find.byKey(_fieldKey), 'zz');
    await tester.pumpAndSettle();
    expect(find.text('No fruit'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('No fruit'), findsNothing);
    await tester.enterText(find.byKey(_fieldKey), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No fruit'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(taken, isEmpty);
  });

  testWidgets('without an emptyBuilder the list closes when nothing matches', (
    tester,
  ) async {
    await tester.pumpWidget(_page(_combobox()));
    await tester.tap(find.byKey(_fieldKey));
    await tester.enterText(find.byKey(_fieldKey), 'zz');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('option-Apple')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Escape hides the list and focus stays in the field', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(_page(_combobox(focusNode: focus)));
    await tester.tap(find.byKey(_fieldKey));
    await tester.enterText(find.byKey(_fieldKey), 'b');
    await tester.pumpAndSettle();
    expect(find.text('Banana'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Banana'), findsNothing);
    expect(focus.hasPrimaryFocus, isTrue);
  });

  testWidgets('a tap takes an option; the value reads selected', (
    tester,
  ) async {
    String? taken;
    await tester.pumpWidget(
      _page(_combobox(value: 'Cherry', onSelected: (o) => taken = o)),
    );
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.controller.text, 'Cherry');
    await tester.tap(find.byKey(_fieldKey));
    await tester.enterText(find.byKey(_fieldKey), '');
    await tester.pumpAndSettle();
    expect(_seen['Cherry'], contains(WidgetState.selected));
    await tester.tap(find.text('Banana'));
    await tester.pumpAndSettle();
    expect(taken, 'Banana');
  });

  testWidgets('a searchable select puts its value back on blur', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      _page(
        _combobox(value: 'Banana', requireSelection: true, focusNode: focus),
      ),
    );
    await tester.tap(find.byKey(_fieldKey));
    await tester.enterText(find.byKey(_fieldKey), 'zzz');
    await tester.pump();
    focus.unfocus();
    await tester.pumpAndSettle();
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.controller.text, 'Banana');
  });

  testWidgets('the highlight scrolls into view in a long list', (tester) async {
    final many = [for (var i = 0; i < 40; i++) 'Item $i'];
    await tester.pumpWidget(
      _page(_combobox(options: many, optionsMaxHeight: 120)),
    );
    await tester.tap(find.byKey(_fieldKey));
    await tester.enterText(find.byKey(_fieldKey), 'Item');
    await tester.pumpAndSettle();
    for (var i = 0; i < 10; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(_lit('Item 10'), isTrue);
    final list = tester.getRect(find.byType(ListView));
    final item = tester.getRect(find.byKey(const ValueKey('option-Item 10')));
    expect(item.top, greaterThanOrEqualTo(list.top - 0.5));
    expect(item.bottom, lessThanOrEqualTo(list.bottom + 0.5));
  });

  testWidgets('right to left: the list sits under the field, as wide', (
    tester,
  ) async {
    await tester.pumpWidget(_page(_combobox(), direction: TextDirection.rtl));
    await tester.tap(find.byKey(_fieldKey));
    await tester.enterText(find.byKey(_fieldKey), 'a');
    await tester.pumpAndSettle();
    final field = tester.getRect(find.byKey(_fieldKey));
    final list = tester.getRect(find.byType(ListView));
    expect(list.top, greaterThanOrEqualTo(field.bottom - 0.5));
    expect(list.right, moreOrLessEquals(field.right));
    expect(list.width, lessThanOrEqualTo(field.width + 0.5));
  });

  testWidgets('the field\'s node is its frame: a label and a helper beside '
      'it keep nodes of their own, as outside a combobox', (tester) async {
    final semantics = tester.ensureSemantics();
    const frame = ValueKey('frame');
    await tester.pumpWidget(
      _page(
        DesignCombobox<String>(
          options: _fruit,
          fieldBuilder: (context, field) => SizedBox(
            width: 366,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Favourite'),
                SizedBox(
                  key: frame,
                  height: 48,
                  child: plainField(
                    controller: field.controller,
                    focusNode: field.focusNode,
                    width: 366,
                  ),
                ),
                const Text('Pick one you like'),
              ],
            ),
          ),
          optionBuilder: _option,
        ),
      ),
    );
    final node = textFieldNode();
    expect(node.rect.size, tester.getSize(find.byKey(frame)));
    expect(node.label, isEmpty);
    expect(find.bySemanticsLabel('Favourite'), findsOneWidget);
    expect(find.bySemanticsLabel('Pick one you like'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a screen reader finds the list by its label', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_page(_combobox()));
    await tester.tap(find.byKey(_fieldKey));
    await tester.enterText(find.byKey(_fieldKey), 'c');
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Fruit'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('option-Cherry'))),
      isSemantics(isButton: true),
    );
    semantics.dispose();
  });

  testWidgets('a search finds the options, now or later; nothing found is '
      'told so', (tester) async {
    final asked = <String>[];
    await tester.pumpWidget(
      _page(
        _combobox(
          options: const [],
          emptyBuilder: (context) => const Text('No fruit'),
          search: (query) {
            asked.add(query);
            if (query == 'now') return const ['Damson'];
            return Future.delayed(
              const Duration(milliseconds: 50),
              () => query == 'later'
                  ? const ['Elderberry', 'Fig']
                  : const <String>[],
            );
          },
        ),
      ),
    );
    await tester.tap(find.byKey(_fieldKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(_fieldKey), 'now');
    await tester.pumpAndSettle();
    expect(find.text('Damson'), findsOneWidget);
    await tester.enterText(find.byKey(_fieldKey), 'later');
    await tester.pumpAndSettle();
    expect(find.text('Elderberry'), findsOneWidget);
    expect(find.text('Fig'), findsOneWidget);
    expect(find.text('Damson'), findsNothing);
    await tester.enterText(find.byKey(_fieldKey), 'kiwi');
    await tester.pumpAndSettle();
    expect(find.text('No fruit'), findsOneWidget);
    expect(asked, containsAll(['now', 'later', 'kiwi']));
  });

  testWidgets('a new value shows while the field is not focused; a new focus '
      'node takes over', (tester) async {
    final first = FocusNode();
    final second = FocusNode();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    String text() =>
        tester.widget<EditableText>(find.byType(EditableText)).controller.text;
    Widget box(String value, [FocusNode? node]) =>
        _page(_combobox(value: value, focusNode: node, requireSelection: true));
    await tester.pumpWidget(box('Banana', first));
    expect(text(), 'Banana');
    await tester.pumpWidget(box('Cherry', first));
    expect(text(), 'Cherry');

    await tester.pumpWidget(box('Cherry', second));
    await tester.enterText(find.byKey(_fieldKey), 'zzz');
    await tester.pump();
    expect(second.hasFocus, isTrue);
    await tester.pumpWidget(box('Apple', second));
    expect(text(), 'zzz', reason: 'what is typed stays while focused');
    second.unfocus();
    await tester.pumpAndSettle();
    expect(text(), 'Apple', reason: 'the new node\'s blur puts it back');

    await tester.pumpWidget(box('Apple'));
    await tester.enterText(find.byKey(_fieldKey), 'yyy');
    await tester.pump();
    FocusManager.instance.primaryFocus!.unfocus();
    await tester.pumpAndSettle();
    expect(text(), 'Apple', reason: 'its own node, then');
  });

  testWidgets(
    "Android's back closes the open list, focus staying in the field and the "
    'page staying; the next back pops the page',
    (tester) async {
      await _pushed(
        tester,
        Align(
          alignment: Alignment.topCenter,
          child: _combobox(value: 'Banana', options: const ['Apple', 'Banana']),
        ),
      );
      await tester.tap(find.byKey(_fieldKey));
      await tester.pumpAndSettle();
      expect(_listed(), ['Apple', 'Banana']);
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

  testWidgets("Android's back closes a list in a popover before the popover", (
    tester,
  ) async {
    await _pushed(
      tester,
      Align(
        alignment: Alignment.topCenter,
        // A popover with a field in it: focus moves in as it opens.
        child: DesignAnchoredOverlay(
          anchorBuilder: (context, anchor) => DesignPressable(
            onPressed: anchor.toggle,
            builder: (context, states, _) =>
                plainFace('Filter', key: const ValueKey('anchor')),
          ),
          overlayBuilder: (context, info) => _combobox(value: 'Banana'),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('anchor')));
    await tester.pumpAndSettle();
    expect(_fieldFocused(tester), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(_listed(), _fruit);
    await _back(tester);
    expect(_listed(), isEmpty, reason: 'the list closed');
    expect(find.byKey(_fieldKey), findsOneWidget, reason: 'the popover not');
    expect(_fieldFocused(tester), isTrue);
    await _back(tester);
    expect(find.byKey(_fieldKey), findsNothing, reason: 'the popover closed');
    expect(find.byKey(const ValueKey('anchor')), findsOneWidget);
    await _back(tester);
    expect(find.text('Home'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
