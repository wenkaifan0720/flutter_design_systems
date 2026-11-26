// In a narrow list every row's words at the end stand on its second line,
// beside the subtitle, short title or long, so the ends keep one column; and
// at any width they take at most half the row.
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

  for (final width in [390.0, 800.0]) {
    testWidgets('the words at the end take at most half the row '
        '(${width.toInt()})', (tester) async {
      const long = 'waiting at the library since the spring, then lent twice';
      await tester.pumpWidget(
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
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.text(long)).width,
        lessThanOrEqualTo(width / 2 + 0.5),
      );
    });
  }
}
