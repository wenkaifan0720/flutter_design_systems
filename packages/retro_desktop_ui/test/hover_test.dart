// ignore_for_file: avoid_relative_lib_imports
// A pointer over a part changes nothing it paints: every pressable part in
// every specimen, in both appearances, paints the same pixels hovered as idle.
// What the pointer does show is the cursor: a click over what presses, a grab
// over what drags, text over a field, and the plain arrow over a disabled part.
// Menus keep their pointer-following highlight and tooltips their delay, so
// their specimens are not compared.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'shape_fit_test.dart' show shapeSpecimens;
import 'support.dart';

/// Specimens a pointer may change on purpose, each with why.
const pointerFollowing = <String, String>{
  'kitSpecimenMenu': 'a menu highlights the item under the pointer',
  'kitSpecimenTopBar': "the menu bar's titles follow the pointer once open",
  'kitSpecimenTooltip': 'a tooltip opens after the pointer rests',
  'kitSpecimenChart': 'a chart reads out the value under the pointer',
  'kitSpecimenLineChart': 'a chart reads out the value under the pointer',
  'kitSpecimenAreaChart': 'a chart reads out the value under the pointer',
  'kitSpecimenDonutChart': 'a chart reads out the value under the pointer',
  'kitSpecimenSparkline': 'a chart reads out the value under the pointer',
};

const appearances = <String, RetroDesktopAppearance>{
  'chisel': RetroDesktopAppearance.chisel,
  'platinum': RetroDesktopAppearance.platinum,
};

Future<Uint8List> pixels(WidgetTester tester, GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  }))!;
}

void main() {
  setUpAll(loadRetroDesktopFonts);

  for (final appearance in appearances.entries) {
    testWidgets(
      '${appearance.key}: hovering paints nothing, the cursor tells',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final theme = RetroDesktopThemeData.classic().copyWith(
          appearance: appearance.value,
        );
        final mouse = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
          pointer: 7,
        );
        await mouse.addPointer(location: const Offset(-10, -10));
        addTearDown(mouse.removePointer);
        // A test mouse is device 1, whatever its pointer number.
        MouseCursor cursor() =>
            RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1) ??
            SystemMouseCursors.basic;
        final changed = <String>[];
        final cursors = <String>[];
        var compared = 0;
        for (final specimen in shapeSpecimens.entries) {
          // The whole screen fills a view, not a scroll: its parts are compared
          // alone.
          if (specimen.key == 'kitSpecimenScreen') continue;
          final key = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) =>
                  RetroDesktopTheme(data: theme, child: child!),
              home: SingleChildScrollView(
                child: RepaintBoundary(
                  key: key,
                  child: KeyedSubtree(
                    key: ValueKey(specimen.key),
                    child: specimen.value(),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle(const Duration(milliseconds: 50));
          final compare = !pointerFollowing.containsKey(specimen.key);
          final presses = find
              .byType(RetroDesktopPressable)
              .evaluate()
              .toList();
          for (var i = 0; i < presses.length; i++) {
            final press = find.byType(RetroDesktopPressable).at(i);
            if (!tester.any(press)) break;
            final box = tester.getRect(press);
            if (box.isEmpty || box.bottom < 0 || box.top > 1600) continue;
            final widget = tester.widget<RetroDesktopPressable>(press);
            final enabled =
                (widget.onPressed != null || widget.onLongPress != null) &&
                !widget.busy;
            final why = '${specimen.key} press $i';
            await mouse.moveTo(const Offset(-10, -10));
            await tester.pump(const Duration(milliseconds: 50));
            final idle = compare ? await pixels(tester, key) : null;
            await mouse.moveTo(box.center);
            await tester.pump(const Duration(milliseconds: 50));
            final over = cursor();
            // The innermost region under the pointer speaks: a part inside a
            // part (a field in a row) may show its own.
            final inner = find
                .descendant(
                  of: press,
                  matching: find.byType(RetroDesktopPressable),
                )
                .evaluate()
                .any(
                  (e) => tester
                      .getRect(find.byElementPredicate((x) => x == e))
                      .contains(box.center),
                );
            if (!inner) {
              final want = !enabled
                  ? [SystemMouseCursors.basic]
                  : widget.cursor != null
                  ? [widget.cursor!]
                  : [SystemMouseCursors.click, SystemMouseCursors.text];
              if (!want.contains(over)) cursors.add('$why: $over');
            }
            if (idle != null) {
              compared++;
              final hovered = await pixels(tester, key);
              if (!listEquals(idle, hovered)) changed.add(why);
            }
          }
          for (final field in find.byType(EditableText).evaluate()) {
            final at = tester.getCenter(
              find.byElementPredicate((x) => x == field),
            );
            if (at.dy < 0 || at.dy > 1600) continue;
            await mouse.moveTo(at);
            await tester.pump();
            final editable = field.widget as EditableText;
            final want = editable.readOnly ? null : SystemMouseCursors.text;
            if (want != null && cursor() != want) {
              cursors.add('${specimen.key} field: ${cursor()}');
            }
          }
          await mouse.moveTo(const Offset(-10, -10));
          await tester.pump();
          expect(tester.takeException(), isNull, reason: specimen.key);
        }
        debugPrint(
          'HOVER ${appearance.key}: $compared parts compared idle and hovered',
        );
        expect(compared, greaterThan(60));
        expect(
          changed,
          isEmpty,
          reason: 'Hover changed the paint: ${changed.join(', ')}',
        );
        expect(cursors, isEmpty, reason: 'Wrong cursor: ${cursors.join('; ')}');
      },
      tags: const ['goldens'],
    );
  }
}
