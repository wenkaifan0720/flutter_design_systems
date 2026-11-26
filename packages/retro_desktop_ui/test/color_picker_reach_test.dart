// A colour picker's hue and alpha strips reach as every control does: on a phone ui_core's touch floor high, on a
// desk the desk's 40. Each strip draws 14 high in the middle of its reach either way.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

// The rects of the strips' gesture detectors (the shade field's is the tall one).
Future<List<Rect>> _strips(WidgetTester tester, double width) async {
  final controller = RawColorController(const Color(0xFF3366FF));
  addTearDown(controller.dispose);
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    retroDesktopApp(
      Padding(
        padding: const EdgeInsets.all(20),
        child: RetroDesktopColorPicker(controller: controller, showAlpha: true),
      ),
      width: width,
    ),
  );
  await tester.pump();
  final detectors = find.descendant(
    of: find.byType(RetroDesktopColorPicker),
    matching: find.byType(GestureDetector),
  );
  return [
    for (final element in detectors.evaluate())
      if (element.renderObject case final RenderBox box)
        if (box.size.height < 100) box.localToGlobal(Offset.zero) & box.size,
  ];
}

void main() {
  setUpAll(loadRetroDesktopFonts);

  testWidgets(
    "on a phone each strip reaches the finger's floor high",
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
    (tester) async {
      final strips = await _strips(tester, 390);
      expect(strips, hasLength(2), reason: 'the hue strip and the alpha strip');
      for (final strip in strips) {
        expect(
          strip.height,
          greaterThanOrEqualTo(RawTapTargets.fallback.touch.height),
          reason: '$strip',
        );
      }
    },
  );

  testWidgets(
    "on a desk each strip keeps the desk's 40",
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    (tester) async {
      final strips = await _strips(tester, 1024);
      expect(strips, hasLength(2), reason: 'the hue strip and the alpha strip');
      for (final strip in strips) {
        expect(strip.height, 40, reason: '$strip');
      }
    },
  );
}
