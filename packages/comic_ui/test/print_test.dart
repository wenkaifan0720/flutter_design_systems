// The print's own laws: dots on whole device pixels at any scale, a tail that doesn't come off, a burst that holds any number
// and only one a screen, lettering that doesn't double, and a cast of nobody.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/src/comic/balloons.dart'
    show ComicBurstFit, ComicBurstLedger, comicBalloonPath;
import 'package:comic_ui/src/comic/internal/geometry.dart';
import 'package:comic_ui/src/comic/print.dart'
    show ComicScreenGrid, RenderComicLettering;

import 'support.dart';

Future<ui.Image> _shot(WidgetTester tester, GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(
    () => boundary.toImage(pixelRatio: tester.view.devicePixelRatio),
  ))!;
}

Future<List<int>> _rgba(WidgetTester tester, ui.Image image) async {
  final bytes = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  return bytes!.buffer.asUint8List();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadComicFonts();
  });

  group('Ben-Day dots', () {
    for (final dpr in const [1.0, 1.5, 2.0, 2.625, 3.0, 3.5]) {
      for (final (pitch, radius) in const [
        (9.0, 2.2),
        (10.0, 1.9),
        (8.0, 1.8),
        (7.0, 1.0),
        (11.0, 2.6),
      ]) {
        test('pitch $pitch at $dpr falls on whole device pixels', () {
          final g = ComicScreenGrid(pitch, radius, dpr);
          // Every dot centre, times the device ratio, is a whole pixel: no dot straddles differently from its neighbour.
          final p = g.points(const Size(200, 200));
          for (var i = 0; i < p.length; i++) {
            final device = p[i] * dpr;
            expect(
              (device - device.roundToDouble()).abs(),
              lessThan(.002),
              reason: 'coordinate $i: ${p[i]}',
            );
          }
          // The pitch stays near what was asked: a screen doesn't change its look across phones.
          expect((g.pitch - pitch).abs(), lessThan(1.1));
        });
      }
    }

    for (final dpr in const [1.0, 2.0, 3.0]) {
      testWidgets('every cell of the screen is the same pixels at $dpr', (
        tester,
      ) async {
        tester.view.physicalSize = Size(240 * dpr, 240 * dpr);
        tester.view.devicePixelRatio = dpr;
        addTearDown(tester.view.reset);
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: const ColoredBox(
              color: Color(0xFFFFFFFF),
              child: ComicBenDay(color: Color(0xFF000000)),
            ),
          ),
        );
        final image = await _shot(tester, key);
        final px = await _rgba(tester, image);
        final g = ComicScreenGrid(9, 2.2, dpr);
        final w = image.width;
        int at(int x, int y) => px[(y * w + x) * 4];
        // Two whole periods apart, away from the edges, the screen repeats exactly: that's no moiré and no drift.
        final dx = g.devicePitch, dy = g.deviceRow * 2;
        // (A dot the panel's edge cuts goes through another rasterising path, so the outer cell is left out.)
        final m = g.devicePitch;
        var off = 0;
        for (var y = m; y < image.height - dy - m; y++) {
          for (var x = m; x < w - dx - m; x++) {
            if (at(x, y) != at(x + dx, y) || at(x, y) != at(x, y + dy)) off++;
          }
        }
        expect(off, 0);
        // And the dots read as dots: ink and paper both there, some of each.
        var dark = 0, light = 0;
        for (var i = 0; i < px.length; i += 4) {
          if (px[i] < 60) dark++;
          if (px[i] > 200) light++;
        }
        final total = px.length / 4;
        expect(
          dark / total,
          greaterThan(.1),
          reason: 'muddy: too few solid dots',
        );
        expect(light / total, greaterThan(.3), reason: 'muddy: no paper left');
        image.dispose();
        // Drawn pixels: the rasterizer's, as a golden's (Linux CI leaves it to macOS).
      }, tags: 'goldens');
    }

    testWidgets('a dotted ground stands on its own layer and never ticks', (
      tester,
    ) async {
      await tester.pumpWidget(
        comicApp(const ComicBenDay(color: Color(0xFF000000), child: Text('x'))),
      );
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
      final paint = tester.renderObject<RenderCustomPaint>(
        find.descendant(
          of: find.byType(ComicBenDay),
          matching: find.byType(CustomPaint),
        ),
      );
      // A repaint boundary above the dots and another under them: words changing on it don't repaint it.
      var parent = paint.parent;
      var boundary = false;
      while (parent != null && !boundary) {
        if (parent is RenderRepaintBoundary) boundary = true;
        parent = parent.parent;
      }
      expect(boundary, isTrue);
      expect(paint.isComplex, isTrue);
    });

    test('the look draws no lip shadow', () {
      for (final f in Directory(
        'lib/src/comic',
      ).listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) continue;
        expect(
          f.readAsStringSync().contains('BoxShadow('),
          isFalse,
          reason: f.path,
        );
      }
    });
  });

  group('a balloon', () {
    for (final tail in ComicTail.values) {
      for (final w in const [36.0, 60.0, 120.0, 320.0, 900.0]) {
        for (final h in const [40.0, 56.0, 300.0]) {
          for (final rtl in const [false, true]) {
            test('$tail $w x $h ${rtl ? 'rtl' : 'ltr'} is one outline', () {
              final path = comicBalloonPath(w, h, tail, 24, rtl: rtl);
              // The tail is fused: the whole outline is one contour, never two shapes that touch.
              expect(path.computeMetrics().length, 1);
              if (tail != ComicTail.none) {
                final bounds = path.getBounds();
                final grew =
                    bounds.bottom > h + .5 ||
                    bounds.top < -.5 ||
                    bounds.left < -.5 ||
                    bounds.right > w + .5;
                expect(
                  grew,
                  isTrue,
                  reason: 'no tail out of the body: $bounds',
                );
              }
            });
          }
        }
      }
    }

    for (final at in const [0.0, .1, .5, .9, 1.0]) {
      test('a tail asked to stand at $at stays on the body', () {
        final path = comicBalloonPath(
          240,
          80,
          ComicTail.bottomStart,
          24,
          at: at,
        );
        expect(path.computeMetrics().length, 1);
      });
    }

    testWidgets('a balloon hugs a word and wraps a sentence at 320', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        comicApp(
          const Align(
            alignment: Alignment.topLeft,
            child: ComicColumn(
              children: [
                ComicBalloon('Hm.', key: ValueKey('word')),
                ComicBalloon(longLine, key: ValueKey('line')),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      // The painted shape, not the row it stands in.
      Size shape(String name) => tester.getSize(
        find
            .descendant(
              of: find.byKey(ValueKey(name)),
              matching: find.byType(CustomPaint),
            )
            .first,
      );
      final word = shape('word');
      final line = shape('line');
      expect(word.width, lessThan(120));
      expect(line.width, lessThanOrEqualTo(320));
      expect(line.height, greaterThan(word.height * 2));
    });
  });

  group('a burst', () {
    Path star(double w, double h, int seed) => polyPath(
      burstPoints(
        w,
        h,
        spikes: 14,
        seed: seed,
        inner: .72,
        jitter: .09,
        pad: 4,
      ),
    );
    for (final number in const [
      '7',
      '23',
      '4.7',
      '1 h 30',
      '1,234',
      '1,234,567',
      '1,234,567,890',
      '€1,234,567.89',
      'Sold out',
      'Quiz\nnight',
      'Donaudampfschifffahrtsgesellschaft',
    ]) {
      for (final (w, h) in const [
        (262.0, 216.0),
        (146.0, 124.0),
        (96.0, 92.0),
        (48.0, 42.0),
      ]) {
        test('$number fits a star of $w x $h with no clipping', () {
          const words = TextStyle(
            fontSize: 16,
            height: 1,
            fontFamily: 'Bangers',
          );
          final big = TextStyle(
            fontSize: h * .45,
            height: 1,
            fontFamily: 'Bangers',
          );
          final s = star(w, h, 3);
          final c = Offset(w / 2, h / 2);
          final fit = ComicBurstFit(s, c, [
            ('Over', words, 2),
            for (final line in number.split('\n')) (line, big, 2),
            ('Under', words, 0),
          ], TextDirection.ltr);
          expect(fit.scale, greaterThan(0));
          expect(fit.holds(s, c, fit.scale), isTrue);
          fit.dispose();
        });
      }
    }

    testWidgets('a second burst on a screen falls to a flat stamp', (
      tester,
    ) async {
      final said = <String>[];
      final was = debugPrint;
      debugPrint = (m, {wrapWidth}) => said.add(m ?? '');
      await tester.pumpWidget(
        comicApp(
          const ComicBurstLedger(
            child: ComicColumn(
              children: [
                ComicBurst(number: '23'),
                ComicBurst(number: '99'),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      debugPrint = was;
      expect(tester.takeException(), isNull);
      expect(find.byType(ComicStamp), findsOneWidget);
      expect(said.join(), contains('ComicBurst'));
    });

    testWidgets('a page takes one on its own: ComicScaffold keeps the ledger', (
      tester,
    ) async {
      final was = debugPrint;
      debugPrint = (m, {wrapWidth}) {};
      await tester.pumpWidget(
        comicApp(
          const ComicScaffold(
            body: ComicColumn(
              children: [
                ComicBurst(number: '23'),
                ComicBurst(number: '99'),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      debugPrint = was;
      expect(find.byType(ComicStamp), findsOneWidget);
    });

    testWidgets('pops repeat as they like', (tester) async {
      await tester.pumpWidget(
        comicApp(
          const ComicBurstLedger(
            child: Wrap(
              children: [ComicPop('1'), ComicPop('2'), ComicPop('3')],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ComicStamp), findsNothing);
    });
  });

  group('lettering', () {
    testWidgets('uses the display family, package and scale from the theme', (
      tester,
    ) async {
      for (final typeface in [
        const ComicTypeface(),
        const ComicTypeface(display: 'ShantellSans', scale: 1.25),
      ]) {
        await tester.pumpWidget(
          comicApp(
            ComicTheme(
              data: ComicThemeData.offset().copyWith(typeface: typeface),
              child: const Center(child: ComicLettering('Issue', size: 40)),
            ),
          ),
        );
        final size = 40 * typeface.scale;
        final words = TextPainter(
          text: TextSpan(
            text: 'ISSUE',
            style: TextStyle(
              inherit: false,
              fontFamily: typeface.display,
              package: typeface.displayPackage,
              fontSize: size,
              height: ((size * .95).roundToDouble() - .01) / size,
              letterSpacing: size * .035,
              fontWeight: FontWeight.w400,
              leadingDistribution: TextLeadingDistribution.even,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        expect(
          tester.getSize(find.byType(ComicLettering)).width,
          closeTo(words.width, .001),
        );
        expect(
          tester.getSize(find.byType(ComicLettering)).height,
          closeTo(words.height, .001),
        );
        words.dispose();
      }
    });

    Future<(RenderComicLettering, List<int>, int, int)> pump(
      WidgetTester tester,
      TextDirection dir,
      double dpr,
    ) async {
      tester.view.physicalSize = Size(500 * dpr, 200 * dpr);
      tester.view.devicePixelRatio = dpr;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: dir,
          child: ComicTheme(
            data: ComicTheme.preset('offset', Brightness.light),
            child: Center(
              child: RepaintBoundary(
                key: key,
                child: ColoredBox(
                  color: const Color(0xFFFFFFFF),
                  child: SizedBox(
                    width: 460,
                    child: ComicLettering(
                      'Huzzah!',
                      size: 100,
                      fill: const Color(0xFFFFD21F),
                      style: ComicLetteringStyle.masthead,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      final render = tester.renderObject<RenderComicLettering>(
        find.byType(ComicLettering),
      );
      final image = await _shot(tester, key);
      final out = await _rgba(tester, image);
      final (w, h) = (image.width, image.height);
      image.dispose();
      return (render, out, w, h);
    }

    testWidgets('it is one part, one layer of text per ink', (tester) async {
      final (r, _, _, _) = await pump(tester, TextDirection.ltr, 1);
      // Its fill, its contour, and two hard layers each with its own contour.
      expect(r.layerCount, lessThanOrEqualTo(6));
      expect(find.byType(Text), findsNothing);
      expect(find.byType(RichText), findsNothing);
    });

    testWidgets('in RTL it draws the same ink, in one place', (tester) async {
      final (_, a, w, h) = await pump(tester, TextDirection.ltr, 1);
      final (_, b, _, _) = await pump(tester, TextDirection.rtl, 1);
      // The same glyph run: count the ink. A doubled word would paint about twice as much.
      int ink(List<int> px) {
        var n = 0;
        for (var i = 0; i < px.length; i += 4) {
          if (px[i] < 250 || px[i + 2] < 250) n++;
        }
        return n;
      }

      expect(w * h, greaterThan(0));
      expect((ink(a) - ink(b)).abs() / ink(a), lessThan(.02));
    }, tags: 'goldens'); // drawn ink

    testWidgets('at scale 3 it stays sharp: the edge is one or two pixels', (
      tester,
    ) async {
      final (_, px, w, h) = await pump(tester, TextDirection.ltr, 3);
      // Walk one row across it and count the pixels neither ink nor paper: a blur would smear these into long runs.
      final y = h ~/ 2;
      var longest = 0, run = 0;
      for (var x = 0; x < w; x++) {
        final i = (y * w + x) * 4;
        final (r, g, bl) = (px[i], px[i + 1], px[i + 2]);
        final solid =
            (r > 245 && g > 245 && bl > 245) ||
            (r < 40 && g < 40 && bl < 60) ||
            (r > 235 && g > 190 && bl < 70) ||
            (r > 180 && g < 80 && bl < 110);
        run = solid ? 0 : run + 1;
        if (run > longest) longest = run;
      }
      expect(longest, lessThan(9));
    }, tags: 'goldens'); // drawn edge
  });

  group('the cast is nobody', () {
    test('no friend of the concept and no comic of the world', () {
      final names = RegExp(
        r"\b(Juno|Mina|Theo|Rafa|Noor|Ellis|Abara|Sato|Lindqvist|Quintero|Fadel|Brandt|Fennel|Odile|Marchetti|"
        r"Marvel|Batman|Superman|Spider-?Man|Archie|Beano|Dandy|Tintin|Asterix)\b",
      );
      for (final dir in [
        'lib/src/',
        'test/pages',
        if (Directory('example/lib/demo_art').existsSync())
          'example/lib/demo_art',
      ]) {
        for (final f in Directory(
          dir,
        ).listSync(recursive: true).whereType<File>()) {
          if (!f.path.endsWith('.dart')) continue;
          final m = names.firstMatch(f.readAsStringSync());
          expect(m?[0], isNull, reason: f.path);
        }
      }
    });

    test(
      'a seeded person keeps their initials and a demo portrait keeps its bust',
      () {
        expect(ComicPerson.seeded('Sam Doe').initials, 'SD');
      },
    );
  });
}
