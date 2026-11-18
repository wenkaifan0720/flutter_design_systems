// The gallery's bar stands outside the app's navigator, so a dialog or a sheet a page raises carries its scrim over
// the bar too (the example's _RaisedOver): softened as the page below it is, gone with the route, and a tap on it
// dismisses the route as a tap on the page's scrim does. ui_core's routes give no barrierColor while they paint their
// own barrier, which the bar read until 0.3.0.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

// The bar is the example app's; a test raises routes under it there.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/main.dart';
import 'gallery_support.dart';

void main() {
  setUpAll(() async {
    await frostedLoadFonts();
    await loadBundledFonts();
  });

  // (the page, the control that raises a route on it, how the route goes)
  for (final (page, raise, byTap) in [
    ('Dialogs', 'Freeze card', false),
    ('Bottom sheets', 'Filters', true),
  ]) {
    testWidgets('$page: $raise raises a softened scrim over the gallery bar '
        'too, and it goes ${byTap ? 'at a tap on the bar' : 'with Escape'}', (
      tester,
    ) async {
      addTearDown(() => kitShownTheme = null);
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(galleryWidth, 844);
      await tester.pumpWidget(const GalleryApp());
      await settle(tester);
      final entry = find.text(page);
      await tester.ensureVisible(entry);
      await settle(tester);
      await tester.tap(entry);
      await settle(tester);

      final over = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_RaisedOver',
      );
      expect(over, findsOneWidget);
      Finder soft() =>
          find.descendant(of: over, matching: find.byType(BackdropFilter));
      expect(soft(), findsNothing, reason: 'nothing raised yet');

      await tester.tap(find.widgetWithText(FrostedButton, raise).first);
      await settle(tester);
      expect(soft(), findsOneWidget, reason: 'the bar softened as the page is');
      final bar = tester.getRect(over);
      expect(bar.top, 0);
      expect(bar.width, galleryWidth);

      if (byTap) {
        await tester.tapAt(bar.center);
      } else {
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      }
      await settle(tester);
      expect(soft(), findsNothing, reason: 'gone with the route');
    });
  }
}
