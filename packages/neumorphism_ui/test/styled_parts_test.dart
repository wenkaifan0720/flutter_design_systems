import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/controls.dart'
    show NeumorphicTapFace;

import 'support.dart';

typedef _Part = Widget Function(NeumorphicStyle?);
typedef _Theme = NeumorphicThemeData Function(
  NeumorphicThemeData,
  NeumorphicStyle,
);

const _content = Text('Content', key: ValueKey('content'));
const _capture = ValueKey('capture');

Future<void> _mount(
  WidgetTester tester,
  Widget child,
  NeumorphicThemeData theme, {
  double width = 320,
  double scale = 1,
  bool flat = true,
}) async {
  tester.view.physicalSize = const Size(600, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(600, 800),
          textScaler: TextScaler.linear(scale),
        ),
        child: NeumorphicTheme(
          data: theme,
          child: Center(
            child: RepaintBoundary(
              key: _capture,
              child: SizedBox(
                width: width,
                child: flat ? NeumorphicFlatScope(child: child) : child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<Color> _facePixel(WidgetTester tester) async {
  final face = tester
      .renderObjectList<RenderCustomPaint>(find.byType(CustomPaint))
      .firstWhere((r) => r.painter.runtimeType.toString() == '_CastPainter');
  final capture = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_capture),
  );
  final at = capture.globalToLocal(
    face.localToGlobal(Offset(9, face.size.height / 2)),
  );
  return (await tester.runAsync(() async {
    final image = await capture.toImage();
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final index = (at.dy.floor() * image.width + at.dx.floor()) * 4;
    final color = Color.fromARGB(
      bytes.getUint8(index + 3),
      bytes.getUint8(index),
      bytes.getUint8(index + 1),
      bytes.getUint8(index + 2),
    );
    image.dispose();
    return color;
  }))!;
}

void main() {
  // Each part runs one of its 18 densities, widths and text sizes every time, in turn ([sweepInTurn]); the
  // sweep runs the rest.
  var matrixCase = 0;
  setUpAll(loadNeumorphicFonts);
  for (final kind in ['slab', 'well', 'card']) {
    testWidgets('$kind inherits content slots and keeps child overrides', (
      tester,
    ) async {
      final style = NeumorphicStyle(
        foreground: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.blue : null,
        ),
        textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 20)),
        iconSize: const WidgetStatePropertyAll(28),
      );
      const children = <Widget>[
        Text('Inherited'),
        Icon(Icons.star, key: ValueKey('inherited icon')),
        Text('Explicit', style: TextStyle(color: Colors.green, fontSize: 17)),
        Icon(
          Icons.star,
          key: ValueKey('explicit icon'),
          color: Colors.green,
          size: 19,
        ),
      ];
      final theme = NeumorphicThemeData.porcelain().copyWith(
        cardTheme: const NeumorphicStyle(
          foreground: WidgetStatePropertyAll(Colors.red),
          textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 14)),
        ),
      );
      for (final selected in [false, true]) {
        await _mount(
          tester,
          NeumorphicStatesScope(
            states: {if (selected) WidgetState.selected},
            child: switch (kind) {
              'slab' => NeumorphicSlab(
                style: style,
                child: const Column(children: children),
              ),
              'well' => NeumorphicWell(
                style: style,
                child: const Column(children: children),
              ),
              _ => NeumorphicCard(
                title: 'Heading',
                subtitle: 'Meta',
                style: style,
                children: children,
              ),
            },
          ),
          theme,
        );
        final expected = selected ? Colors.blue : Colors.red;
        TextStyle words(String text) => tester
            .renderObject<RenderParagraph>(
              find.descendant(
                of: find.text(text),
                matching: find.byType(RichText),
              ),
            )
            .text
            .style!;
        for (final text in [
          'Inherited',
          if (kind == 'card') ...['Heading', 'Meta'],
        ]) {
          expect(words(text).color, expected);
          expect(words(text).fontSize, 20);
        }
        expect(words('Explicit').color, Colors.green);
        expect(words('Explicit').fontSize, 17);
        final icon = tester.element(
          find.byKey(const ValueKey('inherited icon')),
        );
        expect(IconTheme.of(icon).color, expected);
        expect(IconTheme.of(icon).size, 28);
        final explicit = tester.widget<Icon>(
          find.byKey(const ValueKey('explicit icon')),
        );
        expect(explicit.color, Colors.green);
        expect(explicit.size, 19);
      }
    });
  }
  for (final cast in [
    NeumorphicSurfaceLevel.groove,
    NeumorphicSurfaceLevel.well,
  ]) {
    for (final border in <OutlinedBorder?>[
      null,
      const NeumorphicRoundedBorder(radius: 20),
      const NeumorphicStadiumBorder(),
    ]) {
      testWidgets('${cast.name} $border fades smoothly across the content', (
        tester,
      ) async {
        // Hold the outside fixed while moving every edge of the content. Any
        // painted seam, including one around a rounded corner, would move too.
        Future<ui.Image> paint(EdgeInsets padding, double pixelRatio) async {
          await _mount(
            tester,
            SizedBox(
              height: 80,
              child: NeumorphicSurface(
                cast: cast,
                shape: border,
                padding: padding,
                child: const SizedBox.expand(),
              ),
            ),
            NeumorphicThemeData.porcelain(),
            width: 160,
            flat: false,
          );
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(_capture),
          );
          final image = (await tester.runAsync(
            () => boundary.toImage(pixelRatio: pixelRatio),
          ))!;
          addTearDown(image.dispose);
          return image;
        }

        final narrow = await paint(const EdgeInsets.all(2), 2);
        final padded = await paint(
          const EdgeInsets.fromLTRB(22, 12, 16, 10),
          2,
        );
        Future<ByteData> rgba(ui.Image image) async => (await tester.runAsync(
          () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
        ))!;
        final first = await rgba(narrow);
        final second = await rgba(padded);
        expect(
          second.buffer.asUint8List(),
          orderedEquals(first.buffer.asUint8List()),
          reason: 'moving the content changed the DPR 2 inset',
        );

        // At this sampling density the natural blur advances by at most one
        // eight-bit shade per pixel, even on the steep flank near the rim.
        final image = await paint(const EdgeInsets.all(6), 16);
        final pixels = await rgba(image);
        for (final vertical in [false, true]) {
          final length = vertical ? image.height : image.width;
          int tone(int position, int channel) {
            final x = vertical ? image.width ~/ 2 : position;
            final y = vertical ? position : image.height ~/ 2;
            return pixels.getUint8((y * image.width + x) * 4 + channel);
          }

          for (var channel = 0; channel < 3; channel++) {
            final samples = [for (var i = 0; i < length; i++) tone(i, channel)];
            final middle = samples[length ~/ 2];
            final darkRim = samples.indexOf(samples.reduce(math.min));
            final lightRim = samples.lastIndexOf(samples.reduce(math.max));
            expect(darkRim, lessThan(length ~/ 8));
            expect(lightRim, greaterThan(length * 7 ~/ 8));
            expect(samples[darkRim], lessThan(middle));
            expect(samples[lightRim], greaterThan(middle));

            // The highlight and shadow crest just inside the outline. The
            // interior between those rims is monotone up to rounding one shade.
            var highest = samples[darkRim];
            for (var i = 1; i < length; i++) {
              final shade = samples[i];
              if ((shade - samples[i - 1]).abs() > 1) {
                fail(
                  'inset jumps from ${samples[i - 1]} to $shade at '
                  '$i/$length, vertical=$vertical, channel=$channel',
                );
              }
              if (i >= darkRim && i <= lightRim) {
                if (shade < highest - 1) {
                  fail(
                    'inset reverses from $highest to $shade at '
                    '$i/$length, vertical=$vertical, channel=$channel',
                  );
                }
                highest = math.max(highest, shade);
              }
            }
          }
        }
      });
    }
  }
  testWidgets(
    'an open split key shades its own pigment and leaves Save raised',
    (tester) async {
      const green = Color(0xff147a46);
      final theme = NeumorphicThemeData.porcelain();
      await _mount(
        tester,
        NeumorphicSplitButton(
          'Save',
          onPressed: () {},
          actions: [NeumorphicSplitAction('Save a copy', onPressed: () {})],
          style: const NeumorphicStyle(fill: WidgetStatePropertyAll(green)),
        ),
        theme,
        width: 160,
        flat: false,
      );
      final capture = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(_capture),
      );
      final faces = find.byType(NeumorphicTapFace);
      final main = tester
          .getRect(faces.first)
          .shift(-capture.localToGlobal(Offset.zero));
      final key = tester
          .getRect(faces.last)
          .shift(-capture.localToGlobal(Offset.zero));
      Future<ByteData> paint() async {
        return (await tester.runAsync(() async {
          final image = await capture.toImage(pixelRatio: 2);
          try {
            return (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
          } finally {
            image.dispose();
          }
        }))!;
      }

      final before = await paint();
      await tester.tap(find.byIcon(NeumorphicGlyphs.chevronDown));
      await tester.pumpAndSettle();
      expect(find.text('Save a copy'), findsOneWidget);
      final after = await paint();
      final stride = (capture.size.width * 2).round() * 4;
      for (var y = (main.top * 2 + 4).ceil(); y < main.bottom * 2 - 4; y++) {
        for (var x = (main.left * 2 + 4).ceil(); x < main.right * 2 - 4; x++) {
          final i = y * stride + x * 4;
          expect(
            after.getUint32(i),
            before.getUint32(i),
            reason: 'opening the menu repainted Save at ($x, $y)',
          );
        }
      }
      // The red component of the whole green flank lies between the actual
      // pigment's two tones. A second, wall-coloured inset exceeds that range.
      final (hi, lo) = neumorphicTones(green, theme.colors);
      final maxRed = (math.max(green.r, math.max(hi.r, lo.r)) * 255).ceil() + 1;
      final x = ((key.left + 10) * 2).round();
      final reds = [
        for (var y = ((key.top + 3) * 2).ceil(); y < (key.bottom - 2) * 2; y++)
          after.getUint8(y * stride + x * 4),
      ];
      expect(reds.reduce(math.max), lessThanOrEqualTo(maxRed));
      expect(reds.reduce(math.min), lessThan(reds.reduce(math.max)));
      // The chevron face covers the full 48-pixel target at rest and while
      // open, including the two ends outside its 40-pixel content box.
      for (final state in [before, after]) {
        for (final edge in [key.left + 2, key.right - 2]) {
          final i =
              (key.center.dy * 2).round() * stride + (edge * 2).round() * 4;
          expect(
            state.getUint8(i + 1),
            greaterThan(state.getUint8(i + 2)),
            reason: 'the blue body shows through the green key at $edge',
          );
        }
      }
    },
  );

  final parts = <(String, _Part, _Theme)>[
    (
      'slab',
      (s) => NeumorphicSlab(style: s, child: _content),
      (t, s) => t.copyWith(cardTheme: s),
    ),
    (
      'well',
      (s) => NeumorphicWell(style: s, child: _content),
      (t, s) => t.copyWith(cardTheme: s),
    ),
    (
      'card',
      (s) => NeumorphicCard(style: s, children: const [_content]),
      (t, s) => t.copyWith(cardTheme: s),
    ),
    (
      'dialog',
      (s) =>
          NeumorphicDialog(style: s, title: 'Title', content: const [_content]),
      (t, s) => t.copyWith(dialogTheme: s),
    ),
    (
      'sheet',
      (s) => SizedBox(
        height: 300,
        child: NeumorphicBottomSheet(
          style: s,
          showClose: false,
          child: _content,
        ),
      ),
      (t, s) => t.copyWith(sheetTheme: s),
    ),
    (
      'menu',
      (s) => NeumorphicMenu<int>(
        style: s,
        items: const [NeumorphicMenuItem(1, 'Content')],
      ),
      (t, s) => t.copyWith(menuTheme: s),
    ),
    (
      'tooltip',
      (s) => NeumorphicTooltipFace(style: s, message: 'Content'),
      (t, s) => t.copyWith(tooltipTheme: s),
    ),
    (
      'snack',
      (s) => NeumorphicSnackBar('Content', style: s),
      (t, s) => t.copyWith(snackBarTheme: s),
    ),
  ];
  for (final (name, part, setTheme) in parts) {
    testWidgets(
      '$name reads theme fill and widget override in painted pixels',
      (tester) async {
        const themed = NeumorphicStyle(
          fill: WidgetStatePropertyAll(Colors.red),
        );
        const local = NeumorphicStyle(
          fill: WidgetStatePropertyAll(Colors.blue),
        );
        final theme = setTheme(NeumorphicThemeData.porcelain(), themed);
        await _mount(tester, part(null), theme);
        expect((await _facePixel(tester)).toARGB32(), Colors.red.toARGB32());
        await _mount(tester, part(local), theme);
        expect((await _facePixel(tester)).toARGB32(), Colors.blue.toARGB32());
        await _mount(tester, part(const NeumorphicStyle()), theme);
        expect((await _facePixel(tester)).toARGB32(), Colors.red.toARGB32());
      },
      tags: ['goldens'],
    );
    for (final set in const ['look']) {
      for (final (densityName, density) in [
        ('standard', NeumorphicDensity.standard),
        ('comfortable', NeumorphicDensity.comfortable),
        ('compact', NeumorphicDensity.compact),
      ]) {
        for (final width in [120.0, 240.0, 390.0]) {
          for (final scale in [1.0, 1.3]) {
            testWidgets(
              '$name $set $densityName fits content at $width and $scale',
              (tester) async {
                final theme = NeumorphicThemeData.porcelain().copyWith(
                  density: density,
                );
                await _mount(
                  tester,
                  part(null),
                  theme,
                  width: width,
                  scale: scale,
                );
                final surface = tester
                    .widgetList<NeumorphicSurface>(
                      find.byType(NeumorphicSurface),
                    )
                    .first;
                final border =
                    surface.shape ??
                    NeumorphicRoundedBorder(
                      radius:
                          surface.radius ??
                          (surface.cast == NeumorphicSurfaceLevel.slab
                              ? NeumorphicRadii.slab
                              : surface.cast == NeumorphicSurfaceLevel.well
                              ? NeumorphicRadii.well
                              : NeumorphicRadii.control),
                    );
                final paint = tester
                    .renderObjectList<RenderCustomPaint>(
                      find.byType(CustomPaint),
                    )
                    .firstWhere(
                      (r) => r.painter.runtimeType.toString() == '_CastPainter',
                    );
                final path = border.getOuterPath(Offset.zero & paint.size);
                final content =
                    name == 'menu' || name == 'tooltip' || name == 'snack'
                    ? find.text('Content')
                    : find.byKey(const ValueKey('content'));
                final child = tester.renderObject<RenderBox>(content);
                final bounds = MatrixUtils.transformRect(
                  child.getTransformTo(paint),
                  child.paintBounds,
                ).deflate(1);
                for (final point in [
                  bounds.topLeft,
                  bounds.topCenter,
                  bounds.topRight,
                  bounds.centerRight,
                  bounds.bottomRight,
                  bounds.bottomCenter,
                  bounds.bottomLeft,
                  bounds.centerLeft,
                ]) {
                  expect(
                    path.contains(point),
                    isTrue,
                    reason: '$point outside ${paint.size}',
                  );
                }
              },
              tags: sweepInTurn(matrixCase++, 18),
            );
          }
        }
      }
    }
  }
}
