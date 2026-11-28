// The gallery's own-corners tile shows a style's `corners` override as a
// vertically symmetric shape: both top corners take one step and both bottom
// corners another, never a diagonal or one-corner cut.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

// The tile is the example app's.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/gallery.dart';
import 'gallery_support.dart';

void main() {
  testWidgets('the own-corners tile is vertically symmetric', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(galleryWidth, 844);
    await tester.pumpWidget(const GalleryApp());
    await settle(tester);

    final card = tester.widget<FrostedCard>(
      find.ancestor(
        of: find.text('Corners of its own'),
        matching: find.byType(FrostedCard),
      ),
    );
    final share = tester.widget<FrostedButton>(
      find.widgetWithText(FrostedButton, 'Share'),
    );
    for (final style in [card.style, share.style]) {
      final corners = style!.corners!.resolve(const {})!;
      expect(corners.topStart, isNotNull);
      expect(corners.bottomStart, isNotNull);
      expect(corners.topEnd, corners.topStart, reason: 'top corners alike');
      expect(
        corners.bottomEnd,
        corners.bottomStart,
        reason: 'bottom corners alike',
      );
      expect(
        corners.topStart,
        isNot(corners.bottomStart),
        reason: 'top and foot take different steps',
      );
    }
  });
}
