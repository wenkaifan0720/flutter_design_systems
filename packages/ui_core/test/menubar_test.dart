import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart' show SemanticsData;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

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
      const DesignMenuEntry.divider(),
      DesignMenuEntry(label: 'Quit', onPressed: () => _ran.add('quit')),
    ],
  ),
  DesignMenuEntry(
    label: 'Edit',
    children: [
      DesignMenuEntry(label: 'Undo', onPressed: () => _ran.add('undo')),
    ],
  ),
  DesignMenuEntry(
    label: 'View',
    children: [
      DesignMenuEntry(
        label: 'Ruler',
        checked: true,
        onPressed: () => _ran.add('ruler'),
      ),
    ],
  ),
];

// The bare reference painter: labelled rows in a grey panel.
Widget _bar({TextDirection direction = TextDirection.ltr}) =>
    harness(_view(), textDirection: direction);

Widget _view() => Align(
  alignment: Alignment.topLeft,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DesignMenuBar(
        menus: _menus(),
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
      // A control after the bar, to tab out to.
      Focus(child: plainFace('after')),
    ],
  ),
);

bool _lit(String label) =>
    _states[label]?.contains(WidgetState.focused) ?? false;

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void _keyboard() {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
}

void main() {
  setUp(() {
    _ran.clear();
    _states.clear();
  });

  SemanticsData item(WidgetTester t, String label) =>
      t.getSemantics(find.text(label)).getSemanticsData();

  behaviourContract(
    'DesignMenuBar',
    build: (c) => _view(),
    node: () => find.bySemanticsLabel('Menu bar'),
    semantics: isSemantics(label: 'Menu bar'),
    noDisabledState:
        'a bar is never disabled; each entry is (DesignMenuEntry.enabled)',
    keyboard: (p) async {
      final t = p.tester;
      await p.tabInto(p.node);
      expect(
        t.getSemantics(find.text('File')),
        isSemantics(
          label: 'File',
          isFocused: true,
          hasExpandedState: true,
          isExpanded: false,
          hasTapAction: true,
        ),
      );
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(item(t, 'Edit').flagsCollection.isFocused, Tristate.isTrue);
      await p.key(LogicalKeyboardKey.arrowLeft);
      await p.key(LogicalKeyboardKey.arrowDown);
      expect(item(t, 'File').flagsCollection.isExpanded, Tristate.isTrue);
      expect(item(t, 'New').flagsCollection.isFocused, Tristate.isTrue);
      await p.key(LogicalKeyboardKey.escape);
      expect(find.text('New'), findsNothing);
      expect(item(t, 'File').flagsCollection.isFocused, Tristate.isTrue);
      await p.tab();
      expect(p.focusIn(), isFalse, reason: 'one tab stop: Tab leaves the bar');
    },
    rtl: (p) async {
      await p.tabInto(p.node);
      await p.key(LogicalKeyboardKey.arrowLeft);
      expect(
        item(p.tester, 'Edit').flagsCollection.isFocused,
        Tristate.isTrue,
        reason: 'Left moves along the bar, right to left',
      );
    },
    motion: (p) async {
      await p.tabInto(p.node);
      await p.key(LogicalKeyboardKey.arrowDown);
      expect(find.text('New'), findsOneWidget);
    },
  );

  testWidgets('one tab stop; Right moves along the bar; Down opens a menu at '
      'its first item; Escape closes it and focus is back on the bar', (
    tester,
  ) async {
    _keyboard();
    await tester.pumpWidget(_bar());
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_lit('File'), isTrue);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_lit('Edit'), isTrue);
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(find.text('New'), findsOneWidget);
    expect(_lit('New'), isTrue);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_lit('Open recent'), isTrue);
    await _key(tester, LogicalKeyboardKey.end);
    expect(_lit('Quit'), isTrue, reason: 'the divider is not a stop');
    await _key(tester, LogicalKeyboardKey.escape);
    expect(find.text('New'), findsNothing);
    expect(_lit('File'), isTrue);
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_lit('File'), isFalse, reason: 'Tab leaves the bar');
  });

  testWidgets('Right opens a submenu, Left closes it; Right on a command '
      'goes to the next menu; Enter runs an item and closes all', (
    tester,
  ) async {
    _keyboard();
    await tester.pumpWidget(_bar());
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.enter);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_lit('a.txt'), isTrue);
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    expect(find.text('a.txt'), findsNothing);
    expect(_lit('Open recent'), isTrue);
    await _key(tester, LogicalKeyboardKey.arrowUp);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(find.text('New'), findsNothing);
    expect(_lit('Undo'), isTrue, reason: 'the Edit menu opened');
    await _key(tester, LogicalKeyboardKey.enter);
    expect(_ran, ['undo']);
    expect(find.text('Undo'), findsNothing);
    expect(_lit('Edit'), isTrue);
  });

  testWidgets('with a menu open, a pointer over another top item opens it; '
      'a tap outside closes it', (tester) async {
    await tester.pumpWidget(_bar());
    await tester.tap(find.text('File'));
    await tester.pumpAndSettle();
    expect(find.text('New'), findsOneWidget);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: tester.getCenter(find.text('File')));
    await mouse.moveTo(tester.getCenter(find.text('View')));
    await tester.pumpAndSettle();
    expect(find.text('New'), findsNothing);
    expect(find.text('Ruler'), findsOneWidget);
    await tester.tapAt(const Offset(700, 500));
    await tester.pumpAndSettle();
    expect(find.text('Ruler'), findsNothing);
  });

  testWidgets('right to left: Left moves along the bar; a screen reader '
      'hears expanded menus and checked items', (tester) async {
    _keyboard();
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_bar(direction: TextDirection.rtl));
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    expect(_lit('Edit'), isTrue);
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(
      tester.getSemantics(find.text('View')),
      isSemantics(label: 'View', isExpanded: true),
    );
    expect(
      tester.getSemantics(find.text('Ruler')),
      isSemantics(label: 'Ruler', isChecked: true),
    );
    semantics.dispose();
  });
}
