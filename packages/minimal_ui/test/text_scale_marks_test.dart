// Tags, monograms and the glyphs set beside words grow with the reader's
// text size, as the words do: at 200% a tag's words, its glyph and its pill,
// an avatar's initials and a status mark beside a row's title are larger
// than at 100%.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Widget _at(double scale, Widget child) => MaterialApp(
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: MinimalHost(brightness: Brightness.light, child: app!),
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
        _at(scale, const MinimalTag('Bug', icon: LucideIcons.bug)),
      );
      final pill = tester.getSize(find.byType(MinimalTag)).height;
      final glyph = tester.getSize(find.byType(Icon)).height;
      final words = tester.getSize(find.text('Bug')).height;
      sizes[scale] = (pill: pill, glyph: glyph, words: words);
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
              MinimalAvatar('Ana Lima'),
              MinimalAvatar('Bo Ek', size: 96),
            ],
          ),
        ),
      );
      discs.add(tester.getSize(find.byType(MinimalAvatar).first).height);
      letters.add(tester.getSize(find.text('AL')).height);
      portraits.add(tester.getSize(find.byType(MinimalAvatar).last).height);
    }
    expect(discs[1], discs[0] * 2);
    expect(letters[1], greaterThan(letters[0] * 1.5));
    expect(portraits[1], portraits[0]);
  });

  testWidgets("a status mark beside a row's title grows with the text", (
    tester,
  ) async {
    final heights = <double>[];
    for (final scale in const [1.0, 2.0]) {
      await tester.pumpWidget(
        _at(
          scale,
          MinimalListTile(
            title: 'Fix the login',
            leading: MinimalStatusIcon(MinimalTaskStatus.values[1]),
          ),
        ),
      );
      heights.add(tester.getSize(find.byType(MinimalStatusIcon)).height);
    }
    expect(heights[1], greaterThan(heights[0] * 1.3));
  });
}
