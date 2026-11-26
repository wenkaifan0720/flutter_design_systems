// A select field's words keep 8 px of well above and below their lines once those outgrow the 48 px well, as a text
// field's do (under that, centred in it, 7 or more): at twice the size the well held "Every weekday" with its descender
// 2 px off the foot. At the look's own size the field keeps its 48 px height.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

Future<(Rect, Rect)> _pump(WidgetTester tester, double scale) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    neumorphicApp(
      Padding(
        padding: const EdgeInsets.all(16),
        child: NeumorphicSelectField(value: 'Every weekday', onPressed: () {}),
      ),
      textScale: scale,
    ),
  );
  await tester.pumpAndSettle();
  final face = tester.getRect(find.byType(NeumorphicFieldBox));
  final words = tester.getRect(find.text('Every weekday'));
  return (face, words);
}

void main() {
  setUpAll(loadNeumorphicFonts);

  for (final scale in const [1.5, 2.0, 3.0]) {
    testWidgets('at text $scale the words stand clear inside the well', (
      tester,
    ) async {
      final (face, words) = await _pump(tester, scale);
      expect(words.top - face.top, greaterThanOrEqualTo(7));
      expect(face.bottom - words.bottom, greaterThanOrEqualTo(7));
    });
  }

  testWidgets("at the look's own size the field keeps its height", (
    tester,
  ) async {
    final (face, _) = await _pump(tester, 1);
    expect(face.height, 48);
  });
}
