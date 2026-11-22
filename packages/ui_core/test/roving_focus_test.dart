// RawRovingFocusGroup: one tab stop, the arrows between its items, built
// on Flutter's focus system so an app changes a key the Flutter way.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const _words = ['A', 'B', 'C', 'D'];

class _Group extends StatefulWidget {
  const _Group({
    this.orientation,
    this.loop = true,
    this.homeAndEnd = true,
    this.selected,
    this.off = const {},
    this.reversed = false,
    this.ordered = false,
    this.shortcuts,
    this.vertical = false,
  });

  final Axis? orientation;
  final bool loop;
  final bool homeAndEnd;
  final String? selected;
  final Set<String> off;
  // Lays the items out last first, so reading order runs against [_words].
  final bool reversed;
  // Gives each item its place in [_words].
  final bool ordered;
  final Map<ShortcutActivator, Intent>? shortcuts;
  final bool vertical;

  @override
  State<_Group> createState() => _GroupState();
}

final Map<String, FocusNode> _nodes = {};
final List<String> _moved = [];
late FocusNode _before, _after;

class _GroupState extends State<_Group> {
  @override
  Widget build(BuildContext context) {
    final items = [
      for (final (i, word) in _words.indexed)
        RawRovingFocusItem(
          key: ValueKey(word),
          focusNode: _nodes[word]!,
          enabled: !widget.off.contains(word),
          selected: word == widget.selected,
          order: widget.ordered ? i : null,
          onMovedTo: () => _moved.add(word),
          child: Focus(
            focusNode: _nodes[word],
            child: SizedBox(width: 40, height: 40, child: Text(word)),
          ),
        ),
    ];
    final laid = widget.reversed ? items.reversed.toList() : items;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Focus(focusNode: _before, child: const Text('before')),
        RawRovingFocusGroup(
          orientation: widget.orientation,
          loop: widget.loop,
          homeAndEnd: widget.homeAndEnd,
          shortcuts: widget.shortcuts,
          child: widget.vertical
              ? Column(mainAxisSize: MainAxisSize.min, children: laid)
              : Row(mainAxisSize: MainAxisSize.min, children: laid),
        ),
        Focus(focusNode: _after, child: const Text('after')),
      ],
    );
  }
}

String? _focused() {
  for (final MapEntry(:key, :value) in _nodes.entries) {
    if (value.hasPrimaryFocus) return key;
  }
  if (_before.hasPrimaryFocus) return 'before';
  if (_after.hasPrimaryFocus) return 'after';
  return null;
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

Future<void> _enter(WidgetTester tester) async {
  _before.requestFocus();
  await tester.pump();
  await _key(tester, LogicalKeyboardKey.tab);
}

void main() {
  setUp(() {
    _moved.clear();
    for (final word in _words) {
      _nodes[word] = FocusNode(debugLabel: word);
    }
    _before = FocusNode(debugLabel: 'before');
    _after = FocusNode(debugLabel: 'after');
  });
  tearDown(() {
    for (final node in [..._nodes.values, _before, _after]) {
      node.dispose();
    }
    _nodes.clear();
  });

  testWidgets('one tab stop: the selected item, else the first enabled; Tab '
      'leaves from wherever the focus is', (tester) async {
    await tester.pumpWidget(harness(const _Group(selected: 'C')));
    await _enter(tester);
    expect(_focused(), 'C');
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_focused(), 'after');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await _key(tester, LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(_focused(), 'C', reason: 'Shift+Tab enters on the stop too');

    // Moved to A by a key, Tab still leaves.
    await _key(tester, LogicalKeyboardKey.home);
    expect(_focused(), 'A');
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_focused(), 'after');

    await tester.pumpWidget(harness(const _Group(off: {'A'})));
    await _enter(tester);
    expect(_focused(), 'B', reason: 'none selected: the first enabled');

    await tester.pumpWidget(harness(const _Group(selected: 'B', off: {'B'})));
    await _enter(tester);
    expect(_focused(), 'A', reason: 'a selected item turned off is no stop');

    await tester.pumpWidget(harness(const _Group(off: {'A', 'B', 'C', 'D'})));
    await _enter(tester);
    expect(_focused(), 'after', reason: 'all off: no stop');
  });

  testWidgets('the arrows: both pairs with no orientation, one pair with '
      'one; mirrored right to left; disabled items passed over; wrapping', (
    tester,
  ) async {
    await tester.pumpWidget(harness(const _Group(off: {'B'})));
    await _enter(tester);
    expect(_focused(), 'A');
    for (final (key, to) in [
      (LogicalKeyboardKey.arrowRight, 'C'),
      (LogicalKeyboardKey.arrowDown, 'D'),
      (LogicalKeyboardKey.arrowDown, 'A'),
      (LogicalKeyboardKey.arrowUp, 'D'),
      (LogicalKeyboardKey.arrowLeft, 'C'),
      (LogicalKeyboardKey.home, 'A'),
      (LogicalKeyboardKey.end, 'D'),
    ]) {
      await _key(tester, key);
      expect(_focused(), to, reason: '$key');
    }
    expect(_moved, ['C', 'D', 'A', 'D', 'C', 'A', 'D']);

    await tester.pumpWidget(
      harness(const _Group(), textDirection: TextDirection.rtl),
    );
    await _enter(tester);
    expect(_focused(), 'A');
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    expect(_focused(), 'B', reason: 'right to left, Left moves on');
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focused(), 'A');

    await tester.pumpWidget(
      harness(const _Group(orientation: Axis.horizontal)),
    );
    await _enter(tester);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_focused(), isNot('B'), reason: 'Down is not along a row');
    await tester.pumpWidget(
      harness(const _Group(orientation: Axis.vertical, vertical: true)),
    );
    await _enter(tester);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focused(), 'A', reason: 'Right is not along a column');
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_focused(), 'B');
  });

  testWidgets('loop false stops at the ends; homeAndEnd false leaves Home '
      'and End alone', (tester) async {
    await tester.pumpWidget(
      harness(const _Group(loop: false, homeAndEnd: false, selected: 'D')),
    );
    await _enter(tester);
    expect(_focused(), 'D');
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focused(), 'D', reason: 'no way past the last');
    await _key(tester, LogicalKeyboardKey.home);
    expect(_focused(), 'D', reason: 'Home is not bound');
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    expect(_focused(), 'A', reason: 'no way before the first');
  });

  testWidgets('the order: reading order unless every item gives its own', (
    tester,
  ) async {
    await tester.pumpWidget(harness(const _Group(reversed: true)));
    await _enter(tester);
    expect(_focused(), 'D', reason: 'D is drawn first');
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focused(), 'C');
    await tester.pumpWidget(
      harness(const _Group(reversed: true, ordered: true)),
    );
    await _enter(tester);
    expect(_focused(), 'A', reason: 'A is first by its order');
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focused(), 'B');
  });

  testWidgets('an app changes a key the Flutter way: its own shortcuts, a '
      'Shortcuts between, an Actions round the group', (tester) async {
    // The group's own keys, replaced.
    await tester.pumpWidget(
      harness(
        const _Group(
          shortcuts: {
            SingleActivator(LogicalKeyboardKey.keyJ): RawRovingFocusIntent(
              RawRovingFocusMove.next,
            ),
          },
        ),
      ),
    );
    await _enter(tester);
    await _key(tester, LogicalKeyboardKey.keyJ);
    expect(_focused(), 'B');
    expect(_moved, ['B']);
    // Right goes on to the app's own shortcuts (its directional focus).
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_moved, ['B'], reason: 'Right is no longer the group\'s');

    // An action round the group runs in place of the move.
    final seen = <RawRovingFocusMove>[];
    await tester.pumpWidget(
      harness(
        Actions(
          actions: {
            RawRovingFocusIntent: CallbackAction<RawRovingFocusIntent>(
              onInvoke: (intent) => seen.add(intent.move),
            ),
          },
          child: const _Group(),
        ),
      ),
    );
    await _enter(tester);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(seen, [RawRovingFocusMove.next]);
    expect(_focused(), 'A', reason: "the app's action took the key");

    // A Shortcuts between the group and an item stops a key there.
    await tester.pumpWidget(
      harness(
        RawRovingFocusGroup(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final word in _words)
                Shortcuts(
                  shortcuts: const {
                    SingleActivator(LogicalKeyboardKey.arrowRight):
                        DoNothingAndStopPropagationIntent(),
                  },
                  child: RawRovingFocusItem(
                    focusNode: _nodes[word]!,
                    child: Focus(
                      focusNode: _nodes[word],
                      child: SizedBox.square(dimension: 40, child: Text(word)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    _nodes['A']!.requestFocus();
    await tester.pump();
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focused(), 'A');
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_focused(), 'B', reason: 'the other keys still move');
  });

  testWidgets("the caller's nodes keep their settings and are never "
      'disposed; onMovedTo runs on arrival, also onto the focused item', (
    tester,
  ) async {
    var heard = 0;
    _nodes['B']!.addListener(() => heard++);
    await tester.pumpWidget(harness(const _Group(off: {'A', 'C', 'D'})));
    await _enter(tester);
    expect(_focused(), 'B');
    for (final node in _nodes.values) {
      expect(node.skipTraversal, isFalse);
    }
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focused(), 'B', reason: 'the one item enabled');
    expect(_moved, ['B'], reason: 'arrived where it was');
    expect(heard, greaterThan(0));
    await tester.pumpWidget(const SizedBox());
    // Usable after the group is gone: not disposed.
    _nodes['B']!.addListener(() {});
  });

  testWidgets('a row of buttons the caller lays out, its words between them: '
      'one tab stop, the arrows choosing as they move (onMovedTo)', (
    tester,
  ) async {
    final nodes = [for (final w in _words) FocusNode(debugLabel: 'row $w')];
    addTearDown(() {
      for (final node in nodes) {
        node.dispose();
      }
    });
    var chosen = 1;
    await tester.pumpWidget(
      harness(
        StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Focus(focusNode: _before, child: const Text('before')),
              RawRovingFocusGroup(
                orientation: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, word) in _words.indexed) ...[
                      if (i > 0) const Text(' | '),
                      RawRovingFocusItem(
                        focusNode: nodes[i],
                        selected: i == chosen,
                        onMovedTo: () => setState(() => chosen = i),
                        child: RawButton(
                          focusNode: nodes[i],
                          selected: i == chosen,
                          onPressed: () => setState(() => chosen = i),
                          builder: (context, states, _) => Text(word),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await _enter(tester);
    expect(nodes[1].hasPrimaryFocus, isTrue, reason: 'Tab enters on B');
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(nodes[2].hasPrimaryFocus, isTrue);
    expect(chosen, 2);
    await _key(tester, LogicalKeyboardKey.home);
    expect(nodes[0].hasPrimaryFocus, isTrue);
    expect(chosen, 0);
  });
}
