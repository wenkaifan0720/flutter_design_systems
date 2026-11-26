// A row's width decides its lines, whatever the pointer: a narrow row (a
// phone in a browser) stacks its subtitle under its title; a wide one under a
// finger keeps the subtitle beside it, two lines tall. The words at the end
// take at most half the row.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

Widget _row(RawInput input, double width, {String end = '4m'}) => MaterialApp(
  home: TermTheme(
    data: TermThemeData.dark(),
    child: Builder(
      builder: (context) => RawTapTargetScope(
        targets: RawTapTargets.of(context).copyWith(input: input),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: TermListTile(
              title: const Text('Middlemarch'),
              subtitle: const Text('George Eliot'),
              trailing: Text(end),
              onTap: () {},
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  setUpAll(loadFaces);

  testWidgets('a narrow row under a pointer stacks its subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(_row(RawInput.pointer, 390));
    final lh = TermThemeData.dark().grid.lineHeight;
    expect(
      tester.getSize(find.byType(TermListTile)).height,
      closeTo(lh * 2, 0.5),
    );
    expect(
      tester.getTopLeft(find.text('George Eliot')).dy,
      greaterThan(tester.getBottomLeft(find.text('Middlemarch')).dy - 0.5),
    );
  });

  testWidgets('a wide row under a finger keeps its subtitle beside', (
    tester,
  ) async {
    await tester.pumpWidget(_row(RawInput.touch, 900));
    final lh = TermThemeData.dark().grid.lineHeight;
    expect(
      tester.getSize(find.byType(TermListTile)).height,
      closeTo(lh * 2, 0.5),
    );
    expect(
      tester.getCenter(find.text('George Eliot')).dy,
      closeTo(tester.getCenter(find.text('Middlemarch')).dy, 0.5),
    );
    expect(
      tester.getTopLeft(find.text('George Eliot')).dx,
      greaterThan(tester.getTopRight(find.text('Middlemarch')).dx),
    );
  });

  testWidgets('a wide row under a pointer is one line', (tester) async {
    await tester.pumpWidget(_row(RawInput.pointer, 900));
    final lh = TermThemeData.dark().grid.lineHeight;
    expect(tester.getSize(find.byType(TermListTile)).height, closeTo(lh, 0.5));
  });

  testWidgets('the words at the end take at most half the row', (tester) async {
    await tester.pumpWidget(_row(RawInput.pointer, 900, end: 'x' * 200));
    expect(tester.getSize(find.text('x' * 200)).width, lessThanOrEqualTo(450));
    expect(tester.getSize(find.text('Middlemarch')).width, greaterThan(0));
  });
}
