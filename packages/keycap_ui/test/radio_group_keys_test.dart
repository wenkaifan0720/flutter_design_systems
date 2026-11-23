// Keycap's radio group, a one-choice segmented button and a one-at-a-time
// toggle group are Flutter's radio groups: Tab lands on the chosen radio, the
// arrows move and choose, Left reads on right to left, a chosen radio that
// is turned off is no Tab stop, and a press anywhere in a radio's box
// chooses it.
// ignore_for_file: avoid_relative_lib_imports
import 'package:material_ui/material_ui.dart' show Material;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';

import '../example/lib/kit_gallery/kit.dart';

// Options A to D; the radio group and the toggle group turn B off, the
// segmented button cannot turn one key off.
Widget _group(String kind, String? value, ValueChanged<String>? changed) =>
    switch (kind) {
      'radio group' => KeycapRadioGroup<String>(
        options: const ['A', 'B', 'C', 'D'],
        groupValue: value,
        isEnabled: (v) => v != 'B',
        labelOf: (v) => v,
        semanticLabel: 'Letters',
        onChanged: changed,
      ),
      'toggle group' => KeycapToggleGroup<String>(
        options: [
          for (final v in const ['A', 'B', 'C', 'D'])
            KeycapToggleOption(value: v, label: v, enabled: v != 'B'),
        ],
        selected: {?value},
        multiSelectionEnabled: false,
        semanticLabel: 'Letters',
        onSelectionChanged: changed == null ? null : (s) => changed(s.single),
      ),
      _ => KeycapSegmentedButton<String>(
        segments: const [
          KeycapSegment(value: 'A', label: 'A'),
          KeycapSegment(value: 'B', label: 'B'),
          KeycapSegment(value: 'C', label: 'C'),
          KeycapSegment(value: 'D', label: 'D'),
        ],
        selected: {?value},
        semanticLabel: 'Letters',
        onSelectionChanged: changed == null ? null : (s) => changed(s.single),
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
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(390 * 2, 1400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      kitApp(
        brightness: Brightness.light,
        home: Material(
          child: Directionality(
            textDirection: direction,
            child: Align(
              alignment: Alignment.topCenter,
              child: StatefulBuilder(
                builder: (context, setState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 24,
                  children: [
                    KeycapButton(
                      focusNode: before,
                      onPressed: () {},
                      child: const Text('Before'),
                    ),
                    SizedBox(
                      width: 358,
                      child: _group(
                        kind,
                        value,
                        inert ? null : (next) => setState(() => value = next),
                      ),
                    ),
                    KeycapButton(
                      focusNode: after,
                      onPressed: () {},
                      child: const Text('After'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    before.requestFocus();
    await tester.pumpAndSettle();
    await press(LogicalKeyboardKey.tab);
  }

  Future<void> press(LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pumpAndSettle();
  }

  /// Where the focus is: before or after the group, or the value of the
  /// radio holding it (Flutter's RawRadio, under each key).
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
/// key and the room round it.
Rect _boxOf(WidgetTester tester, String value) => tester.getRect(
  find.byWidgetPredicate((w) => w is RawRadio<String> && w.value == value),
);

/// Presses each of [values] at its radio's start, middle, end, top and
/// bottom, each time from another choice, and expects the press to choose
/// it. RawRadio's own detector takes a press only where the face paints; a
/// Keycap radio takes it anywhere in its box, as the published keys did.
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
  for (final kind in ['radio group', 'toggle group', 'segmented button']) {
    final offB = kind != 'segmented button';
    testWidgets('a $kind: Tab into the chosen radio, the arrows move and '
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
      final back = offB ? 'A' : 'B';
      expect((page.focused(), page.value), (back, back));
      await page.press(LogicalKeyboardKey.tab);
      expect(page.focused(), 'after', reason: 'one Tab stop');

      await page.mount(kind, 'A', TextDirection.rtl);
      expect(page.focused(), 'A');
      await page.press(LogicalKeyboardKey.arrowLeft);
      final next = offB ? 'C' : 'B';
      expect((page.focused(), page.value), (next, next), reason: 'rtl');
      await page.press(LogicalKeyboardKey.arrowRight);
      expect((page.focused(), page.value), ('A', 'A'));

      if (offB) {
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
          reason: 'an inert row, its chosen key off, is no Tab stop',
        );
      }
    });
  }

  for (final kind in ['radio group', 'toggle group', 'segmented button']) {
    testWidgets("a $kind: a press anywhere in a radio's box chooses it", (
      tester,
    ) async {
      final page = _Page(tester);
      addTearDown(page.dispose);
      await page.mount(kind, 'A', TextDirection.ltr);
      await _pressEverywhere(
        tester,
        page,
        kind == 'segmented button'
            ? const ['A', 'B', 'C', 'D']
            : const ['A', 'C', 'D'],
      );
    });
  }
}
