// Hover changes the glaze of enabled controls and keeps each control's cursor.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_parts.dart';

import '../example/lib/kit_gallery/kit.dart';

/// These open a second surface on hover.
const pointerFollowing = <String, String>{
  'Tooltip': 'a tooltip opens after the pointer rests',
  'Command': "a command palette's active row follows the pointer",
  'HoverCard': 'a hover card opens after the pointer rests',
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
      '${brightness.name}: hover brings up a reflection and the appropriate cursor',
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
        final lit = <String>{};
        final disabledChanges = <String>[];
        final cursors = <String>[];
        var compared = 0;
        for (final entry in GlossInventory.registry.entries) {
          final builder = entry.builder;
          if (builder == null) continue;
          final key = GlobalKey();
          await tester.pumpWidget(
            kitApp(
              brightness: brightness,
              home: Builder(
                builder: (context) => ColoredBox(
                  color: context.glossTheme.colors.page,
                  child: SingleChildScrollView(
                    child: RepaintBoundary(
                      key: key,
                      child: Padding(
                        padding: const EdgeInsets.all(GlossSpacing.regular),
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
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));
            final idle = compare ? await _pixels(tester, key) : null;
            await mouse.moveTo(box.center);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 400));
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
              if (!listEquals(idle, hovered) && !inner) {
                if (widget.enabled ?? presses) {
                  lit.add(entry.row);
                } else if (over == SystemMouseCursors.basic) {
                  disabledChanges.add(why);
                }
              }
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
        debugPrint(
          'HOVER ${brightness.name}: $compared parts compared idle and hovered',
        );
        expect(compared, greaterThan(60));
        expect(
          lit,
          containsAll(['Button', 'Checkbox', 'Switch', 'Chip', 'IconButton']),
        );
        expect(
          disabledChanges,
          isEmpty,
          reason: 'A disabled control reacted to hover',
        );
        expect(cursors, isEmpty, reason: 'Wrong cursor: ${cursors.join('; ')}');
      },
    );
  }
}
