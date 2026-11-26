// TermGrid.widthOf: a cell for each character Terminal's faces draw, and a
// run of a script no Terminal face draws (Arabic, Devanagari, Thai: the
// platform draws it in a proportional face) measured as it is drawn, so a
// part that sizes itself on widthOf holds its words, no more than a cell over.
// The test engine has no face for these scripts behind Terminal's own (it
// draws them as the face's empty box, a cell wide); a face it can't find
// gives every letter to Flutter's test font, a square em wide, which stands
// in here for the platform's proportional face.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

// A face the test engine can't find: its letters drawn in the test font.
const _face = TermFace(family: 'ProportionalStandIn', advance: 0.6);

void main() {
  setUpAll(loadFaces);
  const grid = TermGrid();

  test('a character the faces draw is a cell', () {
    expect(grid.widthOf('deploy'), grid.cols(6));
    // Hebrew: Liberation Mono, the fallback, draws it on the cell.
    expect(grid.widthOf('\u{5E9}\u{5DC}\u{5D5}\u{5DD}'), grid.cols(4));
    expect(grid.widthOf('\u{90E8}\u{7F72}'), grid.cols(4));
    expect(grid.widthOf('\u{2067}run\u{2069}'), grid.cols(3));
  });

  for (final words in const [
    '\u{627}\u{644}\u{64A}\u{648}\u{645}',
    '\u{906}\u{91C}',
    '\u{E27}\u{E31}\u{E19}\u{E19}\u{E35}\u{E49}',
  ]) {
    testWidgets('$words drawn fits its width, within a cell', (tester) async {
      final theme = TermThemeData.dark(face: _face);
      final grid = theme.grid;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Center(child: Text(words, style: theme.textStyle)),
        ),
      );
      final drawn = tester.getSize(find.text(words)).width;
      final width = grid.widthOf(words);
      expect(width, greaterThanOrEqualTo(drawn - 0.01));
      expect(width, lessThan(drawn + grid.cellWidth + 0.01));
      expect(width, grid.ceilToCols(width), reason: 'whole cells');
    });
  }
}
