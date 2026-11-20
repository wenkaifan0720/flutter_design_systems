import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

void main() {
  for (final (direction, supplied) in [
    for (final direction in TextDirection.values)
      for (final supplied in [false, true]) (direction, supplied),
  ]) {
    testWidgets(
      'Tab enters and leaves once, all four arrows choose in ${direction.name} '
      'with ${supplied ? 'caller' : 'group'} nodes',
      (tester) async {
        final before = FocusNode(), after = FocusNode();
        addTearDown(before.dispose);
        addTearDown(after.dispose);
        final changes = <String>[];
        String? chosen = 'C';
        List<String> options = ['A', 'B', 'C', 'D'];
        final nodes = {
          if (supplied)
            for (final option in options) option: FocusNode(),
        };
        for (final node in nodes.values) {
          addTearDown(node.dispose);
        }
        var disabled = {'B'};
        late StateSetter rebuild;
        await tester.pumpWidget(
          harness(
            StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return Column(
                  children: [
                    Focus(focusNode: before, child: const Text('Before')),
                    DesignRadioGroup<String>(
                      options: options,
                      value: chosen,
                      direction: Axis.horizontal,
                      semanticLabel: 'Plan',
                      isEnabled: (option) => !disabled.contains(option),
                      focusNodeFor: supplied ? (option) => nodes[option] : null,
                      onChanged: (option) => setState(() {
                        changes.add(option);
                        chosen = option;
                      }),
                      itemBuilder: (context, option, node, select) =>
                          DesignPressable(
                            key: ValueKey(option),
                            focusNode: node,
                            onPressed: select,
                            checked: option == chosen,
                            inMutuallyExclusiveGroup: true,
                            semanticLabel: option,
                            builder: (context, states, _) => Text(option),
                          ),
                    ),
                    Focus(focusNode: after, child: const Text('After')),
                  ],
                );
              },
            ),
            textDirection: direction,
          ),
        );
        FocusNode node(String option) => tester
            .widget<DesignPressable>(find.byKey(ValueKey(option)))
            .focusNode!;
        Future<void> key(LogicalKeyboardKey key) async {
          await tester.sendKeyEvent(key);
          await tester.pump();
        }

        Future<void> enter() async {
          before.requestFocus();
          await tester.pump();
          await key(LogicalKeyboardKey.tab);
        }

        await enter();
        if (supplied) expect(node('C'), same(nodes['C']));
        expect(node('C').hasPrimaryFocus, isTrue);
        await key(LogicalKeyboardKey.tab);
        expect(after.hasPrimaryFocus, isTrue);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await key(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        expect(node('C').hasPrimaryFocus, isTrue);
        final rtl = direction == TextDirection.rtl;
        for (final (arrow, value) in [
          (LogicalKeyboardKey.arrowUp, 'A'),
          (
            rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft,
            'D',
          ),
          (LogicalKeyboardKey.arrowDown, 'A'),
          (
            rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight,
            'C',
          ),
        ]) {
          await key(arrow);
          expect(node(value).hasPrimaryFocus, isTrue);
          expect(chosen, value);
        }
        expect(changes, ['A', 'D', 'A', 'C']);
        rebuild(() => chosen = null);
        await tester.pump();
        await enter();
        expect(node('A').hasPrimaryFocus, isTrue);
        await key(LogicalKeyboardKey.space);
        expect(chosen, 'A');
        await key(LogicalKeyboardKey.enter);
        expect(changes, ['A', 'D', 'A', 'C', 'A']);

        // A disabled selection and changes to the option order both use the
        // new reading order, without moving the selection on entry.
        final d = node('D');
        rebuild(() {
          chosen = 'B';
          options = ['B', 'D', 'A'];
        });
        await tester.pump();
        await enter();
        expect(node('D'), same(d));
        expect(d.hasPrimaryFocus, isTrue);
        expect(chosen, 'B');
        await tester.tap(find.byKey(const ValueKey('A')));
        await tester.pumpAndSettle();
        expect(chosen, 'A');
        rebuild(() => disabled = {'A', 'B'});
        await tester.pump();
        await enter();
        await key(LogicalKeyboardKey.arrowDown);
        expect(chosen, 'D');
        final flags = tester
            .getSemantics(find.byKey(const ValueKey('D')))
            .getSemanticsData()
            .flagsCollection;
        expect(flags.isInMutuallyExclusiveGroup, isTrue);
        expect(flags.isButton, isFalse);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('Plan'))
              .getSemanticsData()
              .role,
          SemanticsRole.radioGroup,
        );
        rebuild(() => disabled = options.toSet());
        await tester.pump();
        await enter();
        expect(after.hasPrimaryFocus, isTrue);
      },
    );
  }

  testWidgets('a caller can focus, replace, and reuse its radio nodes', (
    tester,
  ) async {
    final first = FocusNode(), replacement = FocusNode();
    addTearDown(first.dispose);
    addTearDown(replacement.dispose);
    final focusChanges = <bool>[];
    first.addListener(() => focusChanges.add(first.hasPrimaryFocus));
    FocusNode? supplied = first;
    var options = ['A', 'B'];
    String? chosen;
    late StateSetter rebuild;
    await tester.pumpWidget(
      harness(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return DesignRadioGroup<String>(
              options: options,
              value: chosen,
              onChanged: (v) => setState(() => chosen = v),
              focusNodeFor: (v) => v == 'A' ? supplied : null,
              itemBuilder: (context, v, node, select) => DesignPressable(
                key: ValueKey(v),
                focusNode: node,
                onPressed: select,
                checked: v == chosen,
                inMutuallyExclusiveGroup: true,
                builder: (context, states, _) => Text(v),
              ),
            );
          },
        ),
      ),
    );
    FocusNode node(String value) =>
        tester.widget<DesignPressable>(find.byKey(ValueKey(value))).focusNode!;
    final owned = node('B');
    first.requestFocus();
    await tester.pump();
    expect(tester.binding.focusManager.primaryFocus, same(first));
    expect(focusChanges.last, isTrue);
    expect(chosen, isNull);
    rebuild(() => options = ['B', 'A']);
    await tester.pump();
    expect(node('A'), same(first));
    expect(first.hasPrimaryFocus, isTrue);
    expect(node('B'), same(owned));
    owned.requestFocus();
    await tester.pump();
    expect(focusChanges.last, isFalse);
    first.requestFocus();
    await tester.pump();

    rebuild(() => supplied = replacement);
    await tester.pump();
    expect(node('A'), same(replacement));
    expect(first.parent, isNull);
    replacement.requestFocus();
    await tester.pump();
    expect(tester.binding.focusManager.primaryFocus, same(replacement));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(chosen, 'B');
    expect(owned.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(chosen, 'A');
    expect(replacement.hasPrimaryFocus, isTrue);

    rebuild(() => supplied = null);
    await tester.pump();
    expect(node('A'), isNot(same(replacement)));
    rebuild(() {
      supplied = first;
      options = ['A'];
    });
    await tester.pump();
    expect(node('A'), same(first));
    rebuild(() => options = []);
    await tester.pump();
    rebuild(() {
      options = ['A'];
      supplied = replacement;
    });
    await tester.pump();
    expect(node('A'), same(replacement));
    await tester.pumpWidget(
      harness(
        Column(
          children: [
            Focus(focusNode: first, child: const Text('1')),
            Focus(focusNode: replacement, child: const Text('2')),
          ],
        ),
      ),
    );
    for (final callerNode in [first, replacement]) {
      callerNode.requestFocus();
      await tester.pump();
      expect(tester.binding.focusManager.primaryFocus, same(callerNode));
    }
    expect(focusChanges, containsAllInOrder([true, false, true, false]));
  });
}
