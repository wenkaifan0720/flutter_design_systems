// Every gallery page at text scale 2.0, a reader's large-text setting, at a phone's and a desktop's width (ui_core's
// shared check, world_checks.dart): no overflow and no exception. Words wrap or end on purpose and controls grow
// taller; nothing is cut. Reduced motion is on, as it is for many who scale their text, so a loading part's
// spinner stands still and the page settles.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gallery_support.dart';
import 'support.dart';
import 'world_checks.dart';

void main() {
  setUpAll(loadComicFonts);

  for (final page in galleryPages) {
    for (final width in [390.0, 1440.0]) {
      testWidgets('${page.id} at text scale 2 and $width', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.reset);
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await expectNoOverflowAtTextScale(
          tester,
          KeyedSubtree(
            key: ValueKey('${page.id}/$width'),
            child: page.build(Brightness.light),
          ),
        );
      });
    }
  }
}
