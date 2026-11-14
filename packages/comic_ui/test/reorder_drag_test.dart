// A reorderable list's row lifts under a held finger, a held mouse and a mouse on its grip, and its lifted copy stands in
// the navigator's overlay with the themes it was under carried along. None of those themes may put a box of its own
// between the copy and the overlay: the copy is placed by a Positioned, which only the overlay can take. The review
// sheets held a mouse on a row under a page's own ComicTheme in an app with no Material words of Comic's kind; the
// carried theme brought them in a Localizations, whose Semantics box stood in the way and the copy failed to place.
// Material's words now travel only with Comic's own routes, so a field in a raised dialog still has them.
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

Widget _list(List<String> moves) => SizedBox(
  width: 320,
  child: ComicReorderableListView<String>(
    items: const ['Pencils', 'Inks', 'Colours'],
    labelOf: (step) => step,
    shrinkWrap: true,
    onReorder: (from, to) => moves.add('$from to $to'),
    itemBuilder: (context, step) => Text(step),
  ),
);

/// A page's own theme, below the navigator, in each kind of app.
Widget _host(String host, Widget page) {
  final themed = ComicTheme(
    data: ComicTheme.preset('offset', Brightness.light),
    child: Align(alignment: Alignment.topLeft, child: page),
  );
  return switch (host) {
    'the app\'s theme' => comicApp(
      Align(alignment: Alignment.topLeft, child: page),
    ),
    'a page\'s own theme' => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: themed,
    ),
    _ => CupertinoApp(debugShowCheckedModeBanner: false, home: themed),
  };
}

void main() {
  setUpAll(loadComicFonts);

  for (final where in [
    'the app\'s theme',
    'a page\'s own theme',
    'a page\'s own theme in a CupertinoApp',
  ]) {
    for (final (how, kind, onGrip) in const [
      ('a held finger', PointerDeviceKind.touch, false),
      ('a held mouse', PointerDeviceKind.mouse, false),
      ('a mouse on the grip', PointerDeviceKind.mouse, true),
    ]) {
      testWidgets('$how lifts a row under $where', (tester) async {
        final moves = <String>[];
        await tester.pumpWidget(_host(where, _list(moves)));
        await tester.pump();
        final row = tester.getRect(find.text('Inks'));
        final from = onGrip
            ? Offset(
                tester
                        .getRect(find.byType(ComicReorderableListView<String>))
                        .left +
                    20,
                row.center.dy,
              )
            : row.center;
        final gesture = await tester.startGesture(from, kind: kind);
        await tester.pump(const Duration(milliseconds: 700));
        await gesture.moveBy(const Offset(0, 30));
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.moveBy(const Offset(0, 30));
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(moves, isNotEmpty, reason: '$how moved nothing');
      });
    }
  }

  testWidgets(
    'a field in a dialog raised under a page\'s own theme in a CupertinoApp has Material\'s words',
    (tester) async {
      await tester.pumpWidget(
        _host(
          'a page\'s own theme in a CupertinoApp',
          Builder(
            builder: (context) => ComicButton(
              'Rename',
              onPressed: () => showComicDialog<void>(
                context,
                builder: (_) => const ComicDialog(
                  title: 'Rename issue',
                  content: [ComicTextField(hint: 'Title')],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ComicButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final field = find.byType(EditableText);
      expect(field, findsOneWidget);
      expect(
        Localizations.of<MaterialLocalizations>(
          tester.element(field),
          MaterialLocalizations,
        ),
        isNotNull,
      );
      await tester.enterText(field, 'Issue 13');
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
