import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import 'support/centred_host.dart';

void main() {
  testWidgets('on a wide window an action sheet stands centred at a sheet\'s '
      'width; on a phone it spans the screen inside its margins', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    for (final width in [1440.0, 390.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpWidget(
        centredHost(
          Builder(
            builder: (context) => MinimalButton(
              'Open',
              onPressed: () => showMinimalActionSheet(
                context,
                title: 'IMG_2041.jpg',
                actions: [MinimalActionSheetAction('Share', onPressed: () {})],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final card = tester.getRect(find.byType(MinimalActionSheet));
      if (width > 600) {
        expect(card.width, MinimalBottomSheet.centredWidth);
        expect(card.center.dx, width / 2);
      } else {
        expect(card.width, width - 2 * MinimalChromeMetrics.sheetInset);
      }
      Navigator.of(tester.element(find.text('Share'))).pop();
      await tester.pumpAndSettle();
    }
  });
}
