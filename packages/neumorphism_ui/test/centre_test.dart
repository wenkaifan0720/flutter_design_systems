// Text sits centred in its box, on a desktop and a phone. Line boxes, measured from the layout; the glyphs themselves are
// compared with the concept's by tools/compare.py (baseline to baseline).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadNeumorphicFonts();
  });

  Future<void> pump(WidgetTester tester, double width, Widget child) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      neumorphicApp(
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
        NeumorphicButton.filled('Pay now', onPressed: () {}),
      );
      centred(tester, find.byType(NeumorphicButton), find.text('Pay now'));
    });
    testWidgets('line button @$w', (tester) async {
      await pump(
        tester,
        w,
        NeumorphicButton('Back', wide: true, onPressed: () {}),
      );
      centred(tester, find.byType(NeumorphicButton), find.text('Back'));
    });
    testWidgets('chip @$w', (tester) async {
      await pump(tester, w, const NeumorphicChip('Taxi'));
      centred(tester, find.byType(NeumorphicChip), find.text('Taxi'));
    });
    testWidgets('select field @$w', (tester) async {
      await pump(
        tester,
        w,
        const NeumorphicSelectField(value: 'Current ··3108'),
      );
      centred(
        tester,
        find.byType(NeumorphicSelectField),
        find.text('Current ··3108'),
      );
    });
    testWidgets('field, a bare editable at standard density @$w', (
      tester,
    ) async {
      await pump(tester, w, const NeumorphicTextField(initialValue: 'Pepper'));
      centred(
        tester,
        find.byType(NeumorphicTextField),
        find.byType(EditableText),
      );
      final decoration = tester
          .widget<TextField>(find.byType(TextField))
          .decoration!;
      expect(decoration.visualDensity, VisualDensity.standard);
      expect(decoration.contentPadding, EdgeInsets.zero);
    });
    testWidgets('monogram @$w', (tester) async {
      await pump(tester, w, const NeumorphicMonogram('AC'));
      centred(
        tester,
        find.byType(NeumorphicMonogram),
        find.text('AC'),
        tolerance: 1.5,
      );
    });
    testWidgets('tag @$w', (tester) async {
      await pump(tester, w, const NeumorphicTag('Fish'));
      centred(
        tester,
        find.byType(NeumorphicTag),
        find.text('Fish'),
        tolerance: 1.5,
      );
    });
  }
}
