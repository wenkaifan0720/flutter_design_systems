// A text field with a glyph before its words starts them as close to the
// glyph as the search field does: one gap from glyph to words in every
// Gloss well, in either reading direction (the text field's was 8 wider).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  setUpAll(glossLoadFonts);

  for (final direction in TextDirection.values) {
    testWidgets('glyph to words: one gap, $direction', (tester) async {
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, app) => GlossHost(
            theme: GlossThemeData.light(),
            darkTheme: GlossThemeData.dark(),
            brightness: Brightness.light,
            child: Directionality(textDirection: direction, child: app!),
          ),
          home: const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                GlossTextField(
                  hintText: 'Find a recipe',
                  prefixIcon: Icon(LucideIcons.search),
                ),
                SizedBox(height: 16),
                GlossSearchField(hintText: 'Search recipes'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      double gap(Type field, String hint) {
        final glyph = tester.getRect(
          find.descendant(of: find.byType(field), matching: find.byType(Icon)),
        );
        final words = tester.getRect(
          find.descendant(
            of: find.byType(field),
            matching: find.byType(EditableText),
          ),
        );
        return direction == TextDirection.ltr
            ? words.left - glyph.right
            : glyph.left - words.right;
      }

      expect(
        gap(GlossTextField, 'Find a recipe'),
        moreOrLessEquals(gap(GlossSearchField, 'Search recipes'), epsilon: 0.5),
      );
    });
  }
}
