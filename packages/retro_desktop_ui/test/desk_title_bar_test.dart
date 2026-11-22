// On a desk (a pointer's reach), a window that closes stands its title bar as tall as one that does not: the close
// box's press spans the bar as it stands, so two windows side by side keep their titles, stripes and boxes level, and
// the bar holds still as a closable window opens. A finger's reach still grows the bar (reach_test).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

void main() {
  for (final width in const [1440.0, 390.0]) {
    testWidgets(
      'on a desk at $width, a closable window bar is as tall as a plain one',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        var closed = 0;
        Future<double> bar({required bool closes}) async {
          await tester.pumpWidget(
            retroDesktopApp(
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: RetroDesktopWindow(
                    title: 'Task details',
                    onClose: closes ? () => closed++ : null,
                    child: const Text('Inside'),
                  ),
                ),
              ),
              width: width,
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          return tester
              .getSize(
                find
                    .descendant(
                      of: find.byType(RetroDesktopWindow),
                      matching: find.byType(CustomMultiChildLayout),
                    )
                    .first,
              )
              .height;
        }

        final plain = await bar(closes: false);
        final closable = await bar(closes: true);
        expect(closable, plain);
        await tester.tap(find.bySemanticsLabel('Close'));
        expect(closed, 1, reason: 'the close box still closes');
      },
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    );
  }
}
