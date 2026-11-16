// Fluent 2's page motion reaches the routes the gallery pushes itself: Northwind's Files opens a file's page with a
// MaterialPageRoute on the demo's own app (kit.dart's MaterialApp), which reads that app widget's theme rather than
// the look's. At a phone's width and a desktop's, on every platform but a native iOS app, the page comes in from at
// most 20 off its place, settles there, and pops back the same way: nothing slides in from a window's width away.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

import 'gallery_support.dart';

const _platforms = {
  TargetPlatform.android,
  TargetPlatform.fuchsia,
  TargetPlatform.linux,
  TargetPlatform.macOS,
  TargetPlatform.windows,
};

void main() {
  final files = galleryPages.firstWhere((p) => p.id == 'app-files');

  for (final width in [galleryWidth, 1440.0]) {
    testWidgets('a file opens and closes with the look\'s motion at $width', (
      t,
    ) async {
      addTearDown(releaseImages);
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = Size(width, 900);
      addTearDown(t.view.reset);
      await t.pumpWidget(files.build(Brightness.light));
      await settle(t);

      await t.tap(find.text('Q3 plan.docx').hitTestable().first);
      // The hero controller keeps the page off stage for the push's first frame.
      await t.pump();
      await t.pump();
      final copy = find.text('Copy link');
      expect(
        find.ancestor(of: copy, matching: find.byType(Fluent2PageTransition)),
        findsWidgets,
      );
      await t.pump(const Duration(milliseconds: 100));
      final moving = t.getTopLeft(copy);
      await settle(t);
      final placed = t.getTopLeft(copy);
      expect(moving.dy, placed.dy);
      expect(moving.dx - placed.dx, inExclusiveRange(0, 20.001));

      t
          .state<NavigatorState>(
            find.ancestor(of: copy, matching: find.byType(Navigator)).first,
          )
          .pop();
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      final leaving = t.getTopLeft(copy);
      expect(leaving.dy, placed.dy);
      expect(leaving.dx - placed.dx, inExclusiveRange(0, 20.001));
      await settle(t);
      expect(copy, findsNothing);
    }, variant: const TargetPlatformVariant(_platforms));
  }
}
