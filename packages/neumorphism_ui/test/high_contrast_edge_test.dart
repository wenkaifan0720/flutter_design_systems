// With high contrast on, every resting control prints an edge at 3:1 against the ground beside it, read with every
// shadow gone, in every preset and mode, on the wall, in a slab and in a well.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'flat_stage.dart';
import 'support.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadNeumorphicFonts();
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
      'stepper keys': NeumorphicNumberField(value: 2, onChanged: (_) {}),
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
        child: NeumorphicTextField(hintText: 'A name'),
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
            await pumpFlat(
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
            final (w, _, px) = await stagePixels(tester);
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
            // ignore: avoid_print — the measured edges go to the test log, passes included.
            print('EDGE $preset ${b.name} $on: ${measured.join(', ')}');
            expect(weak, isEmpty);
          }, tags: ['goldens']);
        }
      }
    }
  });
}
