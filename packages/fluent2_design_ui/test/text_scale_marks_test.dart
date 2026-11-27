// Tags, monograms and the glyphs set beside words grow with the reader's
// text size, as the words do: at 200% a tag's words, its glyph and its pill,
// an avatar in a row's register and its initials, and a row's glyph are
// larger than at 100%; a portrait keeps its size.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

Widget _at(double scale, Widget child) => MaterialApp(
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: Fluent2Host(brightness: Brightness.light, child: app!),
  ),
  home: Center(child: child),
);

void main() {
  testWidgets('a tag, its glyph and its words grow with the text', (
    tester,
  ) async {
    final sizes = <double, ({double pill, double glyph, double words})>{};
    for (final scale in const [1.0, 2.0]) {
      await tester.pumpWidget(
        _at(
          scale,
          const Fluent2LabelBadge(label: 'Bug', icon: Fluent2Icons.bookmark),
        ),
      );
      sizes[scale] = (
        pill: tester.getSize(find.byType(Fluent2LabelBadge)).height,
        glyph: tester.getSize(find.byType(Icon)).height,
        words: tester.getSize(find.text('Bug')).height,
      );
    }
    expect(sizes[2]!.words, greaterThan(sizes[1]!.words * 1.5));
    expect(sizes[2]!.glyph, greaterThan(sizes[1]!.glyph * 1.5));
    expect(sizes[2]!.pill, greaterThan(sizes[1]!.pill * 1.4));
  });

  testWidgets("a row's avatar and its initials grow with the text; a "
      'portrait keeps its size', (tester) async {
    final discs = <double>[], letters = <double>[], portraits = <double>[];
    for (final scale in const [1.0, 2.0]) {
      await tester.pumpWidget(
        _at(
          scale,
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Fluent2Avatar(name: 'Ana Lima'),
              Fluent2Avatar(name: 'Bo Ek', size: 96),
            ],
          ),
        ),
      );
      discs.add(tester.getSize(find.byType(Fluent2Avatar).first).height);
      letters.add(tester.getSize(find.text('AL')).height);
      portraits.add(tester.getSize(find.byType(Fluent2Avatar).last).height);
    }
    expect(discs[1], discs[0] * 2);
    // Its initials take Fluent's type for the side it is drawn at: a 32
    // avatar at 200% letters as a 64 one does at 100%.
    await tester.pumpWidget(
      _at(1, const Fluent2Avatar(name: 'Ana Lima', size: 64)),
    );
    final at64 = tester.getSize(find.text('AL')).height;
    expect(letters[1], at64);
    expect(letters[1], greaterThan(letters[0] * 1.3));
    expect(portraits[1], portraits[0]);
  });

  testWidgets("a row's glyph grows with the text", (tester) async {
    final heights = <double>[];
    for (final scale in const [1.0, 2.0]) {
      await tester.pumpWidget(
        _at(
          scale,
          const Fluent2ListItem(title: 'Downloads', icon: Fluent2Icons.folder),
        ),
      );
      heights.add(tester.getSize(find.byType(Icon)).height);
    }
    expect(heights[1], greaterThan(heights[0] * 1.5));
  });
}
