// A state a part claims has to show, and it may not move the part. Every filled
// focused, pressed, disabled and error cell of the table differs from idle
// pixel for pixel and has idle's size; an error may add its message below. In
// both appearances, by day and by night. And an empty disabled well in Chisel
// takes the window's grey: it reads as off by its fill, not only its bevel.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'state_parts.dart';
import 'support.dart';

class _Shot {
  const _Shot(this.width, this.height, this.pixels);
  final int width, height;
  final Uint8List pixels;
}

Future<_Shot> _take(WidgetTester tester, GlobalKey key) => tester
    .runAsync(() async {
      final image = await stateBoundary(key).toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final shot = _Shot(image.width, image.height, data!.buffer.asUint8List());
      image.dispose();
      return shot;
    })
    .then((shot) => shot!);

bool _same(_Shot a, _Shot b) {
  if (a.width != b.width || a.height != b.height) return false;
  for (var i = 0; i < a.pixels.length; i++) {
    if (a.pixels[i] != b.pixels[i]) return false;
  }
  return true;
}

void main() {
  setUpAll(loadRetroDesktopFonts);

  for (final appearance in RetroDesktopAppearance.values) {
    for (final brightness in Brightness.values) {
      testWidgets('focused, pressed, disabled and error show and keep the '
          'size, ${appearance.name} ${brightness.name}', (tester) async {
        tester.view.physicalSize = const Size(900, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: const Offset(-10, -10));
        addTearDown(mouse.removePointer);
        final theme = RetroDesktopThemeData.classic(brightness)
            .copyWith(appearance: appearance);
        final problems = <String>[];
        for (final part in stateParts.entries) {
          final plain = part.value('idle');
          if (plain == null) continue;
          final idle = await _take(
            tester,
            await pumpStateHost(tester, theme, plain),
          );
          for (final state in const [
            'focused',
            'pressed',
            'disabled',
            'error',
          ]) {
            final widget = part.value(state);
            if (widget == null) continue;
            // A new tree: a state must not carry over from the cell before.
            await tester.pumpWidget(const SizedBox.shrink());
            final key = await pumpStateHost(tester, theme, widget);
            final down = await enterState(tester, state, mouse);
            final shot = await _take(tester, key);
            await down?.cancel();
            await tester.pump();
            final where = '${part.key} $state';
            if (_same(shot, idle)) {
              problems.add('$where is idle, pixel for pixel');
            }
            // An error's message stands below the part and may be wider.
            final moved = state == 'error'
                ? shot.height < idle.height || shot.width < idle.width
                : shot.height != idle.height || shot.width != idle.width;
            if (moved) {
              problems.add(
                '$where is ${shot.width}x${shot.height}, '
                'idle ${idle.width}x${idle.height}',
              );
            }
            expect(tester.takeException(), isNull, reason: where);
          }
          await tester.pumpWidget(const SizedBox.shrink());
        }
        expect(problems, isEmpty, reason: problems.join('\n'));
      }, tags: const ['goldens']);
    }
  }

  for (final brightness in Brightness.values) {
    testWidgets('an empty disabled Chisel well takes the window\'s grey, '
        '${brightness.name}', (tester) async {
      tester.view.physicalSize = const Size(900, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final theme = RetroDesktopThemeData.classic(brightness)
          .copyWith(appearance: RetroDesktopAppearance.chisel);
      final window = theme.colors.platinum;
      // Each well, and where its middle is: the box a checkbox ticks, a code
      // field's first cell.
      final wells = <String, (Widget Function(bool enabled), Finder)>{
        'Checkbox': (
          (enabled) => RetroDesktopCheckbox(
            label: 'Remember me',
            value: false,
            onChanged: enabled ? (_) {} : null,
          ),
          find.descendant(
            of: find.byType(RetroDesktopCheckbox),
            matching: find.byWidgetPredicate(
              (w) => w is SizedBox && w.width == 14 && w.height == 14,
            ),
          ),
        ),
        'Code field': (
          (enabled) =>
              RetroDesktopInputOtp(label: 'Code', length: 4, enabled: enabled),
          find.descendant(
            of: find.byType(RetroDesktopInputOtp),
            matching: find.byType(Center),
          ),
        ),
      };
      Future<Color> middle(Widget part, Finder well) async {
        final key = await pumpStateHost(tester, theme, part);
        final shot = await _take(tester, key);
        final at = tester.getCenter(well.first);
        final i = (at.dy.floor() * shot.width + at.dx.floor()) * 4;
        final p = shot.pixels;
        return Color.fromARGB(p[i + 3], p[i], p[i + 1], p[i + 2]);
      }

      int apart(Color a, Color b) => [
        (a.r - b.r).abs(),
        (a.g - b.g).abs(),
        (a.b - b.b).abs(),
      ].map((d) => (d * 255).round()).reduce((x, y) => x > y ? x : y);
      for (final well in wells.entries) {
        final (part, finder) = well.value;
        final idle = await middle(part(true), finder);
        await tester.pumpWidget(const SizedBox.shrink());
        final off = await middle(part(false), finder);
        await tester.pumpWidget(const SizedBox.shrink());
        expect(apart(off, window), lessThanOrEqualTo(2), reason: well.key);
        expect(apart(idle, window), greaterThanOrEqualTo(16), reason: well.key);
      }
    }, tags: const ['goldens']);
  }
}
