// A pressed tab tints its whole cell, as a pressed segment does, and its
// words keep their ink: the press never runs across them as a half fill
// from the foot would. On paper and by night, left to right and right to
// left.
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

const _shot = ValueKey('tabs');

Widget _host(TermThemeData theme, TextDirection direction) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: TermTheme(
    data: theme,
    child: Directionality(
      textDirection: direction,
      child: ColoredBox(
        color: theme.background,
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: RepaintBoundary(
              key: _shot,
              child: ColoredBox(
                color: theme.background,
                child: TermTabBar(
                  tabs: const ['steps', 'log', 'env'],
                  selectedIndex: 0,
                  onTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

Future<(ByteData, int)> _pixels(WidgetTester t) async {
  final box = t.renderObject<RenderRepaintBoundary>(find.byKey(_shot));
  return (await t.runAsync(() async {
    final image = await box.toImage();
    final bytes = await image.toByteData();
    return (bytes!, image.width);
  }))!;
}

Color _at(ByteData bytes, int width, Offset p) {
  final i = (p.dy.round() * width + p.dx.round()) * 4;
  return Color.fromARGB(
    bytes.getUint8(i + 3),
    bytes.getUint8(i),
    bytes.getUint8(i + 1),
    bytes.getUint8(i + 2),
  );
}

void main() {
  setUpAll(loadFaces);

  final themes = {'paper': TermThemeData.light, 'night': TermThemeData.dark};
  for (final MapEntry(key: name, value: themeOf) in themes.entries) {
    for (final direction in TextDirection.values) {
      testWidgets('$name ${direction.name}: a pressed tab tints its whole '
          'cell and keeps its words', (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = const Size(600, 200);
        addTearDown(t.view.reset);
        final theme = themeOf();
        await t.pumpWidget(_host(theme, direction));
        await t.pumpAndSettle();

        final words = find.text('log');
        final origin = t.getTopLeft(find.byKey(_shot));
        final line = t.getRect(words).shift(-origin);
        final cell = theme.grid.cellWidth;
        // The padding cell before the words, near the top and near the
        // foot of the line.
        final x = direction == TextDirection.ltr
            ? line.left - cell / 2
            : line.right + cell / 2;
        final top = Offset(x, line.center.dy - 9);
        final foot = Offset(x, line.center.dy + 9);

        final (rest, width) = await _pixels(t);
        final ground = _at(rest, width, top);

        // A finger's press, so the press alone shows: a pointer over the tab
        // adds its own mark (the words in the accent).
        final finger = await t.startGesture(t.getCenter(words));
        // A frame to take the press, one to start its spring, one for the
        // spring to come to rest.
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        await t.pump(const Duration(seconds: 1));

        final (held, _) = await _pixels(t);
        final atTop = _at(held, width, top);
        final atFoot = _at(held, width, foot);
        expect(atTop, isNot(ground), reason: 'the press shows at the top');
        expect(
          atFoot,
          atTop,
          reason: 'the whole cell, not a fill from the foot',
        );
        // The words keep the ink they have at rest.
        final style = t.widget<Text>(words).style;
        final ink = DefaultTextStyle.of(t.element(words)).style.merge(style);
        expect(ink.color, theme.foreground);

        await finger.up();
        await t.pumpAndSettle();
      });
    }
  }
}
