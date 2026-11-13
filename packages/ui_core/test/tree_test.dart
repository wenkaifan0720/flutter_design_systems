import 'dart:ui' show Tristate;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const Map<String, List<String>> _files = {
  'src': ['lib', 'main.dart'],
  'lib': ['a.dart', 'b.dart'],
  'test': ['a_test.dart'],
};

final Map<String, Set<WidgetState>> _states = {};

DesignTreeController<String> _controller() => DesignTreeController(
  roots: const ['src', 'test', 'README.md'],
  childrenOf: (node) => _files[node] ?? const [],
);

// The bare reference painter: the name indented 16 px a level, a sign for
// open and closed folders.
Widget _tree(
  DesignTreeController<String> c, {
  ValueChanged<String>? onActivate,
  TextDirection direction = TextDirection.ltr,
}) => harness(_view(c, onActivate: onActivate), textDirection: direction);

Widget _view(
  DesignTreeController<String> c, {
  ValueChanged<String>? onActivate,
}) => Align(
  alignment: AlignmentDirectional.topStart,
  child: SizedBox(
    width: 300,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignTree<String>(
          controller: c,
          labelOf: (node) => node,
          onActivate: onActivate,
          rowBuilder: (context, item) {
            _states[item.row.node] = item.states;
            final sign = item.hasChildren ? (item.expanded ? '- ' : '+ ') : '';
            return Padding(
              padding: EdgeInsetsDirectional.only(start: 16.0 * item.row.depth),
              child: SizedBox(height: 44, child: Text('$sign${item.row.node}')),
            );
          },
        ),
        // A control after the tree, to tab out to.
        Focus(child: plainFace('after')),
      ],
    ),
  ),
);

late DesignTreeController<String> _tc;

bool _lit(String node) => _states[node]?.contains(WidgetState.focused) ?? false;

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
  await tester.pump();
}

void main() {
  setUp(_states.clear);

  bool focused(WidgetTester t, String text) =>
      t
          .getSemantics(find.text(text))
          .getSemanticsData()
          .flagsCollection
          .isFocused ==
      Tristate.isTrue;

  behaviourContract(
    'DesignTree',
    build: (c) => Owned<DesignTreeController<String>>(
      create: () => _tc = _controller(),
      builder: (context, c) => _view(c),
    ),
    node: () => find.text('+ src'),
    semantics: isSemantics(
      label: 'src',
      hint: 'level 1, 1 of 3',
      isFocusable: true,
      hasTapAction: true,
      hasExpandedState: true,
      isExpanded: false,
    ),
    hidden: const ['+ src', '- src'],
    root: () => find.byType(DesignTree<String>),
    noDisabledState: 'a tree is never disabled; a look greys a row',
    keyboard: (p) async {
      final t = p.tester;
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(_tc.isExpanded('src'), isTrue);
      expect(
        t.getSemantics(find.text('- src')),
        isSemantics(label: 'src', isExpanded: true, isFocused: true),
      );
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(focused(t, '+ lib'), isTrue, reason: 'Right steps in');
      await p.key(LogicalKeyboardKey.arrowDown);
      expect(focused(t, 'main.dart'), isTrue);
      await p.key(LogicalKeyboardKey.space);
      expect(
        t.getSemantics(find.text('main.dart')),
        isSemantics(label: 'main.dart', isSelected: true),
      );
      await p.key(LogicalKeyboardKey.arrowLeft);
      expect(focused(t, '- src'), isTrue, reason: 'Left steps out');
      await p.key(LogicalKeyboardKey.end);
      expect(focused(t, 'README.md'), isTrue);
      await p.tab();
      expect(p.focusIn(), isFalse, reason: 'one tab stop');
    },
    rtl: (p) async {
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowLeft);
      expect(
        _tc.isExpanded('src'),
        isTrue,
        reason: 'Left opens, right to left',
      );
    },
    motion: (p) async {
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowRight);
    },
  );

  test('rows: the open nodes in order, with depth, parent and place', () {
    final c = _controller()..setExpanded('src', true);
    expect(
      [for (final r in c.rows) r.node],
      ['src', 'lib', 'main.dart', 'test', 'README.md'],
    );
    final lib = c.rows[1];
    expect(
      (lib.depth, lib.parent, lib.position, lib.siblingCount),
      (1, 'src', 0, 2),
    );
    c.expandAll();
    expect(c.rows, hasLength(8));
    c.setExpanded('README.md', true);
    expect(c.isExpanded('README.md'), isFalse, reason: 'a leaf');
    c.collapseAll();
    expect(c.rows, hasLength(3));
  });

  testWidgets('one tab stop; Right opens then steps in; Left steps out then '
      'closes; Home, End; Enter activates a leaf; * opens the siblings', (
    tester,
  ) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    final c = _controller();
    addTearDown(c.dispose);
    final opened = <String>[];
    await tester.pumpWidget(_tree(c, onActivate: opened.add));
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_lit('src'), isTrue);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(c.isExpanded('src'), isTrue);
    expect(_lit('src'), isTrue);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_lit('lib'), isTrue);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_lit('main.dart'), isTrue);
    await _key(tester, LogicalKeyboardKey.enter);
    expect(opened, ['main.dart']);
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    expect(_lit('src'), isTrue);
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    expect(c.isExpanded('src'), isFalse);
    await _key(tester, LogicalKeyboardKey.end);
    expect(_lit('README.md'), isTrue);
    await _key(tester, LogicalKeyboardKey.space);
    expect(c.selected, {'README.md'});
    // `*` by its character: here the number pad's.
    await tester.sendKeyEvent(
      LogicalKeyboardKey.numpadMultiply,
      character: '*',
    );
    await tester.pump();
    expect(c.isExpanded('src') && c.isExpanded('test'), isTrue);
    await _key(tester, LogicalKeyboardKey.home);
    expect(_lit('src'), isTrue);
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_states.values.any((s) => s.contains(WidgetState.focused)), isFalse);
  });

  testWidgets('right to left: Left steps in; a press on a folder opens it '
      'and selects it', (tester) async {
    final c = _controller();
    addTearDown(c.dispose);
    await tester.pumpWidget(_tree(c, direction: TextDirection.rtl));
    await tester.tap(find.text('+ test'));
    await tester.pump();
    expect(c.isExpanded('test'), isTrue);
    expect(c.selected, {'test'});
    expect(
      tester.getTopRight(find.text('a_test.dart')).dx,
      lessThan(tester.getTopRight(find.text('- test')).dx),
      reason: 'indented from the right',
    );
    Focus.of(tester.element(find.text('- test'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    await tester.pump();
    expect(
      Focus.of(tester.element(find.text('a_test.dart'))).hasPrimaryFocus,
      isTrue,
    );
  });

  testWidgets('a screen reader hears the level, the place and the state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final c = _controller()..setExpanded('src', true);
    addTearDown(c.dispose);
    await tester.pumpWidget(_tree(c));
    expect(
      tester.getSemantics(find.text('+ lib')),
      isSemantics(
        label: 'lib',
        hint: 'level 2, 1 of 2',
        isExpanded: false,
        hasExpandedState: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('- src')),
      isSemantics(label: 'src', isExpanded: true),
    );
    semantics.dispose();
  });
}
