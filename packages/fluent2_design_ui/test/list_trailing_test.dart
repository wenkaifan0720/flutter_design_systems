// A list row's slots: a control at its end keeps its own semantics node (a
// screen reader reaches the share button, on a phone too, where the row's
// tap target once merged it into the row), a monogram repeating the title
// stays out of the row's name and a status tag stays in it, the end slot is
// bounded so a long tag ellipsizes instead of pushing the title out, and the
// group's rules run on to the end column's edge.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

Widget _page(Widget body, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      builder: (context, app) => Directionality(
        textDirection: direction,
        child: Fluent2Host(brightness: Brightness.light, child: app!),
      ),
      home: Fluent2Scaffold(body: body),
    );

void _size(WidgetTester tester, double width) {
  tester.view
    ..physicalSize = Size(width, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// How many times [words] is said across the nodes a screen reader visits
/// (a node merged into its parent is said as part of the parent's).
int _said(WidgetTester tester, String words) {
  var n = 0;
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (!node.isMergedIntoParent) {
      n += RegExp(RegExp.escape(words)).allMatches(data.label).length;
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return n;
}

/// The nodes a screen reader visits (none merged into its parent) whose
/// data, merged descendants and all, passes [test].
FinderBase<SemanticsNode> _visited(bool Function(SemanticsData data) test) =>
    find.semantics.byPredicate(
      (node) => !node.isMergedIntoParent && test(node.getSemanticsData()),
    );

const _long =
    "Wanted since the spring of last year, on a friend's word, and still";

void main() {
  testWidgets(
    'a share button at the end keeps its own node',
    (tester) async {
      await tester.pumpWidget(
        _page(
          Fluent2ListGroup(
            children: [
              Fluent2ListItem(
                title: 'Dune',
                onTap: () {},
                trailing: Fluent2IconButton(
                  Fluent2Icons.share,
                  semanticLabel: 'Share Dune',
                  onPressed: () {},
                ),
              ),
              Fluent2ListItem(
                title: 'Emma',
                onTap: () {},
                trailing: const Fluent2LabelBadge(label: 'To read'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final share = _visited((data) => data.label == 'Share Dune');
      expect(share, findsOneWidget);
      expect(
        share.evaluate().single.getSemanticsData().hasAction(
          SemanticsAction.tap,
        ),
        isTrue,
      );
      final row = _visited(
        (data) =>
            data.label.startsWith('Dune') &&
            data.hasAction(SemanticsAction.tap),
      );
      expect(row, findsOneWidget);
      expect(
        row.evaluate().single.getSemanticsData().label,
        isNot(contains('Share')),
      );
      const DesignControlNodesCheck(look: 'Fluent 2')
          .check(tester.element(find.byType(Fluent2ListGroup)))
          .verify();
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.macOS,
    }),
  );

  testWidgets("a monogram stays out of the row's name", (tester) async {
    await tester.pumpWidget(
      _page(
        Fluent2ListGroup(
          children: [
            Fluent2ListItem(
              title: 'Piranesi',
              leading: const Fluent2Avatar(name: 'Piranesi'),
              onTap: () {},
            ),
            const Fluent2ListItem(
              title: 'Ada Lovelace',
              leading: Fluent2Avatar(name: 'Ada Lovelace'),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_said(tester, 'Piranesi'), 1);
    expect(_said(tester, 'Ada Lovelace'), 1);
  });

  testWidgets("a status tag stays in the row's name", (tester) async {
    await tester.pumpWidget(
      _page(
        Fluent2ListGroup(
          children: [
            Fluent2ListItem(
              title: 'Piranesi',
              leading: const Fluent2Avatar(name: 'Piranesi'),
              trailing: const Fluent2LabelBadge(
                label: 'Reading',
                appearance: Fluent2BadgeAppearance.tint,
              ),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final row = _visited((data) => data.label.contains('Piranesi'));
    expect(row, findsOneWidget);
    expect(row.evaluate().single.getSemanticsData().label, contains('Reading'));
  });

  for (final direction in TextDirection.values) {
    testWidgets('a long tag ellipsizes in a bounded slot (${direction.name})', (
      tester,
    ) async {
      _size(tester, 390);
      await tester.pumpWidget(
        _page(
          Fluent2ListGroup(
            children: [
              Fluent2ListItem(
                title: 'Dune',
                onTap: () {},
                trailing: const Fluent2LabelBadge(label: _long),
              ),
              Fluent2ListItem(
                title: 'Emma',
                value: 'Austen',
                onTap: () {},
                trailing: const Fluent2LabelBadge(label: _long),
              ),
            ],
          ),
          direction: direction,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final title in ['Dune', 'Emma']) {
        final row = tester.getRect(
          find.ancestor(
            of: find.text(title),
            matching: find.byType(Fluent2ListItem),
          ),
        );
        final tag = tester.getRect(
          find.descendant(
            of: find.ancestor(
              of: find.text(title),
              matching: find.byType(Fluent2ListItem),
            ),
            matching: find.byType(Fluent2LabelBadge),
          ),
        );
        final words = tester.getRect(find.text(title));
        expect(tag.width, lessThan(row.width * 2 / 3), reason: title);
        expect(tag.left, greaterThanOrEqualTo(row.left), reason: title);
        expect(tag.right, lessThanOrEqualTo(row.right), reason: title);
        // The title keeps its words, clear of the tag.
        expect(words.width, greaterThan(20), reason: title);
        expect(
          direction == TextDirection.ltr
              ? words.right <= tag.left
              : words.left >= tag.right,
          isTrue,
          reason: title,
        );
      }
    });
  }

  for (final width in const [390.0, 1440.0]) {
    testWidgets('the rules reach the end column (${width.toInt()})', (
      tester,
    ) async {
      _size(tester, width);
      await tester.pumpWidget(
        _page(
          Fluent2ListGroup(
            children: [
              for (final title in ['Dune', 'Emma'])
                Fluent2ListItem(
                  title: title,
                  onTap: () {},
                  trailing: const Fluent2LabelBadge(label: 'To read'),
                ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final group = tester.getRect(find.byType(Fluent2ListGroup));
      final rules = <Rect>[];
      expect(
        tester.renderObject(find.byType(Fluent2ListGroup)),
        paints..everything((method, arguments) {
          if (method == #drawRect) {
            final rect = arguments[0] as Rect;
            if (rect.height <= 1 && rect.width > 100) rules.add(rect);
          }
          return true;
        }),
      );
      expect(rules, hasLength(1));
      final tag = tester.getRect(find.byType(Fluent2LabelBadge).first);
      final rule = rules.single.shift(group.topLeft);
      expect(rule.right, greaterThanOrEqualTo(tag.right));
      expect(rule.right, lessThanOrEqualTo(group.right + 0.5));
    });
  }
}
