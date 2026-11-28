// A two-line row whose subtitle and end words don't both fit whole on the
// second line moves its end words to a line of their own, at the row's end,
// so a phone at large text reads the author whole (it had kept 6 to 8
// characters beside the status). Where both fit, they share the line.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

Future<void> _list(
  WidgetTester tester,
  double scale, {
  List<(String, String, String)> rows = const [
    ('Middlemarch', 'George Eliot', 'reading'),
    ('Beloved', 'Toni Morrison', 'to read'),
  ],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          textScaler: TextScaler.linear(scale),
        ),
        child: TermTheme(
          data: TermThemeData.dark(),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 390,
              child: TermPane.list(
                title: 'books',
                children: [
                  for (final (title, author, status) in rows)
                    TermListTile(
                      leading: const Text('·'),
                      title: Text(title),
                      subtitle: Text(author),
                      trailing: Text(status),
                      onTap: () {},
                      action: TermIconButton(
                        glyph: '×',
                        semanticLabel: 'delete $title',
                        onPressed: () {},
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

bool _whole(WidgetTester tester, String words) {
  final p = tester.renderObject<RenderParagraph>(find.text(words));
  return !p.didExceedMaxLines &&
      p.size.width + 0.5 >= p.getMaxIntrinsicWidth(double.infinity);
}

void main() {
  setUpAll(loadFaces);

  testWidgets('at 150% on a phone the author reads whole, the status on a '
      'line of its own at the end', (tester) async {
    await _list(tester, 1.5);
    for (final (author, status) in const [
      ('George Eliot', 'reading'),
      ('Toni Morrison', 'to read'),
    ]) {
      expect(_whole(tester, author), isTrue, reason: author);
      expect(_whole(tester, status), isTrue, reason: status);
      expect(
        tester.getRect(find.text(status)).top,
        greaterThanOrEqualTo(tester.getRect(find.text(author)).bottom - 0.5),
        reason: status,
      );
    }
    // One column of ends.
    expect(
      tester.getRect(find.text('reading')).right,
      closeTo(tester.getRect(find.text('to read')).right, 0.5),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('at 150% an author with a note after it reads whole, the '
      'status under it', (tester) async {
    await _list(
      tester,
      1.5,
      rows: const [
        ('The Left Hand of Darkness', 'Ursula K. Le Guin · favourite', 'done'),
      ],
    );
    final sub = find.text('Ursula K. Le Guin · favourite');
    final grid = TermThemeData.dark().grid;
    // At least the author's 17 cells show (it kept 9 beside the status).
    expect(
      tester.renderObject<RenderParagraph>(sub).size.width,
      greaterThanOrEqualTo(17 * grid.cellWidth * 1.5 - 0.5),
    );
    expect(
      tester.getRect(find.text('done')).top,
      greaterThanOrEqualTo(tester.getRect(sub).bottom - 0.5),
    );
  });

  testWidgets('a subtitle too long for the line either way: the end goes '
      'under all the same, the row three lines tall', (tester) async {
    await _list(
      tester,
      1,
      rows: const [
        (
          'run #1482',
          'fix the flaky retry in the uploader when the network drops',
          '4m',
        ),
      ],
    );
    final message = tester.getRect(
      find.text('fix the flaky retry in the uploader when the network drops'),
    );
    expect(
      tester.getRect(find.text('4m')).top,
      greaterThanOrEqualTo(message.bottom - 0.5),
    );
    expect(
      tester.getRect(find.byType(TermListTile)).height,
      closeTo(3 * TermThemeData.dark().grid.lineHeight, 0.5),
    );
  });

  testWidgets('at 100% the author and the status share the second line', (
    tester,
  ) async {
    await _list(tester, 1);
    final author = tester.getRect(find.text('George Eliot'));
    final status = tester.getRect(find.text('reading'));
    expect(status.center.dy, closeTo(author.center.dy, 0.5));
    expect(_whole(tester, 'George Eliot'), isTrue);
  });

  testWidgets('at 200% the status on a line of its own takes that line, '
      'whole', (tester) async {
    await _list(tester, 2);
    for (final status in const ['reading', 'to read']) {
      expect(_whole(tester, status), isTrue, reason: status);
    }
    expect(tester.takeException(), isNull);
  });
}
