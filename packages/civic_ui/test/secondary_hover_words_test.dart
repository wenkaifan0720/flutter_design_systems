// A secondary button under a pointer keeps its words at 4.5:1 or more, by
// day and by night, in every palette, plain and destructive: its face steps
// toward its edge only as far as the words keep that. By night a destructive
// secondary's face lifted to #5E4343 and its #FF9A8F words fell to 4.35:1.
// ignore_for_file: implementation_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:civic_ui/src/civic/internal/paint.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(Color, Color)> _face(WidgetTester tester) async {
  final painter = tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byType(CivicButton),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((p) => p.painter)
      .whereType<CivicFacePainter>()
      .single;
  final words = DefaultTextStyle.of(tester.element(find.text('Remove')))
      .style
      .color!;
  return (painter.fill, words);
}

void main() {
  for (final palette in CivicThemeData.palettes) {
    for (final brightness in Brightness.values) {
      for (final destructive in [false, true]) {
        testWidgets('${palette.label} ${brightness.name}: a '
            '${destructive ? 'destructive ' : ''}secondary button under a '
            'pointer keeps its words at 4.5:1', (tester) async {
          final theme = brightness == Brightness.dark
              ? CivicThemeData.dark(palette: palette)
              : CivicThemeData.light(palette: palette);
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, app) => CivicTheme(data: theme, child: app!),
              home: Center(
                child: CivicButton.secondary(
                  isDestructiveAction: destructive,
                  onPressed: () {},
                  child: const Text('Remove'),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final (rest, _) = await _face(tester);
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: Offset.zero);
          addTearDown(mouse.removePointer);
          await mouse.moveTo(tester.getCenter(find.byType(CivicButton)));
          await tester.pumpAndSettle();
          final (hover, words) = await _face(tester);
          expect(hover, isNot(rest), reason: 'a pointer over it shows');
          expect(
            RawPalette.contrastRatio(hover, words),
            greaterThanOrEqualTo(4.5),
            reason: '$words on $hover',
          );
        });
      }
    }
  }
}
