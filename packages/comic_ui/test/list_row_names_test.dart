// A list row's name, as a screen reader hears it: its title, its meta and its status tag, never its monogram; a control
// at its end keeps a node of its own; the rule over a row reaches its action's column.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget list, {
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    comicApp(
      SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: list),
      ),
      width: width,
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadComicFonts();
  });

  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'a row is read with its status tag, not its monogram / $width',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await _pump(
          tester,
          ComicListTile(
            title: 'Piranesi',
            subtitle: 'Susanna Clarke',
            leading: const ComicPerson(initials: 'PI', size: 28),
            trailing: const ComicTag('Done'),
            onPressed: () {},
          ),
          width: width,
        );
        expect(
          find.bySemanticsLabel('Piranesi, Susanna Clarke, Done'),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel(RegExp('PI')), findsNothing);
        semantics.dispose();
      },
    );

    testWidgets(
      'a control at a pressing row\'s end keeps its own node / $width',
      (tester) async {
        final semantics = tester.ensureSemantics();
        var opened = 0, menus = 0;
        await _pump(
          tester,
          ComicListTile(
            title: 'Piranesi',
            subtitle: 'Susanna Clarke',
            trailing: ComicIconButton(
              ComicGlyphs.more,
              semanticLabel: 'Actions for Piranesi',
              onPressed: () => menus++,
            ),
            onPressed: () => opened++,
          ),
          width: width,
        );
        expect(
          find.bySemanticsLabel('Piranesi, Susanna Clarke'),
          findsOneWidget,
        );
        final menu = find.bySemanticsLabel('Actions for Piranesi');
        expect(menu, findsOneWidget);
        tester.semantics.tap(find.semantics.byLabel('Actions for Piranesi'));
        await tester.pump();
        expect((menus, opened), (1, 0));
        tester.semantics.tap(
          find.semantics.byLabel('Piranesi, Susanna Clarke'),
        );
        await tester.pump();
        expect((menus, opened), (1, 1));
        semantics.dispose();
      },
    );

    testWidgets(
      'the rule over a row with an action reaches the action / $width',
      (tester) async {
        const action = ValueKey('open');
        await _pump(
          tester,
          ComicListSection(
            children: [
              ComicListTile(title: 'First', onPressed: () {}, isFirst: true),
              ComicListTile(
                title: 'Bring the tent',
                subtitle: 'Sat 09:00',
                onPressed: () {},
                action: ComicButton(
                  'Open',
                  key: action,
                  size: ComicButtonSize.small,
                  onPressed: () {},
                ),
              ),
            ],
          ),
          width: width,
        );
        final ruled = find.ancestor(
          of: find.byKey(action),
          matching: find.byType(ComicRuled),
        );
        expect(ruled, findsOneWidget);
        final row = tester.getRect(ruled);
        final open = tester.getRect(find.byKey(action));
        expect(row.left <= open.left && row.right >= open.right, isTrue);
      },
    );
  }
}
