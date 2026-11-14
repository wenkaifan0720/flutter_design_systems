// ignore_for_file: avoid_relative_lib_imports
// The states the round-3 review found drawn as idle, and the parts it found
// out of size, each held in both appearances, by day and by night:
// a list row shows its press and dims when disabled; a checkbox shows its
// error (a ring and its words); a disabled rating keeps its size and dims;
// a stepper is as wide as its value and dims its value when disabled; Chisel
// greys a checkbox or radio while it is held; a chart names every gridline at
// a round value; a window's shadow is its own outline, hard, right and down.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart' show kPressTimeout;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

const appearances = <String, RetroDesktopAppearance>{
  'chisel': RetroDesktopAppearance.chisel,
  'platinum': RetroDesktopAppearance.platinum,
};

void _take(Object? _) {}
void _noop() {}

Future<Uint8List> _pixels(WidgetTester tester, GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  }))!;
}

Future<GlobalKey> _host(
  WidgetTester tester,
  RetroDesktopAppearance appearance,
  Brightness brightness,
  Widget child,
) async {
  tester.view.physicalSize = const Size(700, 500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, app) => RetroDesktopTheme(
        data: RetroDesktopThemeData.classic(brightness)
            .copyWith(appearance: appearance),
        child: app!,
      ),
      home: Builder(
        builder: (context) => ColoredBox(
          color: RetroDesktopTheme.of(context).colors.platinum,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: ColoredBox(
                color: RetroDesktopTheme.of(context).colors.platinum,
                child: Padding(padding: const EdgeInsets.all(12), child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

/// The pixels of [child] idle, and while the pointer holds its first press.
Future<(Uint8List, Uint8List, Size, Size)> _idleAndHeld(
  WidgetTester tester,
  RetroDesktopAppearance appearance,
  Brightness brightness,
  Widget child,
) async {
  final key = await _host(tester, appearance, brightness, child);
  final idle = await _pixels(tester, key);
  final idleSize = tester.getSize(find.byKey(key));
  final down = await tester.startGesture(
    tester.getCenter(find.byType(RetroDesktopPressable).first),
  );
  await tester.pump(kPressTimeout);
  await tester.pump(const Duration(milliseconds: 100));
  final held = await _pixels(tester, key);
  final heldSize = tester.getSize(find.byKey(key));
  await down.cancel();
  await tester.pumpAndSettle();
  return (idle, held, idleSize, heldSize);
}

/// The pixels and size of [child], settled.
Future<(Uint8List, Size)> _still(
  WidgetTester tester,
  RetroDesktopAppearance appearance,
  Brightness brightness,
  Widget child,
) async {
  final key = await _host(tester, appearance, brightness, child);
  return (await _pixels(tester, key), tester.getSize(find.byKey(key)));
}

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
        final (idle, held, idleSize, heldSize) = await _idleAndHeld(
          tester,
          f.value,
          b,
          row(),
        );
        expect(listEquals(idle, held), isFalse, reason: 'pressed = idle');
        expect(heldSize, idleSize, reason: 'the press moves nothing');
        final (off, offSize) = await _still(
          tester,
          f.value,
          b,
          row(enabled: false),
        );
        expect(listEquals(idle, off), isFalse, reason: 'disabled = idle');
        expect(offSize, idleSize);
        // A still row of words (no onPressed) is not a disabled one.
        await _still(
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
        final (idle, idleSize) = await _still(
          tester,
          f.value,
          b,
          RetroDesktopCheckbox(label: 'Agree', value: false, onChanged: _take),
        );
        final boxSize = tester.getSize(find.byType(RetroDesktopPressable));
        await _still(
          tester,
          f.value,
          b,
          RetroDesktopCheckbox(
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
        final (ringed, ringedSize) = await _still(
          tester,
          f.value,
          b,
          RetroDesktopCheckbox(
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
        final (on, onSize) = await _still(
          tester,
          f.value,
          b,
          RetroDesktopRating(label: 'Rating', value: 3, onChanged: _take),
        );
        final (off, offSize) = await _still(
          tester,
          f.value,
          b,
          RetroDesktopRating(
            label: 'Rating',
            value: 3,
            onChanged: _take,
            enabled: false,
          ),
        );
        expect(offSize, onSize);
        expect(listEquals(on, off), isFalse, reason: 'disabled not dimmed');
        await tester.tap(find.byType(RetroDesktopPressable).first);
        await tester.pump();
        expect(tester.takeException(), isNull);
      }, tags: const ['goldens']);

      testWidgets('$name: a stepper is as wide as its value', (tester) async {
        final widths = <double>[];
        for (final value in [0, 5, 9]) {
          await _still(
            tester,
            f.value,
            b,
            RetroDesktopNumberField(
              label: 'Copies',
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
        await _still(
          tester,
          f.value,
          b,
          const RetroDesktopNumberField(label: 'Copies', value: 3, max: 9),
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
          RetroDesktopCheckbox(label: 'Agree', value: false, onChanged: _take),
          RetroDesktopRadioGroup<int>(
            label: 'Delivery',
            onChanged: _take,
            options: const [
              RetroDesktopRadio(1, 'Standard'),
              RetroDesktopRadio(2, 'Express'),
            ],
          ),
        ]) {
          final (idle, held, _, _) = await _idleAndHeld(
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

      testWidgets('$name: a chart names every gridline at a round value', (
        tester,
      ) async {
        for (final (kind, values, names) in [
          (
            RetroDesktopChartType.bar,
            <double>[3, 12, 7, 9],
            ['0', '5', '10', '15'],
          ),
          (
            RetroDesktopChartType.line,
            <double>[9, 15, 22, 12],
            ['5', '10', '15', '20', '25'],
          ),
        ]) {
          await _still(
            tester,
            f.value,
            b,
            SizedBox(
              width: 500,
              child: RetroDesktopChart(
                label: 'Visits',
                kind: kind,
                series: [RetroDesktopChartSeries('Visits', values)],
                labels: const ['Mon', 'Tue', 'Wed', 'Thu'],
              ),
            ),
          );
          final ys = [for (final n in names) tester.getCenter(find.text(n)).dy];
          // Read top to bottom, the values fall, and stand evenly apart.
          for (var i = 1; i < ys.length; i++) {
            expect(ys[i], lessThan(ys[i - 1]), reason: '$kind $names');
          }
          final gaps = [
            for (var i = 2; i < ys.length - 1; i++) ys[i - 1] - ys[i],
          ];
          for (final g in gaps) {
            expect(g, closeTo(gaps.first, 1.5), reason: '$kind $ys');
          }
        }
      }, tags: const ['goldens']);

      testWidgets(
        '$name: a window casts its own outline, hard, right and down',
        (tester) async {
          for (final active in [true, false]) {
            await _still(
              tester,
              f.value,
              b,
              SizedBox(
                width: 300,
                height: 160,
                child: RetroDesktopWindowScope(
                  active: active,
                  compact: false,
                  child: const RetroDesktopWindow(
                    title: 'Profile',
                    child: Text('Your details'),
                  ),
                ),
              ),
            );
            final shadows = [
              for (final box in tester.widgetList<DecoratedBox>(
                find.descendant(
                  of: find.byType(RetroDesktopWindow),
                  matching: find.byType(DecoratedBox),
                ),
              ))
                if (box.decoration case ShapeDecoration(:final shadows?))
                  ...shadows,
            ];
            if (f.value == RetroDesktopAppearance.chisel) {
              expect(shadows, isEmpty, reason: 'Chisel stands on its bevel');
              continue;
            }
            expect(shadows, isNotEmpty);
            for (final s in shadows) {
              expect(s.blurRadius, 0, reason: 'active: $active');
              expect(s.spreadRadius, 0, reason: 'active: $active');
              expect(s.offset.dx, greaterThan(0));
              expect(s.offset.dy, s.offset.dx);
            }
          }
        },
        tags: const ['goldens'],
      );
    }
  }
}
