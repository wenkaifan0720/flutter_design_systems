// At large text on a desktop a key grows with its words, as Material's buttons do, rather than holding them on its
// foot.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery.withClampedTextScaling(
        minScaleFactor: 2,
        maxScaleFactor: 2,
        child: ApplianceHost(
          brightness: Brightness.light,
          child: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _holdsItsWords(WidgetTester tester, String label) {
  final face = tester.getRect(
    find
        .ancestor(
          of: find.text(label),
          matching: find.byType(AnimatedApplianceSurface),
        )
        .first,
  );
  final words = tester.getRect(find.text(label));
  expect(face.height, greaterThanOrEqualTo(words.height + 8), reason: label);
  expect(words.top, greaterThan(face.top), reason: label);
  expect(words.bottom, lessThan(face.bottom), reason: label);
}

void main() {
  setUpAll(applianceLoadFonts);

  testWidgets('a key grows with its words at 2x', (tester) async {
    await _pump(
      tester,
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ApplianceButton('Keep it', onPressed: () {}),
          ApplianceButton.filled('Remove from basket', onPressed: () {}),
        ],
      ),
    );
    _holdsItsWords(tester, 'Keep it');
    _holdsItsWords(tester, 'Remove from basket');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('a strip key grows with its words at 2x', (tester) async {
    await _pump(
      tester,
      ApplianceToggleGroup<String>(
        options: const [
          ApplianceToggleOption(value: 'eco', label: 'Eco'),
          ApplianceToggleOption(value: 'quick', label: 'Quick wash'),
        ],
        selected: const {'eco'},
        onSelectionChanged: (_) {},
      ),
    );
    _holdsItsWords(tester, 'Eco');
    _holdsItsWords(tester, 'Quick wash');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
