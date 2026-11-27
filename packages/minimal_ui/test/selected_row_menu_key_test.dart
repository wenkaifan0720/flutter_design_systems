// A selected row's wash runs under the menu key at its end: the key's square
// is a hairline on whatever it stands on, so it never stamps the page's ground
// over the row's selection, by day or by night.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<(ByteData, int)> _pixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('screen')),
  );
  final image = (await tester.runAsync(() => boundary.toImage()))!;
  final data = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final width = image.width;
  image.dispose();
  return (data, width);
}

Color _at(ByteData data, int width, Offset p) {
  final i = (p.dy.round() * width + p.dx.round()) * 4;
  return Color.fromARGB(
    data.getUint8(i + 3),
    data.getUint8(i),
    data.getUint8(i + 1),
    data.getUint8(i + 2),
  );
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('a selected row\'s wash runs under its menu key '
        '(${brightness.name})', (tester) async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('screen'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, navigator) => MinimalTheme(
              data: MinimalThemeData.preset('standard', brightness),
              child: navigator!,
            ),
            home: MinimalScaffold(
              padding: EdgeInsets.zero,
              body: Column(
                children: [
                  MinimalListTile(
                    title: 'Proof the studio map',
                    subtitle: 'Open studio · Nov 20',
                    selected: true,
                    onTap: () {},
                    trailing: MinimalMenu.button(
                      LucideIcons.ellipsis,
                      semanticLabel: 'Task actions',
                      items: [MinimalMenuItem('Delete', onPressed: () {})],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final key = tester.getRect(find.byType(MinimalMenu));
      // The square the key draws, inside its target: the box the glyph
      // stands in.
      final square = tester.getRect(
        find
            .ancestor(
              of: find.descendant(
                of: find.byType(MinimalMenu),
                matching: find.byType(MinimalIcon),
              ),
              matching: find.byType(Container),
            )
            .first,
      );
      final (data, width) = await _pixels(tester);
      // Just outside the key's start edge, the row's wash; inside its
      // square, above the glyph's middle row of dots and clear of the rim,
      // what the square shows.
      final wash = _at(data, width, Offset(key.left - 3, key.center.dy));
      final inside = _at(data, width, Offset(square.center.dx, square.top + 5));
      final ground = _at(
        data,
        width,
        Offset(
          key.center.dx,
          tester.getRect(find.byType(MinimalListTile)).bottom + 8,
        ),
      );
      expect(wash, isNot(ground), reason: 'the row shows its selection');
      expect(
        inside,
        wash,
        reason: 'the square shows the wash, no fill of its own',
      );
    });
  }
}
