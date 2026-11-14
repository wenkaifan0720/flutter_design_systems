// The shared inventory: every row is answered, by the class an app of another look would name, and each specimen paints.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/comic_host.dart';

void main() {
  Future<void> paint(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ComicHost(
          light: ComicThemeData.offset(),
          child: Center(child: SizedBox(width: 390, height: 640, child: child)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('every row is answered by its own class', (tester) async {
    // verify() fails on an unknown id, a row answered twice, a missing row and an absent row's to-do reason.
    comicInventory.verify();
  });

  // A row Comic leaves out (the floating action button, the colour picker) has its reason and nothing to paint.
  for (final entry in comicInventory.entries.where((e) => e.builder != null)) {
    testWidgets('${entry.row} paints without a fault', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await paint(tester, Builder(builder: entry.builder!));
      expect(tester.takeException(), isNull);
    });
  }
}
