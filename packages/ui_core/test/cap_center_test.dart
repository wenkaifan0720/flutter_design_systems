import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart'
    show
        DefaultMaterialLocalizations,
        InputBorder,
        InputDecoration,
        Material,
        TextField;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';
import 'package:ui_core/ui_core.dart';

// Roboto, from the SDK: its OS/2 cap height is 1456 of 2048 units.
const _roboto = 1456 / 2048;
const _black = Color(0xFF000000);
const _white = Color(0xFFFFFFFF);
// Material's chevron_right: its ink is the middle half of its em, centred.
const _chevron = IconData(0xE15F, fontFamily: 'MaterialIcons');
const _pad = 8.0;

String get _fonts {
  final root =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable)
          .parent
          .parent
          .parent
          .parent
          .parent
          .parent
          .path;
  return '$root/bin/cache/artifacts/material_fonts';
}

Future<ByteData> _load(String family, String file) async {
  final data = ByteData.sublistView(File('$_fonts/$file').readAsBytesSync());
  await (FontLoader(family)..addFont(Future.value(data))).load();
  return data;
}

// The OS/2 cap height over the units per em, read from a font's tables.
double _capFactor(ByteData d) {
  final tables = <String, int>{};
  for (var i = 0; i < d.getUint16(4); i++) {
    final at = 12 + 16 * i;
    final tag = String.fromCharCodes([
      for (var k = 0; k < 4; k++) d.getUint8(at + k),
    ]);
    tables[tag] = d.getUint32(at + 8);
  }
  return d.getInt16(tables['OS/2']! + 88) / d.getUint16(tables['head']! + 18);
}

TextStyle _style(double size, double line) => TextStyle(
  inherit: false,
  fontFamily: 'Roboto',
  fontSize: size,
  height: line / size,
  leadingDistribution: TextLeadingDistribution.even,
  color: _black,
);

// A face [height] high on a white ground, [content] centred on it, the face
// moved down [offset] and scaled by [scale]; drawn at [ratio]. The rows'
// darkness (0 to 1) per column range, and the face's middle, in the
// image's pixels.
class _Drawn {
  _Drawn(this.bytes, this.width, this.height, this.middle);

  // Rows past the face's bottom are left out: the image's last row may be
  // only partly covered, and so transparent.

  final ByteData bytes;
  final int width;
  final int height;
  final double middle;

  // Where the face ends, in the image's pixels.
  late final int faceEnd;

  // How dark row [y] is at its darkest between [x0] and [x1].
  double _row(int y, int x0, int x1) {
    var most = 0.0;
    for (var x = x0; x < x1; x++) {
      final dark = 1 - bytes.getUint8((y * width + x) * 4) / 255;
      if (dark > most) most = dark;
    }
    return most;
  }

  // The ink between [x0] and [x1]: its bottom to a fraction of a pixel,
  // how many rows' worth of ink it holds, and its centre of mass.
  ({double bottom, double sum, double centre}) ink(int x0, int x1) {
    final raw = [for (var y = 0; y < faceEnd; y++) _row(y, x0, x1)];
    // As dark as the ink gets: a stem thinner than a pixel never reaches 1.
    final ink = raw.reduce(math.max);
    final rows = [for (final r in raw) r / ink];
    var last = -1;
    var sum = 0.0, moment = 0.0;
    for (var y = 0; y < faceEnd; y++) {
      if (rows[y] > 0.02) {
        last = y;
        sum += rows[y];
        moment += rows[y] * (y + 0.5);
      }
    }
    expect(last, isNonNegative, reason: 'nothing drawn');
    // The bottom row against the row above: a thin stem is drawn lighter
    // than a crossbar.
    final double bottom = last + math.min(1.0, rows[last] / rows[last - 1]);
    return (bottom: bottom, sum: sum, centre: moment / sum);
  }

  // Where an "H" between [x0] and [x1], [capitals] image pixels high by its
  // font, has its capitals' middle as the widget places it, against the
  // face's. Its bottom is its baseline, on a whole pixel, so it reads
  // exactly; the height is the font's. Its top edge reads up to a pixel
  // heavy where the engine shades it (Core Text), and on a whole pixel up
  // to 1.2 from the font's where it hints (FreeType on Linux), so the ink's
  // height is held to the font's within 1.5; under 20 pixels high its
  // stems are thinner than a pixel and read light.
  double capitals(int x0, int x1, double capitals) {
    final h = ink(x0, x1);
    if (capitals >= 20) {
      expect(h.sum, closeTo(capitals, 1.5), reason: 'as high as its font says');
    }
    return h.bottom - capitals / 2 - middle;
  }
}

Future<_Drawn> _draw(
  WidgetTester tester, {
  required Widget content,
  required double height,
  double width = 160,
  double ratio = 1,
  double offset = 0,
  double scale = 1,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: _white,
            child: SizedBox(
              // Laid out unscaled: room for the face at its own size.
              width: width * math.max(1, scale) + 2 * _pad,
              height: height * math.max(1, scale) + 2 * _pad + 2,
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: _pad, top: _pad + offset),
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: Center(child: content),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final (data, w, h) = (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: ratio);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final size = (image.width, image.height);
    image.dispose();
    return (data!, size.$1, size.$2);
  }))!;
  return _Drawn(data, w, h, (_pad + offset + scale * height / 2) * ratio)
    ..faceEnd = ((_pad + offset + scale * height) * ratio).floor();
}

// The columns [finder]'s box covers in an image drawn at [ratio].
(int, int) _columns(WidgetTester tester, Finder finder, double ratio) {
  final box = tester.renderObject<RenderBox>(finder);
  final rect = MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  );
  return ((rect.left * ratio).ceil(), (rect.right * ratio).floor());
}

// The table's faces in Roboto: font size, line height, face height.
const _faces = [
  (14.0, 20.0, 40.0),
  (16.0, 24.0, 56.0),
  (24.0, 32.0, 96.0),
  (32.0, 40.0, 136.0),
];

Widget _label(
  String words,
  TextStyle style, {
  double textScale = 1,
  bool centred = true,
}) {
  final text = Text(
    words,
    style: style,
    textScaler: TextScaler.linear(textScale),
  );
  return centred
      ? DesignCapCenter(capHeightFactor: _roboto, child: text)
      : text;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final roboto = await _load('Roboto', 'Roboto-Regular.ttf');
    expect(_capFactor(roboto), _roboto);
    await _load('MaterialIcons', 'MaterialIcons-Regular.otf');
  });

  testWidgets('the capitals are drawn within half a device pixel of the '
      'middle at 1x, 2x and 3x and text scale 1 and 1.3; centred by its line '
      'box, a label is not', (tester) async {
    var worst = 0.0;
    var before = 0.0;
    for (final (size, line, face) in _faces) {
      for (final ratio in [1.0, 2.0, 3.0]) {
        for (final textScale in [1.0, 1.3]) {
          for (final centred in [true, false]) {
            final drawn = await _draw(
              tester,
              content: _label(
                'H',
                _style(size, line),
                textScale: textScale,
                centred: centred,
              ),
              height: face,
              ratio: ratio,
            );
            final (x0, x1) = _columns(tester, find.text('H'), ratio);
            final off = drawn
                .capitals(x0, x1, _roboto * size * textScale * ratio)
                .abs();
            if (centred) {
              expect(
                off,
                lessThanOrEqualTo(0.5),
                reason: '$size/$line in $face at ${ratio}x, scale $textScale',
              );
              if (off > worst) worst = off;
            } else if (off > before) {
              before = off;
            }
          }
        }
      }
    }
    expect(before, greaterThan(1), reason: 'the fixture tells them apart');
    debugPrint(
      'cap centre: worst ${worst.toStringAsFixed(2)} device px, '
      'line box ${before.toStringAsFixed(2)}',
    );
  });

  testWidgets('fractional offsets and a scale', (tester) async {
    for (final ratio in [1.0, 2.0, 3.0]) {
      for (final (offset, scale) in [
        (0.25, 1.0),
        (1 / 3, 1.0),
        (0.5, 1.0),
        (0.75, 1.0),
        (0.0, 0.8),
        (0.0, 1.25),
        (0.5, 1.5),
      ]) {
        final drawn = await _draw(
          tester,
          content: _label('H', _style(16, 24)),
          height: 56,
          ratio: ratio,
          offset: offset,
          scale: scale,
        );
        final (x0, x1) = _columns(tester, find.text('H'), ratio);
        expect(
          drawn.capitals(x0, x1, _roboto * 16 * scale * ratio).abs(),
          lessThanOrEqualTo(0.5),
          reason: 'moved $offset, scaled $scale, at ${ratio}x',
        );
      }
    }
  });

  testWidgets('a glyph leading or trailing the label, and a title bar with '
      'no face: the glyph is not moved, and its middle and the capitals\' '
      'share a line', (tester) async {
    const icon = Icon(_chevron, size: 24, color: _black);
    final layouts = <String, (Widget, double, double)>{
      'leading': (
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 8),
            _label('H', _style(14, 20)),
          ],
        ),
        40,
        14,
      ),
      'trailing': (
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _label('H', _style(16, 24)),
            const SizedBox(width: 8),
            icon,
          ],
        ),
        48,
        16,
      ),
      // A title bar: no face, its back glyph and its title centred in a
      // 56 px bar.
      'title bar': (
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 16),
            _label('H', _style(22, 28)),
          ],
        ),
        56,
        22,
      ),
    };
    for (final MapEntry(key: name, value: (content, height, size))
        in layouts.entries) {
      for (final ratio in [1.0, 2.0, 3.0]) {
        for (final offset in [0.0, 1 / 3, 0.5]) {
          final drawn = await _draw(
            tester,
            content: content,
            height: height,
            ratio: ratio,
            offset: offset,
          );
          final (lx0, lx1) = _columns(tester, find.text('H'), ratio);
          final (ix0, ix1) = _columns(tester, find.byType(Icon), ratio);
          final caps = drawn.capitals(lx0, lx1, _roboto * size * ratio);
          // The chevron is as high above its middle as below.
          final glyphMiddle = drawn.ink(ix0, ix1).centre - drawn.middle;
          final why = '$name at ${ratio}x, moved $offset';
          expect(caps.abs(), lessThanOrEqualTo(0.5), reason: why);
          // The glyph is the engine's own: its baseline on the nearest
          // device pixel, so half a pixel from its box's middle at most (a
          // tie at 0.5), read from its shading to a tenth.
          expect(glyphMiddle.abs(), lessThanOrEqualTo(0.6), reason: why);
          // Each goes to a whole device pixel on its own.
          expect((glyphMiddle - caps).abs(), lessThanOrEqualTo(1), reason: why);
        }
      }
    }
  });

  testWidgets('keeps its child\'s size; leaves a wrapping label, an icon '
      'alone and an empty box where they are laid out', (tester) async {
    Future<double> shift(Widget child) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: DesignCapCenter(capHeightFactor: _roboto, child: child),
          ),
        ),
      );
      final outer = tester.renderObject<RenderBox>(
        find.byType(DesignCapCenter),
      );
      final inner = tester.renderObject<RenderBox>(
        find.descendant(
          of: find.byType(DesignCapCenter),
          matching: find.byWidget(child),
        ),
      );
      expect(outer.size, inner.size);
      return inner.localToGlobal(Offset.zero).dy -
          outer.localToGlobal(Offset.zero).dy;
    }

    expect(await shift(Text('H', style: _style(16, 24))), isNot(0));
    expect(
      await shift(
        SizedBox(
          width: 60,
          child: Text('Two words that wrap', style: _style(16, 24)),
        ),
      ),
      0,
    );
    expect(await shift(const Icon(_chevron, size: 24)), 0);
    expect(await shift(const SizedBox(width: 20, height: 20)), 0);
  });

  testWidgets('a new capHeightFactor moves the label', (tester) async {
    Future<double> top(double factor) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: DesignCapCenter(
              capHeightFactor: factor,
              child: Text('H', style: _style(16, 24)),
            ),
          ),
        ),
      );
      return tester.getTopLeft(find.text('H')).dy;
    }

    final roboto = await top(_roboto);
    // Shorter capitals: their middle is lower, so the label goes up.
    expect(await top(0.5), closeTo(roboto - (_roboto - 0.5) * 16 / 2, 1e-9));
  });

  testWidgets('a tap lands where the label is drawn', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: DesignCapCenter(
            capHeightFactor: _roboto,
            child: GestureDetector(
              onTap: () => taps++,
              child: Text('Hello', style: _style(16, 24)),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Hello'));
    expect(taps, 1);
  });

  testWidgets('DesignLabelCheck(drawnTolerance:) holds the capitals and a '
      'glyph beside them', (tester) async {
    Widget control(String name, Widget content, {double height = 56}) =>
        Semantics(
          button: true,
          label: name,
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xFFDDDDDD)),
            child: SizedBox(
              width: 160,
              height: height,
              child: Center(child: content),
            ),
          ),
        );
    Future<List<String>> problems(List<Widget> screen) async {
      await tester.pumpWidget(
        RepaintBoundary(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ColoredBox(
              color: _white,
              child: Align(
                alignment: Alignment.topLeft,
                child: Wrap(spacing: 8, runSpacing: 8, children: screen),
              ),
            ),
          ),
        ),
      );
      final report = await const DesignLabelCheck(
        look: 'Bare',
        drawnTolerance: 0.5,
      ).check(tester.binding.rootElement!, runAsync: tester.runAsync);
      return report.problems;
    }

    const icon = Icon(_chevron, size: 24, color: _black);
    expect(
      await problems([
        control('Edit', _label('Edit', _style(16, 24))),
        control('Share', _label('Share', _style(16, 24))),
        control('Shipping', _label('Shipping', _style(16, 24))),
        control('more', _label('more', _style(16, 24))),
        control(
          'Next',
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [_label('Next', _style(14, 20)), icon],
          ),
          height: 40,
        ),
      ]),
      isEmpty,
    );
    // A line box centred, and an icon 0.7 px low.
    expect(
      await problems([
        control('Done', _label('Done', _style(16, 24), centred: false)),
        control(
          'Next',
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _label('Next', _style(14, 20)),
              Transform.translate(offset: const Offset(0, 0.7), child: icon),
            ],
          ),
          height: 40,
        ),
      ]),
      [
        matches(
          RegExp(
            r'^a button "Done": the capitals of "Done" are drawn '
            r'[0-9.]+ device px (above|below) the middle of its face$',
          ),
        ),
        matches(
          RegExp(
            r'^a button "Next": its icon is drawn [0-9.]+ device px '
            r'below the capitals of "Next"$',
          ),
        ),
      ],
    );
  });

  testWidgets('around a text field: its capitals on the middle, typed or '
      'hinted; the hint, the caret and taps move with the line', (
    tester,
  ) async {
    const style = TextStyle(fontFamily: 'Roboto', fontSize: 14, color: _black);
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    const height = 48.0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Localizations(
            locale: const Locale('en'),
            delegates: const [
              DefaultWidgetsLocalizations.delegate,
              DefaultMaterialLocalizations.delegate,
            ],
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (_) => Material(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: 200,
                        height: height,
                        child: DesignCapCenter(
                          capHeightFactor: _roboto,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextField(
                              controller: controller,
                              style: style,
                              decoration: const InputDecoration(
                                isCollapsed: true,
                                isDense: false,
                                contentPadding: EdgeInsets.zero,
                                hintText: 'HINT',
                                hintStyle: style,
                                border: InputBorder.none,
                                constraints: BoxConstraints(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final editable = tester.allRenderObjects.whereType<RenderEditable>().single;
    const alphabetic = TextBaseline.alphabetic;
    // The capitals' middle as the engine draws them: the baseline on a
    // whole logical pixel below the line's top, the cap height above it.
    double capsMiddle(RenderBox line) {
      final b = line.getDryBaseline(line.constraints, alphabetic)!;
      final drawn = (b + 0.5).floorToDouble();
      return line.localToGlobal(Offset(0, drawn - _roboto * 14 / 2)).dy;
    }

    // Empty: the hint's capitals on the middle, on the line's baseline.
    final hint = tester.renderObject<RenderParagraph>(find.text('HINT'));
    expect(capsMiddle(hint), moreOrLessEquals(height / 2, epsilon: 0.01));
    double baseline(RenderBox line) => line
        .localToGlobal(
          Offset(0, line.getDryBaseline(line.constraints, alphabetic)!),
        )
        .dy;
    expect(baseline(hint), moreOrLessEquals(baseline(editable), epsilon: 0.01));
    // The line is drawn moved from where it is laid out.
    final laidTop = editable.localToGlobal(Offset.zero).dy;
    final shift = laidTop - (height - editable.size.height) / 2;
    expect(shift.abs(), greaterThan(0.05));

    // Typed: the same capitals on the middle.
    controller.text = 'TEXT';
    await tester.pump();
    expect(capsMiddle(editable), moreOrLessEquals(height / 2, epsilon: 0.01));

    // A tap on the third letter, where it is drawn, puts the caret there,
    // and the caret is drawn moved with the line.
    final third = editable
        .getBoxesForSelection(
          const TextSelection(baseOffset: 2, extentOffset: 3),
        )
        .single;
    await tester.tapAt(
      editable.localToGlobal(Offset(third.left + 1, third.toRect().center.dy)),
    );
    await tester.pump();
    expect(controller.selection, const TextSelection.collapsed(offset: 2));
    final caret = editable.getLocalRectForCaret(const TextPosition(offset: 2));
    expect(
      editable.localToGlobal(caret.center).dy,
      moreOrLessEquals(
        editable.localToGlobal(Offset(0, editable.size.height / 2)).dy,
        epsilon: 1,
      ),
    );
    await tester.pumpWidget(const SizedBox());
  });
}
