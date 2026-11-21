// A pointer over a part changes nothing it paints: every pressable in every
// inventory specimen, by day and by night, paints the same pixels hovered as
// idle. What the pointer does show is the cursor: a click over what presses,
// text over a field, the plain arrow over a disabled part. The rows a pointer
// changes on purpose are listed with why, and not compared.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:brutal_ui/brutal_parts.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/kit.dart';
import 'tiers.dart';

/// Rows a pointer may change on purpose, each with why (polish3 §1).
const pointerFollowing = <String, String>{
  'Tooltip': 'a tooltip opens after the pointer rests',
  'Command': "a command palette's active row follows the pointer",
  'HoverCard': 'a hover card opens after the pointer rests',
  'Rating': 'a rating previews the stars up to the pointer',
};

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

void main() {
  // Every run checks every row by day and by night, half its presses in each
  // light (turning over the rows); the sweep checks each half in the other
  // light.
  for (final brightness in Brightness.values) {
    for (final half in const [0, 1]) {
      testWidgets(
        '${brightness.name}: hovering paints nothing, the cursor tells '
        '(${half == 0 ? 'the first' : 'the other'} half of the presses)',
        tags: sweepUnless(half == brightness.index),
        (tester) async {
          tester.view.physicalSize = const Size(390, 1200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: const Offset(-10, -10));
          addTearDown(mouse.removePointer);
          // A test mouse is device 1, whatever its pointer number.
          MouseCursor cursor() =>
              RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(
                1,
              ) ??
              SystemMouseCursors.basic;
          final changed = <String>[];
          final cursors = <String>[];
          var compared = 0;
          for (final (row, entry) in BrutalInventory.registry.entries.indexed) {
            final builder = entry.builder;
            if (builder == null) continue;
            final key = GlobalKey();
            await tester.pumpWidget(
              kitApp(
                brightness: brightness,
                home: Builder(
                  builder: (context) => ColoredBox(
                    color: context.brutalTheme.colors.paper,
                    child: SingleChildScrollView(
                      child: RepaintBoundary(
                        key: key,
                        child: Padding(
                          padding: const EdgeInsets.all(BrutalSpacing.regular),
                          child: Align(
                            alignment: AlignmentDirectional.topStart,
                            child: KeyedSubtree(
                              key: ValueKey(entry.row),
                              child: Builder(builder: builder),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            // A skeleton breathes and a spinner turns for ever: pump a fixed time.
            await tester.pump(const Duration(milliseconds: 600));
            final compare = !pointerFollowing.containsKey(entry.row);
            final count = find.byType(RawButton).evaluate().length;
            for (var i = 0; i < count; i++) {
              if ((row + i) % 2 != half) continue;
              final press = find.byType(RawButton).at(i);
              if (!tester.any(press)) break;
              final box = tester.getRect(press);
              if (box.isEmpty || box.bottom < 0 || box.top > 1200) continue;
              if (box.right < 0 || box.left > 390) continue;
              final widget = tester.widget<RawButton>(press);
              final presses =
                  widget.onPressed != null || widget.onLongPress != null;
              final enabled = (widget.enabled ?? presses) && presses;
              final why = '${entry.row} press $i';
              await mouse.moveTo(const Offset(-10, -10));
              await tester.pump(const Duration(milliseconds: 50));
              final idle = compare ? await _pixels(tester, key) : null;
              await mouse.moveTo(box.center);
              await tester.pump(const Duration(milliseconds: 50));
              final over = cursor();
              // The innermost part under the pointer speaks: a part inside a
              // part may show its own.
              final inner = find
                  .descendant(of: press, matching: find.byType(RawButton))
                  .evaluate()
                  .any(
                    (e) => tester
                        .getRect(find.byElementPredicate((x) => x == e))
                        .contains(box.center),
                  );
              if (!inner) {
                final want = !enabled
                    ? [SystemMouseCursors.basic]
                    : widget.mouseCursor != null
                    ? [widget.mouseCursor!]
                    : [SystemMouseCursors.click, SystemMouseCursors.text];
                if (!want.contains(over)) cursors.add('$why: $over');
              }
              if (idle != null) {
                compared++;
                final hovered = await _pixels(tester, key);
                if (!listEquals(idle, hovered)) changed.add(why);
              }
            }
            for (final field in find.byType(EditableText).evaluate()) {
              final at = tester.getCenter(
                find.byElementPredicate((x) => x == field),
              );
              if (at.dy < 0 || at.dy > 1200 || at.dx < 0 || at.dx > 390) {
                continue;
              }
              await mouse.moveTo(at);
              await tester.pump();
              final editable = field.widget as EditableText;
              if (!editable.readOnly && cursor() != SystemMouseCursors.text) {
                cursors.add('${entry.row} field: ${cursor()}');
              }
            }
            await mouse.moveTo(const Offset(-10, -10));
            await tester.pump(const Duration(milliseconds: 600));
            expect(tester.takeException(), isNull, reason: entry.row);
          }
          // Leave nothing running: a toast's or a tooltip's timer.
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(seconds: 5));
          debugPrint(
            'HOVER ${brightness.name} half $half: $compared parts compared idle '
            'and hovered',
          );
          expect(compared, greaterThan(40));
          expect(
            changed,
            isEmpty,
            reason: 'Hover changed the paint: ${changed.join(', ')}',
          );
          expect(
            cursors,
            isEmpty,
            reason: 'Wrong cursor: ${cursors.join('; ')}',
          );
        },
      );
    }
  }
}
