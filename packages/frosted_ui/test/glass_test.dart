// Glass keeps its words (frosted-glass.md, the legibility contract). Body text reads at 4.5:1 and quiet words at 3:1
// on every glass, over whatever the page puts behind it:
// - in arithmetic, for every preset by day and by night: each glass's tint over black, white and saturated colours
//   (black is the worst behind light glass, white behind dark);
// - as drawn, in the default preset by day and by night: each glass blurred over stripes of black, white and
//   saturated colours, every pixel inside it read against every ink;
// - with transparency off (the theme's opaqueMaterials), each glass is its opaque colour, the page behind unseen;
// - a control's state reads off the glass, not only its words: the control edge reads 3:1 on every glass over any
//   backdrop and on the page, in every preset by day and by night, and an off switch, the chosen segment, chip, tab
//   and sidebar link, a field, an empty check and an unchosen radio each draw their state in it.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

const _glass = [
  FrostedMaterial.sheer,
  FrostedMaterial.pane,
  FrostedMaterial.well,
  FrostedMaterial.slab,
  FrostedMaterial.bar,
];

/// What a page can put behind glass: the two extremes and the saturated hues.
const _behind = [
  Color(0xFF000000),
  Color(0xFFFFFFFF),
  Color(0xFFFF0000),
  Color(0xFF00C800),
  Color(0xFF0000FF),
  Color(0xFFFFFF00),
  Color(0xFFFF00FF),
  Color(0xFF00FFFF),
];

const _page = ValueKey('page');

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + .05) / (math.min(la, lb) + .05);
}

/// The inks that must read at [FrostedMaterials.bodyContrast], by name.
Map<String, Color> _body(FrostedThemeData t) => {
  'textPrimary': t.colorScheme.textPrimary,
  'textSecondary': t.colorScheme.textSecondary,
  'textTertiary': t.colorScheme.textTertiary,
};

/// [material] at the stage's middle over the stripes of [_behind].
Widget _stage(FrostedThemeData theme, FrostedMaterial material) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => FrostedHost(
    light: theme,
    dark: theme,
    brightness: theme.isDark ? Brightness.dark : Brightness.light,
    child: page!,
  ),
  home: Align(
    alignment: Alignment.topLeft,
    child: RepaintBoundary(
      key: _page,
      child: SizedBox(
        width: 400,
        height: 200,
        child: Stack(
          children: [
            Row(
              children: [
                for (final c in _behind) Expanded(child: ColoredBox(color: c)),
              ],
            ),
            Positioned(
              left: 40,
              top: 40,
              width: 320,
              height: 120,
              child: FrostedSurface(
                material: material,
                borderRadius: BorderRadius.circular(20),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);

/// The stage as drawn, one pixel a logical pixel, and a reader of a pixel.
Future<Color Function(int x, int y)> _shot(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_page),
  );
  final width = boundary.size.width.round();
  final px = (await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      return (await image.toByteData())!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }))!;
  return (int x, int y) {
    final i = (y * width + x) * 4;
    return Color.fromARGB(px[i + 3], px[i], px[i + 1], px[i + 2]);
  };
}

/// Every colour the shown part draws an edge, a ring or a boundary in: its
/// faces' edges, rings and shadows (as their diagnostics report them), and
/// its boxes' borders and shadows.
Set<Color> _drawn(WidgetTester tester) {
  final colours = <Color>{};
  for (final w in tester.allWidgets) {
    if (w.runtimeType.toString() == 'FrostedFace') {
      for (final p in w.toDiagnosticsNode().getProperties()) {
        final v = p.value;
        if (p.name == 'color') continue;
        if (v is Color) colours.add(v);
        if (v is Iterable<BoxShadow>) colours.addAll(v.map((s) => s.color));
      }
    } else if (w is DecoratedBox) {
      final d = w.decoration;
      if (d is BoxDecoration) {
        if (d.border case final Border b) colours.add(b.top.color);
        colours.addAll((d.boxShadow ?? const []).map((s) => s.color));
      } else if (d is ShapeDecoration) {
        if (d.shape case final OutlinedBorder s) colours.add(s.side.color);
      }
    }
  }
  return colours;
}

/// Every pixel inside the glass, clear of its rim and its corners.
Iterable<(int, int)> _inside() sync* {
  for (var y = 56; y < 144; y += 2) {
    for (var x = 56; x < 344; x += 2) {
      yield (x, y);
    }
  }
}

/// The controls of glass that wear the lit rim by day.
const _litByDay = {
  'a chosen segment',
  'a chosen chip',
  'a chosen tab',
  'a chosen link',
  'a field',
  'a search field',
};

void main() {
  test('every glass keeps its words over any backdrop, in every preset', () {
    final faults = <String>[];
    for (final id in FrostedThemeData.presets) {
      for (final brightness in Brightness.values) {
        final t = FrostedThemeData.preset(id, brightness);
        final materials = t.materials;
        for (final material in _glass) {
          final recipe = materials.of(material)!;
          for (final behind in _behind) {
            final ground = recipe.groundOver(behind);
            final at = '$id ${brightness.name} ${material.name} over $behind';
            for (final MapEntry(key: ink, value: c) in _body(t).entries) {
              final r = _contrast(c, ground);
              if (r < FrostedMaterials.bodyContrast) {
                faults.add('$at: $ink ${r.toStringAsFixed(2)}');
              }
            }
            final quiet = _contrast(t.colorScheme.textTertiary, ground);
            if (quiet < FrostedMaterials.quietContrast) {
              faults.add('$at: textQuiet ${quiet.toStringAsFixed(2)}');
            }
          }
        }
      }
    }
    expect(faults, isEmpty);
  });

  test('a card is glass, not a white box: the backdrop\'s colour comes '
      'through it', () {
    double apart(Color a, Color b) => math.sqrt(
      math.pow(a.r - b.r, 2) + math.pow(a.g - b.g, 2) + math.pow(a.b - b.b, 2),
    );
    for (final id in FrostedThemeData.presets) {
      for (final brightness in Brightness.values) {
        final m = FrostedThemeData.preset(id, brightness).materials;
        for (final glass in [m.sheer, m.pane, m.bar]) {
          final red = glass.groundOver(const Color(0xFFFF0000));
          final blue = glass.groundOver(const Color(0xFF0000FF));
          expect(
            apart(red, blue),
            greaterThan(.15),
            reason: '$id ${brightness.name}: red behind shows $red, blue $blue',
          );
        }
      }
    }
  });

  test('a control\'s boundary reads 3:1 off any glass and the page, in '
      'every preset', () {
    final faults = <String>[];
    for (final id in FrostedThemeData.presets) {
      for (final brightness in Brightness.values) {
        final t = FrostedThemeData.preset(id, brightness);
        final page = t.colorScheme.background.withValues(alpha: 1);
        final grounds = [
          page,
          Color.alphaBlend(t.colorScheme.surface, page),
          Color.alphaBlend(t.colorScheme.surfaceAlt, page),
          ...t.materials.grounds(),
        ];
        final worst = grounds
            .map((g) => _contrast(t.controlEdge, g))
            .reduce(math.min);
        if (worst < FrostedMaterials.quietContrast) {
          faults.add('$id ${brightness.name}: ${worst.toStringAsFixed(2)}:1');
        }
      }
    }
    expect(faults, isEmpty, reason: faults.join('\n'));
  });

  for (final brightness in Brightness.values) {
    testWidgets('each control draws its state in the control edge by '
        '${brightness.name}', (tester) async {
      final t = FrostedThemeData.preset(
        FrostedThemeData.presets.first,
        brightness,
      );
      void drop(Object? _) {}
      const tabs = [
        FrostedNavItem(IconData(0xe88a), 'Activity'),
        FrostedNavItem(IconData(0xe8b8), 'Settings'),
      ];
      final parts = <String, Widget>{
        'an off switch': FrostedSwitch(
          value: false,
          onChanged: drop,
          label: 'Weekly summary',
        ),
        'a chosen segment': FrostedSegmentedButton<int>(
          segments: const [
            FrostedButtonSegment(0, 'Light'),
            FrostedButtonSegment(1, 'Dark'),
          ],
          value: 0,
          onChanged: drop,
          label: 'Theme',
        ),
        'a chosen chip': FrostedFilterChipGroup<int>(
          options: const [
            FrostedFilterOption(0, 'All'),
            FrostedFilterOption(1, 'Income'),
          ],
          value: 0,
          onChanged: drop,
        ),
        'a chosen tab': FrostedNavigationBar(
          items: tabs,
          onDestinationSelected: drop,
        ),
        'a chosen link': SizedBox(
          width: 240,
          height: 400,
          child: FrostedNavigationDrawer(
            items: tabs,
            onDestinationSelected: drop,
          ),
        ),
        'a field': FrostedTextField(label: 'Name', onChanged: drop),
        'a search field': FrostedSearchField(hint: 'Search', onChanged: drop),
        'an empty check': FrostedCheckbox(
          value: false,
          label: 'Agree',
          onChanged: drop,
        ),
        'an unchosen radio': FrostedRadioGroup<String>(
          label: 'Plan',
          value: 'none',
          onChanged: drop,
          options: const [FrostedRadio('free', 'Free')],
        ),
      };
      final faults = <String>[];
      for (final MapEntry(key: name, value: part) in parts.entries) {
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, page) => FrostedHost(
              light: t,
              dark: t,
              brightness: brightness,
              child: page!,
            ),
            home: Center(child: SizedBox(width: 360, child: part)),
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
        // By day a control of glass wears the lit rim (no dark line on light
        // glass, the identity ruling; its contrast is reported, not hidden);
        // the marks that stand alone (a switch's track, a check, a radio)
        // keep the control edge, their state's 3:1 boundary.
        final edge = brightness == Brightness.light && _litByDay.contains(name)
            ? FrostedChromeMetrics.litEdge
            : t.controlEdge;
        if (!_drawn(tester).contains(edge)) faults.add(name);
      }
      expect(
        faults,
        isEmpty,
        reason: 'drawn without their edge: ${faults.join(', ')}',
      );
    });
  }

  test('thicker glass floats higher: a slab is no thinner than a pane', () {
    for (final id in FrostedThemeData.presets) {
      for (final brightness in Brightness.values) {
        final m = FrostedThemeData.preset(id, brightness).materials;
        expect(m.slab.tint.a, greaterThanOrEqualTo(m.pane.tint.a), reason: id);
        expect(m.pane.tint.a, greaterThanOrEqualTo(m.sheer.tint.a));
        expect(m.slab.blur, greaterThan(m.sheer.blur), reason: id);
      }
    }
  });

  for (final brightness in Brightness.values) {
    final t = FrostedThemeData.preset(
      FrostedThemeData.presets.first,
      brightness,
    );
    for (final material in _glass) {
      testWidgets('${material.name} glass as drawn by ${brightness.name} keeps '
          'its words over black, white and saturated stripes', (tester) async {
        tester.view.physicalSize = const Size(400, 200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_stage(t, material));
        // The face eases from the last stage's.
        await tester.pumpAndSettle();
        final read = await _shot(tester);
        var worstBody = double.infinity;
        var worstQuiet = double.infinity;
        String? where;
        for (final (x, y) in _inside()) {
          final ground = read(x, y);
          for (final c in _body(t).values) {
            final r = _contrast(c, ground);
            if (r < worstBody) {
              worstBody = r;
              where = '($x, $y) $ground';
            }
          }
          worstQuiet = math.min(
            worstQuiet,
            _contrast(t.colorScheme.textTertiary, ground),
          );
        }
        expect(
          worstBody,
          greaterThanOrEqualTo(FrostedMaterials.bodyContrast),
          reason: 'the least body contrast, at $where',
        );
        expect(
          worstQuiet,
          greaterThanOrEqualTo(FrostedMaterials.quietContrast),
        );
      }, tags: const ['goldens']);
    }
  }

  // A sheet over a page: the kit's darkest control by day (the ink button),
  // its brightest by night, under the slab where a row would read. Glass
  // shows the colour behind it; the shape of a button behind does not smear
  // across the rows (the coordinator's Category sheet, 11-11).
  for (final brightness in Brightness.values) {
    testWidgets('a slab over the ink button by ${brightness.name} moves its '
        'ground by a few percent at most', (tester) async {
      final t = FrostedThemeData.preset(
        FrostedThemeData.presets.first,
        brightness,
      );
      tester.view.physicalSize = const Size(640, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, page) => FrostedHost(
            light: t,
            dark: t,
            brightness: brightness,
            child: page!,
          ),
          home: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: _page,
              child: SizedBox(
                width: 640,
                height: 400,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(color: t.colorScheme.background),
                    ),
                    Center(
                      child: FrostedButton('Freeze card', onPressed: () {}),
                    ),
                    Positioned.fill(
                      child: FrostedSurface(
                        material: FrostedMaterial.slab,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final read = await _shot(tester);
      final over = read(320, 200);
      // Clear of the button by three blurs and more, inside the slab's rim.
      final clear = read(40, 40);
      double channel(Color c, int i) => switch (i) {
        0 => c.r,
        1 => c.g,
        _ => c.b,
      };
      final moved = [
        for (var i = 0; i < 3; i++)
          (channel(over, i) - channel(clear, i)).abs(),
      ].reduce(math.max);
      expect(
        moved,
        lessThanOrEqualTo(.04),
        reason: 'over the button $over, clear of it $clear',
      );
    }, tags: const ['goldens']);
  }

  testWidgets('with transparency off every glass is its opaque colour', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final brightness in Brightness.values) {
      final t = FrostedThemeData.preset(
        FrostedThemeData.presets.first,
        brightness,
      ).copyWith(opaqueMaterials: true);
      for (final material in _glass) {
        await tester.pumpWidget(_stage(t, material));
        // The face eases from the last stage's.
        await tester.pumpAndSettle();
        final read = await _shot(tester);
        final want = t.materials.of(material)!.opaque;
        // The middle of the glass, under each stripe: one colour throughout.
        for (final x in [70, 130, 200, 270, 330]) {
          final got = read(x, 100);
          final off = [
            (got.r - want.r).abs(),
            (got.g - want.g).abs(),
            (got.b - want.b).abs(),
          ].reduce(math.max);
          expect(
            off,
            lessThan(6 / 255),
            reason:
                '${brightness.name} ${material.name} at x $x: $got, '
                'not $want',
          );
        }
      }
    }
  }, tags: const ['goldens']);
}
