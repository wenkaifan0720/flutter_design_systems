// Where a menu's focus starts and which row is lit: a menu a click opened
// lights none until the pointer or a key picks one; with the highlight
// following the pointer, one row is lit (hovered when the pointer moved
// last, focused when the keys did), the pointer leaving lights none, and a
// disabled row under it lights none. The menubar's menus, their submenus and
// the split button's menu.
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/src/internal/menu_items.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

final List<String> _ran = [];
final Map<String, Set<WidgetState>> _states = {};

List<DesignMenuEntry> _menus() => [
  DesignMenuEntry(
    label: 'File',
    children: [
      DesignMenuEntry(label: 'New', onPressed: () => _ran.add('new')),
      DesignMenuEntry(
        label: 'Open recent',
        children: [
          DesignMenuEntry(label: 'a.txt', onPressed: () => _ran.add('a')),
          DesignMenuEntry(label: 'b.txt', onPressed: () => _ran.add('b')),
        ],
      ),
      const DesignMenuEntry(label: 'Revert'),
      DesignMenuEntry(label: 'Quit', onPressed: () => _ran.add('quit')),
    ],
  ),
  DesignMenuEntry(
    label: 'Edit',
    children: [
      DesignMenuEntry(label: 'Undo', onPressed: () => _ran.add('undo')),
    ],
  ),
];

Widget _view({
  bool follow = true,
  AlignmentGeometry alignment = Alignment.topLeft,
}) => Align(
  alignment: alignment,
  child: DesignMenuBar(
    menus: _menus(),
    highlightFollowsPointer: follow,
    itemBuilder: (context, entry, level, states) {
      _states[entry.label] = states;
      return SizedBox(
        width: level == DesignMenuLevel.bar ? 60 : 160,
        height: 44,
        child: Text(entry.label),
      );
    },
    surfaceBuilder: (context, info, items) => ColoredBox(
      color: const Color(0xFFEEEEEE),
      child: Column(mainAxisSize: MainAxisSize.min, children: items),
    ),
  ),
);

bool _has(String label, WidgetState state) =>
    _states[label]?.contains(state) ?? false;

// The rows lit (hovered or focused) among [labels].
List<String> _litRows(List<String> labels) => [
  for (final l in labels)
    if (_has(l, WidgetState.hovered) || _has(l, WidgetState.focused)) l,
];

const _fileRows = ['New', 'Open recent', 'Revert', 'Quit'];

FocusNode? _primaryOf(WidgetTester tester, String label) =>
    Focus.maybeOf(tester.element(find.text(label)));

bool _keysOn(WidgetTester tester, String label) =>
    _primaryOf(tester, label)?.hasPrimaryFocus ?? false;

// A mouse resting at the top left, out of the way.
Future<TestGesture> _mouse(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(mouse.removePointer);
  await mouse.addPointer(location: const Offset(700, 500));
  await tester.pump();
  return mouse;
}

Future<void> _click(WidgetTester tester, TestGesture mouse, Finder at) async {
  final c = tester.getCenter(at);
  await mouse.moveTo(c);
  await mouse.down(c);
  await mouse.up();
  await tester.pumpAndSettle();
}

Future<void> _moveTo(WidgetTester tester, TestGesture mouse, Offset to) async {
  await mouse.moveTo(to);
  await tester.pumpAndSettle();
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    _ran.clear();
    _states.clear();
  });

  group('a menubar\'s menu', () {
    testWidgets('a click opens it with no row lit; Down lights the first, '
        'Up the last', (tester) async {
      await tester.pumpWidget(harness(_view()));
      final mouse = await _mouse(tester);
      await _click(tester, mouse, find.text('File'));
      expect(find.text('New'), findsOneWidget);
      expect(_litRows(_fileRows), isEmpty);
      expect(_fileRows.any((l) => _keysOn(tester, l)), isFalse);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_litRows(_fileRows), ['New']);
      expect(_has('New', WidgetState.focused), isTrue);
      await _key(tester, LogicalKeyboardKey.escape);
      await _click(tester, mouse, find.text('File'));
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_litRows(_fileRows), ['Quit']);
    });

    testWidgets('the pointer moves the keys: one row lit, hovered; a key '
        'moves it on and the row under the pointer goes dark; the pointer '
        'leaving lights none', (tester) async {
      await tester.pumpWidget(harness(_view()));
      final mouse = await _mouse(tester);
      await _click(tester, mouse, find.text('File'));
      await _moveTo(tester, mouse, tester.getCenter(find.text('Quit')));
      expect(_keysOn(tester, 'Quit'), isTrue);
      expect(_litRows(_fileRows), ['Quit']);
      expect(_has('Quit', WidgetState.hovered), isTrue);
      expect(_has('Quit', WidgetState.focused), isFalse);
      // A key moves it on, round to the first; the pointer stays on Quit.
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_litRows(_fileRows), ['New']);
      expect(_has('New', WidgetState.focused), isTrue);
      // The pointer moves within Quit: it takes the keys back.
      await _moveTo(
        tester,
        mouse,
        tester.getCenter(find.text('Quit')) + const Offset(2, 0),
      );
      expect(_litRows(_fileRows), ['Quit']);
      // Leaving both the panel and the bar closes the menu.
      await _moveTo(tester, mouse, const Offset(700, 500));
      expect(_litRows(_fileRows), isEmpty);
      expect(find.text('New'), findsNothing);
      await _click(tester, mouse, find.text('File'));
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_litRows(_fileRows), ['New']);
      // A key moves the highlight while the pointer is over a different row.
      await _moveTo(tester, mouse, tester.getCenter(find.text('Quit')));
      await _key(tester, LogicalKeyboardKey.arrowUp);
      // Up from Quit passes the disabled Revert.
      expect(_litRows(_fileRows), ['Open recent']);
      await _moveTo(tester, mouse, const Offset(700, 500));
      expect(find.text('New'), findsNothing);
    });

    testWidgets('a disabled row under the pointer lights none', (tester) async {
      await tester.pumpWidget(harness(_view()));
      final mouse = await _mouse(tester);
      await _click(tester, mouse, find.text('File'));
      await _moveTo(tester, mouse, tester.getCenter(find.text('New')));
      expect(_litRows(_fileRows), ['New']);
      await _moveTo(tester, mouse, tester.getCenter(find.text('Revert')));
      expect(_litRows(_fileRows), isEmpty);
      expect(_has('Revert', WidgetState.disabled), isTrue);
      await mouse.down(tester.getCenter(find.text('Revert')));
      await mouse.up();
      await tester.pumpAndSettle();
      expect(find.text('New'), findsOneWidget, reason: 'a disabled row stays');
    });

    testWidgets('a typed letter picks a row before any is lit', (tester) async {
      await tester.pumpWidget(harness(_view()));
      final mouse = await _mouse(tester);
      await _click(tester, mouse, find.text('File'));
      await _key(tester, LogicalKeyboardKey.keyQ);
      expect(_keysOn(tester, 'Quit'), isTrue);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(_ran, ['quit']);
    });

    testWidgets('a pointer resting on a submenu\'s row opens it, no row lit '
        'in it; its row stays selected while the pointer goes in', (
      tester,
    ) async {
      await tester.pumpWidget(harness(_view()));
      final mouse = await _mouse(tester);
      await _click(tester, mouse, find.text('File'));
      await _moveTo(tester, mouse, tester.getCenter(find.text('Open recent')));
      expect(find.text('a.txt'), findsOneWidget);
      expect(_litRows(['a.txt', 'b.txt']), isEmpty);
      expect(_has('Open recent', WidgetState.selected), isTrue);
      // Into the submenu by the gap at its start, then onto a row.
      final first = tester.getCenter(find.text('b.txt'));
      await _moveTo(tester, mouse, first);
      expect(_litRows(['a.txt', 'b.txt']), ['b.txt']);
      expect(_has('Open recent', WidgetState.selected), isTrue);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(_ran, ['b']);
      expect(find.text('New'), findsNothing, reason: 'the whole menu closed');
    });

    testWidgets('opened from the keys, a submenu starts on its first row', (
      tester,
    ) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await tester.pumpWidget(harness(_view()));
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_litRows(_fileRows), ['New']);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_litRows(['a.txt', 'b.txt']), ['a.txt']);
    });

    testWidgets('highlightFollowsPointer false: the pointer\'s hover is its '
        'own, beside the keys\'', (tester) async {
      await tester.pumpWidget(harness(_view(follow: false)));
      final mouse = await _mouse(tester);
      await _click(tester, mouse, find.text('File'));
      await _moveTo(tester, mouse, tester.getCenter(find.text('Quit')));
      expect(_keysOn(tester, 'Quit'), isFalse);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_has('New', WidgetState.focused), isTrue);
      expect(_has('Quit', WidgetState.hovered), isTrue);
      expect(_litRows(_fileRows), ['New', 'Quit']);
      const bar = DesignMenuBar(
        menus: [],
        itemBuilder: _noItem,
        surfaceBuilder: _noSurface,
        highlightFollowsPointer: false,
      );
      final properties = DiagnosticPropertiesBuilder();
      bar.debugFillProperties(properties);
      expect(
        properties.properties
            .firstWhere((p) => p.name == 'highlightFollowsPointer')
            .toString(),
        contains('highlight stays with the keys'),
      );
    });
  });

  group('a split button\'s menu', () {
    Widget split({bool follow = true}) => Align(
      alignment: Alignment.topLeft,
      child: DesignSplitButton(
        label: 'Save',
        onPressed: () => _ran.add('save'),
        highlightFollowsPointer: follow,
        actions: [
          DesignSplitAction(label: 'Save as', onPressed: () => _ran.add('as')),
          DesignSplitAction(label: 'Export', onPressed: () => _ran.add('ex')),
        ],
        buttonBuilder: (context, part, states, open) =>
            Text(part == DesignSplitPart.main ? 'Save' : 'More'),
        itemBuilder: (context, action, states) {
          _states[action.label] = states;
          return SizedBox(width: 160, height: 44, child: Text(action.label));
        },
        surfaceBuilder: (context, info, items) =>
            Column(mainAxisSize: MainAxisSize.min, children: items),
      ),
    );

    testWidgets('a click opens it with no row lit; the pointer lights one, '
        'and leaving lights none', (tester) async {
      await tester.pumpWidget(harness(split()));
      final mouse = await _mouse(tester);
      await _click(tester, mouse, find.text('More'));
      expect(_litRows(['Save as', 'Export']), isEmpty);
      await _moveTo(tester, mouse, tester.getCenter(find.text('Export')));
      expect(_litRows(['Save as', 'Export']), ['Export']);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_litRows(['Save as', 'Export']), ['Save as']);
      await _moveTo(
        tester,
        mouse,
        tester.getCenter(find.text('Export')) + const Offset(1, 0),
      );
      await _moveTo(tester, mouse, const Offset(700, 500));
      expect(_litRows(['Save as', 'Export']), isEmpty);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(_ran, ['ex']);
    });

    testWidgets('highlightFollowsPointer false: the hover is the row\'s own', (
      tester,
    ) async {
      await tester.pumpWidget(harness(split(follow: false)));
      final mouse = await _mouse(tester);
      await _click(tester, mouse, find.text('More'));
      await _moveTo(tester, mouse, tester.getCenter(find.text('Export')));
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_litRows(['Save as', 'Export']), ['Save as', 'Export']);
    });
  });

  test('the row states: one current row, as the pointer or the keys left '
      'it', () {
    const both = {WidgetState.hovered, WidgetState.focused};
    expect(designMenuRowStates(both, current: false, byPointer: true), isEmpty);
    expect(designMenuRowStates(both, current: true, byPointer: true), {
      WidgetState.hovered,
    });
    expect(designMenuRowStates(both, current: true, byPointer: false), {
      WidgetState.focused,
    });
    // In the touch highlight mode the keys' focus is not shown.
    expect(
      designMenuRowStates(
        const {WidgetState.pressed},
        current: true,
        byPointer: false,
      ),
      {WidgetState.pressed},
    );
  });

  behaviourContract(
    'DesignMenuBar, a menu a click opened',
    // In the middle: room on both sides, so nothing shifts it.
    build: (c) => _view(alignment: Alignment.topCenter),
    open: (tester) async {
      await tester.tap(find.text('File'), kind: PointerDeviceKind.mouse);
    },
    node: () => find.byWidgetPredicate(
      (w) =>
          w is Semantics &&
          w.properties.label == 'File' &&
          w.explicitChildNodes,
    ),
    semantics: isSemantics(label: 'File'),
    noDisabledState:
        'a menu is never disabled; each entry is (DesignMenuEntry.enabled)',
    keyboard: (p) async {
      final t = p.tester;
      expect(_litRows(_fileRows), isEmpty, reason: 'no row lit');
      await p.key(LogicalKeyboardKey.arrowDown);
      expect(_keysOn(t, 'New'), isTrue);
      await p.key(LogicalKeyboardKey.end);
      expect(_keysOn(t, 'Quit'), isTrue);
      await p.key(LogicalKeyboardKey.escape);
      expect(find.text('New'), findsNothing);
      expect(_keysOn(t, 'File'), isTrue, reason: 'back on the bar');
    },
    rtl: (p) async {
      final t = p.tester;
      expect(
        t.getTopRight(find.text('New')).dx,
        moreOrLessEquals(t.getTopRight(find.text('File')).dx),
        reason: 'right to left, the menu hangs from the item\'s right edge',
      );
    },
    motion: (p) async {
      await p.key(LogicalKeyboardKey.escape);
      await p.tester.tap(find.text('Edit'), kind: PointerDeviceKind.mouse);
      await p.tester.pump();
    },
  );
}

Widget _noItem(
  BuildContext context,
  DesignMenuEntry entry,
  DesignMenuLevel level,
  Set<WidgetState> states,
) => const SizedBox();

Widget _noSurface(
  BuildContext context,
  DesignOverlayInfo info,
  List<Widget> items,
) => const SizedBox();
