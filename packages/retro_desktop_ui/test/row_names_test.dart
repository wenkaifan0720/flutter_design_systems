// A list row as a screen reader and an eye take it: its name reads its title, its subtitle and a status tag at its end;
// a control at its end keeps its own node, so it can be reached and pressed apart from the row; and the rule above a
// row with an action runs under the action too, to the list's end.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

Future<void> _pump(WidgetTester tester, List<Widget> rows) async {
  await tester.pumpWidget(
    retroDesktopApp(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 600, child: RetroDesktopList(children: rows)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadRetroDesktopFonts);

  testWidgets("a row's name reads its status tag", (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, [
      RetroDesktopListTile(
        title: 'Piranesi',
        subtitle: 'Susanna Clarke',
        trailing: const RetroDesktopTag('Read'),
        onPressed: () {},
      ),
    ]);
    expect(
      find.bySemanticsLabel(RegExp('Piranesi.*Susanna Clarke.*Read')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets(
    'a control at the end of a row keeps its own node and its own press',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var row = 0, more = 0;
      await _pump(tester, [
        RetroDesktopListTile(
          title: 'Piranesi',
          onPressed: () => row++,
          trailing: RetroDesktopIconButton(
            RetroDesktopGlyphs.more,
            semanticLabel: 'More',
            onPressed: () => more++,
          ),
        ),
      ]);
      expect(find.bySemanticsLabel('More'), findsOneWidget);
      await tester.tap(find.byType(RetroDesktopIconButton));
      await tester.pumpAndSettle();
      expect((row, more), (0, 1));
      semantics.dispose();
    },
  );

  testWidgets('the rule above a row with an action runs under the action too', (
    tester,
  ) async {
    await _pump(tester, [
      RetroDesktopListTile(title: 'Fonts', onPressed: () {}),
      RetroDesktopListTile(
        title: 'Sounds',
        onPressed: () {},
        action: RetroDesktopButton('Open', onPressed: () {}),
      ),
    ]);
    final list = tester.getRect(find.byType(RetroDesktopList));
    final rules = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(RetroDesktopList),
            matching: find.byType(DecoratedBox),
          ),
        )
        .where(
          (d) =>
              d.decoration is BoxDecoration &&
              (d.decoration as BoxDecoration).border?.top.style ==
                  BorderStyle.solid,
        )
        .toList();
    expect(rules, isNotEmpty);
    final widest = rules
        .map((d) => tester.getRect(find.byWidget(d)).width)
        .reduce((a, b) => a > b ? a : b);
    expect(
      widest,
      closeTo(list.width, 1),
      reason: 'The rule reaches the list end, under the action',
    );
  });
}
