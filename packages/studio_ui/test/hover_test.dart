// A pointer over any pressable in the component inventory, by day and by
// night, keeps the part's size and place, leaves a disabled part as it was,
// and shows the cursor its kind calls for: a click over what presses, text
// over a field, the plain arrow over a disabled part. Composite samples whose
// rows follow the pointer on purpose are listed with the reason.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:studio_ui/studio_parts.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/kit.dart';

/// Composite samples that may change under the pointer independently of a disabled target.
const pointerFollowing = <String, String>{
  'MenuBar': "a menu bar's title sinks its slot under the pointer",
  'DataTable': "a table's row sinks its slot under the pointer",
  'TreeView': "a tree's row sinks its slot under the pointer",
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
  for (final brightness in Brightness.values) {
    testWidgets(
      '${brightness.name}: hover preserves target geometry and the disabled state',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: const Offset(-10, -10));
        addTearDown(mouse.removePointer);
        // A test mouse is device 1, whatever its pointer number.
        MouseCursor cursor() =>
            RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1) ??
            SystemMouseCursors.basic;
        final changed = <String>[];
        final cursors = <String>[];
        var targets = 0;
        for (final entry in StudioInventory.registry.entries) {
          final builder = entry.builder;
          if (builder == null) continue;
          final key = GlobalKey();
          await tester.pumpWidget(
            kitApp(
              brightness: brightness,
              home: Builder(
                builder: (context) => ColoredBox(
                  color: context.studioTheme.colors.chassis,
                  child: SingleChildScrollView(
                    child: RepaintBoundary(
                      key: key,
                      child: Padding(
                        padding: const EdgeInsets.all(StudioSpacing.regular),
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
          final count = find.byType(DesignPressable).evaluate().length;
          for (var i = 0; i < count; i++) {
            final press = find.byType(DesignPressable).at(i);
            if (!tester.any(press)) break;
            final box = tester.getRect(press);
            if (box.isEmpty || box.bottom < 0 || box.top > 1200) continue;
            if (box.right < 0 || box.left > 390) continue;
            final widget = tester.widget<DesignPressable>(press);
            final presses =
                widget.onPressed != null || widget.onLongPress != null;
            final enabled = (widget.enabled ?? presses) && presses;
            final why = '${entry.row} press $i';
            await mouse.moveTo(const Offset(-10, -10));
            await tester.pump(const Duration(milliseconds: 50));
            final idle = compare && !enabled
                ? await _pixels(tester, key)
                : null;
            await mouse.moveTo(box.center);
            await tester.pump(const Duration(milliseconds: 50));
            final over = cursor();
            // The innermost part under the pointer speaks: a part inside a
            // part may show its own.
            final inner = find
                .descendant(of: press, matching: find.byType(DesignPressable))
                .evaluate()
                .any(
                  (e) => tester
                      .getRect(find.byElementPredicate((x) => x == e))
                      .contains(box.center),
                );
            expect(tester.getRect(press), box, reason: why);
            targets++;
            if (!inner) {
              final want = !enabled
                  ? [SystemMouseCursors.basic]
                  : widget.mouseCursor != null
                  ? [widget.mouseCursor!]
                  : [SystemMouseCursors.click, SystemMouseCursors.text];
              if (!want.contains(over)) cursors.add('$why: $over');
            }
            if (idle != null && !inner) {
              final hovered = await _pixels(tester, key);
              if (!listEquals(idle, hovered)) changed.add(why);
            }
          }
          for (final field in find.byType(EditableText).evaluate()) {
            final at = tester.getCenter(
              find.byElementPredicate((x) => x == field),
            );
            if (at.dy < 0 || at.dy > 1200 || at.dx < 0 || at.dx > 390) continue;
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
        expect(targets, greaterThan(60));
        expect(
          changed,
          isEmpty,
          reason: 'Hover changed a disabled control: ${changed.join(', ')}',
        );
        expect(cursors, isEmpty, reason: 'Wrong cursor: ${cursors.join('; ')}');
      },
    );
  }
}
