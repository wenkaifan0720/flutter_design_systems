import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore_for_file: avoid_relative_lib_imports — the gallery under test is the example app, not a package dependency.
import '../example/lib/gallery.dart';
import 'gallery_support.dart' show loadBundledFonts, settle;
import 'support.dart' show loadNeumorphicFonts;
import 'world_checks.dart';

/// The gallery right to left: its side bar's keys and a page's own controls stand mirrored.
void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadBundledFonts();
  });

  void desktop(WidgetTester tester, double width, double height) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  // The pilaster's keys and a page's own controls stand mirrored when the gallery reads right to left. Right to left
  // the gallery reads in Arabic (kit_words.dart), whose page names may take more lines than the English in the
  // pilaster (here more still: a test has no Arabic face, so its letters draw as the test font's wide boxes). The parts
  // above every such name are mirrored whole; Appearance, below them all, side to side.
  for (final page in const ['buttons', 'fields', 'selection']) {
    testWidgets('$page mirrors right to left', (tester) async {
      desktop(tester, 1440, 900);
      Widget app(TextDirection direction) => GalleryApp(
        key: ValueKey(direction),
        initialPage: page,
        initialCustom: GalleryCustom(
          rightToLeft: direction == TextDirection.rtl,
        ),
      );
      await expectMirrorsInRtl(
        tester,
        app,
        parts: [
          find.byKey(const Key('gallery-customize')),
          find.byKey(Key('nav-$page')),
          find.byKey(const Key('nav-overview')),
        ],
      );
      final width = tester.view.physicalSize.width;
      final appearance = find.byKey(const Key('gallery-appearance'));
      await tester.pumpWidget(app(TextDirection.ltr));
      await settle(tester);
      final ltr = tester.getRect(appearance);
      await tester.pumpWidget(app(TextDirection.rtl));
      await settle(tester);
      final rtl = tester.getRect(appearance);
      expect(width - rtl.right, moreOrLessEquals(ltr.left, epsilon: .5));
      expect(rtl.size, ltr.size);
    });
  }
}
