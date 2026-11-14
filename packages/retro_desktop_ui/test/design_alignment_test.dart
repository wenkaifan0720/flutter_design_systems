import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

void main() {
  setUpAll(loadRetroDesktopFonts);
  for (final width in [390.0, 1440.0]) {
    for (final size in RetroDesktopButtonSize.values) {
      for (final dark in [false, true]) {
        testWidgets(
          'action faces and label centres align: $width $size dark=$dark',
          (tester) async {
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              retroDesktopApp(
                Center(
                  child: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      RetroDesktopButton(
                        'Save',
                        isDefaultAction: true,
                        size: size,
                        onPressed: () {},
                      ),
                      RetroDesktopButton('Back', size: size, onPressed: () {}),
                      RetroDesktopButton.text(
                        'Skip',
                        size: size,
                        onPressed: () {},
                      ),
                      RetroDesktopButton(
                        'Delete',
                        isDefaultAction: true,
                        isDestructiveAction: true,
                        size: size,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                dark: dark,
              ),
            );
            await tester.pumpAndSettle();
            final labels = ['Save', 'Back', 'Skip', 'Delete'];
            final centres = [
              for (final label in labels) tester.getCenter(find.text(label)).dy,
            ];
            for (final centre in centres) {
              expect(centre, closeTo(centres.first, .01));
            }
            final heights = [
              for (final label in labels)
                tester
                    .getSize(
                      find
                          .descendant(
                            of: find.widgetWithText(RetroDesktopButton, label),
                            // The face's outline box (its clip sits inside
                            // the rim, whose width differs by button).
                            matching: find.byWidgetPredicate(
                              (w) => w.runtimeType.toString() == '_Face',
                            ),
                          )
                          .first,
                    )
                    .height,
            ];
            for (final height in heights) {
              expect(height, closeTo(heights.first, .01));
            }
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
