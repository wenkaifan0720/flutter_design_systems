// A list's rows. A row with swipe actions carries its "More actions"
// button as a control of its own (its own node, a button a screen reader
// reaches), and a pointer over either the row or the button greys them as
// one row. A row's status at the end takes at most its share of the row;
// a leading glyph or monogram stays out of the row's name, which it would
// only repeat, while a status is in it.
import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screens_matrix.dart' show loadScreenFonts;

Future<void> _show(
  WidgetTester tester,
  Widget body, {
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          CivicHost(child: child ?? const SizedBox.shrink()),
      home: CivicScreen(body: body),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _swiped() => CivicSwipeActions(
  menuLabel: 'Actions for Resident permit',
  endActions: [
    CivicSwipeAction(label: 'Archive', onPressed: () {}),
    CivicSwipeAction(
      label: 'Withdraw',
      onPressed: () {},
      isDestructiveAction: true,
    ),
  ],
  child: CivicListRow(
    title: const Text('Resident permit'),
    subtitle: const Text('Zone B'),
    onTap: () {},
  ),
);

/// The ground the row and its button share: the nearest box painted round
/// both.
Color _ground(WidgetTester tester) {
  final menu = find.bySemanticsLabel('Actions for Resident permit');
  final grounds = find.ancestor(
    of: find.text('Resident permit'),
    matching: find.byType(ColoredBox),
  );
  for (final element in grounds.evaluate()) {
    final both = find.descendant(
      of: find.byElementPredicate((e) => e == element),
      matching: menu,
    );
    if (both.evaluate().isNotEmpty) {
      return (element.widget as ColoredBox).color;
    }
  }
  fail('no ground round the row and its button');
}

/// What a screen reader walks through: each node's label and whether it is
/// a button.
List<(String, bool)> _nodes(WidgetTester tester) => [
  for (final node in tester.semantics.simulatedAccessibilityTraversal())
    (
      node.getSemanticsData().label,
      node.getSemanticsData().flagsCollection.isButton,
    ),
];

void main() {
  setUpAll(loadScreenFonts);

  testWidgets("the row's menu button is a button of its own", (tester) async {
    final semantics = tester.ensureSemantics();
    await _show(tester, _swiped());
    final nodes = _nodes(tester);
    expect(nodes, contains(('Actions for Resident permit', true)));
    final row = nodes.singleWhere((n) => n.$1.startsWith('Resident permit'));
    expect(row.$1, isNot(contains('Actions for')));
    semantics.dispose();
  });

  for (final over in ['row', 'button']) {
    testWidgets('a pointer over the $over greys the row and its button as '
        'one', (tester) async {
      await _show(tester, _swiped());
      expect(_ground(tester).a, 0);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(
        tester.getCenter(
          over == 'row'
              ? find.text('Resident permit')
              : find.bySemanticsLabel('Actions for Resident permit'),
        ),
      );
      await tester.pumpAndSettle();
      expect(_ground(tester).a, greaterThan(0));
      // The row's own grey stays off under the shared ground: one grey.
      final rowGround = find.descendant(
        of: find.byType(CivicListRow),
        matching: find.byType(ColoredBox),
      );
      for (final box in tester.widgetList<ColoredBox>(rowGround)) {
        expect(box.color.a, lessThan(0.01), reason: 'a second grey');
      }
    });
  }

  for (final width in [390.0, 1440.0]) {
    testWidgets('a long status keeps within the row and off its words: '
        'beside them at most its share, else under them (${width.toInt()})', (
      tester,
    ) async {
      await _show(
        tester,
        CivicListRow(
          title: const Text('Resident permit'),
          trailing: const CivicTag(
            label: 'Waiting for proof of address from the council office',
          ),
          onTap: () {},
        ),
        width: width,
      );
      expect(tester.takeException(), isNull);
      final row = tester.getRect(find.byType(CivicListRow));
      final tag = tester.getRect(find.byType(CivicTag));
      final title = tester.getRect(find.text('Resident permit'));
      expect(tag.left, greaterThanOrEqualTo(row.left));
      expect(tag.right, lessThanOrEqualTo(row.right));
      if (width < 600) {
        expect(tag.top, greaterThanOrEqualTo(title.bottom));
      } else if (tag.top < title.bottom) {
        // Beside the words: its share of the row at most.
        expect(tag.width, lessThanOrEqualTo(row.width * 0.4 + 1));
      }
      // Never over the words.
      expect(tag.overlaps(title), isFalse);
    });
  }

  testWidgets("a monogram stays out of the row's name; its status is in it", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _show(
      tester,
      CivicListRow(
        leading: const CivicAvatar(name: 'Ana Ruiz'),
        title: const Text('Ana Ruiz'),
        trailing: const CivicTag(label: 'Approved', tone: CivicTone.success),
        onTap: () {},
      ),
    );
    final names = [
      for (final (label, _) in _nodes(tester))
        if (label.contains('Ana Ruiz')) label,
    ];
    expect(names, hasLength(1));
    expect('Ana Ruiz'.allMatches(names.single), hasLength(1));
    expect(names.single, contains('Approved'));
    semantics.dispose();
  });
}
