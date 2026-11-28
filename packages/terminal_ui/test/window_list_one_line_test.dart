// A phone's window list stays one line as the reader's text grows, as
// Material's NavigationBar does: its words grow to 1.3 times their size at
// most, and where the names still don't fit the line the numbers go, then
// the blank cell before each name, then the longest names are cut after a
// whole letter with "…". Each window stays
// a target 40 dp or more each way, and a screen reader hears every name whole.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

Widget _app(
  Widget home, {
  required double scale,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: Directionality(
      textDirection: direction,
      child: TermHost(brightness: Brightness.dark, child: child!),
    ),
  ),
  home: home,
);

Widget _bar(List<String> names, {int selected = 0, double? width}) => Builder(
  builder: (context) => ColoredBox(
    color: TermTheme.of(context).background,
    child: Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: width,
        child: TermNavigationBar(
          destinations: [
            for (final name in names) TermNavigationDestination(label: name),
          ],
          selectedIndex: selected,
          onDestinationSelected: (_) {},
        ),
      ),
    ),
  ),
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

String _plain(RenderParagraph p) =>
    p.text.toPlainText(includeSemanticsLabels: false);

// The words the bar paints, one paragraph a window.
List<RenderParagraph> _words(WidgetTester tester) => tester
    .renderObjectList<RenderParagraph>(
      find.descendant(
        of: find.byType(TermNavigationBar),
        matching: find.byType(RichText),
      ),
    )
    .toList();

// One line of windows, every word whole in its box (cut only by an
// ellipsis the bar wrote), every window a target 40 dp or more each way.
void _oneLine(WidgetTester tester, List<String> names, {RegExp? label}) {
  final words = _words(tester);
  expect(words, hasLength(names.length), reason: '${words.map(_plain)}');
  final rows = {
    for (final p in words)
      ((p.localToGlobal(Offset.zero) & p.size).center.dy * 10).round(),
  };
  expect(rows, hasLength(1), reason: 'windows on ${rows.length} lines');
  for (final p in words) {
    expect(
      p.getMaxIntrinsicWidth(double.infinity),
      lessThanOrEqualTo(p.size.width + 0.5),
      reason: '"${_plain(p)}" is clipped',
    );
  }
  final bar = tester.getRect(find.byType(TermNavigationBar));
  for (final name in names) {
    final target = find.bySemanticsLabel(label ?? name).hitTestable();
    expect(target, findsWidgets, reason: name);
    final rect = tester.getRect(target.first);
    expect(rect.width, greaterThanOrEqualTo(40), reason: '$name: $rect');
    expect(rect.height, greaterThanOrEqualTo(40), reason: '$name: $rect');
    expect(rect.height, closeTo(bar.height, 0.01), reason: '$name: $rect');
  }
}

// Left to right: the first word a cell or more from the line's start, and the
// current window's block a cell or more from the word after it.
void _spaced(WidgetTester tester, int selected) {
  final words = _words(tester);
  final p = words.first;
  final cell = p.getMaxIntrinsicWidth(double.infinity) / _plain(p).length;
  final bar = tester.getRect(find.byType(TermNavigationBar));
  final rects = [for (final p in words) p.localToGlobal(Offset.zero) & p.size];
  expect(rects.first.left, greaterThanOrEqualTo(bar.left + cell - 0.5));
  if (selected + 1 < rects.length) {
    expect(
      rects[selected + 1].left,
      greaterThanOrEqualTo(rects[selected].right + cell - 0.5),
      reason: '${words.map(_plain)}',
    );
  }
}

// The current window's block: the face that paints its mark.
Rect _block(WidgetTester tester) {
  final faces = find.descendant(
    of: find.byType(TermNavigationBar),
    matching: find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == '_Inverse',
    ),
  );
  for (final face in faces.evaluate()) {
    final marked = find.descendant(
      of: find.byWidget(face.widget),
      matching: find.textContaining('*'),
    );
    if (marked.evaluate().isNotEmpty) {
      return tester.getRect(find.byWidget(face.widget));
    }
  }
  throw StateError('no current window');
}

void main() {
  setUpAll(loadFaces);

  for (final scale in [1.3, 1.5, 2.0]) {
    for (final d in TextDirection.values) {
      testWidgets(
        'three windows at 390 and ${(scale * 100).round()}% text, ${d.name}: '
        'one line, every name whole',
        (tester) async {
          _phone(tester);
          await tester.pumpWidget(
            _app(
              _bar(const ['books', 'add', 'settings']),
              scale: scale,
              direction: d,
            ),
          );
          await tester.pumpAndSettle();
          _oneLine(tester, const ['books', 'add', 'settings']);
          expect(_words(tester).map(_plain), const [
            '1:books*',
            '2:add ',
            '3:settings ',
          ]);
          // The words at 1.3 times their size, as Material's labels.
          final p = _words(tester).first;
          expect(
            p.getMaxIntrinsicWidth(double.infinity) / _plain(p).length,
            closeTo(15 * 0.6 * 1.3, 0.01),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets("a shell's window list at 390 and 200% text: one line", (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(
        TermScaffold(
          title: 'shelf',
          destinations: const [
            TermNavigationDestination(label: 'books'),
            TermNavigationDestination(label: 'add'),
            TermNavigationDestination(label: 'settings'),
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          body: const Text('the shelf'),
        ),
        scale: 2,
      ),
    );
    await tester.pumpAndSettle();
    final words = _words(tester).map(_plain).toList();
    expect(words, const ['1:books*', '2:add ', '3:settings ']);
    final rows = {
      for (final p in _words(tester))
        ((p.localToGlobal(Offset.zero) & p.size).center.dy * 10).round(),
    };
    expect(rows, hasLength(1));
    for (final name in const ['books', 'add', 'settings']) {
      final rect = tester.getRect(
        find.bySemanticsLabel(RegExp(name)).hitTestable().first,
      );
      expect(rect.width, greaterThanOrEqualTo(40), reason: name);
      expect(rect.height, greaterThanOrEqualTo(40), reason: name);
    }
    expect(tester.takeException(), isNull);
  });

  for (final d in TextDirection.values) {
    testWidgets('four windows at 390 and 200% text, ${d.name}: the numbers go, '
        'the names stay whole', (tester) async {
      _phone(tester);
      const names = ['home', 'runs', 'deploy', 'config'];
      await tester.pumpWidget(
        _app(_bar(names, selected: 1), scale: 2, direction: d),
      );
      await tester.pumpAndSettle();
      _oneLine(tester, names);
      expect(_words(tester).map(_plain), const [
        'home ',
        'runs*',
        'deploy ',
        'config ',
      ]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('five windows at 390 and 200% text, ${d.name}: the longest '
        'names are cut after a whole letter, never the line', (tester) async {
      _phone(tester);
      const names = ['home', 'runs', 'deploy', 'config', 'settings'];
      await tester.pumpWidget(
        _app(_bar(names, selected: 4), scale: 2, direction: d),
      );
      await tester.pumpAndSettle();
      _oneLine(tester, names);
      final words = _words(tester).map(_plain).toList();
      // Each keeps its mark; a cut name ends in the ellipsis, before it.
      for (final (i, word) in words.indexed) {
        expect(word.endsWith(i == 4 ? '*' : ' '), isTrue, reason: word);
        final shown = word.substring(0, word.length - 1);
        expect(
          shown == names[i] ||
              (shown.endsWith('…') &&
                  names[i].startsWith(shown.substring(0, shown.length - 1))),
          isTrue,
          reason: '$word for ${names[i]}',
        );
      }
      // The cells left over go to the names nearest whole: the short ones
      // stay whole. The longest is cut, and no name is cut shorter than a
      // longer one.
      expect(words.take(2), const ['home ', 'runs ']);
      expect(words[4], contains('…'));
      if (d == TextDirection.ltr) _spaced(tester, 4);
      final shownCells = [for (final w in words) w.length];
      for (var i = 0; i < names.length; i++) {
        for (var j = 0; j < names.length; j++) {
          if (names[i].length < names[j].length) {
            expect(
              shownCells[i],
              lessThanOrEqualTo(shownCells[j] + 1),
              reason: '$words',
            );
          }
        }
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('four windows in a 363 pane at 150% text: a cell short of '
      'a blank cell either side, the names stand closer, none cut', (
    tester,
  ) async {
    _phone(tester);
    const names = ['home', 'runs', 'deploy', 'config'];
    await tester.pumpWidget(
      _app(_bar(names, selected: 1, width: 363), scale: 1.5),
    );
    await tester.pumpAndSettle();
    _oneLine(tester, names);
    expect(_words(tester).map(_plain), const [
      'home ',
      'runs*',
      'deploy ',
      'config ',
    ]);
    _spaced(tester, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a short name among long ones at 100% keeps a finger\'s width', (
    tester,
  ) async {
    _phone(tester);
    const names = [
      'ci',
      'overview',
      'pipelines',
      'artifacts',
      'settings',
      'members',
    ];
    await tester.pumpWidget(_app(_bar(names), scale: 1));
    await tester.pumpAndSettle();
    _oneLine(tester, names);
    expect(_words(tester).map(_plain).first, 'ci*');
    expect(tester.takeException(), isNull);
  });

  for (final (names, ends) in const [
    (['books', 'add', 'settings'], [0, 2]),
    (['library', 'add', 'settings'], [0, 2]),
    (['home', 'runs', 'deploy', 'config'], [0, 3]),
    (['home', 'runs', 'deploy', 'config', 'settings'], [0, 4]),
  ]) {
    for (final scale in [1.5, 2.0]) {
      for (final d in TextDirection.values) {
        testWidgets('${names.length} windows at 390 and '
            '${(scale * 100).round()}% text, ${d.name}: the current one\'s '
            'block stands a cell or more off the screen\'s edges', (
          tester,
        ) async {
          _phone(tester);
          for (final selected in ends) {
            await tester.pumpWidget(
              _app(
                _bar(names, selected: selected),
                scale: scale,
                direction: d,
              ),
            );
            await tester.pumpAndSettle();
            final cell = 15 * 0.6 * 1.3;
            final bar = tester.getRect(find.byType(TermNavigationBar));
            final block = _block(tester);
            expect(
              block.left,
              greaterThanOrEqualTo(bar.left + cell - 0.5),
              reason: '${names[selected]}: $block',
            );
            expect(
              block.right,
              lessThanOrEqualTo(bar.right - cell + 0.5),
              reason: '${names[selected]}: $block',
            );
          }
        });
      }
    }
  }

  testWidgets('at its own text size a window list is as it was', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(_bar(const ['books', 'add', 'settings']), scale: 1),
    );
    await tester.pumpAndSettle();
    _oneLine(tester, const ['books', 'add', 'settings']);
    final p = _words(tester).first;
    expect(
      p.getMaxIntrinsicWidth(double.infinity) / _plain(p).length,
      closeTo(9, 0.01),
    );
  });
}
