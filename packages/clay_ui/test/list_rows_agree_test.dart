// At a large text size the rows of one list agree where their ends stand: on
// a phone every row's key stands under its words, and on a desk's pane every
// row's key stays beside them, whatever each row's words. Rows that decided
// one by one put a key under "Piranesi" and beside "Middlemarch".
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

const _books = [
  ('The Left Hand of Darkness', 'Ursula K. Le Guin · Reading'),
  ('Middlemarch', 'George Eliot · To read'),
  ('Piranesi', 'Susanna Clarke · Done'),
  ('The Remains of the Day', 'Kazuo Ishiguro · To read'),
];

Future<void> _show(
  WidgetTester tester, {
  required double scale,
  required Size size,
  required TextDirection direction,
  double? paneWidth,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final Widget list = ClayGroup(
    children: [
      for (final (title, subtitle) in _books)
        ClayListTile(
          title: title,
          subtitle: subtitle,
          leading: const Icon(IconData(0xe000)),
          trailing: ClayIconButton.plain(
            onPressed: () {},
            icon: const Icon(IconData(0xe001)),
            tooltip: 'Delete $title',
          ),
          onTap: () {},
        ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: ClayTheme(
          data: ClayThemeData.clay(Brightness.light),
          child: app!,
        ),
      ),
      home: Directionality(
        textDirection: direction,
        child: ClayScreen(
          body: paneWidth == null
              ? list
              : Align(
                  alignment: AlignmentDirectional.topStart,
                  child: SizedBox(width: paneWidth, child: list),
                ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// Whether each row's key stands under its words.
List<bool> _under(WidgetTester tester) => [
  for (final (i, (title, _)) in _books.indexed)
    tester.getRect(find.byType(ClayIconButton).at(i)).top >=
        tester.getRect(find.text(title)).bottom - 0.5,
];

void main() {
  setUpAll(clayLoadFonts);
  for (final direction in TextDirection.values) {
    for (final scale in [1.5, 1.6, 1.8, 2.0]) {
      testWidgets('on a phone at ${(scale * 100).round()}% every row\'s key '
          'stands under its words (${direction.name})', (tester) async {
        await _show(
          tester,
          scale: scale,
          size: const Size(390, 844),
          direction: direction,
        );
        expect(_under(tester), everyElement(isTrue));
      });
    }

    testWidgets('on a desk\'s pane at 160% every row\'s key stays beside '
        'its words (${direction.name})', (tester) async {
      await _show(
        tester,
        scale: 1.6,
        size: const Size(1440, 900),
        direction: direction,
        paneWidth: 640,
      );
      expect(_under(tester), everyElement(isFalse));
    });
  }
}
