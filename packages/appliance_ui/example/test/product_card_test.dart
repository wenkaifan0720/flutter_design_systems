import 'package:appliance_ui/appliance_ui.dart';
import 'package:appliance_ui_example/kit_gallery/larder/larder.dart';
import 'package:appliance_ui_example/kit_gallery/larder/shop.dart';
import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(applianceLoadFonts);

  testWidgets('a narrow product card leaves space between price and stock', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const LarderApp(initialScene: LarderScene.search, textScale: 2),
    );
    await tester.pumpAndSettle();
    final card = find.byWidgetPredicate(
      (widget) =>
          widget is LarderProductCard && widget.product.id == 'pour-over',
    );
    final price = tester.getRect(
      find.descendant(of: card, matching: find.text('£36.00')),
    );
    final badge = tester.getRect(
      find.descendant(of: card, matching: find.text('NEW')),
    );
    final lamp = tester.getRect(
      find.descendant(of: card, matching: find.byType(ApplianceLamp)),
    );
    expect(badge.right, lessThan(tester.getRect(card).right - 8));
    expect(lamp.top >= price.bottom || lamp.left >= price.right + 8, isTrue);
    expect(tester.takeException(), isNull);
  });
}
