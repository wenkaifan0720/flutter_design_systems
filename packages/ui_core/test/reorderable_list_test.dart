import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

late _HostState _host;

class _HostState extends State<_Host> {
  List<String> items = ['one', 'two', 'three', 'four'];

  @override
  Widget build(BuildContext context) {
    _host = this;
    return DesignReorderableList<String>(
      items: items,
      labelOf: (item) => item,
      onReorder: (from, to) => setState(() {
        final item = items.removeAt(from);
        items.insert(to, item);
      }),
      // The bare reference painter: the name, a pressable to focus, and a
      // handle.
      itemBuilder: (context, item, reorder) => SizedBox(
        height: 50,
        child: Row(
          children: [
            Expanded(
              child: DesignPressable(
                onPressed: () {},
                builder: (context, states, _) => Text(item),
              ),
            ),
            reorder.handle(
              SizedBox(width: 44, height: 44, child: Text('drag $item')),
            ),
          ],
        ),
      ),
    );
  }
}

// The item [label]'s node: the one with the list's move actions.
Finder _item(String label) => find
    .ancestor(
      of: find.text('drag $label'),
      matching: find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.customSemanticsActions != null,
      ),
    )
    .first;

Finder _press(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(DesignPressable));

Future<void> _alt(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
  await tester.pumpAndSettle();
}

void main() {
  behaviourContract(
    'DesignReorderableList',
    build: (c) => const _Host(),
    node: () => _item('two'),
    semantics: isSemantics(
      customActions: const [
        CustomSemanticsAction(label: 'Move to the start'),
        CustomSemanticsAction(label: 'Move up'),
        CustomSemanticsAction(label: 'Move down'),
        CustomSemanticsAction(label: 'Move to the end'),
      ],
    ),
    noDisabledState: 'a list that may not be put in order is a ListView',
    keyboard: (p) async {
      final t = p.tester;
      await p.tabInto(_press('two'));
      t.takeAnnouncements();
      await _alt(t, LogicalKeyboardKey.arrowDown);
      expect(_host.items, ['one', 'three', 'two', 'four']);
      expect(
        t.takeAnnouncements().map((a) => a.message),
        contains('Moved two to position 3 of 4'),
        reason: 'the move is told',
      );
      expect(p.focusIn(_press('two')), isTrue, reason: 'focus moved with it');
      await _alt(t, LogicalKeyboardKey.arrowUp);
      expect(_host.items, ['one', 'two', 'three', 'four']);
      expect(
        semanticsOf(
          t,
          _item('one'),
        ).getSemanticsData().customSemanticsActionIds,
        hasLength(2),
        reason: 'the first item moves only on',
      );
    },
    motion: (p) async {
      await p.tabInto(_press('two'));
      await _alt(p.tester, LogicalKeyboardKey.arrowDown);
    },
  );

  testWidgets('Alt+Down and Alt+Up move the item the keyboard is in, and '
      'focus stays in it', (tester) async {
    await tester.pumpWidget(harness(const _Host()));
    Focus.of(tester.element(find.text('two'))).requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();
    await tester.pump();
    expect(_host.items, ['one', 'three', 'two', 'four']);
    expect(Focus.of(tester.element(find.text('two'))).hasPrimaryFocus, isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();
    await tester.pump();
    expect(_host.items.first, 'two');
  });

  testWidgets('a drag on the handle moves the item', (tester) async {
    await tester.pumpWidget(harness(const _Host()));
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('drag one')),
    );
    await tester.pump();
    // 105 px down on 50 px rows: past the third row's middle, short of the
    // fourth's.
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.moveBy(const Offset(0, 25));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_host.items, ['two', 'three', 'one', 'four']);
  });

  testWidgets('a screen reader moves an item with the list\'s actions', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(harness(const _Host()));
    final node = tester.getSemantics(find.text('drag three'));
    var target = node;
    while (target.getSemanticsData().customSemanticsActionIds?.isEmpty ??
        true) {
      target = target.parent!;
    }
    final owner = semanticsOwner();
    final toStart = CustomSemanticsAction.getIdentifier(
      const CustomSemanticsAction(label: 'Move to the start'),
    );
    owner.performAction(target.id, SemanticsAction.customAction, toStart);
    await tester.pump();
    expect(_host.items, ['three', 'one', 'two', 'four']);
    semantics.dispose();
  });
}
