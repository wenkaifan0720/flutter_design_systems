import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import 'support/centred_host.dart';

void main() {
  testWidgets('a sheet\'s close keeps its whole tap target', (tester) async {
    await tester.pumpWidget(
      centredHost(
        Builder(
          builder: (context) => MinimalButton(
            'Open',
            onPressed: () => showMinimalBottomSheet<void>(
              context,
              title: 'New habit',
              builder: (_) => const Text('Sheet body'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final close = tester.getRect(
      find.byWidgetPredicate(
        (w) => w is MinimalIconButton && w.semanticLabel == 'Close',
      ),
    );
    await tester.tapAt(
      close.center - Offset(0, MinimalLayout.tapTargets.touch.height / 2 - 1),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sheet body'), findsNothing);
  });

  testWidgets('on a wide window a sheet stands centred at its width; on a '
      'phone it spans the screen inside its margins', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    for (final width in [1440.0, 390.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpWidget(
        centredHost(
          Builder(
            builder: (context) => MinimalButton(
              'Open',
              onPressed: () => showMinimalBottomSheet<void>(
                context,
                title: 'New habit',
                builder: (_) => const Text('Sheet body'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final card = tester.getRect(find.byType(MinimalBottomSheet));
      if (width > 600) {
        expect(card.width, MinimalBottomSheet.centredWidth);
        expect(card.center.dx, width / 2);
      } else {
        expect(card.width, width - 2 * MinimalChromeMetrics.sheetInset);
      }
      Navigator.of(tester.element(find.text('Sheet body'))).pop();
      await tester.pumpAndSettle();
    }
  });
}
