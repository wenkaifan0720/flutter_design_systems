// A list row of three lines or more (a title, its line and a note, or words that wrap) stands its mark and its key at
// the top by itself, as Material 3's list items do, both on the middle of the title's first line; a row of one or two
// lines keeps them on its middle.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

const _mark = Key('mark');
const _key = Key('key');

Future<void> _row(
  WidgetTester tester, {
  String? note,
  bool action = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) =>
          NeumorphicHost(brightness: Brightness.light, child: child!),
      home: Align(
        alignment: Alignment.topCenter,
        child: NeumorphicListTile(
          title: 'Proof the studio map',
          subtitle: 'Open studio',
          note: note,
          leading: const SizedBox(key: _mark, width: 40, height: 40),
          action: action
              ? NeumorphicIconButton(
                  NeumorphicGlyphs.share2,
                  key: _key,
                  semanticLabel: 'Share',
                  onPressed: () {},
                )
              : null,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// The middle of the title's one line.
double _titleMiddle(WidgetTester tester) =>
    tester.getRect(find.text('Proof the studio map')).center.dy;

void main() {
  setUpAll(loadNeumorphicFonts);

  testWidgets('a row of two lines stands its mark on its middle', (
    tester,
  ) async {
    await _row(tester);
    final mark = tester.getRect(find.byKey(_mark));
    final row = tester.getRect(find.byType(NeumorphicListTile));
    expect(mark.center.dy, moreOrLessEquals(row.center.dy, epsilon: 1));
  });

  testWidgets('a row of three lines stands its mark on its title\'s line', (
    tester,
  ) async {
    await _row(tester, note: 'Due on Friday, with the printer');
    final mark = tester.getRect(find.byKey(_mark));
    expect(mark.center.dy, moreOrLessEquals(_titleMiddle(tester), epsilon: 1));
  });

  testWidgets(
    'a row of three lines stands its mark and its key on its title\'s line',
    (tester) async {
      await _row(tester, note: 'Due on Friday, with the printer', action: true);
      final mark = tester.getRect(find.byKey(_mark));
      final key = tester.getRect(find.byKey(_key));
      expect(
        mark.center.dy,
        moreOrLessEquals(_titleMiddle(tester), epsilon: 1),
      );
      expect(key.center.dy, moreOrLessEquals(_titleMiddle(tester), epsilon: 1));
    },
  );
}
