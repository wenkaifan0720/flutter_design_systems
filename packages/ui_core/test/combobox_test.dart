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
}) => DesignCombobox<String>(
  options: options,
  search: search,
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
    expect(_lit('Apricot'), isTrue, reason: 'Down stops at the last');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(_lit('Apple'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_lit('Apricot'), isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(taken, 'Apricot');
    expect(find.text('Apple'), findsNothing, reason: 'the list closed');
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.controller.text, 'Apricot');
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
}
