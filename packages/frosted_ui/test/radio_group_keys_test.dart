/// Frosted's radio group and its one-at-a-time toggle strip are Flutter's
/// radio groups: Tab lands on the chosen radio, the arrows move and choose,
/// Left reads on right to left, a chosen radio that is turned off is no Tab
/// stop, and a press anywhere in a radio's box chooses it.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

Widget _group(
  String kind,
  String? value,
  ValueChanged<String>? changed, {
  bool allowEmpty = false,
  ValueChanged<Set<String>>? changedSet,
}) => switch (kind) {
  'radios' => FrostedRadioGroup<String>(
    label: 'Delivery',
    value: value,
    onChanged: changed,
    options: const [
      FrostedRadio('A', 'A'),
      FrostedRadio('B', 'B', enabled: false),
      FrostedRadio('C', 'C'),
      FrostedRadio('D', 'D'),
    ],
  ),
  _ => FrostedToggleGroup<String>(
    label: 'Alignment',
    allowEmpty: allowEmpty,
    segments: const [
      FrostedButtonSegment('A', 'A'),
      FrostedButtonSegment('B', 'B'),
      FrostedButtonSegment('C', 'C'),
      FrostedButtonSegment('D', 'D'),
    ],
    selected: {?value},
    onChanged:
        changedSet ?? (changed == null ? null : (next) => changed(next.single)),
  ),
};

class _Page {
  _Page(this.tester);

  final WidgetTester tester;
  final before = FocusNode(debugLabel: 'before');
  final after = FocusNode(debugLabel: 'after');
  String? value;

  Future<void> mount(
    String kind,
    String? initial,
    TextDirection direction, {
    bool inert = false,
  }) async {
    value = initial;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (BuildContext context, Widget? page) =>
            FrostedHost(brightness: Brightness.light, child: page!),
        home: Directionality(
          textDirection: direction,
          child: Center(
            child: StatefulBuilder(
              builder: (context, setState) => Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 24,
                children: [
                  Focus(focusNode: before, child: const Text('Before')),
                  SizedBox(
                    width: 320,
                    child: _group(
                      kind,
                      value,
                      inert ? null : (next) => setState(() => value = next),
                    ),
                  ),
                  Focus(focusNode: after, child: const Text('After')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    before.requestFocus();
    await tester.pump();
    await press(LogicalKeyboardKey.tab);
  }

  Future<void> press(LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pumpAndSettle();
  }

  /// Where the focus is: before or after the group, or the value of the
  /// radio holding it (Flutter's RawRadio, under each face).
  String? focused() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == before) return 'before';
    if (focus == after) return 'after';
    String? found;
    focus?.context?.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is RawRadio<String>) found = widget.value;
      return found == null;
    });
    return found;
  }

  void dispose() {
    before.dispose();
    after.dispose();
  }
}

/// The box of the radio standing for [value]: Flutter's RawRadio, under the
/// face and the room round it.
Rect _boxOf(WidgetTester tester, String value) => tester.getRect(
  find.byWidgetPredicate((w) => w is RawRadio<String> && w.value == value),
);

/// Presses each of [values] at its radio's start, middle, end, top and
/// bottom, each time from another choice, and expects the press to choose
/// it. RawRadio's own detector takes a press only where the face paints; a
/// Frosted radio takes it anywhere in its box, its gaps too, as the published
/// rows and toggles did.
Future<void> _pressEverywhere(
  WidgetTester tester,
  _Page page,
  List<String> values,
) async {
  for (final (i, value) in values.indexed) {
    final other = values[(i + 1) % values.length];
    final box = _boxOf(tester, value);
    for (final at in [
      box.centerLeft + const Offset(2, 0),
      box.center,
      box.centerRight - const Offset(2, 0),
      box.topCenter + const Offset(0, 2),
      box.bottomCenter - const Offset(0, 2),
    ]) {
      await tester.tapAt(_boxOf(tester, other).center);
      await tester.pumpAndSettle();
      expect(page.value, other);
      await tester.tapAt(at);
      await tester.pumpAndSettle();
      expect(page.value, value, reason: '$value pressed at $at in $box');
    }
  }
}

void main() {
  for (final kind in ['radios', 'toggles']) {
    // The delivery radios turn B off; the strip's toggles are all on.
    final pastB = kind == 'radios' ? 'A' : 'B';
    testWidgets('$kind: Tab into the chosen radio, the arrows move and '
        'choose, right to left, and a chosen radio turned off', (tester) async {
      final page = _Page(tester);
      addTearDown(page.dispose);

      await page.mount(kind, 'C', TextDirection.ltr);
      expect(page.focused(), 'C', reason: 'Tab lands on the chosen radio');
      await page.press(LogicalKeyboardKey.arrowDown);
      expect((page.focused(), page.value), ('D', 'D'));
      await page.press(LogicalKeyboardKey.arrowUp);
      expect((page.focused(), page.value), ('C', 'C'));
      await page.press(LogicalKeyboardKey.arrowUp);
      expect((page.focused(), page.value), (pastB, pastB));
      await page.press(LogicalKeyboardKey.tab);
      expect(page.focused(), 'after', reason: 'one Tab stop');

      await page.mount(kind, 'A', TextDirection.rtl);
      expect(page.focused(), 'A');
      await page.press(LogicalKeyboardKey.arrowLeft);
      final next = kind == 'radios' ? 'C' : 'B';
      expect((page.focused(), page.value), (next, next), reason: 'rtl');
      await page.press(LogicalKeyboardKey.arrowRight);
      expect((page.focused(), page.value), ('A', 'A'));

      if (kind == 'radios') {
        await page.mount(kind, 'B', TextDirection.ltr);
        expect(
          (page.focused(), page.value),
          ('A', 'B'),
          reason: 'the chosen radio is off: Tab lands on the first on',
        );
        await page.press(LogicalKeyboardKey.arrowDown);
        expect((page.focused(), page.value), ('C', 'C'));
      } else {
        await page.mount(kind, 'C', TextDirection.ltr, inert: true);
        expect(
          (page.focused(), page.value),
          ('after', 'C'),
          reason: 'an inert strip, its chosen toggle off, is no Tab stop',
        );
      }
    });
  }

  for (final allowEmpty in [false, true]) {
    testWidgets('a press, Space or Return on the chosen toggle '
        '${allowEmpty ? 'clears it (allowEmpty)' : 'keeps it'}', (
      tester,
    ) async {
      final changes = <Set<String>>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (BuildContext context, Widget? page) =>
              FrostedHost(brightness: Brightness.light, child: page!),
          home: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Focus(focusNode: node, child: const Text('Before')),
                _group(
                  'toggles',
                  'B',
                  null,
                  allowEmpty: allowEmpty,
                  changedSet: changes.add,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(changes, allowEmpty ? List.filled(3, <String>{}) : isEmpty);
    });
  }

  for (final kind in ['radios', 'toggles']) {
    testWidgets("$kind: a press anywhere in a radio's box chooses it", (
      tester,
    ) async {
      final page = _Page(tester);
      addTearDown(page.dispose);
      await page.mount(kind, 'A', TextDirection.ltr);
      await _pressEverywhere(
        tester,
        page,
        kind == 'radios' ? const ['A', 'C', 'D'] : const ['A', 'B', 'C', 'D'],
      );
    });
  }
}
