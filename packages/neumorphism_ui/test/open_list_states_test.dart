// An open list (a select's, a combobox's, a multi-select's, a menu with a choice) shows its chosen option at a glance in
// the look's material: pressed in under the pigment's wash, as a chosen cell is. The pointer's row sinks a little into
// the panel, the keyboard's place the same a little deeper, and a row held under a finger presses in plain only while
// it is held: none of them reads as a second choice or a rule between rows (the user's walks, 11-15 and 11-18).
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/internal/panel.dart';

import 'support.dart';

/// Every painter drawn under [of], by its class; a row's deeper sink, the keyboard's place, as [_keys].
Set<String> _painters(WidgetTester tester, Finder of) => {
  for (final p in tester.widgetList<CustomPaint>(
    find.descendant(of: of, matching: find.byType(CustomPaint)),
  ))
    for (final q in [p.painter, p.foregroundPainter])
      if (q is NeumorphicPanelRowRaise && (q.focus || q.rim))
        _keys
      else if (q != null)
        q.runtimeType.toString(),
};

Finder _row(String label) =>
    find.byWidgetPredicate((w) => w is NeumorphicTap && w.label == label);

const _chosen = '_ChosenCell';
const _raise = 'NeumorphicPanelRowRaise';
const _keys = 'NeumorphicPanelRowRaise, deeper';

Future<void> _menu(WidgetTester tester, {required bool dark}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final previous = FocusManager.instance.highlightStrategy;
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(() => FocusManager.instance.highlightStrategy = previous);
  await tester.pumpWidget(
    neumorphicApp(
      Align(
        alignment: Alignment.topCenter,
        child: NeumorphicMenu<String>(
          items: const [
            NeumorphicMenuItem('one', 'First choice', selected: true),
            NeumorphicMenuItem('two', 'Second choice'),
            NeumorphicMenuItem('three', 'Third choice'),
          ],
          onSelected: (_) {},
        ),
      ),
      width: 1440,
      dark: dark,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final dark in [false, true]) {
    final mode = dark ? 'night' : 'day';

    testWidgets('a menu: the chosen row alone is pressed in, and the pointer '
        'raises a row and never presses it, $mode', (tester) async {
      await _menu(tester, dark: dark);
      expect(_painters(tester, _row('First choice')), contains(_chosen));
      for (final other in ['Second choice', 'Third choice']) {
        final drawn = _painters(tester, _row(other));
        expect(drawn, isNot(contains(_chosen)), reason: other);
        expect(drawn, isNot(contains('_MenuRowRelief')), reason: other);
      }
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(1400, 880));
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(_row('Second choice')));
      await tester.pumpAndSettle();
      final over = _painters(tester, _row('Second choice'));
      expect(over, contains(_raise));
      expect(over, isNot(contains(_chosen)));
      expect(over, isNot(contains('_MenuRowRelief')));
      // The pointer on the chosen row leaves it as it is: pressed in, not raised.
      await mouse.moveTo(tester.getCenter(_row('First choice')));
      await tester.pumpAndSettle();
      final onChosen = _painters(tester, _row('First choice'));
      expect(onChosen, contains(_chosen));
      expect(onChosen, isNot(contains(_raise)));
    });

    testWidgets('a menu: a row held presses in plain, and comes back when let '
        'go off it, $mode', (tester) async {
      await _menu(tester, dark: dark);
      final press = await tester.startGesture(
        tester.getCenter(_row('Third choice')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final held = _painters(tester, _row('Third choice'));
      expect(held, contains('_MenuRowRelief'));
      expect(held, isNot(contains(_chosen)));
      await press.moveTo(const Offset(1400, 880));
      await press.up();
      await tester.pumpAndSettle();
      expect(
        _painters(tester, _row('Third choice')),
        isNot(contains('_MenuRowRelief')),
      );
      expect(_painters(tester, _row('First choice')), contains(_chosen));
    });

    testWidgets('a menu: the keyboard sinks its place a little deeper than the '
        "pointer's, never presses it in, $mode", (tester) async {
      await _menu(tester, dark: dark);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      final keyed = tester.widget<NeumorphicTap>(_row('Second choice'));
      expect(keyed.focusNode!.hasFocus, isTrue);
      // The row draws the keys' place itself, not the tap's focus lift.
      expect(keyed.showFocus, isFalse);
      final drawn = _painters(tester, _row('Second choice'));
      expect(drawn, contains(_keys));
      expect(drawn, isNot(contains('_FocusLift')));
      expect(drawn, isNot(contains(_chosen)));
      expect(drawn, isNot(contains('_MenuRowRelief')));
      expect(_painters(tester, _row('First choice')), contains(_chosen));
    });

    testWidgets(
      'a palette: one lit row, its active one, which the moving pointer takes, $mode',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          neumorphicApp(
            const Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 480,
                child: NeumorphicCommand(
                  commands: [
                    DesignCommand(label: 'New scene'),
                    DesignCommand(label: 'Dim every room'),
                    DesignCommand(label: 'Find a room'),
                  ],
                ),
              ),
            ),
            width: 1440,
            dark: dark,
          ),
        );
        await tester.pumpAndSettle();
        Finder row(String label) => find.ancestor(
          of: find.text(label),
          matching: find.byType(NeumorphicPanelRow),
        );
        List<String> lit() => [
          for (final label in ['New scene', 'Dim every room', 'Find a room'])
            if (_painters(tester, row(label)).any({_raise, _keys}.contains))
              label,
        ];
        expect(lit(), ['New scene']);
        // A row arrives under a still pointer (the page scrolled it there): it does not stand up beside the active one.
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.addPointer(
          location: tester.getCenter(row('Dim every room')),
        );
        await tester.pumpAndSettle();
        expect(lit(), ['New scene']);
        await mouse.moveBy(const Offset(4, 0));
        await tester.pumpAndSettle();
        expect(lit(), ['Dim every room']);
      },
    );

    testWidgets(
      "right to left, a row's keys read in the order they are held, $mode",
      (tester) async {
        await tester.pumpWidget(
          neumorphicApp(
            const Directionality(
              textDirection: TextDirection.rtl,
              child: SizedBox(
                width: 480,
                child: NeumorphicCommand(
                  commands: [
                    DesignCommand(label: 'New scene', shortcut: '⌘ N'),
                  ],
                ),
              ),
            ),
            dark: dark,
          ),
        );
        await tester.pumpAndSettle();
        final keys = tester.getRect(find.text('⌘ N'));
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text('⌘ N'),
        );
        expect(paragraph.textDirection, TextDirection.ltr);
        expect(
          keys.left,
          lessThan(tester.getRect(find.text('New scene')).left),
          reason: "the keys at the row's end",
        );
      },
    );

    // The row every ui_core list draws: a combobox's, a multi-select's, a menu bar's menu, a split button's, the
    // command palette's.
    final cases = <String, (bool, Set<WidgetState>, Set<String>, Set<String>)>{
      'chosen': (true, const {}, const {_chosen}, const {_raise}),
      'chosen, the pointer on it': (
        true,
        const {WidgetState.hovered},
        const {_chosen},
        const {_raise, 'NeumorphicPanelRowRelief'},
      ),
      'the pointer\'s': (
        false,
        const {WidgetState.hovered},
        const {_raise},
        const {_chosen, 'NeumorphicPanelRowRelief'},
      ),
      'its menu open': (
        false,
        const {WidgetState.selected},
        const {_raise},
        const {_chosen, 'NeumorphicPanelRowRelief'},
      ),
      'the keyboard\'s place': (
        false,
        const {WidgetState.focused},
        const {_keys},
        const {_chosen, _raise, 'NeumorphicPanelRowRelief'},
      ),
      'held': (
        false,
        const {WidgetState.pressed, WidgetState.hovered},
        const {'NeumorphicPanelRowRelief'},
        const {_chosen, _raise},
      ),
    };
    for (final MapEntry(key: name, value: (checked, states, has, hasNot))
        in cases.entries) {
      testWidgets('a list row, $name, $mode', (tester) async {
        await tester.pumpWidget(
          neumorphicApp(
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 320,
                child: NeumorphicPanelRow(
                  label: 'Kitchen',
                  states: states,
                  checked: checked,
                  checkAtEnd: true,
                ),
              ),
            ),
            dark: dark,
          ),
        );
        await tester.pumpAndSettle();
        final drawn = _painters(tester, find.byType(NeumorphicPanelRow));
        for (final p in has) {
          expect(drawn, contains(p));
        }
        for (final p in hasNot) {
          expect(drawn, isNot(contains(p)));
        }
      });
    }
  }
}
