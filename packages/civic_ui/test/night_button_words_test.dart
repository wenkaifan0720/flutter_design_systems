// By night a solid button's white words read at 5:1 or more on its face,
// in every palette, a primary's and a destructive one's: 4.5:1 is the
// floor for large bold words, and a face tuned to the floor itself left no
// margin (about 4.5:1 measured).
import 'package:civic_ui/civic_parts.dart'
    show civicNightFace, CivicFacePainter;
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
}

void main() {
  for (final palette in CivicThemeData.palettes) {
    test('by night in ${palette.label} white words read at 5:1 on a solid '
        'face', () {
      final t = CivicThemeData.dark(palette: palette);
      for (final (name, colour) in [
        ('primary', t.action),
        ('destructive', t.danger),
      ]) {
        final (face, words, _) = civicNightFace(colour);
        expect(words, const Color(0xFFFFFFFF));
        expect(
          _contrast(words, face),
          greaterThanOrEqualTo(5),
          reason: '$name: ${_contrast(words, face).toStringAsFixed(2)}:1',
        );
      }
    });
  }

  testWidgets('a primary button by night paints that face under white words', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            CivicHost(brightness: Brightness.dark, child: child!),
        home: Center(
          child: CivicButton(
            onPressed: () {},
            expand: false,
            child: const Text('Continue'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final painter = tester
        .widgetList<CustomPaint>(
          find.descendant(
            of: find.byType(CivicButton),
            matching: find.byType(CustomPaint),
          ),
        )
        .map((p) => p.painter)
        .whereType<CivicFacePainter>()
        .first;
    final words = DefaultTextStyle.of(tester.element(find.text('Continue')))
        .style
        .color!;
    expect(_contrast(words, painter.fill), greaterThanOrEqualTo(5));
  });
}
