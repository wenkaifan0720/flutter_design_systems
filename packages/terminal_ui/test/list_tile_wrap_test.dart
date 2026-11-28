// A narrow row wraps its title and its author at whole words, as Material's
// ListTile does at large text, so a reader tells the rows apart without
// opening them; a word longer than the line is cut after its last whole
// letter, with "…", and a screen reader hears the words whole. The row's
// action stands on the title's first line.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

const _books = [
  ('Middlemarch', 'George Eliot', 'reading'),
  ('The Left Hand of Darkness', 'Ursula K. Le Guin · favourite', 'to read'),
  ('Pride and Prejudice', 'Jane Austen', 'done'),
];

void main() {
  setUpAll(loadFaces);

  Future<void> pump(
    WidgetTester tester, {
    required double scale,
    required List<(String, String?, String)> books,
    bool action = true,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: TermTheme(
              data: TermThemeData.dark(),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 390,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (title, author, status) in books)
                        TermListTile(
                          key: ValueKey(title),
                          leading: const Text('○'),
                          title: Text(title),
                          subtitle: author == null ? null : Text(author),
                          trailing: Text(status),
                          onTap: () {},
                          action: action
                              ? TermIconButton(
                                  glyph: '×',
                                  semanticLabel: 'delete $title',
                                  onPressed: () {},
                                )
                              : null,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // The words a row shows, line by line, each as it is drawn.
  List<(String, Rect)> shown(WidgetTester tester, String title) {
    final row = find.byKey(ValueKey(title));
    return [
      for (final e
          in find
              .descendant(of: row, matching: find.byType(RichText))
              .evaluate())
        if ((e.renderObject! as RenderParagraph).text.toPlainText()
            case final text when text != '○' && text != '×')
          (text, tester.getRect(find.byWidget(e.widget))),
    ];
  }

  for (final scale in [1.5, 2.0]) {
    testWidgets(
      'at ${(scale * 100).round()}% on a phone every title and author '
      'is shown whole, wrapped at words',
      (tester) async {
        await pump(tester, scale: scale, books: _books);
        expect(tester.takeException(), isNull);
        for (final (title, author, status) in _books) {
          final lines = shown(tester, title);
          // Nothing drawn is cut: each line's words fit the box they stand in.
          for (final e
              in find
                  .descendant(
                    of: find.byKey(ValueKey(title)),
                    matching: find.byType(RichText),
                  )
                  .evaluate()) {
            final p = e.renderObject! as RenderParagraph;
            expect(
              p.getMaxIntrinsicWidth(double.infinity),
              lessThanOrEqualTo(p.size.width + 0.5),
              reason: '"${p.text.toPlainText()}" in "$title" is cut',
            );
          }
          // Read in order, the lines are the words: broken between them only.
          final words = lines.map((l) => l.$1).join(' ');
          expect(words, '$title $author $status');
          // Each a line apart.
          for (var i = 1; i < lines.length; i++) {
            expect(lines[i].$2.top, greaterThanOrEqualTo(lines[i - 1].$2.top));
          }
        }
      },
    );
  }

  testWidgets('a word longer than the line is cut after a whole letter, '
      'with "…", and heard whole', (tester) async {
    final semantics = tester.ensureSemantics();
    const word = 'Supercalifragilisticexpialidocious';
    await pump(tester, scale: 2, books: [(word, 'Anon', 'done')]);
    expect(tester.takeException(), isNull);
    final lines = shown(tester, word);
    expect(lines.first.$1, matches(RegExp(r'^Supercal[a-z]*…$')));
    expect(word.startsWith(lines.first.$1.replaceAll('…', '')), isTrue);
    final p = tester.renderObject<RenderParagraph>(find.text(lines.first.$1));
    expect(
      p.getMaxIntrinsicWidth(double.infinity),
      lessThanOrEqualTo(p.size.width + 0.5),
    );
    // The row's words, apart from its action's ("delete …").
    expect(
      find.bySemanticsLabel(RegExp('^(?!delete)[\\s\\S]*$word')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('a wrapped title is heard once, whole', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, scale: 2, books: _books);
    const title = 'The Left Hand of Darkness';
    // Every label under the row: its words' and its action's.
    final labels = <String>[];
    bool visit(SemanticsNode node) {
      labels.add(node.label);
      node.visitChildren(visit);
      return true;
    }

    visit(tester.getSemantics(find.byKey(const ValueKey(title))));
    final words = labels.where((l) => l.contains('Ursula')).toList();
    expect(words, hasLength(1), reason: '$labels');
    expect(RegExp(title).allMatches(words.single), hasLength(1));
    expect(
      labels.where((l) => !l.startsWith('delete')).join('\n'),
      isNot(contains('The Left Hand of\n')),
    );
    semantics.dispose();
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('the [×] stands on the title\'s first line '
        '(${(scale * 100).round()}%)', (tester) async {
      await pump(tester, scale: scale, books: _books);
      for (final (title, _, _) in _books) {
        final first = shown(tester, title).first.$2;
        final glyph = tester.getRect(
          find.descendant(
            of: find.byKey(ValueKey(title)),
            matching: find.text('×'),
          ),
        );
        expect(glyph.center.dy, closeTo(first.center.dy, 0.5), reason: title);
        // Still a whole target, within the row.
        final target = tester.getRect(
          find.descendant(
            of: find.byKey(ValueKey(title)),
            matching: find.byType(TermIconButton),
          ),
        );
        final row = tester.getRect(find.byKey(ValueKey(title)));
        expect(target.height, greaterThanOrEqualTo(40));
        expect(target.top, greaterThanOrEqualTo(row.top - 0.5));
        expect(target.bottom, lessThanOrEqualTo(row.bottom + 0.5));
      }
    });
  }

  testWidgets('where the words wrap, the status stands after their last '
      'line if it fits there, else on a line of its own', (tester) async {
    const title = 'The Left Hand of Darkness';
    // Distinct line tops: how many lines the row's words take.
    int lineCount(List<(String, Rect)> lines) =>
        lines.map((l) => l.$2.top.round()).toSet().length;

    await pump(
      tester,
      scale: 1.5,
      books: [(title, 'Ursula K. Le Guin · favourite', 'to read')],
    );
    var lines = shown(tester, title);
    expect(lines.map((l) => l.$1), [
      'The Left Hand of',
      'Darkness',
      'Ursula K. Le Guin ·',
      'favourite',
      'to read',
    ]);
    expect(lines[4].$2.center.dy, closeTo(lines[3].$2.center.dy, 0.5));
    expect(lines[4].$2.left, greaterThan(lines[3].$2.right));
    expect(lineCount(lines), 4);

    // Without an author, after the title's last line.
    await pump(tester, scale: 1.5, books: [(title, null, 'done')]);
    lines = shown(tester, title);
    expect(lines.map((l) => l.$1), ['The Left Hand of', 'Darkness', 'done']);
    expect(lines[2].$2.center.dy, closeTo(lines[1].$2.center.dy, 0.5));
    expect(lineCount(lines), 2);

    // At 200% "to read" doesn't fit after "favourite": a line of its own.
    await pump(
      tester,
      scale: 2,
      books: [(title, 'Ursula K. Le Guin · favourite', 'to read')],
    );
    lines = shown(tester, title);
    expect(lines.last.$1, 'to read');
    expect(lines.last.$2.top, greaterThan(lines[lines.length - 2].$2.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a one-line row keeps its [×] centred, with its words', (
    tester,
  ) async {
    await pump(tester, scale: 1, books: [('Beloved', null, 'done')]);
    final row = tester.getRect(find.byKey(const ValueKey('Beloved')));
    final glyph = tester.getRect(find.text('×'));
    final title = tester.getRect(find.text('Beloved'));
    expect(glyph.center.dy, closeTo(row.center.dy, 0.5));
    expect(title.center.dy, closeTo(row.center.dy, 0.5));
  });
}
