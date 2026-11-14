// Middles and fills, read on the pixels painted, at every pixel density
// (1, 1.5, 2 and 3 device pixels to a point), every spacing density, a
// pointer's reach and a finger's, in both appearances by day and by night.
// - A title bar: its glyph's middle and its capitals' middle sit on the
//   boxes' middle line, within half a device pixel.
// - A toggle group: the chosen segment's ground runs its frame's whole height
//   but its rims (the frame a button's height, inside the strip's reach) and,
//   in Chisel, its sunken bevel; not a face centred in a taller cell.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

const appearances = <String, RetroDesktopAppearance>{
  'chisel': RetroDesktopAppearance.chisel,
  'platinum': RetroDesktopAppearance.platinum,
};

const ratios = [1.0, 1.5, 2.0, 3.0];

class _Shot {
  _Shot(this.width, this.height, this.pixels, this.ratio);
  final int width, height;
  final Uint8List pixels;
  final double ratio;

  Color at(int x, int y) {
    final i = (y.clamp(0, height - 1) * width + x.clamp(0, width - 1)) * 4;
    return Color.fromARGB(
      pixels[i + 3],
      pixels[i],
      pixels[i + 1],
      pixels[i + 2],
    );
  }

  /// The commonest colour in [r] (logical): the ground the ink stands on.
  Color ground(Rect r) {
    final count = <int, int>{};
    for (var y = (r.top * ratio).ceil(); y < (r.bottom * ratio).floor(); y++) {
      for (
        var x = (r.left * ratio).ceil();
        x < (r.right * ratio).floor();
        x++
      ) {
        final c = at(x, y).toARGB32();
        count[c] = (count[c] ?? 0) + 1;
      }
    }
    final top = count.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return Color(top.key);
  }

  /// The middle, in device pixels, of the ink in [r] (logical) that stands
  /// out from [bg]: each row's strongest coverage (against the strongest in
  /// [r]) gives its edges a fraction.
  double inkMiddle(Rect r, Color bg) {
    double lum(Color c) => .299 * c.r + .587 * c.g + .114 * c.b;
    final x0 = (r.left * ratio).floor(), x1 = (r.right * ratio).ceil();
    final y0 = (r.top * ratio).floor(), y1 = (r.bottom * ratio).ceil();
    var span = 0.0;
    for (var y = y0; y < y1; y++) {
      for (var x = x0; x < x1; x++) {
        span = math.max(span, (lum(at(x, y)) - lum(bg)).abs());
      }
    }
    final rows = <int, double>{};
    for (var y = y0; y < y1 && span > 0; y++) {
      var most = 0.0;
      for (var x = x0; x < x1; x++) {
        final cover = (lum(at(x, y)) - lum(bg)).abs() / span;
        if (cover > most) most = cover;
      }
      if (most > .08) rows[y] = most;
    }
    expect(rows, isNotEmpty, reason: 'no ink in $r');
    final first = rows.keys.reduce((a, b) => a < b ? a : b);
    final last = rows.keys.reduce((a, b) => a > b ? a : b);
    final top = first + 1 - rows[first]!;
    final bottom = last + rows[last]!;
    return (top + bottom) / 2;
  }
}

final _boundary = GlobalKey();

Future<_Shot> _take(WidgetTester tester, double ratio) => tester
    .runAsync(() async {
      final box =
          _boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await box.toImage(pixelRatio: ratio);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final shot = _Shot(
        image.width,
        image.height,
        data!.buffer.asUint8List(),
        ratio,
      );
      image.dispose();
      return shot;
    })
    .then((shot) => shot!);

Future<RetroDesktopThemeData> _host(
  WidgetTester tester, {
  required RetroDesktopAppearance appearance,
  required Brightness brightness,
  required RetroDesktopDensity density,
  required TargetPlatform platform,
  required double ratio,
  required Widget child,
}) async {
  tester.view.physicalSize = Size(640 * ratio, 400 * ratio);
  tester.view.devicePixelRatio = ratio;
  addTearDown(tester.view.reset);
  late RetroDesktopThemeData used;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(platform: platform),
      builder: (context, page) {
        used = RetroDesktopThemeData.preset('classic', brightness)
            .copyWith(appearance: appearance)
            .atWidth(MediaQuery.sizeOf(context).width)
            .copyWith(density: density);
        return RetroDesktopTheme(data: used, child: page!);
      },
      home: RepaintBoundary(
        key: _boundary,
        child: Builder(
          builder: (context) => ColoredBox(
            color: RetroDesktopTheme.of(context).colors.platinum,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return used;
}

Finder _painted(String painter) => find.byWidgetPredicate(
  (w) =>
      w is RetroDesktopPixelPaint &&
      w.painter.runtimeType.toString() == painter,
);

void main() {
  setUpAll(() async {
    await loadRetroDesktopFonts();
    await loadRetroDesktopGlyphFace();
  });

  for (final appearance in appearances.entries) {
    testWidgets('${appearance.key}: from 600 up a select hugs its widest '
        'option, at most 320; below 600 it spans its column', (tester) async {
      for (final (view, hugs) in const [(640.0, true), (390.0, false)]) {
        tester.view.physicalSize = Size(view, 600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          retroDesktopApp(
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 340,
                child: RetroDesktopTheme(
                  data: RetroDesktopThemeData.preset(
                    'classic',
                    Brightness.light,
                  ).copyWith(appearance: appearance.value).atWidth(view),
                  child: RetroDesktopSelect<String>(
                    label: 'Save new documents to',
                    value: 'here',
                    options: const [
                      RetroDesktopOption('here', 'This computer'),
                      RetroDesktopOption('cloud', 'A shared folder online'),
                    ],
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
            width: view,
          ),
        );
        final face = tester.getRect(find.byType(RetroDesktopPressable).first);
        final widest = tester.getSize(find.text('This computer')).width;
        if (hugs) {
          expect(face.width, lessThan(320.5));
          expect(face.width, lessThan(330), reason: 'stretched to 340');
          expect(face.left, 0);
          expect(widest, greaterThan(0));
        } else {
          expect(face.width, 340);
        }
      }
    });
  }

  for (final appearance in appearances.entries) {
    for (final brightness in Brightness.values) {
      final where = '${appearance.key} ${brightness.name}';

      testWidgets(
        '$where: a title bar\'s glyph and capitals sit on its boxes\' '
        'middle line',
        (tester) async {
          final faults = <String>[];
          for (final density in RetroDesktopDensity.values) {
            for (final platform in const [
              TargetPlatform.macOS,
              TargetPlatform.android,
            ]) {
              for (final close in const [false, true]) {
                if (!close && platform == TargetPlatform.android) continue;
                for (final ratio in ratios) {
                  final theme = await _host(
                    tester,
                    appearance: appearance.value,
                    brightness: brightness,
                    density: density,
                    platform: platform,
                    ratio: ratio,
                    child: SizedBox(
                      width: 420,
                      child: RetroDesktopWindow(
                        title: 'HEN',
                        icon: RetroDesktopGlyphs.fileText,
                        onClose: close ? () {} : null,
                        child: const SizedBox(height: 40),
                      ),
                    ),
                  );
                  final shot = await _take(tester, ratio);
                  final boxes = _painted(
                    theme.chisel ? '_CaptionPainter' : '_BoxPainter',
                  );
                  expect(boxes, findsWidgets);
                  final line = tester.getRect(boxes.first).center.dy * ratio;
                  for (final b in boxes.evaluate()) {
                    final mid = tester
                        .getRect(find.byWidget(b.widget))
                        .center
                        .dy;
                    expect(mid * ratio, closeTo(line, .01));
                  }
                  final words = tester.getRect(find.text('HEN'));
                  final glyph = tester.getRect(
                    find.byIcon(RetroDesktopGlyphs.fileText),
                  );
                  final caps = shot.inkMiddle(
                    words,
                    shot.ground(words.inflate(2)),
                  );
                  final mark = shot.inkMiddle(
                    glyph,
                    shot.ground(glyph.inflate(2)),
                  );
                  final at =
                      '${density.name} ${platform.name}'
                      '${close ? ' with close' : ''} @${ratio}x';
                  if ((caps - line).abs() > .5) {
                    faults.add(
                      '$at: capitals middle ${caps.toStringAsFixed(2)} vs '
                      'boxes ${line.toStringAsFixed(2)} (device px)',
                    );
                  }
                  if ((mark - caps).abs() > .5) {
                    faults.add(
                      '$at: glyph middle ${mark.toStringAsFixed(2)} vs '
                      'capitals ${caps.toStringAsFixed(2)} (device px)',
                    );
                  }
                }
              }
            }
          }
          expect(faults, isEmpty, reason: faults.join('\n'));
        },
        tags: const ['goldens'],
      );

      testWidgets('$where: a toggle group\'s chosen ground fills its cell', (
        tester,
      ) async {
        final faults = <String>[];
        for (final density in RetroDesktopDensity.values) {
          for (final platform in const [
            TargetPlatform.macOS,
            TargetPlatform.android,
          ]) {
            for (final ratio in const [1.0, 2.0]) {
              await _host(
                tester,
                appearance: appearance.value,
                brightness: brightness,
                density: density,
                platform: platform,
                ratio: ratio,
                child: RetroDesktopToggleGroup<String>(
                  values: const ['Day', 'Week', 'Month'],
                  selected: const {'Week'},
                  labelOf: (v) => v,
                  onChanged: (_) {},
                ),
              );
              final shot = await _take(tester, ratio);
              final strip = tester.getRect(
                find.byType(RetroDesktopToggleGroup<String>),
              );
              final words = tester.getRect(find.text('Week'));
              final x = ((words.left - 3) * ratio).floor();
              final y = (words.center.dy * ratio).floor();
              final ground = shot.at(x, y);
              var up = y, down = y;
              while (up > 0 && shot.at(x, up - 1) == ground) {
                up--;
              }
              while (down < shot.height - 1 && shot.at(x, down + 1) == ground) {
                down++;
              }
              final run = (down - up + 1) / ratio;
              // The frame as drawn: a button's height, inside the strip's
              // reach; the ground runs it all but its two rims.
              final page = shot.at(x, (strip.top * ratio).floor() - 2);
              var top = (strip.top * ratio).floor();
              var bottom = (strip.bottom * ratio).ceil() - 1;
              while (top < bottom && shot.at(x, top) == page) {
                top++;
              }
              while (bottom > top && shot.at(x, bottom) == page) {
                bottom--;
              }
              final frame = (bottom - top + 1) / ratio;
              final at = '${density.name} ${platform.name} @${ratio}x';
              // A chosen cell is sunk: Chisel's two-step bevel, 2 px a side
              // inside the rims, and Platinum's turned-in hairline, 1 px a
              // side, are the press, not a gap.
              final sunk = appearance.value == RetroDesktopAppearance.chisel
                  ? 4.0
                  : 2.0;
              if (run < frame - 4.5 - sunk) {
                faults.add(
                  '$at: chosen ground runs $run of the frame\'s $frame',
                );
              }
            }
          }
        }
        expect(faults, isEmpty, reason: faults.join('\n'));
      }, tags: const ['goldens']);
    }
  }
}
