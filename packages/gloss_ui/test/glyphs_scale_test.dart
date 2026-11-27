// A glyph beside words grows with them: a tag's, a segment's, a tree row's, a
// swipe action's, an open menu's check. Glyphs alone in a fixed key (a top bar's
// bead, a stepper's key) keep their size, as Material's icon buttons do.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<double> _glyph(
  WidgetTester t,
  double scale,
  Widget part,
  IconData icon,
) async {
  await t.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: const Size(800, 600),
        textScaler: TextScaler.linear(scale),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: GlossTheme(
          data: GlossThemeData.preset('jade', Brightness.light),
          child: Center(child: part),
        ),
      ),
    ),
  );
  return t.getSize(find.byIcon(icon)).height;
}

void main() {
  testWidgets("a segment's glyph grows with its words", (t) async {
    final part = GlossSegmentedButton<int>(
      segments: const [
        GlossSegment(value: 0, label: 'Grid', icon: LucideIcons.layoutGrid),
        GlossSegment(value: 1, label: 'List', icon: LucideIcons.list),
      ],
      selected: 0,
      onChanged: (_) {},
    );
    final base = await _glyph(t, 1, part, LucideIcons.layoutGrid);
    expect(
      await _glyph(t, 1.4, part, LucideIcons.layoutGrid),
      moreOrLessEquals(base * 1.4, epsilon: .5),
    );
  });

  testWidgets("a tag's glyph grows with its words", (t) async {
    const part = GlossTag(
      'Vegetarian',
      tone: GlossTagTone.accent,
      icon: LucideIcons.leaf,
    );
    final base = await _glyph(t, 1, part, LucideIcons.leaf);
    expect(
      await _glyph(t, 1.4, part, LucideIcons.leaf),
      moreOrLessEquals(base * 1.4, epsilon: .5),
    );
  });
}
