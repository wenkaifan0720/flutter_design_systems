// A screen reader hears the gallery round every page, and every section's heading. Each page of the gallery is an app
// of its own (kitScreen and the Papers screens nest a MaterialApp), and a page preview nests the library's
// RetroDesktopPreview; a nested app's modal barrier hides from the semantics tree everything painted before it in the
// same container (material_ui's MaterialApp draws neither of the two containers Flutter's own did). Without a container
// round each nested app the side navigation (painted before the page) went silent, and so would a section's heading
// over a preview. Here: on each page the side navigation's entry for it and every section heading are heard, and on
// the app the gallery opens on (Overview) the menu bar's way back to the gallery.
// ignore_for_file: avoid_relative_lib_imports — the example app's pages are what this test checks; example/ is not a dependency of the package.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/main.dart';
import 'gallery_support.dart';
import 'support.dart';

/// Every label in the semantics tree as a screen reader gets it, each line of a merged label on its own.
Set<String> _heard(WidgetTester tester) {
  final heard = <String>{};
  bool visit(SemanticsNode node) {
    heard.addAll(node.getSemanticsData().label.split('\n'));
    node.visitChildren(visit);
    return true;
  }

  for (final view in tester.binding.renderViews) {
    final root = view.owner?.semanticsOwner?.rootSemanticsNode;
    if (root != null) visit(root);
  }
  return heard;
}

void main() {
  setUpAll(loadRetroDesktopFonts);

  testWidgets('every page keeps the gallery round it and its section headings '
      'in the semantics tree', (tester) async {
    final semantics = tester.ensureSemantics();
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpWidget(const GalleryApp());
    await settle(tester);
    final lost = <String>[];
    // The gallery opens on an app, the whole screen: its menu bar leads back.
    if (!_heard(tester).contains('Gallery')) {
      lost.add('${examplePages.first.name}: "Gallery" is not heard');
    }
    await tester.tap(find.text('Gallery').first);
    await settle(tester);
    for (final page in examplePages) {
      // An app page is opened from the apps' own menus, not the side navigation.
      if (galleryAppPages.contains(page.name)) continue;
      tester.view.physicalSize = const Size(1440, 900);
      await settle(tester);
      final entry = find.descendant(
        of: find.byKey(galleryNavKey),
        matching: find.text(page.name),
      );
      if (entry.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          entry,
          40,
          scrollable: find
              .descendant(
                of: find.byKey(galleryNavKey),
                matching: find.byType(Scrollable),
              )
              .first,
        );
      }
      await tester.ensureVisible(entry.first);
      await settle(tester);
      await tester.tap(entry.first);
      await settle(tester);
      // The whole page laid out, so every section is built.
      final extents = tester
          .stateList<ScrollableState>(find.byType(Scrollable))
          .where((s) => s.position.axis == Axis.vertical)
          .map((s) => s.position.maxScrollExtent);
      final extent = extents.isEmpty
          ? 0.0
          : extents.reduce((a, b) => a > b ? a : b);
      if (extent > 0) {
        tester.view.physicalSize = Size(1440, (900 + extent).clamp(900, 16000));
        await settle(tester);
      }
      final heard = _heard(tester);
      for (final want in [
        page.name,
        for (final (label, _) in sections())
          label.replaceAll(RegExp(r' \d+$'), ''),
      ]) {
        if (!heard.contains(want)) {
          lost.add('${page.name}: "$want" is not heard');
        }
      }
    }
    semantics.dispose();
    expect(lost, isEmpty, reason: lost.join('\n'));
  });
}
