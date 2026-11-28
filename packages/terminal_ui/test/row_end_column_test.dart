// In a narrow list every row's words at the end stand on its second line,
// beside the subtitle, short title or long, so the ends keep one column. On a
// line they share they take at most half the row; on a line of their own
// they may take all of it, and end in an ellipsis at the row's edge.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

void main() {
  setUpAll(loadFaces);

  testWidgets('the status stands on the second line, short title or long', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TermTheme(
          data: TermThemeData.dark(),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 390,
              child: Column(
                children: [
                  for (final (title, status) in const [
                    ('Beloved', 'to read'),
                    ('A Psalm for the Wild-Built and the Long Way', 'reading'),
                  ])
                    TermListTile(
                      title: Text(title),
                      subtitle: const Text('an author'),
                      trailing: Text(status),
                      onTap: () {},
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final short = tester.getRect(find.text('to read'));
    final long = tester.getRect(find.text('reading'));
    expect(
      short.top,
      greaterThanOrEqualTo(tester.getRect(find.text('Beloved')).bottom - 0.5),
    );
    expect(short.right, closeTo(long.right, 0.5));
    expect(
      short.top - tester.getRect(find.text('Beloved')).top,
      closeTo(
        long.top -
            tester
                .getRect(
                  find.text('A Psalm for the Wild-Built and the Long Way'),
                )
                .top,
        0.5,
      ),
    );
  });

  const long = 'waiting at the library since the spring, then lent twice';
  Future<void> row(WidgetTester tester, double width) => tester.pumpWidget(
    MaterialApp(
      home: TermTheme(
        data: TermThemeData.dark(),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: TermListTile(
              title: const Text('Beloved'),
              subtitle: const Text('Toni Morrison'),
              trailing: const Text(long),
              onTap: () {},
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('on a line of their own (390) the words at the end take the '
      'line, one line, within the row', (tester) async {
    await row(tester, 390);
    expect(tester.takeException(), isNull);
    final end = tester.getRect(find.text(long));
    final author = tester.getRect(find.text('Toni Morrison'));
    final tile = tester.getRect(find.byType(TermListTile));
    expect(end.top, greaterThanOrEqualTo(author.bottom - 0.5));
    expect(end.width, greaterThan(390 / 2));
    expect(end.right, lessThanOrEqualTo(tile.right + 0.5));
    expect(end.height, closeTo(TermThemeData.dark().grid.lineHeight, 0.5));
  });

  testWidgets('on a line they share (800) the words at the end take at most '
      'half the row', (tester) async {
    await row(tester, 800);
    expect(tester.takeException(), isNull);
    final end = tester.getRect(find.text(long));
    expect(end.width, lessThanOrEqualTo(800 / 2 + 0.5));
    expect(
      end.center.dy,
      closeTo(tester.getRect(find.text('Toni Morrison')).center.dy, 0.5),
    );
  });
}
