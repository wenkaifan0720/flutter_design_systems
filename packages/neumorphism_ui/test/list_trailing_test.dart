// A list row's end: a row that opens says its words and its status, not its mark; its menu key is a stop of its own;
// a long status keeps to its share beside the words or goes under them, never past the row; the rule between rows
// runs under the status and the key.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

Future<void> _pump(
  WidgetTester t,
  Widget child, {
  double width = 390,
  TextDirection direction = TextDirection.ltr,
}) async {
  t.view.physicalSize = Size(width, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    neumorphicApp(
      Directionality(
        textDirection: direction,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [child],
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  expect(t.takeException(), isNull);
}

const _long = 'Returned to the library after the second reminder';

void main() {
  setUpAll(loadNeumorphicFonts);

  testWidgets('a row that opens says its words and its status, not its mark', (
    t,
  ) async {
    final handle = t.ensureSemantics();
    await _pump(
      t,
      NeumorphicListTile(
        leading: const NeumorphicMonogram('SW'),
        title: 'Stoner',
        subtitle: 'John Williams',
        trailing: const NeumorphicTag('Reading'),
        onPressed: () {},
      ),
    );
    expect(
      find.bySemanticsLabel('Stoner, John Williams, Reading'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp(r'\bSW\b')), findsNothing);
    handle.dispose();
  });

  testWidgets("a row's menu key is a stop of its own", (t) async {
    final handle = t.ensureSemantics();
    var opened = 0, menus = 0;
    await _pump(
      t,
      NeumorphicListTile(
        title: 'Stoner',
        subtitle: 'John Williams',
        trailing: const NeumorphicStatus('Finished'),
        onPressed: () => opened++,
        action: NeumorphicIconButton(
          NeumorphicGlyphs.ellipsis,
          semanticLabel: 'More',
          onPressed: () => menus++,
        ),
      ),
    );
    final row = t.getSemantics(
      find.bySemanticsLabel('Stoner, John Williams, Finished'),
    );
    final key = t.getSemantics(find.bySemanticsLabel('More'));
    expect(key.id, isNot(row.id));
    expect(key.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(row.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    await t.tap(find.byType(NeumorphicIconButton));
    await t.pumpAndSettle();
    expect((opened, menus), (0, 1));
    handle.dispose();
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      'a long status keeps to its share or goes under the words (${direction.name})',
      (t) async {
        await _pump(
          t,
          NeumorphicListTile(
            leading: const NeumorphicMonogram('P'),
            title: 'Piranesi',
            subtitle: 'Susanna Clarke',
            trailing: const NeumorphicTag(_long),
            onPressed: () {},
          ),
          direction: direction,
        );
        final row = t.getRect(find.byType(NeumorphicListTile));
        final tag = t.getRect(find.byType(NeumorphicTag));
        final title = t.getRect(find.text('Piranesi'));
        expect(tag.left, greaterThanOrEqualTo(row.left - .5));
        expect(tag.right, lessThanOrEqualTo(row.right + .5));
        final beside = tag.top < title.bottom;
        if (beside) {
          expect(tag.width, lessThanOrEqualTo(row.width * .4 + .5));
        }
      },
    );
  }

  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'the rule between rows runs under the status and the key (${width.toInt()})',
      (t) async {
        Widget row(String title, {bool first = false}) => NeumorphicListTile(
          title: title,
          isFirst: first,
          trailing: const NeumorphicTag('Due Friday'),
          onPressed: () {},
          action: NeumorphicIconButton(
            NeumorphicGlyphs.ellipsis,
            semanticLabel: 'More',
            onPressed: () {},
          ),
        );
        await _pump(
          t,
          NeumorphicListSection(
            children: [row('Piranesi', first: true), row('Middlemarch')],
          ),
          width: width,
        );
        final rule = find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString() == '_TopRule',
        );
        expect(rule, findsOneWidget);
        final line = t.getRect(rule);
        final key = t.getRect(find.byType(NeumorphicIconButton).last);
        final tag = t.getRect(find.byType(NeumorphicTag).last);
        expect(line.right, greaterThanOrEqualTo(key.right - .5));
        expect(line.right, greaterThanOrEqualTo(tag.right));
        expect(line.left, lessThanOrEqualTo(tag.left));
      },
    );
  }
}
