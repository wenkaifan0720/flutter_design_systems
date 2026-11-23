// RawTabGroup: a tab bar's behaviour (its semantics, one tab stop with the
// arrows, the selection) round tabs the caller lays out as it likes: frames,
// margins and words between them, its own scroll view round them. Shaped as
// Flutter's RadioGroup: each tab finds the group by its value, wherever it
// stands below it.
import 'dart:ui' show Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const _labels = ['Overview', 'Reviews', 'Photos'];
const _values = ['overview', 'reviews', 'photos'];

// A page's tab row as a generator writes it: each tab in a frame with its
// own margin, a word between the tabs, the row in a scroll view; or, with
// [group] false, the same widgets with no group round them.
class _Row extends StatefulWidget {
  const _Row({
    this.group = true,
    this.follows = true,
    this.off = const {},
    this.direction = TextDirection.ltr,
    this.width,
    this.order,
  });

  final bool group;
  final bool follows;
  final Set<int> off;
  final TextDirection direction;
  // The scroll view's width; null: as wide as the row.
  final double? width;
  // Each tab's place for the arrows; null: reading order.
  final List<int>? order;

  @override
  State<_Row> createState() => _RowState();
}

String _chosenValue = 'overview';
int get _chosen => _values.indexOf(_chosenValue);
final List<Set<WidgetState>> _states = [{}, {}, {}];

class _RowState extends State<_Row> {
  Widget _face(int i, Set<WidgetState> states) {
    _states[i] = states;
    return Container(
      key: ValueKey('face $i'),
      margin: EdgeInsets.symmetric(horizontal: 6.0 + i),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF888888)),
        color: states.contains(WidgetState.selected)
            ? const Color(0xFFDDE4F5)
            : null,
      ),
      child: Text(_labels[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      for (var i = 0; i < _labels.length; i++) ...[
        if (i > 0) const Text('·'),
        if (widget.group)
          RawTabGroupTab(
            value: _values[i],
            enabled: !widget.off.contains(i),
            order: widget.order?[i],
            builder: (context, states, _) => _face(i, states),
          )
        else
          RawButton(
            tab: true,
            selected: i == _chosen,
            onPressed: () {},
            builder: (context, states, _) => _face(i, states),
          ),
      ],
    ];
    Widget row = Row(mainAxisSize: MainAxisSize.min, children: children);
    if (widget.group) {
      row = RawTabGroup<String>(
        groupValue: _chosenValue,
        onChanged: (value) => setState(() => _chosenValue = value),
        selectionFollowsFocus: widget.follows,
        semanticLabel: 'Sections',
        child: row,
      );
    }
    return Directionality(
      textDirection: widget.direction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Focus(focusNode: _before, child: const Text('before')),
          SizedBox(
            key: const ValueKey('view'),
            width: widget.width,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: row,
            ),
          ),
          Focus(focusNode: _after, child: const Text('after')),
        ],
      ),
    );
  }
}

late FocusNode _before, _after;

int? _focusedTab(WidgetTester tester) {
  for (var i = 0; i < _labels.length; i++) {
    final at = tester.element(find.byKey(ValueKey('face $i')));
    if (Focus.of(at).hasPrimaryFocus) return i;
  }
  return null;
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

void main() {
  setUp(() {
    _chosenValue = 'overview';
    _before = FocusNode(debugLabel: 'before');
    _after = FocusNode(debugLabel: 'after');
  });
  tearDown(() {
    _before.dispose();
    _after.dispose();
  });

  testWidgets('the caller lays the tabs out: each face where it stands with '
      'no group round them', (tester) async {
    await tester.pumpWidget(harness(const _Row(group: false)));
    final plain = [
      for (var i = 0; i < _labels.length; i++)
        tester.getRect(find.byKey(ValueKey('face $i'))),
    ];
    await tester.pumpWidget(harness(const _Row()));
    for (var i = 0; i < _labels.length; i++) {
      expect(tester.getRect(find.byKey(ValueKey('face $i'))), plain[i]);
    }
    expect(_states[0], contains(WidgetState.selected));
    expect(_states[1], isNot(contains(WidgetState.selected)));
  });

  testWidgets('a screen reader hears a tab bar of tabs, each with its words '
      'as given and whether it is selected; the words between them are no '
      'tab and break no rule', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(harness(const _Row()));
    expect(tester.takeException(), isNull);
    final bar = tester.semantics.find(find.byType(RawTabGroup<String>));
    expect(bar.getSemanticsData().role, SemanticsRole.tabBar);
    final tabs = <SemanticsData>[];
    bar.visitChildren((node) {
      tabs.add(node.getSemanticsData());
      return true;
    });
    expect([for (final t in tabs) t.role], everyElement(SemanticsRole.tab));
    expect([for (final t in tabs) t.label], _labels);
    expect(
      [for (final t in tabs) t.flagsCollection.isSelected],
      [Tristate.isTrue, Tristate.isFalse, Tristate.isFalse],
    );
    // The words between the tabs are read with the bar's name.
    expect(bar.getSemanticsData().label, 'Sections\n·\n·');
    semantics.dispose();
  });

  testWidgets("the rule those words keep: Flutter's check fails a tab bar "
      'whose words between its tabs are nodes of their own', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      harness(
        Semantics(
          container: true,
          role: SemanticsRole.tabBar,
          explicitChildNodes: true,
          child: Row(
            children: [
              RawButton(
                tab: true,
                selected: true,
                onPressed: () {},
                builder: (context, states, _) => const Text('A'),
              ),
              const Text('·'),
              RawButton(
                tab: true,
                onPressed: () {},
                builder: (context, states, _) => const Text('B'),
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      tester.takeException(),
      isA<FlutterError>().having(
        (error) => error.message,
        'message',
        'Children of TabBar must have the tab role',
      ),
    );
    semantics.dispose();
  });

  testWidgets('a part with a node of its own between the group and its tabs '
      '(a scroll view inside it, an image with a label) leaves a plain '
      'group: the tabs stay tabs, and no check fails', (tester) async {
    final semantics = tester.ensureSemantics();
    var chosen = 'b';
    await tester.pumpWidget(
      harness(
        StatefulBuilder(
          builder: (context, setState) => RawTabGroup<String>(
            groupValue: chosen,
            onChanged: (value) => setState(() => chosen = value),
            semanticLabel: 'Sections',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final value in ['a', 'b'])
                    RawTabGroupTab(
                      value: value,
                      builder: (context, states, _) => Text('Tab $value'),
                    ),
                  Semantics(image: true, label: 'New', child: const Text('*')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final group = tester.semantics.find(find.byType(RawTabGroup<String>));
    expect(group.getSemanticsData().role, SemanticsRole.none);
    expect(group.getSemanticsData().label, 'Sections');
    final a = tester.getSemantics(find.text('Tab a')).getSemanticsData();
    final b = tester.getSemantics(find.text('Tab b')).getSemanticsData();
    expect([a.role, b.role], [SemanticsRole.tab, SemanticsRole.tab]);
    expect(a.flagsCollection.isSelected, Tristate.isFalse);
    expect(b.flagsCollection.isSelected, Tristate.isTrue);
    semantics.dispose();
  });

  testWidgets('the role comes back when the part goes', (tester) async {
    final semantics = tester.ensureSemantics();
    Widget row({required bool badge}) => harness(
      RawTabGroup<String>(
        groupValue: 'a',
        onChanged: (_) {},
        child: Row(
          children: [
            for (final value in ['a', 'b'])
              RawTabGroupTab(
                value: value,
                builder: (context, states, _) => Text('Tab $value'),
              ),
            if (badge)
              Semantics(image: true, label: 'New', child: const Text('*')),
          ],
        ),
      ),
    );
    SemanticsRole role() => tester.semantics
        .find(find.byType(RawTabGroup<String>))
        .getSemanticsData()
        .role;
    await tester.pumpWidget(row(badge: true));
    expect(role(), SemanticsRole.none);
    await tester.pumpWidget(row(badge: false));
    expect(role(), SemanticsRole.tabBar);
    await tester.pumpWidget(row(badge: true));
    expect(role(), SemanticsRole.none);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('each tab finds its group by value through any depth of the '
      "caller's own widgets, and of an int group's too", (tester) async {
    var chosen = 2;
    await tester.pumpWidget(
      harness(
        StatefulBuilder(
          builder: (context, setState) => RawTabGroup<int>(
            groupValue: chosen,
            onChanged: (value) => setState(() => chosen = value),
            child: Column(
              children: [
                for (final value in [1, 2])
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(),
                      child: RawTabGroupTab(
                        value: value,
                        builder: (context, states, _) => Text(
                          states.contains(WidgetState.selected)
                              ? '$value on'
                              : '$value',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('2 on'), findsOneWidget);
    await tester.tap(find.text('1'));
    await tester.pump();
    expect(chosen, 1);
    expect(find.text('1 on'), findsOneWidget);
  });

  testWidgets('one tab stop, on the selected tab; the arrows move along the '
      'row, choosing as they move, past a tab turned off', (tester) async {
    _chosenValue = 'reviews';
    await tester.pumpWidget(harness(const _Row(off: {2})));
    _before.requestFocus();
    await tester.pump();
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_focusedTab(tester), 1, reason: 'Tab enters on the selected tab');
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focusedTab(tester), 0, reason: 'past the tab turned off, round');
    expect(_chosen, 0);
    await _key(tester, LogicalKeyboardKey.end);
    expect(_focusedTab(tester), 1);
    expect(_chosen, 1);
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_after.hasPrimaryFocus, isTrue, reason: 'the next Tab leaves');
  });

  testWidgets("the arrows, Home and End follow the tabs' order where each "
      'gives one, not where they are drawn', (tester) async {
    // Drawn Overview, Reviews, Photos; in order Overview, Photos, Reviews.
    await tester.pumpWidget(harness(const _Row(order: [0, 2, 1])));
    _before.requestFocus();
    await tester.pump();
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_focusedTab(tester), 0);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focusedTab(tester), 2, reason: 'Photos comes second');
    expect(_chosen, 2);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focusedTab(tester), 1);
    await _key(tester, LogicalKeyboardKey.home);
    expect(_focusedTab(tester), 0);
    await _key(tester, LogicalKeyboardKey.end);
    expect(_focusedTab(tester), 1, reason: 'Reviews comes last');
  });

  testWidgets('right to left, Left moves to the next tab', (tester) async {
    await tester.pumpWidget(harness(const _Row(direction: TextDirection.rtl)));
    _before.requestFocus();
    await tester.pump();
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    expect(_focusedTab(tester), 1);
    expect(_chosen, 1);
  });

  testWidgets('with selectionFollowsFocus false, the arrows move and Enter, '
      'Space or a press chooses', (tester) async {
    await tester.pumpWidget(harness(const _Row(follows: false)));
    _before.requestFocus();
    await tester.pump();
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focusedTab(tester), 1);
    expect(_chosen, 0);
    await _key(tester, LogicalKeyboardKey.enter);
    expect(_chosen, 1);
    await tester.tap(find.byKey(const ValueKey('face 2')));
    await tester.pump();
    expect(_chosen, 2);
  });

  testWidgets('in a row that scrolls, a tab the arrows reach is brought '
      'wholly into view, and Home brings the first back', (tester) async {
    await tester.pumpWidget(harness(const _Row(width: 140)));
    _before.requestFocus();
    await tester.pump();
    await _key(tester, LogicalKeyboardKey.tab);
    final view = tester.getRect(find.byKey(const ValueKey('view')));
    Rect face(int i) => tester.getRect(find.byKey(ValueKey('face $i')));
    expect(face(2).right, greaterThan(view.right), reason: 'out of view');
    await _key(tester, LogicalKeyboardKey.arrowRight);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(_focusedTab(tester), 2);
    expect(face(2).right, lessThanOrEqualTo(view.right + .01));
    expect(face(2).left, greaterThanOrEqualTo(view.left - .01));
    await _key(tester, LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    expect(face(0).left, greaterThanOrEqualTo(view.left - .01));
  });
}
