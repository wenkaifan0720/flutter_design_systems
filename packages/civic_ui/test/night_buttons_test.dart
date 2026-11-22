// By night a solid button keeps its weight: its face is the action's (or the
// error's) hue deep enough to carry white words at 4.5:1, standing out from
// the slate page, not the pale tone those colours take for words on it.
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
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
          CivicThemeData.contrastRatio(face.fill, words),
          greaterThanOrEqualTo(4.5),
        );
        // It stands out from the night page as a face, not a pale wash.
        expect(
          CivicThemeData.contrastRatio(face.fill, t.background),
          greaterThanOrEqualTo(3),
        );
        // Its hue is the colour's own.
        final hue = HSLColor.fromColor(destructive ? t.danger : t.action).hue;
        expect(HSLColor.fromColor(face.fill).hue, closeTo(hue, 2));
      },
    );
  }
}
