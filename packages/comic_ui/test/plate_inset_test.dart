import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:comic_ui/comic_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

/// Physical pixels at twice the logical resolution. Only solid pixels count,
/// so a partially covered curve contributes at most half a logical pixel.
class _Pixels {
  const _Pixels(this.bytes, this.stride);

  final Uint8List bytes;
  final int stride;

  int at(int x, int y) {
    final i = (y * stride + x) * 4;
    return bytes[i] << 16 | bytes[i + 1] << 8 | bytes[i + 2];
  }

  /// The first two transitions into [ink] along a ray into the corner.
  List<double> crossings(Offset start, Offset step, Color ink) {
    final rgb = ink.toARGB32() & 0xffffff;
    final distances = <double>[];
    var previous = false;
    for (var i = 0; i < 144; i++) {
      final x = (2 * start.dx + i * step.dx).floor();
      final y = (2 * start.dy + i * step.dy).floor();
      final current = at(x, y) == rgb;
      if (current && !previous) distances.add(i / 2);
      if (distances.length == 2) break;
      previous = current;
    }
    expect(
      distances,
      hasLength(2),
      reason: 'Painted rims from $start along $step',
    );
    return distances;
  }
}

Future<_Pixels> _read(WidgetTester t, Key key) async {
  final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(key));
  return (await t.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final pixels = _Pixels(bytes!.buffer.asUint8List(), image.width);
    image.dispose();
    return pixels;
  }))!;
}

void main() {
  setUpAll(loadComicFonts);
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'Stacked segmented choices keep a concentric corner at $width',
      (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = Size(width, 900);
        addTearDown(t.view.reset);
        final theme = ComicThemeData.offset().copyWith(
          shapes: ComicShapes.rounded(18),
        );
        const shot = ValueKey('stacked segments');
        await t.pumpWidget(
          MaterialApp(
            home: ComicTheme(
              data: theme,
              child: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: RepaintBoundary(
                    key: shot,
                    child: ColoredBox(
                      color: theme.colors.background,
                      child: SizedBox(
                        width: 120,
                        child: ComicSegmentedButton<int>(
                          label: 'View',
                          value: 1,
                          segments: const [
                            ComicButtonSegment(1, 'Day'),
                            ComicButtonSegment(2, 'Week'),
                          ],
                          onChanged: (_) {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(
          t.getCenter(find.text('Week')).dy,
          greaterThan(t.getCenter(find.text('Day')).dy + 35),
        );
        final pixels = await _read(t, shot);
        double first(Color ink, {required bool diagonal}) {
          final color = ink.toARGB32() & 0xffffff;
          for (var y = 0; y < 50; y++) {
            if (pixels.at(diagonal ? y : 80, y) == color) return y / 2;
          }
          throw TestFailure('No painted $ink on the sampled ray');
        }

        final rim = theme.colors.nightLine, face = theme.colors.caption;
        final inset =
            first(face, diagonal: false) - first(rim, diagonal: false);
        final diagonal =
            (first(face, diagonal: true) - first(rim, diagonal: true)) *
            math.sqrt2;
        expect(inset, closeTo(4.5, .5));
        expect(diagonal, closeTo(inset, math.sqrt2));
      },
      tags: 'goldens',
    );

    for (final direction in TextDirection.values) {
      for (final message in [false, true]) {
        testWidgets(
          'The ${message ? 'message action' : 'first selected tag'} follows the frame at $width ${direction.name}',
          (t) async {
            t.view.devicePixelRatio = 1;
            t.view.physicalSize = Size(width, 900);
            addTearDown(t.view.reset);
            // The corner is large enough to resolve in the sampled pixels.
            final theme = ComicThemeData.offset().copyWith(
              shapes: ComicShapes.rounded(message ? 32 : 18),
            );
            const shot = ValueKey('print');
            final rtl = direction == TextDirection.rtl;
            await t.pumpWidget(
              MaterialApp(
                home: ComicTheme(
                  data: theme,
                  child: Directionality(
                    textDirection: direction,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: RepaintBoundary(
                        key: shot,
                        child: ColoredBox(
                          color: theme.colors.background,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: SizedBox(
                              width: 300,
                              child: message
                                  ? ComicSnackBar(
                                      'Saved.',
                                      actionLabel: 'Undo',
                                      onAction: () {},
                                    )
                                  : ComicMultiSelect<String>(
                                      values: const ['Paper'],
                                      options: const ['Paper'],
                                      onChanged: (_) {},
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
            await t.pumpAndSettle();
            final pixels = await _read(t, shot);
            final rect = t
                .getRect(
                  message
                      ? find.byType(ComicSnackBar)
                      : find.byType(ComicMultiSelect<String>),
                )
                .shift(-t.getTopLeft(find.byKey(shot)));
            final text =
                t.getCenter(find.text(message ? 'UNDO' : 'Paper')) -
                t.getTopLeft(find.byKey(shot));
            // Measure the front faces. Hard offset shadows extend beyond the rims.
            final left = message ? rtl : !rtl;
            final top = !message;
            final dx = left ? 1.0 : -1.0, dy = top ? 1.0 : -1.0;
            final x = left ? rect.left : rect.right - .5;
            final y = top ? rect.top : rect.bottom - .5;
            double gap(Offset origin, Offset step) {
              // The action has an offset black shadow. Follow the solid front fills
              // to distinguish its inset corner from the shadow at its back.
              final ink = message ? theme.colors.card : theme.colors.nightLine;
              final runs = pixels.crossings(origin, step, ink);
              return (runs[1] - runs[0]) * step.distance;
            }

            final across = gap(Offset(x, text.dy), Offset(dx, 0));
            final down = gap(Offset(text.dx, y), Offset(0, dy));
            expect(
              across,
              closeTo(down, 1),
              reason: 'Even edge gaps around the plate',
            );
            final diagonal = gap(Offset(x, y), Offset(dx, dy));
            expect(
              diagonal,
              closeTo(down, math.sqrt2),
              reason: 'The corner follows the outer radius minus the inset',
            );
          },
          tags: 'goldens',
        );
      }
    }
  }
}
