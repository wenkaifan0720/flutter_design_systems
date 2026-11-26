// Appliance's six finishes (ApplianceThemeData.presets): warm first, each the
// warm plastic at its own tones in another hue with a signal of its own.
// Every word and legend reads 4.5:1 on what it sits on, the signal's words
// too, and the focus stands 3:1, by day and by night.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Pick = Color Function(ApplianceColors c);

void main() {
  test('six finishes, warm first', () {
    expect(ApplianceThemeData.presets, [
      'warm',
      'mint',
      'butter',
      'powder',
      'blush',
      'slate',
    ]);
  });

  for (final b in Brightness.values) {
    final warm = b == Brightness.dark
        ? ApplianceColors.dark
        : ApplianceColors.light;

    test('${b.name}: warm is the look by day and by night', () {
      expect(ApplianceColors.preset('warm', b), warm);
      expect(ApplianceThemeData.preset('warm', b).colors, warm);
    });

    test('${b.name}: each finish its own signal', () {
      final signals = {
        for (final name in ApplianceThemeData.presets)
          ApplianceColors.preset(name, b).signal,
      };
      expect(signals, hasLength(ApplianceThemeData.presets.length));
    });

    for (final name in ApplianceThemeData.presets) {
      final c = ApplianceThemeData.preset(name, b).colors;
      final housing = [c.housingTop, c.housingBottom];
      final plates = [c.face, c.well];
      final keys = [c.keyTop, c.keyBottom];

      test('${b.name}, $name: its theme wears its colours', () {
        expect(c, ApplianceColors.preset(name, b));
        expect(c.brightness, b);
      });

      test('${b.name}, $name: words read 4.5:1 on the housing, the '
          'faceplates and the keys', () {
        for (final (words, ink, grounds) in [
          ('print', c.print, [...housing, ...plates, ...keys]),
          ('muted print', c.printMuted, [...housing, ...plates, ...keys]),
          ('signal words', c.signalInk, [...housing, ...plates, ...keys]),
        ]) {
          for (final ground in grounds) {
            expect(
              applianceContrast(ink, ground),
              greaterThanOrEqualTo(4.5),
              reason: '$words on #${ground.toARGB32().toRadixString(16)}',
            );
          }
        }
      });

      test('${b.name}, $name: every legend reads 4.5:1 on its key', () {
        for (final (key, legend, fill) in [
          ('signal', c.onSignal, c.signal),
          ('signal top', c.onSignal, c.signalTop),
          ('danger', c.onDanger, c.danger),
          ('display', c.onDisplay, c.display),
        ]) {
          expect(
            applianceContrast(legend, fill),
            greaterThanOrEqualTo(4.5),
            reason: key,
          );
        }
      });

      test('${b.name}, $name: the focus stands 3:1 on the housing and a '
          'faceplate', () {
        for (final fill in [...housing, c.face]) {
          expect(applianceContrast(c.focus, fill), greaterThanOrEqualTo(3));
        }
      });

      test("${b.name}, $name: its plastic at warm's tones", () {
        for (final (pair, a, z) in <(String, _Pick, _Pick)>[
          ('print on the housing', (p) => p.print, (p) => p.housingBottom),
          ('print on a faceplate', (p) => p.print, (p) => p.face),
          ('muted print on a well', (p) => p.printMuted, (p) => p.well),
          ('disabled print on a key', (p) => p.printDisabled, (p) => p.keyTop),
          ('a faceplate in the housing', (p) => p.face, (p) => p.housingTop),
          ('a key on a faceplate', (p) => p.keyBottom, (p) => p.face),
          ('a latched key', (p) => p.keyDownTop, (p) => p.keyTop),
          ('a trough in a faceplate', (p) => p.trough, (p) => p.face),
        ]) {
          final own = applianceContrast(a(warm), z(warm));
          expect(
            applianceContrast(a(c), z(c)),
            closeTo(own, own * 0.02),
            reason: pair,
          );
        }
      });
    }
  }
}
