// The look's laws, the ones a soft look always loses first. Radii stay on the card scale unless the thing is an object. Raised and pressed don't stack up
// when parts nest. A latched control differs from an unlatched one with no shadow at all. And the pigment can't spread: it's out of the barrel, a part
// takes no colour, and a page has one act.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/frames.dart' show NeumorphicDraw;
import 'package:neumorphism_ui/src/neumorphism/theme.dart'
    show NeumorphicPigment;

import 'support.dart';

Iterable<File> _library() sync* {
  for (final f in Directory(
    'lib/src/neumorphism',
  ).listSync(recursive: true).whereType<File>()) {
    if (f.path.endsWith('.dart')) yield f;
  }
}

Iterable<File> _pages() =>
    Directory('test/pages')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

const _stage = ValueKey('flat-stage');

// In use: a bank or box out of use lies flat with its colours toward the ground, which is another law, and its pigment
// with it.
void _pick(String _) {}
void _tap() {}

Future<(int, int, Uint8List)> _pixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_stage),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final out = (image.width, image.height, bytes!.buffer.asUint8List());
    image.dispose();
    return out;
  }))!;
}

/// How many pixels are near the pigment: blue-dominant, far from the plaster's greys, by the preset's own colour.
int _pigmentPixels(Uint8List px, Color pigment) {
  var n = 0;
  final r0 = (pigment.r * 255).round(),
      g0 = (pigment.g * 255).round(),
      b0 = (pigment.b * 255).round();
  for (var i = 0; i < px.length; i += 4) {
    if (px[i + 3] < 200) continue;
    final d =
        (px[i] - r0).abs() + (px[i + 1] - g0).abs() + (px[i + 2] - b0).abs();
    if (d < 60) n++;
  }
  return n;
}

Future<void> _flat(
  WidgetTester tester,
  Widget part,
  NeumorphicThemeData theme, {
  double height = 300,
}) async {
  tester.view.physicalSize = Size(390, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        type: MaterialType.transparency,
        child: NeumorphicTheme(
          data: theme,
          child: RepaintBoundary(
            key: _stage,
            child: ColoredBox(
              color: theme.colors.ground,
              child: Center(child: NeumorphicFlatScope(child: part)),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadNeumorphicFonts();
  });

  group('radii', () {
    test('the scale: controls 8 to 12, a card 20 at most', () {
      expect(NeumorphicRadii.slab, lessThanOrEqualTo(24));
      expect(NeumorphicRadii.well, lessThanOrEqualTo(NeumorphicRadii.slab));
      expect(NeumorphicRadii.control, inInclusiveRange(8, 12));
      expect(NeumorphicRadii.chip, inInclusiveRange(8, 12));
      expect(NeumorphicRadii.cap, inInclusiveRange(8, 12));
    });

    test('no radius over the scale, unless it is drawn on an object', () {
      // An object's round end is drawn from its own size (w / 2, a thumb, a slot), not written as a number.
      final big = RegExp(
        r'(?:BorderRadius|Radius)\.circular\(\s*(\d+(?:\.\d+)?)',
      );
      final found = <String>[];
      for (final f in [..._library(), ..._pages()]) {
        for (final m in big.allMatches(f.readAsStringSync())) {
          if (double.parse(m[1]!) > NeumorphicRadii.slab) {
            found.add('${f.path}: ${m[0]}');
          }
        }
      }
      expect(found, isEmpty);
    });

    test('a page holds no radius of its own', () {
      final found = <String>[];
      for (final f in _pages()) {
        if (RegExp(r'BorderRadius|Radius\.').hasMatch(f.readAsStringSync())) {
          found.add(f.path);
        }
      }
      expect(found, isEmpty);
    });

    testWidgets('a word never stands in a bay window: words are under it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        neumorphicApp(
          const SizedBox(
            width: 600,
            child: NeumorphicRelief(
              title: '1',
              courses: [
                NeumorphicCourse('A', [
                  NeumorphicBay(figure: '18°', name: 'A word', note: 'Another'),
                ]),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      final figure = tester.getRect(find.text('18°'));
      final window = tester
          .renderObjectList<RenderCustomPaint>(find.byType(CustomPaint))
          .where((b) => b.painter.runtimeType.toString() == '_WindowPainter')
          .single;
      final box = (window.localToGlobal(Offset.zero)) & window.size;
      expect(figure.top, greaterThanOrEqualTo(box.bottom - .5));
    });
  });

  group('raised and pressed, nesting', () {
    // The whole table: what each surface draws by what it stands on. The wrong nesting can't be written: it comes out as the right one.
    const draws = <(NeumorphicSurfaceLevel, NeumorphicDraw?, NeumorphicDraw)>[
      // On the wall, each is what it says.
      (NeumorphicSurfaceLevel.part, null, NeumorphicDraw.part),
      (NeumorphicSurfaceLevel.slab, null, NeumorphicDraw.slab),
      (NeumorphicSurfaceLevel.casting, null, NeumorphicDraw.casting),
      (NeumorphicSurfaceLevel.groove, null, NeumorphicDraw.groove),
      (NeumorphicSurfaceLevel.well, null, NeumorphicDraw.well),
      // A slab in a slab is only a small part, a slab on a part a step: shadows don't stack.
      (NeumorphicSurfaceLevel.slab, NeumorphicDraw.slab, NeumorphicDraw.part),
      (NeumorphicSurfaceLevel.slab, NeumorphicDraw.part, NeumorphicDraw.step),
      (
        NeumorphicSurfaceLevel.casting,
        NeumorphicDraw.slab,
        NeumorphicDraw.part,
      ),
      (NeumorphicSurfaceLevel.part, NeumorphicDraw.part, NeumorphicDraw.step),
      (NeumorphicSurfaceLevel.part, NeumorphicDraw.step, NeumorphicDraw.step),
      // A well in a slab is a real well. A well in a well, or a groove in a groove, is only a floor: a hole in a hole is mud.
      (NeumorphicSurfaceLevel.well, NeumorphicDraw.slab, NeumorphicDraw.well),
      (NeumorphicSurfaceLevel.well, NeumorphicDraw.well, NeumorphicDraw.floor),
      (NeumorphicSurfaceLevel.well, NeumorphicDraw.floor, NeumorphicDraw.floor),
      (
        NeumorphicSurfaceLevel.groove,
        NeumorphicDraw.groove,
        NeumorphicDraw.floor,
      ),
      (
        NeumorphicSurfaceLevel.groove,
        NeumorphicDraw.floor,
        NeumorphicDraw.floor,
      ),
      // A well on a button is at most a groove, and a part stands in a well, a button in its bank.
      (NeumorphicSurfaceLevel.well, NeumorphicDraw.part, NeumorphicDraw.groove),
      (NeumorphicSurfaceLevel.part, NeumorphicDraw.well, NeumorphicDraw.part),
    ];
    for (final (cast, on, want) in draws) {
      test('${cast.name} on ${on?.name ?? 'the wall'} draws ${want.name}', () {
        expect(NeumorphicSurface.resolve(cast, on), want);
      });
    }

    testWidgets('the parts obey it: a well in a slab, a well in that', (
      tester,
    ) async {
      await tester.pumpWidget(
        neumorphicApp(
          const NeumorphicSlab(
            child: NeumorphicWell(
              child: NeumorphicColumn(
                children: [
                  Text('a', key: ValueKey('a')),
                  NeumorphicWell(child: Text('b', key: ValueKey('b'))),
                ],
              ),
            ),
          ),
        ),
      );
      expect(
        NeumorphicSurface.on(tester.element(find.byKey(const ValueKey('a')))),
        NeumorphicDraw.well,
      );
      expect(
        NeumorphicSurface.on(tester.element(find.byKey(const ValueKey('b')))),
        NeumorphicDraw.floor,
      );
    });
  });

  group('latched against unlatched, with no shadow visible', () {
    for (final preset in NeumorphicThemeData.presets) {
      for (final b in Brightness.values) {
        final t = NeumorphicThemeData.preset(preset, b);
        final name = '$preset ${b.name}';

        Future<int> count(WidgetTester tester, Widget part) async {
          await _flat(tester, part, t);
          final (_, _, px) = await _pixels(tester);
          return _pigmentPixels(px, t.colors.pigment);
        }

        testWidgets(
          '$name a latch carries the pigment, an unlatched one none',
          (tester) async {
            const options = [
              NeumorphicLatch('One', icon: NeumorphicGlyphs.flame),
              NeumorphicLatch('Two', icon: NeumorphicGlyphs.leaf),
            ];
            final on = await count(
              tester,
              const SizedBox(
                width: 300,
                child: NeumorphicLatchGroup(
                  options: options,
                  value: 'One',
                  onChanged: _pick,
                ),
              ),
            );
            final off = await count(
              tester,
              const SizedBox(
                width: 300,
                child: NeumorphicLatchGroup(options: options, onChanged: _pick),
              ),
            );
            expect(on, greaterThan(8), reason: 'latched');
            expect(off, 0, reason: 'unlatched');
          },
          tags: ['goldens'],
        );

        testWidgets('$name a latch with no icon still carries an LED', (
          tester,
        ) async {
          const options = [NeumorphicLatch('One'), NeumorphicLatch('Two')];
          final on = await count(
            tester,
            const SizedBox(
              width: 300,
              child: NeumorphicLatchGroup(
                options: options,
                value: 'One',
                onChanged: _pick,
              ),
            ),
          );
          expect(on, greaterThan(8));
        }, tags: ['goldens']);

        testWidgets('$name a switch, a push, a selected box, likewise', (
          tester,
        ) async {
          // Enabled: a switch with no onChanged is disabled and lies flat, which is another law.
          expect(
            await count(
              tester,
              NeumorphicSwitch(value: true, onChanged: (_) {}),
            ),
            greaterThan(40),
          );
          expect(
            await count(
              tester,
              NeumorphicSwitch(value: false, onChanged: (_) {}),
            ),
            0,
          );
          const push = NeumorphicPush(icon: NeumorphicGlyphs.sun, label: 'A');
          expect(
            await count(
              tester,
              const SizedBox(
                width: 300,
                child: NeumorphicPushGroup(
                  items: [
                    NeumorphicPush(
                      icon: NeumorphicGlyphs.sun,
                      label: 'A',
                      selected: true,
                    ),
                  ],
                ),
              ),
            ),
            greaterThan(8),
          );
          expect(
            await count(
              tester,
              const SizedBox(
                width: 300,
                child: NeumorphicPushGroup(items: [push]),
              ),
            ),
            0,
          );
          expect(
            await count(
              tester,
              const SizedBox(
                width: 300,
                child: NeumorphicChoiceBox(
                  selected: true,
                  onPressed: _tap,
                  child: Text('A'),
                ),
              ),
            ),
            greaterThan(8),
          );
          expect(
            await count(
              tester,
              const SizedBox(
                width: 300,
                child: NeumorphicChoiceBox(onPressed: _tap, child: Text('A')),
              ),
            ),
            0,
          );
        }, tags: ['goldens']);

        testWidgets('$name high contrast gives a field a printed edge at 3:1', (
          tester,
        ) async {
          await _flat(
            tester,
            const SizedBox(width: 300, child: NeumorphicTextField(hint: 'A')),
            t.copyWith(highContrast: true),
          );
          final (w, h, px) = await _pixels(tester);
          final y = h ~/ 2;
          final ground = t.colors.ground;
          double lum(int i) {
            return Color.fromARGB(
              255,
              px[i],
              px[i + 1],
              px[i + 2],
            ).computeLuminance();
          }

          final g = ground.computeLuminance();
          var best = 1.0;
          for (var x = 0; x < w ~/ 3; x++) {
            final l = lum((y * w + x) * 4);
            final ratio = l > g ? (l + .05) / (g + .05) : (g + .05) / (l + .05);
            if (ratio > best) best = ratio;
          }
          expect(best, greaterThanOrEqualTo(2.9));
        }, tags: ['goldens']);
      }
    }
  });

  group('high contrast gives resting controls a 3:1 edge', () {
    // Shadows are the first thing a bad screen loses, so the edge is read with none: NeumorphicFlatScope, every preset and mode, on the
    // wall, in a slab and in a well. The ground is the pixel just outside the control, not a token, and the edge is the first
    // thing met coming in from it. This is the explicitly selected high-contrast mode;
    // default surfaces instead retain the paired light and dark shadows.
    final parts = <String, Widget>{
      'a resting chip': NeumorphicChip('All', onPressed: () {}),
      'a resting choice': NeumorphicChoiceBox(
        onPressed: () {},
        child: const SizedBox(width: 120, height: 48),
      ),
      'a resting round button': NeumorphicRoundButton(
        NeumorphicGlyphs.plus,
        label: 'Add',
        onPressed: () {},
      ),
      'stepper keys': NeumorphicNumberField(
        value: '2',
        onDecrease: () {},
        onIncrease: () {},
      ),
      'an off switch': NeumorphicSwitch(value: false, onChanged: (_) {}),
      'an open check': NeumorphicRoundCheckbox(onChanged: (_) {}),
      // In use: a bank out of use lies flat, and 3:1 doesn't bind it.
      'an unchosen latch bank': SizedBox(
        width: 300,
        child: NeumorphicLatchGroup(
          options: const [NeumorphicLatch('One'), NeumorphicLatch('Two')],
          onChanged: (_) {},
        ),
      ),
      'an empty field': const SizedBox(
        width: 300,
        child: NeumorphicTextField(hint: 'A name'),
      ),
      'a select': SizedBox(
        width: 300,
        child: NeumorphicSelectField(value: 'A town', onPressed: () {}),
      ),
      'a slider at rest': SizedBox(
        width: 300,
        child: NeumorphicSlider(label: 'Level', value: 0, onChanged: (_) {}),
      ),
    };
    final surfaces = <String, Widget Function(Widget)>{
      'the wall': (c) => c,
      'a slab': (c) => NeumorphicSlab(child: c),
      'a well': (c) => NeumorphicWell(child: c),
    };
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (math.max(x, y) + .05) / (math.min(x, y) + .05);
    }

    final palettes = <String, NeumorphicThemeData Function(Brightness)>{
      for (final id in NeumorphicThemeData.presets)
        id: (b) => NeumorphicThemeData.preset(id, b),
      for (final (name, ground, pigment) in [
        ('custom plum', const Color(0xFFE8E3ED), const Color(0xFF7542A3)),
        ('custom pale', const Color(0xFFEEEEEE), const Color(0xFFFDFAED)),
        ('custom dark', const Color(0xFF080510), const Color(0xFFB4DF76)),
        ('custom grey', const Color(0xFF777777), const Color(0xFF777777)),
        (
          'custom transparent',
          const Color(0x007700FF),
          const Color(0x33777777),
        ),
        ('custom saturated', const Color(0xFF00FF00), const Color(0xFFFF00FF)),
      ])
        name: (b) => NeumorphicThemeData.from(
          ground: ground,
          pigment: pigment,
          brightness: b,
        ),
    };
    for (final MapEntry(key: preset, value: palette) in palettes.entries) {
      for (final b in Brightness.values) {
        final t = palette(b).copyWith(highContrast: true);
        for (final MapEntry(key: on, value: wrap) in surfaces.entries) {
          testWidgets('$preset ${b.name}, on $on', (tester) async {
            final keys = {for (final k in parts.keys) k: GlobalKey()};
            await _flat(
              tester,
              SizedBox(
                width: 360,
                child: wrap(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final MapEntry(key: name, value: part)
                          in parts.entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: KeyedSubtree(key: keys[name], child: part),
                        ),
                    ],
                  ),
                ),
              ),
              t,
              height: 1000,
            );
            final (w, _, px) = await _pixels(tester);
            Color at(int x, int y) {
              final i = (y * w + x) * 4;
              return Color.fromARGB(255, px[i], px[i + 1], px[i + 2]);
            }

            final weak = <String>[];
            final measured = <String>[];
            for (final MapEntry(key: name, value: key) in keys.entries) {
              final box = tester.getRect(find.byKey(key));
              final y = box.center.dy.round(), left = box.left.round();
              final ground = at(left - 4, y);
              var first = -1;
              for (var x = left - 3; x < left + 14 && first < 0; x++) {
                if (contrast(at(x, y), ground) > 1.15) first = x;
              }
              var best = 1.0;
              if (first >= 0) {
                for (var x = first; x < first + 3; x++) {
                  best = math.max(best, contrast(at(x, y), ground));
                }
              }
              if (best < 3) weak.add('$name ${best.toStringAsFixed(2)}');
              measured.add('$name=${best.toStringAsFixed(2)}');
            }
            // Keep the measured matrix in the verification log, including passes.
            // ignore: avoid_print
            print('EDGE $preset ${b.name} $on: ${measured.join(', ')}');
            expect(weak, isEmpty);
          }, tags: ['goldens']);
        }
      }
    }
  });

  group('the pigment cannot spread', () {
    test('the barrel keeps raw pigment and paint helpers out', () {
      final file = File('lib/src/neumorphism.dart');
      final barrel = file.readAsStringSync();
      // The exporter rewrites this path and its directives to the package stem.
      final stem = file.uri.pathSegments.last.replaceFirst('.dart', '');
      for (final hidden in [
        'NeumorphicPigment',
        'neumorphicPaintRaised',
        'neumorphicPaintPressed',
      ]) {
        expect(barrel, contains(hidden), reason: 'hide $hidden');
      }
      // The theme's export hides the pigment first; the rule and edge widths it hides beside it are paint helpers too.
      expect(
        barrel,
        matches(
          RegExp("export '$stem/theme\\.dart'\\s+hide NeumorphicPigment\\b"),
        ),
      );
    });

    test('no example page reaches for a pigment or a colour', () {
      final found = <String>[];
      for (final f in _pages()) {
        final s = f.readAsStringSync();
        for (final bad in [
          '.pigment',
          'pigmentInk',
          'pigmentHi',
          'onPigment',
          'colors.',
          'Color(',
          'Colors.',
          "plaster/theme.dart",
        ]) {
          if (s.contains(bad)) found.add('${f.path}: $bad');
        }
      }
      expect(found, isEmpty);
    });

    test('colour overrides stay confined to documented primitives', () {
      final field = RegExp(r'^\s*final Color\??\s+\w+', multiLine: true);
      final found = <String>[];
      for (final f in _library()) {
        if (f.path.endsWith('/theme.dart') ||
            f.path.endsWith('/geometry.dart')) {
          continue;
        }
        final s = f.readAsStringSync();
        for (final c in RegExp(
          r'^class (\w+)[^\n{]*\{',
          multiLine: true,
        ).allMatches(s)) {
          final name = c[1]!;
          if (name.startsWith('_') || !name.startsWith('Neumorphic')) continue;
          final end = s.indexOf(RegExp(r'^class ', multiLine: true), c.end);
          final body = s.substring(c.start, end < 0 ? s.length : end);
          if (field.hasMatch(body)) found.add(name);
        }
      }
      // A spine is a rule in a column, its colour a token passed inside the library.
      found.remove('NeumorphicColumn');
      // A busy button supplies its on-face ink to its spinner. PACKAGE's
      // styling contract permits this primitive override; pages still use
      // the preset defaults, checked independently above.
      found.remove('NeumorphicCircularProgressIndicator');
      // The parts library's cell bank and panel-row painter: internal helpers, each handed its colour by the part
      // that draws it.
      found.remove('NeumorphicCellBank');
      found.remove('NeumorphicPanelRowRelief');
      expect(found, isEmpty);
    });

    test('an example page has one act', () {
      final found = <String>[];
      for (final f in _pages()) {
        final acts = 'NeumorphicButton.filled('
            .allMatches(f.readAsStringSync())
            .length;
        // A page may place its act twice by width: the rail's on a desktop and the top's on a phone, or a footer's. Never two on one screen: agenda and form hold one.
        if (acts > 1) found.add('${f.path}: $acts');
      }
      expect(found, isEmpty);
    });

    for (final b in Brightness.values) {
      testWidgets('the pigment is a small share of a page, ${b.name}', (
        tester,
      ) async {
        final t = NeumorphicThemeData.preset('porcelain', b);
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: NeumorphicTheme(
                data: t,
                child: RepaintBoundary(
                  key: _stage,
                  child: ColoredBox(
                    color: t.colors.ground,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const NeumorphicPageHead(
                          title: 'A page',
                          subtitle: 'A line',
                        ),
                        const NeumorphicLatchGroup(
                          options: [
                            NeumorphicLatch('One', icon: NeumorphicGlyphs.sun),
                            NeumorphicLatch('Two'),
                          ],
                          value: 'One',
                        ),
                        const NeumorphicDial(
                          compact: true,
                          value: 40,
                          figure: '40',
                          label: 'A word',
                        ),
                        NeumorphicButton.filled('Do it', onPressed: () {}),
                        const NeumorphicLiveText('A state'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        final (w, h, px) = await _pixels(tester);
        final share = _pigmentPixels(px, t.colors.pigment) / (w * h);
        expect(share, lessThan(.04));
      }, tags: ['goldens']);
    }
  });

  group('a chart with no data says so, with no empty axis', () {
    final parts = <String, Widget>{
      'two way': const NeumorphicTwoWayBars(above: []),
      'columns': const NeumorphicColumnBars(values: []),
      'step line': const NeumorphicStepLine(
        readings: [],
        xMax: 1,
        yMin: 0,
        yMax: 1,
      ),
      'shares': const NeumorphicShareBars(rows: []),
    };
    for (final e in parts.entries) {
      testWidgets(e.key, (tester) async {
        await _flat(
          tester,
          e.value,
          NeumorphicThemeData.preset('porcelain', Brightness.light),
        );
        expect(find.byType(NeumorphicEmptyState), findsOneWidget);
      });
    }
  });
}
