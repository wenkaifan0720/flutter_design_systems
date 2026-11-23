// A latched control differs from an unlatched one with no shadow at all: the latched one carries the pigment, the
// unlatched one none.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/theme.dart'
    show NeumorphicPigment;

import 'flat_stage.dart';
import 'support.dart';

// In use: a bank or box out of use lies flat with its colours toward the ground, and its pigment with it.
void _pick(String _) {}
void _tap() {}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadNeumorphicFonts();
  });

  group('latched against unlatched, with no shadow visible', () {
    for (final preset in NeumorphicThemeData.presets) {
      for (final b in Brightness.values) {
        final t = NeumorphicThemeData.preset(preset, b);
        final name = '$preset ${b.name}';

        Future<int> count(WidgetTester tester, Widget part) async {
          await pumpFlat(tester, part, t);
          final (_, _, px) = await stagePixels(tester);
          return pigmentPixels(px, t.colors.pigment);
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
          await pumpFlat(
            tester,
            const SizedBox(
              width: 300,
              child: NeumorphicTextField(hintText: 'A'),
            ),
            t.copyWith(highContrast: true),
          );
          final (w, h, px) = await stagePixels(tester);
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
}
