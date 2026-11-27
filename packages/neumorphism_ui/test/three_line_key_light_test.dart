// A three-line row stands its key at the top, beside the title's first line.
// The key's light, thrown up from its raised face, stays under the row's
// divider: the divider is drawn above the key as it is away from it, by day
// and by night.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

final _shot = GlobalKey();

void main() {
  setUpAll(neumorphicLoadFonts);

  for (final brightness in Brightness.values) {
    testWidgets('by ${brightness.name}, the divider above the key is whole', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 400);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        RepaintBoundary(
          key: _shot,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, child) =>
                NeumorphicHost(brightness: brightness, child: child!),
            home: Material(
              type: MaterialType.transparency,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                  child: NeumorphicListTile(
                    title: 'Proof the studio map',
                    subtitle: 'Open studio · Nov 20',
                    note: 'Due Friday · Ana Souza',
                    onPressed: () {},
                    action: NeumorphicRoundButton(
                      NeumorphicGlyphs.ellipsis,
                      size: 40,
                      semanticLabel: 'Task actions',
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final row = tester.getRect(find.byType(NeumorphicListTile));
      final key = tester.getRect(find.byType(NeumorphicRoundButton));
      final boundary =
          _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final (bytes, width) = (await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData();
        final width = image.width;
        image.dispose();
        return (data!, width);
      }))!;
      int channel(int x, int y, int c) =>
          bytes.getUint8((y * width + x) * 4 + c);
      // The divider's two lines (its groove and its catch-light), over the
      // key's middle and over the words, far from it.
      final over = key.center.dx.round();
      const away = 60;
      for (var y = row.top.round(); y < row.top.round() + 2; y++) {
        for (var c = 0; c < 3; c++) {
          expect(
            (channel(over, y, c) - channel(away, y, c)).abs(),
            lessThanOrEqualTo(1),
            reason: 'y $y',
          );
        }
      }
    });
  }
}
