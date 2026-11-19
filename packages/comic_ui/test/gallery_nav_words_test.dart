// The gallery's side nav keeps its pages' names whole at any text size: it stands 264 wide, and wider where a name
// holds a word longer than its row. At 300% text "Overview" broke mid-word ("Overvie / w").
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show JSONMethodCodec, MethodCall;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import 'gallery_support.dart';
import 'support.dart';

void main() {
  setUpAll(() async {
    await loadComicFonts();
    await loadBundledFonts();
  });

  for (final (text, direction) in const [
    (100, 'ltr'),
    (200, 'ltr'),
    (300, 'ltr'),
    (300, 'rtl'),
  ]) {
    testWidgets("the side nav's names stay whole at $text% text, $direction", (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GalleryApp());
      await settle(tester);
      final link = const JSONMethodCodec().encodeMethodCall(
        MethodCall('pushRouteInformation', {
          'location': '/pickers?theme=light&dir=$direction&text=$text',
          'state': null,
        }),
      );
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/navigation',
        link,
        (_) {},
      );
      await settle(tester);
      expect(tester.takeException(), isNull);

      final nav = find.byType(ComicNavigationDrawer);
      final width = tester.getSize(nav).width;
      if (text == 100) expect(width, 264, reason: 'it keeps its width');
      final names = tester
          .renderObjectList<RenderParagraph>(
            find.descendant(of: nav, matching: find.byType(RichText)),
          )
          .where((p) => p.text.toPlainText().trim().isNotEmpty)
          .toList();
      expect(names, isNotEmpty);
      for (final p in names) {
        final words = p.text.toPlainText();
        for (final word in words.split(' ')) {
          final one = TextPainter(
            text: TextSpan(text: word, style: p.text.style),
            textDirection: p.textDirection,
            textScaler: p.textScaler,
            maxLines: 1,
          )..layout();
          expect(
            p.size.width + .5,
            greaterThanOrEqualTo(one.width),
            reason: '"$word" in "$words" breaks mid-word in a nav $width wide',
          );
          one.dispose();
        }
      }
    });
  }
}
