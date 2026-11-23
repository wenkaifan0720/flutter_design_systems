// States that must not draw as idle, and parts that must keep their size,
// each held in both appearances, by day and by night:
// a list row shows its press and dims when disabled; a checkbox shows its
// error (a ring and its words); a disabled rating keeps its size and dims;
// a stepper is as wide as its value and dims its value when disabled; Chisel
// greys a checkbox or radio while it is held.
import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'still_pixels.dart';
import 'support.dart';

const appearances = <String, RetroDesktopAppearance>{
  'chisel': RetroDesktopAppearance.chisel,
  'platinum': RetroDesktopAppearance.platinum,
};

void _take(Object? _) {}
void _noop() {}

void main() {
  setUpAll(loadRetroDesktopFonts);

  for (final f in appearances.entries) {
    for (final b in Brightness.values) {
      final name = '${f.key} ${b.name}';

      testWidgets('$name: a list row shows its press and dims when disabled', (
        tester,
      ) async {
        Widget row({bool enabled = true}) => SizedBox(
          width: 300,
          child: RetroDesktopListTile(
            title: 'Project notes',
            subtitle: 'Edited today',
            onPressed: _noop,
            enabled: enabled,
          ),
        );
        final (idle, held, idleSize, heldSize) = await idleAndHeldPixels(
          tester,
          f.value,
          b,
          row(),
        );
        expect(listEquals(idle, held), isFalse, reason: 'pressed = idle');
        expect(heldSize, idleSize, reason: 'the press moves nothing');
        final (off, offSize) = await stillPixels(
          tester,
          f.value,
          b,
          row(enabled: false),
        );
        expect(listEquals(idle, off), isFalse, reason: 'disabled = idle');
        expect(offSize, idleSize);
        // A still row of words (no onPressed) is not a disabled one.
        await stillPixels(
          tester,
          f.value,
          b,
          const SizedBox(
            width: 300,
            child: RetroDesktopListTile(
              title: 'Project notes',
              subtitle: 'Edited today',
            ),
          ),
        );
        for (final dim in tester.widgetList<AnimatedOpacity>(
          find.ancestor(
            of: find.text('Project notes'),
            matching: find.byType(AnimatedOpacity),
          ),
        )) {
          expect(dim.opacity, 1, reason: 'a still row dims');
        }
      }, tags: const ['goldens']);

      testWidgets('$name: a checkbox shows its error by its ring', (
        tester,
      ) async {
        final (idle, idleSize) = await stillPixels(
          tester,
          f.value,
          b,
          const RetroDesktopCheckbox(
            label: 'Agree',
            value: false,
            onChanged: _take,
          ),
        );
        final boxSize = tester.getSize(find.byType(RetroDesktopPressable));
        await stillPixels(
          tester,
          f.value,
          b,
          const RetroDesktopCheckbox(
            label: 'Agree',
            value: false,
            isError: true,
            onChanged: _take,
          ),
        );
        // A check carries no message: the field or form says why.
        expect(
          tester.getSize(find.byType(RetroDesktopPressable)),
          boxSize,
          reason: 'the ring stands outside the box: nothing beside it moves',
        );
        // The ring alone shows the error.
        final (ringed, ringedSize) = await stillPixels(
          tester,
          f.value,
          b,
          const RetroDesktopCheckbox(
            label: 'Agree',
            value: false,
            isError: true,
            onChanged: _take,
          ),
        );
        expect(ringedSize, idleSize);
        expect(listEquals(idle, ringed), isFalse, reason: 'error = idle');
      }, tags: const ['goldens']);

      testWidgets('$name: a disabled rating keeps its size and dims', (
        tester,
      ) async {
        final (on, onSize) = await stillPixels(
          tester,
          f.value,
          b,
          const RetroDesktopRating(label: 'Rating', value: 3, onChanged: _take),
        );
        final (off, offSize) = await stillPixels(
          tester,
          f.value,
          b,
          const RetroDesktopRating(
            label: 'Rating',
            value: 3,
            onChanged: _take,
            enabled: false,
          ),
        );
        expect(offSize, onSize);
        expect(listEquals(on, off), isFalse, reason: 'disabled not dimmed');
        // A press on a disabled star (ui_core's RawRating draws no pressables) does nothing, and throws nothing.
        await tester.tap(
          find
              .descendant(
                of: find.byType(RetroDesktopRating),
                matching: find.byType(RetroDesktopPixelPaint),
              )
              .first,
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }, tags: const ['goldens']);

      testWidgets('$name: a stepper is as wide as its value', (tester) async {
        final widths = <double>[];
        for (final value in [0, 5, 9]) {
          await stillPixels(
            tester,
            f.value,
            b,
            RetroDesktopNumberField(
              labelText: 'Copies',
              value: value,
              max: 9,
              onChanged: _take,
            ),
          );
          widths.add(
            tester.getSize(find.byType(RetroDesktopNumberField)).width,
          );
        }
        expect(widths.first, lessThan(200), reason: 'stretched: $widths');
        expect(widths.toSet(), hasLength(1), reason: 'moves as it counts');
        // Disabled, the value and its box dim with the buttons.
        await stillPixels(
          tester,
          f.value,
          b,
          const RetroDesktopNumberField(labelText: 'Copies', value: 3, max: 9),
        );
        final dim = tester.widget<AnimatedOpacity>(
          find
              .ancestor(
                of: find.text('3'),
                matching: find.byType(AnimatedOpacity),
              )
              .first,
        );
        expect(dim.opacity, .5);
      }, tags: const ['goldens']);

      testWidgets('$name: a held checkbox or radio shows it', (tester) async {
        for (final child in <Widget>[
          const RetroDesktopCheckbox(
            label: 'Agree',
            value: false,
            onChanged: _take,
          ),
          const RetroDesktopRadioGroup<int>(
            labelText: 'Delivery',
            onChanged: _take,
            options: [
              RetroDesktopRadio(1, 'Standard'),
              RetroDesktopRadio(2, 'Express'),
            ],
          ),
        ]) {
          final (idle, held, _, _) = await idleAndHeldPixels(
            tester,
            f.value,
            b,
            child,
          );
          expect(
            listEquals(idle, held),
            isFalse,
            reason: '${child.runtimeType} held = idle',
          );
        }
      }, tags: const ['goldens']);
    }
  }
}
