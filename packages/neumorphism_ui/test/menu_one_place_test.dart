// Every open menu keeps one current row:
// the look's own menu (an overflow menu, a select's list), a menu bar's menu and a split button's menu. The pointer's
// row stands up and the keys' place lifts, so whichever moved last has the one lit row, never both at once; a menu
// opened by the pointer lights nothing until the pointer or the keys move, one opened by the keys lights its first
// row; and the lit row has the menu's inset round it, inside the scroll, so its lift never meets the menu's edge.
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/controls.dart'
    show NeumorphicTapFace;
import 'package:neumorphism_ui/src/neumorphism/internal/panel.dart';

import 'support.dart';

/// The rows of [labels] lit in the open menu: the look's menu's sunk or lifted row (the keys' place on the chosen row
/// sinks over its wash), a panel row's sink or lift.
List<String> _lit(WidgetTester tester, List<String> labels) {
  final lit = <String>[];
  for (final label in labels) {
    for (final e
        in find
            .byWidgetPredicate((w) => w is NeumorphicTap && w.label == label)
            .evaluate()) {
      final tap = e.widget as NeumorphicTap;
      final raised = find
          .descendant(
            of: find.byElementPredicate((x) => x == e),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is CustomPaint &&
                  (w.painter is NeumorphicPanelRowRaise ||
                      w.foregroundPainter is NeumorphicPanelRowRaise),
            ),
          )
          .evaluate()
          .isNotEmpty;
      final lifted = tap.showFocus && (tap.focusNode?.hasFocus ?? false);
      if (raised || lifted) lit.add(label);
    }
    for (final e
        in find
            .byWidgetPredicate(
              (w) => w is NeumorphicPanelRow && w.label == label,
            )
            .evaluate()) {
      final paints = find
          .descendant(
            of: find.byElementPredicate((x) => x == e),
            matching: find.byType(CustomPaint),
          )
          .evaluate()
          .map((x) => x.widget as CustomPaint);
      if (paints.any(
        (p) =>
            p.painter is NeumorphicPanelRowRaise || p.foregroundPainter != null,
      )) {
        lit.add(label);
      }
    }
  }
  return lit;
}

Finder _row(String label) => find
    .byWidgetPredicate(
      (w) =>
          (w is NeumorphicTap && w.label == label) ||
          (w is NeumorphicPanelRow && w.label == label),
    )
    .last;

/// The open menu's rows stand the menu's inset ([neumorphicMenuInset]) inside its scroll, every side.
void _roomRound(WidgetTester tester, List<String> labels) {
  final port = tester.getRect(
    find
        .ancestor(of: _row(labels.first), matching: find.byType(Scrollable))
        .first,
  );
  final first = tester.getRect(_row(labels.first));
  final last = tester.getRect(_row(labels.last));
  const inset = neumorphicMenuInset - .5;
  expect(first.top - port.top, greaterThanOrEqualTo(inset), reason: 'top');
  expect(
    port.bottom - last.bottom,
    greaterThanOrEqualTo(inset),
    reason: 'bottom',
  );
  expect(first.left - port.left, greaterThanOrEqualTo(inset), reason: 'start');
  expect(port.right - first.right, greaterThanOrEqualTo(inset), reason: 'end');
}

Future<TestGesture> _mouse(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: const Offset(1, 1));
  addTearDown(mouse.removePointer);
  return mouse;
}

Future<void> _click(WidgetTester tester, TestGesture mouse, Finder at) async {
  await mouse.moveTo(tester.getCenter(at));
  await tester.pump();
  await mouse.down(tester.getCenter(at));
  await mouse.up();
  await tester.pumpAndSettle();
}

Future<void> _hover(
  WidgetTester tester,
  TestGesture mouse,
  String label,
) async {
  await mouse.moveTo(tester.getCenter(_row(label)));
  await tester.pumpAndSettle();
  await mouse.moveBy(const Offset(3, 0));
  await tester.pumpAndSettle();
}

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

/// Opens from the keys: [key] held while the menu builds, as a person's press is.
Future<void> _openByKey(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(key);
  await tester.pumpAndSettle();
  await tester.sendKeyUpEvent(key);
  await tester.pumpAndSettle();
}

Future<void> _desk(WidgetTester tester, Widget child) async {
  final previous = FocusManager.instance.highlightStrategy;
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(() => FocusManager.instance.highlightStrategy = previous);
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(neumorphicApp(child, width: 1440));
  await tester.pumpAndSettle();
}

const _acts = ['Copy link', 'Archive', 'Delete'];

Widget _overflow(FocusNode node) => Align(
  alignment: Alignment.topLeft,
  child: Padding(
    padding: const EdgeInsets.all(40),
    child: Builder(
      builder: (context) => NeumorphicButton(
        'More actions',
        focusNode: node,
        onPressed: () {
          final box = context.findRenderObject()! as RenderBox;
          showNeumorphicMenu<String>(
            context,
            anchor: box.localToGlobal(Offset.zero) & box.size,
            items: [for (final a in _acts) NeumorphicMenuItem(a, a)],
          );
        },
      ),
    ),
  ),
);

const _scenes = ['New scene', 'Duplicate', 'Rename'];

Widget _menuBar() => Align(
  alignment: Alignment.topLeft,
  child: NeumorphicMenuBar(
    menus: [
      DesignMenuEntry(
        label: 'Scene',
        children: [
          for (final s in _scenes) DesignMenuEntry(label: s, onPressed: () {}),
        ],
      ),
    ],
  ),
);

const _starts = ['Start at dusk', 'Start tomorrow', 'Start on Monday'];

Widget _split() => Padding(
  padding: const EdgeInsets.all(40),
  // A stretching column, as a form's or a settings page's.
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      NeumorphicSplitButton(
        'Start now',
        onPressed: () {},
        actions: [
          for (final s in _starts) NeumorphicSplitAction(s, onPressed: () {}),
        ],
      ),
    ],
  ),
);

void main() {
  for (final withIcon in [false, true]) {
    testWidgets('split menu fits its contents and reserves an icon column only '
        'when a row has an icon (icons: $withIcon)', (tester) async {
      tester.view.physicalSize = const Size(2880, 1800);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        neumorphicApp(
          Center(
            child: NeumorphicSplitButton(
              'Save',
              onPressed: () {},
              actions: [
                NeumorphicSplitAction('Save a copy', onPressed: () {}),
                if (withIcon)
                  NeumorphicSplitAction(
                    'Save a copy in another folder',
                    icon: NeumorphicGlyphs.check,
                    onPressed: () {},
                  ),
              ],
            ),
          ),
          width: 1440,
        ),
      );
      await tester.pumpAndSettle();
      final halves = find.byType(NeumorphicTapFace);
      final button = tester
          .getRect(halves.first)
          .expandToInclude(tester.getRect(halves.last));
      final mouse = await _mouse(tester);
      await _click(tester, mouse, find.byIcon(NeumorphicGlyphs.chevronDown));
      final panel = tester.getRect(find.byType(NeumorphicPanel));
      expect(panel.width, greaterThanOrEqualTo(button.width - .5));
      if (withIcon) {
        expect(panel.width, greaterThan(button.width));
        expect(
          tester.getRect(find.text('Save a copy in another folder')).left,
          closeTo(tester.getRect(find.text('Save a copy')).left, .5),
        );
      } else {
        final words = tester.getSize(find.text('Save a copy')).width;
        expect(
          panel.width,
          lessThanOrEqualTo(
            button.width > words + 70 ? button.width + 1 : words + 70,
          ),
        );
      }
      final row = tester.getRect(_row('Save a copy'));
      final label = tester.getRect(find.text('Save a copy'));
      // The row keeps 10 round its words, and an icon's column before them.
      expect(label.left - row.left, closeTo(withIcon ? 40 : 10, .5));
      final main = tester.widget<NeumorphicTapFace>(halves.first);
      final toggle = tester.widget<NeumorphicTapFace>(halves.last);
      expect(main.states, isNot(contains(WidgetState.pressed)));
      expect(toggle.states, contains(WidgetState.pressed));
      expect(
        toggle.pressRelief,
        isFalse,
        reason: 'the key paints its own coloured inset',
      );
    });
  }

  testWidgets('the look\'s menu: opened by the pointer nothing is lit; the '
      'pointer\'s row, then the keys\' going on from it, then the pointer\'s '
      'again, one at a time; its rows stand its inset inside its scroll', (
    tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await _desk(tester, _overflow(node));
    final mouse = await _mouse(tester);
    await _click(tester, mouse, find.text('More actions'));
    expect(_lit(tester, _acts), isEmpty, reason: 'opened by the pointer');
    _roomRound(tester, _acts);
    await _hover(tester, mouse, 'Archive');
    expect(_lit(tester, _acts), ['Archive']);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(
      _lit(tester, _acts),
      ['Delete'],
      reason: 'the keys go on from the pointer\'s row; it no longer stands up',
    );
    await _hover(tester, mouse, 'Copy link');
    expect(_lit(tester, _acts), ['Copy link']);
  });

  testWidgets('the look\'s menu opened by the keys lights its first row, and '
      'the pointer then takes the place', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await _desk(tester, _overflow(node));
    final mouse = await _mouse(tester);
    node.requestFocus();
    await tester.pumpAndSettle();
    await _openByKey(tester, LogicalKeyboardKey.enter);
    expect(_lit(tester, _acts), ['Copy link']);
    await _hover(tester, mouse, 'Delete');
    expect(_lit(tester, _acts), ['Delete']);
  });

  testWidgets('a menu bar\'s menu: one lit row, the last to move has it; '
      'opened by the keys its first row; its rows stand its inset inside its '
      'scroll', (tester) async {
    await _desk(tester, _menuBar());
    final mouse = await _mouse(tester);
    await _click(tester, mouse, find.text('Scene'));
    expect(_lit(tester, _scenes), isEmpty, reason: 'opened by the pointer');
    _roomRound(tester, _scenes);
    await _hover(tester, mouse, 'Duplicate');
    expect(_lit(tester, _scenes), ['Duplicate']);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_lit(tester, _scenes), hasLength(1));
    expect(_lit(tester, _scenes), isNot(contains('Duplicate')));
    await _hover(tester, mouse, 'New scene');
    expect(_lit(tester, _scenes), ['New scene']);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_lit(tester, _scenes), [
      'Duplicate',
    ], reason: 'the keys go on from the pointer\'s row');
  });

  testWidgets('a menu bar\'s menu opened by the keys lights its first row', (
    tester,
  ) async {
    await _desk(tester, _menuBar());
    await _press(tester, LogicalKeyboardKey.tab);
    await _openByKey(tester, LogicalKeyboardKey.arrowDown);
    expect(_lit(tester, _scenes), ['New scene']);
  });

  testWidgets(
    'a split button\'s menu: its own width in a stretching column; '
    'one lit row, the last to move has it; opened by the keys its first row',
    (tester) async {
      await _desk(tester, _split());
      final mouse = await _mouse(tester);
      await _click(tester, mouse, find.byIcon(NeumorphicGlyphs.chevronDown));
      expect(_lit(tester, _starts), isEmpty, reason: 'opened by the pointer');
      expect(
        tester.getSize(find.byType(NeumorphicPanel)).width,
        lessThan(320),
        reason: 'not the column\'s width',
      );
      _roomRound(tester, _starts);
      await _hover(tester, mouse, 'Start at dusk');
      expect(_lit(tester, _starts), ['Start at dusk']);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_lit(tester, _starts), ['Start tomorrow']);
      await _hover(tester, mouse, 'Start on Monday');
      expect(_lit(tester, _starts), ['Start on Monday']);
    },
  );

  testWidgets('a split button\'s menu opened by the keys lights its first '
      'row', (tester) async {
    await _desk(tester, _split());
    await _press(tester, LogicalKeyboardKey.tab);
    await _openByKey(tester, LogicalKeyboardKey.arrowDown);
    expect(_lit(tester, _starts), ['Start at dusk']);
  });

  testWidgets('a long select\'s list: the keys scroll a row in with the '
      'list\'s inset round it, at its end and back at its start', (
    tester,
  ) async {
    const countries = [
      'Austria', 'Belgium', 'Canada', 'Chile', 'Denmark', 'Estonia', //
      'Finland', 'France', 'Germany', 'Greece', 'Iceland', 'Ireland', //
      'Italy', 'Japan', 'Kenya', 'Mexico', 'Norway', 'Peru', 'Poland', //
      'Portugal', 'Spain', 'Sweden', 'Switzerland', 'Uruguay',
    ];
    final previous = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() => FocusManager.instance.highlightStrategy = previous);
    tester.view.physicalSize = const Size(1440, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      neumorphicApp(
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 40),
            child: SizedBox(
              width: 320,
              child: NeumorphicSelect<String>(
                label: 'Country',
                focusNode: node,
                value: 'Austria',
                options: [for (final c in countries) NeumorphicMenuItem(c, c)],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
        width: 1440,
      ),
    );
    await tester.pumpAndSettle();
    node.requestFocus();
    await tester.pumpAndSettle();
    await _openByKey(tester, LogicalKeyboardKey.enter);
    Rect port(String label) => tester.getRect(
      find.ancestor(of: _row(label), matching: find.byType(Scrollable)).first,
    );
    // The list's own inset round its rows, at rest: a field's list keeps its words on the field's, its rows taking most
    // of that inset and the panel a tight one.
    final inset = tester.getRect(_row('Austria')).top - port('Austria').top;
    expect(inset, greaterThanOrEqualTo(4));
    void room(String label) {
      final box = tester.getRect(_row(label));
      expect(box.top - port(label).top, greaterThanOrEqualTo(inset - .5));
      expect(port(label).bottom - box.bottom, greaterThanOrEqualTo(inset - .5));
    }

    expect(_lit(tester, countries), ['Austria']);
    await _press(tester, LogicalKeyboardKey.end);
    expect(_lit(tester, countries), ['Uruguay']);
    room('Uruguay');
    await _press(tester, LogicalKeyboardKey.home);
    expect(_lit(tester, countries), ['Austria']);
    room('Austria');
    await _press(tester, LogicalKeyboardKey.arrowUp);
    expect(_lit(tester, countries), ['Uruguay'], reason: 'Up wraps');
    room('Uruguay');
  });
}
