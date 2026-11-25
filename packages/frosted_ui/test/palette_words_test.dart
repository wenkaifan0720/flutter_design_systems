// Words that read under Material's 4.5:1 on the gallery's pages in Frosted's palettes (ui_core_test's
// DesignContrastCheck), fixed in 0.7.0:
// - by night a chosen tab's words stood in the page's ink on the chosen plate, whose white lifts the glass under a
//   wash: 4.1-4.4:1 in copper and glacier; the words take the nearest tone of the ink that reads;
// - a pane's share ("72% of \$300", at 72% of its hue's ink), its note ("8% less than Sep", 80%) and its due days
//   ("Next due Nov 1", 80%) read 3.5-4.4:1 on a pearl tint by day (and copper's share 4.2:1 by night); each takes the
//   nearest tone that reads at its share, else of the hue's ink;
// - a switch row that cannot be used dims with its switch, but only the switch said it was off, so its words were
//   held as live words (1.9:1); the row now says it is off;
// - opal's quiet ink by night read 4.43:1 on the calendar's glass where the rose and peach washes cross; it reads on
//   the page ink's wash over each peak, as the other palettes' quiet inks do.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

import 'gallery_support.dart';

GalleryPage _page(String id) => galleryPages.firstWhere((p) => p.id == id);

void main() {
  setUpAll(frostedLoadFonts);

  Future<void> reads(
    WidgetTester t,
    String page,
    String palette,
    Brightness brightness,
  ) async {
    await pumpGalleryPage(t, _page(page), palette, brightness);
    t.takeException();
    final report = await const DesignContrastCheck(look: 'Frosted')
        .check(t.binding.rootElement!, runAsync: t.runAsync);
    expect(report.problems, isEmpty);
    expect(report.advisories, isEmpty);
  }

  for (final palette in ['copper', 'glacier']) {
    testWidgets('a chosen tab reads by night in $palette', (t) async {
      await reads(t, 'tabs', palette, Brightness.dark);
    });
  }

  for (final palette in FrostedThemeData.presets) {
    for (final brightness in Brightness.values) {
      testWidgets('a pane\'s share, note and due days read in $palette '
          '(${brightness.name})', (t) async {
        await reads(t, 'card', palette, brightness);
      });
    }
  }

  for (final palette in ['opal', 'quartz']) {
    testWidgets('a switch row that cannot be used is off in $palette', (
      t,
    ) async {
      await reads(t, 'forms', palette, Brightness.light);
    });
  }

  testWidgets('opal\'s quiet ink reads on the calendar by night', (t) async {
    await reads(t, 'calendar', 'opal', Brightness.dark);
  });
}
