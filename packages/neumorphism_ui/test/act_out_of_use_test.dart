// The act out of use lays its pigment down (law 3: the pigment is for what is live): a filled key or cap with no
// onPressed stands as a plain one out of use, no saturated colour on its face, by day and by night. It keeps the act's
// size, its glyph and its words where they stood live, so a key going out of use never shifts its row.
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

/// How many pixels of [part]'s box carry colour: saturated past what the wall's greys and their light and shade
/// reach.
Future<int> _coloured(WidgetTester tester, GlobalKey key, Finder part) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final image = (await tester.runAsync(() => boundary.toImage()))!;
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final width = image.width;
  image.dispose();
  final box = tester.getRect(part);
  var n = 0;
  for (var y = box.top.ceil(); y < box.bottom.floor(); y++) {
    for (var x = box.left.ceil(); x < box.right.floor(); x++) {
      final i = (y * width + x) * 4;
      final colour = HSLColor.fromColor(
        Color.fromARGB(
          255,
          bytes.getUint8(i),
          bytes.getUint8(i + 1),
          bytes.getUint8(i + 2),
        ),
      );
      if (colour.saturation > .35 && colour.lightness > .08) n++;
    }
  }
  return n;
}

/// Lays out [build] live and out of use, one above the other, and expects the one out of use the live one's size,
/// with its face, its glyph and its words at the same rects from its corner. The face is the innermost shape (a
/// pressable's outer one is its focus ring's).
Future<void> _sameLayout(
  WidgetTester tester,
  Widget Function(VoidCallback? onPressed) build, {
  double textScale = 1,
  double width = 800,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 600);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    neumorphicApp(
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KeyedSubtree(key: const ValueKey('live'), child: build(() {})),
          KeyedSubtree(key: const ValueKey('off'), child: build(null)),
        ],
      ),
      width: width,
      textScale: textScale,
    ),
  );
  await tester.pumpAndSettle();
  ({Size size, Rect? face, Rect? glyph, Rect? words}) measure(String which) {
    final key = find.byKey(ValueKey(which));
    final corner = tester.getTopLeft(key);
    Rect? at(Finder part) {
      final found = find.descendant(of: key, matching: part);
      return found.evaluate().isEmpty
          ? null
          : tester.getRect(found.last).shift(-corner);
    }

    return (
      size: tester.getSize(key),
      face: at(find.byType(AnimatedNeumorphicShape)),
      glyph: at(find.byType(Icon)),
      words: at(find.byType(Text)),
    );
  }

  final live = measure('live'), off = measure('off');
  expect(off.size, within(distance: .01, from: live.size), reason: 'its size');
  for (final (part, a, b) in [
    ('face', live.face, off.face),
    ('glyph', live.glyph, off.glyph),
    ('words', live.words, off.words),
  ]) {
    expect(b == null, a == null, reason: 'its $part is drawn as live');
    if (a != null) {
      expect(b, within(distance: .01, from: a), reason: 'its $part');
    }
  }
}

void main() {
  for (final dark in [false, true]) {
    final mode = dark ? 'night' : 'day';
    for (final (name, live, off) in [
      (
        'filled key',
        NeumorphicButton.filled('Start a timer', onPressed: () {}),
        const NeumorphicButton.filled('Start a timer', onPressed: null),
      ),
      (
        'filled cap',
        NeumorphicRoundButton.filled(
          NeumorphicGlyphs.play,
          semanticLabel: 'Start',
          onPressed: () {},
        ),
        const NeumorphicRoundButton.filled(
          NeumorphicGlyphs.play,
          semanticLabel: 'Start',
          onPressed: null,
        ),
      ),
    ]) {
      testWidgets('a $name out of use carries no pigment, by $mode', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(400, 200);
        addTearDown(tester.view.reset);
        final key = GlobalKey();
        Future<int> paint(Widget button) async {
          await tester.pumpWidget(
            neumorphicApp(
              RepaintBoundary(
                key: key,
                child: Builder(
                  builder: (context) => ColoredBox(
                    color: NeumorphicTheme.of(context).colors.ground,
                    child: Center(
                      child: KeyedSubtree(
                        key: const ValueKey('act'),
                        child: button,
                      ),
                    ),
                  ),
                ),
              ),
              dark: dark,
              width: 400,
            ),
          );
          await tester.pumpAndSettle();
          return _coloured(tester, key, find.byKey(const ValueKey('act')));
        }

        expect(
          await paint(live),
          greaterThan(100),
          reason: 'live, it is pigment',
        );
        expect(
          await paint(off),
          0,
          reason: 'out of use, it takes the colour of the wall',
        );
      });
    }
  }

  group('out of use, the act keeps its size', () {
    setUpAll(loadNeumorphicFonts);
    for (final size in NeumorphicButtonSize.values) {
      for (final icon in [null, NeumorphicGlyphs.play]) {
        for (final textScale in [1.0, 2.0]) {
          testWidgets(
            'a ${size.name} filled key${icon == null ? '' : ' with a glyph'} '
            'at text x$textScale',
            (tester) => _sameLayout(
              tester,
              (onPressed) => NeumorphicButton.filled(
                'Start a timer',
                icon: icon,
                size: size,
                onPressed: onPressed,
              ),
              textScale: textScale,
            ),
          );
        }
      }
    }
    testWidgets(
      'a filled key with a glyph whose words wrap',
      (tester) => _sameLayout(
        tester,
        (onPressed) => NeumorphicButton.filled(
          'Start a timer for the second rise',
          icon: NeumorphicGlyphs.play,
          size: NeumorphicButtonSize.small,
          onPressed: onPressed,
        ),
        textScale: 2,
        width: 320,
      ),
    );
    for (final size in [36.0, 48.0, 56.0]) {
      testWidgets(
        'a filled cap ${size.round()} across',
        (tester) => _sameLayout(
          tester,
          (onPressed) => NeumorphicRoundButton.filled(
            NeumorphicGlyphs.play,
            semanticLabel: 'Start',
            size: size,
            onPressed: onPressed,
          ),
        ),
      );
    }
  });
}
