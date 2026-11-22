// A window's shadow is its own outline, hard, right and down, active or not, in Platinum by day and by night; Chisel's
// window stands on its bevel and casts none.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'still_pixels.dart';
import 'support.dart';

const appearances = <String, RetroDesktopAppearance>{
  'chisel': RetroDesktopAppearance.chisel,
  'platinum': RetroDesktopAppearance.platinum,
};

void main() {
  setUpAll(loadRetroDesktopFonts);

  for (final f in appearances.entries) {
    for (final b in Brightness.values) {
      final name = '${f.key} ${b.name}';

      testWidgets(
        '$name: a window casts its own outline, hard, right and down',
        (tester) async {
          for (final active in [true, false]) {
            await stillPixels(
              tester,
              f.value,
              b,
              SizedBox(
                width: 300,
                height: 160,
                child: RetroDesktopWindowScope(
                  active: active,
                  compact: false,
                  child: const RetroDesktopWindow(
                    title: 'Profile',
                    child: Text('Your details'),
                  ),
                ),
              ),
            );
            final shadows = [
              for (final box in tester.widgetList<DecoratedBox>(
                find.descendant(
                  of: find.byType(RetroDesktopWindow),
                  matching: find.byType(DecoratedBox),
                ),
              ))
                if (box.decoration case ShapeDecoration(:final shadows?))
                  ...shadows,
            ];
            if (f.value == RetroDesktopAppearance.chisel) {
              expect(shadows, isEmpty, reason: 'Chisel stands on its bevel');
              continue;
            }
            expect(shadows, isNotEmpty);
            for (final s in shadows) {
              expect(s.blurRadius, 0, reason: 'active: $active');
              expect(s.spreadRadius, 0, reason: 'active: $active');
              expect(s.offset.dx, greaterThan(0));
              expect(s.offset.dy, s.offset.dx);
            }
          }
        },
        tags: const ['goldens'],
      );
    }
  }
}
