// Text sits centred in its box, on a desktop and a phone. Line boxes, measured from the layout; the glyphs themselves are
// compared with the concept's by tools/compare.py (baseline to baseline).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadRetroDesktopFonts();
  });

  Future<void> pump(WidgetTester tester, double width, Widget child) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      retroDesktopApp(
        Center(
          child: SizedBox(width: width - 40, child: child),
        ),
      ),
    );
    await tester.pump();
  }

  void centred(
    WidgetTester tester,
    Finder box,
    Finder text, {
    double tolerance = 1,
  }) {
    final b = tester.getRect(box), t = tester.getRect(text);
    expect(
      (b.center.dy - t.center.dy).abs(),
      lessThanOrEqualTo(tolerance),
      reason: 'box $b, text $t',
    );
  }

  for (final w in const [390.0, 1440.0]) {
    testWidgets('act button @$w', (tester) async {
      await pump(
        tester,
        w,
        RetroDesktopButton('Pay now', isDefaultAction: true, onPressed: () {}),
      );
      centred(tester, find.byType(RetroDesktopButton), find.text('Pay now'));
    });
    testWidgets('line button @$w', (tester) async {
      await pump(tester, w, RetroDesktopButton('Back', onPressed: () {}));
      centred(tester, find.byType(RetroDesktopButton), find.text('Back'));
    });
    testWidgets('chip @$w', (tester) async {
      await pump(tester, w, const RetroDesktopChip('Taxi'));
      centred(tester, find.byType(RetroDesktopChip), find.text('Taxi'));
    });
    testWidgets('popup @$w', (tester) async {
      await pump(tester, w, const RetroDesktopPopupButton('Current'));
      centred(
        tester,
        find.byType(RetroDesktopPopupButton),
        find.text('Current'),
      );
    });
    testWidgets('text box, with InputDecoration, on standard density @$w', (
      tester,
    ) async {
      await pump(tester, w, const RetroDesktopTextField(initial: 'Pepper'));
      centred(
        tester,
        find.byType(RetroDesktopTextField),
        find.byType(EditableText),
      );
      final theme = Theme.of(tester.element(find.byType(InputDecorator)));
      expect(theme.visualDensity, VisualDensity.standard);
    });
    testWidgets('monogram @$w', (tester) async {
      await pump(tester, w, const RetroDesktopMonogram('AC'));
      centred(
        tester,
        find.byType(RetroDesktopMonogram),
        find.text('AC'),
        tolerance: 1.5,
      );
    });
    testWidgets('flag @$w', (tester) async {
      await pump(tester, w, const RetroDesktopFlag('Late'));
      centred(
        tester,
        find.byType(RetroDesktopFlag),
        find.text('Late'),
        tolerance: 1.5,
      );
    });
  }
}
