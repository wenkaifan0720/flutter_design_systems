// By night a palette swatch reads as its colour and stands apart from the
// ground: its lit edge (its top and its leading side, where Clay's light
// falls) stands 3:1 from the ground beside it, in its own hue, where the
// deep night pastels and the clay sank into the dark ground. Its lower
// trailing edge stays in shade: no light added there, no outline round it.
// The Overview's inflated volume stands apart from its card's clay.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/steady/steady.dart';

final _stage = GlobalKey();

Future<void> _open(
  WidgetTester tester, {
  required Size size,
  required TextDirection direction,
  String? part,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _stage,
      child: SteadyApp(
        initialAppearance: SteadyAppearance.dark,
        initialDirection: direction,
        parts: [for (final p in galleryPages) (title: p.title, build: p.build)],
        initialPart: part == null
            ? null
            : galleryPages.indexWhere((p) => p.id == part),
      ),
    ),
  );
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

class _Shot {
  _Shot(this.data, this.width);

  final Uint8List data;
  final int width;

  Color at(Offset p) {
    final i = (p.dy.floor() * width + p.dx.floor()) * 4;
    return Color.fromARGB(255, data[i], data[i + 1], data[i + 2]);
  }
}

Future<_Shot> _shoot(WidgetTester tester) async {
  final boundary =
      _stage.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final data = (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }))!;
  return _Shot(data, tester.getSize(find.byKey(_stage)).width.round());
}

double _hue(Color c) => HSLColor.fromColor(c).hue;

void main() {
  setUpAll(clayLoadFonts);

  for (final width in const [390.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      testWidgets('at ${width.round()} by night, ${direction.name}: each '
          'palette swatch stands 3:1 from the ground at its edge, in its '
          'own hue', (tester) async {
        await _open(
          tester,
          size: Size(width, 2400),
          direction: direction,
          part: 'foundations',
        );
        final shot = await _shoot(tester);
        final swatches = find.ancestor(
          of: find.text('Aa'),
          matching: find.byType(ClaySurface),
        );
        final rects = {
          for (final e in swatches.evaluate())
            if ((e.renderObject! as RenderBox).size.height == 56)
              tester.getRect(find.byElementPredicate((x) => x == e)),
        };
        expect(rects, hasLength(9), reason: 'the nine swatches');
        for (final r in rects) {
          // Mid-height on each side and mid-width on top: the band just
          // inside the edge (its brightest pixel, 1 to 4 px in: a raised
          // face's inner shade darkens its very lower trailing edge) and the
          // ground beside it.
          final fill = shot.at(r.center + const Offset(0, 10));
          final rtl = direction == TextDirection.rtl;
          final startX = rtl ? r.right - 1.5 : r.left + 1;
          final inX = Offset(rtl ? -1 : 1, 0);
          final topX = rtl ? r.right - r.width / 3 : r.left + r.width / 3;
          for (final (inside, inward, outside) in [
            (
              Offset(startX, r.top + r.height / 3),
              inX,
              Offset(startX - inX.dx * 5, r.top + r.height / 3),
            ),
            (
              Offset(topX, r.top + 1),
              const Offset(0, 1),
              Offset(topX, r.top - 4),
            ),
          ]) {
            final ground = shot.at(outside);
            final edge =
                [
                  for (var i = 0; i < 4; i++)
                    shot.at(inside + inward * i.toDouble()),
                ].reduce(
                  (a, b) => clayContrast(a, ground) >= clayContrast(b, ground)
                      ? a
                      : b,
                );
            expect(
              clayContrast(edge, ground),
              greaterThanOrEqualTo(3),
              reason: 'swatch at $r: edge $edge on $ground at $inside',
            );
            final s = HSLColor.fromColor(fill).saturation;
            if (s > 0.25) {
              final d = (_hue(edge) - _hue(fill)).abs();
              expect(
                math.min(d, 360 - d),
                lessThan(12),
                reason: 'swatch at $r: rim $edge, fill $fill',
              );
            }
          }
          // Its face, a quarter in and halfway down, is its colour.
          final colours = ClayThemeData.clay(Brightness.dark).colors;
          final palette = [
            colours.clay,
            colours.accent,
            colours.danger,
            for (final t in ClayTint.values) colours.tint(t),
          ];
          final faceAt = shot.at(
            Offset(
              rtl ? r.right - r.width / 4 : r.left + r.width / 4,
              r.center.dy,
            ),
          );
          int off(Color a, Color b) => [
            ((a.r - b.r) * 255).round().abs(),
            ((a.g - b.g) * 255).round().abs(),
            ((a.b - b.b) * 255).round().abs(),
          ].reduce((x, y) => x > y ? x : y);
          expect(
            palette.map((p) => off(p, faceAt)).reduce((x, y) => x < y ? x : y),
            lessThanOrEqualTo(8),
            reason: 'swatch at $r: its face $faceAt is not its colour',
          );
          // The lower trailing edge, a quarter up its end side, the lower
          // leading side, and the bottom's leading third: no lighter than the
          // swatch's own face, but for a raised face's own soft light down
          // its leading side (the light falls from the top start).
          final endX = rtl ? r.left + 2 : r.right - 2;
          final leadX = rtl ? r.right - 3 : r.left + 3;
          final thirdX = rtl ? r.right - r.width / 3 : r.left + r.width / 3;
          for (final (where, at) in [
            ('lower trailing edge', Offset(endX, r.bottom - r.height / 4)),
            ('lower leading side', Offset(leadX, r.bottom - r.height / 4)),
            ('bottom', Offset(thirdX, r.bottom - 2)),
          ]) {
            final low = shot.at(at);
            expect(
              HSLColor.fromColor(low).lightness,
              lessThanOrEqualTo(HSLColor.fromColor(fill).lightness + 0.06),
              reason: 'swatch at $r: light at its $where, $low over $fill',
            );
          }
        }
      });
    }
  }

  for (final width in const [390.0, 1440.0]) {
    testWidgets('at ${width.round()} by night, the Overview\'s inflated '
        'volume stands apart from its card', (tester) async {
      await _open(
        tester,
        size: Size(width, 2400),
        direction: TextDirection.ltr,
      );
      final card = find.ancestor(
        of: find.text('Inflated volume'),
        matching: find.byType(ClayCard),
      );
      final specimen = find
          .descendant(of: card, matching: find.byType(ClaySurface))
          .evaluate()
          .map((e) => tester.getRect(find.byElementPredicate((x) => x == e)))
          .firstWhere((r) => r.width == 96 && r.height == 64);
      final shot = await _shoot(tester);
      final body = shot.at(specimen.center);
      final clay = shot.at(Offset(specimen.right + 40, specimen.center.dy));
      expect(
        clayContrast(body, clay),
        greaterThanOrEqualTo(1.8),
        reason: 'specimen $body on card $clay',
      );
    });
  }
}
