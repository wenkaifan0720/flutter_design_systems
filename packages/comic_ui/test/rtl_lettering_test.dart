// Words in a right-to-left script (Arabic, Hebrew) are set in the text face wherever Comic letters a part: the lettering
// face has none of their letters, and with it first in the family list an engine draws them as its missing-glyph boxes
// (the docs' Stint in Arabic showed its page title and its buttons as solid boxes). Latin words keep the lettering.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

bool _arabic(String text) =>
    text.codeUnits.any((c) => c >= 0x600 && c <= 0x6FF);

TextStyle _styleOf(WidgetTester tester, bool Function(String) words) {
  final text = tester
      .widgetList<RichText>(find.byType(RichText))
      .firstWhere((t) => words(t.text.toPlainText()));
  return (text.text as TextSpan).style!;
}

void main() {
  testWidgets(
    "a lettered part sets Arabic words in the text face, Latin ones in the lettering",
    (tester) async {
      late ComicThemeData theme;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: ComicHost(
            child: Builder(
              builder: (context) {
                theme = ComicTheme.of(context);
                return Column(
                  children: [
                    const ComicAppBar(title: 'اليوم'),
                    ComicButton('إيقاف', onPressed: () {}),
                    ComicButton('Stop', onPressed: () {}),
                  ],
                );
              },
            ),
          ),
        ),
      );
      final latin = _styleOf(tester, (t) => t.toUpperCase() == 'STOP');
      expect(latin.fontFamily, endsWith(theme.typeface.display));
      for (final word in ['اليوم', 'إيقاف']) {
        final arabic = _styleOf(tester, (t) => _arabic(t) && t.contains(word));
        expect(
          arabic.fontFamily,
          endsWith(theme.typeface.text),
          reason: '"$word" in the text face',
        );
        expect(
          (arabic.fontFamilyFallback ?? const []).where(
            (f) => f.endsWith(theme.typeface.display),
          ),
          isEmpty,
          reason: '"$word" never falls to the lettering face',
        );
      }
    },
  );
}
