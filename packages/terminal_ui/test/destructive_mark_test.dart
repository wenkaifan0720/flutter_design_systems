// A destructive action carries the danger's own glyph, ✗, before its words,
// in every palette: in a one-ink palette (mono, phosphor, amber) the danger
// ink is the words' ink, so the glyph is what tells "delete" from "keep".
// A screen reader hears the words alone.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

Widget _in(String palette, Widget child) => MaterialApp(
  home: TermTheme(
    data: TermThemeData.preset(palette, Brightness.dark),
    child: Align(alignment: Alignment.topLeft, child: child),
  ),
);

Finder _mark(Finder of) => find.descendant(of: of, matching: find.text('✗'));

void main() {
  setUpAll(loadFaces);

  for (final palette in TermThemeData.palettes) {
    testWidgets(
      '${palette.id}: a destructive button wears ✗, a safe one none',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(900, 600);
        addTearDown(tester.view.reset);
        const keep = ValueKey('keep');
        const delete = ValueKey('delete');
        const save = ValueKey('save');
        const erase = ValueKey('erase');
        await tester.pumpWidget(
          _in(
            palette.id,
            Wrap(
              children: [
                TermButton(key: keep, label: 'keep', onPressed: () {}),
                TermButton(
                  key: delete,
                  label: 'delete',
                  isDestructiveAction: true,
                  onPressed: () {},
                ),
                TermButton.filled(key: save, label: 'save', onPressed: () {}),
                TermButton.filled(
                  key: erase,
                  label: 'erase',
                  isDestructiveAction: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        );
        expect(_mark(find.byKey(keep)), findsNothing);
        expect(_mark(find.byKey(save)), findsNothing);
        expect(_mark(find.byKey(delete)), findsOneWidget);
        expect(_mark(find.byKey(erase)), findsOneWidget);
        // The glyph stands before the words, at the reading start.
        expect(
          tester.getCenter(_mark(find.byKey(delete))).dx,
          lessThan(tester.getCenter(find.text('delete')).dx),
        );
      },
    );
  }

  testWidgets("a confirm dialog's destructive yes wears ✗, its no none", (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 600);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _in(
        'amber',
        SizedBox(
          width: 600,
          child: TermConfirmDialog(
            title: 'delete Middlemarch',
            message: 'it leaves your shelf',
            confirmLabel: 'delete',
            cancelLabel: 'keep',
            isDestructiveAction: true,
            sheet: false,
            onConfirm: () {},
            onCancel: () {},
          ),
        ),
      ),
    );
    expect(find.text('✗'), findsOneWidget);
    expect(
      tester.getCenter(find.text('✗')).dx,
      lessThan(tester.getCenter(find.text('delete').last).dx),
    );
  });

  testWidgets("a menu's destructive entry wears ✗", (tester) async {
    await tester.pumpWidget(
      _in(
        'mono',
        const SizedBox(
          width: 300,
          child: Column(
            children: [
              TermMenuRow(label: 'rename', states: {}),
              TermMenuRow(label: 'delete', states: {}, danger: true),
            ],
          ),
        ),
      ),
    );
    expect(find.text('✗'), findsOneWidget);
  });

  testWidgets("a bracket face's destructive words wear ✗", (tester) async {
    await tester.pumpWidget(
      _in(
        'phosphor',
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TermBracketFace(label: 'run', enabled: true, press: 0, focus: 0),
            TermBracketFace(
              label: 'purge',
              enabled: true,
              press: 0,
              focus: 0,
              danger: true,
            ),
          ],
        ),
      ),
    );
    expect(find.text('✗'), findsOneWidget);
    expect(
      tester.getCenter(find.text('✗')).dx,
      lessThan(tester.getCenter(find.text('purge')).dx),
    );
  });

  testWidgets('a screen reader hears the words, not the glyph', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _in(
        'amber',
        TermButton(
          label: 'delete',
          isDestructiveAction: true,
          onPressed: () {},
        ),
      ),
    );
    expect(find.bySemanticsLabel('delete'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('✗')), findsNothing);
    semantics.dispose();
  });
}
