// By night a solid button keeps its weight: its face is the action's (or the
// error's) hue at full strength, deep enough to carry white words at 4.5:1,
// standing out from the slate page, not the pale tone those colours take for
// words on it. Civic's own faces stay as 0.6.1 painted them (#1677D8 and
// #E62713), within a hair: walking the tone in Material's colour space with
// the pale colour's own chroma once greyed them (#3D7BB1, #AC625A).
// ignore_for_file: avoid_relative_lib_imports
import 'dart:math' as math;

import 'package:civic_ui/civic_ui.dart';
import 'package:civic_ui/src/civic/internal/button_face.dart';
import 'package:civic_ui/src/civic/internal/paint.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/kit.dart';

void main() {
  for (final destructive in const [false, true]) {
    testWidgets(
      'a ${destructive ? 'destructive' : 'primary'} button by night is deep, its words white',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          kitApp(
            brightness: Brightness.dark,
            home: Center(
              child: CivicButton(
                isDestructiveAction: destructive,
                onPressed: () {},
                child: const Text('Stop'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final t = CivicTheme.of(tester.element(find.byType(CivicButton)));
        final face = tester
            .widgetList<CustomPaint>(
              find.descendant(
                of: find.byType(CivicButton),
                matching: find.byType(CustomPaint),
              ),
            )
            .map((p) => p.painter)
            .whereType<CivicFacePainter>()
            .single;
        final words = DefaultTextStyle.of(tester.element(find.text('Stop')))
            .style
            .color!;
        expect(words, const Color(0xFFFFFFFF));
        expect(
          RawPalette.contrastRatio(face.fill, words),
          greaterThanOrEqualTo(4.5),
        );
        // It stands out from the night page as a face, not a pale wash.
        expect(
          RawPalette.contrastRatio(face.fill, t.background),
          greaterThanOrEqualTo(3),
        );
        // Its hue is the colour's own (within 3 of HSL's degrees: the
        // strong hue is set at its tone in Material's colour space).
        final hue = HSLColor.fromColor(destructive ? t.danger : t.action).hue;
        expect(HSLColor.fromColor(face.fill).hue, closeTo(hue, 3));
      },
    );
  }

  test("Civic's own night faces stay 0.6.1's, at full strength", () {
    final t = CivicThemeData.dark();
    for (final (colour, was) in [
      (t.action, const Color(0xFF1677D8)),
      (t.danger, const Color(0xFFE62713)),
    ]) {
      final (face, words, _) = civicNightFace(colour);
      final a = RawHct.fromColor(face), b = RawHct.fromColor(was);
      final gap = (a.hue - b.hue).abs() % 360;
      expect(math.min(gap, 360 - gap), lessThan(4), reason: '$was');
      expect((a.chroma - b.chroma).abs(), lessThan(5), reason: '$was');
      expect((a.tone - b.tone).abs(), lessThan(1.5), reason: '$was');
      expect(RawPalette.contrastRatio(words, face), greaterThanOrEqualTo(4.5));
    }
  });
}
